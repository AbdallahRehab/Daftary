import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../database/app_database.dart' show Value;
import '../date/app_clock.dart';
import '../error/failure.dart';
import 'backoff_policy.dart';
import 'connectivity_monitor.dart';
import 'local/sync_local_store.dart';
import 'remote/cloud_auth_data_source.dart';
import 'remote/supabase_initializer.dart';
import 'remote/sync_error_mapper.dart';
import 'remote/sync_remote_data_source.dart';
import 'sync_entity_type.dart';
import 'sync_logger.dart';
import 'sync_models.dart';

/// How a sync cycle ended.
enum SyncCycleResult {
  /// Everything that could be sent was sent.
  completed,

  /// Sync is not configured or switched off; nothing was requested.
  disabled,

  /// The device reports no network; nothing was requested.
  offline,

  /// A whole call failed; the batch is back to `pending` and the next
  /// attempt waits for [SyncCycleOutcome.retryAfter].
  retryScheduled,

  /// The session is missing or refused; the cycle paused.
  authRequired,
}

class SyncCycleOutcome extends Equatable {
  const SyncCycleOutcome(this.result, {this.retryAfter, this.errorCode});

  static const completed = SyncCycleOutcome(SyncCycleResult.completed);
  static const disabled = SyncCycleOutcome(SyncCycleResult.disabled);
  static const offline = SyncCycleOutcome(SyncCycleResult.offline);

  final SyncCycleResult result;

  /// Set for [SyncCycleResult.retryScheduled].
  final Duration? retryAfter;
  final String? errorCode;

  @override
  List<Object?> get props => [result, retryAfter, errorCode];
}

/// The `p_platform` value for this device (`devices.platform` accepts
/// only `android` and `ios`, the two supported targets).
String syncDevicePlatform() =>
    defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

/// Supplied at build time next to the cloud config; diagnostics only.
const syncAppVersion = String.fromEnvironment(
  'DAFTARY_APP_VERSION',
  defaultValue: 'unknown',
);

/// 021: one sync cycle (plan §8). Push phase: US2 (T058) and the
/// initial-upload marker (T065). The pull phase and re-owning are T069.
///
/// Only the [SyncScheduler] calls [runCycle], and never twice at once.
/// Time comes from the injected [AppClock], never `DateTime.now()`.
@lazySingleton
class SyncEngine {
  SyncEngine(
    this._store,
    this._remote,
    this._auth,
    this._supabase,
    this._connectivity,
    this._backoff,
    this._logger,
    this._clock,
  );

  final SyncLocalStore _store;
  final SyncRemoteDataSource _remote;
  final CloudAuthDataSource _auth;
  final SupabaseInitializer _supabase;
  final ConnectivityMonitor _connectivity;
  final BackoffPolicy _backoff;
  final SyncLogger _logger;
  final AppClock _clock;

  /// research.md Decision 19.
  static const pushBatchSize = 100;

  /// A guard against a batch that never leaves `pending` (it cannot happen
  /// with a well-behaved server: every result removes or defers its op).
  static const maxBatchesPerCycle = 1000;

  /// Makes every deferred operation eligible (see `runCycle`).
  static final _farFuture = DateTime.utc(9999);

  /// Error code for an operation the server response did not mention.
  static const noResultErrorCode = 'no_result';

  /// Runs one cycle. With [ignoreBackoff] ("Sync now"), operations waiting
  /// for their retry time are sent at once.
  Future<SyncCycleOutcome> runCycle({bool ignoreBackoff = false}) async {
    if (!_supabase.isConfigured) return SyncCycleOutcome.disabled;
    final state = await _store.readState();
    if (!state.enabled) return SyncCycleOutcome.disabled;
    if (!await _connectivity.currentHasNetwork()) {
      return SyncCycleOutcome.offline;
    }

    final started = _clock.now();
    _logger.event(SyncEvent.syncStarted);
    await _store.writeState(
      (s) => s.copyWith(lastAttemptAt: Value(started.millisecondsSinceEpoch)),
    );

    try {
      await _auth.ensureSession();
    } on SyncRemoteException catch (error) {
      return _callFailed(error, const [], started);
    }
    // T069: compare the uid with sync_state.owner_id here (adopt or re-own).

    final device = DeviceInfo(
      deviceId: state.deviceId,
      platform: syncDevicePlatform(),
      appVersion: syncAppVersion,
    );

    var sessionRefreshed = false;
    var reachedServer = false;
    for (var i = 0; i < maxBatchesPerCycle; i++) {
      final batch = await _store.nextBatch(
        limit: pushBatchSize,
        now: ignoreBackoff ? _farFuture : _clock.now(),
      );
      if (batch.isEmpty) break;
      final ids = [for (final op in batch) op.opId];
      await _store.markInFlight(ids);
      _logger.event(
        SyncEvent.uploadStarted,
        fields: {SyncLogField.count: batch.length},
      );

      final List<PushResult> results;
      try {
        results = await _remote.push(batch, device);
      } on SyncRemoteException catch (error) {
        if (error.failure is UnauthorizedFailure && !sessionRefreshed) {
          // An expired token: refresh once and resend at once.
          sessionRefreshed = true;
          await _store.rescheduleBatch(ids, Duration.zero, error.errorCode);
          try {
            await _auth.refreshSession();
            continue;
          } on SyncRemoteException catch (refreshError) {
            return _callFailed(refreshError, const [], started);
          }
        }
        return _callFailed(error, ids, started);
      } catch (error) {
        // Not a cloud error (a bug or a local failure): never leave the
        // batch stuck in flight.
        await _store.rescheduleBatch(
          ids,
          _backoff.delayFor(0),
          SyncErrorCode.unknown,
        );
        _logger.event(
          SyncEvent.syncAborted,
          fields: {SyncLogField.errorCode: SyncErrorCode.unknown},
        );
        rethrow;
      }

      reachedServer = true;
      await _store.applyPushResults(results, _clock.now());
      final answered = {for (final r in results) r.opId};
      final unanswered = [
        for (final id in ids)
          if (!answered.contains(id)) id,
      ];
      if (unanswered.isNotEmpty) {
        await _store.rescheduleBatch(
          unanswered,
          _backoff.delayFor(0),
          noResultErrorCode,
        );
      }
      _logResults(batch, results);
    }

    // Only a call that reached the server proves it is reachable again:
    // a cycle that found nothing ready to send keeps the backoff count.
    await _store.writeState(
      (s) => s.copyWith(
        consecutiveFailures: reachedServer ? 0 : s.consecutiveFailures,
        lastSuccessAt: Value(_clock.now().millisecondsSinceEpoch),
        lastErrorCode: reachedServer
            ? const Value(null)
            : Value(s.lastErrorCode),
      ),
    );
    await _markInitialUploadIfDone();
    _logger.event(
      SyncEvent.syncCompleted,
      fields: {SyncLogField.durationMs: _elapsedMs(started)},
    );
    return SyncCycleOutcome.completed;
  }

