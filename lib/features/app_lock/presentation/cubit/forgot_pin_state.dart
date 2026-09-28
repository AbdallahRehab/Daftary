import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../data_privacy/presentation/cubit/delete_confirmation_input.dart';

/// Where the user is in the Forgot-PIN flow (FR-017/FR-018). There are only
/// ever two recovery routes — biometric re-authentication or a full local
/// wipe — so there is deliberately no third step to route to.
///
/// - [resolving]: checking whether biometric recovery can be offered.
/// - [biometricRecovery]: biometric is enabled and available — offered
///   first, with the wipe reachable only as the explicit alternative.
/// - [wipeExplanation]: the honest "the only way back in is erasing this
///   device's data" explanation. Nothing is deleted from here.
/// - [wipeConfirmation]: the typed-phrase gate (FR-019); the only step
///   from which `WipeAllLocalData` can run.
enum ForgotPinStep {
  resolving,
  biometricRecovery,
  wipeExplanation,
  wipeConfirmation,
}

/// - [verified]: a genuine biometric check succeeded; the page now hands
///   off to `PinSetupPage(mode: PinSetupMode.reset)`.
/// - [failed]: cancelled/failed prompt (or a storage error) — retryable.
enum BiometricRecoveryStatus { idle, authenticating, verified, failed }

/// - [success]: every table and App Lock key is erased and onboarding has
///   been re-resolved; the page leaves for first-launch onboarding.
/// - [error]: the wipe failed and was rolled back — nothing was removed.
enum WipeStatus { idle, inProgress, success, error }

/// Immutable state for `ForgotPinCubit` (constitution Principle IV —
/// updated exclusively via [copyWith]).
class ForgotPinState extends Equatable {
  const ForgotPinState({
    this.step = ForgotPinStep.resolving,
    this.biometricStatus = BiometricRecoveryStatus.idle,
    this.wipeInput = const DeleteConfirmationInput(),
    this.wipeStatus = WipeStatus.idle,
    this.failure,
  });

  final ForgotPinStep step;
  final BiometricRecoveryStatus biometricStatus;

  /// The same typed-phrase gate as 013's "Delete my data" — this is the
  /// same wipe, so it asks for the same deliberate confirmation.
  final DeleteConfirmationInput wipeInput;
  final WipeStatus wipeStatus;

  /// The last wipe or recovery failure, if any. Never carries a PIN.
  final Failure? failure;

  bool get isAuthenticating =>
      biometricStatus == BiometricRecoveryStatus.authenticating;
  bool get isWiping => wipeStatus == WipeStatus.inProgress;
  bool get isWiped => wipeStatus == WipeStatus.success;
  bool get wipeFailed => wipeStatus == WipeStatus.error;

  /// Whether the final destructive button is enabled — the same rule
  /// `confirmWipe()` enforces: only on the confirmation step, only with
  /// the phrase typed exactly, and never while a wipe is running or done.
  bool get canConfirmWipe =>
      step == ForgotPinStep.wipeConfirmation &&
      wipeInput.isConfirmationEnabled &&
      (wipeStatus == WipeStatus.idle || wipeStatus == WipeStatus.error);

  ForgotPinState copyWith({
    ForgotPinStep? step,
    BiometricRecoveryStatus? biometricStatus,
    DeleteConfirmationInput? wipeInput,
    WipeStatus? wipeStatus,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ForgotPinState(
      step: step ?? this.step,
      biometricStatus: biometricStatus ?? this.biometricStatus,
      wipeInput: wipeInput ?? this.wipeInput,
      wipeStatus: wipeStatus ?? this.wipeStatus,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    step,
    biometricStatus,
    wipeInput,
    wipeStatus,
    failure,
  ];
}
