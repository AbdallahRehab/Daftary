---

description: "Task list template for feature implementation"
---

# Tasks: Reports & Data/Privacy Controls

**Input**: Design documents from `/specs/013-reports-data-privacy/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present). **Hard dependency**: feature 007 (Income & Expense Tracking) MUST be implemented first — `GetSummary`/`GetCategoryBreakdown`/`getHistory` must exist and be registered in DI before any task below can begin.

**Tests**: Included — plan.md's Testing section and constitution Principle XVI both require unit/Cubit/widget/integration tests; test tasks below are not optional. `DeleteAllUserData`'s atomicity test (T032) is the single highest-stakes test in this feature and MUST run against a real in-memory `drift` database, not a mock (research.md Decision 10).

**Organization**: This feature has two structurally independent halves living in different modules (plan.md Project Structure): **Part A (Reports)** extends the existing `lib/features/finance/` module (from feature 007) with new files only — no relocation, no change to any existing 007 file. **Part B (Export/Delete)** creates a brand-new `lib/features/data_privacy/` module from scratch, plus one new `lib/core/database/data_wipe.dart` extension, a `pubspec.yaml` addition for `share_plus`, and a small, additive extension to the existing `lib/features/settings/presentation/pages/settings_page.dart` (a new Danger Zone section — the file is extended, never rewritten). Tasks are grouped by the three user stories in spec.md (US1 Reports P1, US2 Export P1, US3 Delete P2).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Single Flutter app, feature-first (plan.md Project Structure): `lib/features/finance/{domain/usecases,presentation/{cubit,pages,widgets}}/` (existing, extended), `lib/features/data_privacy/{domain,data,presentation}/` (new), `lib/core/database/data_wipe.dart` (new), mirrored under `test/`, plus `integration_test/reports_flows_test.dart` and `integration_test/data_privacy_flows_test.dart`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold the new `data_privacy` module, add the one new dependency, and reserve ARB key space.

- [ ] T001 Create the `data_privacy` feature directory skeleton: `lib/features/data_privacy/domain/{entities,repositories,services,usecases}/`, `lib/features/data_privacy/data/{repositories,services}/`, `lib/features/data_privacy/presentation/{cubit,pages,widgets}/`, mirrored under `test/features/data_privacy/{domain/usecases,data/services,presentation/cubit}/`, plus `test/widget/` (existing, shared) and `integration_test/` (existing, shared), per plan.md's Project Structure. Part A (Reports) needs no new directories — `lib/features/finance/domain/usecases/`, `presentation/{cubit,pages,widgets}/` already exist from feature 007.
- [ ] T002 [P] Add `share_plus` to `pubspec.yaml` (research.md Decision — the one new dependency this feature introduces, justified for the OS share-sheet hand-off, FR-010); run `fvm flutter pub get`.
- [ ] T003 [P] Reserve a contiguous ARB key block in `lib/core/l10n/app_en.arb`/`app_ar.arb` for this feature: Reports screen/chart labels, export screen/error labels, delete-flow warning/confirmation-phrase/button labels — full string values filled in per-phase below (T054), this task only establishes the block exists so later phases don't collide.

**Checkpoint**: Directory layout matches plan.md; `share_plus` resolves; no compile changes yet.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Confirm the one hard external blocker. Unlike prior features, US1/US2/US3 here are genuinely independent domains (Reports touches only `finance`; Export touches `people`/`transactions`/`finance`/`settings` read-only; Delete touches every table but needs nothing Export needs) — there is no shared new code between them beyond Setup.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T004 Verify feature 007 (Income & Expense Tracking) is fully implemented: `FinanceRepository.getSummary`, `getCategoryBreakdown`, and `getHistory` exist, are registered in `injection.config.dart`, and pass their own test suite. This feature's US1 (T009) and US2 (T024) both call these directly — do not proceed past this checkpoint if 007 is only planned, not implemented.

**Checkpoint**: 007 confirmed implemented — every user story phase below can now proceed independently of each other.

---

## Phase 3: User Story 1 - See Spending and Income Trends Over Time (Priority: P1) 🎯 MVP

**Goal**: A Reports screen shows a monthly income/expense trend and a per-category breakdown for a selectable period, built entirely from 007's existing aggregation, with correct empty/error states and RTL/theme-correct charts.

**Independent Test**: With income/expense entries recorded across several past months and categories, open the Reports screen and verify the category breakdown and the monthly trend both display correct figures matching a manual calculation from the underlying entries (spec.md US1 Independent Test).

### Tests for User Story 1 ⚠️ (write first, confirm they fail, then implement)

- [ ] T005 [P] [US1] Unit test `GetSpendingTrend`: confirms the per-month `getSummary` calls run concurrently (`Future.wait`, not sequentially — assert via faked per-call delays and measuring elapsed time is roughly `max`, not `sum`, per `contracts/get_spending_trend.md`); confirms a failure on any single month fails the entire trend result rather than silently omitting that month (FR-005) — in `test/features/finance/domain/usecases/get_spending_trend_test.dart`.
- [ ] T006 [P] [US1] `bloc_test` for `ReportsCubit`: loading → success (trend + breakdown both populated); true empty state when zero finance entries exist anywhere (FR-004); error+retry when either the trend or the breakdown call fails (FR-005); switching the breakdown's selected period re-fetches only the breakdown while the trend is untouched (spec US1 AC3) — in `test/features/finance/presentation/cubit/reports_cubit_test.dart`.
- [ ] T007 [P] [US1] Widget test for `ReportsPage`: category breakdown ordered largest-to-smallest with correct share values (FR-002); RTL chart mirroring — axis direction, legend position, and all labels correctly mirrored, not just text direction (FR-006); light/dark theme legibility for both charts — in `test/widget/reports_page_test.dart`.

### Implementation for User Story 1

- [ ] T008 [P] [US1] Define the `SpendingTrendPoint` entity (data-model.md "Entity: SpendingTrendPoint") in `lib/features/finance/domain/entities/spending_trend_point.dart`: `period` (`DateRange`), `totalIncomeMinorUnits`, `totalExpenseMinorUnits`, `netMinorUnits` — a thin re-shaping of `FinanceSummary` for one month, never recomputing anything (FR-003).
- [ ] T009 [US1] Implement `lib/features/finance/domain/usecases/get_spending_trend.dart` per `contracts/get_spending_trend.md`: depends only on the existing `FinanceRepository` (no cross-feature coordination needed, unlike Home Dashboard's `GetDashboardSnapshot`); computes the last `monthsBack` calendar months (default 6, spec Assumptions' "reasonable rolling window"), calls `getSummary(period)` once per month concurrently via `Future.wait`, folds results into `Either<Failure, List<SpendingTrendPoint>>` — any single month's failure fails the whole result (depends on T008).
- [ ] T010 Annotate `GetSpendingTrend` with `@injectable`, then re-run `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart` (depends on T009).
- [ ] T011 [US1] Implement `lib/features/finance/presentation/cubit/reports_cubit.dart` + `reports_state.dart` (`Equatable`, `copyWith()`): `load()` calls `GetSpendingTrend` and the existing `FinanceRepository.getCategoryBreakdown(period)` (via 007's existing use case, not a new one — FR-003) concurrently; exposes loading/success/empty (FR-004, zero finance entries anywhere)/error (FR-005) states; `changeBreakdownPeriod(period)` re-fetches only the breakdown, leaving the trend data untouched (depends on T009).
- [ ] T012 Annotate `ReportsCubit` with `@injectable`, re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T011).
- [ ] T013 [P] [US1] Implement `lib/features/finance/presentation/widgets/monthly_trend_chart.dart`: a `CustomPainter`-based bar/line chart of `SpendingTrendPoint`s, axis direction and any positional element driven by ambient `Directionality` so it mirrors correctly under RTL with no separate RTL code path (research.md Decision 7), using design tokens for income/expense colors (never hardcoded, constitution Principle XV), paired with icon/label distinction (never color-only, Accessibility standard).
- [ ] T014 [P] [US1] Implement `lib/features/finance/presentation/widgets/category_breakdown_chart.dart`: a proportional-bar layout closely following 007's existing `CategoryBreakdownBar` visual language (FR-002 — ordered largest to smallest, each showing its share), reusing `CategoryIconRegistry` from 007 for icon/color.
- [ ] T015 [US1] Implement `lib/features/finance/presentation/pages/reports_page.dart`: `MonthlyTrendChart` (T013) + a period selector for the breakdown + `CategoryBreakdownChart` (T014); `AppEmptyView`-based empty state (FR-004, direct path to add the first entry) and error+retry state (FR-005); an `AppBar` action icon linking to `/settings/export` (research.md Decision 9 — the Reports→Export shortcut serving SC-002) (depends on T011, T013, T014).
- [ ] T016 Register the `/finance/reports` route for `ReportsPage` in `lib/core/routing/app_router.dart`, nested under the existing People branch alongside 007's `/finance` routes (research.md Decision 9) (depends on T015).
- [ ] T017 [US1] Add a reachable entry point to Reports from the existing `finance` history/summary screen (007's `FinanceHistoryPage`) — a button/link to `/finance/reports` — so Reports is discoverable without requiring prior knowledge of the route (depends on T016).

**Checkpoint**: User Story 1 is fully functional and independently testable — trend and breakdown render correctly with proper empty/error states and RTL/theme correctness.

---

## Phase 4: User Story 2 - Export a Complete Copy of My Data (Priority: P1)

**Goal**: A `DataExportPage` generates one CSV file covering every existing data table, composed entirely from already-existing repository reads (zero new repository methods), and hands it to the OS share sheet.

**Independent Test**: With a mix of people, transactions, income/expense entries, and categories already recorded, request a data export and verify the resulting file contains every one of those records with correct values, and can be shared off the device (spec.md US2 Independent Test).

### Tests for User Story 2 ⚠️

- [ ] T018 [P] [US2] Unit test `ExportUserData` against faked `PeopleRepository`/`TransactionsRepository`/`FinanceRepository`/`CategoryRepository`/`SettingsRepository`: confirms People is sourced from `searchActivePeople()` + `searchArchivedPeople()` concatenated; Transactions from `getPersonHistory(personId)` for each person, flattened; FinanceEntries from `getHistory` paged to completion; Categories from `getCategories(type, includeArchived: true)` for both types; Settings from `getLanguagePreference()`/`getThemeModePreference()` (research.md Decision 2 — asserts zero new repository methods are called, only these exact existing ones); confirms a fully valid file is produced when every repository returns empty lists (FR-008); confirms a failure on any repository call surfaces as `Either.left` with no partially-written file left in a state that looks complete (FR-011) — in `test/features/data_privacy/domain/usecases/export_user_data_test.dart`.
- [ ] T019 [P] [US2] Unit test `SharePlusService`: maps a successful platform share-sheet presentation to `Right(unit)` and any platform exception to a typed `Failure` (never a raw exception surfaced) — in `test/features/data_privacy/data/services/share_plus_service_test.dart`.
- [ ] T020 [P] [US2] `bloc_test` for `ExportCubit`: idle → generating → ready-to-share on success; error+retry on failure (FR-011); confirms `retry()` re-runs `ExportUserData` cleanly — in `test/features/data_privacy/presentation/cubit/export_cubit_test.dart`.
- [ ] T021 [P] [US2] Widget test for `DataExportPage`: in-progress indicator while generating (FR-009); share affordance offered on success (FR-010); canceling the OS share sheet returns to the ready-to-share state, never an error state (spec Edge Cases); error state with retry on failure — in `test/widget/data_export_page_test.dart`.

### Implementation for User Story 2

- [ ] T022 [P] [US2] Define the `ExportResult` entity (data-model.md "Entity: ExportResult") in `lib/features/data_privacy/domain/entities/export_result.dart`: `filePath` (`String`, must point to an existing, non-empty file), `generatedAt` (`DateTime`), `sectionCounts` (`Map<String, int>`, per-section row counts for SC-003 verification).
- [ ] T023 [US2] Define the `ShareService` abstract interface (`contracts/export_user_data.md`) in `lib/features/data_privacy/domain/services/share_service.dart`: `shareFile({required String filePath, String? subject})`, returning success once the OS sheet is presented, not once a share is necessarily completed (spec Edge Cases).
- [ ] T024 [US2] Implement `lib/features/data_privacy/domain/usecases/export_user_data.dart` per `contracts/export_user_data.md`: composes the five existing repositories exactly as specified in research.md Decision 2 (zero new repository methods); serializes each section to its own CSV block with a `## SECTION` marker, header row, then data rows (research.md Decision 4); writes to a temporary path first and only finalizes/renames to the returned `ExportResult.filePath` on full success (FR-011); produces a structurally valid file with header-only sections when there is no data (FR-008) (depends on T022).
- [ ] T025 [US2] Implement `lib/features/data_privacy/data/services/share_plus_service.dart`: the only file in the codebase importing `package:share_plus/share_plus.dart`; implements `ShareService.shareFile` via `Share.shareXFiles([XFile(filePath)], subject: subject)`, mapping any platform exception to a typed `Failure` (depends on T002, T023).
- [ ] T026 Annotate `ExportUserData`/`SharePlusService` with `@injectable`/`@LazySingleton(as: ShareService)`, re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T024, T025).
- [ ] T027 [US2] Implement `lib/features/data_privacy/presentation/cubit/export_cubit.dart` + `export_state.dart` (`Equatable`, `copyWith()`): `generate()` calls `ExportUserData`, transitions idle → generating → ready (holding the `ExportResult`) or error; `share()` calls `ShareService.shareFile` with the generated path; `retry()` re-runs `generate()` (depends on T024, T025).
- [ ] T028 Annotate `ExportCubit` with `@injectable`, re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T027).
- [ ] T029 [US2] Implement `lib/features/data_privacy/presentation/pages/data_export_page.dart`: idle state (explain what export includes, a Generate action), generating state (in-progress indicator, FR-009), ready state (Share action calling `ExportCubit.share()`, FR-010), error state with retry (FR-011) — all copy localized (depends on T027).
- [ ] T030 Register the `/settings/export` route for `DataExportPage` in `lib/core/routing/app_router.dart`, nested under the existing Settings branch (depends on T029).

