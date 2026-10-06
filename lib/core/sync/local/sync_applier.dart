import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' hide coalesce;
import '../../date/app_clock.dart';
import '../sync_entity_type.dart';
import '../sync_mapper_registry.dart';
import '../sync_models.dart';
import 'outbox_coalescer.dart';
import 'sync_local_store.dart' show syncStateId;
import 'sync_outbox.dart' show SyncRecordState;

/// 021 T068: applies server rows to the local database
/// (contracts/sync-rpc.md §4, contracts/dart-interfaces.md §1).
///
/// Rows applied here **never** create outbox entries: the applier writes the
/// business tables directly, not through the feature DAOs that record
/// changes (research.md Decision 2).
abstract class SyncApplier {
  /// Applies one pulled page atomically and advances
  /// `sync_state.last_pulled_revision` to [PullPage.maxRevision] at the end
  /// of the same transaction. A failure leaves the cursor unchanged.
  Future<void> applyPage(PullPage page);

  /// Applies one server row outside a pull — a `server_row` carried by a
  /// push result (contracts/sync-rpc.md §5) or the server side chosen when
  /// resolving a conflict. Joins the caller's transaction when there is one.
  Future<ApplyOutcome> applyServerRow(
    SyncEntityType type,
    Map<String, Object?> row,
  );
}

/// What applying one row did.
enum ApplyOutcome {
  /// The row was inserted or its business fields overwritten.
  written,

  /// A tombstone removed the local row (people, categories, rates).
  deleted,

  /// The record has an open outbox operation: the local row was kept. The
  /// operation's own `base_revision` decides at push time.
  skipped,

  /// The record is in a manual conflict: the local row was kept, and the
  /// conflict now holds this newer server version.
  conflictRefreshed,
}

/// Types whose local delete is a hard delete; their tombstone removes the
/// local row. Transactions and entries are soft-deleted through
/// `deleted_at`, like the app does.
const _hardDeleted = {
  SyncEntityType.person,
  SyncEntityType.financeCategory,
  SyncEntityType.exchangeRate,
  // 022: removed outright in the app (010 research.md Decision 5).
  SyncEntityType.budgetAllocation,
};

class DriftSyncApplier implements SyncApplier {
  DriftSyncApplier(
    this._db,
    this._mappers,
    this._clock, {
    required bool Function(FinanceCategory) isPristineSeed,
  }) : _isPristineSeed = isPristineSeed;

  final AppDatabase _db;
  final SyncMapperRegistry _mappers;
  final AppClock _clock;

  /// Seeded categories the user never touched are overwritten by a
  /// downloaded row (research.md Decision 10). Supplied by the composition
  /// root, because the rule lives in the finance feature.
  final bool Function(FinanceCategory) _isPristineSeed;

  static const _uuid = Uuid();

  @override
  Future<void> applyPage(PullPage page) {
    return _db.transaction(() async {
      for (final change in page.changes) {
        await _apply(change.entityType, change.row, change.revision);
      }
      await _advanceCursor(page.maxRevision);
    });
  }

  @override
  Future<ApplyOutcome> applyServerRow(
    SyncEntityType type,
    Map<String, Object?> row,
  ) {
    final revision = row['revision'];
    return _db.transaction(
      () => _apply(type, row, revision is num ? revision.toInt() : null),
    );
  }

