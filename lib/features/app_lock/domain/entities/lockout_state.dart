import 'package:equatable/equatable.dart';

/// Brute-force protection state (015 data-model.md), persisted so a
/// relaunch cannot bypass an active cooldown (FR-015).
class LockoutState extends Equatable {
  const LockoutState({this.consecutiveFailedAttempts = 0, this.cooldownEndsAt});

  /// No failures, no cooldown — the state after any successful unlock
  /// (FR-014), a PIN change, or disabling App Lock.
  static const LockoutState initial = LockoutState();

  final int consecutiveFailedAttempts;

  /// `null` when not in cooldown.
  final DateTime? cooldownEndsAt;

  /// Whether a cooldown is still running at [now].
  bool isLockedOutAt(DateTime now) =>
      cooldownEndsAt != null && now.isBefore(cooldownEndsAt!);

  /// Time left on the cooldown at [now]; `null` when not locked out.
  Duration? remainingCooldownAt(DateTime now) =>
      isLockedOutAt(now) ? cooldownEndsAt!.difference(now) : null;

  LockoutState copyWith({
    int? consecutiveFailedAttempts,
    DateTime? cooldownEndsAt,
    bool clearCooldown = false,
  }) {
    return LockoutState(
      consecutiveFailedAttempts:
          consecutiveFailedAttempts ?? this.consecutiveFailedAttempts,
      cooldownEndsAt: clearCooldown
          ? null
          : (cooldownEndsAt ?? this.cooldownEndsAt),
    );
  }

  @override
  List<Object?> get props => [consecutiveFailedAttempts, cooldownEndsAt];
}

/// How an unlock attempt ended (015 data-model.md).
enum UnlockOutcome {
  success,
  incorrectPin,
  lockedOut,
  biometricUnavailable,
  biometricFailed,
}

/// Ephemeral result of `VerifyPin`/`VerifyBiometric`, never persisted.
class UnlockAttemptResult extends Equatable {
  const UnlockAttemptResult({required this.outcome, this.remainingCooldown});

  const UnlockAttemptResult.success()
    : outcome = UnlockOutcome.success,
      remainingCooldown = null;

  const UnlockAttemptResult.lockedOut(Duration this.remainingCooldown)
    : outcome = UnlockOutcome.lockedOut;

  final UnlockOutcome outcome;

  /// Present only when [outcome] is [UnlockOutcome.lockedOut].
  final Duration? remainingCooldown;

  bool get isSuccess => outcome == UnlockOutcome.success;

  @override
  List<Object?> get props => [outcome, remainingCooldown];
}
