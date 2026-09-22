# Implementation Plan: App Lock (Biometric/PIN) & Screenshot Protection

**Branch**: `015-app-lock-security` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/015-app-lock-security/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Add an opt-in, off-by-default app-wide lock that gates access to the entire app on launch and on resume-from-background past a configurable inactivity timeout, with two independently selectable unlock methods (device biometric via `local_auth`, and a numeric PIN whose salted hash lives only in OS secure storage via `flutter_secure_storage`), an escalating-cooldown lockout after repeated wrong PIN attempts, and a destructive-only "Forgot PIN" recovery path (biometric re-auth if available, otherwise a strongly-confirmed full local data wipe — this app has no backend to support any non-destructive recovery). Independently, foreground screenshot/screen-recording protection (`FLAG_SECURE`-equivalent on Android, a privacy overlay on iOS) is always active regardless of whether App Lock itself is enabled. This is the first feature in the codebase to introduce OS secure storage as a dependency; it touches no existing feature's data or calculations — purely additive security hardening layered above every screen.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc`, `get_it` + `injectable`, `drift` (existing, reused as-is — App Lock config itself does NOT live in `drift`/SQLite, see Storage below), `fpdart`, `equatable`, `go_router`, `crypto` (new — for salted PIN hashing, e.g. PBKDF2/SHA-256 with a per-install random salt; a small, well-audited primitive is preferred over a bespoke hash routine), `local_auth` (new — biometric authentication, cross-platform), `flutter_secure_storage` (new — Keychain/Keystore-backed secure storage for the PIN hash/salt and lockout state). Screenshot/recording protection uses a thin platform-channel wrapper (Android: `FLAG_SECURE` set/cleared on the `FlutterActivity` window; iOS: an overlay `UIView` toggled around `applicationWillResignActive`/`didBecomeActive` plus `UIScreen.capturedDidChangeNotification` for active-recording detection) rather than a third-party plugin, since the platform surface needed is small, stable, and avoids taking on an external package for two OS API calls per platform (research.md Decision 1).

