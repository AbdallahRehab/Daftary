import 'dart:async';
import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/sync/local/conflict_resolver.dart';
import '../../../../core/sync/local/outbox_coalescer.dart' show OutboxStatus;
import '../../../../core/sync/local/sync_local_store.dart';
import '../../../../core/sync/local/sync_outbox.dart' show SyncRecordState;
import '../../../../core/sync/remote/cloud_auth_data_source.dart';
import '../../../../core/sync/remote/supabase_initializer.dart';
import '../../../../core/sync/remote/sync_error_mapper.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';
import '../../../../core/sync/sync_models.dart';
import '../../../../core/sync/sync_scheduler.dart';
import '../../../../core/sync/sync_trigger.dart';
import '../../domain/email_mask.dart';
import '../../domain/entities/sync_conflict_item.dart';
import '../../domain/entities/sync_failed_item.dart';
import '../../domain/entities/sync_runtime_status.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/cloud_sync_repository.dart';

/// 021: the cloud_sync repository: conflicts (T073), and the status,
/// switch, retry and email methods (T076). The only class that maps the core
/// sync types onto the cloud_sync domain.
@LazySingleton(as: CloudSyncRepository)
class CloudSyncRepositoryImpl implements CloudSyncRepository {
  CloudSyncRepositoryImpl(
    this._db,
    this._resolver,
    this._scheduler,
    this._store,
    this._auth,
    this._supabase,
  );

  final AppDatabase _db;
  final ConflictResolver _resolver;
  final SyncScheduler _scheduler;
  final SyncLocalStore _store;
  final CloudAuthDataSource _auth;
  final SupabaseInitializer _supabase;

