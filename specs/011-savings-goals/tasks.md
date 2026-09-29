---

description: "Task list for Savings Goals (feature 011)"
---

# Tasks: Savings Goals

> **Status (2026-09-29): NOT STARTED.** Regenerated after `/speckit-analyze` re-baselined 011
> against `main` (local schema v10, Supabase migration 022). The earlier task list was ticked
> complete on the `011-savings-goals` branch (commit f28183d) without any code being written;
> every box below is intentionally unchecked. Adds sync (021), currency (018), the contribution
> audit trail, goal editing, and the integrations 012/013/014/017/020 already reserve for this
> feature.

**Input**: Design documents from `/specs/011-savings-goals/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included, consistent with 001/007/008/009/010's precedent (constitution Principle XVI). Each user story's tests are written before its implementation tasks (TDD ordering). `SavingsCalculator`'s pure-function tests (Foundational phase) are the single most exhaustively covered file in this feature, per its role as the sole source of truth for every completion/what-if figure.

**Organization**: Tasks are grouped by user story (spec.md priorities P1-P2) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Maps to spec.md user stories (US1-US4)
- File paths follow plan.md's Project Structure exactly

## Path Conventions

Single Flutter app, feature-first per constitution Principle II: `lib/core/`, `lib/features/savings/{data,domain,presentation}`; `test/` mirrors `lib/`; `integration_test/` for end-to-end flows; `supabase/migrations/` for the cloud schema.

---

## Phase 1: Setup

**Purpose**: Directory skeleton — no new package dependency (plan.md Technical Context).

- [X] T001 Create the directory skeleton: `lib/features/savings/{data/{datasources,models,repositories,sync,adapters},domain/{entities,repositories,services,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/features/savings/{domain/services,domain/usecases,data/repositories,data/sync,data/adapters,presentation/cubit}/`.

**Checkpoint**: Directories exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema, sync registration, entities, date helpers and the pure `SavingsCalculator` every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Define the `SavingsGoal` entity (`id`, `idempotencyKey`, `name`, `type?`, `currency`, `targetAmountMinorUnits`, `monthlyContributionMinorUnits?`, `targetDate?`, `isArchived`, `createdAt`, `updatedAt`, `deletedAt?`) in `lib/features/savings/domain/entities/savings_goal.dart`, per data-model.md.
- [X] T003 [P] Define the standard goal-`type` constant list (`emergencyFund`, `newCar`, `wedding`, `vacation`, `newPhone`, `homeFurniture`, `education`, `other`) in `lib/features/savings/domain/entities/savings_goal_type.dart`, plus a helper distinguishing a standard value from a plain custom-named goal (cosmetic only).
- [X] T004 [P] Define the `ContributionType` enum (`contribution`/`withdrawal`) and the `SavingsContribution` entity (`id`, `idempotencyKey`, `goalId`, `type`, `amountMinorUnits` (goal currency), `enteredAmountMinorUnits`, `enteredCurrency`, `date`, `note?`, `createdAt`, `editedAt?`, `deletedAt?`) in `lib/features/savings/domain/entities/savings_contribution.dart`.
- [X] T005 [P] Define the `SavingsContributionAudit` entity (`id`, `contributionId`, `changeType` `edited|deleted`, `previousValuesJson`, `changedAt`) in `lib/features/savings/domain/entities/savings_contribution_audit.dart` (FR-030, research.md Decision 10).
- [X] T006 [P] Define the `GoalProgress`, `EstimatedCompletion`, `WhatIfResult`, `GoalOverviewLine` and `SavingsOverview` value objects in `lib/features/savings/domain/entities/goal_progress.dart`, `what_if_result.dart` and `savings_overview.dart`, per data-model.md (`remainingMinorUnits`'s never-negative floor, `percentageProgress`'s 100% cap, `hasShortfall`/`shortfallMonths`, `isBlocked`/`missingRatesFor`/`isIncomplete`).
- [X] T007 [P] Add `GoalNotFoundFailure`, `WithdrawalExceedsBalanceFailure`, `GoalHasHistoryFailure`, `InvalidTargetDateFailure`, `GoalArchivedFailure` to `lib/features/savings/domain/entities/savings_failures.dart`, extending the core `Failure`; add their localized messages to `lib/core/l10n/failure_message.dart` (reuse 018's `RatesMissingFailure` as-is).
- [X] T008 [P] Add `wholeMonthsBetween(DateTime from, DateTime to)` and `addCalendarMonths(DateTime, int)` to `lib/core/date/` per research.md Decision 11, with unit tests in `test/core/date/` covering same-month, day-of-month-earlier (20th → 5th = one less), year rollover, and month-end clamping (Jan 31 + 1 → Feb 28/29).
- [X] T009 Define the pure `SavingsCalculator` interface and implementation (no DB/Flutter dependency, integer-only, never converts currency) in `lib/features/savings/domain/services/savings_calculator.dart`: `estimateFromMonthlyContribution` (FR-010, integer ceiling), `requiredContributionForTargetDate` (FR-011, `wholeMonthsBetween` floored at 1, ceiling to next minor unit), `whatIfMonthlyContribution`/`whatIfTargetDate` (FR-013/FR-014), and FR-012 shortfall detection with `shortfallMonths`, per `contracts/savings_repository.md` (depends on T006, T008).
- [X] T010 [P] **Exhaustive table-driven unit test** `SavingsCalculator` with **at least 20 cases** (SC-003): the spec's worked examples (100,000 / 5,000 → 20 months; 100,000 / 35,000 current / 5,000 → 13 months; +1,000 → 6,000 / 11 months; finish in 10 months → 6,500/month), remaining = 0, contribution larger than remaining → 1 month, target date within the current month → 1 month, day-of-month-earlier target, shortfall with correct `shortfallMonths`, non-whole-month rounding up, required-contribution rounding up to the next minor unit, a very long timeline (1 EGP/month vs 1,000,000), and a large-amount case at the money ceiling — in `test/features/savings/domain/services/savings_calculator_test.dart`. Release-blocking anchor for SC-003.
- [X] T011 Update `lib/core/database/app_database.dart`: add `SavingsGoals`, `SavingsContributions`, `SavingsContributionAudits` drift tables per data-model.md's Drift Schema Sketch (unique idempotency-key indexes, `idx_savings_contributions_goal_id`); bump `schemaVersion` **10 → 11** with an additive `onUpgrade` step and a migration test from v10. **Zero changes to any existing table.** Run `dart run build_runner build --delete-conflicting-outputs`.
- [X] T012 Register the three tables with sync (research.md Decision 8): add `savingsGoal('savings_goal', 0)`, `savingsContribution('savings_contribution', 1)`, `savingsContributionAudit('savings_contribution_audit', 2)` to `lib/core/sync/sync_entity_type.dart`; update the exhaustive switch in `test/core/sync/table_classification_guard_test.dart` and the `fromWire` test in `test/core/sync/sync_entity_type_test.dart` (which currently uses `'savings_goal'` as its unknown-value example — change it to another unknown value) (depends on T011).
- [X] T013 [P] Implement `SavingsGoalSyncMapper`, `SavingsContributionSyncMapper`, `SavingsContributionAuditSyncMapper` in `lib/features/savings/data/sync/`, mirroring `lib/features/budgets/data/sync/budget_sync_mapper.dart`; register them with the `SyncMapperRegistry`; round-trip unit tests in `test/features/savings/data/sync/` (depends on T012).
- [X] T014 [P] Write `supabase/migrations/<timestamp>_023_savings_goals_sync.sql`: `savings_goals`, `savings_contributions`, `savings_contribution_audits` with 022's sync columns, `(owner_id, id)` primary key, `unique (owner_id, idempotency_key)` on goals/contributions, length/positivity `check`s, `sync_stamp` trigger, owner-only RLS select/insert/update policies, `(owner_id, revision)` indexes; replace `sync_push`/`sync_pull`/`sync_delete_all` to include the three entity types. Never edit an applied migration. Load the `supabase` and `supabase-postgres-best-practices` skills first.
- [X] T015 Define the `SavingsRepository` abstract interface in `lib/features/savings/domain/repositories/savings_repository.dart` per `contracts/savings_repository.md` (all methods, including `watchGoalDetail`/`watchSavingsOverview` — implemented incrementally across US1-US4).
- [X] T016 [P] Register the new tables in shared infrastructure: `deleteAllUserData` in `lib/core/database/data_wipe.dart` deletes audits → contributions → goals (013; `test/core/database/data_wipe_test.dart` must pass); `DriftCurrencyUsageChecker` in `lib/features/currency/data/services/drift_currency_usage_checker.dart` gains `EXISTS` clauses for `savings_goals.currency_code` and `savings_contributions.entered_currency_code` (018, FR-028), updating its doc comment and test (depends on T011).

**Checkpoint**: Schema (local + cloud), sync registration, entities, and the fully-tested calculator exist; the guard/wipe/sync tests pass. User story implementation can now begin.

---

## Phase 3: User Story 1 - Create a Savings Goal (Priority: P1) 🎯 MVP (part 1 of 2)

**Goal**: Create a goal with a target, currency and, optionally, a starting amount, monthly contribution, and/or target date, with correct initial computed figures; edit it afterwards.

**Independent Test**: Create a goal, confirm correct remaining/estimated-completion; edit its target and confirm recalculation.

### Tests for User Story 1 ⚠️

- [X] T017 [P] [US1] Unit test `CreateSavingsGoal`: rejects `targetAmountMinorUnits <= 0` (FR-002), rejects a negative monthly contribution or starting amount, rejects a `targetDate` on/before today (`InvalidTargetDateFailure`, FR-003), defaults the currency to the primary currency, creates an initial `SavingsContribution` row when `startingAmountMinorUnits > 0` (research.md Decision 3), accepts creation with neither monthly contribution nor target date, idempotent on retry (FR-022) — in `test/features/savings/domain/usecases/create_savings_goal_test.dart`.
- [X] T018 [P] [US1] Unit test `EditSavingsGoal` (FR-029): same validation as create, currency cannot change, history untouched, derived figures recompute — in `test/features/savings/domain/usecases/edit_savings_goal_test.dart`.
- [X] T019 [P] [US1] Repository test against `NativeDatabase.memory()`: `createSavingsGoal`'s idempotency-key uniqueness, the starting-amount contribution in the same DB transaction, `editSavingsGoal`, and that each write enqueues exactly one outbox row per changed record — in `test/features/savings/data/repositories/savings_repository_impl_test.dart`.
- [X] T020 [P] [US1] `bloc_test` for `GoalFormCubit`: create (contribution-mode and target-date-mode), edit mode prefilled from an existing goal, validation rejections, duplicate-tap producing exactly one saved goal — in `test/features/savings/presentation/cubit/goal_form_cubit_test.dart`.
- [X] T021 [P] [US1] Widget test `GoalFormPage`: live estimate preview updates, validation messages, currency picker shown on create and hidden on edit, the "set a monthly contribution or target date to see an estimate" prompt (US1 AS-6) — in `test/widget/savings_goal_form_page_test.dart`.

### Implementation for User Story 1

- [X] T022 [US1] Implement `lib/features/savings/data/datasources/savings_dao.dart` (drift DAO): insert a goal (idempotency-guarded) optionally with its initial contribution row in one DB transaction, update a goal, insert/query contributions; every write enqueues its 021 outbox row in the same transaction, mirroring `BudgetsDao`.
- [X] T023 [P] [US1] Implement `lib/features/savings/data/models/savings_goal_mapper.dart`, `savings_contribution_mapper.dart`, `savings_contribution_audit_mapper.dart` (drift rows ↔ domain entities).
- [X] T024 [US1] Implement `SavingsRepositoryImpl.createSavingsGoal`/`editSavingsGoal` in `lib/features/savings/data/repositories/savings_repository_impl.dart` (depends on T015, T022, T023).
- [X] T025 [P] [US1] Implement `lib/features/savings/domain/usecases/create_savings_goal.dart` and `edit_savings_goal.dart`, wrapping T024.
- [X] T026 Annotate `SavingsRepositoryImpl`/`SavingsDao`, `SavingsCalculator`, the sync mappers and the US1 use cases with `@injectable`/`@LazySingleton(as: ...)`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T009, T013, T022-T025).
- [X] T027 [US1] Implement `lib/features/savings/presentation/cubit/goal_form_cubit.dart` + `goal_form_state.dart`: create and edit modes, fresh idempotency key on open, currency defaulting to the primary currency (create only), live estimate preview via `SavingsCalculator`, validation per FR-002/FR-003, Save disabled immediately on tap (FR-022) (depends on T009, T025).
- [X] T028 [P] [US1] Implement `lib/features/savings/presentation/widgets/goal_progress_card.dart` (initial create/preview rendering — full progress rendering completed in US2).
- [X] T029 [US1] Implement `lib/features/savings/presentation/pages/goal_form_page.dart` on the 020 adaptive app bar: name, type picker (T003), currency picker (create only), target amount, optional starting amount, optional monthly contribution, optional target date, live estimate preview, Save wired to `GoalFormCubit` (depends on T027, T028).
- [X] T030 Register `/savings/new` and `/savings/:goalId/edit` in the People branch of `lib/core/routing/app_router.dart`, declaring static `/savings/...` paths above `/savings/:goalId` (research.md Decision 12) (depends on T029).

**Checkpoint**: A goal can be created and edited with correct computed figures, and syncs.

---

## Phase 4: User Story 2 - Log Contributions and Track Progress (Priority: P1) 🎯 MVP (part 2 of 2)

**Goal**: Log contributions/withdrawals (any currency, converted at log time), edit/delete them with an audit trail, see progress recompute live, achieved-state transition.

**Independent Test**: Log several contributions (one in a foreign currency) and a withdrawal, edit and delete one; confirm all figures recalculate and audit rows exist.

### Tests for User Story 2 ⚠️

- [X] T031 [P] [US2] Unit test `LogContribution`/`LogWithdrawal`: rejects amount <= 0 (FR-007), `LogWithdrawal` rejects an amount exceeding the current balance (`WithdrawalExceedsBalanceFailure`, FR-006), rejects a new entry on an archived goal (`GoalArchivedFailure`, FR-020), converts a foreign-currency amount at the current rate and stores both figures (FR-028), returns `RatesMissingFailure` and writes nothing when the rate is missing, idempotent on retry — in `test/features/savings/domain/usecases/log_contribution_withdrawal_test.dart`.
- [X] T032 [P] [US2] Unit test `EditContribution`/`DeleteContribution`: recalculation after edit/delete; an edited withdrawal re-validated against the balance excluding its own prior value; deleting a contribution that would leave the balance negative is rejected; a foreign-currency edit re-converts at the current rate; each edit/delete writes exactly one audit row with the prior values (FR-030, SC-008); allowed on an archived goal — in `test/features/savings/domain/usecases/edit_delete_contribution_test.dart`.
- [X] T033 [P] [US2] Unit test `GetGoalDetail`'s `GoalProgress`/`isAchieved` derivation: achieved when current >= target (FR-017), reverses automatically when an edit/delete/withdrawal brings current below target (FR-018), history ordered by date then `createdAt` (FR-008) — in `test/features/savings/domain/usecases/get_goal_detail_test.dart`.
- [X] T034 [P] [US2] Repository test: `logContribution`/`logWithdrawal`/`editContribution`/`deleteContribution` against an in-memory drift DB, including the withdrawal-balance query, the audit row and outbox row written in the same transaction as the change, and an **SC-002 scenario of at least 50 entries** (contributions, withdrawals, edits, deletes and one converted foreign-currency entry) asserting current = Σcontributions − Σwithdrawals exactly — extend `test/features/savings/data/repositories/savings_repository_impl_test.dart` (T019).
- [X] T035 [P] [US2] `bloc_test` for `GoalDetailCubit`/`ContributionFormCubit`: loads and live-updates progress (including a change arriving via `watchGoalDetail`), log/edit/delete, missing-rate error state, archived-goal state, duplicate-tap protection — in `test/features/savings/presentation/cubit/goal_detail_cubit_test.dart` and `contribution_form_cubit_test.dart`.
- [X] T036 [P] [US2] Widget tests: `GoalDetailPage` achieved state (celebratory, not warning vocabulary), shortfall message ("N months after your target date", FR-012), no-estimate prompt, history rows showing entered + converted amounts; `ContributionFormPage` currency picker and missing-rate message — in `test/widget/savings_goal_detail_page_test.dart` and `test/widget/savings_contribution_form_page_test.dart`.

### Implementation for User Story 2

- [X] T037 [US2] Implement `SavingsRepositoryImpl.logContribution`/`logWithdrawal`/`editContribution`/`deleteContribution`/`getGoalDetail`/`watchGoalDetail` in `lib/features/savings/data/repositories/savings_repository_impl.dart`: conversion through 018's `CurrencyConverter` with the current `ConversionContext`; audit + outbox rows in the same transaction as each edit/delete; `getGoalDetail` composes the goal, its non-deleted history and `SavingsCalculator` into `GoalProgress`; `watchGoalDetail` re-emits on goal/contribution/rate changes (depends on T009, T024).
- [X] T038 [P] [US2] Implement `lib/features/savings/domain/usecases/log_contribution.dart`, `log_withdrawal.dart`, `edit_contribution.dart`, `delete_contribution.dart`, `get_goal_detail.dart`, `watch_goal_detail.dart`, wrapping T037.
- [X] T039 Annotate the US2 use cases with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T038).
- [X] T040 [US2] Implement `lib/features/savings/presentation/cubit/goal_detail_cubit.dart` + state (loading/success/empty/error, subscribed to `WatchGoalDetail`) and `contribution_form_cubit.dart` + state (log/edit contribution or withdrawal, entered currency defaulting to the goal's, fresh idempotency key per save, disabled-on-tap) (depends on T038, T039).
- [X] T041 [P] [US2] Finalize `lib/features/savings/presentation/widgets/goal_progress_card.dart` (current/remaining/percentage/estimated completion, **plus the FR-012 shortfall line** and the no-estimate prompt), implement `achieved_goal_badge.dart` (celebratory, FR-017) and `contribution_list_tile.dart` (type-labeled row showing entered amount/currency and, when different, the converted amount — FR-008/FR-028).
- [X] T042 [US2] Implement `lib/features/savings/presentation/pages/goal_detail_page.dart` (progress card, achieved badge, history list with lazy rendering, log-contribution/log-withdrawal actions hidden with an explanation when archived, edit-goal action) and `contribution_form_page.dart` (amount, currency, date, optional note, contribution/withdrawal toggle), both on the 020 adaptive app bar with confirmations via `showAppModalSheet`/`AppConfirmDialog` (depends on T040, T041).
- [X] T043 Register `/savings/:goalId` and `/savings/:goalId/log` in the People branch of `lib/core/routing/app_router.dart` (`/savings/:goalId` is already 017's deep-link target in `notification_tap_router.dart`) (depends on T042).

**Checkpoint**: User Stories 1-2 together deliver the MVP — goals can be created and accurately tracked from real logged progress, in any currency, with an audit trail, synced.

---

## Phase 5: User Story 3 - Run "What If" Scenarios (Priority: P2)

**Goal**: Non-destructive what-if exploration for monthly contribution and target date, with an explicit apply action.

**Independent Test**: Run a what-if, confirm correct result and that the real goal is unchanged until applied.

### Tests for User Story 3 ⚠️

- [X] T044 [P] [US3] Unit test `CalculateWhatIfMonthlyContribution`/`CalculateWhatIfCompletionDate`: correct results against the spec's worked examples, rejects a non-positive hypothetical contribution or a past hypothetical target date (`ValidationFailure`/`InvalidTargetDateFailure`, FR-016), returns a clear "already achieved" signal for an achieved goal (FR-016) — in `test/features/savings/domain/usecases/what_if_test.dart`.
- [X] T045 [P] [US3] **Critical-path unit test** `ApplyWhatIfScenario`: updates the goal's real `monthlyContributionMinorUnits`/`targetDate` to the scenario's values; a preceding call to either `CalculateWhatIf*` use case with the same inputs is verified to have made zero repository writes (mock verification) — in `test/features/savings/domain/usecases/apply_what_if_scenario_test.dart`. Primary automated evidence for SC-004.
- [X] T046 [P] [US3] `bloc_test` for `WhatIfCubit`: explore-then-apply, explore-then-cancel leaves the goal unchanged (verified via re-fetch), achieved-goal messaging — in `test/features/savings/presentation/cubit/what_if_cubit_test.dart`.
- [X] T047 [P] [US3] Widget test `WhatIfCalculatorPage`: both input modes, validation messages, apply/cancel, achieved-goal "nothing left to plan" state — in `test/widget/savings_what_if_calculator_page_test.dart`.

### Implementation for User Story 3

- [X] T048 [US3] Implement `lib/features/savings/domain/usecases/calculate_what_if_monthly_contribution.dart` and `calculate_what_if_completion_date.dart`: call only `SavingsCalculator`, never `SavingsRepository` — validate inputs before calling the calculator, and short-circuit with a clear "already achieved" result when the goal's `GoalProgress.isAchieved` (read via `GetGoalDetail`).
- [X] T049 [US3] Implement `lib/features/savings/domain/usecases/apply_what_if_scenario.dart` reusing `SavingsRepository.editSavingsGoal` (T024) — applying a scenario is an ordinary goal edit, not a new DAO path.
- [X] T050 Annotate the US3 use cases with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T048, T049).
- [X] T051 [US3] Implement `lib/features/savings/presentation/cubit/what_if_cubit.dart` + state: hypothetical result held as a clearly separate field from real-goal state, explicit "apply" calling `ApplyWhatIfScenario`, achieved-goal "nothing to plan for" state (depends on T048-T050).
- [X] T052 [P] [US3] Implement `lib/features/savings/presentation/widgets/what_if_result_card.dart`.
- [X] T053 [US3] Implement `lib/features/savings/presentation/pages/what_if_calculator_page.dart` on the 020 adaptive app bar: two input modes, `WhatIfResultCard`, apply/cancel (depends on T051, T052).
- [X] T054 Register `/savings/:goalId/what-if` in `lib/core/routing/app_router.dart` and link to it from `goal_detail_page.dart` (depends on T042, T053).

**Checkpoint**: What-if exploration is safe, correct, and clearly non-destructive until applied.

---

## Phase 6: User Story 4 - Manage Multiple Concurrent Goals (Priority: P2)

**Goal**: Goals overview with a primary-currency combined total (missing-rate aware), archive/restore, delete-protection, empty state.

**Independent Test**: Create several goals in two currencies, view overview totals with and without the rate, archive one, confirm delete-protection on a goal with history.

### Tests for User Story 4 ⚠️

- [X] T055 [P] [US4] Unit test `GetSavingsOverview`: per-goal `GoalProgress` in each goal's own currency, combined total converted into the primary currency, a goal needing a missing rate listed as blocked and excluded with `isIncomplete` and `missingRatesFor` set (FR-019), `includeArchived` toggling — in `test/features/savings/domain/usecases/get_savings_overview_test.dart`.
- [X] T056 [P] [US4] Unit test `ArchiveSavingsGoal`/`RestoreSavingsGoal`: hides/restores from the active list, history untouched, archived goal accepts edits/deletes of existing entries but rejects new ones (FR-020) — in `test/features/savings/domain/usecases/archive_restore_savings_goal_test.dart`.
- [X] T057 [P] [US4] Unit test `DeleteSavingsGoal`: blocked when any (including soft-deleted) contribution row exists (`GoalHasHistoryFailure`, FR-021); a zero-history goal is tombstoned (`deletedAt`) and enqueued for sync — in `test/features/savings/domain/usecases/delete_savings_goal_test.dart`.
- [X] T058 [P] [US4] `bloc_test` for `SavingsOverviewCubit`/`ArchivedGoalsCubit` (including live updates via `watchSavingsOverview` and the incomplete-total state) — in `test/features/savings/presentation/cubit/savings_overview_cubit_test.dart` and `archived_goals_cubit_test.dart`.
- [X] T059 [P] [US4] Widget test `SavingsOverviewPage`: empty state with a create-first-goal action (FR-023), incomplete-total message naming the missing rate, delete-blocked → offer-archive dialog — in `test/widget/savings_overview_page_test.dart`.

### Implementation for User Story 4

- [X] T060 [US4] Implement `SavingsRepositoryImpl.getSavingsOverview`/`watchSavingsOverview`/`archiveSavingsGoal`/`restoreSavingsGoal`/`deleteSavingsGoal` in `lib/features/savings/data/repositories/savings_repository_impl.dart`; the overview converts through `CurrencyConverter` with missing-rate blocking shaped like 010's `UnbudgetedCategorySpend` (depends on T024, T037).
- [X] T061 [P] [US4] Implement `lib/features/savings/domain/usecases/get_savings_overview.dart`, `watch_savings_overview.dart`, `archive_savings_goal.dart`, `restore_savings_goal.dart`, `delete_savings_goal.dart`, wrapping T060.
- [X] T062 Annotate the US4 use cases with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T061).
- [X] T063 [US4] Implement `lib/features/savings/presentation/cubit/savings_overview_cubit.dart` and `archived_goals_cubit.dart` + states (depends on T061, T062).
- [X] T064 [P] [US4] Implement `lib/features/savings/presentation/widgets/savings_overview_summary_card.dart` (primary-currency total, incomplete marker naming missing rates).
- [X] T065 [US4] Implement `lib/features/savings/presentation/pages/savings_overview_page.dart` (goal cards, combined total, empty state per FR-023) and `archived_goals_page.dart` (mirrors `ArchivedOccasionsPage`), both on the 020 adaptive app bar (depends on T063, T064).
- [X] T066 Register `/savings` and `/savings/archived` in the People branch of `lib/core/routing/app_router.dart` (static paths above `/savings/:goalId`), with a route-matching test that `/savings/new` and `/savings/archived` never resolve to the goal-detail page (depends on T065).

**Checkpoint**: All four user stories complete — the full Savings Goals feature is usable end-to-end.

---

## Phase 7: Integrations (FR-031, research.md Decisions 12-13)

**Purpose**: Connect the placeholders other features already reserve for 011. Each is read-only through this feature's use cases.

- [X] T067 [P] 017: implement `lib/features/savings/data/adapters/savings_repository_insights_source.dart` (`implements SavingsInsightsSource`: `activeGoals()` maps `GoalProgress`/`EstimatedCompletion` to `SavingsGoalSnapshot`; `goalExists()`), replace `UnavailableSavingsInsightsSource` in DI and delete it; unit test in `test/features/savings/data/adapters/`; confirm `evaluate_savings_goal_notifications_test.dart` and the notification-tap tests still pass.
- [X] T068 [P] 014: add `getSavingsGoalStatus` (wraps `GetGoalDetail`/`GetSavingsOverview`) and `getSavingsProjection` (wraps `CalculateWhatIfMonthlyContribution`) to `lib/features/ai_assistant/domain/tools/tool_catalog.dart` and its dispatcher, removing the "deferred until 011" comment; tool tests assert the stated figure equals the use case's figure and `foundData = false` when no goal exists.
- [X] T069 [P] 012: add a Savings card to `lib/features/dashboard/presentation/pages/home_page.dart` (opens `/savings` via `_openThenRefresh`, like the Budgets card) and replace `UpcomingPlaceholderCard` with active goals that have a target date when any exist (keeping the honest empty state otherwise); update the dashboard widget tests.

**Checkpoint**: Savings is visible from Home, feeds 017 check-ins and answers 014 assistant questions.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Localization, theming, performance, and end-to-end validation across the whole feature.

- [X] T070 [P] Add all Savings strings (goal form, type labels, currency labels, contribution/withdrawal log, missing-rate and archived messages, achieved celebration, shortfall line, what-if calculator, overview, incomplete total, empty states, failures) to `lib/core/l10n/app_en.arb` and `app_ar.arb`; regenerate `AppLocalizations` (FR-025).
- [X] T071 [P] RTL/LTR, theme and Liquid Glass pass: every savings screen, the achieved badge and progress indicators in Arabic RTL and English LTR, light and dark, glass on and off (FR-025, SC-007).
- [X] T072 [P] Performance check: a goal with 200 contributions renders `GoalDetailPage` in <1s; 50 goals render the overview promptly (plan.md Performance Goals).
- [X] T073 Write `integration_test/savings_flows_test.dart` covering quickstart.md scenarios 1-6: create (contribution-mode and target-date-mode) and edit (US1); log/withdraw/edit/delete with recompute, withdrawal-exceeds-balance rejection, foreign-currency conversion and missing-rate block, achieved transition and reversal (US2); what-if explore + explicit apply (US3); multi-currency overview with incomplete total, archive/restore, delete-protection (US4).
- [ ] T074 Apply `023_savings_goals_sync` to the Supabase project and run quickstart.md scenario 7 (two-device sync, audit rows, delete-all-my-data) and scenario 8 (integrations).
- [X] T075 Run `fvm flutter analyze` and `fvm dart format`, fix all warnings (no `// ignore` without a documented reason).
- [X] T076 Run the full `fvm flutter test` suite and `fvm flutter test integration_test`; confirm all pass, with special attention to T010 (`SavingsCalculator`), T045 (`ApplyWhatIfScenario` non-mutation), T034 (SC-002), and the sync guard / data-wipe tests.
- [X] T077 Code-review pass against the constitution's Definition of Done, verifying zero changes to any 001/007/008/009/010 table, entity or calculation (FR-026): grep the diff to confirm nothing outside `lib/features/savings/`, `lib/core/{database,sync,date,di,l10n,routing}/`, `supabase/migrations/`, and the integration touch points in T016/T067-T069 was modified.

---

## Dependencies & Execution Order

- **Setup (Phase 1)** → **Foundational (Phase 2)**: strictly sequential; Foundational blocks every user story. Within it, T011 (schema) precedes T012-T014/T016 (sync + shared registration).
- **US1 (Phase 3)** depends only on Foundational.
- **US2 (Phase 4)** depends on US1 (a goal must exist to log against); together US1+US2 are the MVP.
- **US3 (Phase 5)** depends on US2 (goal detail/`isAchieved` must be readable, and the goal-detail entry point must exist).
- **US4 (Phase 6)** depends on US1 and US2, and is otherwise independent of US3.
- **Integrations (Phase 7)** depend on US2 (T067, T069) and US3 (T068's projection tool); T069's Savings card also needs T066.
- **Polish (Phase 8)** depends on all prior phases.

## Parallel Execution Examples

- Within Foundational: T002-T008 can run in parallel; T009-T010 (calculator and its tests) are a tight unit once T006/T008 land; T013, T014 and T016 run in parallel after T011/T012.
- Within each story: all test tasks marked [P] can run in parallel before implementation.
- Integrations: T067, T068, T069 are independent of each other.

## Implementation Strategy

**MVP first**: Phases 1-4 (Setup, Foundational, US1, US2) deliver the minimum valuable release — goals can be planned, edited and accurately tracked from real logged progress, in any currency, audited and synced. Ship this before continuing.

**Incremental delivery**: US3 (what-if) is the next-highest-priority increment. US4 (multi-goal management) can be delivered in either order relative to US3. Phase 7 should follow immediately after US3/US4 so the rest of the app stops showing savings placeholders.
