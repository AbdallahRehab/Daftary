---

description: "Task list for Onboarding / Intro Screens"
---

# Tasks: Onboarding / Intro Screens

**Input**: Design documents from `/specs/006-onboarding-screens/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/onboarding_repository.md, quickstart.md

**Tests**: Test tasks are included — plan.md's Testing section and quickstart.md's "Automated validation" / Definition of Done list explicit unit, `bloc_test`, widget, and `integration_test` coverage for this feature (mirroring the established pattern in `integration_test/language_switch_flow_test.dart`), and constitution Principle XVI requires it; they are not optional here.

**Organization**: Tasks are grouped by user story (spec.md priorities P1/P1/P1/P2) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Exact file paths are given for every task

## Path Conventions

Single Flutter app (feature-first clean architecture), matching features 001/002/003:

- `lib/core/` — cross-feature infrastructure (database, DI, l10n, routing)
- `lib/features/onboarding/{data,domain,presentation}/` — this feature's new module
- `lib/features/people/`, `lib/features/transactions/` — existing features gaining one new repository method each
- `test/` mirrors `lib/`; `integration_test/` holds end-to-end flows

---

## Phase 1: Setup

**Purpose**: Create the new feature's directory skeleton. No new package dependency is needed (plan.md's Technical Context confirms `flutter_bloc`, `go_router`, `drift`, `get_it`/`injectable`, `fpdart`, `intl` are all already present; `PageView`/`PageController` are built-in).

- [ ] T001 Create the `onboarding` feature skeleton directories: `lib/features/onboarding/data/datasources/`, `lib/features/onboarding/data/repositories/`, `lib/features/onboarding/domain/entities/`, `lib/features/onboarding/domain/repositories/`, `lib/features/onboarding/domain/usecases/`, `lib/features/onboarding/presentation/cubit/`, `lib/features/onboarding/presentation/pages/`, `lib/features/onboarding/presentation/widgets/`
- [ ] T002 [P] Create the mirrored test skeleton directories: `test/features/onboarding/data/repositories/`, `test/features/onboarding/domain/usecases/`, `test/features/onboarding/presentation/cubit/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The persistence layer and the FR-010a existing-data business rule that every user story either shows (US1), navigates through (US2), relies on for its "does not reappear" guarantee (US3), or writes to via a second path (US4, Skip).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T003 In `lib/core/database/app_database.dart`, add the new `OnboardingStatus` Drift table exactly per data-model.md: `id` (`TextColumn`, primary key) — "Always the fixed constant `'singleton'` — never more than one row, same pattern as `AppSettings`"; `isComplete` (`BoolColumn`, `withDefault(const Constant(false))`) — "`true` once the user has finished the last screen, explicitly skipped, or the app auto-detected pre-existing data (FR-010a)"; `completedAt` (`IntColumn`, nullable, epoch ms) — "Set once, at the moment `isComplete` is written `true`. `null` while no row exists yet or `isComplete` is still `false`." Add `OnboardingStatus` to the `@DriftDatabase(tables: [...])` list, bump `schemaVersion` from `3` to `4` (this assumes `003-dark-mode-theme`'s own `2`→`3` migration has already been merged — confirm `schemaVersion` is actually `3` before starting this task; if `003-dark-mode-theme` hasn't shipped yet, coordinate migration order first rather than both claiming version `3`), and extend `MigrationStrategy.onUpgrade` per data-model.md's Migration section: `if (from < 4) { await m.createTable(onboardingStatus); }` (leave the existing `if (from < 2)` and `if (from < 3)` branches untouched)
- [ ] T004 [P] Create the `OnboardingTopic` domain enum (Flutter-free per Principle I) in `lib/features/onboarding/domain/entities/onboarding_topic.dart` with exactly the 5 values in this declaration order (data-model.md: "`OnboardingTopic.values` ... **is** the sequence and step count driving the progress indicator"): `understandingMoney` (FR-002(1)), `moneyBetweenPeople` (FR-002(2)), `socialOccasions` (FR-002(3)), `scanningRecords` (FR-002(4)), `aiAssistant` (FR-002(5))
- [ ] T005 Create `OnboardingDao` (`@injectable`, constructor-injected `AppDatabase`, mirroring `lib/features/settings/data/datasources/settings_dao.dart`'s single-row shape) with `getStatus()` (returns the single `'singleton'` row or `null` if absent) and `markComplete(int completedAt)` (single-row upsert keyed on the fixed `'singleton'` id, `isComplete = true`) in `lib/features/onboarding/data/datasources/onboarding_dao.dart` (depends on T003)
- [ ] T006 [P] Create the `OnboardingRepository` abstract interface exactly as specified in contracts/onboarding_repository.md — `Future<Either<Failure, bool>> isOnboardingComplete()` and `Future<Either<Failure, Unit>> completeOnboarding()` (idempotent: "calling it again after it is already `true` is a no-op success") — in `lib/features/onboarding/domain/repositories/onboarding_repository.dart`
- [ ] T007 Create `OnboardingRepositoryImpl` (`@LazySingleton(as: OnboardingRepository)`, constructor-injected `OnboardingDao`, mirroring `lib/features/settings/data/repositories/settings_repository_impl.dart`) in `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart`: maps a `null`/`isComplete == false` row to `Right(false)`, wraps DB I/O errors as `CacheFailure` (reuse `lib/core/error/failure.dart` — no new failure type), and makes `completeOnboarding()` a no-op success if already `true` (depends on T005, T006)
- [ ] T008 [P] Add `Future<Either<Failure, bool>> hasAnyPerson();` to `lib/features/people/domain/repositories/people_repository.dart` per contracts/onboarding_repository.md: "whether at least one Person record exists at all — active OR archived (unlike `searchActivePeople`, which excludes archived). An archived-only install still proves prior real use."
- [ ] T009 [P] Add `hasAnyPerson()` to `lib/features/people/data/datasources/people_dao.dart`: a cheap `LIMIT 1`/count-style existence query against the `people` table covering both active and archived rows — never a full list fetch
- [ ] T010 Implement `PeopleRepositoryImpl.hasAnyPerson()` in `lib/features/people/data/repositories/people_repository_impl.dart`, delegating to `PeopleDao.hasAnyPerson()` and wrapping DB I/O errors as `CacheFailure` (depends on T008, T009)
- [ ] T011 [P] Add `Future<Either<Failure, bool>> hasAnyTransaction();` to `lib/features/transactions/domain/repositories/transactions_repository.dart` per contracts/onboarding_repository.md: "whether at least one MoneyTransaction record exists at all — including soft-deleted rows (`deletedAt IS NOT NULL`). A since-deleted transaction still proves the app was previously used, matching the existing precedent in `PeopleDao.countTransactionsForPerson`"
- [ ] T012 [P] Add `hasAnyTransaction()` to `lib/features/transactions/data/datasources/transactions_dao.dart`: a cheap `LIMIT 1`/count-style existence query against `money_transactions` including soft-deleted rows — never a full list fetch
- [ ] T013 Implement `TransactionsRepositoryImpl.hasAnyTransaction()` in `lib/features/transactions/data/repositories/transactions_repository_impl.dart`, delegating to `TransactionsDao.hasAnyTransaction()` and wrapping DB I/O errors as `CacheFailure` (depends on T011, T012)
- [ ] T014 Create `ResolveOnboardingStatus` (`@injectable`, coordinates `OnboardingRepository` + `PeopleRepository` + `TransactionsRepository`) in `lib/features/onboarding/domain/usecases/resolve_onboarding_status.dart` per contracts/onboarding_repository.md: (1) if `isOnboardingComplete()` is `true` → `OnboardingGateStatus.mainApp`; (2) else if `hasAnyPerson()` or `hasAnyTransaction()` is `true` → call `completeOnboarding()` then return `mainApp` (FR-010a); (3) else → `showOnboarding` (nothing persisted yet); on any internal `Failure` at step 1 or 2, "fails open to `mainApp` ... never returns a `Failure` itself" (research.md Decision 7) — log, never swallow silently (depends on T007, T010, T013)
- [ ] T015 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `lib/core/database/app_database.g.dart` (new `OnboardingStatus` table) and `lib/core/di/injection.config.dart` (new `OnboardingDao`, `OnboardingRepositoryImpl`, `ResolveOnboardingStatus` registrations) (depends on T003, T005, T007, T014)

**Checkpoint**: Persistence layer, the two new existence-check repository methods, and the FR-010a gate-resolution use case exist and compile — user story implementation can now begin.

---

## Phase 3: User Story 1 - First-Time User Understands the App Before Entering It (Priority: P1) 🎯 MVP

**Goal**: A first-time user launching the app sees the onboarding sequence — 5 screens, one per topic — instead of the main product, before anything else is reachable.

**Independent Test**: Install/launch the app for the first time (no prior completion recorded) and verify the onboarding sequence is shown before any main-product screen is reachable.

### Implementation for User Story 1

- [ ] T016 [US1] Create `OnboardingState` (`Equatable`, a `status` field of a new presentation-only `OnboardingLoadStatus` enum: `resolving` / `showOnboarding` / `mainApp` — distinct from the domain-layer `OnboardingGateStatus` in contracts/onboarding_repository.md, which has only `showOnboarding`/`mainApp`; `resolving` is this Cubit's own pre-resolution loading state and has no domain equivalent, per contracts/onboarding_repository.md's naming note — updated via `copyWith()`, mirroring `lib/features/settings/presentation/cubit/settings_state.dart`'s shape) in `lib/features/onboarding/presentation/cubit/onboarding_state.dart`
- [ ] T017 [US1] Create `OnboardingCubit` (`flutter_bloc` `Cubit<OnboardingState>`, `@lazySingleton` since it is root-scoped like `SettingsCubit`) with an `initialize()` method that awaits `ResolveOnboardingStatus()` and emits the resulting status, in `lib/features/onboarding/presentation/cubit/onboarding_cubit.dart` (depends on T014, T016)
- [ ] T018 [US1] Add the ARB keys for all 5 onboarding topics (one title + one description each, per FR-002, in plain language "without accounting jargon") and the step-progress text (e.g. "Step {current} of {total}") to `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_ar.arb`, then run `flutter gen-l10n` to regenerate `lib/core/l10n/app_localizations_en.dart`/`app_localizations_ar.dart` — the `aiAssistant` topic's copy MUST describe the AI assistant's capability accurately and MUST NOT state or imply unsupported financial guarantees (FR-003) (depends on T004)
- [ ] T019 [P] [US1] Create `onboarding_content.dart` — a `Map<OnboardingTopic, ...>`-style lookup returning each topic's `AppLocalizations` title/description getters plus an `IconData`/asset reference styled via `core/design_system` tokens (Presentation layer, since it needs `BuildContext`/l10n, per data-model.md) — in `lib/features/onboarding/presentation/onboarding_content.dart` (depends on T004, T018)
- [ ] T020 [P] [US1] Create `OnboardingScreenView` (renders one topic's icon/illustration + title + description using `core/design_system` tokens, no hardcoded colors/spacing) in `lib/features/onboarding/presentation/widgets/onboarding_screen_view.dart`
- [ ] T021 [US1] Create `OnboardingProgressIndicator` (always-visible step indicator per FR-004; conveys progress with both a visual element and localized "step X of N" text — never color alone, per constitution Accessibility standard) in `lib/features/onboarding/presentation/widgets/onboarding_progress_indicator.dart`
- [ ] T022 [US1] Create `OnboardingPage` — a `PageView.builder` over `OnboardingTopic.values` (research.md Decision 4) hosting `OnboardingScreenView` per page, with the current step index held as local widget state via `PageController`/`onPageChanged` (research.md Decision 5 — not `OnboardingCubit` state) driving `OnboardingProgressIndicator` — in `lib/features/onboarding/presentation/pages/onboarding_page.dart` (depends on T019, T020, T021)
- [ ] T023 [US1] In `lib/core/routing/app_router.dart`, add a new top-level `GoRoute('/onboarding')` (a sibling of the existing `StatefulShellRoute.indexedStack`, not nested inside it — no bottom nav) building `OnboardingPage`, and add a global `redirect:` callback on the `GoRouter` constructor per research.md Decision 1: redirect to `/onboarding` when `OnboardingCubit`'s state is `showOnboarding` and the current location isn't already `/onboarding`; redirect to `/` when its state is `mainApp` and the current location is `/onboarding`; otherwise no redirect (depends on T017, T022)
- [ ] T024 [US1] In `lib/main.dart`, await `getIt<OnboardingCubit>().initialize()` before `runApp`, alongside the existing `SettingsCubit.initialize()` await, and wrap `DaftaryApp`'s subtree in a `MultiBlocProvider` providing both `SettingsCubit` and `OnboardingCubit` (depends on T017)
- [ ] T025 [US1] Run `dart run build_runner build --delete-conflicting-outputs` again to regenerate `lib/core/di/injection.config.dart` with the new `@lazySingleton OnboardingCubit` registration (depends on T017)
- [ ] T026 [P] [US1] Unit tests for `OnboardingRepositoryImpl`/`OnboardingDao` against Drift's in-memory `NativeDatabase.memory()`: `isOnboardingComplete()` returns `Right(false)` when no row exists yet, persist-then-read-back returns `Right(true)` after `completeOnboarding()`, and a second `completeOnboarding()` call is a no-op success (idempotency, per contract), in `test/features/onboarding/data/repositories/onboarding_repository_impl_test.dart` (depends on T007)
- [ ] T027 [P] [US1] Add `hasAnyPerson()` cases to the existing suite in `test/features/people/data/repositories/people_repository_impl_test.dart`: `Right(false)` with no people, `Right(true)` with an active person, and `Right(true)` with only an archived person (depends on T010)
- [ ] T028 [P] [US1] Add `hasAnyTransaction()` cases to the existing suite in `test/features/transactions/data/repositories/transactions_repository_impl_test.dart`: `Right(false)` with no transactions, `Right(true)` with an active transaction, and `Right(true)` with only a soft-deleted transaction (depends on T013)
- [ ] T029 [P] [US1] Unit tests for `ResolveOnboardingStatus` with faked `OnboardingRepository`/`PeopleRepository`/`TransactionsRepository`, covering: already-complete short-circuits to `mainApp`; a Person-only, a MoneyTransaction-only, an archived-person-only, and a soft-deleted-transaction-only install each auto-complete onboarding and return `mainApp` (FR-010a); a genuinely empty install returns `showOnboarding` with nothing persisted; and any repository `Failure` fails open to `mainApp` (research.md Decision 7), in `test/features/onboarding/domain/usecases/resolve_onboarding_status_test.dart` (depends on T014)
- [ ] T030 [P] [US1] `bloc_test` unit test asserting `OnboardingCubit.initialize()` emits `OnboardingState(status: showOnboarding)` for a fresh install, given a faked `ResolveOnboardingStatus`, in `test/features/onboarding/presentation/cubit/onboarding_cubit_test.dart` (depends on T017)
- [ ] T031 [US1] Widget test asserting `OnboardingPage` renders the 5 topics in `OnboardingTopic.values` order (understanding money → money between people → social occasions → scanning records → AI assistant) with no accounting jargon, and `OnboardingProgressIndicator` shows the correct step/total, under both `Directionality.ltr` and `Directionality.rtl`, in `test/widget/onboarding_page_test.dart` (depends on T022)
- [ ] T032 [US1] Create `integration_test/onboarding_flow_test.dart` (new file, mirroring `integration_test/language_switch_flow_test.dart`'s `bootApp()`-style helper against a real on-device SQLite database): a fresh install shows `OnboardingPage` before `MainShell`/`NavigationBar` is reachable on cold start (US1 Acceptance Scenario 1); plus the FR-010a existing-data scenarios — seed a `Person`-only, a `MoneyTransaction`-only, an archived-person-only, and a soft-deleted-transaction-only database state (no `OnboardingStatus` row) and verify each launches directly to the main entry point with `OnboardingStatus.isComplete` now `true` (depends on T023, T024)

**Checkpoint**: User Story 1 is fully functional and independently testable — a first-time user is shown the 5-screen onboarding sequence before the main app, and an existing-data install is never shown it.

---

## Phase 4: User Story 2 - User Navigates and Completes Onboarding (Priority: P1)

**Goal**: The user can move forward/backward through the onboarding screens with correct progress shown at every step, and reach a final call-to-action that takes them into the main app.

**Independent Test**: Step through every onboarding screen using next/back controls, verify the progress indicator updates correctly at each step, and verify the final screen's call-to-action takes the user into the main app.

### Implementation for User Story 2

- [ ] T033 [US2] Create `OnboardingControls` (a Back / Next / Get Started row using `AppButton` for the primary Next/Get Started action and `AppSecondaryButton` for Back, per plan.md; Back hidden/disabled on screen 1, the label reads "Get Started"/finish-style rather than "Next" on the final screen per FR-007) in `lib/features/onboarding/presentation/widgets/onboarding_controls.dart`
- [ ] T034 [US2] Wire `OnboardingPage` (`lib/features/onboarding/presentation/pages/onboarding_page.dart`) to `OnboardingControls`: Next/Back call `pageController.nextPage()`/`previousPage()`, `onPageChanged` keeps the local step index (and thus `OnboardingProgressIndicator`) in sync; read `MediaQuery.of(context).disableAnimations` and use `pageController.jumpToPage(i)` instead of `animateToPage(...)` when `true` (FR-013, research.md Decision 3) (depends on T022, T033)
- [ ] T035 [US2] Add a `completeOnboarding()` method to `OnboardingCubit` (`lib/features/onboarding/presentation/cubit/onboarding_cubit.dart`) that calls `OnboardingRepository.completeOnboarding()` directly (no wrapper use case, per contracts/onboarding_repository.md and plan.md's Constitution Check Principle V) and then emits `OnboardingState(status: mainApp)` (depends on T017)
- [ ] T036 [US2] Wire the final onboarding screen's `OnboardingControls` call-to-action to invoke `OnboardingCubit.completeOnboarding()`, which flips `OnboardingCubit`'s state to `mainApp` and lets the T023 router `redirect` take the user to the main entry point (FR-007) (depends on T034, T035)
- [ ] T037 [US2] Add the ARB keys for the Back / Next / Get Started button labels to `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_ar.arb`, then run `flutter gen-l10n` (depends on T033)
- [ ] T038 [P] [US2] Extend `test/widget/onboarding_page_test.dart`: tapping Next advances the screen and updates the progress text at each step; tapping Back from any screen after the first returns to the previous screen with progress decremented correctly; tapping the final screen's call-to-action invokes `OnboardingCubit.completeOnboarding()` (mocked cubit, mirroring `test/widget/settings_page_test.dart`'s `MockCubit` pattern) (depends on T034, T036)
- [ ] T039 [P] [US2] Extend `test/features/onboarding/presentation/cubit/onboarding_cubit_test.dart` with a `bloc_test` asserting `completeOnboarding()` calls the faked `OnboardingRepository.completeOnboarding()` and emits `OnboardingState(status: mainApp)` (depends on T035)
- [ ] T040 [US2] Extend `integration_test/onboarding_flow_test.dart`: from a fresh install, tap Next repeatedly through all 5 screens verifying the progress indicator at each step and correct content per topic; tap Back and verify correct decrement; on screen 5, tap the call-to-action and verify landing on the main app's People list; time the direct walkthrough and assert it completes in under 60 seconds (SC-002) (depends on T036)

**Checkpoint**: User Stories 1 and 2 both work independently — onboarding is shown, fully navigable, and exits correctly into the main app.

---

## Phase 5: User Story 3 - Completion Is Remembered So Onboarding Does Not Reappear (Priority: P1)

**Goal**: Once a user has completed onboarding, every subsequent launch goes straight to the main app; an app killed mid-onboarding shows onboarding again from the start rather than resuming or corrupting state.

**Independent Test**: Complete onboarding, fully close the app, and reopen it; verify the app goes directly to the normal entry point with no onboarding shown. Repeat using the skip path if skip is available.

### Implementation for User Story 3

> No new production code is required beyond Phase 2/3/4's work: data-model.md deliberately defines no partial-progress/"started" state, so an interrupted onboarding already has nothing to resume from, and `OnboardingCubit.initialize()` (T017) already re-resolves the persisted flag on every launch. This story is verification that those design decisions hold end-to-end.

- [ ] T041 [US3] Extend `test/features/onboarding/presentation/cubit/onboarding_cubit_test.dart` with a `bloc_test` asserting `initialize()` resolves directly to `OnboardingState(status: mainApp)`, with no intermediate `showOnboarding` emission, when the faked `ResolveOnboardingStatus` reports onboarding already complete (depends on T017, T030)
- [ ] T042 [US3] Extend `integration_test/onboarding_flow_test.dart` (US3 Acceptance Scenario 1): complete onboarding via the final call-to-action, then rebuild the widget tree against the same underlying `AppDatabase` (simulating a restart, mirroring `language_switch_flow_test.dart`'s `bootApp()` helper), and verify `OnboardingPage` never appears and the app opens directly to the main entry point (depends on T036, T032)
- [ ] T043 [US3] Extend `integration_test/onboarding_flow_test.dart` (Edge Case): fresh install, advance to screen 3 of 5, then simulate a force-kill by rebuilding the widget tree without ever calling `completeOnboarding()`/skip, and verify onboarding shows again starting from screen 1, not resumed at screen 3, and no `OnboardingStatus` row was written (FR-010) (depends on T032)

**Checkpoint**: User Stories 1-3 are all independently functional — onboarding shows once, navigates correctly, and never reappears once genuinely completed; an interrupted flow always restarts cleanly.

---

## Phase 6: User Story 4 - User Can Skip Onboarding (Priority: P2)

**Goal**: A user can skip the remaining onboarding screens from any point and land directly in the main app, with that choice remembered on the next launch exactly like a normal completion.

**Independent Test**: From any onboarding screen, choose skip and verify the user lands directly in the main app, and that this choice is remembered on the next launch (per User Story 3).

### Implementation for User Story 4

- [ ] T044 [US4] Add a Skip action to `OnboardingControls` (`lib/features/onboarding/presentation/widgets/onboarding_controls.dart`), reachable from every onboarding screen including the first and last (FR-006) (depends on T033)
- [ ] T045 [US4] Add a `skipOnboarding()` method to `OnboardingCubit` (`lib/features/onboarding/presentation/cubit/onboarding_cubit.dart`) that calls `OnboardingRepository.completeOnboarding()` — "the repository does not distinguish the reason, per data-model.md's deliberately minimal flag" — then emits `OnboardingState(status: mainApp)`, exactly like `completeOnboarding()` (depends on T035)
- [ ] T046 [US4] Wire the Skip control (`OnboardingPage`/`OnboardingControls`) to invoke `OnboardingCubit.skipOnboarding()` from any screen, letting the T023 router `redirect` take the user to the main entry point immediately, with no confirmation dialog required by the spec (depends on T044, T045, T023)
- [ ] T047 [US4] Add the ARB key for the Skip label to `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_ar.arb`, then run `flutter gen-l10n` (depends on T044)
- [ ] T048 [P] [US4] Extend `test/widget/onboarding_page_test.dart`: tapping Skip from the first, a middle, and the last onboarding screen each invokes `OnboardingCubit.skipOnboarding()` (mocked cubit) (depends on T046)
- [ ] T049 [P] [US4] Extend `test/features/onboarding/presentation/cubit/onboarding_cubit_test.dart` with a `bloc_test` asserting `skipOnboarding()` calls the faked `OnboardingRepository.completeOnboarding()` and emits `OnboardingState(status: mainApp)` (depends on T045)
- [ ] T050 [US4] Extend `integration_test/onboarding_flow_test.dart` (US4 Acceptance Scenarios 1-2): from a middle onboarding screen, tap Skip and verify landing directly in the main app; then rebuild the widget tree against the same underlying `AppDatabase` (restart) and verify onboarding does not reappear (depends on T046)

**Checkpoint**: All 4 user stories are independently functional — SC-001 through SC-005 are verifiable end-to-end.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final gates spanning all four user stories.

- [ ] T051 [P] Manual content review of the `aiAssistant` topic's ARB copy (`lib/core/l10n/app_en.arb`/`app_ar.arb`): confirm it describes the AI assistant's capability accurately and contains zero unsupported financial promises or guarantees (FR-003, SC-005) — sign off in the PR description
- [ ] T052 [P] Visual review of all 5 `OnboardingScreenView` screens, `OnboardingProgressIndicator`, and `OnboardingControls` in both Arabic/RTL and English/LTR, and in both Light and Dark theme (FR-011, FR-012, SC-004) — fix any cut-off text, broken layout, or incorrect mirroring found — also include a pass at a small-screen width (e.g. `SizedBox(width: 320)` in a widget test, or the smallest supported device/simulator) confirming all content, controls, and the progress indicator remain fully visible and usable, wrapping/resizing rather than being cut off (Edge Cases: "very small screens")
- [ ] T053 Extend `integration_test/onboarding_flow_test.dart` (Edge Case): from mid-onboarding, switch the app language (Arabic ↔ English) via `SettingsCubit`, then switch theme (Light ↔ Dark) — verify the same screen/step index is preserved both times and content re-renders correctly in the new language/direction/theme (research.md Decision 6) (depends on T040)
- [ ] T054 [P] Manual accessibility pass: enable OS-level Reduce Motion (iOS) / Remove Animations (Android) and confirm onboarding transitions are instant with Next/Back/Skip always immediately tappable (FR-013); separately enable a large system text-size setting and confirm no onboarding text or control is cut off, wrapping instead (FR-014, Edge Cases)
- [ ] T055 Run `flutter analyze` and resolve any warnings/errors introduced by this feature
- [ ] T056 Run `flutter test` and `flutter test integration_test` in full and fix any regressions surfaced across the whole suite (not just this feature's new tests)
- [ ] T057 Manually run quickstart.md's full validation — all 4 User Stories, FR-010a's four seeded-data cases, and both Edge Cases (app killed mid-onboarding; language/theme switch mid-onboarding) — as a final smoke test before considering the feature done

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories (the `OnboardingStatus` table, `OnboardingRepository`, `hasAnyPerson`/`hasAnyTransaction`, and `ResolveOnboardingStatus` are shared by every story)
- **User Story 1 (Phase 3)**: Depends on Foundational only
- **User Story 2 (Phase 4)**: Depends on Foundational; also extends `OnboardingPage`/`OnboardingCubit`/`app_router.dart` created in US1 (T017, T022, T023) — cannot start until those files exist
- **User Story 3 (Phase 5)**: Depends on Foundational and on US2's `completeOnboarding()` wiring (T035, T036) for its "complete → restart" scenario; adds no new production code, only verification
- **User Story 4 (Phase 6)**: Depends on Foundational and on US2's `OnboardingControls`/`OnboardingCubit.completeOnboarding()` (T033, T035) which `skipOnboarding()` mirrors; its "skip → restart" scenario also reuses US3's restart-testing pattern
- **Polish (Phase 7)**: Depends on all 4 user stories being complete

### Within Each User Story

- US1: State/Cubit (T016-T017) → content/ARB (T018-T019) → widgets (T020-T021) → page (T022) → routing/startup wiring (T023-T025) → tests (T026-T032)
- US2: Controls widget (T033) → page wiring + reduced motion (T034) → Cubit completion method (T035) → CTA wiring (T036) → ARB (T037) → tests (T038-T040)
- US3: Tests only (T041-T043), built on US1/US2's implementation
- US4: Skip control (T044) → Cubit skip method (T045) → wiring (T046) → ARB (T047) → tests (T048-T050)

### Parallel Opportunities

- T001/T002 in parallel
- Within Foundational: T004 in parallel with T003; T006 in parallel with T003/T004; T008/T009 in parallel; T011/T012 in parallel
- Within US1: T019 and T020 in parallel; T026, T027, T028, T029, T030 in parallel once their respective implementation tasks land
- Within US2: T038 and T039 in parallel
- Within US4: T048 and T049 in parallel
- Within Polish: T051, T052, T054 in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch independent Foundational tasks together:
Task: "Create the OnboardingTopic domain enum in lib/features/onboarding/domain/entities/onboarding_topic.dart"
Task: "Create the OnboardingRepository interface in lib/features/onboarding/domain/repositories/onboarding_repository.dart"
Task: "Add hasAnyPerson() to lib/features/people/domain/repositories/people_repository.dart"
Task: "Add hasAnyPerson() to lib/features/people/data/datasources/people_dao.dart"
```

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 test tasks together once their implementation tasks are done:
Task: "OnboardingRepositoryImpl/OnboardingDao unit tests in test/features/onboarding/data/repositories/onboarding_repository_impl_test.dart"
Task: "hasAnyPerson cases in test/features/people/data/repositories/people_repository_impl_test.dart"
Task: "hasAnyTransaction cases in test/features/transactions/data/repositories/transactions_repository_impl_test.dart"
Task: "ResolveOnboardingStatus unit tests in test/features/onboarding/domain/usecases/resolve_onboarding_status_test.dart"
Task: "OnboardingCubit bloc_test in test/features/onboarding/presentation/cubit/onboarding_cubit_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run quickstart.md's User Story 1 + FR-010a scenarios — onboarding shows on a genuinely fresh install and never on an existing-data install
5. Demo if ready — note the onboarding sequence will not yet be navigable with Next/Back/CTA controls beyond swipe (that's User Story 2)

### Incremental Delivery

1. Setup + Foundational → persistence/gate-resolution foundation ready
2. Add User Story 1 → validate independently → demo (MVP: onboarding shows/hides correctly at startup)
3. Add User Story 2 → validate independently → demo (adds Next/Back/progress/final CTA)
4. Add User Story 3 → validate independently → demo (confirms restart/interruption correctness — no new UI)
5. Add User Story 4 → validate independently → demo (adds Skip)
6. Polish → final full-suite run and manual smoke test

### Parallel Team Strategy

With two developers after Foundational is done:

1. Developer A: User Story 1 → User Story 2 → User Story 3 (sequential — each builds directly on the previous story's `OnboardingCubit`/`OnboardingPage`/`app_router.dart`)
2. Developer B: `hasAnyPerson`/`hasAnyTransaction` test coverage (T027, T028) and the Polish-phase visual/accessibility reviews (T051, T052, T054) can proceed once Foundational lands, largely independent of the UI work
3. User Story 4 is best done last by whichever developer finishes first, since it directly extends US2's `OnboardingControls`/`OnboardingCubit`
4. Both converge for Phase 7 Polish once all four stories are done