  /// Ticks when the account changes (an email linked or signed in), so the
  /// status re-reads it.
  final _authChanges = StreamController<void>.broadcast();

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
  Stream<SyncStatus> watchStatus() {
    final subscriptions = <StreamSubscription<Object?>>[];
    late final StreamController<SyncStatus> controller;
    SchedulerState? runtime;
    SyncCounts? counts;
    SyncStateRow? state;
    var stateRead = false;

    void publish() {
      final r = runtime;
      final c = counts;
      if (r == null || c == null || !stateRead || controller.isClosed) return;
      controller.add(_statusOf(r, c, state));
    }

    controller = StreamController<SyncStatus>(
      onListen: () {
        subscriptions
          ..add(
            _scheduler.status.listen((value) {
              runtime = value;
              publish();
            }, onError: controller.addError),
          )
          ..add(
            _store.watchCounts().listen((value) {
              counts = value;
              publish();
            }, onError: controller.addError),
          )
          ..add(
            (_db.select(_db.syncState)..where((s) => s.id.equals(syncStateId)))
                .watchSingleOrNull()
                .listen((value) {
                  state = value;
                  stateRead = true;
                  publish();
                }, onError: controller.addError),
          )
          ..add(_authChanges.stream.listen((_) => publish()));
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream.distinct();
  }

  SyncStatus _statusOf(
    SchedulerState runtime,
    SyncCounts counts,
    SyncStateRow? state,
  ) {
    // The auth client exists only once the scheduler initialized Supabase;
    // before that the device has no account yet.
    final initialized = _supabase.isInitialized;
    final email = initialized ? _auth.currentEmail : null;
    final lastSuccessAt = state?.lastSuccessAt;
    return SyncStatus(
      runtime: _runtimeOf(runtime),
      enabled: state?.enabled ?? true,
      noticeShown: state?.noticeShown ?? false,
      pending: counts.pending,
      failed: counts.failed,
      conflicts: counts.conflicts,
      isAnonymous: !initialized || _auth.isAnonymous || email == null,
      available: _supabase.isConfigured,
      lastSuccessAt: lastSuccessAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastSuccessAt),
      linkedEmailMasked: email == null ? null : maskEmail(email),
      problem: state?.lastErrorCode == SyncErrorCode.downloadUnreadableRow
          ? SyncProblem.unreadableCloudData
          : null,
    );
  }

  static SyncRuntimeStatus _runtimeOf(SchedulerState state) => switch (state) {
    SchedulerState.idle => SyncRuntimeStatus.idle,
    SchedulerState.syncing => SyncRuntimeStatus.syncing,
    SchedulerState.offline => SyncRuntimeStatus.offline,
    SchedulerState.backingOff => SyncRuntimeStatus.backingOff,
    SchedulerState.authRequired => SyncRuntimeStatus.authRequired,
    SchedulerState.disabled => SyncRuntimeStatus.disabled,
  };

  @override
  Future<Either<Failure, Unit>> syncNow() async {
    try {
      _scheduler.request(SyncTrigger.manual);
      return const Right(unit);
    } catch (e) {
      return Left(UnknownFailure('Failed to request a sync: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setEnabled(bool enabled) async {
    try {
      // Persists the switch, then pauses (token refresh stopped) or
      // requests a cycle.
      await _scheduler.setEnabled(enabled);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to switch sync: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markNoticeShown() async {
    try {
      await _store.writeState((s) => s.copyWith(noticeShown: true));
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to record the notice: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> retryFailed() async {
    try {
      await _db.transaction(() async {
        await (_db.update(
          _db.syncOutboxEntries,
        )..where((o) => o.status.equals(OutboxStatus.failed))).write(
          const SyncOutboxEntriesCompanion(
            status: Value(OutboxStatus.pending),
            nextAttemptAt: Value(null),
          ),
        );
        await (_db.update(
          _db.syncRecordMeta,
        )..where((m) => m.state.equals(SyncRecordState.failed))).write(
          const SyncRecordMetaCompanion(state: Value(SyncRecordState.pending)),
        );
      });
      _scheduler.request(SyncTrigger.manual);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to retry the failed items: $e'));
    }
  }

  @override
  Stream<List<SyncFailedItem>> watchFailedItems() =>
      (_db.select(_db.syncOutboxEntries)
            ..where((o) => o.status.equals(OutboxStatus.failed))
            ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
          .watch()
          .map((rows) => [for (final row in rows) ?_failedItemOf(row)]);

  static SyncFailedItem? _failedItemOf(SyncOutboxRow row) {
    final kind = _kinds[row.entityType];
    if (kind == null) return null;
    return SyncFailedItem(
      kind: kind,
      entityId: row.entityId,
      reason: switch (row.errorCode) {
        PushRejectReason.personHasTransactions =>
          SyncFailedReason.personHasTransactions,
        PushRejectReason.categoryTypeMismatch =>
          SyncFailedReason.categoryTypeMismatch,
        PushRejectReason.validation ||
        PushRejectReason.unknownEntity => SyncFailedReason.invalid,
        _ => SyncFailedReason.other,
      },
    );
  }

  static final _kinds = {
    for (final type in SyncEntityType.values)
      type.wire: switch (type) {
        SyncEntityType.person => SyncItemKind.person,
        SyncEntityType.moneyTransaction => SyncItemKind.transaction,
        SyncEntityType.transactionAudit => SyncItemKind.transactionHistory,
        SyncEntityType.financeCategory => SyncItemKind.financeCategory,
        SyncEntityType.financeEntry => SyncItemKind.financeEntry,
        SyncEntityType.exchangeRate => SyncItemKind.exchangeRate,
        SyncEntityType.primaryCurrency => SyncItemKind.primaryCurrency,
        SyncEntityType.conflictResolution => SyncItemKind.conflictResolution,
        SyncEntityType.occasion => SyncItemKind.occasion,
        SyncEntityType.budget => SyncItemKind.budget,
        SyncEntityType.budgetAllocation => SyncItemKind.budgetAllocation,
      },
  };

  @override
  Future<Either<Failure, Unit>> requestEmailCode(
    String email, {
    required bool linkCurrent,
  }) => _emailStep(() async {
    if (linkCurrent) {
      await _auth.requestEmailLinkCode(email);
    } else {
      await _auth.requestSignInCode(email);
    }
  });

  @override
  Future<Either<Failure, Unit>> confirmEmailCode(
    String email,
    String code, {
    required bool linkCurrent,
  }) => _emailStep(() async {
    if (linkCurrent) {
      // The uid is unchanged: the data already belongs to this account.
      await _auth.confirmEmailLink(email, code);
    } else {
      // A new uid: the next cycle re-owns the local data (T069).
      await _auth.confirmSignIn(email, code);
    }
    _authChanges.add(null);
    _scheduler.request(SyncTrigger.manual);
  });

  /// The email steps talk to the cloud, so they need sync configured and
  /// switched on (Supabase is never initialized otherwise, plan §4).
  Future<Either<Failure, Unit>> _emailStep(Future<void> Function() step) async {
    try {
      if (!_supabase.isConfigured || !(await _store.readState()).enabled) {
        return const Left(ValidationFailure('Cloud sync is off'));
      }
      if (!await _supabase.ensureInitialized()) {
        return const Left(ValidationFailure('Cloud sync is not configured'));
      }
      await step();
      return const Right(unit);
    } on SyncRemoteException catch (e) {
      return Left(e.failure);
    } catch (e) {
      // Never the email itself: only the error type.
      return Left(UnknownFailure('Email step failed: ${e.runtimeType}'));
    }
  }
}
