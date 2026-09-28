---

description: "Task list for Household Budgets (feature 010)"
---

# Tasks: Household Budgets

**Input**: Design documents from `/specs/010-household-budgets/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included, consistent with 001/007/008/009's precedent (constitution Principle XVI). Each user story's tests are written before its implementation tasks (TDD ordering).

**Organization**: Tasks are grouped by user story (spec.md priorities P1-P3) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Maps to spec.md user stories (US1-US5)
- File paths follow plan.md's Project Structure exactly

## Path Conventions

Single Flutter app, feature-first per constitution Principle II: `lib/core/`, `lib/features/budgets/{data,domain,presentation}`; this feature adds zero code to `lib/features/finance/` (007), depending only on its existing public Domain interfaces; `test/` mirrors `lib/`; `integration_test/` for end-to-end flows.

---

## Phase 1: Setup

**Purpose**: Add the one new dependency and directory skeleton this feature needs.

- [X] T001 Add `fl_chart` to `pubspec.yaml` dependencies, pinned to its latest stable version compatible with Flutter 3.47.0; run `fvm flutter pub get` to confirm resolution (research.md Decision 4).
- [X] T002 [P] Create the directory skeleton: `lib/features/budgets/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/features/budgets/{domain/usecases,data/repositories,presentation/cubit}/`.

**Checkpoint**: Dependencies resolve, directories exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema/entity changes and the 007-repository composition every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Define the `Budget` entity (`id`, `idempotencyKey`, `month`, `expectedIncomeMinorUnits?`, `createdAt`, `updatedAt`, `deletedAt?`) in `lib/features/budgets/domain/entities/budget.dart`, per data-model.md.
- [X] T004 [P] Define the `BudgetCategoryAllocation` entity (`id`, `budgetId`, `categoryId`, `plannedAmountMinorUnits`, `createdAt`, `updatedAt`) in `lib/features/budgets/domain/entities/budget_category_allocation.dart`, per data-model.md.
- [X] T005 [P] Define the `BudgetCategoryStatus` enum (`onTrack`/`nearFull`/`overBudget`) and the `BudgetCategoryLine` value object (per data-model.md's field table, including the `percentageUsed` null-when-zero-planned rule and the "any spend against a zero-planned allocation is immediately overBudget" rule) in `lib/features/budgets/domain/entities/budget_category_line.dart`.
- [X] T006 [P] Define the `BudgetSummary` value object (`totalPlannedMinorUnits`, `totalActualMinorUnits`, `totalRemainingMinorUnits`, `overallPercentageUsed?`, `isOverBudgetOverall`, `categoryBreakdown`, `unbudgetedSpending`) and `UnbudgetedCategorySpend`/`BudgetMonthDetail` in `lib/features/budgets/domain/entities/budget_summary.dart`, per data-model.md.
- [X] T007 [P] Define the `BudgetTrendPoint` value object (`month`, `plannedMinorUnits`, `actualMinorUnits`) in `lib/features/budgets/domain/entities/budget_trend_point.dart`, per data-model.md.
- [X] T008 [P] Add `BudgetAlreadyExistsForMonthFailure`/`BudgetNotFoundFailure` to `lib/features/budgets/domain/entities/budget_failures.dart`, extending the core `Failure`.
- [X] T009 Update `lib/core/database/app_database.dart`: add `Budgets` and `BudgetCategoryAllocations` drift tables per data-model.md's Drift Schema Sketch (`UNIQUE INDEX idx_budgets_idempotency_key`, `UNIQUE INDEX idx_budgets_month ... WHERE deleted_at IS NULL`, `UNIQUE INDEX idx_budget_allocations_budget_category`, `INDEX idx_budget_allocations_budget_id`); bump `schemaVersion` by 1 with the additive `onUpgrade` step. **Zero changes to any existing table** (data-model.md's explicit note). Run `dart run build_runner build --delete-conflicting-outputs`.
- [X] T010 Define the `BudgetsRepository` abstract interface in `lib/features/budgets/domain/repositories/budgets_repository.dart` per `contracts/budgets_repository.md` (all method signatures — implemented incrementally across US1-US5); constructor-documents its dependency on 007's `FinanceRepository`/`CategoryRepository` interfaces (research.md Decision 1).
- [X] T011 [P] Confirm 007's `CategoryRepository.getCategories(type: expense)` and `FinanceRepository.getCategoryBreakdown(period)` are sufficient for this feature's needs (research.md Decision 2's "reuse, no 007 change" default); if a gap is found during implementation, add the additive `FinanceRepository.getCategoryTotalForPeriod` method per research.md Decision 2's documented fallback, in `lib/features/finance/domain/repositories/finance_repository.dart` and its `*Impl`, with its own unit test.
- [X] T012 [P] Register `lib/core/di/injection.dart` scanning confirmation for `lib/features/budgets/` (DI annotations added incrementally per task below).

**Checkpoint**: Schema and entities exist; the dependency on 007 is confirmed. User story implementation can now begin.

---

## Phase 3: User Story 1 - Create a Monthly Budget (Priority: P1) 🎯 MVP (part 1 of 2)

**Goal**: Create a budget for a month and allocate planned amounts to expense categories.

**Independent Test**: Create a budget, allocate planned amounts to several categories, confirm retrievable with correct amounts.

### Tests for User Story 1 ⚠️

- [X] T013 [P] [US1] Unit test `CreateBudget`: rejects a second budget for a month that already has one (`BudgetAlreadyExistsForMonthFailure`), a retried call with the same `idempotencyKey` returns the existing budget (FR-017) — in `test/features/budgets/domain/usecases/create_budget_test.dart`.
- [X] T014 [P] [US1] Unit test `AddBudgetCategoryAllocation`: rejects a negative `plannedAmountMinorUnits` (FR-002, zero accepted), rejects a duplicate `(budgetId, categoryId)` allocation, rejects a `categoryId` whose `Category.type != expense` — in `test/features/budgets/domain/usecases/add_budget_category_allocation_test.dart`.
- [X] T015 [P] [US1] Unit test `GetBudgetForMonth`'s "exceeds income" indication: `BudgetSummary.totalPlannedMinorUnits > Budget.expectedIncomeMinorUnits` surfaces correctly without blocking (FR-004) — in `test/features/budgets/domain/usecases/get_budget_for_month_test.dart`.
- [X] T016 [P] [US1] Repository test against an in-memory `NativeDatabase.memory()`, with a real (in-memory-backed) 007 `FinanceRepository`/`CategoryRepository`: `BudgetsRepositoryImpl.createBudget`/`addBudgetCategoryAllocation` idempotency and duplicate-month/duplicate-allocation constraints — in `test/features/budgets/data/repositories/budgets_repository_impl_test.dart`.
- [X] T017 [P] [US1] `bloc_test` for `BudgetFormCubit`: happy-path create + allocate, negative-amount rejection, duplicate-tap producing exactly one saved budget/allocation — in `test/features/budgets/presentation/cubit/budget_form_cubit_test.dart`.

### Implementation for User Story 1

- [X] T018 [US1] Implement `lib/features/budgets/data/datasources/budgets_dao.dart` (drift DAO): insert a budget guarded by the `idempotency_key` and `month` unique indexes (on conflict, return the existing row or a duplicate-month signal); insert/update/delete allocations guarded by the `(budget_id, category_id)` unique index; query budget + allocations by month/id.
- [X] T019 [P] [US1] Implement `lib/features/budgets/data/models/budget_mapper.dart` and `budget_category_allocation_mapper.dart`: map between drift rows and domain entities (T003, T004).
- [X] T020 [US1] Implement `BudgetsRepositoryImpl.createBudget`/`addBudgetCategoryAllocation`/`getBudgetForMonth` in `lib/features/budgets/data/repositories/budgets_repository_impl.dart`: `getBudgetForMonth` composes `BudgetsDao` allocations with 007's `CategoryRepository`/`FinanceRepository` (per T011's resolved approach) to build `BudgetSummary`/`BudgetCategoryLine`/unbudgeted list; validates `categoryId`'s type is `expense` before allocating (depends on T010, T018, T019).
- [X] T021 [P] [US1] Implement `lib/features/budgets/domain/usecases/create_budget.dart`, `add_budget_category_allocation.dart`, `get_budget_for_month.dart`, wrapping the T020 repository methods.
- [X] T022 Annotate `BudgetsRepositoryImpl`/`BudgetsDao` and the US1 use cases with `@injectable`/`@LazySingleton(as: ...)`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T018-T021).
- [X] T023 [US1] Implement `lib/features/budgets/presentation/cubit/budget_form_cubit.dart` + `budget_form_state.dart`: generates a fresh idempotency key per save, validates non-negative planned amounts, computes/exposes the "exceeds income" indicator live as allocations are added, disables Save immediately on tap (FR-017) (depends on T021).
- [X] T024 [P] [US1] Implement `lib/features/budgets/presentation/widgets/budget_category_progress_row.dart` (initial create-mode rendering; full planned/actual/status rendering completed in US2/US3).
- [X] T025 [US1] Implement `lib/features/budgets/presentation/pages/budget_form_page.dart`: month display, optional expected-income field, category allocation picker (reuses 007's category picker, expense-type + non-archived filtered per FR-021), Save wired to `BudgetFormCubit` (depends on T023, T024).
- [X] T026 Register `/budgets/:month/new` route in `lib/core/routing/app_router.dart` and add a reachable entry point from the app's main navigation (depends on T025).

**Checkpoint**: A budget can be created with category allocations.

---

## Phase 4: User Story 2 - See Planned vs. Actual, Remaining, and Percentage Used (Priority: P1) 🎯 MVP (part 2 of 2)

**Goal**: View a budget's per-category and overall planned/actual/remaining/percentage, including unbudgeted spending, recalculating live.

**Independent Test**: Create a budget, record real expenses against budgeted categories, confirm displayed figures exactly match.

### Tests for User Story 2 ⚠️

- [X] T027 [P] [US2] Unit test `BudgetCategoryLine` computation: actual/remaining/percentage correctness against a fixture set of `FinanceEntry` rows spanning multiple categories and months (only the target month's non-deleted expense rows count) — extend `test/features/budgets/domain/usecases/get_budget_for_month_test.dart` (T015).
- [X] T028 [P] [US2] Unit test `BudgetSummary.unbudgetedSpending`: correctly identifies expense categories with month spend that are absent from the budget's allocations, with correct amounts, via 007's `getCategoryBreakdown` (FR-007) — extend the same test file.
- [X] T029 [P] [US2] Unit test confirming `GetBudgetForMonth` recomputes correctly after a 007 `FinanceEntry` is added/edited/deleted (call 007's `AddFinanceEntry`/`EditFinanceEntry`/`DeleteFinanceEntry` use cases against the same in-memory DB, then re-fetch) — extend `test/features/budgets/data/repositories/budgets_repository_impl_test.dart` (T016).
- [X] T030 [P] [US2] `bloc_test` for `BudgetMonthCubit`: loads and exposes `BudgetMonthDetail`, refreshes correctly, renders the FR-018 empty state when `getBudgetForMonth` returns a null budget — in `test/features/budgets/presentation/cubit/budget_month_cubit_test.dart`.

### Implementation for User Story 2

- [X] T031 [US2] Finalize `BudgetsRepositoryImpl.getBudgetForMonth`'s live-recompute correctness (no caching layer between it and 007's live data — every call re-derives from current `FinanceEntry`/`Category` state) (depends on T020).
- [X] T032 [US2] Implement `lib/features/budgets/presentation/cubit/budget_month_cubit.dart` + `budget_month_state.dart`: loads `GetBudgetForMonth`, exposes loading/success/empty/error states (constitution: complete UI states), supports pull-to-refresh/re-fetch after returning from an expense edit elsewhere in the app (depends on T021, T031).
- [X] T033 [P] [US2] Finalize `lib/features/budgets/presentation/widgets/budget_category_progress_row.dart`: planned/actual/remaining/percentage display for a `BudgetCategoryLine`.
- [X] T034 [P] [US2] Implement `lib/features/budgets/presentation/widgets/budget_overall_summary_card.dart` and `unbudgeted_spending_card.dart`.
- [X] T035 [US2] Implement `lib/features/budgets/presentation/pages/budget_month_page.dart`: renders `BudgetOverallSummaryCard`, the `BudgetCategoryProgressRow` list, `UnbudgetedSpendingCard`, and the FR-018 empty state with a create/copy-forward offer (copy action wired in US4) (depends on T032, T033, T034).
- [X] T036 Register `/budgets/:month` route in `lib/core/routing/app_router.dart` (depends on T035).

**Checkpoint**: User Stories 1-2 together deliver the MVP — budgets can be created and accurately tracked against real spending.

---

## Phase 5: User Story 3 - See Over-Budget Warnings (Priority: P2)

**Goal**: Clear on-track/near-full/over-budget visual states per category and overall.

**Independent Test**: Push a category's actual spend past planned; confirm a clear, distinct visual warning.

### Tests for User Story 3 ⚠️

- [X] T037 [P] [US3] Unit test `BudgetCategoryLine.status` derivation: `overBudget` when actual > planned (including any spend against a zero-planned allocation), `nearFull` at the 90% threshold, `onTrack` otherwise (FR-008, Assumptions) — extend `test/features/budgets/domain/usecases/get_budget_for_month_test.dart` (T027).
- [X] T038 [P] [US3] Unit test `BudgetSummary.isOverBudgetOverall` derivation (FR-009) — extend the same test file.
- [X] T039 [P] [US3] Widget test for `OverBudgetWarningBadge`: renders three visually distinct states using more than color alone (e.g. icon + label), per constitution Accessibility standard and FR-020 — in `test/widget/over_budget_warning_badge_test.dart`.

### Implementation for User Story 3

- [X] T040 [P] [US3] Implement `lib/features/budgets/presentation/widgets/over_budget_warning_badge.dart`: icon + label + color per status (never color alone) (depends on T005).
- [X] T041 [US3] Wire `OverBudgetWarningBadge` into `BudgetCategoryProgressRow` (T033) per-category and into `BudgetOverallSummaryCard` (T034) for the overall state (depends on T033, T034, T040).

**Checkpoint**: Warning states are clear, accessible, and correctly themed.

---

## Phase 6: User Story 4 - Carry a Budget Forward to a New Month (Priority: P2)

**Goal**: Copy a previous month's budget into a new month as an independent starting point.

**Independent Test**: Copy a budget to a new month; confirm identical categories/amounts, independently editable.

### Tests for User Story 4 ⚠️

- [X] T042 [P] [US4] Unit test `CopyBudgetToMonth`: produces a new `Budget` + matching `BudgetCategoryAllocation` rows for `targetMonth`, no ongoing link to the source (editing the copy doesn't touch the source, verified via a follow-up fetch), rejects a target month that already has a budget, idempotent on retry — in `test/features/budgets/domain/usecases/copy_budget_to_month_test.dart`.

### Implementation for User Story 4

- [X] T043 [US4] Implement `BudgetsRepositoryImpl.copyBudgetToMonth` in `lib/features/budgets/data/repositories/budgets_repository_impl.dart`: reads the source budget's allocations, inserts a new `Budget` + cloned `BudgetCategoryAllocation` rows for `targetMonth` in one DB transaction (depends on T020).
- [X] T044 [P] [US4] Implement `lib/features/budgets/domain/usecases/copy_budget_to_month.dart`, wrapping T043.
- [X] T045 Annotate the US4 use case with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T044).
- [X] T046 [US4] Implement `lib/features/budgets/presentation/cubit/copy_budget_cubit.dart` + state: offers the most recent prior month with a budget as the copy source, generates a fresh idempotency key, disables the action on tap (depends on T044, T045).
- [X] T047 [P] [US4] Implement a `MonthNavigator` widget (`lib/features/budgets/presentation/widgets/month_navigator.dart`) for moving between months on `budget_month_page.dart`, and wire the copy-forward action into that page's empty state (T035) (depends on T035, T046).

**Checkpoint**: Budgets can be carried forward, and users can navigate between months.

---

## Phase 7: User Story 5 - View Spending Trends Across Months (Priority: P3)

**Goal**: Planned-vs-actual trend view across recent months, per category or overall.

**Independent Test**: With 3+ months of budget/expense history, open the trend view and confirm correctness.

### Tests for User Story 5 ⚠️

- [X] T048 [P] [US5] Unit test `GetBudgetTrend`: correct `BudgetTrendPoint` list for `monthsBack` months, overall vs. per-category, correct "not enough history" signal when fewer than 2 months have an actual `Budget` row (data-model.md's rule) — in `test/features/budgets/domain/usecases/get_budget_trend_test.dart`.
- [X] T049 [P] [US5] `bloc_test` for `BudgetTrendCubit`: category-selection filtering, insufficient-history empty state — in `test/features/budgets/presentation/cubit/budget_trend_cubit_test.dart`.
- [X] T050 [P] [US5] Widget test for `BudgetTrendChart` (`fl_chart`-backed): renders grouped bars correctly for a fixture `List<BudgetTrendPoint>`, RTL-mirrored axis labels — in `test/widget/budget_trend_chart_test.dart`.

### Implementation for User Story 5

- [X] T051 [US5] Implement `BudgetsRepositoryImpl.getBudgetTrend` in `lib/features/budgets/data/repositories/budgets_repository_impl.dart`: iterates the last `monthsBack` months, calling `getBudgetForMonth`-equivalent logic per month (or a dedicated lighter query) plus 007's per-category total (depends on T020).
- [X] T052 [P] [US5] Implement `lib/features/budgets/domain/usecases/get_budget_trend.dart`, wrapping T051.
- [X] T053 Annotate the US5 use case with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T052).
- [X] T054 [US5] Implement `lib/features/budgets/presentation/cubit/budget_trend_cubit.dart` + state (depends on T052, T053).
- [X] T055 [P] [US5] Implement `lib/features/budgets/presentation/widgets/budget_trend_chart.dart` using `fl_chart`'s grouped bar chart, with localized month labels and RTL-aware layout (research.md Decision 4).
- [X] T056 [US5] Implement `lib/features/budgets/presentation/pages/budget_trend_page.dart`: category selector (optional), `BudgetTrendChart`, insufficient-history empty state (depends on T054, T055).
- [X] T057 Register `/budgets/trend` route in `lib/core/routing/app_router.dart` and link to it from `budget_month_page.dart` (depends on T056).

**Checkpoint**: All five user stories complete — the full Budgets feature is usable end-to-end.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Localization, theming, performance, and end-to-end validation across the whole feature.

- [X] T058 [P] Add all Budgets-feature strings (budget form, warning-state labels, month navigator, copy-forward, trend view, empty states) to `lib/core/l10n/app_en.arb` and `app_ar.arb`; regenerate `AppLocalizations` (FR-020).
- [X] T059 [P] RTL/LTR and theme pass: verify budget month/form/trend screens, progress rows, warning badges, and the `fl_chart` trend chart render correctly in Arabic RTL and English LTR, and in both light and dark mode (FR-020, SC-007).
- [X] T060 [P] Performance check: seed a month with 30 budgeted categories against 2,000 expense entries and confirm `GetBudgetForMonth` renders in <1s; seed 6 months of history and confirm the trend view renders in <1.5s (plan.md Performance Goals).
- [ ] T061 Write `integration_test/budgets_flows_test.dart` covering: create budget + allocate categories (US1); record/edit/delete expenses and verify actual/remaining/percentage + unbudgeted spending (US2); on-track/near-full/over-budget states, overall over-budget (US3); copy-forward to a new month + independent editing (US4); month navigation; trend view with 3+ months of data and an insufficient-history case (US5) — per quickstart.md's manual scenarios.
- [X] T062 Run `fvm flutter analyze` and `fvm flutter format`, fix all warnings (no `// ignore` suppressions without a documented reason).
- [ ] T063 Run the full `fvm flutter test` suite and `fvm flutter test integration_test`; confirm all pass.
- [X] T064 Code-review pass against the constitution's Definition of Done checklist, with explicit verification that zero changes were made to any 001/007 table, entity, or calculation (FR-022) — grep the diff for any edit inside `lib/features/finance/` or `lib/features/transactions/` and confirm none exist beyond what T011 may have added to `FinanceRepository` (additive method only).

