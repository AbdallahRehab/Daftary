import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' hide coalesce;
import '../../date/app_clock.dart';
import '../backoff_policy.dart';
import '../sync_bootstrap.dart';
import '../sync_entity_type.dart';
import '../sync_models.dart';
import 'outbox_coalescer.dart';
import 'sync_applier.dart';
import 'sync_outbox.dart';

/// 021: the engine's view of the local sync tables
/// (contracts/dart-interfaces.md §1). Only the engine and the scheduler use
/// it; feature code records changes through `SyncOutbox`.
abstract class SyncLocalStore {
  /// Up to [limit] operations ready to send: `pending` with
  /// `next_attempt_at <= now`, ordered by rank then FIFO. An operation is
  /// skipped while its parent record (a transaction's person, an entry's
  /// category, an audit's transaction) has an operation that is `failed`,
  /// `blocked_conflict` or waiting for its retry time — only the dependents
  /// wait, nothing else.
  Future<List<OutboxOp>> nextBatch({required int limit, required DateTime now});

  /// Marks the batch as sent (`in_flight`) and counts the attempt.
  Future<void> markInFlight(List<String> opIds);

  /// Puts every `in_flight` operation back to `pending` — run on startup,
  /// because an app killed mid-upload leaves them there. The server ledger
  /// makes the replay safe. Also re-queues the interim
  /// `unhandled_conflict` operations (see [unhandledConflictErrorCode]).
  Future<void> resetInFlight();

  /// Applies one `sync_push` response in a single transaction
  /// (contracts/sync-rpc.md §5).
  Future<void> applyPushResults(List<PushResult> results, DateTime now);

  /// Puts the still-`in_flight` operations among [opIds] back to `pending`,
  /// eligible again after [delay].
  Future<void> rescheduleBatch(
    List<String> opIds,
    Duration delay,
    String errorCode,
  );

  /// The `sync_state` row, created with a new device id on first read.
  Future<SyncStateRow> readState();

  /// Replaces the `sync_state` row with `update(current)`.
  Future<void> writeState(SyncStateRow Function(SyncStateRow) update);

  /// Pending, failed and conflict counts from `sync_record_meta`.
  Stream<SyncCounts> watchCounts();

  /// The number of operations still in the outbox, whatever their status.
  Future<int> openOpCount();

  /// The number of `synced` records per entity type.
  Future<Map<SyncEntityType, int>> syncedCountsByType();

  /// T069: the session now belongs to another account ([ownerId]). In one
  /// transaction, every local record is queued again for that account (the
  /// bootstrap with `force: true`), the download cursor goes back to 0 and
  /// the new owner is stored. Local data is never deleted. Returns the
  /// number of operations queued.
  Future<int> reown(String ownerId);
}

/// The `error_code` of an operation blocked by a manual conflict.
const conflictErrorCode = 'conflict';

/// The `error_code` builds before T071 stored for `conflict` and
/// `superseded` results (kept as `failed`, never dropped). [resetInFlight]
/// re-queues such operations: the server ledger replays the same result for
/// the same `op_id`, with the current server row, so they become
/// `sync_conflicts` rows or restored records on the next cycle.
const unhandledConflictErrorCode = 'unhandled_conflict';

/// The fixed id of the single `sync_state` row.
const syncStateId = 'singleton';

@LazySingleton(as: SyncLocalStore)
class DriftSyncLocalStore implements SyncLocalStore {
  DriftSyncLocalStore(
    this._db,
    this._clock,
    this._backoff,
    this._applier,
    this._bootstrap,
  );

  final AppDatabase _db;
  final AppClock _clock;
  final BackoffPolicy _backoff;
  final SyncApplier _applier;
  final SyncBootstrap _bootstrap;

  static const _uuid = Uuid();

  /// How many candidate rows [nextBatch] reads at a time.
  static const _scanChunk = 200;

  $SyncOutboxEntriesTable get _outbox => _db.syncOutboxEntries;