  /// T065: once everything queued at upgrade (and since) has reached the
  /// server, the initial upload is complete. An empty outbox alone never
  /// re-triggers the bootstrap; `bootstrap_enqueued` guards that.
  Future<void> _markInitialUploadIfDone() async {
    final state = await _store.readState();
    if (!state.bootstrapEnqueued || state.initialUploadDone) return;
    if (await _store.openOpCount() > 0) return;
    await _store.writeState((s) => s.copyWith(initialUploadDone: true));
    final counts = await _store.syncedCountsByType();
    for (final type in SyncEntityType.values) {
      _logger.event(
        SyncEvent.uploadSuccess,
        fields: {
          SyncLogField.entityType: type.wire,
          SyncLogField.count: counts[type] ?? 0,
        },
      );
    }
  }

  /// A whole call failed: nothing in [opIds] was acknowledged.
  Future<SyncCycleOutcome> _callFailed(
    SyncRemoteException error,
    List<String> opIds,
    DateTime started,
  ) async {
    final code = error.errorCode;
    _logger.event(
      SyncEvent.uploadFailed,
      fields: {
        SyncLogField.errorCode: code,
        if (opIds.isNotEmpty) SyncLogField.count: opIds.length,
      },
    );

    if (error.requiresAuth) {
      // Paused until the session is valid again; no backoff is counted.
      await _store.rescheduleBatch(opIds, Duration.zero, code);
      await _store.writeState((s) => s.copyWith(lastErrorCode: Value(code)));
      _logger.event(
        SyncEvent.syncAborted,
        fields: {
          SyncLogField.errorCode: code,
          SyncLogField.durationMs: _elapsedMs(started),
        },
      );
      return SyncCycleOutcome(SyncCycleResult.authRequired, errorCode: code);
    }

    final failures = (await _store.readState()).consecutiveFailures + 1;
    final delay = _backoff.delayFor(failures - 1);
    await _store.rescheduleBatch(opIds, delay, code);
    await _store.writeState(
      (s) =>
          s.copyWith(consecutiveFailures: failures, lastErrorCode: Value(code)),
    );
    _logger.event(
      SyncEvent.retryScheduled,
      fields: {
        SyncLogField.errorCode: code,
        SyncLogField.delayMs: delay.inMilliseconds,
      },
    );
    _logger.event(
      SyncEvent.syncAborted,
      fields: {
        SyncLogField.errorCode: code,
        SyncLogField.durationMs: _elapsedMs(started),
      },
    );
    return SyncCycleOutcome(
      SyncCycleResult.retryScheduled,
      retryAfter: delay,
      errorCode: code,
    );
  }

  void _logResults(List<OutboxOp> batch, List<PushResult> results) {
    final byId = {for (final op in batch) op.opId: op};
    var acknowledged = 0;
    for (final result in results) {
      final type = byId[result.opId]?.entityType.wire;
      switch (result) {
        case PushApplied():
          acknowledged++;
        case PushConflict() || PushSuperseded():
          _logger.event(
            SyncEvent.conflict,
            fields: {SyncLogField.entityType: ?type},
          );
        case PushRejected(:final reason):
          _logger.event(
            result.isTransient
                ? SyncEvent.retryScheduled
                : SyncEvent.uploadFailed,
            fields: {
              SyncLogField.entityType: ?type,
              SyncLogField.errorCode: reason,
              SyncLogField.opId: result.opId,
            },
          );
      }
    }
    _logger.event(
      SyncEvent.uploadSuccess,
      fields: {SyncLogField.count: acknowledged},
    );
  }

  int _elapsedMs(DateTime started) =>
      _clock.now().difference(started).inMilliseconds;
}
