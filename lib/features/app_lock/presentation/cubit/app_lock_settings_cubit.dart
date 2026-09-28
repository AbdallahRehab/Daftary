import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/app_lock_config.dart';
import '../../domain/entities/app_lock_failures.dart';
import '../../domain/entities/lockout_state.dart';
import '../../domain/services/biometric_service.dart';
import '../../domain/usecases/disable_app_lock.dart';
import '../../domain/usecases/enable_app_lock.dart';
import '../../domain/usecases/get_app_lock_config.dart';
import '../../domain/usecases/record_failed_pin_attempt.dart';
import '../../domain/usecases/set_biometric_enabled.dart';
import '../../domain/usecases/set_inactivity_timeout.dart';
import '../../domain/usecases/verify_biometric.dart';
import '../../domain/usecases/verify_pin.dart';
import 'app_lock_settings_state.dart';

/// Drives the Security settings screen (User Story 6): App Lock on/off,
/// the biometric toggle, the inactivity timeout, and Change PIN.
///
/// - **Enable** (FR-002/FR-027): the page first runs `PinSetupPage` in
///   initial-setup mode whenever [needsPinSetup] — which, because
///   [DisableAppLock] deletes the credential, is every enable after a
///   disable — and only then calls [enableAfterPinSetup].
/// - **Change PIN** (FR-023): `PinSetupPage` in change mode owns the whole
///   flow including the current-PIN/biometric re-authentication; this cubit
///   only refreshes afterwards ([pinChanged]).
/// - **Disable** (FR-026): gated on a fresh re-authentication through
///   [reauthenticateWithPin] or [reauthenticateWithBiometric]. [disable]
///   refuses to run without one, and consumes it, so each disable needs its
///   own re-authentication.
///
/// Duplicate Action Protection: every action checks
/// [AppLockSettingsState.isSubmitting] synchronously, before its first
/// `await`.
@injectable
class AppLockSettingsCubit extends Cubit<AppLockSettingsState> {
  AppLockSettingsCubit(
    this._getConfig,
    this._biometrics,
    this._enableAppLock,
    this._disableAppLock,
    this._setBiometricEnabled,
    this._setInactivityTimeout,
    this._verifyPin,
    this._verifyBiometric,
    this._recordFailedPinAttempt, {
    @ignoreParam DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const AppLockSettingsState());

  final GetAppLockConfig _getConfig;
  final BiometricService _biometrics;
  final EnableAppLock _enableAppLock;
  final DisableAppLock _disableAppLock;
  final SetBiometricEnabled _setBiometricEnabled;
  final SetInactivityTimeout _setInactivityTimeout;
  final VerifyPin _verifyPin;
  final VerifyBiometric _verifyBiometric;
  final RecordFailedPinAttempt _recordFailedPinAttempt;
  final DateTime Function() _now;

  /// Set by a successful re-authentication, consumed by [disable].
  bool _isReauthenticated = false;

  /// Whether turning App Lock on must first go through PIN setup. `false`
  /// only when a PIN was stored but enabling then failed, so the user is
  /// not asked to invent a second PIN for the same attempt.
  bool get needsPinSetup => !state.config.hasPin;

  Future<void> load() async {
    emit(
      state.copyWith(status: AppLockSettingsStatus.loading, clearFailure: true),
    );
    final result = await _getConfig();
    final biometricAvailable = await _biometrics.isAvailable();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AppLockSettingsStatus.loadFailure,
          isBiometricAvailable: biometricAvailable,
          failure: failure,
        ),
      ),
      (config) => emit(
        state.copyWith(
          status: AppLockSettingsStatus.ready,
          config: config,
          isBiometricAvailable: biometricAvailable,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- enable

  /// Called once `PinSetupPage` (initial setup) reported success — or
  /// directly when ![needsPinSetup]. The inactivity timeout keeps its
  /// stored value, which defaults to one minute (FR-011).
  Future<void> enableAfterPinSetup() async {
    if (state.isSubmitting || state.isEnabled) return;
    await _submit(_enableAppLock.call, AppLockSettingsOutcome.enabled);
  }

  /// Called after `PinSetupPage` (change mode) reported success.
  Future<void> pinChanged() async {
    if (state.isSubmitting) return;
    await _submit(
      () async => const Right<Failure, Unit>(unit),
      AppLockSettingsOutcome.pinChanged,
    );
  }

  // ------------------------------------------------------------- settings

  /// FR-024: independent of the PIN, which is never touched. Turning it on
  /// re-checks availability live, so a device that lost its enrolment since
  /// the screen was opened gets a clear failure instead of a dead toggle.
  Future<void> setBiometricEnabled(bool enabled) async {
    if (state.isSubmitting || !state.isEnabled) return;
    if (enabled == state.config.isBiometricEnabled) return;
    await _submit(() => _setBiometricEnabled(enabled), null);
  }

  /// FR-025: applies from the next backgrounding.
  Future<void> setInactivityTimeout(InactivityTimeout timeout) async {
    if (state.isSubmitting || !state.isEnabled) return;
    if (timeout == state.config.inactivityTimeout) return;
    await _submit(() => _setInactivityTimeout(timeout), null);
  }

  // --------------------------------------------------------------- disable

  /// Re-authenticates with the current PIN before a disable. Returns the
  /// attempt's result (incorrect PIN / locked out / success) so the PIN
  /// prompt can explain it; a wrong PIN counts toward the lockout exactly
  /// as on the lock screen (FR-013). `null` for an unexpected failure.
  Future<UnlockAttemptResult?> reauthenticateWithPin(String pin) async {
    _isReauthenticated = false;
    final result = await _verifyPin(pin);
    final attempt = result.fold<UnlockAttemptResult?>(
      (Failure failure) => failure is PinLockedOutFailure
          ? UnlockAttemptResult.lockedOut(failure.remainingCooldown)
          : null,
      (UnlockAttemptResult attempt) => attempt,
    );
    if (attempt == null) return null;
    if (attempt.isSuccess) {
      _isReauthenticated = true;
      return attempt;
    }
    if (attempt.outcome != UnlockOutcome.incorrectPin) return attempt;
    // `VerifyPin` never touches the counter; a wrong PIN here counts
    // exactly like one on the lock screen, and may start a cooldown.
    final lockout = await _recordFailedPinAttempt();
    final remaining = lockout.fold(
      (Failure _) => null,
      (LockoutState state) => state.remainingCooldownAt(_now()),
    );
    return remaining == null
        ? attempt
        : UnlockAttemptResult.lockedOut(remaining);
  }

  /// Re-authenticates with biometrics before a disable. `false` for any
  /// non-success, after which the page falls back to the PIN prompt.
  Future<bool> reauthenticateWithBiometric({
    required String localizedReason,
  }) async {
    _isReauthenticated = false;
    if (!state.config.isBiometricEnabled || !state.isBiometricAvailable) {
      return false;
    }
    final result = await _verifyBiometric(localizedReason: localizedReason);
    _isReauthenticated = result.fold(
      (Failure _) => false,
      (UnlockAttemptResult a) => a.isSuccess,
    );
    return _isReauthenticated;
  }

  /// The user backed out of the re-authentication prompt.
  void cancelReauthentication() => _isReauthenticated = false;

  /// Disables App Lock and deletes the PIN (FR-026/FR-027). Refused unless
  /// a re-authentication just succeeded; screenshot protection is left on
  /// (FR-020).
  Future<void> disable() async {
    if (state.isSubmitting || !state.isEnabled || !_isReauthenticated) return;
    _isReauthenticated = false;
    await _submit(_disableAppLock.call, AppLockSettingsOutcome.disabled);
  }

  // --------------------------------------------------------------- helpers

  /// Runs [action], then re-reads the configuration so the screen always
  /// reflects what was actually persisted.
  Future<void> _submit(
    Future<Either<Failure, Unit>> Function() action,
    AppLockSettingsOutcome? outcome,
  ) async {
    emit(
      state.copyWith(
        status: AppLockSettingsStatus.submitting,
        clearFailure: true,
      ),
    );
    final result = await action();
    if (isClosed) return;
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    final refreshed = await _getConfig();
    final biometricAvailable = failure is BiometricUnavailableFailure
        ? false
        : state.isBiometricAvailable;
    if (isClosed) return;
    emit(
      state.copyWith(
        status: AppLockSettingsStatus.ready,
        config: refreshed.getOrElse((_) => state.config),
        isBiometricAvailable: biometricAvailable,
        failure: failure ?? refreshed.getLeft().toNullable(),
        outcome: failure == null ? outcome : null,
      ),
    );
  }
}
