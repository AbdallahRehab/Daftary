# Implementation Plan: Savings Goals

**Branch**: `011-savings-goals` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-savings-goals/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Let the app's single local user create named savings goals (target amount, optional monthly contribution and/or target date), log deposits and withdrawals against each goal, see current/remaining/percentage-progress/estimated-completion figures computed entirely from deterministic arithmetic over that logged history (never a freely-editable "current amount" field), and explore non-destructive "what if" recalculations before optionally applying them. Implemented as one new, fully independent Flutter clean-architecture feature (`savings`) with two new local tables (`SavingsGoals`, `SavingsContributions`) and zero dependency on, or changes to, any existing feature's schema or calculations — the cleanest-boundary feature yet in this roadmap tier, mirroring 007's original "structurally parallel, not merged" decision rather than 008/009/010's compose-through-an-existing-contract pattern, because savings goals share no real entity (no `Person`, no `Category`) with any existing feature.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc`, `get_it` + `injectable`, `drift` + `sqlite3_flutter_libs` + `path_provider`, `fpdart`, `equatable`, `uuid`, `intl`, `go_router` (all existing, reused as-is). **No new package dependency** — a goal's progress ring/bar is a simple custom `LinearProgressIndicator`/`CustomPainter`-based widget built in `core/design_system` (or `features/savings/presentation/widgets/` if judged not generically reusable), explicitly **not** `fl_chart` (010's dependency, introduced for genuine multi-series trend charts, which a single-value progress indicator does not need — research.md Decision 4, resolved 2026-09-22 during `/speckit-analyze` to remove an accidental `pubspec.yaml`-ordering dependency on 010). This removes any wave-sequencing constraint between 011 and 010 — this feature's core value is arithmetic and record-keeping, not new device capabilities.

**Storage**: Local SQLite via `drift`, same `AppDatabase`. Additive schema migration: two new tables, `SavingsGoals` and `SavingsContributions`. No column is added to, or removed from, any existing table — this feature touches nothing from 001/007/008/009/010 (FR-026). `AppDatabase.schemaVersion` increments by 1 from whatever value it holds when this feature is implemented.

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail`, `integration_test` (create goal, log contributions/withdrawals and verify current/remaining/estimated-completion, what-if scenarios non-destructive until applied, achieved-state transition, multi-goal overview, archive/delete-protection).

