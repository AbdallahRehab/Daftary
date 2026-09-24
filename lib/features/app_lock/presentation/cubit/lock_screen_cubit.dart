import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/lockout_state.dart';
import '../../domain/services/biometric_service.dart';
import '../../domain/usecases/get_app_lock_config.dart';
import '../../domain/usecases/get_lockout_state.dart';
import '../../domain/usecases/record_failed_pin_attempt.dart';
import '../../domain/usecases/verify_biometric.dart';
import '../../domain/usecases/verify_pin.dart';
import 'lock_screen_state.dart';
import 'pin_cooldown_ticker.dart';

/// Drives `LockScreenPage`. A fresh instance is created every time the app
/// locks (the gate rebuilds the page), so [start] re-reads everything:
/// configuration, live biometric availability, and the persisted lockout
/// state (FR-015).
///
/// - Biometric first (FR-006): when enabled and available, [start] can
///   prompt straight away; the PIN pad stays usable throughout.
/// - A failed/cancelled biometric attempt never touches the PIN counter
///   (FR-008); biometrics going away mid-session falls back to PIN-only
///   (FR-007).
/// - Wrong PIN -> `RecordFailedPinAttempt` (FR-013), which may start a
///   cooldown; the countdown ticks live and PIN entry is disabled until it
///   ends, while biometric unlock remains available.
///
/// On success the state becomes [LockScreenStatus.unlocked]; the page then
/// releases the gate via `AppLifecycleObserver.unlock()`.
@injectable
class LockScreenCubit extends Cubit<LockScreenState> {
  LockScreenCubit(
    this._getConfig,
    this._getLockoutState,
    this._verifyPin,
    this._recordFailedPinAttempt,
    this._verifyBiometric,
    this._biometricService, {
    @ignoreParam DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const LockScreenState()) {
    _ticker = PinCooldownTicker(clock: _now, onTick: _onCooldownTick);
  }

  final GetAppLockConfig _getConfig;
  final GetLockoutState _getLockoutState;
  final VerifyPin _verifyPin;
  final RecordFailedPinAttempt _recordFailedPinAttempt;
  final VerifyBiometric _verifyBiometric;
  final BiometricService _biometricService;
  final DateTime Function() _now;
  late final PinCooldownTicker _ticker;

  String _biometricReason = '';

  /// Set synchronously before any `await` so a double tap in the same frame
  /// can't submit twice (constitution Duplicate Action Protection).
  bool _isVerifyingPin = false;
  bool _isVerifyingBiometric = false;

  /// Loads the lock screen. [biometricReason] is the localized text shown
  /// in the OS prompt. With [promptBiometric] the biometric prompt opens
  /// immediately when it's enabled and available; the page passes `false`
  /// while the app is still in the background (a prompt can't be shown
  /// then) and calls [promptBiometricIfAvailable] on resume instead.
  Future<void> start({
    required String biometricReason,
    bool promptBiometric = true,
  }) async {
    _biometricReason = biometricReason;

    final config = await _getConfig();
    final biometricEnabled = config.match(
      (_) => false,
      (config) => config.isBiometricEnabled,
    );
    final biometricAvailable =
        biometricEnabled && await _biometricService.isAvailable();
    final lockout = await _getLockoutState();
    if (isClosed) return;

    emit(
      state.copyWith(
        status: LockScreenStatus.ready,
        isBiometricEnabled: biometricEnabled,
        isBiometricAvailable: biometricAvailable,
        // A config read error still leaves PIN entry fully working — the
        // repository enforces the cooldown on every attempt regardless.
        message: config.isLeft() ? LockScreenMessage.unexpected : null,
      ),
    );
    lockout.match((_) {}, _applyLockout);

    if (promptBiometric) await promptBiometricIfAvailable();
  }

  /// Opens the biometric prompt when biometric unlock is enabled and was
  /// available at the last check — used for the automatic prompt and for
  /// the manual "Use biometrics" button. Ignored while a prompt is already
  /// up, or once unlocked. Works during a PIN cooldown (FR-008).
  Future<void> promptBiometricIfAvailable() async {
    if (!state.canUseBiometric) return;
    await authenticateWithBiometric();
  }

  /// Runs one biometric attempt.
  Future<void> authenticateWithBiometric() async {
    if (_isVerifyingBiometric || state.isUnlocked || state.isLoading) return;
    if (!state.isBiometricEnabled) return;
    _isVerifyingBiometric = true;

    emit(
      state.copyWith(
        status: state.status == LockScreenStatus.verifyingPin
            ? null
            : LockScreenStatus.verifyingBiometric,
        clearMessage: true,
      ),
    );
    final result = await _verifyBiometric(localizedReason: _biometricReason);
    _isVerifyingBiometric = false;
    if (isClosed || state.isUnlocked) return;

    result.match((_) => _settle(LockScreenMessage.unexpected), (attempt) {
      switch (attempt.outcome) {
        case UnlockOutcome.success:
          _unlock();
        case UnlockOutcome.biometricUnavailable:
          // Enrollment changed or hardware gone since the last check:
          // PIN-only from here on (FR-007).
          emit(state.copyWith(isBiometricAvailable: false));
          _settle(LockScreenMessage.biometricUnavailable);
        case UnlockOutcome.biometricFailed:
        case UnlockOutcome.incorrectPin:
        case UnlockOutcome.lockedOut:
          // Never counted against the PIN lockout (FR-008).
          _settle(LockScreenMessage.biometricFailed);
      }
    });
  }

  /// Checks a PIN typed on the pad. Ignored during a cooldown, while
  /// another PIN is being checked, or once unlocked.
  Future<void> submitPin(String pin) async {
    if (_isVerifyingPin || !state.isPinEntryEnabled) return;
    _isVerifyingPin = true;

    emit(
      state.copyWith(status: LockScreenStatus.verifyingPin, clearMessage: true),
    );
    final result = await _verifyPin(pin);
    if (isClosed || state.isUnlocked) {
      _isVerifyingPin = false;
      return;
    }

    await result.match(
      (_) async => _settle(LockScreenMessage.unexpected, fromPin: true),
      (attempt) async {
        switch (attempt.outcome) {
          case UnlockOutcome.success:
            _unlock();
          case UnlockOutcome.lockedOut:
            // The persisted cooldown is still running (e.g. restored after
            // a relaunch in another instance) — show it.
            _settle(null, fromPin: true);
            final remaining = attempt.remainingCooldown;
            if (remaining != null) _ticker.start(_now().add(remaining));
          case UnlockOutcome.incorrectPin:
          case UnlockOutcome.biometricFailed:
          case UnlockOutcome.biometricUnavailable:
            await _onIncorrectPin();
        }
      },
    );
    _isVerifyingPin = false;
  }

  Future<void> _onIncorrectPin() async {
    // FR-013/FR-016: counts the attempt; the PIN itself is never passed on.
    final recorded = await _recordFailedPinAttempt();
    if (isClosed || state.isUnlocked) return;
    _settle(LockScreenMessage.incorrectPin, fromPin: true);
    recorded.match((Failure _) {}, _applyLockout);
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

  /// Back to waiting for input once an attempt ends — unless the other kind
  /// of attempt is still running. [fromPin] marks the PIN attempt itself
  /// settling (its in-flight flag is still set at that point).
  void _settle(LockScreenMessage? message, {bool fromPin = false}) {
    final status = !fromPin && _isVerifyingPin
        ? LockScreenStatus.verifyingPin
        : _isVerifyingBiometric
        ? LockScreenStatus.verifyingBiometric
        : LockScreenStatus.ready;
    emit(
      state.copyWith(
        status: status,
        message: message,
        clearMessage: message == null,
      ),
    );
  }

  void _unlock() {
    _ticker.cancel();
    emit(
      state.copyWith(
        status: LockScreenStatus.unlocked,
        clearCooldown: true,
        clearMessage: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }
}
