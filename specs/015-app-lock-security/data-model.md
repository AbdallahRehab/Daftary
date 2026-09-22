# Phase 1 Data Model: App Lock (Biometric/PIN) & Screenshot Protection

*All entities below live in OS secure storage (`flutter_secure_storage`), never in `AppDatabase`/`drift` — see research.md Decision 2. There is no SQL schema for this feature.*

## Entity: AppLockConfig (NEW, secure storage)

The user's overall security configuration. A single record (not a list — one device, one configuration).

| Field | Type | Notes |
|---|---|---|
| `isEnabled` | `bool` | Whether App Lock gates the app at all. Default `false` (FR-001). |
| `activeUnlockMethods` | `Set<UnlockMethod>` | Subset of `{pin, biometric}`. `pin` is always present once `isEnabled` is `true` (FR-002); `biometric` present only if the user opted in and the device supports it (FR-005). |
| `inactivityTimeout` | `InactivityTimeout` (enum: `immediately`, `after30s`, `after1min`, `after5min`) | Default `after1min` on first enable (FR-011). |
| `pinLastChangedAt` | `DateTime?` | For potential future auditing; never used to reconstruct the PIN itself. |

## Entity: PinCredential (NEW, secure storage)

The user's PIN, represented irreversibly.

| Field | Type | Notes |
|---|---|---|
| `hash` | `String` (base64/hex) | PBKDF2-HMAC-SHA256 output over the raw PIN + `salt` (research.md Decision 7). Never the raw PIN. |
| `salt` | `String` (base64/hex) | Per-installation random salt, generated once at first PIN setup via a CSPRNG. |
| `iterations` | `int` | KDF iteration count used to produce `hash`, stored alongside so a future increase in the default iteration count doesn't invalidate existing credentials without an explicit migration. |

**Validation rules** (enforced in `PinHasher`/`SetPin`/`ChangePin`, not at this storage layer): raw PIN 4-6 numeric digits only (FR-003); confirm-entry must match (spec User Story 1 Scenario 3) before `PinCredential` is ever written.

## Entity: LockoutState (NEW, secure storage)

Tracks brute-force protection. Persisted (not in-memory only) so a relaunch cannot bypass an active cooldown (FR-015).

| Field | Type | Notes |
|---|---|---|
| `consecutiveFailedAttempts` | `int` | Incremented by `RecordFailedPinAttempt` on each wrong PIN; reset to `0` on any successful PIN or biometric unlock (FR-014). Biometric failures never increment this (FR-008). |
| `cooldownEndsAt` | `DateTime?` | `null` when not in cooldown. Set by `RecordFailedPinAttempt` per `LockoutPolicy`'s schedule (research.md Decision 3) whenever a threshold is crossed. |

**State transitions**:

```text
0 failures ──(wrong PIN)──► 1..4 failures (no cooldown)
1..4 failures ──(wrong PIN, reaching 5)──► cooldownEndsAt = now + 30s
5..7 failures ──(wrong PIN, reaching 8)──► cooldownEndsAt = now + 2min
8+ failures ──(wrong PIN, every +3 beyond 8)──► cooldownEndsAt = now + 5min
any state ──(correct PIN or successful biometric)──► consecutiveFailedAttempts = 0, cooldownEndsAt = null
```

## Value Object: UnlockAttemptResult *(ephemeral, not persisted)*

Returned by `VerifyPin`/`VerifyBiometric` to the calling Cubit.

| Field | Type | Notes |
|---|---|---|
| `outcome` | enum: `success`, `incorrectPin`, `lockedOut`, `biometricUnavailable`, `biometricFailed` | Drives the lock screen's next UI state. |
| `remainingCooldown` | `Duration?` | Present only when `outcome == lockedOut`; drives the countdown display (FR-013). |

## Relationships

```text
AppLockConfig ──1:1── PinCredential   (PinCredential present only if `pin` ∈ activeUnlockMethods)
AppLockConfig ──1:1── LockoutState    (always present once isEnabled has ever been true; persists
                                        even across a PIN change, reset only by ChangePin's own
                                        fresh-start semantics — see Assumptions below)
```

No relationship to any existing entity (`Person`, `MoneyTransaction`, `FinanceEntry`, etc.) — this feature reads and writes nothing in `AppDatabase` (FR-030).

## Secure Storage Key Sketch (for Phase 2 task planning, not exhaustive)

```text
app_lock.config              -> JSON-encoded AppLockConfig
app_lock.pin_credential      -> JSON-encoded PinCredential
app_lock.lockout_state       -> JSON-encoded LockoutState
```

Three logical keys under the `flutter_secure_storage` namespace this feature owns exclusively; no other feature reads or writes these keys (enforced by keeping `SecureAppLockStorage` as the sole data source touching them, per the Repository Pattern gate).

## Assumptions

- **`ChangePin` resets `LockoutState`**: Setting a new PIN (whether via normal "Change PIN" or via the Forgot-PIN biometric-recovery path) clears `consecutiveFailedAttempts` to 0 and `cooldownEndsAt` to `null`, since the old lockout was scoped to attempts against the now-superseded PIN.
- **Disabling App Lock clears all three entities**: Per spec FR-027, re-enabling App Lock always requires fresh PIN setup — disabling therefore deletes `PinCredential` and `LockoutState` outright (not merely flips `isEnabled`), so no stale credential could ever be silently reused.
