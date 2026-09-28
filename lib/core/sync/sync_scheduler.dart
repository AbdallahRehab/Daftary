import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../database/app_database.dart';
import '../database/watch_tables.dart';
import '../date/app_clock.dart';
import 'backoff_policy.dart';
import 'connectivity_monitor.dart';
import 'local/sync_local_store.dart';
import 'remote/supabase_initializer.dart';
import 'sync_engine.dart';
import 'sync_logger.dart';
import 'sync_trigger.dart';

/// 021: the single-flight gate in front of [SyncEngine] (plan §8,
/// FR-018/019/053).
///
/// Every trigger calls [request]. At most one cycle runs at a time; a
/// request that arrives during a cycle schedules exactly one follow-up.
/// While sync is unconfigured or switched off the scheduler reports
/// `disabled`, never initializes Supabase and sends nothing.
@lazySingleton
class SyncScheduler {
  SyncScheduler(
    this._engine,
    this._store,
    this._supabase,
    this._connectivity,
    this._db,
    this._backoff,
    this._logger,
    this._clock,
  );

  final SyncEngine _engine;
  final SyncLocalStore _store;
  final SupabaseInitializer _supabase;
  final ConnectivityMonitor _connectivity;
  final AppDatabase _db;
  final BackoffPolicy _backoff;
  final SyncLogger _logger;
  final AppClock _clock;

  /// research.md Decision 19.
  static const writeDebounce = Duration(seconds: 3);
  static const periodicInterval = Duration(minutes: 5);

  /// A network that comes back must stay up this long before it triggers a
  /// cycle, so a flapping connection produces one request, not ten.
  static const networkSettle = Duration(seconds: 2);

  final _statusController = StreamController<SchedulerState>.broadcast();
  SchedulerState _status = SchedulerState.idle;

  bool _started = false;
  bool _disposed = false;
  Future<void>? _running;
  bool _rerunRequested = false;
  SyncTrigger? _rerunTrigger;

  /// While positive, [runExclusive] holds new cycles off; the first request
  /// made meanwhile is replayed once afterwards.
  int _exclusive = 0;
  SyncTrigger? _heldTrigger;

  /// No automatic request runs before this instant (persisted backoff).
  DateTime? _backoffUntil;
  Timer? _backoffTimer;
  Timer? _periodic;
  Timer? _writeDebounce;
  Timer? _networkDebounce;
  AppLifecycleListener? _lifecycle;
  StreamSubscription<bool>? _networkSub;
  StreamSubscription<void>? _outboxSub;
  bool? _lastHasNetwork;

  /// The current status, then every change.
  Stream<SchedulerState> get status async* {
    yield _status;
    yield* _statusController.stream;
  }

  SchedulerState get currentStatus => _status;

