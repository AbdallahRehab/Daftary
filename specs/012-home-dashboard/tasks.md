---

description: "Task list template for feature implementation"
---

# Tasks: Home Dashboard

**Input**: Design documents from `/specs/012-home-dashboard/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present). **Hard dependency**: feature 007 (Income & Expense Tracking) MUST be implemented first — `GetFinanceSummary`/`GetFinanceHistory` must exist and be registered in DI before Phase 2 of this feature can begin.

**Tests**: Included — plan.md's Testing section and constitution Principle XVI both require unit/Cubit/widget/integration tests; test tasks below are not optional.

**Organization**: Tasks are grouped by user story (spec.md P1-P2) to enable independent implementation and testing of each story. Unlike feature 007, this feature is partly a **relocation** of existing, working code (`OverviewPage`/`OverviewCubit`/`OverviewState`/`OverviewSummaryCard`) into the new `lib/features/dashboard/` module, not a from-scratch build — those tasks are explicitly marked "relocate" below per research.md Decision 1, and existing behavior/tests must be preserved, not rewritten.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

Single Flutter app, feature-first (plan.md Project Structure): `lib/features/dashboard/{domain,presentation}/`, `lib/core/config/`, mirrored under `test/features/dashboard/`, plus `integration_test/dashboard_flows_test.dart`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold the new `dashboard` feature module and the shared feature-flags file.

- [X] T001 Create the `dashboard` feature directory skeleton: `lib/features/dashboard/domain/{entities,usecases}/`, `lib/features/dashboard/presentation/{cubit,pages,widgets}/`, mirrored under `test/features/dashboard/{domain/usecases,presentation/cubit}/`, plus `test/widget/` (existing, shared) and `integration_test/` (existing, shared), per plan.md's Project Structure.
- [X] T002 [P] Create `lib/core/config/feature_flags.dart` (research.md Decision 4): `const bool kOccasionsFeatureEnabled = false;` and `const bool kOcrScanFeatureEnabled = false;`, each with a doc comment pointing at the future feature (Occasions §V2.1, OCR §V2.4) responsible for flipping it.
- [X] T003 [P] Reserve a contiguous ARB key block in `lib/core/l10n/app_en.arb`/`app_ar.arb` for this feature (`homeTitle`, financial-snapshot labels, quick-action labels, Insights/Upcoming placeholder copy, error/retry labels, combined-empty-state copy) — full string values filled in per-phase below (T041), this task only establishes the block exists so later phases don't collide.

**Checkpoint**: Directory layout matches plan.md; feature flags exist; no compile changes yet.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The coordination use case and shared state shape every user story depends on. **Requires feature 007 implemented** (its `GetFinanceSummary`/`GetFinanceHistory` use cases must already be registered in DI).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 [P] Define the `LoadStatus` enum (`loading` \| `success` \| `failure`, data-model.md "Value object: LoadStatus") in `lib/features/dashboard/presentation/cubit/load_status.dart` — the direct successor to the `OverviewStatus` enum being retired in this feature (research.md Decision 1), now used twice per `DashboardState`.
- [X] T005 [P] Define the `DashboardSnapshot` entity (data-model.md "Entity: DashboardSnapshot") in `lib/features/dashboard/domain/entities/dashboard_snapshot.dart`: `overview` (`Either<Failure, OverviewSummary>`), `finance` (`Either<Failure, FinanceSummary>`), `hasAnyFinanceEntry` (`bool`).
- [X] T006 Implement `lib/features/dashboard/domain/usecases/get_dashboard_snapshot.dart` per `contracts/get_dashboard_snapshot.md`: depends on `GetOverview` (from `transactions/domain/usecases/`), `GetFinanceSummary`, and `GetFinanceHistory` (both from `finance/domain/usecases/`, feature 007) — never a repository directly (research.md Decision 1). Runs all three calls concurrently via `Future.wait` (never sequentially — this is the "genuine parallel coordination" the contract requires for SC-001's 1-second target). Calls `GetFinanceHistory(limit: 1, offset: 0)` with no filter as the existence check (research.md Decision 3); a failure on that specific call degrades to "assume not empty" and never fails the whole call. Returns a populated `DashboardSnapshot` (depends on T005).
- [X] T007 Annotate `GetDashboardSnapshot` (T006) with `@injectable`, then re-run `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart` (depends on T006).
- [X] T008 [P] Unit test `GetDashboardSnapshot` with faked `GetOverview`/`GetFinanceSummary`/`GetFinanceHistory` use case dependencies (not faked repositories — per the contract, this use case depends on other use cases): confirms the three calls run concurrently (not serially — assert via a faked delay on each and measuring total elapsed time is roughly `max`, not `sum`), confirms a failure on one aggregate does not block or alter the other's returned `Either`, and confirms a failure on the `GetFinanceHistory(limit: 1)` existence check degrades to "assume not empty" rather than failing the whole call — in `test/features/dashboard/domain/usecases/get_dashboard_snapshot_test.dart`.

**Checkpoint**: The coordination use case exists and is verified — every user story phase below can now proceed.

---

## Phase 3: User Story 1 - See My Complete Financial Picture at a Glance (Priority: P1) 🎯 MVP

**Goal**: A single Home screen shows the existing owed-to-me/owed-by-me totals alongside this month's income/expense/net, loading together, with one combined first-run empty state when truly nothing has ever been recorded.

**Independent Test**: With existing people balances and finance entries already recorded, open the home screen and verify the owed-to-me/owed-by-me totals and the this-month income/expense/net figures are all visible together and match what the People and Finance sections show individually (spec.md US1 Independent Test).

### Tests for User Story 1 ⚠️ (write first, confirm they fail, then implement)

- [X] T009 [P] [US1] `bloc_test` for `DashboardCubit.load()`: both aggregates loading → both succeed → `DashboardState` carries `overviewSummary`/`financeSummary` populated and `isFullyLoading == false` (FR-001/FR-002) — in `test/features/dashboard/presentation/cubit/dashboard_cubit_test.dart`.
- [X] T010 [P] [US1] `bloc_test` for `DashboardCubit`'s combined-empty detection: zero people (per `OverviewSummary.peopleTheyOweYou.length + peopleYouOweThem.length + settledCount == 0`, research.md Decision 3) AND zero finance entries ever (`hasAnyFinanceEntry == false`) → `isCombinedEmpty == true`; either side having any data → `isCombinedEmpty == false` (FR-005, Edge Cases: a user with finance history from a prior month but zero balance activity must NOT see the combined empty state) — extends `dashboard_cubit_test.dart`.
- [X] T011 [P] [US1] `bloc_test` for `DashboardCubit.refresh()`: re-fetches both aggregates together (FR-012, pull-to-refresh) — extends `dashboard_cubit_test.dart`.
- [X] T012 [P] [US1] Widget test for `HomePage`'s Financial Snapshot section: renders owed-to-me/owed-by-me + this-month income/expense/net together as one cohesive section (not visually disconnected, spec US1 AC2), and renders the single combined empty state only when `isCombinedEmpty == true` — in `test/widget/home_page_test.dart`.

### Implementation for User Story 1

- [X] T013 [US1] Implement `lib/features/dashboard/presentation/cubit/dashboard_state.dart` per data-model.md "Entity: DashboardState" (`Equatable`, `copyWith()`): `overviewStatus`/`financeStatus` (`LoadStatus`, independent), `overviewSummary`/`financeSummary` (nullable), `overviewError`/`financeError` (nullable, localized-ready strings), `isCombinedEmpty` (bool, set once on first successful load of both), plus derived getters `isFullyLoading`, `isFullFailure`, `isAnyPartialError` (never separately stored, per constitution Principle IV) (depends on T004).
- [X] T014 [US1] Implement `lib/features/dashboard/presentation/cubit/dashboard_cubit.dart`: `load()` calls `GetDashboardSnapshot` (T006), unpacks its `overview`/`finance` `Either`s into `DashboardState`'s independent status/data/error fields, computes `isCombinedEmpty` from `hasAnyFinanceEntry` + the zero-people sum (research.md Decision 3); `refresh()` re-runs `load()`'s full logic (FR-012) (depends on T006, T013).
- [X] T015 Annotate `DashboardCubit` with `@injectable`, re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T014).
- [X] T016 [US1] Relocate `lib/features/transactions/presentation/widgets/overview_summary_card.dart` to `lib/features/dashboard/presentation/widgets/overview_summary_card.dart` unchanged (research.md Decision 1 — it renders the unchanged `OverviewSummary` entity from `transactions/domain/`; only its file location moves since its only remaining consumer becomes the new `HomePage`). Update its import in the relocated page (T018).
- [X] T017 [P] [US1] Implement `lib/features/dashboard/presentation/widgets/finance_snapshot_card.dart`: this-month total income, total expenses, and net, reusing `EgpFormatter` from `core/money` and design tokens from `core/design_system` — never a hardcoded color (constitution Principle XV), income/expense/net distinguished by icon+label as well as color (Accessibility standard).
- [X] T018 [US1] Relocate `lib/features/transactions/presentation/pages/overview_page.dart` to `lib/features/dashboard/presentation/pages/home_page.dart`, renamed `HomePage`, updating its `BlocProvider` to `DashboardCubit` (T014) and its `AppBar`/nav-facing title to `l10n.homeTitle`: render `OverviewSummaryCard` (T016, relocated) and `FinanceSnapshotCard` (T017) together inside one "Financial Snapshot" section (spec US1 AC2 — cohesive, not visually disconnected); preserve the existing `RefreshIndicator` → `DashboardCubit.refresh()` wiring, the existing loading `CircularProgressIndicator`, and the existing per-person list rendering (`_PersonSummaryRow`, kept from the original file) (depends on T013, T016, T017).
- [X] T019 [US1] Extend `home_page.dart` (T018) with the single combined first-run empty state (FR-005, SC-006): shown only when `DashboardState.isCombinedEmpty == true`, using `AppEmptyView` with copy explaining the app's purpose and a direct "get started" action (e.g. Add Person or Add Expense) — MUST NOT render alongside or instead of real data on either side when only one side is truly empty (Edge Cases) (depends on T018).
- [X] T020 Delete the now-relocated `lib/features/transactions/presentation/cubit/overview_cubit.dart` and `lib/features/transactions/presentation/cubit/overview_state.dart` (fully superseded by `DashboardCubit`/`DashboardState`, T013-T014); relocate `test/features/transactions/presentation/cubit/overview_cubit_test.dart`'s still-relevant assertions (balance-total rendering, "all settled" behavior) into `dashboard_cubit_test.dart` (T009-T011) rather than leaving a dangling test file against deleted classes (depends on T014, T009-T011).
- [X] T021 Update `/overview` route's builder in `lib/core/routing/app_router.dart` from `OverviewPage` to `HomePage` (T018); path string itself stays `/overview` unchanged (research.md Decision 5) (depends on T018).
- [X] T022 Update `lib/core/routing/main_shell.dart`'s corresponding `NavigationDestination` label from `l10n.overviewTitle` to the new `l10n.homeTitle` (T003); destination position (index 1, after People) and icon unchanged; People remains tab index 0 / default landing route (spec Assumption) (depends on T003, T021).

**Checkpoint**: User Story 1 is fully functional and independently testable — the combined financial snapshot renders correctly, including the single combined empty state.

---

## Phase 4: User Story 2 - Start a Common Action Without Hunting for It (Priority: P1)

**Goal**: Five one-tap quick actions (Add Expense, Add Income, Add Person, Add Money Received, Add Money Given) open their existing, unmodified forms directly from Home; two future slots (Add Occasion, Scan Paper) stay hidden/disabled behind the feature flags from T002.

**Independent Test**: From the home screen, tap each quick action and verify it opens the correct existing entry form pre-configured for that action (spec.md US2 Independent Test).

### Tests for User Story 2 ⚠️

- [X] T023 [P] [US2] Widget test for `QuickActionRow`/`QuickActionButton`: renders exactly the five active quick actions plus the two feature-flagged slots hidden (given `kOccasionsFeatureEnabled`/`kOcrScanFeatureEnabled` both `false`, T002); each active button carries a route/callback wired to the correct destination and pre-set parameter (e.g. Add Expense → finance entry form with `type=expense`) — in `test/widget/quick_action_row_test.dart`.
- [X] T024 [P] [US2] Widget test asserting a rapid double-tap on a single quick action triggers only one navigation (FR-013) — extends `quick_action_row_test.dart`.
- [X] T025 [P] [US2] `integration_test` scenario (folded into `dashboard_flows_test.dart`, T045): tapping each of the five quick actions opens the correct existing form; completing one and returning to Home shows the updated snapshot without a manual refresh (FR-011, spec US2 AC5).

### Implementation for User Story 2

- [X] T026 [P] [US2] Implement `lib/features/dashboard/presentation/widgets/quick_action_button.dart`: a single tappable action (icon + localized label) that disables itself immediately after tap until the navigation completes (FR-013 — no double-tap duplicate navigation), reusing `AppButton`/design tokens.
- [X] T027 [US2] Implement `lib/features/dashboard/presentation/widgets/quick_action_row.dart`: renders `QuickActionButton`s for Add Expense (`context.push('/finance/entries/new?type=expense')`, per feature 007's routes), Add Income (`?type=income`), Add Person (`context.push('/people/new')`), Add Money Received (`context.push('/transactions/new?direction=received')`), Add Money Given (`?direction=given`) — confirm the exact existing route/query-parameter shape against `app_router.dart`/`transaction_form_page.dart` before wiring (no new form is built here, FR-007). Reads `kOccasionsFeatureEnabled`/`kOcrScanFeatureEnabled` (T002) to hide (or render visibly-disabled, implementer's choice at build time per FR-008) the two future slots — never a live route to a non-existent screen (depends on T026).
- [X] T028 [US2] Extend `home_page.dart` (T018) with the `QuickActionRow` (T027) as its own "Quick Actions" section, positioned per progressive-disclosure order (Financial Snapshot → Quick Actions → Insights → Upcoming, per spec's section ordering) (depends on T018, T027).
- [X] T029 [US2] Extend `DashboardCubit`/`HomePage` (T014/T018) so returning to Home after a quick action (e.g. via `GoRouterState` refresh-on-pop or a `didPopNext`/route-observer hook consistent with existing app navigation patterns) triggers `DashboardCubit.refresh()` automatically (FR-011) — confirm this does not conflict with the existing pull-to-refresh `RefreshIndicator` from T018 (depends on T014, T018, T027).

**Checkpoint**: User Stories 1 AND 2 both work independently — the snapshot renders and every quick action reaches its correct existing form with no duplicate-tap risk.

---

## Phase 5: User Story 3 - Know What's Coming Without Being Told a Lie (Priority: P2)

**Goal**: Insights and Upcoming sections show honest, clearly-worded "not yet available" copy — never any fabricated content — until the AI Assistant/Budgets/Savings features exist.

**Independent Test**: On a fresh install with none of the AI Assistant, Budgets, or Savings features present, open the home screen and verify the Insights and Upcoming sections each show an honest, clearly-worded empty state rather than any invented content (spec.md US3 Independent Test).

### Tests for User Story 3 ⚠️

- [X] T030 [P] [US3] Widget test for `InsightsPlaceholderCard`: renders only the approved "insights arrive once the AI Assistant is set up" copy — SC-004's dedicated regression assertion that this is the *only* string this widget can ever render (a hardcoded golden-string comparison, not a substring/contains check, so a future accidental "helpful" hardcoded insight fails this test immediately) — in `test/widget/insights_placeholder_card_test.dart`.
- [X] T031 [P] [US3] Widget test for `UpcomingPlaceholderCard`: same golden-string discipline as T030 for the Upcoming copy (SC-004), and confirms its wording is textually distinct from the Financial Snapshot's balance-totals copy (spec US3 AC3 — no duplication) — in `test/widget/upcoming_placeholder_card_test.dart`.

### Implementation for User Story 3

- [X] T032 [P] [US3] Implement `lib/features/dashboard/presentation/widgets/insights_placeholder_card.dart`: a static `AppEmptyView`/`AppCard`-based widget rendering the localized "insights arrive once the AI Assistant is set up" string (FR-009) — no data binding, no conditional content, so it is structurally impossible for this widget to ever show fabricated content.
- [X] T033 [P] [US3] Implement `lib/features/dashboard/presentation/widgets/upcoming_placeholder_card.dart`: same structural discipline as T032, rendering the localized "upcoming bills, savings goals, and unsettled balances arrive once Budgets/Savings exist" string (FR-010), worded distinctly from the Financial Snapshot section.
- [X] T034 [US3] Extend `home_page.dart` (T018/T028) with the Insights (T032) and Upcoming (T033) sections, positioned last per progressive disclosure (depends on T018, T028, T032, T033).

**Checkpoint**: User Stories 1-3 all work independently — the screen never shows fabricated forward-looking content.

---

## Phase 6: User Story 4 - Recover Gracefully When Part of the Data Fails to Load (Priority: P2)

**Goal**: A failure in one aggregate (balance totals or finance summary) never blocks or hides the other; each failed card offers its own retry; a full-screen error only appears when both fail.

**Independent Test**: Simulate one aggregate (balance totals or finance summary) failing to load while the other succeeds, and verify the screen still renders the successful part fully, with a clear, localized retry affordance on just the failed part (spec.md US4 Independent Test).

### Tests for User Story 4 ⚠️

- [X] T035 [P] [US4] `bloc_test` for `DashboardCubit.retryOverview()`: re-fetches only the overview aggregate; `financeStatus`/`financeSummary`/`financeError` are provably untouched by the call (FR-003) — extends `dashboard_cubit_test.dart`.
- [X] T036 [P] [US4] `bloc_test` for `DashboardCubit.retryFinance()`: re-fetches only the finance aggregate; `overviewStatus`/`overviewSummary`/`overviewError` are provably untouched (FR-003) — extends `dashboard_cubit_test.dart`.
- [X] T037 [P] [US4] `bloc_test` asserting `isFullFailure` is true only when both `overviewStatus` and `financeStatus` are `failure` simultaneously, and false in every other combination (FR-004) — extends `dashboard_cubit_test.dart`.
- [X] T038 [P] [US4] Widget test for `HomePage`'s partial-error rendering: one card in an inline error+retry state, the other rendering its real data normally, rest of screen (quick actions, Insights, Upcoming) fully visible and unaffected (spec US4 AC1/AC2) — extends `home_page_test.dart`.
- [X] T039 [P] [US4] Widget test for `HomePage`'s full-failure rendering: a single full-screen error state with one retry action that calls `DashboardCubit.load()` again (re-attempting both) — extends `home_page_test.dart`.

### Implementation for User Story 4

- [X] T040 [US4] Extend `dashboard_cubit.dart` (T014) with `retryOverview()` (re-runs only the `GetOverview` portion of `GetDashboardSnapshot`'s logic — or calls `GetOverview` directly and merges just that result into state — updating only `overviewStatus`/`overviewSummary`/`overviewError` via `copyWith()`) and `retryFinance()` (symmetric, touching only the finance fields), per `contracts/get_dashboard_snapshot.md`'s `DashboardCubit` retry-surface contract (depends on T014).
- [X] T041 [US4] Extend `home_page.dart`'s Financial Snapshot section (T018) so `OverviewSummaryCard`/`FinanceSnapshotCard` each independently render their own inline error state (localized message + retry button calling `retryOverview()`/`retryFinance()` respectively, FR-003) when their corresponding `LoadStatus == failure`, and a single full-screen `AppEmptyView`-based error state with one combined retry (calling `DashboardCubit.load()`) when `isFullFailure == true` (FR-004) (depends on T018, T040).
- [X] T042 Complete the ARB key block reserved in T003 (`lib/core/l10n/app_en.arb`/`app_ar.arb`): Home title, financial-snapshot labels, quick-action labels, Insights/Upcoming placeholder copy (matching T030/T031's golden strings exactly), inline/full-screen error and retry labels, combined-empty-state copy — confirm no hardcoded `Text("...")` remains anywhere in `lib/features/dashboard/` (constitution Principle XIII) (depends on T019, T027, T032, T033, T041).

**Checkpoint**: All four user stories are independently functional — the Home Dashboard feature is complete end-to-end.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Isolation verification, localization/theme completeness, and the end-to-end regression this feature's dependency chain makes highest-value.

- [X] T043 [P] Regression test confirming FR-016: `DashboardCubit`/`GetDashboardSnapshot` never alter the values `GetOverview`/`GetFinanceSummary` themselves would return when called directly — in `test/features/dashboard/isolation_from_sources_test.dart`.
- [X] T044 [P] Widget test for `HomePage`: Arabic RTL layout (card order, quick-action row direction, number/currency formatting) and light/dark theme legibility for every card and status color — in `test/widget/home_page_test.dart` (extends existing).
- [X] T045 [P] `integration_test/dashboard_flows_test.dart`: end-to-end coverage of US1-US4 per quickstart.md's Manual Validation Scenarios 1-6 — combined snapshot rendering, all five quick actions plus the two hidden future slots, Insights/Upcoming honesty, single-source failure + retry for each side, full-failure + combined retry, and the FR-016 isolation check.
- [X] T046 Verify no `// ignore` suppressions, no hardcoded colors/strings were introduced across the `dashboard` feature (constitution Principle XV/XIII); run `flutter analyze` and fix any warnings.
- [X] T047 Run `flutter test integration_test` end-to-end on an emulator/simulator and `flutter format` across all new/relocated files; confirm all quickstart.md Automated Verification commands pass clean.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately (requires no part of feature 007).
- **Foundational (Phase 2)**: Depends on Setup completion AND feature 007 being implemented (its `GetFinanceSummary`/`GetFinanceHistory` must exist in DI) — BLOCKS all user stories.
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion.
  - US1 (P1) is the relocation + combined-snapshot core — every other story extends the `HomePage`/`DashboardCubit` it establishes.
  - US2 (P1) depends on US1's `HomePage`/`DashboardCubit` existing (adds the Quick Actions section to the same page).
  - US3 (P2) depends on US1's `HomePage` existing (adds two more sections); has no dependency on US2.
  - US4 (P2) depends on US1's `DashboardCubit`/`DashboardState` existing (extends both with retry logic); has no dependency on US2/US3.