**Checkpoint**: User Stories 1 AND 2 both work independently — Reports render correctly and a complete, correct export can be generated and shared.

---

## Phase 5: User Story 3 - Permanently Delete All My Data (Priority: P2)

**Goal**: A two-step, typed-confirmation "Delete My Data" flow in Settings wipes every table as one atomic transaction and returns the app to its onboarding state — with provable zero data loss on any failure.

**Independent Test**: With a full set of people, transactions, income/expense entries, and categories recorded, trigger the delete-all-data flow, complete its confirmation, and verify every record is gone and the app behaves exactly like a fresh install afterward (spec.md US3 Independent Test).

### Tests for User Story 3 ⚠️

- [ ] T031 [P] [US3] Real-`drift` atomicity test for `AppDatabase.deleteAllUserData()` against `NativeDatabase.memory()`, pre-populated with rows in every table: forces a failure partway through the transaction (e.g., a faked constraint violation on one delete) and asserts every table is provably still fully intact afterward (FR-018, research.md Decision 10 — this specific test intentionally exercises the real `drift` transaction mechanism, not a mock, since atomicity is a property of the SQL boundary, not the Dart call sequence) — in `test/core/database/data_wipe_test.dart`.
- [ ] T032 [P] [US3] Unit test `DeleteAllUserData` with a faked `DataWipeRepository`: success/failure pass-through, confirms this use case performs no orchestration of its own beyond the repository call (research.md Decision 6 — orchestration belongs to `DeleteAccountCubit`) — in `test/features/data_privacy/domain/usecases/delete_all_user_data_test.dart`.
- [ ] T033 [P] [US3] `bloc_test` for `DeleteAccountCubit`: confirming → inProgress → success (asserts `OnboardingCubit.initialize()` is called exactly once on success, per research.md Decision 6) → error path leaves state clearly showing failure with no data implied lost; a rapid double-tap on `confirmDelete()` triggers the underlying `DeleteAllUserData` call exactly once (FR-021) — in `test/features/data_privacy/presentation/cubit/delete_account_cubit_test.dart`.
- [ ] T034 [P] [US3] Widget test for `DeleteDataConfirmationPage`: the destructive button stays disabled until the typed phrase exactly matches the expected localized phrase (FR-015); the permanent/irreversible warning copy is present and visible before any input (FR-014); canceling/navigating away at any point before final confirmation leaves no data affected (FR-020, asserted via a spy on `DeleteAccountCubit` never being invoked) — in `test/widget/delete_data_confirmation_page_test.dart`.