  @override
  Future<List<OutboxOp>> nextBatch({
    required int limit,
    required DateTime now,
  }) async {
    final nowMs = now.millisecondsSinceEpoch;

    // Entities whose open operation cannot go now. Their dependents wait.
    final waiting =
        await (_db.select(_outbox)..where(
              (o) =>
                  o.status.isIn(const [
                    OutboxStatus.failed,
                    OutboxStatus.blockedConflict,
                  ]) |
                  (o.status.equals(OutboxStatus.pending) &
                      o.nextAttemptAt.isBiggerThanValue(nowMs)),
            ))
            .get();
    final blocked = {for (final o in waiting) _key(o.entityType, o.entityId)};
    // A record in conflict sends nothing more until the user resolves it.
    final inConflict = {
      for (final o in waiting)
        if (o.status == OutboxStatus.blockedConflict)
          _key(o.entityType, o.entityId),
    };

    final batch = <OutboxOp>[];
    var offset = 0;
    while (batch.length < limit) {
      final rows =
          await (_db.select(_outbox)
                ..where(
                  (o) =>
                      o.status.equals(OutboxStatus.pending) &
                      (o.nextAttemptAt.isNull() |
                          o.nextAttemptAt.isSmallerOrEqualValue(nowMs)),
                )
                ..orderBy([
                  (o) => OrderingTerm.asc(o.dependsOnRank),
                  (o) => OrderingTerm.asc(o.createdAt),
                  (o) => OrderingTerm.asc(o.rowId),
                ])
                ..limit(_scanChunk, offset: offset))
              .get();
      if (rows.isEmpty) break;
      offset += rows.length;

      for (final row in rows) {
        final op = _toOp(row);
        final own = _key(row.entityType, row.entityId);
        final parent = _parentKey(op);
        if (inConflict.contains(own) ||
            (parent != null && blocked.contains(parent))) {
          // Transitively block this record's own dependents too.
          blocked.add(own);
          continue;
        }
        batch.add(op);
        if (batch.length == limit) break;
      }
      if (rows.length < _scanChunk) break;
    }
    return batch;
  }

  @override
  Future<void> markInFlight(List<String> opIds) async {
    if (opIds.isEmpty) return;
    final nowMs = _clock.now().millisecondsSinceEpoch;
    await (_db.update(_outbox)..where((o) => o.opId.isIn(opIds))).write(
      SyncOutboxEntriesCompanion.custom(
        status: const Constant(OutboxStatus.inFlight),
        attemptCount: _outbox.attemptCount + const Constant(1),
        lastAttemptAt: Constant(nowMs),
      ),
    );
  }

  @override
  Future<void> resetInFlight() {
    return _db.transaction(() async {
      await (_db.update(
        _outbox,
      )..where((o) => o.status.equals(OutboxStatus.inFlight))).write(
        const SyncOutboxEntriesCompanion(status: Value(OutboxStatus.pending)),
      );
      await _requeueUnhandledConflicts();
    });
  }

  /// Migrates the interim `unhandled_conflict` rows (see
  /// [unhandledConflictErrorCode]): replaying the same `op_id` returns the
  /// stored conflict or superseded result with the current server row.
  Future<void> _requeueUnhandledConflicts() async {
    final legacy =
        await (_db.select(_outbox)..where(
              (o) =>
                  o.status.equals(OutboxStatus.failed) &
                  o.errorCode.equals(unhandledConflictErrorCode),
            ))
            .get();
    for (final op in legacy) {
      await (_db.update(_outbox)..where((o) => o.opId.equals(op.opId))).write(
        const SyncOutboxEntriesCompanion(
          status: Value(OutboxStatus.pending),
          nextAttemptAt: Value(null),
          errorCode: Value(null),
        ),
      );
      final meta = await _metaFor(op.entityType, op.entityId);
      if (meta?.state == SyncRecordState.failed) {
        await _writeMeta(
          op.entityType,
          op.entityId,
          SyncRecordState.pending,
          meta?.serverRevision,
          lastSyncedAt: meta?.lastSyncedAt,
        );
      }
    }
  }

