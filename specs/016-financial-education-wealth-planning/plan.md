# Implementation Plan: Financial Education & Wealth Planning

**Branch**: `016-financial-education-wealth-planning` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/016-financial-education-wealth-planning/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Ship a fully local, self-contained "Financial Education & Wealth Planning" section: a static, bundled library of educational articles organized into categories (budgeting basics, saving strategies, general investment concepts/risk explanations), plus three deterministic calculators (compound-growth "what if," rule-of-72 doubling time, effective-savings-rate) that never read the user's real financial data and never recommend a specific product or allocation. A persistent, non-dismissible-permanently disclaimer appears on every screen this feature introduces. This is the project's own explicitly-chosen safer MVP alternative to personalized investment advice (`docs/project.txt` §9) — the non-personalization boundary (FR-004/FR-005) is enforced structurally, not just by copy: the calculators' domain services take no dependency on any repository that could read real transaction/income/savings data at all.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc`, `get_it` + `injectable`, `equatable`, `go_router`, `intl` (all existing, reused as-is). No new external package dependency is required — content is bundled as static Dart data/asset files (research.md Decision 1), and the calculators are pure Dart arithmetic like `SavingsCalculator` (011). Optionally reuses `SavingsRepository` (011, read-only) for the single documented pre-fill convenience (FR-014) — the only cross-feature dependency in this entire spec.

