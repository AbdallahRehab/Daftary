# Implementation Plan: Onboarding / Intro Screens

**Branch**: `006-onboarding-screens` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-onboarding-screens/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Show a first-time user a 5-screen, skippable intro sequence — knowing your money, remembering money between people, remembering social occasions, scanning/organizing records, and the AI assistant — before they reach the app's existing People/Overview/Settings shell, then never show it again. Implemented as a new `onboarding` clean-architecture feature whose completion flag is persisted the same way the `settings` feature persists language (a new single-row Drift table via a Dao-backed repository), gated at startup by resolving that state *before* `runApp` (mirroring `main.dart`'s existing `SettingsCubit.initialize()` await) and enforced via a global `redirect` on the existing `GoRouter`, treating `/onboarding` as an unauthenticated-style guarded route exactly like the constitution's navigation standard for protected routes. FR-010a's "existing installs count as already onboarded" rule is implemented as a dedicated `ResolveOnboardingStatus` use case that coordinates the new `OnboardingRepository` with two new lightweight existence-check methods added to the already-present `PeopleRepository` and `TransactionsRepository` — a genuine multi-repository business rule, not a trivial wrapper (constitution Principle V). Onboarding screens reuse the existing design system (`AppButton`/`AppSecondaryButton`, tokens) and the existing `gen_l10n`/theme mechanisms from features 001/002 (and 003's dark-mode tokens per this feature's Assumptions), navigated with a plain built-in `PageView`/`PageController` — no new dependency — and respect `MediaQuery.disableAnimations` for FR-013's reduced-motion requirement.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.38 stable (matches feature 002's plan)

**Primary Dependencies**: `flutter_bloc` (new `OnboardingCubit`, Principle III) for the startup gate + completion/skip actions; `go_router`'s existing `GoRouter` extended with a top-level `redirect` callback and one new top-level `GoRoute('/onboarding')` sitting outside the existing `StatefulShellRoute.indexedStack` (onboarding has no bottom nav); `drift` for a new `OnboardingStatus` table (schemaVersion 3→4 migration, assuming 003-dark-mode-theme's 2→3 migration has already landed) via the existing `AppDatabase`; `get_it` + `injectable` for DI (same generated `injection.config.dart`); `fpdart` for `Either<Failure, Success>`; `intl`/`gen_l10n` for all onboarding copy (no hardcoded strings, Principle XIII); Flutter's built-in `PageView`/`PageController` for screen navigation — **no new package dependency**, since no existing dependency (Lottie, Rive, etc.) is present and none is justified for 5 static illustrated screens.