  @override
  Future<void> applyPushResults(List<PushResult> results, DateTime now) {
    final nowMs = now.millisecondsSinceEpoch;
    return _db.transaction(() async {
      for (final result in results) {
        final op = await (_db.select(
          _outbox,
        )..where((o) => o.opId.equals(result.opId))).getSingleOrNull();
        if (op == null) continue;
        final type = SyncEntityType.fromWire(op.entityType);
        switch (result) {
          case PushApplied(:final revision, :final serverRow):
            await _acknowledge(op, revision, nowMs);
            // A category archived instead of deleted: re-inserted locally.
            if (serverRow != null) {
              await _applier.applyServerRow(type, serverRow);
            }
          case PushConflict(:final revision, :final serverRow):
            await _block(op, revision, serverRow, nowMs);
          case PushSuperseded(:final revision, :final serverRow):
            // The delete lost to a concurrent edit: the record is restored.
            await _acknowledge(op, revision, nowMs);
            await _applier.applyServerRow(type, serverRow);
          case PushRejected(:final reason, :final serverRow, :final revision)
              when reason == PushRejectReason.personHasTransactions &&
                  serverRow != null:
            // Restored now, not on the next pull: the cursor may already be
            // past this revision.
            await _acknowledge(op, revision, nowMs);
            await _applier.applyServerRow(type, serverRow);
          case PushRejected(:final reason) when result.isTransient:
            final delay = _backoff.delayFor(op.attemptCount - 1);
            await _reschedule(op.opId, nowMs + delay.inMilliseconds, reason);
          case PushRejected(:final reason):
            await _fail(op, reason, nowMs);
        }
      }
    });
  }

  /// `conflict` (contracts/sync-rpc.md §5): the operation waits for the
  /// user, and both versions are kept in `sync_conflicts`.
  Future<void> _block(
    SyncOutboxRow op,
    int serverRevision,
    Map<String, Object?> serverRow,
    int nowMs,
  ) async {
    await (_db.update(_outbox)..where((o) => o.opId.equals(op.opId))).write(
      SyncOutboxEntriesCompanion(
        status: const Value(OutboxStatus.blockedConflict),
        errorCode: const Value(conflictErrorCode),
        lastAttemptAt: Value(nowMs),
        nextAttemptAt: const Value(null),
      ),
    );

    final open =
        await (_db.select(_db.syncConflicts)..where(
              (c) =>
                  c.entityType.equals(op.entityType) &
                  c.entityId.equals(op.entityId) &
                  c.resolvedAt.isNull(),
            ))
            .getSingleOrNull();
    final serverJson = jsonEncode(serverRow);
    if (open == null) {
      await _db
          .into(_db.syncConflicts)
          .insert(
            SyncConflictsCompanion.insert(
              id: _uuid.v4(),
              entityType: op.entityType,
              entityId: op.entityId,
              localPayloadJson: op.payloadJson,
              serverPayloadJson: serverJson,
              serverRevision: serverRevision,
              detectedAt: nowMs,
            ),
          );
    } else {
      await (_db.update(
        _db.syncConflicts,
      )..where((c) => c.id.equals(open.id))).write(
        SyncConflictsCompanion(
          localPayloadJson: Value(op.payloadJson),
          serverPayloadJson: Value(serverJson),
          serverRevision: Value(serverRevision),
        ),
      );
    }

    final meta = await _metaFor(op.entityType, op.entityId);
    await _writeMeta(
      op.entityType,
      op.entityId,
      SyncRecordState.conflict,
      meta?.serverRevision,
      lastSyncedAt: meta?.lastSyncedAt,
    );
  }