- **Polish (Phase 7)**: Depends on all four user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Foundational only. No dependency on other stories — this is the MVP slice.
- **US2 (P1)**: Extends US1's `HomePage` with a new section — build immediately after US1.
- **US3 (P2)**: Extends US1's `HomePage` with two new sections — independently addable in parallel with US2 (different widgets, same page file — coordinate the page-file edit order).
- **US4 (P2)**: Extends US1's `DashboardCubit`/`DashboardState` — independently addable in parallel with US2/US3 (different Cubit methods, same page file for the error-rendering piece — coordinate the page-file edit order).

### Within Each User Story

- Tests written first, confirmed to fail, then implementation (per this repo's established TDD convention, mirrored from spec 001/007).
- Entities/enums before use cases; use cases before Cubits; Cubits before pages/widgets.
- DI annotation + codegen (`build_runner`) after each phase's use cases/Cubits are defined.
- Relocation tasks (T016, T018, T020) preserve existing behavior first — verified by carrying forward `overview_cubit_test.dart`'s assertions (T020) — before any new US1 behavior (empty-state detection) is added on top.

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel.
- T004/T005 (Foundational entities/enums) can run in parallel; T006 depends on both.
- All [P] test tasks within a phase can run in parallel (different files).
- US2 and US3 can be staffed in parallel once US1 completes (both only extend `HomePage` with new, independent sections — coordinate merge order on `home_page.dart`).
- US4 can be staffed in parallel with US2/US3 once US1 completes (extends `DashboardCubit`, touches `home_page.dart`'s error rendering — coordinate merge order).

---

## Parallel Example: User Story 1

```bash
# Launch all US1 tests together:
Task: "bloc_test for DashboardCubit.load() in test/features/dashboard/presentation/cubit/dashboard_cubit_test.dart"
Task: "bloc_test for combined-empty detection in test/features/dashboard/presentation/cubit/dashboard_cubit_test.dart"
Task: "Widget test for HomePage's Financial Snapshot section in test/widget/home_page_test.dart"

# Launch US1 foundational entities together:
Task: "Define LoadStatus enum"
Task: "Define DashboardSnapshot entity"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories; requires feature 007 implemented first)
3. Complete Phase 3: User Story 1 (combined financial snapshot, including the relocation of `OverviewPage`/`OverviewCubit`)
4. **STOP and VALIDATE**: Test the combined snapshot independently per quickstart.md Scenario 1
5. Deploy/demo if ready — a user can already see their complete financial picture on one screen, the feature's core value

### Incremental Delivery

1. Setup + Foundational → coordination use case verified
2. Add US1 → Test independently → Deploy/Demo (MVP!)
3. Add US2 (quick actions) → Test independently → Deploy/Demo
4. Add US3 (honest placeholders) → Test independently → Deploy/Demo
5. Add US4 (partial-failure resilience) → Test independently → Deploy/Demo
6. Polish (Phase 7) → full regression, localization/theme completeness, FR-016 isolation proof

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (confirm feature 007 is genuinely implemented, not just planned, before starting Phase 2 — this is the one hard external blocker in this feature).
2. Once US1 lands:
   - Developer A: US2 (quick actions thread)
   - Developer B: US3 (Insights/Upcoming thread)
   - Developer C: US4 (partial-error/retry thread)
3. Stories integrate at `home_page.dart`/`dashboard_cubit.dart` — coordinate merge order since all three touch the same two files in different sections/methods.

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to specific user story for traceability.
- This feature relocates (not duplicates) `OverviewPage`/`OverviewCubit`/`OverviewState`/`OverviewSummaryCard` from `transactions/presentation/` into `dashboard/presentation/` (T016, T018, T020) — `GetOverview` and its entities stay untouched in `transactions/domain/`. FR-016 (T043) is the regression test guarding that the underlying calculations themselves are never touched by this move.
- Verify tests fail before implementing.
- Commit after each task or logical group.
- Stop at any checkpoint to validate a story independently.
- Avoid: vague tasks, same-file conflicts, cross-story dependencies that break independence.
