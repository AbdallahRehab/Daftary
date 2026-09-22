# Implementation Plan: Household Budgets

**Branch**: `010-household-budgets` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-household-budgets/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Let the app's single local user plan a monthly household budget by allocating planned amounts to existing (or newly-created) expense categories from 007, then see — per category and overall — actual spend, remaining, percentage used, and over/near/on-track warning states, all computed on demand from 007's existing `FinanceEntry`/`Category` data (never a second copy of it), plus a month-over-month spending trend view. Implemented as one new Flutter clean-architecture feature (`budgets`) that depends on 007's `FinanceRepository`/`CategoryRepository` public Domain contracts exactly as 007's own data-model.md anticipated, with two new local tables (`Budgets`, `BudgetCategoryAllocations`) and zero changes to 001/007's existing schema or calculations.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc`, `get_it` + `injectable`, `drift` + `sqlite3_flutter_libs` + `path_provider`, `fpdart`, `equatable`, `uuid`, `intl`, `go_router` (all existing, reused as-is). **New dependency**: `fl_chart` (MIT-licensed, actively maintained charting package) for the spending trend view (FR-014) — chosen over hand-rolled `CustomPainter` charts because the trend view needs grouped bar/line rendering with axis labels and responsive RTL-aware layout, which `fl_chart` provides out of the box (research.md Decision 4); no other new dependency required.

