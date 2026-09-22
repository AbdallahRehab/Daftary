# Contract: AppLockRepository

Local-only Domain/Data boundary backed by `flutter_secure_storage`, not `drift` (research.md Decision 2 — see 011's `savings_repository.md` for why this replaces a network API contract in this codebase). All methods return `Either<Failure, T>`.

```dart
abstract class AppLockRepository {
  /// Current configuration; returns a default (isEnabled=false, empty
  /// activeUnlockMethods, inactivityTimeout=after1min) if never configured.
  Future<Either<Failure, AppLockConfig>> getConfig();

  /// Enables App Lock. Must be called only after setPin has already
  /// succeeded (FR-002) — the use case layer (EnableAppLock) enforces this
  /// ordering; this method itself just persists isEnabled=true.
  Future<Either<Failure, Unit>> enableAppLock();

  /// Disables App Lock and, per FR-027, deletes the stored PinCredential
  /// and resets LockoutState (data-model.md Assumptions) so a future
  /// re-enable always starts from fresh PIN setup.
  Future<Either<Failure, Unit>> disableAppLock();

  /// Sets a PIN for the first time. Rejects if a PinCredential already
  /// exists (caller should use changePin instead) or if rawPin fails
  /// PinHasher's length/digit validation (FR-003).
  Future<Either<Failure, Unit>> setPin(String rawPin);

  /// Replaces an existing PIN after the caller has already verified the
  /// current PIN or biometric (FR-023). Resets LockoutState (data-model.md
  /// Assumptions).
  Future<Either<Failure, Unit>> changePin(String newRawPin);

  /// Verifies a PIN attempt against the stored PinCredential via
  /// PinHasher.verify (constant-time comparison). On success, resets
  /// LockoutState (FR-014). On failure, the caller (VerifyPin use case)
  /// is responsible for invoking recordFailedPinAttempt — this method
  /// itself is a pure read+compare, not a side-effecting attempt-counter.
  /// Returns PinLockedOutFailure without even comparing if a cooldown is
  /// currently active (FR-013).
  Future<Either<Failure, bool>> verifyPin(String rawPin);

  /// Records one failed PIN attempt, applying LockoutPolicy's escalating
  /// schedule (research.md Decision 3) to compute and persist the next
  /// cooldownEndsAt if a threshold is crossed (FR-013). Never logs or
  /// persists the attempted rawPin value itself (FR-016) — callers must
  /// not pass it in; this method only touches the counter.
  Future<Either<Failure, LockoutState>> recordFailedPinAttempt();

  /// Current lockout state, for the lock screen to render a countdown
  /// (FR-013) or the PIN pad's enabled/disabled state.
  Future<Either<Failure, LockoutState>> getLockoutState();

  /// Enables/disables biometric as an active unlock method (FR-024).
  /// The caller (SetBiometricEnabled use case) is responsible for first
  /// confirming BiometricService.isAvailable() — this method just persists
  /// the resulting activeUnlockMethods set.
  Future<Either<Failure, Unit>> setBiometricEnabled(bool enabled);

  /// Updates the configured inactivity timeout (FR-025); takes effect on
  /// the next backgrounding per AppLifecycleObserver (research.md
  /// Decision 6).
  Future<Either<Failure, Unit>> setInactivityTimeout(InactivityTimeout timeout);
}
```

## Contract: BiometricService (abstract; `local_auth` wrapper — no `Either`, throws are caught internally and mapped to `bool`/`BiometricCheckResult`)

```dart
abstract class BiometricService {
  /// Whether the device currently reports biometric hardware present AND
  /// at least one biometric enrolled (queried live, never cached —
  /// research.md/spec Assumptions: "queried live... rather than cached
  /// indefinitely").
  Future<bool> isAvailable();

  /// Presents the OS biometric prompt. Returns true only on a genuine
  /// successful authentication. A user-cancelled or failed prompt returns
  /// false (never throws to the caller) so the caller can offer a retry
  /// or fall back to PIN entry (FR-007) without a failed attempt ever
  /// reaching the PIN lockout counter (FR-008).
  Future<bool> authenticate({required String localizedReason});
}
```

## Contract: PinHasher (pure Domain service — no I/O, no `Either`)

```dart
abstract class PinHasher {
  /// Validates rawPin is 4-6 numeric digits (FR-003); throws
  /// ArgumentError if not — callers translate to a typed Failure at the
  /// use-case boundary, this service stays exception-based internally
  /// since it never crosses a repository I/O boundary.
  void validate(String rawPin);

  /// Generates a fresh random salt and derives {hash, salt, iterations}
  /// via PBKDF2-HMAC-SHA256 (research.md Decision 7).
  PinCredential hash(String rawPin);

  /// Constant-time comparison of rawPin (re-hashed with the stored salt/
  /// iterations) against an existing PinCredential.hash.
  bool verify(String rawPin, PinCredential credential);
}
```

## Contract: LockoutPolicy (pure Domain service — no I/O, no `Either`)

```dart
abstract class LockoutPolicy {
  /// FR-013's escalating schedule as pure input→output:
  /// 0-4 failures -> null (no cooldown)
  /// 5-7 failures -> Duration(seconds: 30)
  /// 8 failures   -> Duration(minutes: 2)
  /// 8 + 3n failures (n>=1) -> Duration(minutes: 5)
  /// Any other count between thresholds -> the most recently crossed
  /// threshold's duration (a cooldown, once triggered, holds until its
  /// own end time regardless of further attempts made while already
  /// locked out — recordFailedPinAttempt is not even reachable mid-cooldown
  /// per AppLockRepository.verifyPin's short-circuit).
  Duration? cooldownFor(int consecutiveFailedAttempts);
}
```

**Failure modes**: `IncorrectPinFailure`, `PinLockedOutFailure` (carries `remainingCooldown`), `PinMismatchFailure` (confirm-entry didn't match during setup/change — a Presentation/Cubit-level check, not a repository call, since nothing is persisted until the two entries already match), `BiometricUnavailableFailure`, `NotFoundFailure` (no `PinCredential` configured yet), `CacheFailure` (secure-storage read/write error), `UnknownFailure`.

**Idempotency note**: `enableAppLock`/`disableAppLock`/`setPin`/`changePin` act on a single-record configuration (not a list), so a duplicate rapid-tap simply reapplies the same end state — still guarded at the Presentation layer (disabled submit button while in flight, per constitution Engineering Standards "Duplicate Action Protection") but with no risk of creating a *second* PIN or a *duplicate* record the way a list-based entity (e.g. `SavingsContribution`) would need an idempotency key for.

**Cross-feature note**: `AppLockRepository` calls no other feature's repository. `WipeAllLocalData` (used by the Forgot-PIN destructive path) is the one use case in this feature that reaches outside `app_lock`'s own boundary — it clears every table in `AppDatabase` plus this feature's own secure-storage keys, and is intentionally *not* expressed as a method on `AppLockRepository` itself (which owns only App Lock's own state) — see research.md Decision 4 for the documented seam with the future `DeleteAllUserData` (V1.5.3) use case.
