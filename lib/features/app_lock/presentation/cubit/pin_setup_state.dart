import 'package:equatable/equatable.dart';

/// Which flow `PinSetupPage` runs (see `PinSetupPage` for the contract).
enum PinSetupMode {
  /// First PIN when turning App Lock on: enter + confirm -> `SetPin`. Does
  /// not enable App Lock; the caller runs `EnableAppLock`.
  initialSetup,

  /// Security settings "Change PIN": re-authenticate with the current PIN
  /// or biometrics first (FR-023), then enter + confirm -> `ChangePin`.
  change,

  /// After the caller already re-authenticated (Forgot PIN via
  /// biometrics): enter + confirm -> `ChangePin`.
  reset,
}

/// The screen currently asked of the user.
enum PinSetupStep {
  /// [PinSetupMode.change] only: prove it's the owner first.
  verifyCurrent,

  /// Choose the new PIN.
  enterNew,

  /// Type the new PIN again (FR-002).
  confirmNew,
}

/// - [idle]: waiting for input.
/// - [verifying]: checking the current PIN or a biometric attempt.
/// - [saving]: the new PIN is being stored; input is ignored.
/// - [success]: stored — the page pops with `true`.
enum PinSetupStatus { idle, verifying, saving, success }

/// Typed feedback; the page picks the localized wording. Never carries PIN
/// digits (FR-016).
enum PinSetupMessage {
  /// The confirmation didn't match the first entry. The first entry is
  /// kept, so the user only re-types the confirmation.
  mismatch,

  /// The new PIN isn't 4-6 digits (FR-003).
  invalidPin,

  /// Wrong current PIN during [PinSetupStep.verifyCurrent].
  incorrectCurrentPin,

  /// Biometric re-authentication was cancelled or not recognized.
  biometricFailed,

  /// Biometrics can't be used on this device right now — use the PIN.
  biometricUnavailable,

  /// Storage or other unexpected error; retrying is safe.
  unexpected,
}

/// Immutable state for `PinSetupCubit` (constitution Principle IV). The
/// first PIN entry is kept privately inside the cubit, never in state, so
/// no state dump or observer can ever see PIN digits.
class PinSetupState extends Equatable {
  const PinSetupState({
    required this.mode,
    required this.step,
    this.status = PinSetupStatus.idle,
    this.message,
    this.canUseBiometric = false,
    this.cooldownRemaining,
  });

  /// The first step of [mode]'s flow.
  factory PinSetupState.initial(PinSetupMode mode) => PinSetupState(
    mode: mode,
    step: mode == PinSetupMode.change
        ? PinSetupStep.verifyCurrent
        : PinSetupStep.enterNew,
  );

  final PinSetupMode mode;
  final PinSetupStep step;
  final PinSetupStatus status;
  final PinSetupMessage? message;

  /// [PinSetupStep.verifyCurrent] can be satisfied by biometrics
  /// (FR-023): enabled in settings and available on the device.
  final bool canUseBiometric;

  /// PIN lockout time left during [PinSetupStep.verifyCurrent] (FR-013);
  /// `null` when the current PIN may be entered.
  final Duration? cooldownRemaining;

  bool get isBusy =>
      status == PinSetupStatus.verifying || status == PinSetupStatus.saving;
  bool get isSuccess => status == PinSetupStatus.success;
  bool get isLockedOut => cooldownRemaining != null;

  /// Whether the PIN pad accepts input right now.
  bool get isPinEntryEnabled =>
      status == PinSetupStatus.idle &&
      !(step == PinSetupStep.verifyCurrent && isLockedOut);

  PinSetupState copyWith({
    PinSetupStep? step,
    PinSetupStatus? status,
    PinSetupMessage? message,
    bool clearMessage = false,
    bool? canUseBiometric,
    Duration? cooldownRemaining,
    bool clearCooldown = false,
  }) {
    return PinSetupState(
      mode: mode,
      step: step ?? this.step,
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      canUseBiometric: canUseBiometric ?? this.canUseBiometric,
      cooldownRemaining: clearCooldown
          ? null
          : (cooldownRemaining ?? this.cooldownRemaining),
    );
  }

  @override
  List<Object?> get props => [
    mode,
    step,
    status,
    message,
    canUseBiometric,
    cooldownRemaining,
  ];
}