### Implementation for User Story 3

- [ ] T035 [P] [US3] Define the `DeleteConfirmationInput` value object (data-model.md "Entity: DeleteConfirmationInput") in `lib/features/data_privacy/presentation/cubit/delete_confirmation_input.dart`: `typedPhrase` (`String`), `expectedPhrase` (`String`, sourced from `l10n`), `isConfirmationEnabled` (derived — `typedPhrase.trim() == expectedPhrase`, never independently settable, constitution Principle IV).
- [ ] T036 [US3] Define the `DataWipeRepository` abstract interface (data-model.md, ONE method) in `lib/features/data_privacy/domain/repositories/data_wipe_repository.dart`: `Future<Either<Failure, Unit>> deleteAllUserData()`.
- [ ] T037 [US3] Implement `lib/core/database/data_wipe.dart` per `contracts/delete_all_user_data.md`: `extension DataWipe on AppDatabase` with `Future<void> deleteAllUserData()`, wrapping a bulk delete of every table (`TransactionAuditEntries`, `MoneyTransactions`, `People`, `FinanceEntries`, `FinanceCategories`, `AppSettings`, `OnboardingStatus`, in FK-respecting order) inside a single `transaction(() async { ... })` block — mirrors the existing `balance_queries.dart` precedent of a cross-feature extension on `AppDatabase` (depends on T031 to verify correctness).
- [ ] T038 [US3] Implement `lib/features/data_privacy/data/repositories/data_wipe_repository_impl.dart`: wraps `AppDatabase.deleteAllUserData()` (T037), maps any thrown exception to a typed `Failure` (depends on T036, T037).
- [ ] T039 [US3] Implement `lib/features/data_privacy/domain/usecases/delete_all_user_data.dart` per `contracts/delete_all_user_data.md`: a thin wrapper around `DataWipeRepository.deleteAllUserData()` — deliberately no orchestration here (research.md Decision 6) (depends on T036).
- [ ] T040 Annotate `DataWipeRepositoryImpl`/`DeleteAllUserData` with `@injectable`/`@LazySingleton(as: DataWipeRepository)`, re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T038, T039).
- [ ] T041 [US3] Implement `lib/features/data_privacy/presentation/cubit/delete_account_cubit.dart` + `delete_account_state.dart` (`Equatable`, `copyWith()`): holds a `DeleteConfirmationInput` (T035), updates it as the user types; `confirmDelete()` — guarded so a rapid repeated call executes the underlying deletion at most once (FR-021, e.g. an in-flight guard flag) — transitions confirming → inProgress → calls `DeleteAllUserData` (T039) → on success, calls the existing, already-re-callable `OnboardingCubit.initialize()` (research.md Decision 6) and emits `success`; on failure, emits `error` with a localized message and explicitly communicates that no data was lost (FR-018) (depends on T039).
- [ ] T042 Annotate `DeleteAccountCubit` with `@injectable`, re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T041).
- [ ] T043 [P] [US3] Implement `lib/features/data_privacy/presentation/widgets/typed_confirmation_field.dart`: an `AppTextField`-based input bound to `DeleteConfirmationInput.typedPhrase`, showing the required phrase as a hint/label, live-updating `isConfirmationEnabled`.
- [ ] T044 [US3] Implement `lib/features/data_privacy/presentation/pages/delete_data_confirmation_page.dart`: the explicit permanent/irreversible warning (FR-014), `TypedConfirmationField` (T043), a destructive "Delete Everything" button disabled until `isConfirmationEnabled` (FR-015), an in-progress indicator during `DeleteAccountState.inProgress` (FR-019), and on `success` calls `context.go('/')` — relying on the router's existing `redirect:` check (already reading `OnboardingCubit`'s state) to land on `/onboarding` naturally (research.md Decision 6, no new redirect logic) (depends on T041, T043).
- [ ] T045 Register the `/settings/delete-data` route for `DeleteDataConfirmationPage` in `lib/core/routing/app_router.dart`, nested under the existing Settings branch (depends on T044).
- [ ] T046 [US3] Extend `lib/features/settings/presentation/pages/settings_page.dart` with a new `_SettingsSection` ("Danger Zone", placed below the existing Theme section) containing a single "Delete My Data" list tile linking to `/settings/delete-data` — the existing Language/Theme sections and `SettingsCubit` wiring are untouched, this is a strictly additive extension, never a rewrite (depends on T045).

