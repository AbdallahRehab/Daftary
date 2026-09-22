# Implementation Plan: Income & Expense Tracking

**Branch**: `007-income-expense-tracking` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-income-expense-tracking/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Let the app's single local user record personal income and expense entries (amount, category, date, optional note) separately from the existing person-to-person `MoneyTransaction` ledger, manage a customizable set of income/expense categories (soft-archived once used, hard-deleted otherwise), and review history/totals/per-category breakdowns over a selectable period — fully offline, fully localized (Arabic/English, RTL/LTR), consistent with the existing `people`/`transactions` UX. Implemented as one new Flutter clean-architecture feature (`finance`) with two new local tables (`FinanceEntries`, `FinanceCategories`) alongside the existing `AppDatabase`, using BLoC/Cubit for state, the existing integer-minor-unit `Money` type, and the existing soft-delete/edit-audit + idempotency conventions already proven in `transactions`. This feature does not read, write, or alter `MoneyTransactions`, `People`, or any existing balance calculation — it is purely additive, and it establishes the Category vocabulary that Budgets (V2) will read from later.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc` (state management, per constitution Principle III), `get_it` + `injectable` for dependency injection, `drift` + `sqlite3_flutter_libs` + `path_provider` for the local relational database (same `AppDatabase`, new tables), `fpdart` for `Either<Failure, Success>` result flow, `equatable` for value equality, `uuid` for entity/idempotency-key generation, `intl` (`flutter_localizations`/`gen_l10n`) for Arabic/English localization and EGP formatting, `go_router` for declarative navigation. No new package dependency is required for this feature.

