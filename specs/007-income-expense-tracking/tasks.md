---

description: "Task list template for feature implementation"
---

# Tasks: Income & Expense Tracking

**Input**: Design documents from `/specs/007-income-expense-tracking/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included — `plan.md`'s Testing section and constitution Principle XVI both require unit/Cubit/integration tests for this feature; test tasks below are not optional.

**Organization**: Tasks are grouped by user story (spec.md P1-P3) to enable independent implementation and testing of each story. `lib/features/finance/` does not exist yet — every task below creates new files; no existing `people`/`transactions`/`settings`/`onboarding` code is modified except `app_database.dart` (additive migration), `app_router.dart`/`main_shell.dart` (new route/nav entry), and the shared ARB files (new keys only).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

Single Flutter app, feature-first (plan.md Project Structure): `lib/features/finance/{data,domain,presentation}/`, mirrored under `test/features/finance/`, plus `integration_test/finance_flows_test.dart`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold the new `finance` feature module. No new package dependencies are required (plan.md Technical Context confirms this).

- [X] T001 Create the `finance` feature directory skeleton: `lib/features/finance/data/{datasources,models,repositories}/`, `lib/features/finance/domain/{entities,repositories,usecases}/`, `lib/features/finance/presentation/{cubit,pages,widgets}/`, mirrored under `test/features/finance/{domain/usecases,data/repositories,presentation/cubit}/`, per plan.md's Project Structure.
- [X] T002 [P] Add the `finance` module's ARB scaffolding: reserve a contiguous key block in `lib/core/l10n/app_en.arb`/`app_ar.arb` for this feature (entry form, category management, summary/period, empty/error states) — full string values are filled in per-phase below (T086), this task only establishes the block exists so later phases don't collide.

**Checkpoint**: Directory layout matches plan.md; no compile changes yet.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema migration, shared entities, and the icon registry every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Add `FinanceCategories` and `FinanceEntries` drift tables to `lib/core/database/app_database.dart` exactly per data-model.md's Schema section: `FinanceCategories(id, name, normalizedName, type, icon, isDefault, isArchived, createdAt, updatedAt)` with primary key `id`; `FinanceEntries(id, idempotencyKey UNIQUE, categoryId REFERENCES FinanceCategories(id), type, amountMinorUnits, date, note NULLABLE, createdAt, editedAt NULLABLE, deletedAt NULLABLE)` with primary key `id`. Add indexes `idx_finance_categories_normalized_name` on `(normalizedName, type)`, `idx_finance_entries_category_id` on `(categoryId, deletedAt)`, `idx_finance_entries_date` on `(date, deletedAt)`.
- [X] T004 Bump `AppDatabase.schemaVersion` from 4 to 5 in `lib/core/database/app_database.dart`; extend the `onUpgrade` migration strategy with `if (from < 5) { await m.createTable(financeCategories); await m.createTable(financeEntries); }` followed by an in-migration seed insert of the default category rows (data-model.md "Seed data": 16 expense categories — Rent, Electricity, Water, Internet, Phone, Groceries, Transportation, Fuel, Medical, Education, Entertainment, Shopping, Restaurants, Subscriptions, Family, Other; 6 income categories — Salary, Freelance, Business, Bonus, Gift, Other Income — each `isDefault = true`, `isArchived = false`). Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `app_database.g.dart`.
- [X] T005 [P] Unit test the v4→v5 migration against a database pre-populated with existing `People`/`MoneyTransactions` rows (research.md Decision 2 / quickstart.md Prerequisites): confirms both new tables are created, the 22 seed categories are inserted exactly once, and every pre-existing row in `People`/`MoneyTransactions`/`TransactionAuditEntries` is untouched — in `test/core/database/finance_migration_test.dart`.
- [X] T006 [P] Define `FinanceEntryType`/`CategoryType` enum (`income` \| `expense`, single shared enum per data-model.md — both entities reference the same two-value type) in `lib/features/finance/domain/entities/finance_entry_type.dart`.
- [X] T007 [P] Define the `Category` entity (`Equatable`) in `lib/features/finance/domain/entities/category.dart`: `id`, `name` (required, non-empty after trim), `type` (immutable after creation per data-model.md), `icon` (a `CategoryIconRegistry` key, not a raw `IconData`/color), `isDefault`, `isArchived` (default `false`), `createdAt`, `updatedAt`.
- [X] T008 [P] Define the `FinanceEntry` entity (`Equatable`) in `lib/features/finance/domain/entities/finance_entry.dart`: `id`, `idempotencyKey`, `categoryId`, `type` (must match the referenced category's `type`), `amountMinorUnits` (`> 0`), `date` (date-only, defaults to today, future dates accepted), `note?`, `createdAt`, `editedAt?` (`null` = never edited), `deletedAt?` (`null` = active).
- [X] T009 [P] Define the derived (never persisted) `FinanceSummary` (`totalIncomeMinorUnits`, `totalExpenseMinorUnits`, `netMinorUnits`, `period`) and `CategoryBreakdownItem` (`categoryId`, `categoryName`, `icon`, `totalMinorUnits`, `shareOfPeriod`) value objects in `lib/features/finance/domain/entities/finance_summary.dart` and `lib/features/finance/domain/entities/category_breakdown_item.dart`, plus a `DateRange`/`FinanceHistoryFilter` value object (type/categoryId/date-range filter, per `finance_repository.md`) in `lib/features/finance/domain/entities/finance_history_filter.dart`.
- [X] T010 [P] Add `DuplicateCategoryFailure` (carries the matching existing `Category`) and `CategoryInUseFailure` (informational — never actually blocks removal per data-model.md's archive-instead-of-block semantics, but documents why an archive happened) to `lib/features/finance/domain/entities/finance_failures.dart`, extending the core `Failure` from `lib/core/error/failure.dart`.
- [X] T011 [P] Build `CategoryIconRegistry` in `lib/features/finance/presentation/widgets/category_icon_registry.dart` (research.md Decision 10): maps each seeded/curated icon string key (`'groceries'`, `'rent'`, `'salary'`, `'other'`, etc. — one per default category at minimum) to a `Material` `IconData` and a design-token color from `core/design_system/tokens.dart` — never a raw hex color or persisted `IconData`.

**Checkpoint**: Migration verified, shared domain entities and the icon registry exist — every user story phase below can now proceed.

---

## Phase 3: User Story 1 - Record an Expense (Priority: P1) 🎯 MVP

**Goal**: From the finance section, add a new expense with a positive amount and a required category; it saves instantly and appears at the top of history with correct amount/category/date.

**Independent Test**: Add a new expense with an amount and a category, save it, and verify it appears at the top of the history with the correct amount, category, and date (spec.md US1 Independent Test).

### Tests for User Story 1 ⚠️ (write first, confirm they fail, then implement)

- [ ] T012 [P] [US1] Unit test `AddFinanceEntry`: rejects `amountMinorUnits <= 0` with a `ValidationFailure` (FR-003), rejects a `categoryId` whose `Category.type` does not match the entry's `type`, defaults `date` to today when unset, accepts a future `date`, and a retried call with the same `idempotencyKey` returns the already-persisted entry rather than creating a second one (FR-021) — in `test/features/finance/domain/usecases/add_finance_entry_test.dart`.
- [ ] T013 [P] [US1] Repository test against an in-memory `NativeDatabase.memory()`: `FinanceRepositoryImpl.addEntry` — the `idempotencyKey` unique index makes a retried insert a no-op returning the existing row (FR-021), rejects a category/type mismatch — in `test/features/finance/data/repositories/finance_repository_impl_test.dart`.
- [ ] T014 [P] [US1] `bloc_test` for `FinanceEntryFormCubit`: happy-path expense save, zero/empty-amount rejection preserving already-entered fields (FR-003), no-category-selected rejection, today-as-default date, future-date acceptance, and a simulated double-tap producing exactly one saved entry (FR-021) — in `test/features/finance/presentation/cubit/finance_entry_form_cubit_test.dart`.

### Implementation for User Story 1

- [X] T015 [US1] Define the `FinanceRepository` abstract interface in `lib/features/finance/domain/repositories/finance_repository.dart` per `contracts/finance_repository.md` (`addEntry` implemented in this phase; `editEntry`/`deleteEntry`/`restoreEntry`/`getHistory`/`getSummary`/`getCategoryBreakdown` implemented in later phases).
- [X] T016 [US1] Define the `CategoryRepository` abstract interface in `lib/features/finance/domain/repositories/category_repository.dart` per `contracts/category_repository.md` (`getCategories` implemented in this phase so the entry form has categories to pick from; `createCategory`/`editCategory`/`removeCategory` implemented in US4).
- [X] T017 [US1] Implement `lib/features/finance/data/datasources/finance_dao.dart` (drift DAO): `insertEntry` guarded by the `idempotencyKey` unique index — on a unique-constraint violation, fetch and return the existing row instead of erroring (FR-021, mirrors `transactions_dao.dart`'s precedent); `getCategoriesByType(type, includeArchived)` query.
- [X] T018 [US1] Implement `lib/features/finance/data/models/finance_entry_mapper.dart` and `lib/features/finance/data/models/category_mapper.dart`: map between drift `FinanceEntries`/`FinanceCategories` rows and the domain entities (T007, T008).
- [X] T019 [US1] Implement `lib/features/finance/data/repositories/finance_repository_impl.dart`: `addEntry` (validates `amountMinorUnits > 0` per FR-003, validates the category/type match per data-model.md, maps DB exceptions to `CacheFailure`/`UnknownFailure`) (depends on T015, T017, T018).
- [X] T020 [US1] Implement `lib/features/finance/data/repositories/category_repository_impl.dart`: `getCategories` only in this phase (depends on T016, T017, T018).
- [X] T021 [P] [US1] Implement `lib/features/finance/domain/usecases/add_finance_entry.dart`, wrapping `FinanceRepository.addEntry` (the `idempotencyKey` is caller-supplied, not generated here, per the contract).
- [X] T022 [P] [US1] Implement `lib/features/finance/domain/usecases/get_categories.dart`, wrapping `CategoryRepository.getCategories`.
- [X] T023 [P] [US1] Implement `lib/features/finance/domain/usecases/seed_default_categories.dart` — a no-op guard/read-through use case documenting that seeding itself happens in the T004 migration, not at runtime; exists so `CategoryManagementCubit` (US4) and tests have a single named place to confirm the starter set is present (per plan.md's use-case list).
- [X] T024 Annotate `FinanceRepositoryImpl`/`CategoryRepositoryImpl`/`FinanceDao` and the US1 use cases (T021-T023) with `@injectable`/`@LazySingleton(as: ...)`, then re-run `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart` (depends on T017-T023).
- [ ] T025 [US1] Implement `lib/features/finance/presentation/cubit/finance_entry_form_cubit.dart` + `finance_entry_form_state.dart` (`Equatable`, `copyWith`): generates a fresh idempotency key when the form opens, loads expense categories via `GetCategories(type: expense)`, disables Save immediately on tap so a rapid double-tap cannot re-invoke the use case (FR-021), validates `amountMinorUnits > 0` and a selected category client-side before calling `AddFinanceEntry`, defaults `date` to today, and folds the `Either` result into success/failure state (depends on T021, T022).
- [ ] T026 [P] [US1] Implement `lib/features/finance/presentation/widgets/category_picker_field.dart`: a grid/list of category chips (using `CategoryIconRegistry`, T011) filtered to the entry's `type` and excluding archived categories (FR-011), with live update if categories change.
- [ ] T027 [US1] Implement `lib/features/finance/presentation/pages/finance_entry_form_page.dart`: amount field accepting Arabic-Indic and Western numerals via `core/money/numeral_parser.dart` (FR-024), income/expense type toggle (defaults to whichever the entry point specified — Add Expense vs. Add Income), date picker defaulting to today (FR-001), optional note field, `CategoryPickerField` (T026), a Save button wired to `FinanceEntryFormCubit`, inline validation error display for zero/negative amounts and missing category (FR-003) without discarding already-entered fields (depends on T025, T026).
- [ ] T028 [US1] Register the `/finance/entries/new` route for `FinanceEntryFormPage` (accepting a `type` query parameter, e.g. `?type=expense`) nested under the existing People `StatefulShellBranch` in `lib/core/routing/app_router.dart` (research.md Decision 9 — no new bottom-nav tab).

**Checkpoint**: User Story 1 is fully functional and independently testable — record an expense with validation and guaranteed-once saves.

---

## Phase 4: User Story 2 - Record Income (Priority: P1)

**Goal**: From the finance section, add a new income entry with an amount and an income category; it appears in history and totals, visually distinguished from expenses.

**Independent Test**: Add a new income entry with an amount and a category, save it, and verify it appears in the history and totals separately from expenses (spec.md US2 Independent Test).

### Tests for User Story 2 ⚠️

- [ ] T029 [P] [US2] Unit test `AddFinanceEntry` with `type: income`: applies the identical validation rules as US1 (amount, category required, category/type match) with no branching by type in the use case itself (FR-002, FR-003) — extends `test/features/finance/domain/usecases/add_finance_entry_test.dart`.
- [ ] T030 [P] [US2] Widget test for `FinanceEntryListTile` (income vs. expense variants): confirms income and expense rows are visually distinguished (color, icon, sign) whenever both appear together, not solely by category name (FR-005) — in `test/widget/finance_entry_list_tile_test.dart`.

### Implementation for User Story 2

- [ ] T031 [US2] Extend `finance_entry_form_cubit.dart`/`finance_entry_form_page.dart` (T025/T027) so the income/expense toggle actually swaps the loaded category set (`GetCategories(type: income)` vs. `type: expense`) and the Add Income entry point pre-selects `income` — no new Cubit/page needed, this is the same form serving both directions per FR-002 (depends on T025, T027).
- [ ] T032 [P] [US2] Implement `lib/features/finance/presentation/widgets/finance_entry_list_tile.dart`: renders one history row with a clear income/expense visual distinction (design-token colors from `core/design_system/tokens.dart` — never a hardcoded color, constitution Principle XV) — an icon/label pairing so the distinction never relies on color alone (constitution Accessibility standard).
- [ ] T033 Register the `/finance/entries/new?type=income` entry point (Add Income quick action) alongside T028's route registration in `lib/core/routing/app_router.dart` (depends on T028, T031).

**Checkpoint**: User Stories 1 AND 2 both work independently — income and expense entries can each be recorded and are visually distinct.

---

## Phase 5: User Story 3 - Review History and Totals (Priority: P2)

**Goal**: A summary view shows total income, total expenses, and net for a selectable period, plus a per-category breakdown ordered largest to smallest, with filtering and correct empty/no-match states.

**Independent Test**: With a mix of income and expense entries across categories and dates already recorded, open the history/summary view and verify totals, per-category breakdown, and period filtering are all correct (spec.md US3 Independent Test).

### Tests for User Story 3 ⚠️

- [ ] T034 [P] [US3] Unit test `GetFinanceSummary`: `SUM(amountMinorUnits) ... WHERE date BETWEEN ? AND ? AND deletedAt IS NULL GROUP BY type` computed by SQL aggregate (research.md Decision 6) for "this month," "last month," and a custom range, with zero-rounding-discrepancy across a large synthetic entry set (SC-003) — in `test/features/finance/domain/usecases/get_finance_summary_test.dart`.
- [ ] T035 [P] [US3] Unit test `GetCategoryBreakdown`: per-category totals for a period, descending by amount, each carrying its share of the period total (FR-015) — in `test/features/finance/domain/usecases/get_category_breakdown_test.dart`.
- [ ] T036 [P] [US3] Unit test `GetFinanceHistory`: filters by type, categoryId, and date range correctly in combination, excludes soft-deleted rows, newest-date-first ordering, pagination (`limit`/`offset`) (FR-012/FR-013) — in `test/features/finance/domain/usecases/get_finance_history_test.dart`.
- [ ] T037 [P] [US3] `bloc_test` for `FinanceHistoryCubit`: loads summary + breakdown + history together for the default period, switches period (this month/last month/custom range) and reloads all three, applies type/category/date-range filters, distinguishes the true first-use empty state (zero entries anywhere) from the "no matching results" state (entries exist, filter matches none) (FR-017/FR-018) — in `test/features/finance/presentation/cubit/finance_history_cubit_test.dart`.

### Implementation for User Story 3

- [X] T038 [US3] Extend `finance_dao.dart` (T017) with `getSummary(DateRange)` (single `GROUP BY type` aggregate query) and `getCategoryBreakdown(DateRange)` (`GROUP BY categoryId` aggregate query, descending by amount) per research.md Decision 6 — never summed client-side in Dart (depends on T017).
- [X] T039 [US3] Extend `finance_dao.dart` with `getHistory(FinanceHistoryFilter?, limit, offset)`: filtered, paginated, newest-date-first, excludes soft-deleted rows (FR-012/FR-013) (depends on T017).
- [X] T040 [US3] Extend `finance_repository_impl.dart` (T019) with `getSummary`, `getCategoryBreakdown`, and `getHistory`, wrapping T038/T039 (depends on T019, T038, T039).
- [X] T041 [P] [US3] Implement `lib/features/finance/domain/usecases/get_finance_summary.dart`, `lib/features/finance/domain/usecases/get_category_breakdown.dart`, and `lib/features/finance/domain/usecases/get_finance_history.dart`, each wrapping the corresponding `FinanceRepository` method.
- [X] T042 Annotate T041's three use cases with `@injectable`, re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T041).
- [ ] T043 [US3] Implement `lib/features/finance/presentation/cubit/finance_history_cubit.dart` + `finance_history_state.dart`: coordinates `GetFinanceSummary` + `GetCategoryBreakdown` + `GetFinanceHistory` for the selected period/filter, resolves period presets ("this month" = first day of current month to today, "last month" = full previous calendar month, per research.md Decision 6) in Domain-adjacent Presentation logic, and distinguishes true-empty vs. no-match states (FR-017/FR-018) (depends on T041).
- [ ] T044 [P] [US3] Implement `lib/features/finance/presentation/widgets/period_selector.dart`: this month / last month / custom range picker (reuses `AppDateField` from `core/design_system`).
- [ ] T045 [P] [US3] Implement `lib/features/finance/presentation/widgets/finance_summary_card.dart`: total income / total expenses / net for the selected period, reusing `EgpFormatter` from `core/money`.
- [ ] T046 [P] [US3] Implement `lib/features/finance/presentation/widgets/category_breakdown_bar.dart`: per-category total + share, ordered largest to smallest, using `CategoryIconRegistry` (T011) for icon/color.
- [ ] T047 [US3] Implement `lib/features/finance/presentation/pages/finance_history_page.dart`: `FinanceSummaryCard` (T045), `PeriodSelector` (T044), `CategoryBreakdownBar` (T046), a `ListView.builder`-backed history list of `FinanceEntryListTile` (T032) rows, type/category/date-range filter controls, the true first-use `AppEmptyView` (FR-017, with a direct "add your first entry" action) and the distinct no-matching-results `AppEmptyView` (FR-018), loading and error-with-retry states per constitution's Complete UI States standard (depends on T043-T046).
- [ ] T048 Register the `/finance` route for `FinanceHistoryPage` in `lib/core/routing/app_router.dart`, nested under the People branch alongside T028 (depends on T028, T047).

**Checkpoint**: User Stories 1-3 all work independently — entries can be recorded and reviewed with correct totals, breakdowns, filters, and empty states.

---

## Phase 6: User Story 4 - Manage Categories (Priority: P2)

**Goal**: A starter category set exists on first use; the user can create, rename/re-icon, and remove (archive-if-used, else hard-delete) categories without losing history.

**Independent Test**: Create a custom category, use it on a new entry, then rename and archive a different category, and verify existing entries referencing archived categories still display correctly in history (spec.md US4 Independent Test).

### Tests for User Story 4 ⚠️

- [ ] T049 [P] [US4] Unit test `CreateCategory`: rejects an empty-after-trim name, returns `DuplicateCategoryFailure` when an existing *active* category of the same `type` has an identical normalized (trimmed, whitespace-collapsed, lowercased) name (FR-008, research.md Decision 5), succeeds otherwise — in `test/features/finance/domain/usecases/create_category_test.dart`.
- [ ] T050 [P] [US4] Unit test `EditCategory`: renames/re-icons without changing `type` (immutable after creation, data-model.md); confirms every `FinanceEntry` referencing the category reflects the change on next read (live FK, not a name snapshot) (FR-009) — in `test/features/finance/domain/usecases/edit_category_test.dart`.
- [ ] T051 [P] [US4] Unit test `RemoveCategory`: a category with zero referencing `FinanceEntries` (including soft-deleted ones) is hard-deleted; a category with one or more references is archived (`isArchived = true`), never deleted (FR-010, research.md Decision 4) — in `test/features/finance/domain/usecases/remove_category_test.dart`.
- [ ] T052 [P] [US4] Repository test: `CategoryRepositoryImpl.createCategory` duplicate-check scoping (same name, different `type`, is allowed — e.g. "Gift" as both an income and expense category name, research.md Decision 5) and `removeCategory`'s reference-count branch against an in-memory `NativeDatabase.memory()` — extends `test/features/finance/data/repositories/finance_repository_impl_test.dart` or a new `category_repository_impl_test.dart`.
- [ ] T053 [P] [US4] `bloc_test` for `CategoryManagementCubit`: lists active + archived categories, creates a category, shows the duplicate-name failure pointing at the existing category, renames a category, and removes a category via the archive-vs-delete branching transparently (the Cubit does not need to know which branch applied) — in `test/features/finance/presentation/cubit/category_management_cubit_test.dart`.
- [ ] T054 [P] [US4] `bloc_test` for `CategoryFormCubit`: create and edit flows, client-side validation (non-empty name, icon selected, type required only on create) — in `test/features/finance/presentation/cubit/category_form_cubit_test.dart`.

### Implementation for User Story 4

- [X] T055 [US4] Extend `finance_dao.dart` (T017) with `countEntriesForCategory(categoryId)` (includes soft-deleted rows, per research.md Decision 4), `insertCategory` (computes `normalizedName` at write time — lowercased, whitespace-collapsed, mirroring `people`'s `normalized_name` precedent), `updateCategory`, `archiveCategory`, `deleteCategory`, and a normalized-name duplicate lookup scoped to `(normalizedName, type)` among active categories only (FR-008) (depends on T017).
- [X] T056 [US4] Extend `category_repository_impl.dart` (T020) with `createCategory` (runs the FR-008 duplicate check before insert), `editCategory` (name/icon only, `type` rejected as an edit parameter), and `removeCategory` (counts references via T055, branches hard-delete vs. archive per research.md Decision 4) (depends on T020, T055).
- [X] T057 [P] [US4] Implement `lib/features/finance/domain/usecases/create_category.dart`, `lib/features/finance/domain/usecases/edit_category.dart`, `lib/features/finance/domain/usecases/remove_category.dart`, each wrapping the corresponding `CategoryRepository` method.
- [X] T058 Annotate T056/T057 with `@injectable`, re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T056, T057).
- [ ] T059 [US4] Implement `lib/features/finance/presentation/cubit/category_management_cubit.dart` + `category_management_state.dart`: lists categories by type including archived (for visibility/editing), surfaces `DuplicateCategoryFailure` from create as a validation message pointing at the existing category, invokes `RemoveCategory` without the caller needing to know which branch (archive/delete) will apply (depends on T022, T057).
- [ ] T060 [US4] Implement `lib/features/finance/presentation/cubit/category_form_cubit.dart` + `category_form_state.dart`: create mode (name + icon + type) and edit mode (name + icon only, type read-only/hidden) (depends on T057).
- [ ] T061 [P] [US4] Implement `lib/features/finance/presentation/pages/category_management_page.dart`: grouped active/archived lists per type, using `CategoryIconRegistry` (T011), an `AppConfirmDialog` before removal explaining the archive-vs-delete outcome will be automatic, reachable from the finance history page (T047) and from `finance_entry_form_page.dart`'s category picker (T026) via a "manage categories" affordance (depends on T059).
- [ ] T062 [P] [US4] Implement `lib/features/finance/presentation/pages/category_form_page.dart`: name field, icon picker (grid of `CategoryIconRegistry` keys), type selector shown only on create (depends on T060).
- [ ] T063 Register `/finance/categories` and `/finance/categories/new`/`/finance/categories/:id/edit` routes in `lib/core/routing/app_router.dart`, nested under the People branch (depends on T048, T061, T062).

**Checkpoint**: User Stories 1-4 all work independently — categories can be fully managed without ever orphaning an entry's category reference.

---

## Phase 7: User Story 5 - Edit or Delete an Entry (Priority: P3)

**Goal**: An existing entry's amount/category/date/note can be corrected; deletion requires confirmation and offers a short-window undo; totals recalculate immediately in both cases.

**Independent Test**: Edit an existing entry's amount and category, verify totals recalculate correctly, then delete a different entry and verify it disappears from history and totals while its change is auditable, with an undo option (spec.md US5 Independent Test).

### Tests for User Story 5 ⚠️

- [ ] T064 [P] [US5] Unit test `EditFinanceEntry`: updates amount/category/date/note, re-derives `type` from the (possibly new) category rather than accepting it directly (contract note in `finance_repository.md`), sets `editedAt`, rejects the same validation rules as create (FR-019) — in `test/features/finance/domain/usecases/edit_finance_entry_test.dart`.
- [ ] T065 [P] [US5] Unit test `DeleteFinanceEntry`/`RestoreFinanceEntry`: delete sets `deletedAt` immediately and commits (not deferred — research.md Decision 8's process-death-safety rationale), restore un-sets `deletedAt`, restore is a no-op success (not an error) if the entry is not currently soft-deleted (defensive against a stale/duplicate undo tap) (FR-020) — in `test/features/finance/domain/usecases/delete_finance_entry_test.dart`.
- [ ] T066 [P] [US5] `bloc_test` for `FinanceEntryFormCubit`'s edit mode: loads an existing entry (including one referencing an archived category, which must remain selectable for that entry per FR-011), saves the edit, and totals-affecting state is correctly signaled to listeners — extends `test/features/finance/presentation/cubit/finance_entry_form_cubit_test.dart`.
- [ ] T067 [P] [US5] `bloc_test` for delete/undo behavior (either on `FinanceHistoryCubit` or a dedicated flow) — confirms a delete followed by an undo tap within the window restores the entry exactly as it was, and a delete followed by the window expiring leaves it removed — in `test/features/finance/presentation/cubit/finance_history_cubit_test.dart` (extends T037).

### Implementation for User Story 5

- [X] T068 [US5] Extend `finance_dao.dart`/`finance_repository_impl.dart` (T017/T019) with `editEntry` (re-derives `type` from `categoryId`, sets `editedAt`) and `deleteEntry`/`restoreEntry` (soft-delete tombstone via `deletedAt`, immediate commit per research.md Decision 8) (depends on T017, T019).
- [X] T069 [P] [US5] Implement `lib/features/finance/domain/usecases/edit_finance_entry.dart`, `lib/features/finance/domain/usecases/delete_finance_entry.dart`, and `lib/features/finance/domain/usecases/restore_finance_entry.dart`, each wrapping the corresponding `FinanceRepository` method.
- [X] T070 Annotate T069's three use cases with `@injectable`, re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T069).
- [ ] T071 [US5] Extend `finance_entry_form_cubit.dart` (T025) with an edit mode: pre-fills from an existing `FinanceEntry`, keeps an archived category selectable for that entry only (FR-011), calls `EditFinanceEntry` instead of `AddFinanceEntry`, sets/surfaces an "edited" indicator (depends on T025, T069).
- [ ] T072 [US5] Extend `finance_history_cubit.dart` (T043) with `deleteEntry(id)` (calls `DeleteFinanceEntry` immediately, exposes a ~5-second undo window per research.md Decision 8) and `undoDelete(id)` (calls `RestoreFinanceEntry`), reloading summary/breakdown/history after either (depends on T043, T069).
- [ ] T073 [US5] Extend `finance_entry_list_tile.dart`/`finance_history_page.dart` (T032/T047) with an edit affordance (navigates to `/finance/entries/:id/edit`), a delete affordance behind `AppConfirmDialog`, and an undo `SnackBar`/inline affordance shown for the ~5-second window after a confirmed delete (depends on T047, T072).
- [ ] T074 [US5] Register the `/finance/entries/:id/edit` route for `FinanceEntryFormPage` (edit mode) in `lib/core/routing/app_router.dart` (depends on T063, T071).

**Checkpoint**: All five user stories are independently functional — the full income/expense feature is complete end-to-end.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Isolation verification, localization completeness, and the end-to-end regression the roadmap treats as this feature's highest-value test.

- [X] T075 [P] Regression test confirming FR-023: adding/editing/deleting finance entries never alters an existing `Person`'s balance or the `transactions` feature's `OverviewSummary` totals, and finance queries never join against `People`/`MoneyTransactions` — in `test/features/finance/isolation_from_transactions_test.dart`.
- [ ] T076 [P] Widget test for `FinanceEntryFormPage`: Arabic-Indic numeral input parses identically to Western digits (FR-024); zero/negative amount and missing-category validation messages render correctly in both `ar` and `en` — in `test/widget/finance_entry_form_page_test.dart`.
- [ ] T077 [P] Widget test for `CategoryManagementPage`: RTL layout, icon/color legibility in light and dark mode — in `test/widget/category_management_page_test.dart`.
- [ ] T078 Verify no `// ignore` suppressions, no hardcoded colors/strings were introduced across the `finance` feature (constitution Principle XV/XIII); run `flutter analyze` and fix any warnings.
- [X] T079 [P] Performance check: seed ~5,000 synthetic `FinanceEntries` (Scale/Scope ceiling) and confirm `GetFinanceSummary`/`GetCategoryBreakdown`/`GetFinanceHistory` each complete in <1s and the history list sustains ~60fps scroll on a mid-range-equivalent test profile — documented in `test/features/finance/performance_smoke_test.dart` or a manual quickstart note if automated profiling isn't practical in CI.
- [ ] T080 Add the finance-section entry points referenced by research.md Decision 9 to the existing `OverviewPage` (`lib/features/transactions/presentation/pages/overview_page.dart`): a lightweight "This Month" finance summary card linking to `/finance`, and confirm it does not alter `OverviewCubit`'s existing behavior (this is intentionally the minimal seam V1.5.2 Home Dashboard will later expand into `GetDashboardSnapshot` — this task only adds a reachable link, not new aggregation logic).
- [ ] T081 [P] `integration_test/finance_flows_test.dart`: end-to-end coverage of US1-US5 per quickstart.md's Manual Validation Scenarios 1-6 — add expense, add income, review history/totals/breakdown/period-switch/filter, manage categories (create/duplicate-reject/rename/archive/delete), edit/delete-with-undo/double-tap-protection, and the FR-023 isolation check.
- [ ] T082 Run `flutter test integration_test` end-to-end on an emulator/simulator and `flutter format` across all new files; confirm all quickstart.md Automated Verification commands pass clean.
- [X] T083 [P] Complete the ARB key block reserved in T002 (`lib/core/l10n/app_en.arb`/`app_ar.arb`): entry form labels, category management strings, period/summary labels, default category names (`ar`/`en` translations for all 22 seeded categories), empty/no-match/error states — confirm no hardcoded `Text("...")` remains anywhere in `lib/features/finance/` (constitution Principle XIII).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories (schema migration, shared entities, icon registry).
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion.
  - US1 (P1) and US2 (P2→ effectively P1 pairing, spec.md lists both as P1) share the same form/Cubit — US2 is a thin extension of US1, not independently built from scratch.
  - US3 (P2) depends on US1/US2 existing (entries to summarize) but its repository/use-case/Cubit work is independently addable.
  - US4 (P2) is independently buildable in parallel with US3 (categories don't require US3's summary work) but is naturally sequenced after US1 since US1 needs `GetCategories` to populate its picker (already covered in Phase 3, T016/T020/T022).
  - US5 (P3) depends on US1's `FinanceEntryFormCubit`/`FinanceHistoryPage` existing (it extends both).