**Storage**: Local SQLite via the existing `drift` `AppDatabase` — a new single-row `OnboardingStatus` table (schemaVersion 3→4, extending the `MigrationStrategy.onUpgrade` already added by feature 002 and further extended by feature 003's `themeMode` column migration (2→3); this feature assumes 003-dark-mode-theme's migration has already been merged — see spec Assumptions); no remote backend (fully local, per spec Assumptions: no backend/network call needed)

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail` (`OnboardingCubit` unit tests with a faked `OnboardingRepository`), Drift's in-memory `NativeDatabase.memory()` for `OnboardingRepositoryImpl`/`OnboardingDao` tests (mirrors `SettingsRepositoryImpl` test pattern) plus the new `PeopleRepository.hasAnyPerson`/`TransactionsRepository.hasAnyTransaction` cases added to their existing repository test suites, widget tests for the onboarding page (progress indicator, back/next, skip) under both LTR/RTL, `integration_test` covering first-launch → onboarding → main app, restart-doesn't-reappear, skip, and the FR-010a existing-data scenario end-to-end

**Target Platform**: Android and iOS mobile apps (existing `android/`/`ios/` platform folders; matches features 001/002)

**Project Type**: mobile-app (Flutter, feature-first clean architecture) — adds one new feature (`onboarding`) to the existing `people`/`transactions`/`settings` features

**Performance Goals**: A new user can view all 5 screens and reach the main app in under 60 seconds moving directly through without skipping (SC-002) — screen transitions MUST be immediate/non-blocking (tap-to-advance, not auto-advancing timers with forced dwell time); onboarding animations MUST be smooth and MUST NOT delay or block interaction with Next/Back/Skip controls, and MUST respect `MediaQuery.disableAnimations` (FR-013, Engineering & Quality Standards: Performance & Animation)

**Constraints**: Onboarding MUST be shown before any main-app screen is reachable on a qualifying first launch (FR-001) and MUST NOT reappear once completed/skipped (FR-009); an interrupted (killed mid-flow) onboarding MUST restart from screen 1 next launch, i.e. no partial-progress persistence (FR-010, Edge Cases); on first startup after this feature ships, any pre-existing `Person` or `MoneyTransaction` row (including archived people / soft-deleted transactions, since either still proves prior real use) MUST auto-mark onboarding complete without ever showing it (FR-010a); the AI-assistant screen's copy MUST NOT state or imply unsupported financial guarantees (FR-003, SC-005); onboarding MUST render correctly in Arabic/RTL and English/LTR (FR-011) and in Light/Dark theme (FR-012, depends on feature 003's theming mechanism per this feature's Assumptions); switching language or theme mid-onboarding MUST preserve the current screen/progress (Edge Cases); no new third-party dependency unless clearly justified (none was)

**Scale/Scope**: 1 new feature (`onboarding`); 5 fixed content screens + a step progress indicator + a persistent skip action + a final call-to-action; 1 new Drift table (`OnboardingStatus`, schemaVersion 3→4 — assumes 003-dark-mode-theme's 2→3 migration has already landed; if it hasn't, coordinate migration order first rather than both targeting version 3); 2 new lightweight existence-check methods added to 2 existing repositories (`PeopleRepository.hasAnyPerson`, `TransactionsRepository.hasAnyTransaction`) plus their Dao/Impl; 1 new top-level route and a global `redirect` gate added to `app_router.dart`; `main.dart`'s startup sequence extended with one more awaited Cubit initialization alongside `SettingsCubit`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
| --- | --- | --- |
| I. Clean Architecture Layering | New `onboarding` feature split into `data/domain/presentation`; `OnboardingCubit` never touches `drift` directly, only `OnboardingRepository` (Domain abstraction) and the `ResolveOnboardingStatus` use case; `OnboardingPage`/widgets are pure Presentation with no business logic or direct DB/repository-implementation access | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/onboarding/`; the router redirect/route addition lives in the existing cross-feature `lib/core/routing/`, not a new catch-all folder; the two new existence-check methods live inside `people`/`transactions`' own repositories/Daos (each feature still owns its own table) | PASS |
| III. BLoC/Cubit Mandate | `OnboardingCubit` is a `flutter_bloc` `Cubit`, same pattern as `SettingsCubit`. The in-flow screen index (which `PageView` page is showing) is treated as ephemeral UI/navigation state kept locally in `OnboardingPage`'s `PageController`, exactly like `MainShell`'s `StatefulNavigationShell.currentIndex` today — not promoted to Cubit state, since it carries no business meaning and nothing else needs to observe it; documented in research.md | PASS |
| IV. Immutable State | `OnboardingState` is an `Equatable` value class (a `status` field of a presentation-only `OnboardingLoadStatus` enum: `resolving` / `showOnboarding` / `mainApp` — distinct from the domain-layer `OnboardingGateStatus` in contracts/onboarding_repository.md, which has only `showOnboarding`/`mainApp` since it never represents the pre-resolution loading moment) updated via `copyWith()`, mirroring `SettingsState`'s shape | PASS |
| V. Domain-Driven Business Logic | `ResolveOnboardingStatus` is a real business action: it coordinates 3 repositories (`OnboardingRepository`, `PeopleRepository`, `TransactionsRepository`) to implement FR-010a's existing-user rule and, when it detects pre-existing data, itself calls `OnboardingRepository.completeOnboarding()` — genuine multi-repository coordination, not a passthrough. Completing/skipping onboarding from the UI calls `OnboardingRepository.completeOnboarding()` directly from `OnboardingCubit` (no wrapper use case), which matches the existing codebase precedent of `TransactionFormCubit`/`ArchivedPeopleCubit` injecting a repository directly alongside use cases rather than manufacturing a trivial one-call use case | PASS |
| VI. Repository Pattern | Domain defines `OnboardingRepository`; Data provides `OnboardingRepositoryImpl` backed by a new `OnboardingDao` — same shape as `SettingsRepository`/`SettingsRepositoryImpl`/`SettingsDao`. `PeopleRepository`/`TransactionsRepository` each gain one new interface method (`hasAnyPerson`/`hasAnyTransaction`) implemented against their own existing Dao/table — `onboarding` never reaches into `people`'s or `transactions`' tables directly | PASS |
| VII. Explicit Error Handling | `OnboardingRepository` and the new repository methods return `Either<Failure, T>` (`CacheFailure` for local DB I/O errors), never a raw exception. If `ResolveOnboardingStatus` itself fails (e.g. a `CacheFailure` reading the flag or the existence checks), `OnboardingCubit` fails open to `mainApp` rather than blocking the user behind an unresolvable gate — logged, never silently swallowed; documented as a deliberate decision in research.md | PASS |
| VIII. Deterministic Financial Calculations | Not applicable — no financial calculation in this feature | PASS (N/A) |
| IX. AI Isolation | Not applicable — the AI-assistant onboarding screen (FR-003) is static descriptive copy about the existing AI feature; it does not call any AI/LLM integration itself | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — the scanning/OCR onboarding screen (FR-002 item 4) is static descriptive copy; no OCR flow is invoked from onboarding | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Fully local, no network — "offline" is the permanent default, consistent with feature 002. `completeOnboarding()`'s local-write failure never blocks navigation into the main app (fail-open, same philosophy as feature 002's FR-008 policy, though no user-facing retry/notice is required here since no FR demands one) | PASS |
| XII. Security & Secrets | No secrets/credentials/sensitive data involved — the onboarding-completion flag and the existence-check booleans are not sensitive; no new logging of sensitive values | PASS (N/A) |
| XIII. Localization & RTL/LTR | Every onboarding string comes from `gen_l10n` (`app_en.arb`/`app_ar.arb`), extended with new keys per screen; layout, progress indicator, and Back/Next/Skip controls MUST mirror correctly under RTL using the same `Directionality`-driven Material widgets already used by `MainShell` (FR-011) | PASS |
| XIV. Dependency Injection | `OnboardingRepository`, `OnboardingDao`, `ResolveOnboardingStatus`, and `OnboardingCubit` are all wired through the existing `get_it`/`injectable` setup, regenerating `injection.config.dart` exactly as feature 002 did for `settings` | PASS |
| XV. Design System | Onboarding screens reuse `core/design_system` tokens and shared widgets (`AppButton` for the final CTA/Next, `AppSecondaryButton` for Back, tokens for spacing/typography/radius) — no new hardcoded colors/spacing; a new `OnboardingProgressIndicator` widget is scoped to `lib/features/onboarding/presentation/widgets/` (not promoted to `core/` — only one feature uses it, per Principle XV's promotion rule) | PASS |
| XVI. Testability by Design | Unit tests for `OnboardingRepositoryImpl`/`OnboardingDao` (in-memory Drift), `ResolveOnboardingStatus` (mocked repositories, covering FR-010a's auto-complete branch), `OnboardingCubit` (`bloc_test` + `mocktail`), widget tests for progress indicator/back/next/skip under LTR and RTL, and an `integration_test` end-to-end onboarding flow covering all 4 user stories | PASS |

Additional Engineering & Quality Standards checked: **Performance & Animation** — transitions are tap-driven (no forced auto-advance dwell), respect `MediaQuery.disableAnimations` (FR-013) → PASS. **Accessibility** — reuses `AppButton`'s existing 48dp touch targets, text uses themed styles that respond to system text scaling, progress is conveyed with both a visual indicator and localized "step X of N" text (never color alone) → PASS. **Navigation** — the onboarding gate is implemented as a single centralized `redirect` on the existing `GoRouter`, following the same "protected route" navigation standard the constitution calls for auth-gated routes → PASS.

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): The single-row `OnboardingStatus` table, the two new existence-check repository methods, and the `ResolveOnboardingStatus` use case added during design are the minimal implementation of FR-008/FR-009/FR-010a — no speculative scope (in particular, no partial-progress/step-position persistence was added, per the spec's Edge Cases requiring a full restart on interruption). The decision to keep the in-flow `PageView` index as local widget state rather than Cubit state, and to have `OnboardingCubit` call `OnboardingRepository` directly for completion (rather than a trivial wrapper use case), both follow direct precedent already present in this codebase (`MainShell`, `TransactionFormCubit`/`ArchivedPeopleCubit`). No new dependency, layering, or state-management deviation was introduced beyond what the Constitution Check above already accounted for; all gates remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/006-onboarding-screens/
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
│   ├── database/
│   │   └── app_database.dart        # +OnboardingStatus table, schemaVersion 3→4 (assumes
│   │                                   003-dark-mode-theme's 2→3 migration already landed),
│   │                                   MigrationStrategy.onUpgrade extended (from < 4 branch)
│   ├── di/                          # regenerated injection.config.dart (onboarding + new deps registered)
│   ├── l10n/                        # app_en.arb / app_ar.arb — +onboarding screen copy, progress text,
│   │                                   skip/back/next/get-started labels
│   └── routing/
│       └── app_router.dart          # +top-level `redirect` gate (onboarding vs main app) +
│                                       new top-level GoRoute('/onboarding'), outside the
│                                       StatefulShellRoute (no bottom nav on this screen)
│
├── features/
│   ├── onboarding/                  # NEW feature
│   │   ├── data/
│   │   │   ├── datasources/         # OnboardingDao (drift, single-row OnboardingStatus table)
│   │   │   └── repositories/        # OnboardingRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/            # OnboardingTopic (Flutter-free enum: the 5 fixed screen topics)
│   │   │   ├── repositories/        # OnboardingRepository (abstract)
│   │   │   └── usecases/            # ResolveOnboardingStatus (coordinates OnboardingRepository +
│   │   │                              PeopleRepository.hasAnyPerson + TransactionsRepository.hasAnyTransaction)
│   │   └── presentation/
│   │       ├── cubit/               # OnboardingCubit (root-scoped startup gate + complete/skip actions),
│   │       │                          OnboardingState
│   │       ├── onboarding_content.dart  # static OnboardingTopic → l10n getter/icon mapping (Presentation-
│   │       │                              layer, since it needs BuildContext/l10n — keeps Domain Flutter-free)
│   │       ├── pages/                # OnboardingPage (PageView host + local PageController/step index)
│   │       └── widgets/              # OnboardingProgressIndicator, OnboardingScreenView, OnboardingControls
│   │                                   (Back / Skip / Next / Get Started row)
│   │
│   ├── people/
│   │   ├── domain/repositories/people_repository.dart          # +hasAnyPerson()
│   │   ├── data/repositories/people_repository_impl.dart       # +hasAnyPerson()
│   │   └── data/datasources/people_dao.dart                    # +hasAnyPerson() (SELECT ... LIMIT 1,
│   │                                                              active + archived)
│   └── transactions/
│       ├── domain/repositories/transactions_repository.dart    # +hasAnyTransaction()
│       ├── data/repositories/transactions_repository_impl.dart # +hasAnyTransaction()
│       └── data/datasources/transactions_dao.dart               # +hasAnyTransaction() (SELECT ... LIMIT 1,
│                                                                   including soft-deleted rows)
│
└── main.dart                         # +await getIt<OnboardingCubit>().initialize() alongside the existing
                                        SettingsCubit.initialize() await, before runApp; +MultiBlocProvider

