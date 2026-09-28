import 'package:injectable/injectable.dart';

/// FR-013's escalating PIN-lockout schedule as pure input→output
/// (research.md Decision 3) — no I/O, no clock.
abstract class LockoutPolicy {
  /// The cooldown owed after [consecutiveFailedAttempts] wrong PINs:
  /// - 0-4 -> `null` (no cooldown)
  /// - 5-7 -> 30 seconds
  /// - 8-10 -> 2 minutes
  /// - 11 and beyond (8 + 3n, n >= 1, and everything between) -> 5 minutes
  ///
  /// Applied after *every* failed attempt once the count reaches 5 (not only
  /// on the exact threshold counts), so once lockout engages every further
  /// guess costs at least 30 seconds (SC-006).
  Duration? cooldownFor(int consecutiveFailedAttempts);
}

@LazySingleton(as: LockoutPolicy)
class EscalatingLockoutPolicy implements LockoutPolicy {
  const EscalatingLockoutPolicy();

  static const int firstThreshold = 5;
  static const int secondThreshold = 8;
  static const int escalationStep = 3;

  static const Duration firstCooldown = Duration(seconds: 30);
  static const Duration secondCooldown = Duration(minutes: 2);
  static const Duration escalatedCooldown = Duration(minutes: 5);

  @override
  Duration? cooldownFor(int consecutiveFailedAttempts) {
    if (consecutiveFailedAttempts < firstThreshold) return null;
    if (consecutiveFailedAttempts < secondThreshold) return firstCooldown;
    if (consecutiveFailedAttempts < secondThreshold + escalationStep) {
      return secondCooldown;
    }
    return escalatedCooldown;
  }
}