  Future<ApplyOutcome> _apply(
    SyncEntityType type,
    Map<String, Object?> row,
    int? revision,
  ) async {
    final id = row['id'];
    if (id is! String) {
      throw const FormatException('Invalid wire value for "id"');
    }
    final table = _tableFor(type);
    final idColumn = table.columnsByName['id']! as GeneratedColumn<String>;
    final existing = await (_db.select(
      table,
    )..where((_) => idColumn.equals(id))).getSingleOrNull();

    final openOps =
        await (_db.select(_db.syncOutboxEntries)..where(
              (o) => o.entityType.equals(type.wire) & o.entityId.equals(id),
            ))
            .get();
    if (openOps.isNotEmpty) {
      if (openOps.any((o) => o.status == OutboxStatus.blockedConflict)) {
        await _refreshConflict(type, id, row, revision);
        return ApplyOutcome.conflictRefreshed;
      }
      final pristineSeed =
          existing is FinanceCategory && _isPristineSeed(existing);
      if (!pristineSeed) return ApplyOutcome.skipped;
      // A seed still equal to its definition carries no user change (a
      // change made and then reverted): the downloaded row wins, and the
      // no-op upload is dropped so it cannot overwrite it later.
      await (_db.delete(_db.syncOutboxEntries)..where(
            (o) => o.entityType.equals(type.wire) & o.entityId.equals(id),
          ))
          .go();
    }

    final ApplyOutcome outcome;
    if (row['deleted_at'] != null && _hardDeleted.contains(type)) {
      if (await _hasLocalChildren(type, id)) {
        // The server only removes a childless record; local children not
        // uploaded yet keep it until they reach the server.
        return ApplyOutcome.skipped;
      }
      await (_db.delete(table)..where((_) => idColumn.equals(id))).go();
      outcome = ApplyOutcome.deleted;
    } else {
      final mapper = _mappers.mapperFor(type);
      await _db
          .into(table)
          .insertOnConflictUpdate(
            mapper.fromWire(row, existingLocal: existing),
          );
      outcome = ApplyOutcome.written;
    }

    await _db
        .into(_db.syncRecordMeta)
        .insertOnConflictUpdate(
          SyncRecordMetaCompanion.insert(
            entityType: type.wire,
            entityId: id,
            state: SyncRecordState.synced,
            serverRevision: Value(revision),
            lastSyncedAt: Value(_clock.now().millisecondsSinceEpoch),
          ),
        );
    return outcome;
  }

  /// Keeps an open conflict on the latest server version, so "keep theirs"
  /// never applies a stale row and "keep mine" uses the latest base.
  Future<void> _refreshConflict(
    SyncEntityType type,
    String id,
    Map<String, Object?> row,
    int? revision,
  ) async {
    await (_db.update(_db.syncConflicts)..where(
          (c) =>
              c.entityType.equals(type.wire) &
              c.entityId.equals(id) &
              c.resolvedAt.isNull(),
        ))
        .write(
          SyncConflictsCompanion(
            serverPayloadJson: Value(jsonEncode(row)),
            serverRevision: revision == null
                ? const Value.absent()
                : Value(revision),
          ),
        );
  }

  Future<bool> _hasLocalChildren(SyncEntityType type, String id) async {
    switch (type) {
      case SyncEntityType.person:
        final child =
            await (_db.select(_db.moneyTransactions)
                  ..where((t) => t.personId.equals(id))
                  ..limit(1))
                .getSingleOrNull();
        return child != null;
      case SyncEntityType.financeCategory:
        final child =
            await (_db.select(_db.financeEntries)
                  ..where((e) => e.categoryId.equals(id))
                  ..limit(1))
                .getSingleOrNull();
        return child != null;
      default:
        return false;
    }
  }

  Future<void> _advanceCursor(int maxRevision) async {
    final updated =
        await (_db.update(_db.syncState)
              ..where((s) => s.id.equals(syncStateId)))
            .write(SyncStateCompanion(lastPulledRevision: Value(maxRevision)));
    if (updated == 0) {
      await _db
          .into(_db.syncState)
          .insert(
            SyncStateCompanion.insert(
              id: syncStateId,
              deviceId: _uuid.v4(),
              lastPulledRevision: Value(maxRevision),
            ),
          );
    }
  }

  TableInfo<Table, Object?> _tableFor(SyncEntityType type) => switch (type) {
    SyncEntityType.person => _db.people,
    SyncEntityType.moneyTransaction => _db.moneyTransactions,
    SyncEntityType.transactionAudit => _db.transactionAuditEntries,
    SyncEntityType.financeCategory => _db.financeCategories,
    SyncEntityType.financeEntry => _db.financeEntries,
    SyncEntityType.exchangeRate => _db.exchangeRates,
    SyncEntityType.primaryCurrency => _db.primaryCurrencySettings,
    SyncEntityType.conflictResolution => _db.conflictResolutions,
    SyncEntityType.occasion => _db.occasions,
    SyncEntityType.budget => _db.budgets,
    SyncEntityType.budgetAllocation => _db.budgetCategoryAllocations,
    SyncEntityType.savingsGoal => _db.savingsGoals,
    SyncEntityType.savingsContribution => _db.savingsContributions,
    SyncEntityType.savingsContributionAudit => _db.savingsContributionAudits,
    SyncEntityType.financeEntryAudit => _db.financeEntryAudits,
  };
}