**Checkpoint**: All three user stories are independently functional — Reports, Export, and Delete each work correctly and Delete is provably atomic.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Edge-case coverage, localization/theme completeness, and the end-to-end regressions this feature's destructive/privacy nature makes highest-value.

- [ ] T047 [P] Regression test confirming FR-003: `ReportsCubit`/`GetSpendingTrend` never compute a figure that differs from calling `GetSummary`/`GetCategoryBreakdown` directly — in `test/features/finance/reports_isolation_test.dart`.
- [ ] T048 [P] Regression test confirming `ExportUserData` never mutates any table (read-only proof against an in-memory `drift` DB — row counts and content identical before/after an export call) — in `test/features/data_privacy/export_read_only_test.dart`.
- [ ] T049 [P] Edge case test: export on a brand-new install with zero data of any kind produces a valid, correctly-structured (header-only) file, not an error (FR-008, SC-007) — extends `export_user_data_test.dart`.
- [ ] T050 [P] Edge case test: device with zero network connectivity completes Reports/Export/Delete's own logic normally; only the final OS share-sheet destination choice is outside the app's control (FR-022) — a manual/documented check in `quickstart.md` Scenario 4, plus an automated assertion that no HTTP/network client is invoked anywhere in `data_privacy`'s or `finance`'s Reports code paths.
- [ ] T051 [P] Widget/localization test: Reports, Export, and Delete screens fully localized in both `ar`/`en`, correct RTL layout (including chart mirroring, FR-006), correctly themed in light/dark mode, and free of any hardcoded `Text("...")` (FR-023, constitution Principle XIII) — in `test/widget/{reports_page_test.dart,data_export_page_test.dart,delete_data_confirmation_page_test.dart}` (extends existing).
- [ ] T052 Complete the ARB key block reserved in T003 (`lib/core/l10n/app_en.arb`/`app_ar.arb`): Reports chart/period labels, export screen/error labels, delete-flow warning copy, confirmation-phrase label, and destructive-button label.
- [ ] T053 [P] `integration_test/reports_flows_test.dart`: end-to-end coverage of US1 per quickstart.md Scenario 1 — trend + breakdown rendering, period switch, empty state, error+retry, RTL/theme spot-check.
- [ ] T054 [P] `integration_test/data_privacy_flows_test.dart`: end-to-end coverage of US2 + US3 per quickstart.md Scenarios 2-3 — full export generation and content verification (SC-003), OS share-sheet cancel-returns-to-ready behavior, full delete-and-confirm-reset-to-onboarding, and a forced-failure delete asserting zero data loss (SC-005).
- [ ] T055 Run `flutter analyze`/`flutter format` across all new/extended files; confirm no `// ignore` suppressions or hardcoded colors/strings were introduced; confirm all quickstart.md Automated Verification commands pass clean, including the real-transaction `data_wipe_test.dart`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately (requires no part of feature 007).
- **Foundational (Phase 2)**: A single external-dependency checkpoint (feature 007 implemented) — BLOCKS all user stories, but requires no new code of its own.
- **User Stories (Phase 3-5)**: All depend on Foundational (T004) completion. US1, US2, and US3 have **no dependency on each other** — each reads a different, non-overlapping set of existing data/capabilities (US1: `finance` only; US2: five existing repositories, read-only; US3: a new all-table wipe capability that neither US1 nor US2 touches).
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Foundational only (needs 007 implemented). No dependency on US2/US3 — independently shippable as the MVP slice on its own.
- **US2 (P1)**: Foundational only (needs 007 implemented, plus `people`/`transactions`/`settings` which are already stable V1 features). No dependency on US1/US3.
- **US3 (P2)**: Foundational only in the sense that it needs no finance data specifically — it wipes every table regardless of whether 007 has shipped, but is sequenced after US1/US2 per spec.md's own priority ordering (destructive action, rarer need) and because `data_privacy`'s directory skeleton (T001) is shared Setup. No functional dependency on US1/US2's own code.

