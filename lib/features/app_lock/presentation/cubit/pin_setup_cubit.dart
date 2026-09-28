import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/app_lock_failures.dart';
import '../../domain/entities/lockout_state.dart';
import '../../domain/services/biometric_service.dart';
import '../../domain/usecases/change_pin.dart';
import '../../domain/usecases/get_app_lock_config.dart';
import '../../domain/usecases/get_lockout_state.dart';
import '../../domain/usecases/record_failed_pin_attempt.dart';
import '../../domain/usecases/set_pin.dart';
import '../../domain/usecases/verify_biometric.dart';
import '../../domain/usecases/verify_pin.dart';
import 'pin_cooldown_ticker.dart';
import 'pin_setup_state.dart';

/// Drives `PinSetupPage` for every [PinSetupMode]:
///
/// 1. [PinSetupMode.change] only — [submitCurrentPin] or
///    [authenticateWithBiometric] (FR-023), with the same lockout rules as
///    the lock screen (a wrong PIN is recorded; a cooldown disables entry;
///    biometric failures are never counted, FR-008).
/// 2. [submitNewPin] — the first entry, held privately in this cubit.
/// 3. [submitConfirmation] — must match the first entry (FR-002). A
///    mismatch keeps the first entry so only the confirmation is retyped
///    (US1 Scenario 3); [startOver] discards it.
///
/// Saving is at-most-once: a second tap while the first save is running —
/// or after it succeeded — is ignored (constitution Duplicate Action
/// Protection).
@injectable
class PinSetupCubit extends Cubit<PinSetupState> {
  PinSetupCubit(
    @factoryParam PinSetupMode mode,
    this._setPin,
    this._changePin,
    this._verifyPin,
    this._recordFailedPinAttempt,
    this._getLockoutState,
    this._getConfig,
    this._verifyBiometric,
    this._biometricService, {
    @ignoreParam DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(PinSetupState.initial(mode)) {
    _ticker = PinCooldownTicker(clock: _now, onTick: _onCooldownTick);
  }

  final SetPin _setPin;
  final ChangePin _changePin;
  final VerifyPin _verifyPin;
  final RecordFailedPinAttempt _recordFailedPinAttempt;
  final GetLockoutState _getLockoutState;
  final GetAppLockConfig _getConfig;
  final VerifyBiometric _verifyBiometric;
  final BiometricService _biometricService;
  final DateTime Function() _now;
  late final PinCooldownTicker _ticker;

  /// The first new-PIN entry. Never exposed through state (FR-016).
  String? _firstEntry;

  /// Set synchronously, before any `await`, by every async action.
  bool _isBusy = false;

  /// Stays `true` after a successful save.
  bool _hasSaved = false;

  /// For [PinSetupMode.change]: whether biometrics can replace the current
  /// PIN, and the persisted lockout (FR-015). A no-op for other modes.
  Future<void> start() async {
    if (state.step != PinSetupStep.verifyCurrent) return;
    final config = await _getConfig();
    final enabled = config.match((_) => false, (c) => c.isBiometricEnabled);
    final available = enabled && await _biometricService.isAvailable();
    final lockout = await _getLockoutState();
    if (isClosed) return;
    if (available != state.canUseBiometric) {
      emit(state.copyWith(canUseBiometric: available));
    }
    lockout.match((_) {}, _applyLockout);
  }

  /// Checks the current PIN ([PinSetupStep.verifyCurrent]).
  Future<void> submitCurrentPin(String pin) async {
    if (_isBusy ||
        state.step != PinSetupStep.verifyCurrent ||
        !state.isPinEntryEnabled) {
      return;
    }
    _isBusy = true;
    emit(state.copyWith(status: PinSetupStatus.verifying, clearMessage: true));

    final result = await _verifyPin(pin);
    if (isClosed) return;
    await result.match((_) async => _idle(PinSetupMessage.unexpected), (
      attempt,
    ) async {
      switch (attempt.outcome) {
        case UnlockOutcome.success:
          _proceedToNewPin();
        case UnlockOutcome.lockedOut:
          _idle(null);
          final remaining = attempt.remainingCooldown;
          if (remaining != null) _ticker.start(_now().add(remaining));
        case UnlockOutcome.incorrectPin:
        case UnlockOutcome.biometricFailed:
        case UnlockOutcome.biometricUnavailable:
          // FR-013/FR-016: counted, the PIN itself never passed on.
          final recorded = await _recordFailedPinAttempt();
          if (isClosed) return;
          _idle(PinSetupMessage.incorrectCurrentPin);
          recorded.match((Failure _) {}, _applyLockout);
      }
    });
    _isBusy = false;
  }

  /// Re-authenticates with biometrics instead of the current PIN
  /// ([PinSetupStep.verifyCurrent]); allowed during a PIN cooldown.
  Future<void> authenticateWithBiometric({
    required String localizedReason,
  }) async {
    if (_isBusy ||
        state.step != PinSetupStep.verifyCurrent ||
        !state.canUseBiometric) {
      return;
    }
    _isBusy = true;
    emit(state.copyWith(status: PinSetupStatus.verifying, clearMessage: true));

    final result = await _verifyBiometric(localizedReason: localizedReason);
    if (isClosed) return;
    result.match((_) => _idle(PinSetupMessage.unexpected), (attempt) {
      switch (attempt.outcome) {
        case UnlockOutcome.success:
          _proceedToNewPin();
        case UnlockOutcome.biometricUnavailable:
          emit(state.copyWith(canUseBiometric: false));
          _idle(PinSetupMessage.biometricUnavailable);
        case UnlockOutcome.biometricFailed:
        case UnlockOutcome.incorrectPin:
        case UnlockOutcome.lockedOut:
          _idle(PinSetupMessage.biometricFailed);
      }
    });
    _isBusy = false;
  }

  /// Takes the first entry of the new PIN ([PinSetupStep.enterNew]).
  void submitNewPin(String pin) {
    if (_isBusy || state.step != PinSetupStep.enterNew) return;
    if (!_isWellFormed(pin)) {
      emit(state.copyWith(message: PinSetupMessage.invalidPin));
      return;
    }
    _firstEntry = pin;
    emit(state.copyWith(step: PinSetupStep.confirmNew, clearMessage: true));
  }

  /// Takes the confirmation ([PinSetupStep.confirmNew]) and, when it
  /// matches, saves the PIN — exactly once.
  Future<void> submitConfirmation(String pin) async {
    final first = _firstEntry;
    if (_isBusy ||
        _hasSaved ||
        state.step != PinSetupStep.confirmNew ||
        first == null) {
      return;
    }
    if (pin != first) {
      // US1 Scenario 3: keep the first entry, retype the confirmation.
      emit(state.copyWith(message: PinSetupMessage.mismatch));
      return;
    }
    _isBusy = true;
    emit(state.copyWith(status: PinSetupStatus.saving, clearMessage: true));

    final result = state.mode == PinSetupMode.initialSetup
        ? await _setPin(first, confirmation: pin)
        : await _changePin(first, confirmation: pin);
    if (isClosed) return;

    result.match(
      (failure) {
        _isBusy = false;
        switch (failure) {
          case PinMismatchFailure():
            _idle(PinSetupMessage.mismatch);
          case ValidationFailure():
            // Only a malformed PIN gets here — choose a new one.
            _firstEntry = null;
            emit(
              state.copyWith(
                step: PinSetupStep.enterNew,
                status: PinSetupStatus.idle,
                message: PinSetupMessage.invalidPin,
              ),
            );
          default:
            // Keep the first entry so "Save" can simply be retried.
            _idle(PinSetupMessage.unexpected);
        }
      },
      (_) {
        _hasSaved = true;
        _firstEntry = null;
        emit(
          state.copyWith(status: PinSetupStatus.success, clearMessage: true),
        );
      },
    );
  }

  /// Discards the first entry and goes back to choosing the new PIN.
  void startOver() {
    if (_isBusy || _hasSaved || state.step != PinSetupStep.confirmNew) return;
    _firstEntry = null;
    emit(state.copyWith(step: PinSetupStep.enterNew, clearMessage: true));
  }

  void _proceedToNewPin() {
    _ticker.cancel();
    emit(
      state.copyWith(
        step: PinSetupStep.enterNew,
        status: PinSetupStatus.idle,
        clearMessage: true,
        clearCooldown: true,
      ),
    );
  }

  void _idle(PinSetupMessage? message) {
    emit(
      state.copyWith(
        status: PinSetupStatus.idle,
        message: message,
        clearMessage: message == null,
      ),
    );
  }

  void _applyLockout(LockoutState lockout) {
    final endsAt = lockout.cooldownEndsAt;
    if (endsAt != null && lockout.isLockedOutAt(_now())) {
      _ticker.start(endsAt);
    }
  }

  void _onCooldownTick(Duration? remaining) {
    if (isClosed) return;
    emit(
      remaining == null
          ? state.copyWith(clearCooldown: true)
          : state.copyWith(cooldownRemaining: remaining),
    );
  }

  static final RegExp _pinPattern = RegExp(r'^[0-9]{4,6}$');

  static bool _isWellFormed(String pin) => _pinPattern.hasMatch(pin);

  @override
  Future<void> close() {
    _ticker.cancel();
    _firstEntry = null;
    return super.close();
  }
}
