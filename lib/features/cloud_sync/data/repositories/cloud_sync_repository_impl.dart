import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/sync/local/conflict_resolver.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';
import '../../domain/entities/sync_conflict_item.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/cloud_sync_repository.dart';

/// 021: the cloud_sync repository. T073 implements the conflict part
/// ([watchConflicts], [resolveConflict], [watchHasConflict]); the status,
/// switch, retry and email methods are finished by T076.
@LazySingleton(as: CloudSyncRepository)
class CloudSyncRepositoryImpl implements CloudSyncRepository {
  CloudSyncRepositoryImpl(this._db, this._resolver);

  final AppDatabase _db;
  final ConflictResolver _resolver;

  static const _notYet = UnknownFailure('not yet implemented');

  // ---------------------------------------------------------------------------
  // Conflicts (T073)
  // ---------------------------------------------------------------------------

  @override
  Stream<List<SyncConflictItem>> watchConflicts() =>
      (_db.select(_db.syncConflicts)
            ..where((c) => c.resolvedAt.isNull())
            ..orderBy([(c) => OrderingTerm.asc(c.detectedAt)]))
          .watch()
          .map((rows) => [for (final row in rows) ?_toItem(row)]);

  @override
  Stream<bool> watchHasConflict(String entityType, String entityId) =>
      (_db.selectOnly(_db.syncConflicts)
            ..addColumns([_db.syncConflicts.id])
            ..where(
              _db.syncConflicts.entityType.equals(entityType) &
                  _db.syncConflicts.entityId.equals(entityId) &
                  _db.syncConflicts.resolvedAt.isNull(),
            ))
          .watch()
          .map((rows) => rows.isNotEmpty)
          .distinct();

  @override
  Future<Either<Failure, Unit>> resolveConflict(
    String entityType,
    String entityId,
    ConflictChoice choice,
  ) async {
    if (ConflictEntityType.tryFromWire(entityType) == null) {
      return Left(ValidationFailure('No manual conflicts for $entityType'));
    }
    final type = SyncEntityType.fromWire(entityType);
    try {
      switch (choice) {
        case ConflictChoice.keepMine:
          await _resolver.keepMine(type, entityId);
        case ConflictChoice.keepTheirs:
          await _resolver.keepTheirs(type, entityId);
      }
      return const Right(unit);
    } on NoOpenConflictException {
      return const Left(NotFoundFailure('No open conflict for this record'));
    } catch (e) {
      return Left(CacheFailure('Failed to resolve the conflict: $e'));
    }
  }

  /// Null for a record type that is never in a manual conflict.
  SyncConflictItem? _toItem(SyncConflictRow row) {
    final type = ConflictEntityType.tryFromWire(row.entityType);
    if (type == null) return null;
    return SyncConflictItem(
      entityType: type,
      entityId: row.entityId,
      localSummary: _version(type, row.localPayloadJson),
      serverSummary: _version(type, row.serverPayloadJson),
      detectedAt: DateTime.fromMillisecondsSinceEpoch(row.detectedAt),
    );
  }

  /// The compared fields of one wire payload (contracts/sync-rpc.md §1):
  /// money as a string (local) or a number (server).
  static ConflictVersion _version(ConflictEntityType type, String json) {
    final payload = (jsonDecode(json) as Map).cast<String, Object?>();
    final direction = switch (type) {
      ConflictEntityType.moneyTransaction =>
        SyncWire.string(payload, 'direction') == 'received'
            ? ConflictDirection.received
            : ConflictDirection.given,
      ConflictEntityType.financeEntry =>
        SyncWire.string(payload, 'type') == 'income'
            ? ConflictDirection.income
            : ConflictDirection.expense,
    };
    return ConflictVersion(
      amount: Money.fromMinorUnits(
        SyncWire.parseMoney(payload['amount_minor'], 'amount_minor'),
        Currency.fromCode(SyncWire.string(payload, 'currency_code')),
      ),
      date: DateTime.fromMillisecondsSinceEpoch(
        SyncWire.parseInstant(payload['occurred_at'], 'occurred_at'),
      ),
      direction: direction,
      note: SyncWire.stringOrNull(payload, 'note'),
      isDeleted: payload['deleted_at'] != null,
    );
  }

  // ---------------------------------------------------------------------------
  // Status, switch, retry and email (T076)
  // ---------------------------------------------------------------------------

  @override
  Stream<SyncStatus> watchStatus() => Stream.error(_notYet);

  @override
  Future<Either<Failure, Unit>> syncNow() async => const Left(_notYet);

  @override
  Future<Either<Failure, Unit>> setEnabled(bool enabled) async =>
      const Left(_notYet);

  @override
  Future<Either<Failure, Unit>> markNoticeShown() async => const Left(_notYet);

  @override
  Future<Either<Failure, Unit>> retryFailed() async => const Left(_notYet);

  @override
  Future<Either<Failure, Unit>> requestEmailCode(
    String email, {
    required bool linkCurrent,
  }) async => const Left(_notYet);

  @override
  Future<Either<Failure, Unit>> confirmEmailCode(
    String email,
    String code, {
    required bool linkCurrent,
  }) async => const Left(_notYet);
}
