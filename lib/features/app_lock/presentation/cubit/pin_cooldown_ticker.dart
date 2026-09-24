import 'dart:async';

/// Drives a live PIN-lockout countdown (FR-013) for the lock screen and the
/// change-PIN re-authentication step.
///
/// [onTick] receives the time left, rounded up to whole seconds, right away
/// on [start] and then once a second; it receives `null` exactly once when
/// the cooldown is over, after which the ticker stops itself.
class PinCooldownTicker {
  PinCooldownTicker({
    required DateTime Function() clock,
    required void Function(Duration? remaining) onTick,
  }) : _now = clock,
       _onTick = onTick;

  static const Duration interval = Duration(seconds: 1);

  final DateTime Function() _now;
  final void Function(Duration? remaining) _onTick;

  Timer? _timer;
  DateTime? _endsAt;

  bool get isRunning => _endsAt != null;

  /// Starts (or restarts) counting down to [endsAt]. An [endsAt] already in
  /// the past reports `null` straight away.
  void start(DateTime endsAt) {
    cancel();
    _endsAt = endsAt;
    _tick();
    if (_endsAt != null) {
      _timer = Timer.periodic(interval, (_) => _tick());
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
  }

  void _tick() {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final remaining = endsAt.difference(_now());
    if (remaining <= Duration.zero) {
      cancel();
      _onTick(null);
      return;
    }
    _onTick(roundUpToSeconds(remaining));
  }

  /// "0.2 s left" still reads as "1 s", never as "0 s" while PIN entry is
  /// still disabled.
  static Duration roundUpToSeconds(Duration duration) {
    final seconds = (duration.inMilliseconds / 1000).ceil();
    return Duration(seconds: seconds);
  }
}