  Future<void> _acknowledge(SyncOutboxRow op, int? revision, int nowMs) async {
    await (_db.delete(_outbox)..where((o) => o.opId.equals(op.opId))).go();

    final meta = await _metaFor(op.entityType, op.entityId);
    final serverRevision = revision ?? meta?.serverRevision;
    final others =
        await (_db.select(_outbox)..where(
              (o) =>
                  o.entityType.equals(op.entityType) &
                  o.entityId.equals(op.entityId),
            ))
            .get();

    if (others.isEmpty) {
      await _writeMeta(
        op.entityType,
        op.entityId,
        SyncRecordState.synced,
        serverRevision,
        lastSyncedAt: nowMs,
      );
      return;
    }

    // A change made while this one was in flight was queued against the
    // previous revision. It follows our own write, so it is rebased onto
    // the revision the server just confirmed — otherwise the server would
    // report our own write as a conflict.
    if (serverRevision != null) {
      await (_db.update(_outbox)..where(
            (o) =>
                o.entityType.equals(op.entityType) &
                o.entityId.equals(op.entityId) &
                o.status.equals(OutboxStatus.pending),
          ))
          .write(
            SyncOutboxEntriesCompanion(baseRevision: Value(serverRevision)),
          );
    }
    final statuses = {for (final o in others) o.status};
    await _writeMeta(
      op.entityType,
      op.entityId,
      statuses.contains(OutboxStatus.blockedConflict)
          ? SyncRecordState.conflict
          : statuses.contains(OutboxStatus.failed)
          ? SyncRecordState.failed
          : SyncRecordState.pending,
      serverRevision,
      lastSyncedAt: nowMs,
    );
  }

  Future<void> _fail(SyncOutboxRow op, String errorCode, int nowMs) async {
    await (_db.update(_outbox)..where((o) => o.opId.equals(op.opId))).write(
      SyncOutboxEntriesCompanion(
        status: const Value(OutboxStatus.failed),
        errorCode: Value(errorCode),
        lastAttemptAt: Value(nowMs),
        nextAttemptAt: const Value(null),
      ),
    );
    final meta = await _metaFor(op.entityType, op.entityId);
    await _writeMeta(
      op.entityType,
      op.entityId,
      SyncRecordState.failed,
      meta?.serverRevision,
      lastSyncedAt: meta?.lastSyncedAt,
    );
  }

  Future<void> _reschedule(String opId, int nextAttemptAt, String code) =>
      (_db.update(_outbox)..where((o) => o.opId.equals(opId))).write(
        SyncOutboxEntriesCompanion(
          status: const Value(OutboxStatus.pending),
          nextAttemptAt: Value(nextAttemptAt),
          errorCode: Value(code),
        ),
      );

  @override
  Future<void> rescheduleBatch(
    List<String> opIds,
    Duration delay,
    String errorCode,
  ) async {
    if (opIds.isEmpty) return;
    final nowMs = _clock.now().millisecondsSinceEpoch;
    await (_db.update(_outbox)..where(
          (o) => o.opId.isIn(opIds) & o.status.equals(OutboxStatus.inFlight),
        ))
        .write(
          SyncOutboxEntriesCompanion(
            status: const Value(OutboxStatus.pending),
            nextAttemptAt: Value(nowMs + delay.inMilliseconds),
            errorCode: Value(errorCode),
          ),
        );
  }

  @override
  Future<SyncStateRow> readState() async {
    final existing = await _selectState();
    if (existing != null) return existing;
    await _db
        .into(_db.syncState)
        .insert(
          SyncStateCompanion.insert(id: syncStateId, deviceId: _uuid.v4()),
          mode: InsertMode.insertOrIgnore,
        );
    return (await _selectState())!;
  }

  Future<SyncStateRow?> _selectState() => (_db.select(
    _db.syncState,
  )..where((s) => s.id.equals(syncStateId))).getSingleOrNull();

  @override
  Future<void> writeState(SyncStateRow Function(SyncStateRow) update) {
    return _db.transaction(() async {
      final current = await readState();
      await _db
          .into(_db.syncState)
          .insertOnConflictUpdate(
            // nullToAbsent: false, so a field set back to null is written.
            update(current).copyWith(id: syncStateId).toCompanion(false),
          );
    });
  }

