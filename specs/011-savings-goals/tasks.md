---

description: "Task list for Savings Goals (feature 011)"
---

# Tasks: Savings Goals

**Input**: Design documents from `/specs/011-savings-goals/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included, consistent with 001/007/008/009/010's precedent (constitution Principle XVI). Each user story's tests are written before its implementation tasks (TDD ordering). `SavingsCalculator`'s pure-function tests (Foundational phase) are the single most exhaustively covered file in this feature, per its role as the sole source of truth for every completion/what-if figure.

**Organization**: Tasks are grouped by user story (spec.md priorities P1-P3) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Maps to spec.md user stories (US1-US4)
- File paths follow plan.md's Project Structure exactly

## Path Conventions

Single Flutter app, feature-first per constitution Principle II: `lib/core/`, `lib/features/savings/{data,domain,presentation}` — a fully independent feature sharing no entity with any existing one; `test/` mirrors `lib/`; `integration_test/` for end-to-end flows.

---

## Phase 1: Setup

**Purpose**: Directory skeleton — no new dependency is required for this feature (plan.md Technical Context).

- [ ] T001 Create the directory skeleton: `lib/features/savings/{data/{datasources,models,repositories},domain/{entities,repositories,services,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/features/savings/{domain/services,domain/usecases,data/repositories,presentation/cubit}/`.

**Checkpoint**: Directories exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema/entities and the pure `SavingsCalculator` service every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T002 [P] Define the `SavingsGoal` entity (`id`, `idempotencyKey`, `name`, `type?`, `targetAmountMinorUnits`, `monthlyContributionMinorUnits?`, `targetDate?`, `isArchived`, `createdAt`, `updatedAt`, `deletedAt?`) in `lib/features/savings/domain/entities/savings_goal.dart`, per data-model.md.
- [ ] T003 [P] Define the standard goal-`type` constant list (`emergencyFund`, `newCar`, `wedding`, `vacation`, `newPhone`, `homeFurniture`, `education`, `other`) in `lib/features/savings/domain/entities/savings_goal_type.dart`, plus a helper distinguishing a standard value from a plain custom-named goal (research.md Assumptions — cosmetic only).
- [ ] T004 [P] Define the `ContributionType` enum (`contribution`/`withdrawal`) and the `SavingsContribution` entity (`id`, `idempotencyKey`, `goalId`, `type`, `amountMinorUnits`, `date`, `note?`, `createdAt`, `editedAt?`, `deletedAt?`) in `lib/features/savings/domain/entities/savings_contribution.dart`, per data-model.md.
- [ ] T005 [P] Define the `GoalProgress`, `EstimatedCompletion`, and `WhatIfResult` value objects in `lib/features/savings/domain/entities/goal_progress.dart` and `what_if_result.dart`, per data-model.md's field tables (including `remainingMinorUnits`'s never-negative floor, `percentageProgress`'s 100%-cap, and `hasShortfall`/`shortfallMonths`).
- [ ] T006 [P] Add `GoalNotFoundFailure`, `WithdrawalExceedsBalanceFailure`, `GoalHasHistoryFailure`, `InvalidTargetDateFailure` to `lib/features/savings/domain/entities/savings_failures.dart`, extending the core `Failure`.
- [ ] T007 Define the pure `SavingsCalculator` interface and implementation (no DB/Flutter dependency, per research.md Decision 1) in `lib/features/savings/domain/services/savings_calculator.dart`: `estimateFromMonthlyContribution` (FR-010, ceil-rounded-up per Assumptions), `requiredContributionForTargetDate` (FR-011, months-remaining floored at 1), `whatIfMonthlyContribution`/`whatIfTargetDate` (FR-013/FR-014, pure — never touches `SavingsRepository`), and the FR-012 shortfall detection, per `contracts/savings_repository.md`'s `SavingsCalculator` contract.
- [ ] T008 [P] **Exhaustive unit test** `SavingsCalculator` against the spec's own worked examples (100,000 target / 35,000 current / 5,000 monthly → 13 months; the what-if 1,000-more-per-month example → 6,000/11 months; the "finish in 10 months" example → 6,500/month) plus edge cases (remaining = 0, monthly contribution larger than remaining → 1 month, a target date within the current month → floored at 1 month not divide-by-zero, a shortfall scenario, rounding-up verification for a non-whole-month division) — in `test/features/savings/domain/services/savings_calculator_test.dart`. This is the release-blocking correctness anchor for SC-003.
- [ ] T009 Update `lib/core/database/app_database.dart`: add `SavingsGoals` and `SavingsContributions` drift tables per data-model.md's Drift Schema Sketch (`UNIQUE INDEX idx_savings_goals_idempotency_key`, `UNIQUE INDEX idx_savings_contributions_idempotency_key`, `INDEX idx_savings_contributions_goal_id`); bump `schemaVersion` by 1 with the additive `onUpgrade` step. **Zero changes to any existing table**. Run `dart run build_runner build --delete-conflicting-outputs`.
- [ ] T010 Define the `SavingsRepository` abstract interface in `lib/features/savings/domain/repositories/savings_repository.dart` per `contracts/savings_repository.md` (all method signatures — implemented incrementally across US1-US4).
- [ ] T011 [P] Register `lib/core/di/injection.dart` scanning confirmation for `lib/features/savings/` (DI annotations added incrementally per task below).

**Checkpoint**: Schema, entities, and the fully-tested calculator exist. User story implementation can now begin.

---

## Phase 3: User Story 1 - Create a Savings Goal (Priority: P1) 🎯 MVP (part 1 of 2)

**Goal**: Create a goal with a target and, optionally, a starting amount, monthly contribution, and/or target date, with correct initial computed figures.

**Independent Test**: Create a goal, confirm correct remaining/estimated-completion.

### Tests for User Story 1 ⚠️

- [ ] T012 [P] [US1] Unit test `CreateSavingsGoal`: rejects `targetAmountMinorUnits <= 0` (FR-002), rejects a negative `monthlyContributionMinorUnits`, rejects a `targetDate` on/before today (`InvalidTargetDateFailure`, FR-003), creates an initial `SavingsContribution` row when `startingAmountMinorUnits > 0` is given (research.md Decision 3), accepts creation with neither monthly contribution nor target date, idempotent on retry (FR-022) — in `test/features/savings/domain/usecases/create_savings_goal_test.dart`.
- [ ] T013 [P] [US1] Repository test against an in-memory `NativeDatabase.memory()`: `SavingsRepositoryImpl.createSavingsGoal`'s idempotency-key uniqueness and the starting-amount-contribution DB-transaction correctness — in `test/features/savings/data/repositories/savings_repository_impl_test.dart`.
- [ ] T014 [P] [US1] `bloc_test` for `GoalFormCubit`: happy-path create (contribution-mode and target-date-mode), validation rejections, duplicate-tap producing exactly one saved goal — in `test/features/savings/presentation/cubit/goal_form_cubit_test.dart`.

### Implementation for User Story 1

- [ ] T015 [US1] Implement `lib/features/savings/data/datasources/savings_dao.dart` (drift DAO): insert a goal (idempotency-guarded) optionally with its initial contribution row in one DB transaction; insert/query contributions.
- [ ] T016 [P] [US1] Implement `lib/features/savings/data/models/savings_goal_mapper.dart` and `savings_contribution_mapper.dart`: map between drift rows and domain entities (T002, T004).
- [ ] T017 [US1] Implement `SavingsRepositoryImpl.createSavingsGoal` in `lib/features/savings/data/repositories/savings_repository_impl.dart` (depends on T010, T015, T016).
- [ ] T018 [P] [US1] Implement `lib/features/savings/domain/usecases/create_savings_goal.dart`, wrapping T017.
- [ ] T019 Annotate `SavingsRepositoryImpl`/`SavingsDao`, `SavingsCalculator`, and the US1 use case with `@injectable`/`@LazySingleton(as: ...)`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T007, T015-T018).
- [ ] T020 [US1] Implement `lib/features/savings/presentation/cubit/goal_form_cubit.dart` + `goal_form_state.dart`: generates a fresh idempotency key on open, supports both contribution-mode and target-date-mode entry with live preview of the computed estimate (via `SavingsCalculator`, no repository call needed for the live preview), validates per FR-002/FR-003, disables Save immediately on tap (FR-022) (depends on T007, T018).
- [ ] T021 [P] [US1] Implement `lib/features/savings/presentation/widgets/goal_progress_card.dart` (initial create/preview rendering — full progress rendering completed in US2).
- [ ] T022 [US1] Implement `lib/features/savings/presentation/pages/goal_form_page.dart`: name, type picker (standard set + custom, T003), target amount, optional starting amount, optional monthly contribution, optional target date, live-computed estimate preview, Save wired to `GoalFormCubit` (depends on T020, T021).
- [ ] T023 Register `/savings/new` route in `lib/core/routing/app_router.dart`, and add a reachable entry point from the app's main navigation (depends on T022).

**Checkpoint**: A goal can be created with correct initial computed figures.

---

## Phase 4: User Story 2 - Log Contributions and Track Progress (Priority: P1) 🎯 MVP (part 2 of 2)

**Goal**: Log contributions/withdrawals, see current/remaining/percentage/estimated-completion recompute live, achieved-state transition.

**Independent Test**: Log several contributions and a withdrawal; confirm all figures recalculate correctly.

### Tests for User Story 2 ⚠️

- [ ] T024 [P] [US2] Unit test `LogContribution`/`LogWithdrawal`: rejects `amountMinorUnits <= 0` (FR-007), `LogWithdrawal` rejects an amount exceeding the goal's current computed balance (`WithdrawalExceedsBalanceFailure`, FR-006), both idempotent on retry — in `test/features/savings/domain/usecases/log_contribution_withdrawal_test.dart`.
- [ ] T025 [P] [US2] Unit test `EditContribution`/`DeleteContribution`: recalculation correctness after edit/delete; an edited withdrawal is re-validated against the goal's balance excluding its own prior value (data-model.md rule) — in `test/features/savings/domain/usecases/edit_delete_contribution_test.dart`.
- [ ] T026 [P] [US2] Unit test `GetGoalDetail`'s `GoalProgress`/`isAchieved` derivation: achieved when current >= target (FR-017), reverses automatically when a later edit/delete/withdrawal brings current back below target (FR-018, research.md Decision 6) — in `test/features/savings/domain/usecases/get_goal_detail_test.dart`.
- [ ] T027 [P] [US2] Repository test: `SavingsRepositoryImpl.logContribution`/`logWithdrawal`/`editContribution`/`deleteContribution` against an in-memory drift DB, including the withdrawal-balance-check query correctness — extend `test/features/savings/data/repositories/savings_repository_impl_test.dart` (T013).
- [ ] T028 [P] [US2] `bloc_test` for `GoalDetailCubit`/`ContributionFormCubit`: loads progress, applies contribution/withdrawal logging, edit/delete, recomputes live, duplicate-tap protection — in `test/features/savings/presentation/cubit/goal_detail_cubit_test.dart` and `contribution_form_cubit_test.dart`.

### Implementation for User Story 2

- [ ] T029 [US2] Implement `SavingsRepositoryImpl.logContribution`/`logWithdrawal`/`editContribution`/`deleteContribution`/`getGoalDetail` in `lib/features/savings/data/repositories/savings_repository_impl.dart`: `getGoalDetail` composes the goal row, its non-deleted contribution history, and `SavingsCalculator` to build `GoalProgress` (depends on T007, T017).
- [ ] T030 [P] [US2] Implement `lib/features/savings/domain/usecases/log_contribution.dart`, `log_withdrawal.dart`, `edit_contribution.dart`, `delete_contribution.dart`, `get_goal_detail.dart`, wrapping T029.
- [ ] T031 Annotate the US2 use cases with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T030).
- [ ] T032 [US2] Implement `lib/features/savings/presentation/cubit/goal_detail_cubit.dart` + state (loading/success/empty/error, constitution: complete UI states) and `contribution_form_cubit.dart` + state (log/edit contribution or withdrawal, fresh idempotency key per save, disabled-on-tap) (depends on T030, T031).
- [ ] T033 [P] [US2] Finalize `lib/features/savings/presentation/widgets/goal_progress_card.dart` (current/remaining/percentage/estimated-completion) and implement `achieved_goal_badge.dart` (distinct celebratory treatment, FR-017) and `contribution_list_tile.dart` (type-labeled history row, FR-008).
- [ ] T034 [US2] Implement `lib/features/savings/presentation/pages/goal_detail_page.dart` (progress card, achieved badge when applicable, contribution history list, log-contribution/log-withdrawal actions) and `contribution_form_page.dart` (amount, date, optional note, contribution/withdrawal toggle) (depends on T032, T033).
- [ ] T035 Register `/savings/:goalId`, `/savings/:goalId/log` routes in `lib/core/routing/app_router.dart` (depends on T034).

**Checkpoint**: User Stories 1-2 together deliver the MVP — goals can be created and accurately tracked from real logged progress.

---

## Phase 5: User Story 3 - Run "What If" Scenarios (Priority: P2)

**Goal**: Non-destructive what-if exploration for monthly contribution and target date, with an explicit apply action.

**Independent Test**: Run a what-if, confirm correct result and that the real goal is unchanged until applied.

### Tests for User Story 3 ⚠️

- [ ] T036 [P] [US3] Unit test `CalculateWhatIfMonthlyContribution`/`CalculateWhatIfCompletionDate`: correct results against the spec's worked examples, rejects a non-positive hypothetical contribution or a past hypothetical target date (`ValidationFailure`/`InvalidTargetDateFailure`, FR-016), returns a clear "already achieved" signal instead of a recalculation for an achieved goal (FR-016) — in `test/features/savings/domain/usecases/what_if_test.dart`.
- [ ] T037 [P] [US3] **Critical-path unit test** `ApplyWhatIfScenario`: updates the goal's real `monthlyContributionMinorUnits`/`targetDate` to the scenario's values; a preceding call to either `CalculateWhatIf*` use case with the same inputs is verified to have made zero repository writes (mock verification: `SavingsRepository` received no mutation calls) — in `test/features/savings/domain/usecases/apply_what_if_scenario_test.dart`. This is the primary automated evidence for SC-004's "provably unchanged unless explicitly applied."
- [ ] T038 [P] [US3] `bloc_test` for `WhatIfCubit`: explore-then-apply flow, explore-then-cancel leaves the goal unchanged (verified via a re-fetch), achieved-goal messaging — in `test/features/savings/presentation/cubit/what_if_cubit_test.dart`.

### Implementation for User Story 3

- [ ] T039 [US3] Implement `lib/features/savings/domain/usecases/calculate_what_if_monthly_contribution.dart` and `calculate_what_if_completion_date.dart`: call only `SavingsCalculator` (T007), never `SavingsRepository` (research.md Decision 1) — validate inputs (positive amount / future date) before calling the calculator, and short-circuit with a clear "already achieved" result if the goal's current `GoalProgress.isAchieved` is true (fetched read-only via `GetGoalDetail`).
- [ ] T040 [US3] Implement `SavingsRepositoryImpl.editSavingsGoal`'s reuse for `ApplyWhatIfScenario`'s actual write (no separate DAO method needed — applying a scenario is just an ordinary goal edit) and `lib/features/savings/domain/usecases/apply_what_if_scenario.dart` wrapping it (depends on T017, T029).
- [ ] T041 Annotate the US3 use cases with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T039, T040).
- [ ] T042 [US3] Implement `lib/features/savings/presentation/cubit/what_if_cubit.dart` + state: holds the hypothetical result as a clearly separate field from any real-goal state (constitution Principle IV note in plan.md), exposes an explicit "apply" action calling `ApplyWhatIfScenario`, exposes the achieved-goal "nothing to plan for" state (depends on T039-T041).
- [ ] T043 [P] [US3] Implement `lib/features/savings/presentation/widgets/what_if_result_card.dart`.
- [ ] T044 [US3] Implement `lib/features/savings/presentation/pages/what_if_calculator_page.dart`: two input modes (hypothetical monthly contribution / hypothetical target date), `WhatIfResultCard`, apply/cancel actions (depends on T042, T043).
- [ ] T045 Register `/savings/:goalId/what-if` route in `lib/core/routing/app_router.dart` and link to it from `goal_detail_page.dart` (depends on T034, T044).

**Checkpoint**: What-if exploration is safe, correct, and clearly non-destructive until applied.

---

## Phase 6: User Story 4 - Manage Multiple Concurrent Goals (Priority: P2)

**Goal**: Goals overview with combined total, archive/restore, delete-protection, empty state.

**Independent Test**: Create several goals, view overview totals, archive one, confirm delete-protection on a goal with history.

### Tests for User Story 4 ⚠️

- [ ] T046 [P] [US4] Unit test `GetSavingsOverview`: correct per-goal `GoalProgress` list and combined total currently saved across active goals, `includeArchived` toggling — in `test/features/savings/domain/usecases/get_savings_overview_test.dart`.
- [ ] T047 [P] [US4] Unit test `ArchiveSavingsGoal`/`RestoreSavingsGoal`: hides/restores from the active list, leaves history untouched, archived goal still accepts contribution edits (FR-020) — in `test/features/savings/domain/usecases/archive_restore_savings_goal_test.dart`.
- [ ] T048 [P] [US4] Unit test `DeleteSavingsGoal`: blocks permanent delete when any (including soft-deleted) `SavingsContribution` rows exist (`GoalHasHistoryFailure`, FR-021), succeeds for a zero-history goal — in `test/features/savings/domain/usecases/delete_savings_goal_test.dart`.
- [ ] T049 [P] [US4] `bloc_test` for `SavingsOverviewCubit`/`ArchivedGoalsCubit` — in `test/features/savings/presentation/cubit/savings_overview_cubit_test.dart` and `archived_goals_cubit_test.dart`.

### Implementation for User Story 4

- [ ] T050 [US4] Implement `SavingsRepositoryImpl.getSavingsOverview`/`archiveSavingsGoal`/`restoreSavingsGoal`/`deleteSavingsGoal` in `lib/features/savings/data/repositories/savings_repository_impl.dart` (depends on T017, T029).
- [ ] T051 [P] [US4] Implement `lib/features/savings/domain/usecases/get_savings_overview.dart`, `archive_savings_goal.dart`, `restore_savings_goal.dart`, `delete_savings_goal.dart`, wrapping T050.
- [ ] T052 Annotate the US4 use cases with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T051).
- [ ] T053 [US4] Implement `lib/features/savings/presentation/cubit/savings_overview_cubit.dart` and `archived_goals_cubit.dart` + states (depends on T051, T052).
- [ ] T054 [P] [US4] Implement `lib/features/savings/presentation/widgets/savings_overview_summary_card.dart`.
- [ ] T055 [US4] Implement `lib/features/savings/presentation/pages/savings_overview_page.dart` (goal cards, combined total, empty state per FR-023) and `archived_goals_page.dart` (mirrors 001's `ArchivedPeoplePage`/008's `ArchivedOccasionsPage` pattern) (depends on T053, T054).
- [ ] T056 Register `/savings`, `/savings/archived` routes in `lib/core/routing/app_router.dart`, and make `/savings` the feature's main navigation entry point (depends on T055).

**Checkpoint**: All four user stories complete — the full Savings Goals feature is usable end-to-end.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Localization, theming, performance, and end-to-end validation across the whole feature.

- [ ] T057 [P] Add all Savings-feature strings (goal form, type labels, contribution/withdrawal log, achieved-state celebration, what-if calculator, overview, empty states) to `lib/core/l10n/app_en.arb` and `app_ar.arb`; regenerate `AppLocalizations` (FR-025).
- [ ] T058 [P] RTL/LTR and theme pass: verify goal form/detail/overview/what-if/archived screens, the achieved badge, and progress indicators render correctly in Arabic RTL and English LTR, and in both light and dark mode (FR-025, SC-007).
- [ ] T059 [P] Performance check: seed a goal with 200 logged contributions and confirm `GetGoalDetail` renders in <1s; seed 50 goals and confirm the overview renders promptly (plan.md Performance Goals).
- [ ] T060 Write `integration_test/savings_flows_test.dart` covering: create goal (contribution-mode and target-date-mode, per US1); log contributions/withdrawals and verify recompute, withdrawal-exceeds-balance rejection, achieved-state transition and reversal (US2); what-if exploration + explicit apply, non-destructive-until-applied verification, achieved-goal messaging (US3); multi-goal overview, archive/restore, delete-protection (US4) — per quickstart.md's manual scenarios.
- [ ] T061 Run `fvm flutter analyze` and `fvm flutter format`, fix all warnings (no `// ignore` suppressions without a documented reason).
- [ ] T062 Run the full `fvm flutter test` suite and `fvm flutter test integration_test`; confirm all pass, with special attention to T008 (`SavingsCalculator`) and T037 (`ApplyWhatIfScenario`'s non-mutation guarantee).
- [ ] T063 Code-review pass against the constitution's Definition of Done checklist, with explicit verification that zero changes were made to any 001/007/008/009/010 table, entity, or calculation (FR-026) — grep the diff to confirm nothing outside `lib/features/savings/`, `lib/core/database/app_database.dart` (additive only), `lib/core/di/`, `lib/core/l10n/`, and `lib/core/routing/` was touched.

---

## Dependencies & Execution Order

- **Setup (Phase 1)** → **Foundational (Phase 2)**: strictly sequential; Foundational blocks every user story.
- **US1 (Phase 3)** depends only on Foundational.
- **US2 (Phase 4)** depends on US1 (a goal must exist to log against); together US1+US2 are the MVP.
- **US3 (Phase 5)** depends on US2 (a goal's current `GoalProgress`/`isAchieved` must be readable to short-circuit an achieved goal's what-if, and the goal-detail entry point must exist to reach the calculator from).
- **US4 (Phase 6)** depends on US1 (goals exist) and US2 (delete-protection needs contribution history to exist as a test case), and is otherwise independent of US3.
- **Polish (Phase 7)** depends on all prior phases.

## Parallel Execution Examples

- Within Foundational: T002-T006 (entities/value objects/failures) can run in parallel; T007-T008 (the calculator and its exhaustive tests) should be treated as a tight, careful unit before any use case depends on it, but can proceed in parallel with T002-T006.
- Within US1: T012-T014 (tests) can run in parallel before implementation.
- Within US2: T024-T028 (tests) can run in parallel; T030 (use cases) can run in parallel once T029 lands.
- Within US3: T036-T038 (tests) can run in parallel; T037's mock-verification approach should be reviewed carefully given its role as the structural proof of FR-015.

## Implementation Strategy

**MVP first**: Phases 1-4 (Setup, Foundational, US1, US2) deliver the minimum valuable release — goals can be planned and accurately tracked from real logged progress, with a fully correct, exhaustively-tested completion-estimate calculator underneath. Ship this before continuing.

**Incremental delivery**: US3 (what-if scenarios) is the feature's signature planning value and the next-highest-priority increment. US4 (multi-goal management) is valuable as soon as a user has more than one goal and can be delivered in either order relative to US3.
