---

description: "Task list template for feature implementation"
---

# Tasks: App Lock (Biometric/PIN) & Screenshot Protection

**Input**: Design documents from `/specs/015-app-lock-security/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included — the constitution's Testability by Design principle and this feature's own security-critical nature (PIN hashing, lockout math, secure-storage boundary) make test coverage non-optional in practice, matching the precedent set by 011-savings-goals.

**Organization**: Tasks are grouped by user story (spec.md) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US6)
- Include exact file paths in descriptions

## Path Conventions

Mobile Flutter app (existing structure): `lib/features/app_lock/{data,domain,presentation}/`, `lib/core/security/`, `test/features/app_lock/`, `test/core/security/`, `integration_test/`, plus native platform code under `android/app/src/main/kotlin/` and `ios/Runner/`.

---

## Phase 1: Setup

**Purpose**: Project initialization and dependency setup

- [X] T001 Create the directory skeleton: `lib/features/app_lock/{data/{datasources,services,repositories},domain/{entities,repositories,services,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/features/app_lock/{domain/services,domain/usecases,data/repositories,presentation/cubit}/`, plus `lib/core/security/` and `test/core/security/`.
- [X] T002 Add `local_auth`, `flutter_secure_storage`, and `crypto` to `pubspec.yaml` (research.md Decisions 1/2/7); run `fvm flutter pub get`.
- [X] T003 [P] Add Android biometric/permission manifest entries (`USE_BIOMETRIC`/`USE_FINGERPRINT` in `android/app/src/main/AndroidManifest.xml`) and iOS `NSFaceIDUsageDescription` in `ios/Runner/Info.plist`, per constitution Engineering Standards (permissions requested contextually, with a shown rationale).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core entities, storage boundary, and native platform channels that MUST exist before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 [P] Define the `AppLockConfig` entity (`isEnabled`, `activeUnlockMethods: Set<UnlockMethod>`, `inactivityTimeout: InactivityTimeout`, `pinLastChangedAt?`) and the `UnlockMethod`/`InactivityTimeout` enums in `lib/features/app_lock/domain/entities/app_lock_config.dart`, per data-model.md.
- [X] T005 [P] Define the `PinCredential` entity (`hash`, `salt`, `iterations`) in `lib/features/app_lock/domain/entities/pin_credential.dart`, per data-model.md — never exposes or logs the raw PIN by construction (no raw-PIN field exists on this type at all).
- [X] T006 [P] Define the `LockoutState` entity (`consecutiveFailedAttempts`, `cooldownEndsAt?`) and the `UnlockAttemptResult` value object (`outcome` enum: `success`/`incorrectPin`/`lockedOut`/`biometricUnavailable`/`biometricFailed`, `remainingCooldown?`) in `lib/features/app_lock/domain/entities/lockout_state.dart`, per data-model.md.
- [X] T007 [P] Add `IncorrectPinFailure`, `PinLockedOutFailure` (carries `remainingCooldown`), `PinMismatchFailure`, `BiometricUnavailableFailure` to `lib/features/app_lock/domain/entities/app_lock_failures.dart`, extending the core `Failure`.
- [X] T008 Implement the pure `PinHasher` interface and implementation (PBKDF2-HMAC-SHA256 via `crypto`, per-install random salt, 100k+ iterations, research.md Decision 7) in `lib/features/app_lock/domain/services/pin_hasher.dart`: `validate(rawPin)` enforces 4-6 numeric digits only (FR-003, throws `ArgumentError` on violation), `hash(rawPin)` returns a fresh `PinCredential`, `verify(rawPin, credential)` does a constant-time comparison — per `contracts/app_lock_repository.md`.
- [X] T009 [P] **Exhaustive unit test** `PinHasher`: accepts 4/5/6-digit PINs, rejects <4 and >6 digits and non-numeric input (FR-003), `verify` returns true only for the exact original PIN re-hashed with the stored salt, two `hash()` calls for the same PIN produce different salts/hashes (no salt reuse), timing-safety of `verify` is structurally reviewed (constant-time comparison, not early-exit string equality) — in `test/features/app_lock/domain/services/pin_hasher_test.dart`. This is a release-blocking correctness anchor for SC-008/Principle XII.
- [X] T010 Implement the pure `LockoutPolicy` interface and implementation (research.md Decision 3) in `lib/features/app_lock/domain/services/lockout_policy.dart`: `cooldownFor(consecutiveFailedAttempts)` returns `null` for 0-4, `Duration(seconds: 30)` at 5-7, `Duration(minutes: 2)` at 8, `Duration(minutes: 5)` for every +3 beyond 8 (FR-013), per `contracts/app_lock_repository.md`.
- [X] T011 [P] **Exhaustive unit test** `LockoutPolicy` against every threshold boundary (4→null, 5→30s, 7→30s, 8→2min, 11→5min, 14→5min) — in `test/features/app_lock/domain/services/lockout_policy_test.dart`. This is the primary automated evidence for SC-006.
- [X] T012 Define the `AppLockRepository` abstract interface in `lib/features/app_lock/domain/repositories/app_lock_repository.dart` per `contracts/app_lock_repository.md` (all method signatures — implemented incrementally across US1-US6).
- [X] T013 Define the `BiometricService` abstract interface in `lib/features/app_lock/domain/services/biometric_service.dart` per `contracts/app_lock_repository.md` (`isAvailable()`, `authenticate({localizedReason})`, never throws to the caller — FR-007).
- [X] T014 Implement `SecureAppLockStorage` (the sole `flutter_secure_storage` data source touching the `app_lock.*` keys, per data-model.md's Secure Storage Key Sketch and the Repository Pattern gate) in `lib/features/app_lock/data/datasources/secure_app_lock_storage.dart`: JSON read/write for `AppLockConfig`, `PinCredential`, `LockoutState`, plus atomic delete-all-app-lock-keys for the disable/re-enable-requires-fresh-setup flow (FR-027).
- [X] T015 [P] Repository test against a fake in-memory implementation of the secure-storage platform channel (never the real Keychain/Keystore in tests, per plan.md Testability gate): round-trip read/write for all three entities — in `test/features/app_lock/data/datasources/secure_app_lock_storage_test.dart`.
- [X] T016 Implement `AppLockRepositoryImpl` in `lib/features/app_lock/data/repositories/app_lock_repository_impl.dart` implementing `getConfig`/`enableAppLock`/`disableAppLock`/`setPin`/`changePin`/`verifyPin`/`recordFailedPinAttempt`/`getLockoutState`/`setBiometricEnabled`/`setInactivityTimeout`, composing `SecureAppLockStorage` (T014), `PinHasher` (T008), and `LockoutPolicy` (T010) exactly per `contracts/app_lock_repository.md`'s method-by-method contract (including `verifyPin`'s short-circuit on an active cooldown, `disableAppLock`'s credential/lockout wipe, `changePin`'s lockout reset).
- [X] T017 [P] Implement `LocalAuthBiometricService` (implements `BiometricService`) in `lib/features/app_lock/data/services/local_auth_biometric_service.dart` wrapping the `local_auth` plugin: `isAvailable()` queries live (never cached, per spec Assumptions), `authenticate()` catches all `local_auth` exceptions internally and returns `false` rather than throwing (FR-007).
- [X] T018 Implement the native `SecurityPlugin` platform channel: Android `FLAG_SECURE` set/clear (`android/app/src/main/kotlin/.../SecurityPlugin.kt`) and iOS privacy-overlay + `UIScreen.capturedDidChangeNotification` observation (`ios/Runner/SecurityPlugin.swift`), per research.md Decision 1. Expose a Dart-side `ScreenshotProtectionService` interface in `lib/core/security/screenshot_protection_service.dart` with `enable()`/`disable()`/an active-recording stream, always invoked as always-on (FR-020/FR-021) independent of App Lock's own enabled state.
- [X] T019 [P] Widget/platform-channel test for `ScreenshotProtectionService` using a `MethodChannel` test double (mock platform responses, no real OS screen capture) confirming `enable()` is invoked at app start regardless of `AppLockConfig.isEnabled` — in `test/core/security/screenshot_protection_service_test.dart`.
- [X] T020 Implement `AppLifecycleObserver` (`WidgetsBindingObserver`) in `lib/core/security/app_lifecycle_observer.dart` per research.md Decision 6: starts the inactivity timer only on `AppLifecycleState.paused`, cancels it on return to `resumed` before it elapses, and exposes a "should show lock screen" signal combining `(timer elapsed while paused) OR (fresh cold launch)` for the router redirect (T023) to consume.
- [X] T021 [P] Unit test `AppLifecycleObserver`: `paused` past the configured timeout triggers the lock signal; a `paused→resumed` transition before the timeout does NOT trigger it; the transient `inactive` state alone (simulating a permission dialog/incoming call/OS share sheet) never starts the timer at all (FR-010 edge cases) — in `test/core/security/app_lifecycle_observer_test.dart`. This is the primary automated evidence for the plan.md's highest-risk-correctness requirement.
- [X] T022 Register `SecureAppLockStorage`, `AppLockRepositoryImpl` (as `AppLockRepository`), `LocalAuthBiometricService` (as `BiometricService`), `PinHasher`, `LockoutPolicy`, `ScreenshotProtectionService`, and `AppLifecycleObserver` with `@injectable`/`@LazySingleton(as: ...)` in `lib/core/di/`; run `fvm dart run build_runner build --delete-conflicting-outputs`.
- [X] T023 Wire a top-level `go_router` `redirect` (or `MaterialApp.builder` overlay) in `lib/core/routing/app_router.dart` that consults `AppLockRepository.getConfig()` + `AppLifecycleObserver`'s lock signal ahead of rendering any route (research.md Decision 5) — the single cross-cutting change every other existing feature's screens rely on for correctness without any change of their own.
- [X] T024 Initialize `ScreenshotProtectionService.enable()` and register `AppLifecycleObserver` unconditionally at app startup in `lib/main.dart`, alongside the existing DI bootstrap (independent of whether App Lock itself is ever enabled, per FR-020).

**Checkpoint**: Foundation ready — secure storage boundary, PIN hashing, lockout math, biometric wrapper, screenshot protection, and the router-level lock gate all exist and are independently tested. User story implementation can now begin.

---

## Phase 3: User Story 1 - Enable App Lock and Set a PIN (Priority: P1) 🎯 MVP (part 1 of 3)

**Goal**: A user can turn App Lock on, set a PIN (confirmed twice), and have it actually gate the app on relaunch/resume.

**Independent Test**: Enable App Lock, set a matching PIN, background and reopen the app, confirm the lock screen appears and only the correct PIN unlocks it.

### Tests for User Story 1 ⚠️

- [X] T025 [P] [US1] Unit test `EnableAppLock`/`SetPin`: `EnableAppLock` fails with a clear error if no `PinCredential` exists yet (FR-002 ordering); `SetPin` rejects a PIN failing `PinHasher.validate` and rejects a mismatched confirm-entry at the use-case boundary (`PinMismatchFailure`) — in `test/features/app_lock/domain/usecases/enable_app_lock_set_pin_test.dart`.
- [X] T026 [P] [US1] Unit test `VerifyPin`: correct PIN returns `success` and resets `LockoutState` (FR-014); incorrect PIN returns `incorrectPin` and does NOT itself increment the counter (that's `RecordFailedPinAttempt`'s job, called separately by the Cubit) — in `test/features/app_lock/domain/usecases/verify_pin_test.dart`.
- [X] T027 [P] [US1] `bloc_test` for `PinSetupCubit`: happy-path set-twice-matching flow, mismatch-then-retry-without-losing-first-entry (spec User Story 1 Scenario 3), duplicate-tap producing exactly one `PinCredential` write — in `test/features/app_lock/presentation/cubit/pin_setup_cubit_test.dart`.
- [X] T028 [P] [US1] `bloc_test` for `LockScreenCubit`: correct PIN unlocks and returns to the pre-background screen; incorrect PIN stays locked with a clear error state — in `test/features/app_lock/presentation/cubit/lock_screen_cubit_test.dart`.

### Implementation for User Story 1

- [X] T029 [P] [US1] Implement `lib/features/app_lock/domain/usecases/set_pin.dart` (wraps `AppLockRepository.setPin`, T016) and `lib/features/app_lock/domain/usecases/enable_app_lock.dart` (wraps `AppLockRepository.enableAppLock`, enforcing the "PIN must already be set" ordering per FR-002).
- [X] T030 [P] [US1] Implement `lib/features/app_lock/domain/usecases/verify_pin.dart` wrapping `AppLockRepository.verifyPin`.
- [X] T031 Annotate the US1 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T029, T030).
- [X] T032 [US1] Implement `lib/features/app_lock/presentation/cubit/pin_setup_cubit.dart` + state: two-step entry (enter, confirm), mismatch handling that preserves the first entry for retry, disables Save immediately on tap (constitution Duplicate Action Protection) (depends on T029, T031).
- [X] T033 [US1] Implement `lib/features/app_lock/presentation/cubit/lock_screen_cubit.dart` + state: PIN entry, calls `VerifyPin` (T030), on success signals the router redirect (T023) to release the lock and restore the prior route (depends on T030, T031).
- [X] T034 [P] [US1] Implement `lib/features/app_lock/presentation/widgets/pin_pad.dart` (numeric keypad, RTL-safe layout, no hardcoded strings).
- [X] T035 [US1] Implement `lib/features/app_lock/presentation/pages/pin_setup_page.dart` (uses T032, T034) and `lib/features/app_lock/presentation/pages/lock_screen_page.dart` (uses T033, T034) as a full-screen, non-dismissible overlay per research.md Decision 5 (not a normal `go_router` route).
- [X] T036 [US1] Add the "Security" section entry point to `lib/features/settings/presentation/pages/settings_page.dart` with an App Lock enable toggle that launches `PinSetupPage` (T035) on first enable, wiring `EnableAppLock` (T029) on successful PIN setup.

**Checkpoint**: User Story 1 fully functional and independently testable — App Lock can be enabled, a PIN set, and the app locks/unlocks correctly on relaunch and timeout-based resume.

---

## Phase 4: User Story 2 - Unlock with Biometrics, with PIN Fallback (Priority: P1) 🎯 MVP (part 2 of 3)

**Goal**: A user with enrolled biometrics can unlock instantly, with PIN always reachable as a guaranteed fallback.

**Independent Test**: Enable biometric unlock, confirm the lock screen auto-prompts biometrics with a visible PIN option, then simulate biometric failure/unavailability and confirm PIN entry always works.

### Tests for User Story 2 ⚠️

- [X] T037 [P] [US2] Unit test `SetBiometricEnabled`: succeeds only when `BiometricService.isAvailable()` returns true, otherwise returns `BiometricUnavailableFailure` with a clear reason (FR-005/FR-007) — in `test/features/app_lock/domain/usecases/set_biometric_enabled_test.dart`.
- [X] T038 [P] [US2] Unit test `VerifyBiometric`: success returns `success` and resets `LockoutState` exactly like a correct PIN (FR-014); cancellation/failure returns `biometricFailed` WITHOUT calling `RecordFailedPinAttempt` (FR-008, verified via mock — zero interactions with the PIN lockout path) — in `test/features/app_lock/domain/usecases/verify_biometric_test.dart`.
- [X] T039 [P] [US2] `bloc_test` for `LockScreenCubit`'s biometric extension: auto-prompts on entering the locked state when biometric is active and available; falls back to PIN-only UI automatically when `isAvailable()` flips to false mid-session (device enrollment changed, FR-007 edge case) — extend `test/features/app_lock/presentation/cubit/lock_screen_cubit_test.dart` (T028).

### Implementation for User Story 2

- [X] T040 [P] [US2] Implement `lib/features/app_lock/domain/usecases/set_biometric_enabled.dart` (checks `BiometricService.isAvailable()` before calling `AppLockRepository.setBiometricEnabled`, per contracts/app_lock_repository.md).
- [X] T041 [P] [US2] Implement `lib/features/app_lock/domain/usecases/verify_biometric.dart` wrapping `BiometricService.authenticate()` + `AppLockRepository`'s lockout-reset-on-success path.
- [X] T042 Annotate the US2 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T040, T041).
- [X] T043 [US2] Extend `LockScreenCubit` (T033) to auto-trigger `VerifyBiometric` (T041) on entering the locked state whenever biometric is an active, available unlock method, always keeping a "Use PIN instead" affordance immediately reachable (FR-006) (depends on T041, T042).
- [X] T044 [US2] Extend `lib/features/app_lock/presentation/pages/lock_screen_page.dart` (T035) with the biometric-prompt-pending visual state and the manual PIN-switch affordance.
- [X] T045 [US2] Add the biometric-unlock toggle to the Security settings screen (`lib/features/app_lock/presentation/pages/security_settings_page.dart`, first created here — extended further in US6), disabled with an explanatory message when `BiometricService.isAvailable()` is false (depends on T040).

**Checkpoint**: User Stories 1 AND 2 together deliver the full P1 MVP — biometric-first unlock with a dependable PIN fallback, matching the spec's own priority framing.

---

## Phase 5: User Story 3 - Lockout After Repeated Wrong PIN Attempts (Priority: P2)

**Goal**: Repeated wrong PINs trigger an escalating, persisted cooldown that never blocks biometric unlock and never logs the attempted PIN.

**Independent Test**: Enter the wrong PIN repeatedly past the threshold, confirm an escalating cooldown engages and persists across a force-quit/relaunch, and confirm biometric remains usable throughout.

### Tests for User Story 3 ⚠️

- [X] T046 [P] [US3] Unit test `RecordFailedPinAttempt`: increments the counter, applies `LockoutPolicy.cooldownFor` (T010) correctly at each threshold, and — critically — asserts no PIN value is ever passed into or logged by this use case (a static/code-review-style assertion plus a log-capture test confirming zero PIN-shaped strings in captured output, per FR-016) — in `test/features/app_lock/domain/usecases/record_failed_pin_attempt_test.dart`.
- [X] T047 [P] [US3] Unit test `AppLockRepositoryImpl.verifyPin`'s cooldown short-circuit: returns `PinLockedOutFailure` with the correct `remainingCooldown` WITHOUT even comparing the submitted PIN when a cooldown is active — extend `test/features/app_lock/data/repositories/app_lock_repository_impl_test.dart`.
- [X] T048 [P] [US3] Integration-style unit test: `LockoutState` persisted via `SecureAppLockStorage` survives a simulated repository re-instantiation (proxy for an app relaunch, FR-015) — extend `test/features/app_lock/data/datasources/secure_app_lock_storage_test.dart` (T015).
- [X] T049 [P] [US3] `bloc_test` for `LockScreenCubit`'s lockout countdown state, and confirmation that a biometric attempt dispatched while `LockoutState` shows an active cooldown still reaches `VerifyBiometric` (FR-008/US3 Scenario 4) — extend `test/features/app_lock/presentation/cubit/lock_screen_cubit_test.dart`.

### Implementation for User Story 3

- [X] T050 [US3] Implement `lib/features/app_lock/domain/usecases/record_failed_pin_attempt.dart` wrapping `AppLockRepository.recordFailedPinAttempt` (T016), invoked by the Cubit only on an `incorrectPin` `VerifyPin` outcome — never passed the raw PIN value at all (FR-016, enforced by the method signature taking no PIN parameter, per contracts/app_lock_repository.md).
- [X] T051 [P] [US3] Implement `lib/features/app_lock/domain/usecases/get_lockout_state.dart` wrapping `AppLockRepository.getLockoutState`.
- [X] T052 Annotate the US3 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T050, T051).
- [X] T053 [US3] Extend `LockScreenCubit` (T033/T043) to call `RecordFailedPinAttempt` (T050) on every `incorrectPin` result, fetch `GetLockoutState` (T051) on entering the locked state (surviving relaunch, FR-015), and drive a live countdown from `LockoutState.cooldownEndsAt` (depends on T050-T052).
- [X] T054 [P] [US3] Implement `lib/features/app_lock/presentation/widgets/lockout_countdown_banner.dart` (RTL-safe duration formatting, FR-013).
- [X] T055 [US3] Wire `LockoutCountdownBanner` (T054) into `lock_screen_page.dart` (T035/T044), disabling `PinPad` (T034) input while a cooldown is active but leaving the biometric-prompt affordance fully interactive (depends on T053, T054).

**Checkpoint**: User Story 3 independently testable — brute-force PIN guessing is now measurably slowed per FR-013/SC-006, without ever weakening biometric availability.

---

## Phase 6: User Story 4 - Recover Access After Forgetting the PIN (Priority: P2)

**Goal**: A user locked out by their own forgotten PIN has an honest recovery path — biometric re-auth if available, otherwise a strongly-confirmed full local data wipe, with zero fake non-destructive alternatives ever implied.

**Independent Test**: Trigger "Forgot PIN," confirm biometric re-auth is offered first when available and succeeds with zero data loss; confirm the non-biometric path only offers a clearly-explained, strongly-confirmed, atomic data wipe.

### Tests for User Story 4 ⚠️

- [X] T056 [P] [US4] Unit test `RecoverViaBiometric`: on `BiometricService.authenticate()` success, allows a subsequent `ChangePin` call with zero other side effects (no data touched outside `app_lock`'s own PIN credential) — in `test/features/app_lock/domain/usecases/recover_via_biometric_test.dart`.
- [X] T057 [P] [US4] Unit test `WipeAllLocalData`: clears every `AppDatabase` table AND all three `app_lock.*` secure-storage keys atomically (either both fully clear or neither does, tested via a forced mid-wipe failure injection) — in `test/features/app_lock/domain/usecases/wipe_all_local_data_test.dart`. This is the release-blocking correctness anchor for FR-019's atomicity requirement.
- [X] T058 [P] [US4] `bloc_test` for `ForgotPinCubit`: routes to biometric-recovery when available, routes straight to the wipe-confirmation explanation otherwise (never presenting or implying a third option, per FR-018), cancel-at-any-point-before-final-confirmation leaves all data untouched — in `test/features/app_lock/presentation/cubit/forgot_pin_cubit_test.dart`.

### Implementation for User Story 4

- [X] T059 [P] [US4] Implement `lib/features/app_lock/domain/usecases/recover_via_biometric.dart` (calls `BiometricService.authenticate()`, then permits a `ChangePin` call, per contracts/app_lock_repository.md).
- [X] T060 [US4] Implement `lib/features/app_lock/domain/usecases/wipe_all_local_data.dart`: clears `AppDatabase` (all tables, via a single DB transaction) and all `app_lock.*` secure-storage keys, then resets the app's own launch/onboarding-seen flag so the app returns to first-launch state (FR-019) — documents the seam with the future `DeleteAllUserData` (V1.5.3) use case per research.md Decision 4 in a code comment.
- [X] T061 Annotate the US4 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T059, T060).
- [X] T062 [US4] Implement `lib/features/app_lock/presentation/cubit/forgot_pin_cubit.dart` + state: biometric-recovery branch (success → hands off to `PinSetupCubit`/T032 for the new PIN) and wipe-only branch, with an explicit strong-confirmation gate before invoking `WipeAllLocalData` (T060) — no path in this Cubit reaches the wipe without that gate (depends on T059-T061).
- [X] T063 [P] [US4] Implement `lib/features/app_lock/presentation/pages/forgot_pin_page.dart` (entry point from the lock screen, routes into biometric recovery or the wipe explanation) and `wipe_confirmation_page.dart` (typed-confirmation-phrase or equivalent deliberate double-confirmation, per constitution Financial Domain Override, FR-019).
- [X] T064 [US4] Add a "Forgot PIN" affordance to `lock_screen_page.dart` (T035/T044/T055) navigating to `ForgotPinPage` (T063) (depends on T062, T063).

**Checkpoint**: User Story 4 independently testable — the feature's one irreversible action is honestly presented, strongly gated, and provably atomic.

---

## Phase 7: User Story 5 - Screenshot and Screen-Recording Protection (Priority: P2)

**Goal**: Foreground screen-capture protection is always active, independent of App Lock, without interfering with the app's own legitimate share/export flows.

**Independent Test**: With App Lock off, attempt a screenshot/recording and check the app-switcher thumbnail; confirm protection is active regardless; confirm a legitimate OS share-sheet flow from elsewhere in the app is unaffected.

### Tests for User Story 5 ⚠️

- [X] T065 [P] [US5] Widget/platform-channel test confirming `ScreenshotProtectionService.enable()` (T018/T019) is invoked at `main.dart` startup (T024) unconditionally, BEFORE any check of `AppLockConfig.isEnabled` — extend `test/core/security/screenshot_protection_service_test.dart` (T019). This is the primary automated evidence for User Story 5 Scenario 4 (protection independent of App Lock).
- [X] T066 [P] [US5] Platform-channel test simulating an active-recording notification (iOS `UIScreen.capturedDidChangeNotification` test double) and confirming the obscuring-overlay state is entered and exited correctly around the simulated recording window (FR-021) — extend `test/core/security/screenshot_protection_service_test.dart`.

### Implementation for User Story 5

- [X] T067 [US5] Implement `lib/core/security/app_switcher_placeholder.dart` (the neutral branded placeholder widget/asset referenced by the native `SecurityPlugin` (T018) for the Android/iOS app-switcher thumbnail — wired at the native layer, this Dart file documents/owns the branding asset used) (depends on T018).
- [X] T068 [US5] Verify (code-review + manual per quickstart.md Scenario 5) that no existing or planned OS-share-sheet-based flow is registered as a "screenshot" from the platform's perspective — document the distinction explicitly in a code comment on `SecurityPlugin.kt`/`SecurityPlugin.swift` (FR-022) (depends on T018).

**Checkpoint**: User Story 5 independently testable — screenshot/recording protection is verifiably always-on and provably non-interfering with the app's own data-output paths.

---

## Phase 8: User Story 6 - Manage Security Settings (Priority: P3)

**Goal**: Ongoing configuration — change PIN, adjust unlock methods, adjust inactivity timeout, disable App Lock — all reachable and correctly re-authenticated where required.

**Independent Test**: With App Lock already enabled, change the PIN, change the inactivity timeout, disable biometric, and disable App Lock entirely, confirming each change takes effect correctly on the next lock/unlock cycle.

### Tests for User Story 6 ⚠️

- [X] T069 [P] [US6] Unit test `ChangePin`: requires a preceding successful `VerifyPin`/`VerifyBiometric` (enforced at the Cubit layer, tested via the Cubit rather than the use case itself, which trusts its caller per contracts/app_lock_repository.md), resets `LockoutState` on success (data-model.md Assumptions) — in `test/features/app_lock/domain/usecases/change_pin_test.dart`.
- [X] T070 [P] [US6] Unit test `SetInactivityTimeout`: persists the new value; a concurrently-running `AppLifecycleObserver` timer picks up the NEW value only on the next backgrounding, not retroactively applied to an in-flight timer (FR-025) — in `test/features/app_lock/domain/usecases/set_inactivity_timeout_test.dart`.
- [X] T071 [P] [US6] Unit test `DisableAppLock`: clears `PinCredential` and `LockoutState` (FR-027, data-model.md Assumptions), leaves `ScreenshotProtectionService` untouched (independent concern, FR-020) — in `test/features/app_lock/domain/usecases/disable_app_lock_test.dart`.
- [X] T072 [P] [US6] `bloc_test` for `AppLockSettingsCubit`: change-PIN flow requiring re-auth first, timeout selection, biometric toggle, disable-then-re-enable-requires-fresh-PIN-setup end-to-end — in `test/features/app_lock/presentation/cubit/app_lock_settings_cubit_test.dart`.

### Implementation for User Story 6

- [X] T073 [P] [US6] Implement `lib/features/app_lock/domain/usecases/change_pin.dart` wrapping `AppLockRepository.changePin`.
- [X] T074 [P] [US6] Implement `lib/features/app_lock/domain/usecases/set_inactivity_timeout.dart` wrapping `AppLockRepository.setInactivityTimeout`, and `lib/features/app_lock/domain/usecases/disable_app_lock.dart` wrapping `AppLockRepository.disableAppLock`.
- [X] T075 Annotate the US6 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T073, T074).
- [X] T076 [US6] Implement `lib/features/app_lock/presentation/cubit/app_lock_settings_cubit.dart` + state: change-PIN (requires re-auth via `LockScreenCubit`'s verify flow before proceeding), timeout picker, biometric toggle (reuses T040), disable action with confirmation, re-enable routing back into `PinSetupPage` (T035) fresh (depends on T029, T040, T073-T075).
- [X] T077 [US6] Finalize `lib/features/app_lock/presentation/pages/security_settings_page.dart` (first created in T045): App Lock on/off, unlock-method toggles, timeout picker, Change PIN action, wired to `AppLockSettingsCubit` (T076) (depends on T076).

**Checkpoint**: All 6 user stories independently functional. Feature is feature-complete per spec.md.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Localization, theming, performance, full regression, and final constitution compliance pass

- [X] T078 [P] Add all App-Lock-feature strings (lock screen, PIN pad, Security settings, Forgot-PIN flow, wipe confirmation, lockout countdown) to `lib/core/l10n/app_en.arb` and `app_ar.arb`; regenerate `AppLocalizations` (FR-029).
- [X] T079 [P] RTL/LTR and theme pass: verify the lock screen, PIN pad, Security settings, Forgot-PIN/wipe-confirmation screens, and lockout countdown render correctly in Arabic RTL and English LTR, and in both light and dark mode (FR-029, SC-007).
- [ ] T080 [P] Performance check: confirm lock-screen-to-unlocked transition renders in <300ms after successful authentication and the biometric prompt appears within 500ms of reaching the lock screen (plan.md Performance Goals).
- [X] T081 Write `integration_test/app_lock_flows_test.dart` covering: enable + set PIN, cold-launch lock, resume-past-timeout lock, no-lock-on-brief-interruption (US1); biometric success/fallback/unavailable (US2); escalating lockout persisting across relaunch, biometric unaffected by PIN lockout (US3); Forgot-PIN biometric recovery and data-wipe paths with a test double for the actual wipe (US4); screenshot-protection service invocation around app lifecycle transitions via platform-channel test doubles (US5); change PIN, change timeout, disable/re-enable requiring fresh setup (US6) — per quickstart.md's manual scenarios.
- [X] T082 Run `fvm flutter analyze` and `fvm flutter format`, fix all warnings (no `// ignore` suppressions without a documented reason).
- [X] T083 Run the full `fvm flutter test` suite and `fvm flutter test integration_test`; confirm all pass, with special attention to T009 (`PinHasher`), T011 (`LockoutPolicy`), T021 (`AppLifecycleObserver`'s interruption-vs-backgrounding distinction), and T057 (`WipeAllLocalData`'s atomicity).
- [X] T084 Code-review pass against the constitution's Definition of Done checklist and Principle XII specifically: grep the diff and log output for any accidental PIN-value logging, confirm `AppLockConfig`/`PinCredential`/`LockoutState` never appear in `AppDatabase`/`drift` (data-model.md), and confirm zero changes were made to any existing feature's data or calculations (FR-030) outside `lib/features/app_lock/`, `lib/core/security/`, `lib/core/di/`, `lib/core/l10n/`, `lib/core/routing/` (one redirect hook), `lib/features/settings/` (one entry point), `lib/main.dart` (one init call), and the two native platform files.
- [X] T085 **[Added 2026-09-22, `/speckit-analyze` finding F8 — resolves research.md Decision 4's deferred consolidation seam, now that `specs/013-reports-data-privacy` exists and is complete on disk.]** Extend `specs/013-reports-data-privacy`'s `DeleteAllUserData` use case (`lib/features/data_privacy/domain/usecases/delete_all_user_data.dart`, wraps `DataWipeRepository.deleteAllUserData()`) so that, after `AppDatabase.deleteAllUserData()` (013's `lib/core/database/data_wipe.dart`) succeeds, it also clears App Lock's three `app_lock.*` secure-storage keys (PIN hash, salt, lockout state — the same set `WipeAllLocalData`/T057 clears) whenever the `app_lock` feature is present, via a small optional `SecureStorageWiper` interface injected into `DeleteAllUserData` (Domain-layer abstraction only; no `app_lock` import in `data_privacy`, per constitution Principle II) implemented by `app_lock`'s data layer and bound via `get_it`/`injectable`. This makes 013's Settings → "Delete My Data" flow and 015's Forgot-PIN → data-wipe flow (T057-T062) converge on one fully-consolidated wipe guarantee instead of two independent ones (depends on T057, and on `specs/013-reports-data-privacy/tasks.md` T036-T040 already being implemented).
- [X] T086 **[Added 2026-09-22, `/speckit-analyze` finding F8]** Extend 013's real-`drift` atomicity test (`test/core/database/data_wipe_test.dart`, `specs/013-reports-data-privacy/tasks.md` T031) with an App-Lock-aware variant asserting that after `DeleteAllUserData` runs with App Lock configured (PIN set, lockout state present), all three `app_lock.*` secure-storage keys are also gone — and that a forced mid-wipe failure leaves both the database AND secure storage provably untouched (same all-or-nothing guarantee as T057, now spanning both storage mechanisms) — in `test/features/app_lock/integration/delete_all_user_data_secure_storage_test.dart` (depends on T085).

---

## Dependencies & Execution Order

- **Phase 1 (Setup)** → **Phase 2 (Foundational)**: strictly sequential; Phase 2 blocks every user story.
- **Phase 3 (US1)** and **Phase 4 (US2)** together form the P1 MVP; US2 extends `LockScreenCubit`/`lock_screen_page.dart` created in US1, so US2 has a soft dependency on US1's Cubit/page existing, though its own use cases (T040/T041) are independently buildable in parallel with US1.
- **Phase 5 (US3)**, **Phase 6 (US4)**, **Phase 7 (US5)** are all P2 and mutually independent of each other, but US3 and US4 both extend the `LockScreenCubit`/`lock_screen_page.dart` from US1/US2, so should follow the P1 MVP in practice even though nothing in Phase 2 strictly blocks starting them earlier.
- **Phase 8 (US6)** is P3 and depends on `PinSetupCubit` (US1) and `SetBiometricEnabled` (US2) already existing, since Change-PIN and the biometric toggle reuse them.
- **Phase 9 (Polish)** runs last, after all desired user stories are implemented.

## Parallel Execution Examples

- Within Phase 2: T004-T007 (entities/failures) in parallel; T009 and T011 (the two exhaustive pure-function test suites) in parallel with each other once T008/T010 land; T015, T017, T019, T021 in parallel once their respective implementation tasks land.
- Within Phase 3 (US1): T025-T028 (all four test tasks) in parallel; T029-T030 in parallel; T034 in parallel with T032/T033.
- Within Phase 5 (US3): T046-T049 in parallel.
- Across phases: once Phase 2 is complete, US1 (Phase 3) and the test-writing halves of US2/US3/US5 (T037-T039, T046-T049, T065-T066) can be staffed in parallel by different contributors, since their test tasks depend only on Phase 2's interfaces, not on each other's implementation tasks landing first — though a single implementer following this document should still complete Phase 3 before Phase 4 per the Dependencies note above.

## Implementation Strategy

**MVP first**: Phases 1-4 (Setup, Foundational, US1, US2) deliver the feature's core promise — biometric-first unlock with a dependable PIN fallback gating the whole app — and are independently demoable/testable per quickstart.md Scenarios 1-2. Phases 5-8 (lockout hardening, forgot-PIN recovery, screenshot protection, ongoing settings management) are additive hardening layers, each independently testable and shippable in any order after the MVP, matching their P2/P3 priorities in spec.md. Phase 9 always runs last regardless of how many user-story phases have shipped so far.
