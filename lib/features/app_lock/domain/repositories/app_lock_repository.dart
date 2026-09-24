import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_lock_config.dart';
import '../entities/lockout_state.dart';

/// App Lock's Domain/Data boundary, backed by OS secure storage — never
/// `AppDatabase` (research.md Decision 2). See
/// `specs/015-app-lock-security/contracts/app_lock_repository.md`.
///
/// Failure modes: `ValidationFailure` (PIN not 4-6 digits),
/// `PinLockedOutFailure`, `NotFoundFailure` (no PIN configured),
/// `CacheFailure` (secure-storage read/write error).
abstract class AppLockRepository {
  /// Current configuration; [AppLockConfig.initial] (disabled, no methods,
  /// 1-minute timeout) if never configured.
  Future<Either<Failure, AppLockConfig>> getConfig();

  /// Persists `isEnabled = true`. The `EnableAppLock` use case guarantees a
  /// PIN was set first (FR-002). `NotFoundFailure` if no PIN is stored.
  Future<Either<Failure, Unit>> enableAppLock();

  /// Disables App Lock and deletes the stored PIN credential and lockout
  /// state (FR-027) so a re-enable always starts from fresh PIN setup. The
  /// inactivity timeout preference is kept.
  Future<Either<Failure, Unit>> disableAppLock();

  /// Sets the first PIN. `ValidationFailure` if [rawPin] isn't 4-6 digits
  /// (FR-003) or a PIN already exists (use [changePin]).
  Future<Either<Failure, Unit>> setPin(String rawPin);

  /// Replaces the existing PIN after the caller has already re-authenticated
  /// (FR-023) and resets the lockout state. `ValidationFailure` for a bad
  /// PIN, `NotFoundFailure` if no PIN exists yet.
  Future<Either<Failure, Unit>> changePin(String newRawPin);

  /// Compares [rawPin] against the stored credential (constant time).
  /// `Right(true)` on a match — and the lockout state is reset (FR-014);
  /// `Right(false)` on a mismatch — the counter is NOT touched (the
  /// `VerifyPin` use case calls [recordFailedPinAttempt]).
  /// `Left(PinLockedOutFailure)` without comparing while a cooldown is
  /// active (FR-013); `Left(NotFoundFailure)` if no PIN is stored.
  Future<Either<Failure, bool>> verifyPin(String rawPin);

  /// Records one failed PIN attempt and, per `LockoutPolicy`, persists the
  /// resulting cooldown end time (FR-013). Never receives the raw PIN.
  Future<Either<Failure, LockoutState>> recordFailedPinAttempt();

  /// Current lockout state, for the countdown and PIN pad enablement.
  Future<Either<Failure, LockoutState>> getLockoutState();

  /// Resets the failed-attempt counter and cooldown — used after a
  /// successful biometric unlock (FR-014), which never goes through
  /// [verifyPin].
  Future<Either<Failure, Unit>> resetLockout();

  /// Adds/removes biometric from the active unlock methods (FR-024). The
  /// caller checks `BiometricService.isAvailable()` first.
  Future<Either<Failure, Unit>> setBiometricEnabled(bool enabled);

  /// Updates the inactivity timeout (FR-025); read fresh by
  /// `AppLifecycleObserver` on the next backgrounding.
  Future<Either<Failure, Unit>> setInactivityTimeout(InactivityTimeout timeout);
}
