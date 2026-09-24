import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../core/date/app_clock.dart';
import '../domain/repositories/notification_last_run_store.dart';
import '../domain/usecases/notification_engine.dart';

/// Decides when [NotificationEngine.run] happens (research.md Decision
/// 4/5): once at startup and on every return to the foreground, each only
/// when more than [catchUpInterval] has passed since the last completed
/// pass.
///
/// A minimal local lifecycle listener: 015-app-lock-security's
/// `AppLifecycleObserver` does not exist in code yet. Follow-up — once it
/// does, consolidate this onto it instead of registering a second
/// `WidgetsBindingObserver`.
///
/// Daily fixed-time trigger: `flutter_local_notifications` can schedule a
/// notification but cannot run Dart code at a scheduled time while the app
/// is not running, so a true background daily recomputation needs a
/// periodic-task plugin such as `workmanager` — out of scope here and
/// flagged as a follow-up. Until then a real threshold crossing is noticed
/// the next time the app starts or resumes (at most [catchUpInterval] of
/// foreground staleness); the engine's band bookkeeping makes that single
/// late pass notify exactly as a scheduled one would have.
@lazySingleton
class NotificationRecomputeTrigger with WidgetsBindingObserver {
  NotificationRecomputeTrigger(this._engine, this._lastRun, this._clock);

  final NotificationEngine _engine;
  final NotificationLastRunStore _lastRun;
  final AppClock _clock;

  /// The foreground catch-up threshold (research.md Decision 4).
  static const Duration catchUpInterval = Duration(hours: 6);

  bool _started = false;
  Future<bool>? _inFlight;

  /// Starts listening for app resumes and kicks off the startup pass
  /// without blocking the caller (so it never delays the first frame).
  /// Idempotent.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(runIfDue());
  }

  /// Stops listening. The trigger lives for the app's lifetime, so in
  /// practice only tests call this.
  void dispose() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(runIfDue());
  }

  /// Runs one pass if none has completed within [catchUpInterval]; returns
  /// whether it ran. A call while a pass is already in flight joins it
  /// rather than starting a second one. Never throws — a failed pass is
  /// simply retried on the next resume.
  Future<bool> runIfDue() => _inFlight ??= _runIfDue().whenComplete(() {
    _inFlight = null;
  });

  Future<bool> _runIfDue() async {
    try {
      final last = await _lastRun.read();
      if (last != null && _clock.now().difference(last) <= catchUpInterval) {
        return false;
      }
      await _engine.run();
      return true;
    } catch (_) {
      return false;
    }
  }
}
