import 'package:equatable/equatable.dart';

/// - [loading]: reading the configuration and persisted lockout state.
/// - [ready]: waiting for the user (PIN pad, biometric button).
/// - [verifyingPin]: a submitted PIN is being checked; input is ignored.
/// - [verifyingBiometric]: the OS biometric prompt is up; the PIN pad
///   stays visible behind it as the fallback (FR-006).
/// - [unlocked]: authentication succeeded — the page dismisses the gate.
enum LockScreenStatus {
  loading,
  ready,
  verifyingPin,
  verifyingBiometric,
  unlocked,
}

/// What the lock screen tells the user after an attempt. Typed, so the page
/// picks the localized wording; never carries the attempted PIN (FR-016).
enum LockScreenMessage {
  /// Wrong PIN (FR-012).
  incorrectPin,

  /// Biometric prompt cancelled or not recognized — PIN still works.
  biometricFailed,

  /// Biometrics stopped being usable on this device (FR-007); the screen
  /// fell back to PIN-only.
  biometricUnavailable,

  /// Storage or other unexpected error; the user may simply retry.
  unexpected,
}

/// Immutable state for `LockScreenCubit` (constitution Principle IV —
/// updated exclusively via [copyWith]). Deliberately holds no PIN digits:
/// they live only in the `PinPad` widget until submitted.
class LockScreenState extends Equatable {
  const LockScreenState({
    this.status = LockScreenStatus.loading,
    this.isBiometricEnabled = false,
    this.isBiometricAvailable = false,
    this.cooldownRemaining,
    this.message,
  });

  final LockScreenStatus status;

  /// The user turned biometric unlock on in Security settings.
  final bool isBiometricEnabled;

  /// The device can perform biometrics right now (queried live).
  final bool isBiometricAvailable;

  /// Time left on the PIN lockout, rounded up to whole seconds; `null`
  /// when PIN entry is allowed (FR-013).
  final Duration? cooldownRemaining;

  final LockScreenMessage? message;

  bool get isLoading => status == LockScreenStatus.loading;
  bool get isUnlocked => status == LockScreenStatus.unlocked;
  bool get isVerifyingBiometric =>
      status == LockScreenStatus.verifyingBiometric;
  bool get isLockedOut => cooldownRemaining != null;

  /// Biometric unlock is offered — even during a PIN cooldown (FR-008).
  bool get canUseBiometric => isBiometricEnabled && isBiometricAvailable;

  /// Whether the PIN pad accepts input: not while loading, verifying, or
  /// during a cooldown.
  bool get isPinEntryEnabled =>
      !isLockedOut &&
      (status == LockScreenStatus.ready ||
          status == LockScreenStatus.verifyingBiometric);

  LockScreenState copyWith({
    LockScreenStatus? status,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    Duration? cooldownRemaining,
    bool clearCooldown = false,
    LockScreenMessage? message,
    bool clearMessage = false,
  }) {
    return LockScreenState(
      status: status ?? this.status,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      cooldownRemaining: clearCooldown
          ? null
          : (cooldownRemaining ?? this.cooldownRemaining),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    status,
    isBiometricEnabled,
    isBiometricAvailable,
    cooldownRemaining,
    message,
  ];
}