**Storage**: App Lock configuration (enabled flag, active unlock methods, inactivity timeout, PIN hash + salt, lockout attempt count + cooldown-end timestamp) lives entirely in OS secure storage via `flutter_secure_storage`, deliberately **not** in the existing `AppDatabase` (`drift`/SQLite) — this data exists specifically to gate access to that database's contents, so it must not live inside it (research.md Decision 2). `AppDatabase.schemaVersion` is **unchanged** by this feature — zero new tables, zero new columns on any existing table.

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail`, `integration_test` (enable App Lock + set PIN, lock-on-background-past-timeout, correct/incorrect PIN, biometric success/fallback/unavailable, escalating lockout across relaunch, Forgot-PIN biometric-recovery path, Forgot-PIN data-wipe path, screenshot-protection thumbnail/capture behavior verified via platform-channel test doubles, disable/re-enable App Lock).

**Target Platform**: Android and iOS mobile apps (existing app scope). `local_auth` and the screenshot-protection platform channel both require real per-platform native code (`android/app/src/main/...`, `ios/Runner/...`), not pure Dart.

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: PIN setup completed in <60s end-to-end (SC-001, dominated by user input); lock-screen-to-unlocked transition renders in <300ms after successful authentication (no perceptible delay revealing content); biometric prompt appears within 500ms of reaching the lock screen when enabled; screenshot/app-switcher-thumbnail protection has zero measurable added frame cost during normal foreground use (a static platform flag/overlay toggle, not a per-frame operation).

**Constraints**: Fully offline — this feature makes zero network calls (FR-028). PIN raw value never persisted, logged, or held in memory longer than the single verification operation (FR-004/FR-016). Failed-attempt lockout state persists across relaunch (FR-015) — an in-memory-only counter would be a trivial bypass. The lock screen must intercept *every* app entry point (cold launch, resume-from-background past timeout) with zero gaps, and must correctly distinguish genuine backgrounding from a brief system interruption (FR-010) — this is the single highest-risk correctness requirement in this feature, since a false negative here silently defeats the entire feature. Screenshot protection must not interfere with the app's own OS-share-sheet-based export flows introduced by other features (FR-022) — mutually exclusive concerns (block *unsanctioned* capture, never the app's *own* data-output action).

**Scale/Scope**: Single user per device; App Lock configuration is a single record, not a list (no scale dimension). ~6 new screens/overlays (lock screen with PIN pad, PIN setup/change flow, biometric prompt integration, Security settings section, Forgot-PIN flow, data-wipe strong-confirmation screen) plus the screenshot-protection app-switcher placeholder and (iOS) the active-recording overlay. One new feature module (`app_lock`), zero changes to any existing feature's domain/data layer.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `app_lock` splits into `data/domain/presentation`; the lock screen and Security settings UI never touch `flutter_secure_storage`/`local_auth` directly — always through `AppLockRepository`/`BiometricService` interfaces resolved via DI | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/app_lock/`; a small `core/security/` addition holds only the genuinely cross-cutting lock-screen-interception plumbing (the `go_router` redirect/overlay hook and the app-lifecycle observer), since every existing feature's screens must be gated without each one individually depending on `app_lock` | PASS |
| III. BLoC/Cubit Mandate | Cubits per flow (`AppLockSettingsCubit`, `LockScreenCubit`, `PinSetupCubit`, `ForgotPinCubit`); no alternate state layer | PASS |
| IV. Immutable State | All Cubit states are `Equatable` value classes updated via `copyWith()`; lockout countdown state is recomputed from a persisted end-timestamp, never mutated in place | PASS |
| V. Domain-Driven Business Logic | Use cases: `EnableAppLock`, `DisableAppLock`, `SetPin`, `ChangePin`, `VerifyPin`, `VerifyBiometric`, `RecordFailedPinAttempt` (encapsulates the escalating-cooldown rule, research.md Decision 3), `GetLockoutState`, `SetInactivityTimeout`, `SetBiometricEnabled`, `RecoverViaBiometric`, `WipeAllLocalData` (reused/shared boundary with any future Data-Privacy "Delete My Data" use case — see research.md Decision 4) — each a meaningful, independently testable business action | PASS |
| VI. Repository Pattern | Domain defines `AppLockRepository` (owns the secure-storage-backed config/PIN-hash/lockout state) and a `BiometricService` interface (wraps `local_auth`); Presentation/Domain depend only on the abstractions via DI | PASS |
| VII. Explicit Error Handling | All repository/use-case calls return `Either<Failure, T>`; new typed failures `IncorrectPinFailure`, `PinLockedOutFailure`, `BiometricUnavailableFailure`, `PinMismatchFailure` alongside reused `core/error/failure.dart` types — no empty catches, no raw platform exceptions surfaced to UI | PASS |
| VIII. Deterministic Financial Calculations | Not directly applicable (this feature computes no financial figures), but the escalating-lockout cooldown schedule (FR-013) is itself simple, deterministic, fully-specified arithmetic over an attempt count — no AI, no guesswork | PASS (N/A financial, still deterministic) |
| IX. AI Isolation | Not applicable — no AI integration in this feature | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is fully local and makes zero network calls (FR-028); lockout-state writes are the only "mutation under retry" risk and are naturally idempotent (recording a failed attempt is monotonic, never re-appliable to double-count from a single tap given standard duplicate-submission guarding) | PASS |
| XII. Security & Secrets Management | This feature's entire purpose is Principle XII: PIN hash+salt in OS secure storage, never plaintext, never logged (FR-004/FR-016); biometric handled entirely by the OS (the app never sees raw biometric data, only a pass/fail result from `local_auth`); the data-wipe recovery path is the constitution's Financial Domain Override applied to a security feature — an explicit strong confirmation before an irreversible action | PASS |
| XIII. Localization & RTL/LTR | `gen_l10n` ARB additions for `ar`/`en` (lock screen, PIN pad, Security settings, Forgot-PIN flow, wipe confirmation); PIN pad digit layout and countdown-timer formatting both verified in RTL | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires `AppLockRepository`, `BiometricService`, `ScreenshotProtectionService`, all use cases, and Cubits; nothing self-instantiated, including the two new native-platform-channel wrappers | PASS |
| XV. Design System | Reuses existing `core/design_system` (`AppButton`, `AppConfirmDialog`, `AppTextField` where applicable); a numeric PIN pad and a lockout-countdown indicator are the only genuinely new visual components, built inside `features/app_lock/presentation/widgets/` first, promoted to `core/` only if a second feature later needs a PIN-style input | PASS |
| XVI. Testability by Design | `RecordFailedPinAttempt`'s cooldown-escalation math is unit-tested exhaustively as pure logic (no I/O); `AppLockRepositoryImpl` tested against a fake secure-storage implementation (mockable interface, never the real Keychain/Keystore in tests); Cubits tested with `bloc_test`/`mocktail`; widget tests for the PIN pad and Forgot-PIN flow; `integration_test` covers the full lock/unlock/lockout/recovery/screenshot-protection matrix | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): Keeping App Lock configuration entirely out of `AppDatabase` (Decision 2) is the direct, minimal implementation of "this data gates access to that database" — not speculative scope; it also means a future `DeleteAllUserData` use case (roadmap V1.5.3) must independently know to also clear secure storage, which is called out explicitly in research.md Decision 4 rather than left as a silent gap. **Resolved 2026-09-22 (`/speckit-analyze` finding F8)**: `specs/013-reports-data-privacy` now exists complete on disk, so this is no longer a future/hypothetical seam — see tasks.md T085/T086 for the concrete consolidation of 013's `DeleteAllUserData` with App Lock's secure-storage wipe. Isolating `RecordFailedPinAttempt`'s escalation schedule as a pure function (rather than folding it into the repository or a Cubit) is what makes the lockout timing independently, exhaustively unit-testable per FR-013/SC-006. No new architectural pattern, no layering deviation. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/015-app-lock-security/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/                    # UNCHANGED — App Lock config never lives here (Decision 2)
│   ├── design_system/                # reused as-is
│   ├── di/                           # gains app_lock feature registrations
│   ├── error/                        # reused; gains IncorrectPinFailure/PinLockedOutFailure/
│   │                                  # BiometricUnavailableFailure/PinMismatchFailure
│   ├── l10n/                         # app_en.arb / app_ar.arb gain app_lock-feature keys
│   ├── routing/                      # app_router.dart gains a top-level redirect/observer that
│   │                                  # checks AppLockRepository's lock state ahead of every route
│   │                                  # (the one genuinely cross-cutting routing change this
│   │                                  # feature requires — see research.md Decision 5)
│   └── security/                     # NEW, small, cross-cutting only:
│       ├── app_lifecycle_observer.dart   # WidgetsBindingObserver distinguishing genuine
│       │                                  # backgrounding from brief system interruptions
│       │                                  # (FR-010) and starting/cancelling the inactivity timer
│       └── screenshot_protection_service.dart  # thin interface over the platform channel,
│                                                # always active regardless of App Lock state
│
├── features/
│   ├── people/                       # UNCHANGED
│   ├── transactions/                  # UNCHANGED
│   ├── settings/                      # gains a "Security" section entry point only
│   │                                  # (navigates into app_lock's own settings screen)
│   └── app_lock/                      # NEW
│       ├── data/
│       │   ├── datasources/           # SecureAppLockStorage (flutter_secure_storage wrapper)
│       │   ├── services/              # LocalAuthBiometricService (implements BiometricService),
│       │   │                          # PlatformChannelScreenshotProtectionService
│       │   └── repositories/          # AppLockRepositoryImpl
│       ├── domain/
│       │   ├── entities/              # AppLockConfig, LockoutState, UnlockMethod (enum)
│       │   ├── repositories/           # AppLockRepository (abstract)
│       │   ├── services/               # BiometricService (abstract), PinHasher (pure —
│       │   │                           # salted-hash generation/verification, no I/O),
│       │   │                           # LockoutPolicy (pure — escalating-cooldown schedule)
│       │   └── usecases/               # EnableAppLock, DisableAppLock, SetPin, ChangePin,
│       │                               # VerifyPin, VerifyBiometric, RecordFailedPinAttempt,
│       │                               # GetLockoutState, SetInactivityTimeout,
│       │                               # SetBiometricEnabled, RecoverViaBiometric,
│       │                               # WipeAllLocalData
│       └── presentation/
│           ├── cubit/                  # AppLockSettingsCubit, LockScreenCubit, PinSetupCubit,
│           │                           # ForgotPinCubit
│           ├── pages/                   # LockScreenPage (overlay, not a go_router route),
│           │                           # SecuritySettingsPage, PinSetupPage, ForgotPinPage,
│           │                           # WipeConfirmationPage
│           └── widgets/                 # PinPad, LockoutCountdownBanner,
│                                       # UnlockMethodToggleTile, AppSwitcherPlaceholder
│
└── main.dart                            # gains AppLifecycleObserver + ScreenshotProtectionService
                                          # initialization alongside existing DI bootstrap

