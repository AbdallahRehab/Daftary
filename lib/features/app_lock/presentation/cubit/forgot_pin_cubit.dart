import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../domain/entities/app_lock_failures.dart';
import '../../domain/usecases/recover_via_biometric.dart';
import '../../domain/usecases/wipe_all_local_data.dart';
import 'forgot_pin_state.dart';

/// Drives the Forgot-PIN flow (015 US4): biometric recovery first when it
/// can work (FR-017), otherwise — or when the user explicitly chooses it —
/// the honest explanation that erasing this device's data is the only way
/// back in (FR-018), behind a typed-phrase gate (FR-019).
///
/// Nothing is ever deleted before [confirmWipe] runs from
/// [ForgotPinStep.wipeConfirmation] with the phrase typed exactly; every
/// other method only moves between steps, so backing out at any earlier
/// point leaves all data untouched.
///
/// Handing off to `PinSetupPage(mode: reset)` after [BiometricRecoveryStatus
/// .verified], and dismissing the lock screen, are the page's job.
@injectable
class ForgotPinCubit extends Cubit<ForgotPinState> {
  ForgotPinCubit(
    this._recoverViaBiometric,
    this._wipeAllLocalData,
    this._onboardingCubit,
  ) : super(const ForgotPinState());

  final RecoverViaBiometric _recoverViaBiometric;
  final WipeAllLocalData _wipeAllLocalData;
  final OnboardingCubit _onboardingCubit;

  /// Set synchronously on entry to [confirmWipe], before any `await`, so a
  /// second tap in the same frame sees it. Stays set after a success.
  bool _isWiping = false;

  /// Picks the first step: biometric recovery when enabled and available,
  /// otherwise straight to the wipe explanation.
  Future<void> initialize() async {
    if (state.step != ForgotPinStep.resolving) return;
    final available = await _recoverViaBiometric.isAvailable();
    if (isClosed) return;
    emit(
      state.copyWith(
        step: available
            ? ForgotPinStep.biometricRecovery
            : ForgotPinStep.wipeExplanation,
      ),
    );
  }

  /// Presents the OS biometric prompt. On success the page pushes the
  /// reset-PIN screen; on a cancelled/failed prompt the user may retry.
  /// If biometric has become unavailable meanwhile, only the wipe remains.
  Future<void> recoverWithBiometric({required String localizedReason}) async {
    if (state.step != ForgotPinStep.biometricRecovery ||
        state.isAuthenticating ||
        state.biometricStatus == BiometricRecoveryStatus.verified) {
      return;
    }
    emit(
      state.copyWith(
        biometricStatus: BiometricRecoveryStatus.authenticating,
        clearFailure: true,
      ),
    );
    final result = await _recoverViaBiometric(localizedReason: localizedReason);
    if (isClosed) return;
    switch (result) {
      case Right(value: true):
        emit(state.copyWith(biometricStatus: BiometricRecoveryStatus.verified));
      case Right(value: false):
        emit(state.copyWith(biometricStatus: BiometricRecoveryStatus.failed));
      case Left(value: BiometricUnavailableFailure()):
        emit(
          state.copyWith(
            step: ForgotPinStep.wipeExplanation,
            biometricStatus: BiometricRecoveryStatus.idle,
          ),
        );
      case Left(value: final failure):
        emit(
          state.copyWith(
            biometricStatus: BiometricRecoveryStatus.failed,
            failure: failure,
          ),
        );
    }
  }

  /// The user backed out of the reset-PIN screen without saving a new PIN.
  /// A fresh biometric check is required before trying again — a verified
  /// status must never outlive the hand-off it was granted for.
  void pinResetAbandoned() {
    if (state.biometricStatus != BiometricRecoveryStatus.verified) return;
    emit(state.copyWith(biometricStatus: BiometricRecoveryStatus.idle));
  }

  /// From biometric recovery, the user explicitly chose the wipe route
  /// instead (e.g. biometric keeps failing). Only moves to the explanation.
  void chooseWipe() {
    if (state.step != ForgotPinStep.biometricRecovery ||
        state.isAuthenticating) {
      return;
    }
    emit(
      state.copyWith(
        step: ForgotPinStep.wipeExplanation,
        biometricStatus: BiometricRecoveryStatus.idle,
        clearFailure: true,
      ),
    );
  }

  /// The user read the explanation and chose to continue to the typed
  /// confirmation. Still deletes nothing.
  void proceedToWipeConfirmation() {
    if (state.step != ForgotPinStep.wipeExplanation) return;
    emit(
      state.copyWith(
        step: ForgotPinStep.wipeConfirmation,
        wipeInput: state.wipeInput.copyWith(typedPhrase: ''),
        wipeStatus: WipeStatus.idle,
        clearFailure: true,
      ),
    );
  }

  /// The user left the confirmation screen before confirming: back to the
  /// explanation, with whatever they had typed discarded.
  void cancelWipeConfirmation() {
    if (state.step != ForgotPinStep.wipeConfirmation ||
        state.isWiping ||
        state.isWiped) {
      return;
    }
    emit(
      state.copyWith(
        step: ForgotPinStep.wipeExplanation,
        wipeInput: state.wipeInput.copyWith(typedPhrase: ''),
        wipeStatus: WipeStatus.idle,
        clearFailure: true,
      ),
    );
  }

  /// Supplies the localized phrase the user must type; re-called on a
  /// locale change so the gate follows the label.
  void setExpectedPhrase(String phrase) {
    emit(
      state.copyWith(
        wipeInput: state.wipeInput.copyWith(expectedPhrase: phrase),
      ),
    );
  }

  void updateTypedPhrase(String typed) {
    emit(
      state.copyWith(wipeInput: state.wipeInput.copyWith(typedPhrase: typed)),
    );
  }

  /// The one path to `WipeAllLocalData`, and only through the gate.
  Future<void> confirmWipe() async {
    if (_isWiping || !state.canConfirmWipe) return;
    _isWiping = true;

    emit(state.copyWith(wipeStatus: WipeStatus.inProgress, clearFailure: true));
    final result = await _wipeAllLocalData();

    await result.match(
      (failure) async {
        _isWiping = false;
        // Rolled back across the database and App Lock's keys alike:
        // nothing was removed, and the PIN still guards the data.
        if (isClosed) return;
        emit(state.copyWith(wipeStatus: WipeStatus.error, failure: failure));
      },
      (_) async {
        // The onboarding flag went with the tables; re-resolve the app-wide
        // gate so the router sends the user to first-launch onboarding.
        await _onboardingCubit.initialize();
        if (isClosed) return;
        emit(state.copyWith(wipeStatus: WipeStatus.success));
      },
    );
  }
}
