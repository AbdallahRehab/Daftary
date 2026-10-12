import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../core/date/app_clock.dart';
import '../domain/entities/sms_value_types.dart';
import '../domain/services/lock_status.dart';
import '../domain/usecases/expire_pending_imports.dart';
import '../domain/usecases/run_catch_up_scan.dart';

/// Waits until the current frame has been drawn.
typedef FrameWaiter = Future<void> Function();

/// Decides when the automatic catch-up ([RunCatchUpScan]) happens (T128,
/// FR-013, ui-contract §9): when the app starts, on every return to the
/// foreground and when App Lock is unlocked, at most once per [debounce].
///
/// A sibling of `NotificationRecomputeTrigger`: its own
/// [WidgetsBindingObserver], an idempotent [start], a single-flight
/// [runIfDue] that never throws. It runs only while the app is in the
/// foreground. There is no receiver, service, alarm or WorkManager job.
///
/// App Lock decides the lock on a resume asynchronously
/// (`discovery/permissions-lifecycle.md` L1), so [runIfDue] waits for the
/// end of the current frame before it reads [LockStatus.isLocked]. While
/// locked it does nothing; the unlock event runs it again. If the app
/// locks while a catch-up runs, the catch-up is cancelled (it keeps what
/// it already staged).
///
/// The first time the app is unlocked after start, it also runs
/// [ExpirePendingImports], on every platform (pasted and shared items
/// expire too), and again on a later pass once [expiryInterval] has
/// passed, so a process that lives for weeks still purges (SC-011).
///
/// It never shows anything and never logs. A failed pass is retried on the
/// next resume.
@lazySingleton
class SmsCatchUpTrigger with WidgetsBindingObserver {
  SmsCatchUpTrigger(
    this._catchUp,
    this._expire,
    this._lock,
    this._clock, {
    @ignoreParam FrameWaiter? waitForFrame,
  }) : _waitForFrame = waitForFrame ?? _endOfFrame;

  final RunCatchUpScan _catchUp;
  final ExpirePendingImports _expire;
  final LockStatus _lock;
  final AppClock _clock;
  final FrameWaiter _waitForFrame;

  /// At most one catch-up attempt per this period (FR-013).
  static const Duration debounce = RunCatchUpScan.debounce;

  /// At most one expiry pass per this period after the first one.
  static const Duration expiryInterval = Duration(days: 1);

  bool _started = false;
  DateTime? _lastExpiredAt;
  DateTime? _lastAttemptAt;
  Future<bool>? _inFlight;
  StreamSubscription<bool>? _lockChanges;

  static Future<void> _endOfFrame() => WidgetsBinding.instance.endOfFrame;

  /// Starts listening for resumes and lock changes, and kicks off the
  /// first pass without blocking the caller. Idempotent.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _lockChanges = _lock.changes.listen(_onLockChanged);
    unawaited(runIfDue());
  }

  /// Stops listening. The trigger lives as long as the app, so in practice
  /// only tests call this.
  Future<void> dispose() async {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    final changes = _lockChanges;
    _lockChanges = null;
    await changes?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(runIfDue());
  }

  void _onLockChanged(bool locked) {
    if (locked) {
      _catchUp.cancel();
    } else {
      unawaited(runIfDue());
    }
  }

  /// Runs one catch-up when the app is unlocked and none was attempted
  /// within [debounce]; returns whether a catch-up ran. A call while a pass
  /// is in flight joins it. Never throws.
  Future<bool> runIfDue() => _inFlight ??= _runIfDue().whenComplete(() {
    _inFlight = null;
  });

  Future<bool> _runIfDue() async {
    try {
      // App Lock may still be deciding the lock for this resume.
      await _waitForFrame();
      if (_lock.isLocked) return false;

      final now = _clock.now();
      final expiredAt = _lastExpiredAt;
      if (expiredAt == null ||
          now.isBefore(expiredAt) ||
          now.difference(expiredAt) >= expiryInterval) {
        _lastExpiredAt = now;
        await _expire();
      }

      final last = _lastAttemptAt;
      if (last != null) {
        final elapsed = now.difference(last);
        if (!elapsed.isNegative && elapsed < debounce) return false;
      }
      _lastAttemptAt = now;

      final outcome = await _catchUp();
      return outcome is CatchUpRan;
    } catch (_) {
      // Never inspected or kept: retried at the next resume.
      return false;
    }
  }
}
