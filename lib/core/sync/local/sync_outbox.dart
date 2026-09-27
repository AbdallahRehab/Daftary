import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' hide coalesce;
import '../../date/app_clock.dart';
import '../sync_entity_type.dart';
import 'outbox_coalescer.dart';

/// 021: records local changes for upload (research.md Decision 2).
///
/// Feature DAOs call it **inside** their own `_db.transaction`, right after
/// the business write, so the record and its outbox row commit — or roll
/// back — together. Calling it outside a transaction is a programming error
/// and throws [StateError].
abstract class SyncOutbox {
  /// Queues an upsert of [payload] (the wire shape, contracts/sync-rpc.md
  /// §1) for the record [id].
  Future<void> recordUpsert(
    SyncEntityType type,
    String id,
    Map<String, Object?> payload,
  );

  /// Queues a delete of the record [id]; [lastKnownPayload] is its final
  /// wire snapshot.
  Future<void> recordDelete(
    SyncEntityType type,
    String id,
    Map<String, Object?> lastKnownPayload,
  );
}

/// `sync_record_meta.state` values.
abstract final class SyncRecordState {
  static const synced = 'synced';
  static const pending = 'pending';
  static const failed = 'failed';
  static const conflict = 'conflict';
}

@LazySingleton(as: SyncOutbox)
class DriftSyncOutbox implements SyncOutbox {
  DriftSyncOutbox(this._db, this._clock);

  final AppDatabase _db;
  final AppClock _clock;

  static const _uuid = Uuid();

  @override
  Future<void> recordUpsert(
    SyncEntityType type,
    String id,
    Map<String, Object?> payload,
  ) => _record(type, id, OutboxOpType.upsert, payload);

  @override
  Future<void> recordDelete(
    SyncEntityType type,
    String id,
    Map<String, Object?> lastKnownPayload,
  ) => _record(type, id, OutboxOpType.delete, lastKnownPayload);

  Future<void> _record(
    SyncEntityType type,
    String id,
    OutboxOpType opType,
    Map<String, Object?> payload,
  ) async {
    _assertInTransaction();

    final existing = await _openOpFor(type, id);
    final decision = coalesce(
      existing == null
          ? null
          : ExistingOutboxOp(
              opId: existing.opId,
              opType: OutboxOpType.fromWire(existing.opType),
              baseRevision: existing.baseRevision,
              status: existing.status,
            ),
      type: type,
      newOpType: opType,
    );
    final payloadJson = jsonEncode(payload);

    switch (decision) {
      case InsertNewOp():
        final meta = await _metaFor(type, id);
        await _db
            .into(_db.syncOutboxEntries)
            .insert(
              SyncOutboxEntriesCompanion.insert(
                opId: _uuid.v4(),
                entityType: type.wire,
                entityId: id,
                opType: opType.wire,
                payloadJson: payloadJson,
                baseRevision: Value(meta?.serverRevision),
                dependsOnRank: type.rank,
                status: OutboxStatus.pending,
                createdAt: _clock.now().millisecondsSinceEpoch,
              ),
            );
        await _markPending(type, id, meta);
      case MergeIntoOp(:final opId, opType: final mergedType):
        await (_db.update(
          _db.syncOutboxEntries,
        )..where((o) => o.opId.equals(opId))).write(
          SyncOutboxEntriesCompanion(
            opType: Value(mergedType.wire),
            payloadJson: Value(payloadJson),
          ),
        );
        await _markPending(type, id, await _metaFor(type, id));
      case DropBothOps(:final opId):
        await (_db.delete(
          _db.syncOutboxEntries,
        )..where((o) => o.opId.equals(opId))).go();
        // The server never saw the record, and it no longer exists locally.
        await (_db.delete(_db.syncRecordMeta)..where(
              (m) => m.entityType.equals(type.wire) & m.entityId.equals(id),
            ))
            .go();
    }
  }

  void _assertInTransaction() {
    // drift swaps `resolvedEngine` for a transaction-specific engine inside
    // `transaction(...)`; there is no public "in transaction" API.
    // ignore: invalid_use_of_internal_member
    if (identical(_db.resolvedEngine, _db)) {
      throw StateError(
        'SyncOutbox must be called inside the caller\'s database '
        'transaction, so the business write and its outbox row are atomic.',
      );
    }
  }

  /// The operation to coalesce with: the entity's newest `pending` one if
  /// any, otherwise its newest open one (which [coalesce] will not merge
  /// into).
  Future<SyncOutboxRow?> _openOpFor(SyncEntityType type, String id) {
    final o = _db.syncOutboxEntries;
    return (_db.select(o)
          ..where((r) => r.entityType.equals(type.wire) & r.entityId.equals(id))
          ..orderBy([
            (r) => OrderingTerm.desc(r.status.equals(OutboxStatus.pending)),
            (r) => OrderingTerm.desc(r.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<SyncRecordMetaRow?> _metaFor(SyncEntityType type, String id) =>
      (_db.select(_db.syncRecordMeta)..where(
            (m) => m.entityType.equals(type.wire) & m.entityId.equals(id),
          ))
          .getSingleOrNull();

  Future<void> _markPending(
    SyncEntityType type,
    String id,
    SyncRecordMetaRow? meta,
  ) async {
    // An open conflict stays visible until the user resolves it.
    if (meta?.state == SyncRecordState.conflict) return;
    await _db
        .into(_db.syncRecordMeta)
        .insertOnConflictUpdate(
          SyncRecordMetaCompanion.insert(
            entityType: type.wire,
            entityId: id,
            state: SyncRecordState.pending,
            serverRevision: Value(meta?.serverRevision),
            lastSyncedAt: Value(meta?.lastSyncedAt),
          ),
        );
  }
}