**Storage**: None persisted by this feature. Educational content is bundled as static, versioned assets shipped with the app binary (research.md Decision 1) — not a database table, not a remote fetch. `AppDatabase.schemaVersion` is **unchanged** — zero new tables, zero new columns.

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail`, `integration_test` (browse content library → category → article → back; run each calculator with valid/invalid inputs; confirm disclaimer presence across all screens; confirm zero network activity; confirm optional Savings Goal pre-fill behavior when 011 exists and its graceful absence when it doesn't).

**Target Platform**: Android and iOS mobile apps (existing app scope). Pure Dart/Flutter, no native platform code required.

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: Content library home → article in <15s of user navigation time (SC-001, dominated by reading/tapping, not computation); calculator result renders in <200ms of the final input change (a trivial arithmetic operation, no I/O in the hot path); zero network requests observed during any session in this feature (SC-001/SC-007).

**Constraints**: Fully offline — this feature makes zero network calls and this is itself a testable requirement (FR-017). All calculators are pure, deterministic, documented arithmetic — no AI/LLM involvement anywhere (constitution Principle VIII), trivially satisfied by having no AI integration at all in this feature. The non-personalization boundary is a hard architectural constraint, not just a UI copy choice: no calculator's Domain service accepts, and no calculator's Presentation Cubit passes in, any real transaction/income/expense/savings-history data as an input — the one narrow, explicit, read-only exception is the optional Savings-Goal-current-amount pre-fill (FR-014), which is Presentation-layer convenience (a value copied into a text field the user can freely edit), never fed into the calculation as a hidden/implicit factor. The disclaimer must be structurally impossible to permanently dismiss — implemented as an always-rendered UI element, never a one-time-shown flag persisted anywhere (FR-016).

**Scale/Scope**: Single user per device; content scope is a meaningful initial set (research.md Decision 2 gives the exact category/article count for task planning) rather than a single placeholder page, per spec.md Assumptions. ~6 screens (content library home, category view, article view, compound-growth calculator, doubling-time calculator, effective-savings-rate calculator). One new feature module (`financial_education`), zero changes to any existing feature's domain/data layer beyond one read-only call into `SavingsRepository` (011) for the optional pre-fill.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `financial_education` splits into `data/domain/presentation`; screens never contain the compound-interest/rule-of-72/savings-rate math themselves (Domain-layer pure services, exactly like 011's `SavingsCalculator`) | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/financial_education/`; zero changes to any existing feature except one read-only call site into 011's already-public `SavingsRepository` interface | PASS |
| III. BLoC/Cubit Mandate | Cubits per screen/flow (`ContentLibraryCubit`, `ArticleCubit`, `CompoundGrowthCalculatorCubit`, `DoublingTimeCalculatorCubit`, `SavingsRateCalculatorCubit`); no alternate state layer | PASS |
| IV. Immutable State | All Cubit states are `Equatable` value classes updated via `copyWith()` | PASS |
| V. Domain-Driven Business Logic | Use cases/services: `GetEducationCategories`, `GetArticle`, `CompoundGrowthCalculator` (pure), `DoublingTimeCalculator` (pure), `SavingsRateCalculator` (pure), `GetPrefillableSavingsGoalAmount` (the one use case touching another feature, explicitly read-only) — each independently testable and, for the three calculators, deliberately free of any repository dependency that could read real financial data (research.md Decision 3) | PASS |
| VI. Repository Pattern | `EducationContentRepository` (Domain interface) abstracts the bundled-content data source, even though it's static, so Presentation never reads raw asset files directly; the calculators are pure services with no repository at all (nothing to abstract — no I/O) | PASS |
| VII. Explicit Error Handling | `EducationContentRepository` calls return `Either<Failure, T>` (a missing/malformed bundled asset is a real, if rare, failure mode); calculator services return validation results via a typed result object rather than throwing, matching 011's `SavingsCalculator`/`WhatIfResult` precedent | PASS |
| VIII. Deterministic Financial Calculations | All three calculators are pure, documented, deterministic arithmetic (research.md Decision 4) — the central architectural point of this entire feature, since it exists specifically as the deterministic, non-AI-estimated alternative the product brief calls for | PASS |
| IX. AI Isolation | Not applicable — no AI integration in this feature; explicitly the point of its own existence as the "safer MVP alternative" | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is 100% local and read-only/computational — no mutations exist anywhere in this feature (no create/edit/delete use case at all), so idempotency and sync-retry concerns are structurally not applicable | PASS (N/A) |
| XII. Security & Secrets | No secrets, no new data classification, no PII collected — directly reinforced by FR-005's explicit prohibition on collecting risk-tolerance/income/net-worth profiling data | PASS |
| XIII. Localization & RTL/LTR | Every article's content and every calculator's copy exists in both `ar`/`en`; `gen_l10n` ARB additions for UI chrome (calculator labels, disclaimer text, category/nav labels); article body content itself is bundled per-locale (research.md Decision 1), not run through `gen_l10n` string interpolation, since it's long-form prose, not short UI strings | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires `EducationContentRepository`, the three calculator services, and Cubits; the read-only `SavingsRepository` (011) dependency is injected exactly like any other cross-feature dependency in this codebase (e.g. Budgets → `FinanceRepository`, per ROADMAP-PLAN.md §6), never self-instantiated | PASS |
| XV. Design System | Reuses existing `core/design_system` (`AppCard`, `AppButton`, `AppTextField`, `AppEmptyView`); the only genuinely new visual components are the persistent disclaimer banner and a simple results-breakdown card, built inside `features/financial_education/presentation/widgets/` first | PASS |
| XVI. Testability by Design | The three calculator services are unit-tested exhaustively as pure functions (no DB/Flutter dependency at all), mirroring 011's `SavingsCalculator` test rigor; `EducationContentRepository` tested against its bundled test-fixture content; Cubits tested with `bloc_test`/`mocktail`; widget tests confirm the disclaimer's presence on every screen; `integration_test` for full browse/calculate flows | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): Keeping the three calculator services entirely free of any repository/data-source dependency (research.md Decision 3) is the direct, minimal, structural implementation of FR-004/FR-005/FR-013 — it is not merely a copy/UI promise that a future refactor could quietly violate; a calculator service that physically cannot import `TransactionRepository`/`FinanceRepository`/`SavingsRepository` cannot regress into implicit personalization even by accident. The one deliberate exception (`GetPrefillableSavingsGoalAmount`, FR-014) is isolated as a single, narrow, explicitly-read-only use case that returns a plain numeric value into a Presentation-layer text field default — never passed as a hidden input to any calculator's actual computation path. No new dependency, no layering deviation. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/016-financial-education-wealth-planning/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/            # Phase 1 output (/speckit-plan command)
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/                    # UNCHANGED — this feature persists nothing
│   ├── design_system/                # reused as-is
│   ├── di/                           # gains financial_education feature registrations
│   ├── error/                        # reused; gains ContentNotFoundFailure/
│   │                                  # InvalidCalculatorInputFailure
│   ├── l10n/                         # app_en.arb / app_ar.arb gain UI-chrome keys (labels,
│   │                                  # disclaimer text, nav entry) — NOT article bodies
│   └── routing/                      # app_router.dart gains the financial_education routes
│
├── features/
│   ├── savings/                      # UNCHANGED — exposes only its existing, already-public
│   │                                  # SavingsRepository.getSavingsOverview for the read-only
│   │                                  # pre-fill (FR-014); no new method added to 011's contract
│   ├── settings/                     # UNCHANGED except a nav entry point (research.md Decision 5)
│   └── financial_education/          # NEW
│       ├── data/
│       │   ├── content/               # bundled static content: en/*.json + ar/*.json per
│       │   │                          # article, or an equivalent bundled asset format
│       │   │                          # (research.md Decision 1) — versioned with the app,
│       │   │                          # never fetched
│       │   ├── datasources/           # BundledEducationContentDataSource (reads the bundled
│       │   │                          # assets for the active locale)
│       │   └── repositories/          # EducationContentRepositoryImpl
│       ├── domain/
│       │   ├── entities/              # EducationCategory, EducationArticle,
│       │   │                          # CompoundGrowthResult, DoublingTimeResult,
│       │   │                          # SavingsRateResult
│       │   ├── repositories/           # EducationContentRepository (abstract)
│       │   ├── services/               # CompoundGrowthCalculator, DoublingTimeCalculator,
│       │   │                          # SavingsRateCalculator — all pure, zero repository
│       │   │                          # dependency (research.md Decision 3)
│       │   └── usecases/               # GetEducationCategories, GetArticle,
│       │                              # CalculateCompoundGrowth, CalculateDoublingTime,
│       │                              # CalculateSavingsRate, GetPrefillableSavingsGoalAmount
│       │                              # (the one use case depending on 011's SavingsRepository,
│       │                              # read-only)
│       └── presentation/
│           ├── cubit/                  # ContentLibraryCubit, ArticleCubit,
│           │                          # CompoundGrowthCalculatorCubit,
│           │                          # DoublingTimeCalculatorCubit,
│           │                          # SavingsRateCalculatorCubit
│           ├── pages/                   # ContentLibraryHomePage, CategoryPage, ArticlePage,
│           │                          # CompoundGrowthCalculatorPage,
│           │                          # DoublingTimeCalculatorPage,
│           │                          # SavingsRateCalculatorPage
│           └── widgets/                 # PersistentDisclaimerBanner, CalculatorResultCard,
│                                       # ArticleListTile
│
└── main.dart                            # UNCHANGED

