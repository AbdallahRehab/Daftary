import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import 'app_lock_status_provider.dart';

/// Creates the inactivity timer; injectable so tests can substitute one.
typedef LockTimerFactory = Timer Function(Duration duration, void Function());

/// Decides *when* the app must show the lock screen (015 research.md
/// Decision 6), and exposes that as [isLocked] for `AppLockGate`.
///
/// - **Cold launch**: [initialize] locks when App Lock is enabled.
/// - **Genuine backgrounding** (`AppLifecycleState.paused`): records when it
///   happened, reads the timeout fresh from [AppLockStatusProvider], and
///   starts the inactivity timer (locks immediately for a zero timeout).
/// - **Resume** (`resumed`): cancels the timer, and locks if the wall-clock
///   time spent paused reached the timeout — covering OSes that suspend the
///   process so the timer never gets to fire. A clock that moved backwards
///   while paused also locks (fail closed).
/// - **Brief interruptions** (`inactive`: permission dialog, incoming-call
///   banner, system sheet) and `hidden` are ignored entirely (FR-010).
///
/// Unlocking is explicit: only the lock screen calls [unlock], after a
/// successful PIN/biometric check.
@lazySingleton
class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver(
    this._status, {
    @ignoreParam LockTimerFactory? timerFactory,
    @ignoreParam DateTime Function()? clock,
  }) : _timerFactory = timerFactory ?? Timer.new,
       _now = clock ?? DateTime.now;

  final AppLockStatusProvider _status;
  final LockTimerFactory _timerFactory;
  final DateTime Function() _now;

  final ValueNotifier<bool> _isLocked = ValueNotifier<bool>(false);

  Timer? _timer;
  DateTime? _pausedAt;

  /// The timeout read for the current backgrounding; `null` until the read
  /// completes or when App Lock is disabled.
  Duration? _pausedTimeout;
  bool _pausedTimeoutResolved = false;

  /// Bumped on every paused/resumed transition so a slow timeout read from
  /// an earlier backgrounding can never act on a later one.
  int _generation = 0;
  int _externalActivityDepth = 0;
  bool _attached = false;

  /// `true` while the lock screen must cover the app.
  ValueListenable<bool> get isLocked => _isLocked;

  /// Registers with [WidgetsBinding] and applies the cold-launch rule: the
  /// app starts locked when App Lock is enabled. Await before `runApp` so
  /// the very first frame is already gated.
  Future<void> initialize() async {
    if (!_attached) {
      WidgetsBinding.instance.addObserver(this);
      _attached = true;
    }
    if (await _status.lockTimeoutIfEnabled() != null) lock();
  }

  /// Shows the lock screen now.
  void lock() {
    _cancelTimer();
    _isLocked.value = true;
  }

  /// Dismisses the lock screen — call only after a successful unlock.
  void unlock() {
    _cancelTimer();
    _isLocked.value = false;
  }

  /// Runs [action] (e.g. the app's own OS share sheet or photo picker, which
  /// fully background the app on Android) without the resulting `paused`
  /// counting as a backgrounding (FR-010).
  Future<T> runExternalActivity<T>(Future<T> Function() action) async {
    _externalActivityDepth++;
    try {
      return await action();
    } finally {
      _externalActivityDepth--;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onPaused();
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // Transient interruptions never start the timer (FR-010).
        break;
    }
  }

  void _onPaused() {
    if (_pausedAt != null || _externalActivityDepth > 0) return;
    final generation = ++_generation;
    _pausedAt = _now();
    _pausedTimeout = null;
    _pausedTimeoutResolved = false;
    unawaited(
      _status.lockTimeoutIfEnabled().then((timeout) {
        if (generation != _generation) return; // already resumed
        _pausedTimeout = timeout;
        _pausedTimeoutResolved = true;
        if (timeout == null || _isLocked.value) return;
        if (timeout <= Duration.zero) {
          lock();
        } else {
          _timer = _timerFactory(timeout, lock);
        }
      }),
    );
  }

  void _onResumed() {
    _cancelTimer();
    final pausedAt = _pausedAt;
    _pausedAt = null;
    _generation++;
    if (pausedAt == null || _isLocked.value) return;
    final elapsed = _now().difference(pausedAt);
    if (_pausedTimeoutResolved) {
      if (_shouldLock(_pausedTimeout, elapsed)) lock();
      return;
    }
    // The timeout read hadn't completed yet (a very short background).
    unawaited(
      _status.lockTimeoutIfEnabled().then((timeout) {
        if (_shouldLock(timeout, elapsed)) lock();
      }),
    );
  }

  bool _shouldLock(Duration? timeout, Duration elapsed) =>
      timeout != null && (elapsed.isNegative || elapsed >= timeout);

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @disposeMethod
  void dispose() {
    _cancelTimer();
    if (_attached) {
      WidgetsBinding.instance.removeObserver(this);
      _attached = false;
    }
    _isLocked.dispose();
  }
}