  /// Resets interrupted uploads, installs the triggers and requests the
  /// launch cycle. Idempotent. Call it only after startup is ready.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    if (!_supabase.isConfigured) {
      _setStatus(SchedulerState.disabled);
      return;
    }

    await _store.resetInFlight();
    final state = await _store.readState();
    _restoreBackoff(state);
    _lastHasNetwork = await _connectivity.currentHasNetwork();
    if (_disposed) return;

    _lifecycle = AppLifecycleListener(
      onResume: _onResume,
      onHide: _stopPeriodic,
      onPause: _stopPeriodic,
    );
    _networkSub = _connectivity.hasNetwork.listen(_onNetwork);
    // The first event is the immediate one; only writes count.
    _outboxSub = _db
        .changesOf({_db.syncOutboxEntries})
        .skip(1)
        .listen((_) => _onOutboxChanged());
    _startPeriodic();
    request(SyncTrigger.launch);
  }

  /// Asks for a cycle. Coalesces: never runs two cycles at once, and any
  /// number of requests during a cycle produce one follow-up.
  void request(SyncTrigger trigger) {
    if (!_started || _disposed) return;
    if (_exclusive > 0) {
      _heldTrigger ??= trigger;
      return;
    }
    if (_running != null) {
      _rerunRequested = true;
      // A manual request keeps its right to skip a backoff delay.
      if (trigger == SyncTrigger.manual || _rerunTrigger == null) {
        _rerunTrigger = trigger;
      }
      return;
    }
    _running = _loop(trigger).whenComplete(() => _running = null);
  }

  /// Completes when the current cycle (and its follow-up) has finished.
  Future<void> get idle => _running ?? Future.value();

  /// Runs [action] with no cycle in flight and none able to start: waits
  /// for the current cycle to finish first. For a device wipe (013/015),
  /// which must never interleave with an upload or a download. With
  /// [resetBackoff], a backoff remembered from before [action] is dropped
  /// too — after a wipe it belonged to data and a session that are gone.
  Future<T> runExclusive<T>(
    Future<T> Function() action, {
    bool resetBackoff = false,
  }) async {
    _exclusive++;
    try {
      await idle;
      final result = await action();
      if (resetBackoff) _clearBackoff();
      return result;
    } finally {
      _exclusive--;
      final held = _heldTrigger;
      if (_exclusive == 0 && held != null) {
        _heldTrigger = null;
        request(held);
      }
    }
  }

  /// Applies the sync switch (FR-041): persists it, then stops or restarts
  /// the token refresh, so no request leaves the device while it is off.
  Future<void> setEnabled(bool enabled) async {
    await _store.writeState((s) => s.copyWith(enabled: enabled));
    if (!enabled) {
      _supabase.stopAutoRefresh();
      _setStatus(SchedulerState.disabled);
      return;
    }
    _supabase.startAutoRefresh();
    _setStatus(SchedulerState.idle);
    request(SyncTrigger.enabled);
  }

  Future<void> dispose() async {
    _disposed = true;
    _backoffTimer?.cancel();
    _periodic?.cancel();
    _writeDebounce?.cancel();
    _networkDebounce?.cancel();
    _lifecycle?.dispose();
    await _networkSub?.cancel();
    await _outboxSub?.cancel();
    await _running;
    unawaited(_statusController.close());
  }

  Future<void> _loop(SyncTrigger trigger) async {
    var current = trigger;
    while (true) {
      _rerunRequested = false;
      _rerunTrigger = null;
      await _runOnce(current);
      if (!_rerunRequested || _disposed) return;
      current = _rerunTrigger ?? SyncTrigger.localWrite;
    }
  }

  Future<void> _runOnce(SyncTrigger trigger) async {
    try {
      if (!_supabase.isConfigured) {
        _setStatus(SchedulerState.disabled);
        return;
      }
      final state = await _store.readState();
      if (!state.enabled) {
        // Supabase is never initialized while sync is off.
        _setStatus(SchedulerState.disabled);
        return;
      }
      final until = _backoffUntil;
      if (until != null &&
          trigger != SyncTrigger.manual &&
          _clock.now().isBefore(until)) {
        // Connectivity flaps and writes never shorten a backoff (FR-053).
        _setStatus(SchedulerState.backingOff);
        _armBackoffTimer(until);
        return;
      }
      if (!await _connectivity.currentHasNetwork()) {
        _setStatus(SchedulerState.offline);
        return;
      }
      if (!await _supabase.ensureInitialized()) {
        _setStatus(SchedulerState.disabled);
        return;
      }

      _setStatus(SchedulerState.syncing);
      final outcome = await _engine.runCycle(
        ignoreBackoff: trigger == SyncTrigger.manual,
      );
      _applyOutcome(outcome);
    } catch (_) {
      // A local failure (or a bug): back off rather than spin.
      _logger.event(
        SyncEvent.syncAborted,
        fields: const {SyncLogField.errorCode: 'local'},
      );
      _enterBackoff(_backoff.delayFor(0));
    }
  }

  void _applyOutcome(SyncCycleOutcome outcome) {
    switch (outcome.result) {
      case SyncCycleResult.completed:
        _clearBackoff();
        _setStatus(SchedulerState.idle);
      case SyncCycleResult.disabled:
        _setStatus(SchedulerState.disabled);
      case SyncCycleResult.offline:
        _setStatus(SchedulerState.offline);
      case SyncCycleResult.authRequired:
        _setStatus(SchedulerState.authRequired);
      case SyncCycleResult.retryScheduled:
        _enterBackoff(outcome.retryAfter ?? _backoff.delayFor(0));
    }
  }

  void _enterBackoff(Duration delay) {
    final until = _clock.now().add(delay);
    _backoffUntil = until;
    _setStatus(SchedulerState.backingOff);
    _armBackoffTimer(until);
  }

  void _armBackoffTimer(DateTime until) {
    _backoffTimer?.cancel();
    final wait = until.difference(_clock.now());
    _backoffTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
      _backoffUntil = null;
      request(SyncTrigger.backoffElapsed);
    });
  }

  void _clearBackoff() {
    _backoffUntil = null;
    _backoffTimer?.cancel();
    _backoffTimer = null;
  }

  /// Backoff persists across restarts: `consecutive_failures` and the last
  /// attempt time are stored in `sync_state`.
  void _restoreBackoff(SyncStateRow state) {
    final failures = state.consecutiveFailures;
    final lastAttemptAt = state.lastAttemptAt;
    if (failures <= 0 || lastAttemptAt == null) return;
    final until = DateTime.fromMillisecondsSinceEpoch(
      lastAttemptAt,
    ).add(_backoff.nominalDelayFor(failures - 1));
    if (_clock.now().isBefore(until)) _backoffUntil = until;
  }

  void _onResume() {
    _startPeriodic();
    request(SyncTrigger.resumed);
    // supabase_flutter restarts the token refresh on every resume; while
    // sync is off it must stay stopped (plan §4). Run after its observer.
    unawaited(
      Future<void>(() async {
        if (_disposed || !_supabase.isInitialized) return;
        final state = await _store.readState();
        if (!state.enabled) _supabase.stopAutoRefresh();
      }),
    );
  }

  void _onNetwork(bool hasNetwork) {
    final had = _lastHasNetwork;
    _lastHasNetwork = hasNetwork;
    if (!hasNetwork) {
      _networkDebounce?.cancel();
      if (_running == null && _status != SchedulerState.disabled) {
        _setStatus(SchedulerState.offline);
      }
      return;
    }
    if (had == true) return;
    _networkDebounce?.cancel();
    _networkDebounce = Timer(networkSettle, () {
      if (_lastHasNetwork == true) request(SyncTrigger.connectivityRestored);
    });
  }

  void _onOutboxChanged() {
    _writeDebounce?.cancel();
    _writeDebounce = Timer(writeDebounce, () async {
      if (_disposed) return;
      // The engine's own outbox writes also land here: request a cycle only
      // when something is actually ready to send.
      try {
        final ready = await _store.nextBatch(limit: 1, now: _clock.now());
        if (ready.isNotEmpty) request(SyncTrigger.localWrite);
      } catch (_) {
        // The next trigger retries.
      }
    });
  }

  void _startPeriodic() {
    _periodic?.cancel();
    _periodic = Timer.periodic(
      periodicInterval,
      (_) => request(SyncTrigger.periodic),
    );
  }

  void _stopPeriodic() {
    _periodic?.cancel();
    _periodic = null;
  }

  void _setStatus(SchedulerState status) {
    if (_status == status) return;
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}