### Within Each User Story

- Tests written first, confirmed to fail, then implementation (per this repo's established TDD convention).
- Entities/value objects before use cases; use cases before Cubits; Cubits before pages/widgets.
- DI annotation + codegen (`build_runner`) after each phase's use cases/Cubits are defined.
- T037 (`data_wipe.dart`)'s correctness is verified by T031's real-transaction test — implement T031 first, watch it fail against a stub, then implement T037 to make it pass (the one place in this feature where the test genuinely drives the implementation of a non-trivial mechanism, not just a contract shape).

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel.
- Once Foundational (T004) completes, **US1, US2, and US3 can be staffed fully in parallel** by three different developers — they share no files except the Setup-phase directory skeleton and `app_router.dart` (coordinate route-registration merge order: T016, T030, T045 each add one `GoRoute` to the same file).
- All [P] test tasks within a phase can run in parallel (different files).
- All [P] domain entity/value-object tasks within a phase can run in parallel.

---

## Parallel Example: Cross-Story (once Foundational completes)

```bash
# Three developers can start simultaneously:
Developer A: "T005-T017 (User Story 1 - Reports)"
Developer B: "T018-T030 (User Story 2 - Export)"
Developer C: "T031-T046 (User Story 3 - Delete)"
```

```bash
# Within User Story 3, launch all tests together:
Task: "Real-drift atomicity test in test/core/database/data_wipe_test.dart"
Task: "Unit test DeleteAllUserData in test/features/data_privacy/domain/usecases/delete_all_user_data_test.dart"
Task: "bloc_test DeleteAccountCubit in test/features/data_privacy/presentation/cubit/delete_account_cubit_test.dart"
Task: "Widget test DeleteDataConfirmationPage in test/widget/delete_data_confirmation_page_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — confirm feature 007 is genuinely implemented)
3. Complete Phase 3: User Story 1 (Reports)
4. **STOP and VALIDATE**: Test trend/breakdown rendering independently per quickstart.md Scenario 1
5. Deploy/demo if ready — Reports alone already delivers real user value without Export/Delete existing yet

### Incremental Delivery

1. Setup + Foundational → 007 confirmed implemented
2. Add US1 (Reports) → Test independently → Deploy/Demo
3. Add US2 (Export) → Test independently → Deploy/Demo — the two P1 privacy/trust stories are now both live
4. Add US3 (Delete) → Test independently → Deploy/Demo
5. Polish (Phase 6) → full regression, localization/theme completeness, the two highest-stakes proofs (SC-003 export completeness, SC-005 zero-partial-deletion)

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (confirm feature 007 is genuinely implemented before starting — the one hard external blocker).
2. Once Foundational completes:
   - Developer A: US1 (Reports — entirely inside `finance`)
   - Developer B: US2 (Export — entirely inside new `data_privacy`, read-only)
   - Developer C: US3 (Delete — entirely inside new `data_privacy` + one `core/database/` file)
3. All three integrate cleanly with no shared files beyond `app_router.dart` (three independent `GoRoute` additions — trivial merge) and `settings_page.dart` (US3 only, additive section).

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to specific user story for traceability.
- This feature adds no new database table and no new column to any existing table — its only schema-adjacent addition is `lib/core/database/data_wipe.dart` (T037), a row-wipe capability, never a structural change.
- `ExportUserData` (T024) deliberately calls zero new repository methods (research.md Decision 2) — if implementation reveals a genuine gap, treat that as a signal to re-examine the decision, not a license to add ad hoc new repository surface without updating research.md first.
- T031 (the real-`drift` atomicity test) is this feature's single most important test — do not skip or weaken it to a mocked equivalent under time pressure; it is the only test that actually proves FR-018/SC-005.
- Verify tests fail before implementing.
- Commit after each task or logical group.
- Stop at any checkpoint to validate a story independently.
- Avoid: vague tasks, same-file conflicts, cross-story dependencies that break independence.
