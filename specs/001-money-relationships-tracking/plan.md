# Implementation Plan: Money Relationships Tracking

**Branch**: `001-money-relationships-tracking` | **Date**: 2026-09-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-money-relationships-tracking/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Let a single device's user create people/contacts and record money given to or received from them (including partial/over-repayments), see each person's automatically computed net balance and status (they owe you / you owe them / settled), browse full chronological history with traceable edits/deletions, and see a consolidated owed-to-me / I-owe overview — all offline-capable and local-only (no backend, no login, no cross-device sync per the spec's clarifications). Implemented as two Flutter clean-architecture features (`people`, `transactions`) on a local SQLite database, using BLoC/Cubit for state, integer minor-unit money arithmetic for zero rounding drift, and idempotency keys + a soft-delete/edit audit trail to satisfy the constitution's duplicate-protection and financial-traceability requirements.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.38 stable

**Primary Dependencies**: `flutter_bloc` (state management, per constitution Principle III), `get_it` (+ `injectable` for codegen) for dependency injection, `drift` + `sqlite3_flutter_libs` + `path_provider` for the local relational database, `fpdart` for `Either<Failure, Success>` result flow, `equatable` for value equality on entities/states, `uuid` for entity/idempotency-key generation, `intl` (via `flutter_localizations` / `gen_l10n`) for Arabic/English localization and EGP currency formatting, `go_router` for declarative navigation

**Storage**: Local SQLite via `drift` (single on-device file database); no remote backend or network layer for this feature (single-device, local-only per spec Clarifications)

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail` (Cubit/BLoC unit tests with faked repositories/use cases), `integration_test` (critical end-to-end flows: record transaction, view balance, repayment, overview, archive/restore, edit/delete)

**Target Platform**: Android and iOS mobile apps (per the product brief); desktop/web build targets already scaffolded by `flutter create` are not in scope for this feature

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: Overview totals correct and rendered in <2s across 500 people / 10,000 combined transactions (SC-005); person history scrolling on mid-range Android hardware sustains ~60fps with no single frame exceeding 32ms (User Story 2, Acceptance Scenario 4's measurable threshold); first person + first transaction completable in <60s (SC-001)

**Constraints**: Fully offline-capable (no network dependency at all for this feature); money MUST be stored/computed as integer minor units (piastres), never floating point (constitution Principle VIII); every save is idempotent — a rapid double-tap or retried save MUST never create more than one transaction (FR-020, SC-006); every transaction edit/deletion MUST remain traceable (what changed, when) per SC-007 and the constitution's Financial Domain Override; full Arabic (RTL) and English (LTR) UI and numeral support (FR-022, FR-023)

**Scale/Scope**: Single user per device; up to ~500 people and ~10,000 combined transactions (SC-005 ceiling); 2 features (`people`, `transactions`), roughly 8-10 screens (people list, person detail/history, add/edit transaction, add/edit person, archived people, overview)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `people` and `transactions` each split into `data/domain/presentation`; screens never touch `drift`/DB directly | PASS |
| II. Feature-First Modularity | Code lives under `lib/features/people/`, `lib/features/transactions/`; shared code only in `lib/core/` (db, design tokens, error types, money type, DI, l10n) | PASS |
| III. BLoC/Cubit Mandate | Cubits per screen/flow (e.g. `PersonListCubit`, `PersonDetailCubit`, `TransactionFormCubit`, `OverviewCubit`); no alternate state layer introduced | PASS |
| IV. Immutable State | All Cubit states are `Equatable` value classes updated via `copyWith()`; no shared mutable list/map fields | PASS |
| V. Domain-Driven Business Logic | Use cases: `AddTransaction`, `RecordRepayment`, `EditTransaction`, `DeleteTransaction`, `CreatePerson`, `ArchivePerson`, `RestorePerson`, `GetPersonBalance`, `GetOverview`, `FindPossibleDuplicatePerson` — each a meaningful business action, not a bare repository passthrough | PASS |
| VI. Repository Pattern | Domain defines `PeopleRepository` / `TransactionsRepository` interfaces; `drift`-backed `*RepositoryImpl` in Data; Presentation/Domain depend only on the interface via DI | PASS |
| VII. Explicit Error Handling | All repository/use-case calls return `Either<Failure, T>` (`fpdart`); typed `Failure`s (`ValidationFailure`, `CacheFailure`, `NotFoundFailure`, `UnknownFailure`) — no empty catches, no raw exceptions reaching the UI | PASS |
| VIII. Deterministic Financial Calculations | Balances/totals computed by SQL aggregate + domain code over integer minor-unit columns; AI is entirely out of scope for this feature | PASS |
| IX. AI Isolation | Not applicable — no AI integration in this feature | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is local-only (no network), so "offline" is the permanent default; idempotency enforced via a client-generated idempotency key with a DB unique constraint, not network sync/reconciliation | PASS |
| XII. Security & Secrets | No secrets/API keys in this feature; local DB holds only the user's own data (name, phone, amounts), protected at rest via OS-level sandboxed-storage protection rather than app-level DB encryption — explicit decision and justification in research.md Decision 11 (single-user/single-device, no credentials stored); no sensitive values in logs | PASS |
| XIII. Localization & RTL/LTR | `gen_l10n` ARB files for `ar`/`en` from the start; `intl` currency/number formatting; Arabic-Indic digit parsing utility in `core/` | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires DB, repositories, use cases, Cubits; nothing self-instantiated in widgets/Cubits | PASS |
| XV. Design System | Reuses/extends a minimal `core/design_system` (tokens + `AppButton`/`AppTextField`/`AppCard`/`AppEmptyView`) rather than hardcoded values; new shared widgets only promoted to `core/` once used by both features | PASS |
| XVI. Testability by Design | Use cases/repositories/money math/mappers unit-tested; Cubits tested with `bloc_test` + `mocktail`; widget tests for key screens; `integration_test` for the critical flows listed in Scale/Scope | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): The `TransactionAuditEntry` table and soft-delete tombstone (`deletedAt`) added during design are the direct, minimal implementation of Principle VII/XI traceability and the Financial Domain Override — not speculative scope. Both entities live inside `features/transactions/`, so Principle II (feature-first modularity, no premature `core/` sharing) still holds. No new dependency, layering, or state-management deviation was introduced; all gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/001-money-relationships-tracking/
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
│   ├── database/            # drift AppDatabase, generated .g.dart, migrations
│   ├── design_system/       # tokens (color/typography/spacing/radius) + AppButton, AppTextField,
│   │                         # AppCard, AppEmptyView, AppConfirmDialog (promoted here once shared)
│   ├── di/                  # get_it/injectable service locator setup
│   ├── error/                # Failure types, exception -> Failure mapping
│   ├── l10n/                 # gen_l10n ARB files (app_en.arb, app_ar.arb) + generated localizations
│   ├── money/                 # Money value type (integer minor units), EGP formatter, numeral parser
│   └── routing/               # go_router configuration
│
├── features/
│   ├── people/
│   │   ├── data/
│   │   │   ├── datasources/    # drift PeopleDao
│   │   │   ├── models/         # PersonTable / PersonEntity <-> domain mappers
│   │   │   └── repositories/   # PeopleRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/       # Person
│   │   │   ├── repositories/   # PeopleRepository (abstract)
│   │   │   └── usecases/       # CreatePerson, EditPerson, ArchivePerson, RestorePerson,
│   │   │                        # SearchPeople, FindPossibleDuplicatePerson
│   │   └── presentation/
│   │       ├── cubit/          # PersonListCubit, PersonFormCubit, ArchivedPeopleCubit
│   │       ├── pages/          # PeopleListPage, PersonFormPage, ArchivedPeoplePage
│   │       └── widgets/        # PersonListTile, DuplicateWarningSheet, RelationshipTagChip
│   │
│   └── transactions/
│       ├── data/
│       │   ├── datasources/    # drift TransactionsDao
│       │   ├── models/         # TransactionTable / TransactionEntity <-> domain mappers,
│       │   │                    # TransactionAuditEntry model
│       │   └── repositories/   # TransactionsRepositoryImpl
│       ├── domain/
│       │   ├── entities/       # MoneyTransaction, PersonBalance, TransactionAuditEntry
│       │   ├── repositories/   # TransactionsRepository (abstract)
│       │   └── usecases/       # AddTransaction, RecordRepayment, EditTransaction,
│       │                        # DeleteTransaction, GetPersonHistory, GetPersonBalance,
│       │                        # GetOverview
│       └── presentation/
│           ├── cubit/          # TransactionFormCubit, PersonDetailCubit, OverviewCubit
│           ├── pages/          # PersonDetailPage, TransactionFormPage, OverviewPage
│           └── widgets/        # TransactionListTile, BalanceStatusBadge, OverviewSummaryCard
│
└── main.dart                   # DI bootstrap + MaterialApp.router + localization delegates

test/
├── core/
│   └── money/                  # Money value type + EGP formatter + numeral parser unit tests
├── features/
│   ├── people/
│   │   ├── domain/usecases/    # unit tests, faked PeopleRepository
│   │   ├── data/repositories/  # PeopleRepositoryImpl tests against an in-memory drift DB
│   │   └── presentation/cubit/ # bloc_test + mocktail
│   └── transactions/
│       ├── domain/usecases/
│       ├── data/repositories/
│       └── presentation/cubit/
└── widget/                     # key widget tests (PersonDetailPage, TransactionFormPage, OverviewPage)

integration_test/
└── money_relationships_flows_test.dart   # record transaction, repayment, overview totals,
                                            # archive/restore, edit/delete traceability (US1-US6)
```

**Structure Decision**: Standard single Flutter app (Option 1 shape), organized feature-first per constitution Principle II: two features (`people`, `transactions`) each with `data/domain/presentation`, and a `lib/core/` reserved strictly for genuinely cross-feature concerns (local database, design system, DI, error types, money/localization utilities, routing). No `backend/`/`api/` split — this feature has no server component (see Clarifications: single-device, local-only). Tests mirror `lib/` under Flutter's conventional `test/` directory (not `tests/`), plus `integration_test/` for the end-to-end flows the constitution's Testability principle requires.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