**Target Platform**: Android and iOS mobile apps (existing app scope).

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: Goal creation with target + monthly contribution in <45s end-to-end (SC-001, dominated by user input time); current/remaining/percentage/estimated-completion recompute renders in <1s for up to 200 logged contributions on a single goal; what-if recalculation renders in under 1s of computation time (SC-004's "5 seconds of interaction" budget is dominated by user input, not calculation).

**Constraints**: Fully offline-capable; money stored/computed as integer minor units via the existing `Money` type (constitution Principle VIII); every goal-creation and contribution-logging save is idempotent (FR-022); every completion/required-contribution calculation (FR-010/FR-011) and every what-if scenario (FR-013/FR-014) is pure, deterministic arithmetic with zero AI/LLM involvement (constitution Principle VIII/IX — trivially satisfied by having no AI integration at all in this feature); a what-if scenario is never persisted and never mutates the real goal except through the single explicit "apply" action (FR-015); this feature MUST NOT alter 001/007/008/009/010's schema, data, or calculations (FR-026).

**Scale/Scope**: Single user per device; up to ~50 concurrent goals and ~500 logged contributions per goal as the practical ceiling (well above realistic personal use); 1 new feature (`savings`), zero changes to any existing feature; ~6 screens (goals overview, goal detail, create/edit goal, log contribution/withdrawal, contribution history, what-if calculator — some may be combined at implementation time, see Project Structure).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `savings` splits into `data/domain/presentation`; screens never touch `drift`/DB directly, and never contain the completion/what-if math themselves (that lives in Domain — see V below) | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/savings/`; zero changes to any existing feature — the cleanest-boundary feature in this tier, sharing no entity with 001/007/008/009/010 | PASS |
| III. BLoC/Cubit Mandate | Cubits per screen/flow (`SavingsOverviewCubit`, `GoalFormCubit`, `GoalDetailCubit`, `ContributionFormCubit`, `WhatIfCubit`); no alternate state layer | PASS |
| IV. Immutable State | All Cubit states are `Equatable` value classes updated via `copyWith()`; a what-if scenario's hypothetical result is held as an immutable, clearly-separate field on `WhatIfState` — never merged into or confused with the real goal's state | PASS |
| V. Domain-Driven Business Logic | Use cases: `CreateSavingsGoal`, `EditSavingsGoal`, `DeleteSavingsGoal`, `ArchiveSavingsGoal`, `RestoreSavingsGoal`, `LogContribution`, `LogWithdrawal`, `EditContribution`, `DeleteContribution`, `GetGoalDetail`, `GetSavingsOverview`, `CalculateWhatIfMonthlyContribution`, `CalculateWhatIfCompletionDate`, `ApplyWhatIfScenario` — each a meaningful business action; the two `CalculateWhatIf*` use cases are pure functions with no side effects, deliberately separated from `ApplyWhatIfScenario` (the only one that writes) so "explore" and "commit" can never be accidentally conflated | PASS |
| VI. Repository Pattern | Domain defines `SavingsRepository` (owns `SavingsGoals`/`SavingsContributions`); Presentation/Domain depend only on the interface via DI | PASS |
| VII. Explicit Error Handling | All repository/use-case calls return `Either<Failure, T>`; typed `Failure`s reused from `core/error/failure.dart` plus `GoalNotFoundFailure`/`WithdrawalExceedsBalanceFailure`/`InvalidTargetDateFailure` — no empty catches, no raw exceptions to UI | PASS |
| VIII. Deterministic Financial Calculations | All completion/required-contribution/what-if math is simple, documented, deterministic integer-money and date arithmetic in a pure `SavingsCalculator` Domain service (research.md Decision 1) — no AI, no floating point | PASS |
| IX. AI Isolation | Not applicable — no AI integration in this feature; explicitly the point of Decision above | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is local-only; `createSavingsGoal`/`logContribution`/`logWithdrawal` take a caller-generated idempotency key with a DB unique constraint, mirroring the established pattern | PASS |
| XII. Security & Secrets | No secrets/API keys; no new data classification beyond what 001/007 already protect | PASS |
| XIII. Localization & RTL/LTR | `gen_l10n` ARB additions for `ar`/`en` (goal form, contribution log, what-if calculator, achieved-state celebration, goal-type labels); `intl` currency/number/date formatting reused from `core/money`/`core/date` | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires the new DAO, `SavingsRepository`, `SavingsCalculator`, use cases, Cubits; nothing self-instantiated | PASS |
| XV. Design System | Reuses existing `core/design_system` components (`AppButton`, `AppTextField`, `AppDateField`, `AppCard`, `AppEmptyView`, `AppConfirmDialog`); a goal progress ring/bar and an achieved-state celebratory badge are the only genuinely new visual components, built inside `features/savings/presentation/widgets/` first | PASS |
| XVI. Testability by Design | `SavingsCalculator` is unit-tested exhaustively as pure functions (no DB/Flutter dependency at all); repositories/mappers/use cases unit-tested; Cubits tested with `bloc_test`/`mocktail`; widget tests for the goal form and what-if calculator; `integration_test` for the flows listed in Scale/Scope | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): Deriving `currentAmount` entirely from `SavingsContribution` rows (research.md Decision 2, spec FR-004) rather than accepting a directly-editable field is the direct, minimal implementation of the spec's own explicitly-reasoned key decision, consistent with every prior derived-balance precedent in this codebase (001/008/010) — not speculative scope. Keeping `SavingsCalculator` as a pure, DB-free, side-effect-free Domain service (rather than folding the math into the repository or a Cubit) is what makes FR-010/FR-011/FR-013/FR-014's determinism independently, exhaustively unit-testable, and is what structurally guarantees a what-if exploration cannot accidentally mutate a real goal (only `ApplyWhatIfScenario` writes anything). No new dependency, no layering/state-management deviation. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/011-savings-goals/
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
│   ├── database/                  # AppDatabase gains SavingsGoals + SavingsContributions
│   │                                # tables; schemaVersion incremented by 1, additive migration
│   │                                # only; zero changes to any existing table
│   ├── design_system/              # reused as-is
│   ├── di/                         # gains savings feature registrations
│   ├── error/                      # reused; gains GoalNotFoundFailure/
│   │                                # WithdrawalExceedsBalanceFailure/InvalidTargetDateFailure
│   ├── l10n/                       # app_en.arb / app_ar.arb gain savings-feature keys
│   ├── money/                      # reused as-is
│   ├── date/                       # reused as-is (month-count/target-date arithmetic
│   │                                # centralized here per constitution Engineering Standards)
│   └── routing/                    # app_router.dart gains the savings branch/routes
│
├── features/
│   ├── people/                     # UNCHANGED
│   ├── transactions/                # UNCHANGED
│   ├── occasions/                   # UNCHANGED
│   ├── ocr/                         # UNCHANGED (if present)
│   ├── finance/                     # UNCHANGED (007)
│   ├── budgets/                     # UNCHANGED (010) — no interaction (Assumptions)
│   ├── settings/                    # UNCHANGED
│   ├── onboarding/                  # UNCHANGED
│   └── savings/                     # NEW
│       ├── data/
│       │   ├── datasources/         # SavingsDao (drift): goals + contributions queries
│       │   ├── models/              # SavingsGoalEntity/SavingsContributionEntity <-> domain
│       │   └── repositories/        # SavingsRepositoryImpl
│       ├── domain/
│       │   ├── entities/            # SavingsGoal, SavingsContribution, ContributionType
│       │   │                          # (contribution/withdrawal), GoalProgress, WhatIfResult
│       │   ├── repositories/         # SavingsRepository (abstract)
│       │   ├── services/             # SavingsCalculator (pure, DB-free deterministic math —
│       │   │                          # remaining, percentage, estimated completion, required
│       │   │                          # monthly contribution, what-if variants)
│       │   └── usecases/             # CreateSavingsGoal, EditSavingsGoal, DeleteSavingsGoal,
│       │   │                          # ArchiveSavingsGoal, RestoreSavingsGoal, LogContribution,
│       │   │                          # LogWithdrawal, EditContribution, DeleteContribution,
│       │   │                          # GetGoalDetail, GetSavingsOverview,
│       │   │                          # CalculateWhatIfMonthlyContribution,
│       │   │                          # CalculateWhatIfCompletionDate, ApplyWhatIfScenario
│       └── presentation/
│           ├── cubit/                # SavingsOverviewCubit, GoalFormCubit, GoalDetailCubit,
│           │                          # ContributionFormCubit, WhatIfCubit,
│           │                          # ArchivedGoalsCubit
│           ├── pages/                 # SavingsOverviewPage, GoalFormPage, GoalDetailPage,
│           │                          # ContributionFormPage, WhatIfCalculatorPage,
│           │                          # ArchivedGoalsPage
│           └── widgets/               # GoalProgressCard, GoalProgressRing, AchievedGoalBadge,
│                                       # ContributionListTile, WhatIfResultCard,
│                                       # SavingsOverviewSummaryCard
│
└── main.dart                          # UNCHANGED

test/
├── features/
│   └── savings/
│       ├── domain/services/          # SavingsCalculator unit tests — the most exhaustively
│       │                              # tested file in this feature (pure functions, no DB)
│       ├── domain/usecases/          # unit tests, faked SavingsRepository
│       ├── data/repositories/        # SavingsRepositoryImpl tests against an in-memory drift DB
│       └── presentation/cubit/       # bloc_test + mocktail
└── widget/                            # GoalFormPage, WhatIfCalculatorPage,
                                        # ContributionFormPage widget tests

integration_test/
└── savings_flows_test.dart            # create goal (contribution-mode and target-date-mode);
                                        # log contributions/withdrawals and verify recompute;
                                        # withdrawal-exceeds-balance rejection; achieved-state
                                        # transition and reversal; what-if scenario exploration +
                                        # explicit apply; multi-goal overview; archive/delete
                                        # protection
```

**Structure Decision**: Standard single Flutter app (Option 1 shape), one new feature-first module `lib/features/savings/` added alongside the existing features, per constitution Principle II. Unlike 008/009/010 (each of which composes through an existing feature's public Domain interface because they share a real entity with it — `Person`/`MoneyTransaction`, or `Category`/`FinanceEntry`), `savings` shares no entity with any existing feature and is therefore fully independent at the Domain level, closer to 007's original "structurally parallel" precedent than to 008-010's composition precedent — both are valid applications of the same underlying rule (constitution Principle II: only couple across features when the sharing is genuine), and this plan explicitly names why this feature lands on the independent side of that line. No `backend/`/`api/` split. Tests mirror `lib/` under `test/`, plus one new `integration_test/` file.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