**Storage**: Local SQLite via `drift`, same `AppDatabase`. Additive schema migration: two new tables, `Budgets` and `BudgetCategoryAllocations`. No column is added to, or removed from, any existing table (`People`, `MoneyTransactions`, `TransactionAuditEntries`, `Occasions`, `OccasionAttachments`, `FinanceCategories`, `FinanceEntries`) — this feature is purely additive and read-only against 007's tables. `AppDatabase.schemaVersion` increments by 1 from whatever value it holds when this feature is implemented.

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail`, `integration_test` (create budget, record expenses and verify actual/remaining/percentage, over-budget warning states, copy-forward, month navigation, trend view).

**Target Platform**: Android and iOS mobile apps (existing app scope).

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: Budget creation with 5 categories in <90s end-to-end (SC-001, dominated by user input time); a budget's full planned/actual/remaining/percentage recompute renders in <1s for up to 30 budgeted categories against up to 2,000 expense entries in that month (extrapolated from 007's own 5,000-entry ceiling); trend view (6 months × up to 30 categories) renders in <1.5s.

**Constraints**: Fully offline-capable; money stored/computed as integer minor units via the existing `Money` type (constitution Principle VIII); every budget/allocation save is idempotent (FR-017); every budget edit/deletion is a normal, traceable financial-planning-domain edit (a `Budget`/`BudgetCategoryAllocation` is a plan, not a financial transaction itself, so it does not require the same `TransactionAuditEntry`-style audit trail as 001/007/008/009 — see research.md Decision 5 for why this is a deliberate, justified difference rather than an oversight); this feature MUST NOT alter 001/007's schema, data, or calculations (FR-022) — it is a read-only overlay wherever it touches `FinanceEntry`/`Category`, and a fully independent write path for `Budget`/`BudgetCategoryAllocation` data.

**Scale/Scope**: Single user per device; up to ~24 months of budget history and ~30 categories per budget as the practical ceiling (well above realistic personal use); 1 new feature (`budgets`), zero changes to existing features beyond read-only repository calls; ~5 screens (budget month view, create/edit budget, category allocation picker, copy-forward confirmation, trend view — some may be combined at implementation time, see Project Structure).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `budgets` splits into `data/domain/presentation`; screens never touch `drift`/DB or 007's DAO directly — only through `FinanceRepository`/`CategoryRepository`'s existing Domain interfaces and the new `BudgetsRepository` | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/budgets/`; zero changes to `lib/features/finance/` (007) or any other existing feature — this is the cleanest cross-feature composition yet (depends on 007's Domain layer only, adds nothing to it) | PASS |
| III. BLoC/Cubit Mandate | Cubits per screen/flow (`BudgetMonthCubit`, `BudgetFormCubit`, `CopyBudgetCubit`, `BudgetTrendCubit`); no alternate state layer | PASS |
| IV. Immutable State | All Cubit states are `Equatable` value classes updated via `copyWith()`; no mutated list/map fields | PASS |
| V. Domain-Driven Business Logic | Use cases: `CreateBudget`, `EditBudget`, `DeleteBudget`, `CopyBudgetToMonth`, `AddBudgetCategoryAllocation`, `RemoveBudgetCategoryAllocation`, `GetBudgetForMonth`, `GetBudgetTrend` — each a meaningful business action; `GetBudgetForMonth`'s planned/actual/remaining/percentage/unbudgeted computation is the feature's core domain logic, kept entirely in Domain (not the DAO or the Cubit) | PASS |
| VI. Repository Pattern | Domain defines `BudgetsRepository` (new, owns `Budgets`/`BudgetCategoryAllocations`); this feature's use cases also depend directly on 007's existing `FinanceRepository`/`CategoryRepository` interfaces (never a concrete `*Impl`, never a new/duplicate expense-aggregation query) | PASS |
| VII. Explicit Error Handling | All repository/use-case calls return `Either<Failure, T>`; typed `Failure`s reused from `core/error/failure.dart` plus `BudgetAlreadyExistsForMonthFailure`/`BudgetNotFoundFailure` — no empty catches, no raw exceptions to UI | PASS |
| VIII. Deterministic Financial Calculations | Actual/remaining/percentage/trend figures computed by SQL aggregate (via `FinanceRepository`'s existing period/category query capability, research.md Decision 2) plus simple deterministic arithmetic in Domain — no AI, no floating point | PASS |
| IX. AI Isolation | Not applicable — no AI integration in this feature | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is local-only; `createBudget`/`addBudgetCategoryAllocation` take a caller-generated idempotency key with a DB unique constraint (`Budgets` unique on `(month)`, `BudgetCategoryAllocations` unique on `(budgetId, categoryId)`), mirroring the established pattern | PASS |
| XII. Security & Secrets | No secrets/API keys; no new data classification beyond what 001/007 already protect (a budget contains no more sensitive information than the expense data it already summarizes) | PASS |
| XIII. Localization & RTL/LTR | `gen_l10n` ARB additions for `ar`/`en` (budget form, warning-state labels, trend view); `intl` currency/number/month formatting reused from `core/money`/`core/date`; `fl_chart` axis labels and RTL mirroring verified explicitly (research.md Decision 4) | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires the new DAO, `BudgetsRepository`, use cases, Cubits; nothing self-instantiated | PASS |
| XV. Design System | Reuses existing `core/design_system` components (`AppButton`, `AppTextField`, `AppCard`, `AppEmptyView`, `AppConfirmDialog`); a budget-category progress row (planned/actual/percentage bar) and an over-budget warning badge are the only genuinely new visual components, built inside `features/budgets/presentation/widgets/` first, plus a thin `fl_chart`-backed trend chart widget | PASS |
| XVI. Testability by Design | Use cases/repositories/mappers/validators unit-tested; Cubits tested with `bloc_test`/`mocktail` against faked `FinanceRepository`/`CategoryRepository`/`BudgetsRepository`; widget tests for the budget form and category progress row; `integration_test` for the flows listed in Scale/Scope | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): `BudgetsRepository` composing 007's `FinanceRepository`/`CategoryRepository` (rather than a new spend-aggregation table or query, per FR-016) is the direct, minimal implementation of the spec's explicit scope boundary, and it is the exact composition 007's own data-model.md already anticipated — not speculative scope. Deciding that a `Budget`/`BudgetCategoryAllocation` edit does not need a `TransactionAuditEntry`-style audit log (research.md Decision 5) is a deliberate, justified narrowing of the Financial Domain Override's traceability requirement to genuine financial *transactions* (money that moved) rather than financial *plans* (an intention that can freely change) — documented here rather than silently assumed. No new dependency beyond `fl_chart` (justified above), no layering/state-management deviation. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/010-household-budgets/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/                  # AppDatabase gains Budgets + BudgetCategoryAllocations tables;
│   │                                # schemaVersion incremented by 1, additive migration only;
│   │                                # zero changes to any existing table
│   ├── design_system/              # reused as-is
│   ├── di/                         # gains budgets feature registrations
│   ├── error/                      # reused; gains BudgetAlreadyExistsForMonthFailure/
│   │                                # BudgetNotFoundFailure
│   ├── l10n/                       # app_en.arb / app_ar.arb gain budgets-feature keys
│   ├── money/                      # reused as-is
│   ├── date/                       # reused as-is (month/period handling already centralized
│   │                                # per constitution Engineering Standards)
│   └── routing/                    # app_router.dart gains the budgets branch/routes
│
├── features/
│   ├── people/                     # UNCHANGED
│   ├── transactions/                # UNCHANGED
│   ├── occasions/                   # UNCHANGED
│   ├── ocr/                         # UNCHANGED (if present) — no interaction
│   ├── finance/                     # UNCHANGED (007) — read-only dependency via its own
│   │                                # public Domain interfaces (FinanceRepository/
│   │                                # CategoryRepository); zero code added here
│   ├── settings/                    # UNCHANGED
│   ├── onboarding/                  # UNCHANGED
│   └── budgets/                     # NEW
│       ├── data/
│       │   ├── datasources/         # BudgetsDao (drift): budgets + allocations queries
│       │   ├── models/              # BudgetEntity/BudgetCategoryAllocationEntity <-> domain
│       │   └── repositories/        # BudgetsRepositoryImpl (composes BudgetsDao +
│       │                              # FinanceRepository + CategoryRepository, 007)
│       ├── domain/
│       │   ├── entities/            # Budget, BudgetCategoryAllocation, BudgetSummary,
│       │   │                          # BudgetCategoryStatus (onTrack/nearFull/overBudget),
│       │   │                          # UnbudgetedSpending, BudgetTrendPoint
│       │   ├── repositories/         # BudgetsRepository (abstract)
│       │   └── usecases/             # CreateBudget, EditBudget, DeleteBudget,
│       │   │                          # CopyBudgetToMonth, AddBudgetCategoryAllocation,
│       │   │                          # RemoveBudgetCategoryAllocation, GetBudgetForMonth,
│       │   │                          # GetBudgetTrend
│       └── presentation/
│           ├── cubit/                # BudgetMonthCubit, BudgetFormCubit, CopyBudgetCubit,
│           │                          # BudgetTrendCubit
│           ├── pages/                 # BudgetMonthPage, BudgetFormPage, BudgetTrendPage
│           └── widgets/               # BudgetCategoryProgressRow, OverBudgetWarningBadge,
│                                       # BudgetOverallSummaryCard, UnbudgetedSpendingCard,
│                                       # MonthNavigator, BudgetTrendChart (fl_chart-backed)
│
└── main.dart                          # UNCHANGED

test/
├── features/
│   └── budgets/
│       ├── domain/usecases/          # unit tests, faked BudgetsRepository/FinanceRepository/
│       │                              # CategoryRepository
│       ├── data/repositories/        # BudgetsRepositoryImpl tests against an in-memory drift DB
│       └── presentation/cubit/       # bloc_test + mocktail
└── widget/                            # BudgetFormPage, BudgetCategoryProgressRow,
                                        # BudgetTrendChart widget tests

integration_test/
└── budgets_flows_test.dart            # create budget + allocate categories; record expenses and
                                        # verify actual/remaining/percentage; over-budget/near-full/
                                        # on-track states; unbudgeted spending; copy-forward to a new
                                        # month; month navigation; trend view with 3+ months of data
```

**Structure Decision**: Standard single Flutter app (Option 1 shape), one new feature-first module `lib/features/budgets/` added alongside the existing features, per constitution Principle II. `budgets` depends on 007's `FinanceRepository`/`CategoryRepository` **public Domain interfaces only** — the same composition-through-stable-contract pattern 008 established for `transactions` and 009 established for both `transactions` and `occasions` — but is the first of these compositions to be entirely read-only against the feature it depends on, adding zero code to `finance`. No `backend/`/`api/` split. Tests mirror `lib/` under `test/`, plus one new `integration_test/` file.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