  @override
  Stream<SyncCounts> watchCounts() {
    return _db
        .customSelect(
          'SELECT state, COUNT(*) AS c FROM sync_record_meta GROUP BY state',
          readsFrom: {_db.syncRecordMeta},
        )
        .watch()
        .map((rows) {
          final byState = {
            for (final row in rows)
              row.read<String>('state'): row.read<int>('c'),
          };
          return SyncCounts(
            pending: byState[SyncRecordState.pending] ?? 0,
            failed: byState[SyncRecordState.failed] ?? 0,
            conflicts: byState[SyncRecordState.conflict] ?? 0,
          );
        })
        .distinct();
  }

  @override
  Future<int> openOpCount() async {
    final count = _outbox.opId.count();
    final row = await (_db.selectOnly(
      _outbox,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<Map<SyncEntityType, int>> syncedCountsByType() async {
    final rows = await _db
        .customSelect(
          'SELECT entity_type, COUNT(*) AS c FROM sync_record_meta '
          'WHERE state = ? GROUP BY entity_type',
          variables: [Variable.withString(SyncRecordState.synced)],
          readsFrom: {_db.syncRecordMeta},
        )
        .get();
    return {
      for (final row in rows)
        SyncEntityType.fromWire(row.read<String>('entity_type')): row.read<int>(
          'c',
        ),
    };
  }

  @override
  Future<int> reown(String ownerId) {
    return _db.transaction(() async {
      final queued = await _bootstrap.enqueueExistingDataIfNeeded(
        _db,
        force: true,
      );
      await writeState(
        (s) => s.copyWith(
          ownerId: Value(ownerId),
          lastPulledRevision: 0,
          initialUploadDone: false,
        ),
      );
      return queued;
    });
  }

  Future<SyncRecordMetaRow?> _metaFor(String type, String id) =>
      (_db.select(_db.syncRecordMeta)
            ..where((m) => m.entityType.equals(type) & m.entityId.equals(id)))
          .getSingleOrNull();

  Future<void> _writeMeta(
    String type,
    String id,
    String state,
    int? serverRevision, {
    int? lastSyncedAt,
  }) => _db
      .into(_db.syncRecordMeta)
      .insertOnConflictUpdate(
        SyncRecordMetaCompanion.insert(
          entityType: type,
          entityId: id,
          state: state,
          serverRevision: Value(serverRevision),
          lastSyncedAt: Value(lastSyncedAt),
        ),
      );

  static String _key(String type, String id) => '$type|$id';

  /// The record an operation depends on, as a [_key].
  static String? _parentKey(OutboxOp op) {
    final (parentType, field) = switch (op.entityType) {
      SyncEntityType.moneyTransaction => (SyncEntityType.person, 'person_id'),
      SyncEntityType.financeEntry => (
        SyncEntityType.financeCategory,
        'category_id',
      ),
      SyncEntityType.transactionAudit => (
        SyncEntityType.moneyTransaction,
        'transaction_id',
      ),
      SyncEntityType.savingsContribution => (
        SyncEntityType.savingsGoal,
        'goal_id',
      ),
      SyncEntityType.savingsContributionAudit => (
        SyncEntityType.savingsContribution,
        'contribution_id',
      ),
      _ => (null, null),
    };
    if (parentType == null) return null;
    final parentId = op.payload[field];
    return parentId is String ? _key(parentType.wire, parentId) : null;
  }

  static OutboxOp _toOp(SyncOutboxRow row) => OutboxOp(
    opId: row.opId,
    entityType: SyncEntityType.fromWire(row.entityType),
    entityId: row.entityId,
    opType: OutboxOpType.fromWire(row.opType),
    payload: (jsonDecode(row.payloadJson) as Map).cast<String, Object?>(),
    baseRevision: row.baseRevision,
    attemptCount: row.attemptCount,
    createdAt: row.createdAt,
  );
}