android/app/src/main/kotlin/.../SecurityPlugin.kt   # NEW — FLAG_SECURE set/clear platform channel
ios/Runner/SecurityPlugin.swift                      # NEW — privacy-overlay + recording-detection
                                                      # platform channel

test/
├── core/security/                      # AppLifecycleObserver interruption-vs-backgrounding tests
└── features/
    └── app_lock/
        ├── domain/services/            # PinHasher + LockoutPolicy unit tests — the most
        │                               # exhaustively tested files in this feature (pure, no I/O)
        ├── domain/usecases/            # unit tests, faked AppLockRepository/BiometricService
        ├── data/repositories/          # AppLockRepositoryImpl tests against a fake secure
        │                               # storage implementation (never the real Keychain/Keystore)
        └── presentation/cubit/         # bloc_test + mocktail

integration_test/
└── app_lock_flows_test.dart            # enable + set PIN; lock on cold launch; lock on
                                          # resume-past-timeout; no lock on brief interruption;
                                          # correct/incorrect PIN; biometric success/fallback/
                                          # unavailable; escalating lockout persisting across
                                          # relaunch; Forgot-PIN biometric recovery;
                                          # Forgot-PIN data-wipe (with a test double for the
                                          # actual wipe, verifying the confirmation gate rather
                                          # than destroying the test environment); disable/
                                          # re-enable App Lock requiring fresh PIN setup;
                                          # screenshot-protection service invoked correctly
                                          # around app lifecycle transitions (via a platform
                                          # channel test double, not real OS screen capture)
```

**Structure Decision**: Single new feature module `lib/features/app_lock/` following the established clean-architecture shape, plus a deliberately small `lib/core/security/` addition for the two pieces of plumbing that must, by nature, sit above every feature rather than inside one: the app-lifecycle-aware backgrounding/interruption detector and the always-on screenshot-protection service. Everything else (PIN hashing, lockout policy, biometric wrapping, the lock screen itself) stays inside `app_lock`. No existing feature's code changes except a one-line Settings entry point and a router-level redirect hook.

## Complexity Tracking

*No Constitution Check violations — table intentionally omitted.*