test/
├── features/
│   └── financial_education/
│       ├── domain/services/          # CompoundGrowthCalculator/DoublingTimeCalculator/
│       │                              # SavingsRateCalculator unit tests — the most exhaustively
│       │                              # tested files in this feature (pure functions, no I/O)
│       ├── domain/usecases/          # unit tests, faked EducationContentRepository/
│       │                              # SavingsRepository
│       ├── data/repositories/        # EducationContentRepositoryImpl tests against bundled
│       │                              # test-fixture content
│       └── presentation/cubit/       # bloc_test + mocktail
└── widget/                            # disclaimer-presence tests across every screen this
                                        # feature introduces (widget test, not just a code-review
                                        # spot-check, per SC-003)

integration_test/
└── financial_education_flows_test.dart  # browse home → category → article → back;
                                          # compound-growth calculator valid/invalid inputs +
                                          # high-rate note; doubling-time valid/invalid inputs;
                                          # savings-rate calculator including the >100% case;
                                          # optional Savings Goal pre-fill present when 011 has
                                          # goals, absent/hidden when it doesn't; disclaimer
                                          # present on every screen across two separate visits
                                          # each (SC-003); zero-network-activity assertion
```

**Structure Decision**: Single new feature module `lib/features/financial_education/` following the established clean-architecture shape. No existing feature's schema, data, or calculation changes at all — the only touch point outside the new module is one read-only call into 011's already-public `SavingsRepository` interface for the optional pre-fill convenience, plus a one-line Settings/navigation entry point.

## Complexity Tracking

*No Constitution Check violations — table intentionally omitted.*
