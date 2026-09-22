---

description: "Task list template for feature implementation"
---

# Tasks: Financial Education & Wealth Planning

**Input**: Design documents from `/specs/016-financial-education-wealth-planning/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included — the calculators' correctness and the non-personalization/disclaimer boundaries are the feature's core compliance guarantees and warrant explicit automated coverage, matching the precedent set by 011-savings-goals.

**Organization**: Tasks are grouped by user story (spec.md) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US4)
- Include exact file paths in descriptions

## Path Conventions

Mobile Flutter app (existing structure): `lib/features/financial_education/{data,domain,presentation}/`, `test/features/financial_education/`, `integration_test/`.

---

## Phase 1: Setup

**Purpose**: Project initialization and directory structure

- [ ] T001 Create the directory skeleton: `lib/features/financial_education/{data/{content/{en,ar}/articles,datasources,repositories},domain/{entities,repositories,services,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/features/financial_education/{domain/services,domain/usecases,data/repositories,presentation/cubit}/`.
- [ ] T002 [P] Author `lib/features/financial_education/data/content/en/categories.json` and `ar/categories.json`: 3 categories (`budgeting_basics`, `saving_strategies`, `understanding_investment_concepts`) per research.md Decision 2, each with `id`/`title`/`shortDescription`/`articleIds`, in both locales with matching ids.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core entities, the content repository, and the three pure calculator services that MUST exist before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 [P] Define the `EducationCategory` entity (`id`, `title`, `shortDescription`, `articleIds`) in `lib/features/financial_education/domain/entities/education_category.dart`, per data-model.md.
- [ ] T004 [P] Define the `EducationArticle` entity (`id`, `categoryId`, `title`, `shortDescription`, `bodySections: List<ArticleSection>`) and the `ArticleSection` value object (`heading?`, `paragraphs`) in `lib/features/financial_education/domain/entities/education_article.dart`, per data-model.md.
- [ ] T005 [P] Define `CompoundGrowthResult` (`futureValueMinorUnits`, `totalContributedMinorUnits`, `totalGrowthMinorUnits`, `isHighRateWarningShown`), `DoublingTimeResult` (`approximateDoublingYears`), `SavingsRateResult` (`savingsRatePercent`) value objects in `lib/features/financial_education/domain/entities/calculator_results.dart`, per data-model.md.
- [ ] T006 [P] Define `CalculatorValidationResult<T>` (`.success(value)` / `.invalid(problem)`) and the `CalculatorInputProblem` enum (`nonPositiveAmount`, `negativeRate`, `nonPositiveDuration`, `nonPositiveIncome`, `nonPositiveRate`) in `lib/features/financial_education/domain/entities/calculator_validation_result.dart`, per contracts/education_content_repository.md.
- [ ] T007 [P] Add `ContentNotFoundFailure`, `ContentAssetLoadFailure` to `lib/features/financial_education/domain/entities/education_failures.dart`, extending the core `Failure`.
- [ ] T008 Implement the pure `CompoundGrowthCalculator` interface and implementation (research.md Decision 4's formula, zero repository dependency per research.md Decision 3) in `lib/features/financial_education/domain/services/compound_growth_calculator.dart`: rejects `monthlyContributionMinorUnits <= 0` (FR-008), rejects `annualRatePercent < 0` (FR-008), rejects `years <= 0` (FR-008), handles the `monthlyRate == 0` degenerate case explicitly (research.md Decision 4), sets `isHighRateWarningShown = true` above the 30% sanity-check threshold (FR-010, spec.md Assumptions) — per `contracts/education_content_repository.md`.
- [ ] T009 [P] **Exhaustive unit test** `CompoundGrowthCalculator` against known reference values (monthly 1,000 EGP / 10% annual / 10 years — verify against the standard future-value-of-annuity formula by hand-calculation in the test's own comment), the 0%-rate degenerate branch, each individual rejection case (zero/negative monthly amount, negative rate, zero/negative years), and the high-rate-warning threshold boundary (29% vs 31%) — in `test/features/financial_education/domain/services/compound_growth_calculator_test.dart`. This is the release-blocking correctness anchor for SC-002.
- [ ] T010 Implement the pure `DoublingTimeCalculator` (rule of 72, FR-011) in `lib/features/financial_education/domain/services/doubling_time_calculator.dart`: rejects `annualRatePercent <= 0`.
- [ ] T011 [P] **Exhaustive unit test** `DoublingTimeCalculator`: 8% → 9 years, boundary rejection at exactly 0 and at a negative rate — in `test/features/financial_education/domain/services/doubling_time_calculator_test.dart`.
- [ ] T012 Implement the pure `SavingsRateCalculator` (FR-012) in `lib/features/financial_education/domain/services/savings_rate_calculator.dart`: rejects `incomeMinorUnits <= 0`; explicitly accepts (never clamps) `savingsAmountMinorUnits > incomeMinorUnits`.
- [ ] T013 [P] **Exhaustive unit test** `SavingsRateCalculator`: 20,000/5,000 → 25%, the >100% case (25,000 savings against 20,000 income → 125%, verify NOT clamped/rejected), zero-income rejection — in `test/features/financial_education/domain/services/savings_rate_calculator_test.dart`.
- [ ] T014 Implement `BundledEducationContentDataSource` in `lib/features/financial_education/data/datasources/bundled_education_content_data_source.dart`: loads `categories.json` and per-article JSON files from `rootBundle` for the currently active app language, maps JSON to `EducationCategory`/`EducationArticle`, returns `ContentAssetLoadFailure` on a parse error.
- [ ] T015 [P] Repository test using a test-fixture bundled asset set (a small deterministic `categories.json` + 1-2 article files under the test tree) confirming correct category/article retrieval and `ContentNotFoundFailure` for an unknown id — in `test/features/financial_education/data/repositories/education_content_repository_impl_test.dart`.
- [ ] T016 Define the `EducationContentRepository` abstract interface in `lib/features/financial_education/domain/repositories/education_content_repository.dart` per `contracts/education_content_repository.md`, and implement `EducationContentRepositoryImpl` in `lib/features/financial_education/data/repositories/education_content_repository_impl.dart` composing `BundledEducationContentDataSource` (T014).
- [ ] T017 Implement `lib/features/financial_education/domain/usecases/get_education_categories.dart` and `get_article.dart`, wrapping T016.
- [ ] T018 Register `EducationContentRepositoryImpl` (as `EducationContentRepository`), `BundledEducationContentDataSource`, `CompoundGrowthCalculator`, `DoublingTimeCalculator`, `SavingsRateCalculator`, and the two US1-adjacent use cases with `@injectable`/`@LazySingleton(as: ...)` in `lib/core/di/`; run `fvm dart run build_runner build --delete-conflicting-outputs`.
- [ ] T019 [P] Implement `lib/features/financial_education/presentation/widgets/persistent_disclaimer_banner.dart`: an always-rendered (never a dismiss-and-hide-forever) banner/element per FR-015/FR-016 — no internal state field capable of permanently suppressing it (structural enforcement, not just a UI default).

**Checkpoint**: Foundation ready — content repository, all three exhaustively-tested pure calculator services, and the always-rendered disclaimer widget all exist. User story implementation can now begin.

---

## Phase 3: User Story 1 - Browse and Read Educational Content (Priority: P1) 🎯 MVP (part 1 of 2)

**Goal**: A user can browse categories, open articles, and read full content, fully offline, with the disclaimer visible throughout.

**Independent Test**: Open the Financial Education section, browse categories, open an article, confirm content renders correctly with the disclaimer visible and zero network activity.

### Tests for User Story 1 ⚠️

- [ ] T020 [P] [US1] Unit test `GetEducationCategories`/`GetArticle`: correct pass-through to the repository, `ContentNotFoundFailure` surfaced correctly for an unknown article id — in `test/features/financial_education/domain/usecases/get_categories_article_test.dart`.
- [ ] T021 [P] [US1] `bloc_test` for `ContentLibraryCubit`/`ArticleCubit`: loading/success/error states (constitution: complete UI states), correct category/article data shape — in `test/features/financial_education/presentation/cubit/content_library_cubit_test.dart` and `article_cubit_test.dart`.
- [ ] T022 [P] [US1] Widget test confirming `PersistentDisclaimerBanner` (T019) renders on `ContentLibraryHomePage`, `CategoryPage`, and `ArticlePage`, across two separate simulated navigations to each (SC-003) — in `test/widget/financial_education_disclaimer_test.dart` (this file grows further in later phases as more screens are added).

### Implementation for User Story 1

- [ ] T023 [US1] Implement `lib/features/financial_education/presentation/cubit/content_library_cubit.dart` + state (loading/success/error) wrapping `GetEducationCategories` (T017) (depends on T017, T018).
- [ ] T024 [US1] Implement `lib/features/financial_education/presentation/cubit/article_cubit.dart` + state wrapping `GetArticle` (T017) (depends on T017, T018).
- [ ] T025 [P] [US1] Implement `lib/features/financial_education/presentation/widgets/article_list_tile.dart` (title + short description, per FR-003).
- [ ] T026 [US1] Implement `lib/features/financial_education/presentation/pages/content_library_home_page.dart` (category list + `PersistentDisclaimerBanner`, T019) and `category_page.dart` (article list via `ArticleListTile`, T025, + banner) (depends on T023, T025, T019).
- [ ] T027 [US1] Implement `lib/features/financial_education/presentation/pages/article_page.dart` (renders `bodySections` with headings/paragraphs + banner) (depends on T024, T019).
- [ ] T028 Register `/financial-education`, `/financial-education/:categoryId`, `/financial-education/:categoryId/:articleId` routes in `lib/core/routing/app_router.dart`, and add the navigation entry point (research.md Decision 5 — e.g. a Settings row or Home card) (depends on T026, T027).

**Checkpoint**: User Story 1 fully functional and independently testable — the content library is browsable end-to-end, fully offline, with the disclaimer present throughout.

---

## Phase 4: User Story 2 - Run a Compound-Growth "What If" Calculator (Priority: P1) 🎯 MVP (part 2 of 2)

**Goal**: A user can run the compound-growth calculator with manual inputs (or an optional Savings Goal pre-fill), see a correct, clearly-illustrative result, and be blocked from computing with invalid inputs.

**Independent Test**: Enter a monthly amount, rate, and duration; confirm the projected total, breakdown, and illustrative-disclaimer note are all correct and deterministic.

### Tests for User Story 2 ⚠️

- [ ] T029 [P] [US2] Unit test `CalculateCompoundGrowth` use case: thin wrapper correctness around `CompoundGrowthCalculator` (T008) — in `test/features/financial_education/domain/usecases/calculate_compound_growth_test.dart`.
- [ ] T030 [P] [US2] Unit test `GetPrefillableSavingsGoalAmount`: returns `null` when `SavingsRepository` (011) reports zero active goals or is otherwise unavailable in this build (graceful degradation, Edge Cases), returns the most-recently-created active goal's current amount otherwise, and is verified via mock to make no write calls whatsoever to `SavingsRepository` (read-only, FR-014) — in `test/features/financial_education/domain/usecases/get_prefillable_savings_goal_amount_test.dart`.
- [ ] T031 [P] [US2] `bloc_test` for `CompoundGrowthCalculatorCubit`: valid-input success, each individual validation rejection (zero/negative monthly, negative rate, zero/negative years) surfaced as a clear inline error (not a thrown exception), high-rate-warning note appears above the threshold, determinism (same inputs submitted twice produce an identical result object), pre-fill-then-overwrite flow — in `test/features/financial_education/presentation/cubit/compound_growth_calculator_cubit_test.dart`.

### Implementation for User Story 2

- [ ] T032 [P] [US2] Implement `lib/features/financial_education/domain/usecases/calculate_compound_growth.dart` wrapping `CompoundGrowthCalculator` (T008).
- [ ] T033 [P] [US2] Implement `lib/features/financial_education/domain/usecases/get_prefillable_savings_goal_amount.dart`: the ONE use case in this feature depending on `SavingsRepository` (011, read-only, injected exactly like any other cross-feature dependency per plan.md) — returns `null` gracefully when unavailable/empty (FR-014, Edge Cases).
- [ ] T034 Annotate the US2 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T032, T033).
- [ ] T035 [US2] Implement `lib/features/financial_education/presentation/cubit/compound_growth_calculator_cubit.dart` + state: form-input state (monthly/rate/years), optional pre-fill action calling T033 into a freely-editable starting-amount field, calculate action calling T032, maps `CalculatorValidationResult.invalid` to a clear per-field error state (depends on T032-T034).
- [ ] T036 [P] [US2] Implement `lib/features/financial_education/presentation/widgets/calculator_result_card.dart` (contributed-vs-growth breakdown + illustrative-disclaimer note + high-rate note, FR-009/FR-010).
- [ ] T037 [US2] Implement `lib/features/financial_education/presentation/pages/compound_growth_calculator_page.dart`: input form, optional pre-fill button (visible only when T033 returns non-null), `CalculatorResultCard` (T036), `PersistentDisclaimerBanner` (T019) (depends on T035, T036, T019).
- [ ] T038 Register `/financial-education/calculators/compound-growth` route in `lib/core/routing/app_router.dart`, linked from the content library home (T026) (depends on T037).
- [ ] T039 [US2] Extend the disclaimer-presence widget test (T022) to cover `CompoundGrowthCalculatorPage` across two separate visits (SC-003) — extend `test/widget/financial_education_disclaimer_test.dart`.

**Checkpoint**: User Stories 1 AND 2 together deliver the full P1 MVP — a browsable content library and the feature's signature deterministic calculator, both fully offline and disclaimer-protected.

---

## Phase 5: User Story 3 - Run a Simple Effective-Savings-Rate / Rule-of-Thumb Calculator (Priority: P2)

**Goal**: A user can run the doubling-time and effective-savings-rate calculators with correct, purely manual-input, deterministic results.

**Independent Test**: Enter a rate into the doubling-time calculator and an income/savings pair into the savings-rate calculator; confirm both compute correctly, including the >100% savings-rate case.

### Tests for User Story 3 ⚠️

- [ ] T040 [P] [US3] Unit test `CalculateDoublingTime`/`CalculateSavingsRate` use cases: thin wrapper correctness around T010/T012 — in `test/features/financial_education/domain/usecases/calculate_doubling_time_savings_rate_test.dart`.
- [ ] T041 [P] [US3] `bloc_test` for `DoublingTimeCalculatorCubit`/`SavingsRateCalculatorCubit`: valid-input success, rejection cases surfaced as clear inline errors, the >100% savings-rate case explicitly asserted as accepted-not-clamped (FR-012/Edge Cases) — in `test/features/financial_education/presentation/cubit/doubling_time_calculator_cubit_test.dart` and `savings_rate_calculator_cubit_test.dart`.

### Implementation for User Story 3

- [ ] T042 [P] [US3] Implement `lib/features/financial_education/domain/usecases/calculate_doubling_time.dart` wrapping T010, and `calculate_savings_rate.dart` wrapping T012.
- [ ] T043 Annotate the US3 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T042).
- [ ] T044 [US3] Implement `lib/features/financial_education/presentation/cubit/doubling_time_calculator_cubit.dart` and `savings_rate_calculator_cubit.dart` + states (depends on T042, T043).
- [ ] T045 [US3] Implement `lib/features/financial_education/presentation/pages/doubling_time_calculator_page.dart` and `savings_rate_calculator_page.dart`, each with `CalculatorResultCard` (T036) and `PersistentDisclaimerBanner` (T019) (depends on T044, T036, T019).
- [ ] T046 Register `/financial-education/calculators/doubling-time` and `/financial-education/calculators/savings-rate` routes in `lib/core/routing/app_router.dart`, linked from the content library home (T026) (depends on T045).
- [ ] T047 [US3] Extend the disclaimer-presence widget test (T022/T039) to cover both new calculator pages across two separate visits each (SC-003) — extend `test/widget/financial_education_disclaimer_test.dart`.

**Checkpoint**: User Story 3 independently testable — both lightweight calculators are complete alongside the compound-growth calculator, all sharing the same result-card and disclaimer patterns.

---

## Phase 6: User Story 4 - Understand the Feature's Boundaries via the Persistent Disclaimer (Priority: P2)

**Goal**: Verify, structurally and via content audit, that the non-personalization boundary and disclaimer persistence hold across every screen this feature introduces — not a new screen of its own, but a cross-cutting verification pass over US1-US3's output.

**Independent Test**: Navigate to every screen introduced by this feature and confirm the disclaimer is present on every visit; confirm no screen anywhere collects risk-tolerance/income-profiling/net-worth data used to tailor content or results.

### Tests for User Story 4 ⚠️

- [ ] T048 [US4] Consolidate and finalize `test/widget/financial_education_disclaimer_test.dart` (extended incrementally in T022/T039/T047) into one comprehensive suite asserting `PersistentDisclaimerBanner` renders on ALL 6 screens (library home, category, article, and all 3 calculators), across two separate widget-pump cycles per screen, with no code path capable of hiding it after a first render (SC-003).
- [ ] T049 [P] [US4] Static/structural test (or a documented code-review checklist item run as a script) confirming no `EducationContentRepository`, `CompoundGrowthCalculator`, `DoublingTimeCalculator`, or `SavingsRateCalculator` file imports `TransactionRepository`, `FinanceRepository`, or any risk-profiling type — a grep-based assertion in `test/features/financial_education/architecture_boundary_test.dart` verifying research.md Decision 3's structural guarantee holds (FR-004/FR-005/FR-013).

### Implementation for User Story 4

- [ ] T050 [US4] Full content-and-copy audit of every `en`/`ar` article body (T002 and all articles authored across Phase 1-5) and every calculator result/disclaimer string: verify zero instances of naming a specific investment product/asset/platform, zero directive ("you should...") phrasing, and zero personal-profiling input fields anywhere in the feature — document the audit outcome in a short review note referenced by this task; fix any violation found directly in the content/copy files. This is the release-blocking manual verification for SC-004, run once all content/copy exists (i.e., after Phases 3-5).

**Checkpoint**: User Story 4 independently verified — the feature's core compliance guarantees (persistent disclaimer, non-personalization) hold both structurally (T049) and by content audit (T050) across every screen.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Localization completeness, theming, performance, full regression, and final constitution compliance pass

- [ ] T051 [P] Author the remaining articles for all 3 categories per research.md Decision 2's content plan (target: 3-4 articles per category, both `en`/`ar`, 300-800 words each) under `lib/features/financial_education/data/content/{en,ar}/articles/`.
- [ ] T052 [P] Add all UI-chrome strings (calculator labels/hints, disclaimer text, nav entry label, validation-error copy) to `lib/core/l10n/app_en.arb` and `app_ar.arb`; regenerate `AppLocalizations` (FR-018). Article body content itself stays in the bundled JSON per research.md Decision 1, not in the ARB files.
- [ ] T053 [P] RTL/LTR and theme pass: verify the content library home/category/article pages and all 3 calculator pages render correctly in Arabic RTL and English LTR, and in both light and dark mode, with special attention to numeric/percentage formatting in the calculator result cards (FR-018, SC-006).
- [ ] T054 [P] Offline/airplane-mode verification pass across all 6 screens confirming zero network requests are ever attempted by this feature (FR-017, SC-007) — inspect via a network-request-audit tool/log during a full manual pass per quickstart.md Scenario 5.
- [ ] T055 Write `integration_test/financial_education_flows_test.dart` covering: browse home → category → article → back (US1); compound-growth calculator valid/invalid inputs + high-rate note + pre-fill present/absent (US2); doubling-time and savings-rate calculators including the >100% case (US3); disclaimer present across every screen on repeated visits, zero-network-activity assertion (US4) — per quickstart.md's manual scenarios.
- [ ] T056 Run `fvm flutter analyze` and `fvm flutter format`, fix all warnings (no `// ignore` suppressions without a documented reason).
- [ ] T057 Run the full `fvm flutter test` suite and `fvm flutter test integration_test`; confirm all pass, with special attention to T009/T011/T013 (the three calculators' exhaustive suites) and T048/T049 (disclaimer + structural non-personalization guarantees).
- [ ] T058 Code-review pass against the constitution's Definition of Done checklist, with explicit verification that zero changes were made to any existing feature's table, entity, or calculation (FR-019) — grep the diff to confirm nothing outside `lib/features/financial_education/`, `lib/core/di/`, `lib/core/l10n/`, `lib/core/routing/`, and one Settings/Home navigation-entry-point line was touched, and that the sole cross-feature call site (`GetPrefillableSavingsGoalAmount` → `SavingsRepository.getSavingsOverview`) is read-only.

---

## Dependencies & Execution Order

- **Phase 1 (Setup)** → **Phase 2 (Foundational)**: strictly sequential; Phase 2 blocks every user story.
- **Phase 3 (US1)** and **Phase 4 (US2)** together form the P1 MVP; they are otherwise independent of each other (US2's calculator does not require US1's content screens to exist) and could be built in either order, though this document sequences US1 first to match spec.md's own priority framing.
- **Phase 5 (US3)** is P2 and independent of US1/US2's implementation details, reusing only `CalculatorResultCard` (T036, built in US2) and `PersistentDisclaimerBanner` (T019, built in Phase 2) — soft dependency on those two shared widgets existing.
- **Phase 6 (US4)** is a verification-only phase over the output of US1-US3 and should run last among the user-story phases, once all screens and content exist.
- **Phase 7 (Polish)** runs last, after all desired user stories are implemented.

## Parallel Execution Examples

- Within Phase 2: T003-T007 (entities/failures/value objects) in parallel; T009, T011, T013 (the three exhaustive pure-function test suites) in parallel with each other once T008/T010/T012 land; T015 in parallel with T017 once T014 lands.
- Within Phase 3 (US1): T020-T022 (all three test tasks) in parallel; T025 in parallel with T023/T024.
- Within Phase 4 (US2): T029-T031 in parallel; T032-T033 in parallel.
- Across phases: once Phase 2 is complete, US1 (Phase 3) and US2's use-case/test layer (T029-T033) can be staffed in parallel by different contributors, since US2's use cases depend only on Phase 2's calculator services, not on US1's screens landing first.

## Implementation Strategy

**MVP first**: Phases 1-4 (Setup, Foundational, US1, US2) deliver the feature's core promise — a browsable, offline educational library plus the signature compound-growth calculator, both disclaimer-protected — and are independently demoable/testable per quickstart.md Scenarios 1-2. Phases 5-6 (the two lighter calculators and the dedicated compliance-verification pass) are additive and independently shippable in either order after the MVP, matching their P2 priority in spec.md. Phase 7 always runs last regardless of how many user-story phases have shipped so far.
