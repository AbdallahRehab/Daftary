# Phase 0 Research: App Lock (Biometric/PIN) & Screenshot Protection

## 1. Native platform channel vs. a third-party screenshot-protection plugin

**Decision**: Implement a small, purpose-built platform channel (`SecurityPlugin.kt`/`SecurityPlugin.swift`) rather than adopting a third-party Flutter plugin for screenshot/recording protection.

**Rationale**: The Android surface needed is one flag (`FLAG_SECURE` on the activity window); the iOS surface needed is toggling a privacy overlay around two lifecycle callbacks and observing `UIScreen.capturedDidChangeNotification`. This is small and stable enough that a full third-party dependency (with its own maintenance/version-compatibility risk) is not justified per the constitution's "unjustified new dependencies" prohibition — a native channel this thin is the simpler, more maintainable, more auditable choice, and keeps the security-critical code directly reviewable in-repo rather than trusted to an external package.

**Alternatives considered**: `screen_protector`/similar community packages — rejected as an unjustified dependency for ~20 lines of platform code per side; a Dart-only approach — rejected, no such capability exists without native code on either platform.

## 2. App Lock configuration storage: secure storage, not `AppDatabase`

**Decision**: All App Lock state (enabled flag, active unlock methods, inactivity timeout, PIN hash + salt, lockout attempt count + cooldown-end timestamp) is stored via `flutter_secure_storage`, entirely outside the existing `drift`/SQLite `AppDatabase`.

**Rationale**: This data's entire purpose is to gate access to `AppDatabase`'s contents. Storing the PIN hash or lockout state inside the very database it's meant to protect would be a circular trust boundary (anyone with raw file access to the unencrypted SQLite file could read or tamper with the gate itself) and would also entangle a purely local-device security concern with the app's synchronizable/exportable financial data. `flutter_secure_storage` uses Keychain (iOS) / EncryptedSharedPreferences-backed Keystore (Android), matching constitution Principle XII exactly.

**Alternatives considered**: A new `drift` table — rejected for the circularity reason above; `shared_preferences` (plaintext) — rejected outright, violates Principle XII for a PIN hash and especially for the salt.

## 3. Escalating lockout policy as a pure function

**Decision**: `LockoutPolicy` is a pure, deterministic Domain service: given a consecutive-failure count, it returns the required cooldown duration (0 for <5 failures, 30s at the 5th, 2min at the 8th, +5min for every 3 additional failures beyond the 8th — spec FR-013). It takes no dependencies and performs no I/O; `RecordFailedPinAttempt` (a use case) is what actually persists the resulting state via `AppLockRepository`.

**Rationale**: Separating the *schedule* (pure math, exhaustively unit-testable with a simple input→output table) from the *persistence* (which requires a repository and is tested with fakes) mirrors the same reasoning 011-savings-goals applied to `SavingsCalculator` — the riskiest-to-get-wrong logic in the feature is isolated where it's cheapest and fastest to test.

**Alternatives considered**: Encoding the schedule directly inside `AppLockRepositoryImpl` — rejected, would force every schedule-logic test through a fake-secure-storage repository instead of a trivial pure-function test.

## 4. `WipeAllLocalData` — a shared boundary with the future Data-Privacy feature

**Decision**: This feature introduces its own `WipeAllLocalData` use case (for the Forgot-PIN destructive-recovery path, spec FR-018/FR-019) scoped inside `app_lock`, rather than depending on the not-yet-built `DeleteAllUserData` use case from roadmap V1.5.3 (Reports & Data/Privacy Controls). When V1.5.3 is eventually implemented, its own `/speckit-plan` should either (a) have `app_lock`'s `WipeAllLocalData` call into the shared `DeleteAllUserData` domain logic once it exists, or (b) consolidate both call sites onto one canonical wipe implementation — this plan does not implement that consolidation now, since V1.5.3 does not yet exist in this codebase, but documents the seam explicitly so it isn't silently duplicated logic later.

**Rationale**: Constitution Principle V (no duplicated sources of truth) is honored by flagging this explicitly now rather than pretending the dependency doesn't exist; building `app_lock`'s own wipe now (rather than blocking this entire feature on V1.5.3 being built first) is the pragmatic sequencing choice consistent with this feature having "no dependency on any other unbuilt feature" per the roadmap.

**Alternatives considered**: Blocking this feature until V1.5.3 ships — rejected, contradicts the roadmap's explicit statement that App Lock has no hard dependency on any unbuilt feature.

## 5. Router-level lock interception vs. a per-screen guard

**Decision**: A single `go_router` top-level `redirect` (or an equivalent full-screen overlay raised above the `Navigator` via `MaterialApp.builder`) checks `AppLockRepository`'s current lock state ahead of rendering any route, rather than adding a lock-check to every individual screen.

**Rationale**: This is the only way to guarantee zero gaps (spec Constraints: "the lock screen must intercept every app entry point... with zero gaps") — a per-screen guard requires every current and future screen to remember to add it, which is exactly the kind of "duplicated across widgets" navigation anti-pattern the constitution's Engineering Standards (Navigation) explicitly prohibits ("navigation decisions MUST NOT be duplicated across widgets").

**Alternatives considered**: A per-screen `AppLockGuard` wrapper widget added individually to each page — rejected as fragile (silently bypassable by forgetting to add it to a new screen) and duplicative.

## 6. Distinguishing genuine backgrounding from a brief system interruption

**Decision**: `AppLifecycleObserver` (a `WidgetsBindingObserver`) starts an inactivity timer only on `AppLifecycleState.paused` (true backgrounding), not on `AppLifecycleState.inactive` (the transient state used for interruptions like an incoming call banner, a permission dialog, or the OS share sheet, none of which fully background the app). The timer is cancelled if the app returns to `resumed` before it elapses; if it elapses while still backgrounded, the lock state is set and enforced by the router redirect (Decision 5) on the next resume.

**Rationale**: Flutter's own `AppLifecycleState` already distinguishes exactly this (`inactive` = momentarily not receiving events but still foregrounded/visible, e.g. a system dialog; `paused` = fully backgrounded/not visible) — using the platform's own signal rather than inventing a custom heuristic is both simpler and more reliable, directly satisfying FR-010's edge case.

**Alternatives considered**: A single combined "app not focused" timer with no distinction between `inactive`/`paused` — rejected, would fail the OS-share-sheet and permission-dialog edge cases explicitly called out in the spec.

## 7. PIN hashing primitive

**Decision**: PBKDF2 (via the `crypto` package's `Hmac`/`sha256`, iterated, e.g. 100k+ rounds) with a per-installation random salt (generated once via a CSPRNG at first PIN setup and stored alongside the hash in secure storage), rather than a bespoke hashing scheme or a single unsalted SHA-256 pass.

**Rationale**: A 4-6 digit numeric PIN has a tiny keyspace (10,000–1,000,000 possibilities) — a single fast hash (even salted) is still crackable in a local-storage-compromise scenario in negligible time; a deliberately slow, iterated KDF is the standard mitigation and is proportionate effort for a security feature the constitution treats as first-class (Principle XII), while still being trivially fast enough at verification time (single PIN check, not a hot loop) to have zero user-facing latency impact.

**Alternatives considered**: `bcrypt`/`argon2` Dart packages — considered but not chosen to avoid adding a package with less mature/maintained Flutter-specific bindings than the well-established `crypto` package already available in the Dart ecosystem; PBKDF2 via `crypto` is judged sufficient given the local-secure-storage threat model (the primary defense is the OS Keychain/Keystore itself, not the hash alone).
