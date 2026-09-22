---

description: "Task list template for feature implementation"
---

# Tasks: Multi-Currency Support

**Input**: Design documents from `/specs/018-multi-currency-support/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present). **Note**: this feature's tasks assume People (001), Income/Expense (007), Occasions (008), Budgets (010), and Savings Goals (011) are implemented in code — its migrations extend their existing tables. Unlike 015/016/017, this is not a standalone module; see plan.md's Project Structure and Complexity Tracking.

**Tests**: Included — this feature touches five existing features' balance/total calculations, the single highest-risk-of-silent-corruption category of change in this entire V3 batch per the constitution's Financial Domain Override; automated coverage is non-negotiable.

**Organization**: Tasks are grouped by user story (spec.md) to enable independent implementation and testing of each story, with a dedicated per-existing-feature migration phase ahead of them (research.md Decision 3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US3)
- Include exact file paths in descriptions

## Path Conventions

Mobile Flutter app (existing structure): `lib/core/money/`, `lib/features/currency/{data,domain,presentation}/`, plus extensions to `lib/features/{people,finance,occasions,budgets,savings}/`, `test/`, `integration_test/`.

---

## Phase 1: Setup

**Purpose**: Project initialization for the new `currency` module and the bundled catalog

- [ ] T001 Create the directory skeleton: `lib/features/currency/{data/{content,datasources,repositories},domain/{entities,repositories,services,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/features/currency/{domain/services,domain/usecases,data/repositories,presentation/cubit}/`.
- [ ] T002 [P] Author the bundled starter-currency catalog (`lib/features/currency/data/content/currencies.json`): EGP (non-removable), USD, EUR, SAR, AED, GBP — each with `code`, `symbol`, `nameEn`/`nameAr`, `minorUnitsPerMajor: 100`, `isRemovable` per data-model.md.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core entities, `Money`'s currency-aware extension, the pure `CurrencyConverter`, the new tables, and the `currency` feature's own repository — all of which MUST exist before either the per-feature migrations (Phase 3) or any user story can proceed

**⚠️ CRITICAL**: No per-feature migration or user story work can begin until this phase is complete

- [ ] T003 [P] Define the `Currency` entity (`code`, `symbol`, `nameEn`, `nameAr`, `minorUnitsPerMajor`, `isRemovable`) in `lib/core/money/currency.dart`, per data-model.md.
- [ ] T004 **[HIGH BLAST RADIUS]** Extend `lib/core/money/money.dart`: `Money` gains a required `currency: Currency` field (research.md Decision 2) — this is a breaking compile-time change to every existing `Money` construction call site across 001/007/008/010/011; do NOT attempt to fix all call sites in this task (that happens per-feature in Phase 3) — this task only lands the type change itself and updates `Money`'s own arithmetic operators (`add`/`subtract`/etc.) to assert matching currencies (throwing a clear `ArgumentError` on a currency mismatch, since adding two different currencies' raw minor-units together is never valid — only `CurrencyConverter` may bridge currencies).
- [ ] T005 [P] **Exhaustive unit test** `Money`'s currency-matching arithmetic: same-currency add/subtract succeed normally; cross-currency add/subtract throw a clear error — in `test/core/money/money_test.dart` (extends the existing test file, does not replace it).
- [ ] T006 Implement `CurrencyFormatter` in `lib/core/money/currency_formatter.dart` per research.md Decision 5: locale-aware, cached `NumberFormat` per (locale, currency) pair, Western-digit guarantee, currency symbol/code placement correct for RTL/LTR (constitution Principle XIII). Update `lib/core/money/egp_formatter.dart` to become a thin wrapper delegating to `CurrencyFormatter(currency: egpCurrency)`, preserving byte-identical output (FR-015/SC-008).
- [ ] T007 [P] **Regression test**: `EgpFormatter`'s output is byte-for-byte identical before/after T006's refactor, run against a fixture set of at least 20 varied amounts — in `test/core/money/egp_formatter_regression_test.dart`. This is the release-blocking anchor for SC-008.
- [ ] T008 [P] Define `PrimaryCurrencySetting`, `ExchangeRate`, `ConversionResult` (sealed: `.converted`/`.rateUnavailable`), `SumResult` (sealed: `.total`/`.blocked`) in `lib/features/currency/domain/entities/`, per data-model.md and `contracts/currency_converter.md`.
- [ ] T009 [P] Add `InvalidExchangeRateFailure`, `RateRequiredForSwitchFailure`, `CurrencyNotFoundFailure` to `lib/features/currency/domain/entities/currency_failures.dart`, extending the core `Failure`.
- [ ] T010 Implement the pure `CurrencyConverter` interface and implementation (research.md Decision 4's round-half-up rule, Decision 6's zero-repository-dependency design) in `lib/features/currency/domain/services/currency_converter.dart`: `convert()` (same-currency trivial success; direct-rate conversion; `rateUnavailable` otherwise — NEVER a 1:1 fallback) and `sumToTargetCurrency()` (all-or-nothing blocking per FR-009) — per `contracts/currency_converter.md`.
- [ ] T011 [P] **Exhaustive unit test** `CurrencyConverter`: same-currency passthrough, direct-rate conversion against hand-verified reference values, rate-unavailable case (confirm it is NEVER treated as 1:1), rounding boundary cases (values requiring round-half-up in both directions), `sumToTargetCurrency`'s all-or-nothing blocking when even one of several amounts lacks a rate — in `test/features/currency/domain/services/currency_converter_test.dart`. This is the release-blocking correctness anchor for SC-002/SC-004/FR-013.
- [ ] T012 Update `lib/core/database/app_database.dart`: add `PrimaryCurrencySetting` and `ExchangeRates` tables per data-model.md's Drift Schema Sketch (`UNIQUE INDEX idx_exchange_rates_pair` on `(currency_code, relative_to_currency_code)`); this is step 1 of the coordinated migration (research.md Decision 3) — subsequent per-feature column additions happen in Phase 3, all under the SAME `schemaVersion` increment as this task. Do not bump `schemaVersion` again in Phase 3 — one coordinated bump for the whole feature.
- [ ] T013 [P] Repository test against an in-memory `NativeDatabase.memory()`: `CurrencyRepositoryImpl`'s `setExchangeRate` upsert-by-pair uniqueness, `getPrimaryCurrency`'s EGP default — in `test/features/currency/data/repositories/currency_repository_impl_test.dart`.
- [ ] T014 Define the `CurrencyRepository` abstract interface in `lib/features/currency/domain/repositories/currency_repository.dart` per `contracts/currency_converter.md`, and implement `CurrencyRepositoryImpl` in `lib/features/currency/data/repositories/currency_repository_impl.dart` (composing a `BundledCurrencyCatalogDataSource` reading T002's JSON, plus drift DAOs for T012's tables).
- [ ] T015 Implement `lib/features/currency/domain/usecases/get_supported_currencies.dart`, `get_exchange_rates.dart`, `set_exchange_rate.dart` wrapping T014.
- [ ] T016 Register `CurrencyRepositoryImpl` (as `CurrencyRepository`), `CurrencyConverter`, and the Phase-2 use cases with `@injectable`/`@LazySingleton(as: ...)` in `lib/core/di/`; run `fvm dart run build_runner build --delete-conflicting-outputs`.
- [ ] T017 [P] Implement `CurrencyPicker` and `CurrencyIndicatorChip` in `lib/core/design_system/currency_picker.dart` / `currency_indicator_chip.dart` — the documented Principle XV exception (plan.md Complexity Tracking): built directly in `core/design_system` since five existing features need them simultaneously.
- [ ] T018 [P] Widget test for `CurrencyPicker`/`CurrencyIndicatorChip`: correct RTL/LTR symbol placement, correct localized currency names — in `test/widget/currency_picker_indicator_test.dart`.

**Checkpoint**: Foundation ready — `Money` is currency-aware (with every existing call site now a compile error, intentionally, per T004), `CurrencyConverter` is exhaustively tested, the two new tables exist, and the shared picker/indicator components exist. Per-feature migration (Phase 3) can now begin — the app will NOT compile again until each of 001/007/008/010/011 is fixed up in that phase.

---

## Phase 3: Per-Existing-Feature Migration (blocking prerequisite for all user stories)

**Purpose**: Fix every existing `Money` construction/consumption call site across the five affected features, per research.md Decision 3's "independently tested, not independently shipped" principle. This phase is NOT itself a user story — it is what makes User Stories 1-3 possible to build against real, currency-aware existing data. The app does not compile from the end of Phase 2 until this phase completes.

**⚠️ CRITICAL**: This is the highest-risk phase in this entire V3 batch (constitution Financial Domain Override) — each sub-phase below MUST pass its own existing (pre-feature) test suite unmodified in behavior (aside from now requiring a currency parameter) before moving to the next.

### 3a. People / Transactions (001)

- [ ] T019 Add `currency_code TEXT NOT NULL DEFAULT 'EGP'` to `MoneyTransactions` in the SAME migration step as T012 (research.md Decision 3 — one coordinated `schemaVersion`, backfills every pre-existing row to `EGP` explicitly per FR-002).
- [ ] T020 [P] **Migration test**: every pre-existing `MoneyTransaction` row has `currency_code = 'EGP'` post-migration, zero nulls/ambiguous values — in `test/core/database/migration_currency_support_test.dart` (extend across 3a-3e, one assertion block per table). This is the release-blocking anchor for SC-005.
- [ ] T021 Fix up `lib/features/people/data/` and `lib/features/people/domain/`: every `Money` construction/consumption now supplies/reads `currency`; `PersonRepository`'s balance-aggregation query (`balance_queries.dart`) composes `CurrencyConverter.sumToTargetCurrency()` against the primary currency, returning a `SumResult`-aware balance type that surfaces the blocked/rate-needed state (FR-009) up through to `GetPersonBalance`/`GetOverview`'s existing use cases.
- [ ] T022 [P] **Extend** (do not duplicate) `people`'s existing unit/Cubit test suites with multi-currency scenarios: a person with transactions in 2+ currencies, one with a missing rate (blocked total), one fully convertible (correct sum) — per contracts/currency_converter.md's `SumResult`.
- [ ] T023 Update the transaction entry form (`lib/features/people/presentation/` or `lib/features/transactions/presentation/`) to include `CurrencyPicker` (T017) defaulting to primary currency; update the transaction history list and person-balance display to show `CurrencyIndicatorChip` per record (FR-010) and a `RateNeededBanner` (T032, built in Phase 2's sibling — see note) when the balance total is blocked.

### 3b. Income/Expense (007)

- [ ] T024 Add `currency_code TEXT NOT NULL DEFAULT 'EGP'` to `FinanceEntries` in the same coordinated migration (T012/T019).
- [ ] T025 Fix up `lib/features/finance/data/` and `domain/`: `FinanceRepository`'s summary/category-breakdown queries compose `CurrencyConverter`; entry form gains `CurrencyPicker`; breakdown/summary screens gain `CurrencyIndicatorChip`/`RateNeededBanner`.
- [ ] T026 [P] **Extend** `finance`'s existing test suites with multi-currency scenarios (mirrors T022).

### 3c. Occasions (008)

- [ ] T027 Add `currency_code TEXT NOT NULL DEFAULT 'EGP'` to the occasion-contribution table in the same coordinated migration.
- [ ] T028 Fix up `lib/features/occasions/data/` and `domain/`: occasion-totals computation composes `CurrencyConverter`; contribution form gains `CurrencyPicker`; totals/history screens gain `CurrencyIndicatorChip`/`RateNeededBanner`.
- [ ] T029 [P] **Extend** `occasions`' existing test suites with multi-currency scenarios (mirrors T022).

### 3d. Budgets (010)

- [ ] T030 Add `currency_code TEXT NOT NULL DEFAULT 'EGP'` to `Budgets` in the same coordinated migration.
- [ ] T031 Fix up `lib/features/budgets/data/` and `domain/`: `GetBudgetOverview`-equivalent composes `CurrencyConverter` for both per-category (planned vs. actual, which may differ in currency) and aggregate totals; budget form gains `CurrencyPicker`; overview screen gains `CurrencyIndicatorChip`/`RateNeededBanner`.
- [ ] T032 [P] Implement `RateNeededBanner` in `lib/features/currency/presentation/widgets/rate_needed_banner.dart` (the shared "blocked total" indicator reused across all five affected features, referenced by T023/T025/T028/T031/T035) — built once here, consumed everywhere.
- [ ] T033 [P] **Extend** `budgets`' existing test suites with multi-currency scenarios (mirrors T022).

### 3e. Savings Goals (011)

- [ ] T034 Add `currency_code TEXT NOT NULL DEFAULT 'EGP'` to `SavingsGoals`, and `entered_currency_code TEXT NOT NULL DEFAULT 'EGP'` + `goal_currency_amount_minor_units INTEGER NOT NULL DEFAULT 0` (backfilled = `amount_minor_units`) to `SavingsContributions`, in the same coordinated migration, per data-model.md's one-currency-per-goal design.
- [ ] T035 Fix up `lib/features/savings/data/` and `domain/`: `SavingsGoal`/`SavingsContribution` entities gain the entered-vs-goal-currency distinction (data-model.md); `GetSavingsOverview`'s combined total composes `CurrencyConverter`; a contribution logged in a different currency than its goal converts to the goal's currency AT LOG TIME (spec Edge Cases) via `CurrencyConverter`, storing both `enteredAmount` (FR-010's own-record display) and `goalCurrencyAmount` (what progress math sums); goal/contribution forms gain `CurrencyPicker`; overview gains `CurrencyIndicatorChip`/`RateNeededBanner`. **`ProjectSavingsCompletion`/the what-if calculator itself is explicitly NOT modified to call `CurrencyConverter`** (FR-011) — verify by code review that it continues operating purely on already-goal-currency-normalized figures.
- [ ] T036 [P] **Extend** `savings`' existing test suites with multi-currency scenarios, PLUS a dedicated test confirming `ProjectSavingsCompletion`'s pure function signature/imports are unchanged by this feature (structural non-regression check for FR-011) — extend `test/features/savings/domain/services/savings_calculator_test.dart`.

**Checkpoint**: The app compiles again. Every existing feature is now currency-aware, every pre-existing row is explicitly EGP, and every existing test suite passes with its multi-currency extensions. User story implementation (which is now mostly about the NEW `currency` settings screens) can proceed.

---

## Phase 4: User Story 1 - Record an Amount in a Non-Primary Currency (Priority: P1) 🎯 MVP (part 1 of 3)

**Goal**: Verify, end-to-end, that a user can actually pick and save a non-primary currency on a new record in every affected feature, and that an EGP-only user sees zero change.

**Independent Test**: Record a new amount in a non-primary currency in each of the five features; confirm it saves and displays correctly; confirm an all-EGP user's flow is unchanged.

**Note**: Much of this story's actual implementation already landed in Phase 3 (the `CurrencyPicker` wiring per feature) — this phase is primarily its dedicated cross-feature verification and the one remaining piece, the currency-settings entry point's own default-currency-source wiring.

### Tests for User Story 1 ⚠️

- [ ] T037 [P] [US1] Cross-feature widget test confirming `CurrencyPicker` defaults to the current `PrimaryCurrencySetting` on every one of the five affected features' entry forms — in `test/widget/currency_picker_default_test.dart`.
- [ ] T038 [P] [US1] **Regression test**: a full EGP-only flow (create person, transaction, income entry, budget, savings goal — never touching the currency picker) produces byte-for-byte identical saved records/displays to a snapshot of pre-feature behavior — in `test/features/currency/no_op_for_egp_only_user_test.dart`. Release-blocking anchor for FR-015/SC-008.

### Implementation for User Story 1

- [ ] T039 [US1] Verify (and fix any gaps found) that every one of the five entry forms touched in Phase 3 (T023/T025/T028/T031/T035) correctly wires `CurrencyPicker`'s default to `GetSupportedCurrencies`/`GetPrimaryCurrency` (T015) rather than a hardcoded EGP default — this is the one piece of US1 not already covered by Phase 3's per-feature fix-up, since Phase 3 focused on making the picker PRESENT, not on confirming its default-value SOURCE is live.

**Checkpoint**: User Story 1 independently testable — recording a non-primary-currency amount works correctly everywhere, and an EGP-only user's experience is provably unchanged.

---

## Phase 5: User Story 2 - See Aggregated Totals Correctly Across Currencies (Priority: P1) 🎯 MVP (part 2 of 3)

**Goal**: Every aggregate total across all five features correctly converts-and-sums or clearly blocks, consistently.

**Independent Test**: Mix currencies feeding a single aggregate; confirm correct conversion when all rates exist, correct blocking when one doesn't, and correct unblocking once the missing rate is added.

**Note**: Also largely landed in Phase 3 (each feature's `CurrencyConverter` composition) — this phase is the dedicated cross-feature consistency verification.

### Tests for User Story 2 ⚠️

- [ ] T040 [P] [US2] **Cross-feature consistency test**: the identical missing-rate scenario (one record in an unconfigured currency) produces the identical `RateNeededBanner` blocked-state behavior on all five of: Person balance (001), Overview (001), Finance summary (007), a Budget total (010), Savings overview (011) — in `test/features/currency/cross_feature_blocking_consistency_test.dart`. This is the release-blocking anchor for FR-008's "no aggregate screen is exempt."
- [ ] T041 [P] [US2] **Cross-feature consistency test**: the identical fully-convertible multi-currency scenario produces mathematically consistent totals across the same five screens (each independently converts the same underlying amounts to the same primary currency using the same rate — verified by comparing raw computed figures, not just UI presence) — extend the same test file.

### Implementation for User Story 2

- [ ] T042 [US2] Verify (and fix any gaps found) that every one of the five aggregation call sites fixed in Phase 3 correctly surfaces `SumResult.blocked`'s specific missing-currency list through to `RateNeededBanner` (T032) rather than a generic "error" state — the banner must name which currency needs a rate (FR-009), not just that something is wrong.

**Checkpoint**: User Story 2 independently testable — aggregation is correct and consistently blocking across every affected screen in the app.

---

## Phase 6: User Story 3 - Set the Primary Currency and Manage Exchange Rates (Priority: P1) 🎯 MVP (part 3 of 3)

**Goal**: The user has a real settings surface to manage the primary currency and exchange rates, including the FR-012 forced-rate-on-switch flow.

**Independent Test**: Open currency settings, change primary currency (triggering the forced-rate flow when needed), add/edit/remove rates, confirm each change's effect on subsequent aggregation.

### Tests for User Story 3 ⚠️

- [ ] T043 [P] [US3] Unit test `SetPrimaryCurrency`: succeeds trivially when no existing record uses the current primary currency; requires `rateForPreviousPrimary` (or fails with `RateRequiredForSwitchFailure`) when records exist and no reverse rate is configured (FR-012) — in `test/features/currency/domain/usecases/set_primary_currency_test.dart`. This use case's cross-feature "is this currency used anywhere" check is mocked against all five repositories.
- [ ] T044 [P] [US3] Unit test `SetExchangeRate`/`GetExchangeRates`: rejects zero/negative rate (FR-006), upserts by pair, `lastUpdatedAt` updates on edit (FR-007's own timestamp requirement) — in `test/features/currency/domain/usecases/set_exchange_rate_test.dart`.
- [ ] T045 [P] [US3] `bloc_test` for `PrimaryCurrencyCubit`, `ExchangeRateListCubit`, `ExchangeRateFormCubit`: happy paths, the forced-rate-on-switch prompt flow, validation rejections, duplicate-tap protection — in `test/features/currency/presentation/cubit/`.

### Implementation for User Story 3

- [ ] T046 [US3] Implement `lib/features/currency/domain/usecases/set_primary_currency.dart` (the `SetPrimaryCurrency` implementation, per `contracts/currency_converter.md`): the one cross-feature-reading use case in this entire feature (read-only "is this currency used" checks against 001/007/008/010/011's repositories, mirroring 017's `GetPrefillableSavingsGoalAmount` isolation pattern) (depends on T014, T021, T025, T028, T031, T035 — needs all five repositories' read interfaces available).
- [ ] T047 Annotate the US3 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T046).
- [ ] T048 [US3] Implement `lib/features/currency/presentation/cubit/primary_currency_cubit.dart`: loads current primary currency, change action calling `SetPrimaryCurrency` (T046), surfaces the `RateRequiredForSwitchFailure` as an inline prompt to enter the needed rate before retrying the switch (depends on T046, T047).
- [ ] T049 [P] [US3] Implement `lib/features/currency/presentation/cubit/exchange_rate_list_cubit.dart` and `exchange_rate_form_cubit.dart` wrapping T015's `GetExchangeRates`/`SetExchangeRate` use cases, disables Save immediately on tap (constitution Duplicate Action Protection) (depends on T015).
- [ ] T050 [US3] Implement `lib/features/currency/presentation/pages/currency_settings_page.dart` (primary currency display + change action), `exchange_rate_list_page.dart` (list with last-updated timestamps, manual/not-auto-fetched disclosure per FR-007), `exchange_rate_form_page.dart` (add/edit, validation) (depends on T048, T049).
- [ ] T051 Register `/settings/currency`, `/settings/currency/rates`, `/settings/currency/rates/:code/edit` routes in `lib/core/routing/app_router.dart`, and add a "Currency" entry point from `lib/features/settings/presentation/pages/settings_page.dart` (depends on T050).

**Checkpoint**: All three P1 user stories independently functional — together they form this feature's full scope (spec.md has no P2/P3 story; all three are foundational and mutually necessary).

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Localization completeness, theming, performance, full regression, and final constitution compliance pass

- [ ] T052 [P] Add all currency-settings strings (primary currency picker, exchange rate list/form, forced-rate-switch prompt, "manual, not auto-fetched" disclosure) plus `RateNeededBanner` copy (reused across five features) to `lib/core/l10n/app_en.arb`/`app_ar.arb`; regenerate `AppLocalizations` (FR-016).
- [ ] T053 [P] RTL/LTR and theme pass: verify `CurrencySettingsPage`, `ExchangeRateListPage`/`ExchangeRateFormPage`, `CurrencyPicker`, `CurrencyIndicatorChip`, and `RateNeededBanner` across ALL FIVE affected features' screens render correctly in Arabic RTL and English LTR, and in both light and dark mode, with special attention to currency symbol/code placement (FR-016, SC-007).
- [ ] T054 [P] Zero-network-activity audit pass across every currency-settings action and every aggregation view (mirrors 016's/017's own pattern) confirming this feature makes no network call anywhere (FR-014, SC-006).
- [ ] T055 Write `integration_test/currency_flows_test.dart` covering: set primary currency, add/edit/remove exchange rate, forced-rate-on-switch (FR-012), rate deletion re-blocks a total — per quickstart.md Scenario 3. Extend each of `people_flows_test.dart`/`finance_flows_test.dart`/`occasions_flows_test.dart`/`budgets_flows_test.dart`/`savings_flows_test.dart` (001/007/008/010/011's own existing integration suites, if implemented) with one multi-currency scenario each — per quickstart.md Scenario 2.
- [ ] T056 Full-installation migration test: seed a pre-feature-shaped database with at least 100 records spanning all five features (per SC-005), run the migration, assert zero ambiguous-currency records — extend `test/core/database/migration_currency_support_test.dart` (T020) to this full-scale scenario.
- [ ] T057 Run `fvm flutter analyze` and `fvm flutter format`, fix all warnings (no `// ignore` suppressions without a documented reason).
- [ ] T058 Run the full `fvm flutter test` suite and `fvm flutter test integration_test`; confirm all pass, with special attention to T005/T007 (Money/EgpFormatter regression), T011 (CurrencyConverter), T020/T056 (migration), T038 (EGP-only no-op regression), and T040/T041 (cross-feature consistency).
- [ ] T059 Code-review pass against the constitution's Definition of Done and the Financial Domain Override specifically: confirm every one of 001/007/008/010/011's own pre-existing balance/total FORMULA is textually unchanged (only a `CurrencyConverter` composition step was inserted ahead of the sum, per FR-017) — diff each feature's aggregation query/use case against its pre-feature version; confirm `ProjectSavingsCompletion` (011) has zero new imports/dependencies (FR-011); confirm no call site anywhere silently defaults a missing rate to 1:1 (grep for any such fallback pattern); confirm the one cross-feature-reading use case (`SetPrimaryCurrency`) is read-only.

---

## Dependencies & Execution Order

- **Phase 1 (Setup)** → **Phase 2 (Foundational)** → **Phase 3 (Per-Feature Migration)**: strictly sequential — Phase 3 cannot start until `Money`/`CurrencyConverter`/the new tables exist (Phase 2), and the app does not compile between the end of Phase 2 and the completion of Phase 3 (T004's intentional breaking change).
- **Within Phase 3**: sub-phases 3a-3e (one per existing feature) are mutually independent of EACH OTHER (each touches a disjoint set of files) and may be staffed in parallel by different contributors, though all must complete before Phase 4-6 begin, since those phases' verification tasks assume all five are currency-aware.
- **Phase 4 (US1)**, **Phase 5 (US2)**, **Phase 6 (US3)** are mutually independent in principle (each verifies/builds a different slice) but in practice Phase 6's `SetPrimaryCurrency` (T046) needs read access to all five repositories, which only exist post-Phase-3 — so all three of Phase 4-6 are gated on Phase 3's completion, not on each other.
- **Phase 7 (Polish)** runs last.

## Parallel Execution Examples

- Within Phase 2: T003, T008, T009 in parallel; T005, T007, T011, T013, T018 (test tasks) in parallel with each other once their respective implementation tasks land.
- Within Phase 3: 3a/3b/3c/3d/3e (T019-T036) can be staffed as five parallel workstreams by five different contributors, since each touches a disjoint feature directory — the single shared coordination point is the ONE migration file (T012/T019/T024/T027/T030/T034 all land in the same `vNN_currency_support.dart`, requiring sequential merge coordination even though the FEATURE-side fix-up code in each sub-phase is independent).
- Within Phase 6: T043-T045 (test tasks) in parallel; T049 in parallel with T046 (different files).

## Implementation Strategy

**MVP first, but this feature's MVP is unusually monolithic**: Unlike 015/016/017, Phases 1-6 together form this feature's actual MVP — spec.md defines all three user stories as P1 (recording, aggregating, and managing rates are mutually necessary; none is independently useful without the other two, since recording a non-primary-currency amount with no way to aggregate or set a rate for it is an incomplete, confusing half-feature). Phase 3 (the five-feature migration) is the true bulk of this feature's implementation effort and risk — budget review/testing time accordingly, consistent with the constitution's Financial Domain Override treating this class of change as the least acceptable place for a defect in this entire V3 batch. Phase 7 always runs last.
