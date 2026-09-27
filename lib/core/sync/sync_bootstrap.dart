import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../database/app_database.dart' hide coalesce;
import '../date/app_clock.dart';
import 'local/outbox_coalescer.dart';
import 'local/sync_local_store.dart' show syncStateId;
import 'local/sync_outbox.dart';
import 'sync_entity_type.dart';
import 'sync_logger.dart';
import 'sync_mapper_registry.dart';

/// 021 T063: queues every record that existed before sync, exactly once
/// (plan §16, data-model.md §3 step 4).
///
/// Runs in `beforeOpen`, after the finance seed. The only guard against a
/// second run is `sync_state.bootstrap_enqueued`, set in the **same**
/// transaction that queues the rows — never "the outbox is empty", which is
/// also true after a finished upload. A crash mid-way therefore leaves
/// nothing, and the next open queues everything.
///
/// It writes `sync_outbox` directly, never through `SyncOutbox` (whose
/// callers are the feature DAOs), so it cannot recurse into them.
class SyncBootstrap {
  SyncBootstrap(
    this._mappers,
    this._logger,
    this._clock, {
    required bool Function(FinanceCategory) isPristineSeed,
  }) : _isPristineSeed = isPristineSeed;

  final SyncMapperRegistry _mappers;
  final SyncLogger _logger;
  final AppClock _clock;

  /// Seeded categories the user never touched are not uploaded (research.md
  /// Decision 10). Supplied by the composition root, because the rule lives
  /// in the finance feature.
  final bool Function(FinanceCategory) _isPristineSeed;

  static const chunkSize = 500;
  static const _uuid = Uuid();

  /// Every synced type in upload order: parents (rank 0) first.
  static final List<SyncEntityType> _order = [...SyncEntityType.values]
    ..sort((a, b) => a.rank.compareTo(b.rank));

  /// Queues the pre-existing data unless that was already done. Returns the
  /// number of operations queued.
  ///
  /// With [force] (T069, re-owning after the account changed) it runs even
  /// though the bootstrap was already done: every local record is queued
  /// again as an upsert with `base_revision = null`, because the new
  /// account's server has never seen it. A record that already has a
  /// `pending` operation keeps it, rebased to `base_revision = null`; one
  /// blocked or failed keeps its operation unchanged. Joins the caller's
  /// transaction when there is one. Local data is never deleted.
  Future<int> enqueueExistingDataIfNeeded(
    AppDatabase db, {
    bool force = false,
  }) async {
    final counts = <SyncEntityType, int>{};
    await db.transaction(() async {
      final state = await (db.select(
        db.syncState,
      )..where((s) => s.id.equals(syncStateId))).getSingleOrNull();
      if (!force && (state?.bootstrapEnqueued ?? false)) return;

      final createdAt = _clock.now().millisecondsSinceEpoch;
      if (force) {
        // The old account's revisions mean nothing to the new one.
        await (db.update(db.syncOutboxEntries)
              ..where((o) => o.status.equals(OutboxStatus.pending)))
            .write(const SyncOutboxEntriesCompanion(baseRevision: Value(null)));
        await db
            .update(db.syncRecordMeta)
            .write(const SyncRecordMetaCompanion(serverRevision: Value(null)));
      }
      for (final type in _order) {
        counts[type] = await _enqueueType(db, type, createdAt);
      }

      if (state == null) {
        await db
            .into(db.syncState)
            .insert(
              SyncStateCompanion.insert(
                id: syncStateId,
                deviceId: _uuid.v4(),
                bootstrapEnqueued: const Value(true),
              ),
            );
      } else {
        await (db.update(db.syncState)..where((s) => s.id.equals(syncStateId)))
            .write(const SyncStateCompanion(bootstrapEnqueued: Value(true)));
      }
    });

    for (final MapEntry(key: type, value: count) in counts.entries) {
      _logger.event(
        SyncEvent.migrationEnqueued,
        fields: {SyncLogField.entityType: type.wire, SyncLogField.count: count},
      );
    }
    return counts.values.fold<int>(0, (a, b) => a + b);
  }

  Future<int> _enqueueType(
    AppDatabase db,
    SyncEntityType type,
    int createdAt,
  ) async {
    final table = _tableFor(db, type);
    final mapper = _mappers.mapperFor(type);

    // A record that already has an open operation is already queued.
    final open = {
      for (final row in await (db.select(
        db.syncOutboxEntries,
      )..where((o) => o.entityType.equals(type.wire))).get())
        row.entityId,
    };

    var queued = 0;
    for (var offset = 0; ; offset += chunkSize) {
      final rows =
          await (db.select(table)
                ..orderBy([(_) => OrderingTerm.asc(table.rowId)])
                ..limit(chunkSize, offset: offset))
              .get();
      if (rows.isEmpty) break;

      final ops = <SyncOutboxEntriesCompanion>[];
      final metas = <SyncRecordMetaCompanion>[];
      for (final row in rows) {
        if (row is FinanceCategory && _isPristineSeed(row)) continue;
        final payload = mapper.toWire(row);
        final id = payload['id'] as String;
        if (open.contains(id)) continue;
        ops.add(
          SyncOutboxEntriesCompanion.insert(
            opId: _uuid.v4(),
            entityType: type.wire,
            entityId: id,
            opType: OutboxOpType.upsert.wire,
            payloadJson: jsonEncode(payload),
            // Never synced: the server decides create vs replay (3a/3b).
            baseRevision: const Value(null),
            dependsOnRank: type.rank,
            status: OutboxStatus.pending,
            createdAt: createdAt,
          ),
        );
        metas.add(
          SyncRecordMetaCompanion.insert(
            entityType: type.wire,
            entityId: id,
            state: SyncRecordState.pending,
          ),
        );
      }
      await db.batch((batch) {
        batch.insertAll(db.syncOutboxEntries, ops);
        batch.insertAllOnConflictUpdate(db.syncRecordMeta, metas);
      });
      queued += ops.length;
      if (rows.length < chunkSize) break;
    }
    return queued;
  }

  static TableInfo<Table, Object?> _tableFor(
    AppDatabase db,
    SyncEntityType type,
  ) => switch (type) {
    SyncEntityType.person => db.people,
    SyncEntityType.moneyTransaction => db.moneyTransactions,
    SyncEntityType.transactionAudit => db.transactionAuditEntries,
    SyncEntityType.financeCategory => db.financeCategories,
    SyncEntityType.financeEntry => db.financeEntries,
    SyncEntityType.exchangeRate => db.exchangeRates,
    SyncEntityType.primaryCurrency => db.primaryCurrencySettings,
    SyncEntityType.conflictResolution => db.conflictResolutions,
  };
}
