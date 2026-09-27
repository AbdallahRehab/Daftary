import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' hide coalesce;
import '../../date/app_clock.dart';
import '../sync_entity_type.dart';
import '../sync_mapper_registry.dart';
import 'outbox_coalescer.dart';
import 'sync_applier.dart';
import 'sync_outbox.dart';

/// The side the user kept when resolving a conflict, as stored in
/// `conflict_resolutions.chosen_side`.
enum ConflictSide {
  local('local'),
  server('server');

  const ConflictSide(this.wire);

  final String wire;
}

/// Thrown when there is no open conflict for the record.
class NoOpenConflictException implements Exception {
  const NoOpenConflictException();

  @override
  String toString() => 'NoOpenConflictException';
}

/// 021 T072: resolves a manual conflict on a financial record
/// (contracts/sync-rpc.md §6). Each resolution runs in one transaction,
/// closes the blocked operation, sets `sync_conflicts.resolved_at`, and
/// writes one `conflict_resolutions` record — queued for upload through
/// [SyncOutbox] — holding the discarded version. No version is ever lost.
abstract class ConflictResolver {
  /// Keeps the local version: it is queued again against the server
  /// revision it conflicted with, so the server accepts it.
  Future<void> keepMine(SyncEntityType type, String entityId);

  /// Keeps the server version: it is applied locally, and the local change
  /// is not uploaded. Audit entries recorded for the local edit stay queued
  /// unchanged (spec FR-035).
  Future<void> keepTheirs(SyncEntityType type, String entityId);
}

@LazySingleton(as: ConflictResolver)
class DriftConflictResolver implements ConflictResolver {
  DriftConflictResolver(
    this._db,
    this._outbox,
    this._applier,
    this._mappers,
    this._clock,
  );

  final AppDatabase _db;
  final SyncOutbox _outbox;
  final SyncApplier _applier;
  final SyncMapperRegistry _mappers;
  final AppClock _clock;

  static const _uuid = Uuid();

  @override
  Future<void> keepMine(SyncEntityType type, String entityId) {
    return _db.transaction(() async {
      final conflict = await _openConflict(type, entityId);
      final ops = await _openOps(type, entityId);
      final pending = _newestPending(ops);
      final localJson = pending?.payloadJson ?? conflict.localPayloadJson;
      final nowMs = _clock.now().millisecondsSinceEpoch;

      await _deleteOps([
        for (final op in ops)
          if (op.status == OutboxStatus.blockedConflict) op.opId,
      ]);
      if (pending != null) {
        // A later local edit already carries the newest local version.
        await (_db.update(
          _db.syncOutboxEntries,
        )..where((o) => o.opId.equals(pending.opId))).write(
          SyncOutboxEntriesCompanion(
            baseRevision: Value(conflict.serverRevision),
          ),
        );
      } else {
        await _db
            .into(_db.syncOutboxEntries)
            .insert(
              SyncOutboxEntriesCompanion.insert(
                opId: _uuid.v4(),
                entityType: type.wire,
                entityId: entityId,
                opType: OutboxOpType.upsert.wire,
                payloadJson: localJson,
                baseRevision: Value(conflict.serverRevision),
                dependsOnRank: type.rank,
                status: OutboxStatus.pending,
                createdAt: nowMs,
              ),
            );
      }
      await _db
          .into(_db.syncRecordMeta)
          .insertOnConflictUpdate(
            SyncRecordMetaCompanion.insert(
              entityType: type.wire,
              entityId: entityId,
              state: SyncRecordState.pending,
              serverRevision: Value(conflict.serverRevision),
            ),
          );

      await _record(
        type,
        entityId,
        ConflictSide.local,
        conflict.serverPayloadJson,
        nowMs,
      );
      await _close(conflict, nowMs);
    });
  }

  @override
  Future<void> keepTheirs(SyncEntityType type, String entityId) {
    return _db.transaction(() async {
      final conflict = await _openConflict(type, entityId);
      final ops = await _openOps(type, entityId);
      final localJson =
          _newestPending(ops)?.payloadJson ?? conflict.localPayloadJson;
      final nowMs = _clock.now().millisecondsSinceEpoch;

      // Every queued change of this record is discarded — it is kept in the
      // resolution record below. Other records (its audit entries) are
      // untouched.
      await _deleteOps([for (final op in ops) op.opId]);
      final server = (jsonDecode(conflict.serverPayloadJson) as Map)
          .cast<String, Object?>();
      await _applier.applyServerRow(type, {
        ...server,
        'revision': conflict.serverRevision,
      });

      await _record(type, entityId, ConflictSide.server, localJson, nowMs);
      await _close(conflict, nowMs);
    });
  }

  Future<SyncConflictRow> _openConflict(
    SyncEntityType type,
    String entityId,
  ) async {
    final conflict =
        await (_db.select(_db.syncConflicts)..where(
              (c) =>
                  c.entityType.equals(type.wire) &
                  c.entityId.equals(entityId) &
                  c.resolvedAt.isNull(),
            ))
            .getSingleOrNull();
    if (conflict == null) throw const NoOpenConflictException();
    return conflict;
  }

  Future<List<SyncOutboxRow>> _openOps(SyncEntityType type, String entityId) =>
      (_db.select(_db.syncOutboxEntries)
            ..where(
              (o) =>
                  o.entityType.equals(type.wire) & o.entityId.equals(entityId),
            )
            ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
          .get();

  static SyncOutboxRow? _newestPending(List<SyncOutboxRow> ops) {
    SyncOutboxRow? newest;
    for (final op in ops) {
      if (op.status == OutboxStatus.pending) newest = op;
    }
    return newest;
  }

  Future<void> _deleteOps(List<String> opIds) async {
    if (opIds.isEmpty) return;
    await (_db.delete(
      _db.syncOutboxEntries,
    )..where((o) => o.opId.isIn(opIds))).go();
  }

  /// The synced, append-only record of the decision (research.md
  /// Decision 8), holding the discarded version.
  Future<void> _record(
    SyncEntityType type,
    String entityId,
    ConflictSide side,
    String discardedJson,
    int nowMs,
  ) async {
    final id = _uuid.v4();
    await _db
        .into(_db.conflictResolutions)
        .insert(
          ConflictResolutionsCompanion.insert(
            id: id,
            entityType: type.wire,
            entityId: entityId,
            chosenSide: side.wire,
            discardedValuesJson: discardedJson,
            resolvedAt: nowMs,
          ),
        );
    final row = await (_db.select(
      _db.conflictResolutions,
    )..where((r) => r.id.equals(id))).getSingle();
    await _outbox.recordUpsert(
      SyncEntityType.conflictResolution,
      id,
      _mappers.mapperFor(SyncEntityType.conflictResolution).toWire(row),
    );
  }

  Future<void> _close(SyncConflictRow conflict, int nowMs) =>
      (_db.update(_db.syncConflicts)..where((c) => c.id.equals(conflict.id)))
          .write(SyncConflictsCompanion(resolvedAt: Value(nowMs)));
}