---

## Dependencies & Execution Order

- **Setup (Phase 1)** → **Foundational (Phase 2)**: strictly sequential; Foundational blocks every user story.
- **US1 (Phase 3)** depends only on Foundational.
- **US2 (Phase 4)** depends on US1 (a budget must exist to view); together US1+US2 are the MVP.
- **US3 (Phase 5)** depends on US2 (the category-line/summary computation must exist to attach status to).
- **US4 (Phase 6)** depends on US1 (budgets exist to copy) and benefits from US2's month view existing (empty-state integration point), but its own repository/use-case work can start once US1 lands.
- **US5 (Phase 7)** depends on US2 (per-month computation logic is reused/extended for the trend) and is otherwise independent of US3/US4.
- **Polish (Phase 8)** depends on all prior phases.

## Parallel Execution Examples

- Within Foundational: T003-T008 (entities/value objects/failures) can run in parallel with each other once agreed; T011 (007 dependency confirmation) is independent of T003-T009 and can run in parallel.
- Within US1: T013-T017 (tests) can run in parallel before implementation; T021 (use cases) can run in parallel once T020 lands.
- Within US2: T027-T030 (tests) can run in parallel; T033/T034 (widgets) can run in parallel.

## Implementation Strategy

**MVP first**: Phases 1-4 (Setup, Foundational, US1, US2) deliver the minimum valuable release — a budget can be planned and accurately tracked against real spending, with unbudgeted spending never silently hidden. Ship this before continuing.

**Incremental delivery**: US3 (warning states) and US4 (copy-forward) are the next-highest-value increments, in either order — both address real recurring friction/usefulness. US5 (trend view) is the lowest-priority, safely deferrable increment, and has no meaningful data to show until a user has multiple months of history regardless of when it ships.