**Storage**: Local SQLite via `drift`, same single on-device `daftary.sqlite` file/`AppDatabase` used by `people`/`transactions`; two new tables (`FinanceEntries`, `FinanceCategories`) added via a `drift` schema migration (`schemaVersion` 4 → 5). No remote backend or network layer (feature is local-only, matching the rest of the app).

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail` (Cubit unit tests with faked repositories/use cases), `integration_test` (critical end-to-end flows: add expense, add income, manage categories, filter/period history, edit/delete with undo).

**Target Platform**: Android and iOS mobile apps (existing app scope); desktop/web build targets scaffolded by `flutter create` remain out of scope.

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: Entry save-to-visible-in-history round trip in <15s end-to-end per SC-001 (dominated by user input time, not system latency — the save itself must complete well under 300ms on mid-range Android); period/category totals recompute and render in <1s for up to 5,000 combined finance entries (extrapolated from the existing `transactions` feature's 10,000-row/2s ceiling, scaled to this feature's expected lower volume); history list scrolling sustains ~60fps on mid-range Android hardware.

**Constraints**: Fully offline-capable (no network dependency at all); money stored/computed as integer minor units (piastres) via the existing `Money` type, never floating point (constitution Principle VIII); every entry save is idempotent (FR-021 — no accidental double-submit duplicates, same pattern as `transactions`' idempotency key); every entry edit/deletion remains traceable (FR-019/FR-020, constitution Financial Domain Override); full Arabic (RTL) and English (LTR) UI, including default category names and Arabic-Indic numeral input (FR-024); this feature MUST NOT modify the `MoneyTransactions`/`People` schema, data, or balance computation (FR-023).

**Scale/Scope**: Single user per device; assume up to ~5,000 combined finance entries and ~50 categories (well above realistic personal use) as the practical performance ceiling; 1 new feature (`finance`), ~7-8 screens (entry list/history, add/edit entry, category picker, manage categories, add/edit category, period/summary view — some of these may be combined at implementation time, see Project Structure).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `finance` splits into `data/domain/presentation`; screens never touch `drift`/DB directly | PASS |
| II. Feature-First Modularity | Code lives under `lib/features/finance/`; no new global catch-all folders; shared code only added to `lib/core/` if genuinely cross-feature (none identified for this feature) | PASS |
| III. BLoC/Cubit Mandate | Cubits per screen/flow (`FinanceEntryFormCubit`, `FinanceHistoryCubit`, `CategoryManagementCubit`, `CategoryFormCubit`); no alternate state layer | PASS |
| IV. Immutable State | All Cubit states are `Equatable` value classes updated via `copyWith()`; no mutated list/map fields | PASS |
| V. Domain-Driven Business Logic | Use cases: `AddFinanceEntry`, `EditFinanceEntry`, `DeleteFinanceEntry`, `GetFinanceHistory`, `GetFinanceSummary`, `CreateCategory`, `EditCategory`, `RemoveCategory`, `GetCategories` — each a meaningful business action | PASS |
| VI. Repository Pattern | Domain defines `FinanceRepository`/`CategoryRepository` interfaces; `drift`-backed `*RepositoryImpl` in Data; Presentation/Domain depend only on the interface via DI | PASS |
| VII. Explicit Error Handling | All repository/use-case calls return `Either<Failure, T>` (`fpdart`); typed `Failure`s reused from `core/error/failure.dart` plus feature-specific ones (`DuplicateCategoryFailure`, `CategoryInUseFailure` if needed) — no empty catches, no raw exceptions to UI | PASS |
| VIII. Deterministic Financial Calculations | Totals/breakdowns computed by SQL aggregate + domain code over integer minor-unit columns; no AI involvement in this feature | PASS |
| IX. AI Isolation | Not applicable — no AI integration in this feature | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is local-only; idempotency enforced via a client-generated idempotency key with a DB unique constraint on `FinanceEntries`, mirroring `MoneyTransactions.idempotencyKey` | PASS |
| XII. Security & Secrets | No secrets/API keys; local DB holds only the user's own data, protected at rest via the same OS-level sandboxed-storage decision already made for `transactions` (research.md Decision 11 in spec 001) — no new decision needed here | PASS |
| XIII. Localization & RTL/LTR | `gen_l10n` ARB additions for `ar`/`en` (entry form, category management, summary/period labels, default category names); `intl` currency/number formatting reused from `core/money`; Arabic-Indic numeral parsing reused from `core/money/numeral_parser.dart` | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires the new DAO, repositories, use cases, Cubits; nothing self-instantiated | PASS |
| XV. Design System | Reuses existing `core/design_system` components (`AppButton`, `AppTextField`, `AppDateField`, `AppCard`, `AppEmptyView`, `AppConfirmDialog`, `AppIconBadge`); category icon/color picker and a category "pill"/chip are the only genuinely new visual components, built inside `features/finance/presentation/widgets/` first and only promoted to `core/` if a later feature (Budgets) needs the same chip | PASS |
| XVI. Testability by Design | Use cases/repositories/mappers/validators unit-tested; Cubits tested with `bloc_test`/`mocktail`; widget tests for entry form and category management; `integration_test` for the flows listed in Scale/Scope | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): The category archive-vs-delete split (FR-010) and the `FinanceCategories.isArchived` flag are the direct, minimal implementation of the spec's data-integrity requirement (never orphan an entry's category) — not speculative scope, and it mirrors the existing `People.isArchived` pattern exactly (Principle II consistency). No new dependency, layering, or state-management deviation was introduced; all gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/007-income-expense-tracking/
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
├── core/                        # UNCHANGED by this feature (no new cross-cutting code identified)
│   ├── database/                 # AppDatabase gains FinanceEntries + FinanceCategories tables,
│   │                              # schemaVersion 4 -> 5, additive migration only
│   ├── design_system/            # reused as-is
│   ├── di/                       # gains finance feature registrations (generated via injectable)
│   ├── error/                    # reused; may gain DuplicateCategoryFailure/CategoryInUseFailure
│   ├── l10n/                     # app_en.arb / app_ar.arb gain finance-feature keys
│   ├── money/                    # reused as-is (Money, EgpFormatter, numeral parser)
│   └── routing/                  # app_router.dart gains the finance branch/routes
│
├── features/
│   ├── people/                   # UNCHANGED
│   ├── transactions/              # UNCHANGED — this feature never touches it
│   ├── settings/                  # UNCHANGED
│   ├── onboarding/                # UNCHANGED
│   └── finance/                   # NEW
│       ├── data/
│       │   ├── datasources/       # FinanceDao (drift): entries + categories queries
│       │   ├── models/            # FinanceEntryEntity/FinanceCategoryEntity <-> domain mappers
│       │   └── repositories/      # FinanceRepositoryImpl, CategoryRepositoryImpl
│       ├── domain/
│       │   ├── entities/          # FinanceEntry, Category, FinanceSummary, CategoryBreakdownItem
│       │   ├── repositories/      # FinanceRepository, CategoryRepository (abstract)
│       │   └── usecases/          # AddFinanceEntry, EditFinanceEntry, DeleteFinanceEntry,
│       │   │                       # GetFinanceHistory, GetFinanceSummary, CreateCategory,
│       │   │                       # EditCategory, RemoveCategory, GetCategories,
│       │   │                       # SeedDefaultCategories
│       └── presentation/
│           ├── cubit/             # FinanceHistoryCubit, FinanceEntryFormCubit,
│           │                       # CategoryManagementCubit, CategoryFormCubit
│           ├── pages/              # FinanceHistoryPage, FinanceEntryFormPage,
│           │                       # CategoryManagementPage, CategoryFormPage
│           └── widgets/            # FinanceEntryListTile, CategoryChip, CategoryIconPicker,
│                                    # PeriodSelector, CategoryBreakdownBar, FinanceSummaryCard
│
└── main.dart                       # UNCHANGED (finance Cubits resolved per-screen via DI like
                                     # transactions' Cubits already are — no app-level bootstrap change)

test/
├── features/
│   └── finance/
│       ├── domain/usecases/       # unit tests, faked repositories
│       ├── data/repositories/     # *RepositoryImpl tests against an in-memory drift DB
│       └── presentation/cubit/    # bloc_test + mocktail
└── widget/                         # FinanceEntryFormPage, CategoryManagementPage widget tests

integration_test/
└── finance_flows_test.dart         # add expense, add income, manage categories (create/rename/
                                     # archive/delete), filter by period/category/type, edit/delete
                                     # with undo (US1-US5)
```

**Structure Decision**: Standard single Flutter app (Option 1 shape), one new feature-first module `lib/features/finance/` added alongside the four existing features, per constitution Principle II. Deliberately named `finance` (not `transactions` or `expenses`) to make the separation from the existing person-to-person `transactions` feature explicit at the folder level — the two are structurally identical in shape (`data/domain/presentation`) but own entirely different tables, entities, and screens. No `backend/`/`api/` split — this feature has no server component. Tests mirror `lib/` under Flutter's `test/` directory, plus one new `integration_test/` file.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