test/
├── features/
│   ├── onboarding/
│   │   ├── domain/usecases/          # ResolveOnboardingStatus — faked OnboardingRepository/PeopleRepository/
│   │   │                               TransactionsRepository, covering the FR-010a auto-complete branch
│   │   ├── data/repositories/        # OnboardingRepositoryImpl — against an in-memory drift DB
│   │   └── presentation/cubit/       # OnboardingCubit — bloc_test + mocktail
│   ├── people/domain/usecases/       # (existing suite) + hasAnyPerson cases
│   └── transactions/domain/usecases/ # (existing suite) + hasAnyTransaction cases
└── widget/
    └── onboarding_page_test.dart     # NEW — progress indicator advances on Next/Back, Skip navigates to
                                        main app, renders correctly under LTR and RTL

integration_test/
└── onboarding_flow_test.dart         # NEW — first launch shows onboarding before main app is reachable,
                                        forward/back/progress, finish → main app, restart doesn't reappear,
                                        skip → main app → restart doesn't reappear, FR-010a existing-data
                                        auto-complete, and language/theme switch mid-onboarding preserves
                                        screen/progress (spec User Stories 1-4 + Edge Cases)
```

**Structure Decision**: Same single Flutter app shape as features 001/002 (Option 1), extended with one new feature-first module (`lib/features/onboarding/`) following the identical `data/domain/presentation` layering as `settings`. The onboarding gate/route addition is a cross-feature routing concern and correctly lives in the existing `lib/core/routing/app_router.dart` (Principle II) rather than inside `onboarding` itself; the two new existence-check methods stay inside their owning features' repositories rather than a new cross-feature query surface, preserving Principle VI's boundary. No `backend/`/`api/` split; this feature adds no network layer. Tests continue to mirror `lib/` under `test/`, plus `integration_test/` for the end-to-end onboarding flow.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