- **Polish (Phase 8)**: Depends on all five user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Foundational only. No dependency on other stories.
- **US2 (P1)**: Extends US1's form/Cubit directly — build immediately after US1.
- **US3 (P2)**: Foundational + benefits from US1/US2 entries existing to display, but its own tasks (T034-T048) have no code dependency on US4/US5.
- **US4 (P2)**: Foundational + US1's `CategoryRepository.getCategories` (T016/T020/T022) already in place from Phase 3.
- **US5 (P3)**: Extends US1's form Cubit (T025) and US3's history Cubit (T043) — build after both.

### Within Each User Story

- Tests written first, confirmed to fail, then implementation (per this repo's established TDD convention, mirrored from spec 001).
- Entities/enums before repositories; repositories before use cases; use cases before Cubits; Cubits before pages/widgets.
- DI annotation + codegen (`build_runner`) after each phase's use cases are defined, before the Cubits that consume them.

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel.
- All Foundational entity/enum tasks (T006-T011) marked [P] can run in parallel once T003/T004 (migration) land.
- Once Foundational completes, US3 and US4 can be staffed in parallel (both only depend on Foundational + US1's `GetCategories`).
- All [P] test tasks within a phase can run in parallel (different files).
- All [P] domain entity/use-case tasks within a phase can run in parallel.

---

## Parallel Example: User Story 1

```bash
# Launch all US1 tests together:
Task: "Unit test AddFinanceEntry in test/features/finance/domain/usecases/add_finance_entry_test.dart"
Task: "Repository test FinanceRepositoryImpl.addEntry in test/features/finance/data/repositories/finance_repository_impl_test.dart"
Task: "bloc_test for FinanceEntryFormCubit in test/features/finance/presentation/cubit/finance_entry_form_cubit_test.dart"

# Launch US1 use cases together once repositories exist:
Task: "Implement add_finance_entry.dart"
Task: "Implement get_categories.dart"
Task: "Implement seed_default_categories.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories; includes the schema migration, the single highest-risk task in this feature since it's the only one touching a shared database file)
3. Complete Phase 3: User Story 1 (record an expense)
4. Complete Phase 4: User Story 2 (record income — thin extension of US1)
5. **STOP and VALIDATE**: Test recording both expense and income independently per quickstart.md Scenarios 1-2
6. Deploy/demo if ready — a user can already log their day-to-day spending and income, the feature's core value

### Incremental Delivery

1. Setup + Foundational → migration verified, categories seeded
2. Add US1 + US2 → Test independently → Deploy/Demo (MVP!)
3. Add US3 (history/totals/breakdown/filtering) → Test independently → Deploy/Demo
4. Add US4 (category management) → Test independently → Deploy/Demo
5. Add US5 (edit/delete/undo) → Test independently → Deploy/Demo
6. Polish (Phase 8) → full regression, localization completeness, FR-023 isolation proof

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (the schema migration in particular should not be parallelized across people — one owner, reviewed carefully).
2. Once Foundational is done:
   - Developer A: US1 → US2 → US5 (the form/edit/delete thread)
   - Developer B: US3 (history/summary/breakdown/filter thread)
   - Developer C: US4 (category management thread)
3. Stories integrate at the Cubit/page level once US1's `FinanceEntryFormCubit`/`CategoryRepository` contracts are stable (end of Phase 3).

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to specific user story for traceability.
- This feature is purely additive — no existing `people`/`transactions`/`settings`/`onboarding` code is modified except the database migration (T003/T004), the router (T028/T033/T048/T063/T074), the Overview entry-point seam (T080), and ARB key additions (T002/T083). FR-023 (T075) is the regression test guarding this boundary permanently.
- Verify tests fail before implementing.
- Commit after each task or logical group.
- Stop at any checkpoint to validate a story independently.
- Avoid: vague tasks, same-file conflicts, cross-story dependencies that break independence.
