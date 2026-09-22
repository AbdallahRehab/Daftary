# Implementation Plan: Reports & Data/Privacy Controls

**Branch**: `013-reports-data-privacy` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/013-reports-data-privacy/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Two bundled, independently-testable capabilities, both read/administer already-existing data and add no new business calculation: (A) **Reports** — a `ReportsPage` inside the `finance` feature (007) showing a monthly income/expense trend and a per-category breakdown, built entirely by calling 007's existing `GetSummary`/`GetCategoryBreakdown` use cases across multiple periods via one new coordinating use case, `GetSpendingTrend`; (B) **Data & Privacy Controls** — a new `lib/features/data_privacy/` feature providing a `DataExportPage` (generates one shareable CSV file covering every existing data table, composed entirely from already-existing repository read methods with zero new repository surface on `people`/`transactions`/`finance`) and a "Delete My Data" flow nested in the existing `SettingsPage` (a two-step, typed-confirmation destructive action, backed by one genuinely new capability — `AppDatabase.deleteAllUserData()`, a `core/database/` extension mirroring the existing `balance_queries.dart` precedent — executed inside a single `drift` transaction for true all-or-nothing atomicity, followed by re-running the existing `OnboardingCubit.initialize()` gate so the app naturally redirects to onboarding). The only new dependency is `share_plus`, isolated behind a `ShareService` Domain interface so Presentation never touches the platform share API directly.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc`, `get_it` + `injectable`, `fpdart`, `equatable`, `intl` (`gen_l10n`), `go_router` — all existing, no new pattern. One new dependency: `share_plus` (OS share-sheet integration for the export file — the minimal, justified addition for a hard privacy requirement per `docs/project.txt` §16, no existing capability covers it).

**Storage**: No new database table. `AppDatabase.schemaVersion` is unchanged by this feature (still whatever 007 leaves it at, e.g. 5). Reports reads only, via existing `finance` use cases. Export reads only, via existing repository methods across `people`/`transactions`/`finance`/`settings` (research.md Decision 2 — deliberately zero new repository read methods). Delete is the one genuinely new write capability: a full-table row wipe (not a schema change) across every existing table, added as a `core/database/` extension.

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail`, `integration_test` (critical end-to-end flows: view trend/breakdown, export and verify file contents, delete-and-confirm-reset-to-onboarding).

**Target Platform**: Android and iOS mobile apps (existing app scope). `share_plus` is a well-established cross-platform plugin covering both.

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: Reports load within 2s (SC-001) — the monthly trend calls `GetSummary` once per month in the window (research.md Decision 1's window default), run concurrently, never sequentially, to stay well under this ceiling even as history grows. Export generation for a realistic single-user dataset (per 007's own ~5,000-entry ceiling plus people/transactions) completes in a few seconds; the UI must show progress rather than implying instant completion. Deletion (FR-019) completes in a short, bounded time — a single-transaction bulk `DELETE FROM` per table is fast even at the app's realistic data ceiling.

**Constraints**: Fully offline-capable except for the user-initiated OS share-sheet hand-off (FR-022); export/delete MUST NOT alter any existing calculation logic (FR-003's "single source of truth" rule applies to Reports; export is read-only by definition); deletion MUST be transactional/all-or-nothing (FR-018, constitution Financial Domain Override) — this is the single most destructive action in the app and gets this plan's strictest gate.

**Scale/Scope**: Single user per device; 2 feature-surface additions — new screens/use cases inside the existing `finance` feature (Reports), and one new small feature module `lib/features/data_privacy/` (Export + Delete). No new backend/API surface; still zero network dependency for the app's own logic.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `finance` (Reports additions) and the new `data_privacy` feature both split into `data/domain/presentation`; the platform share call is isolated in `data_privacy/data/services/`, never touched by Presentation directly | PASS |
| II. Feature-First Modularity | Reports lives in `finance` (it is finance data, owned by the feature that already owns `Category`/`FinanceEntry`); Export/Delete get a new `data_privacy` feature because neither concerns income/expense specifically — both touch `people`/`transactions`/`finance`/`settings` equally, so neither existing feature should own them (mirrors the Home Dashboard feature's own justification for a new cross-feature module) | PASS |
| III. BLoC/Cubit Mandate | `ReportsCubit` (new, `finance/presentation/cubit/`), `ExportCubit`, `DeleteAccountCubit` (new, `data_privacy/presentation/cubit/`) — each with an explicit, constitution-compliant state lifecycle | PASS |
| IV. Immutable State | All three Cubits' states are `Equatable` value classes updated via `copyWith()` | PASS |
| V. Domain-Driven Business Logic | `GetSpendingTrend` (coordinates `GetSummary` N times — real multi-call composition, not a passthrough); `ExportUserData` (composes 5+ existing repository calls into one serialized artifact — real coordination); `DeleteAllUserData` (owns the atomicity/ordering/onboarding-reset sequencing — real business logic, not a bare DB call) | PASS |
| VI. Repository Pattern | `GetSpendingTrend` depends only on `FinanceRepository` (existing interface); `ExportUserData` depends only on the existing `PeopleRepository`/`TransactionsRepository`/`FinanceRepository`/`CategoryRepository`/`SettingsRepository` interfaces (research.md Decision 2 — zero new abstract methods added to any of them); `DeleteAllUserData` depends on a new `DataWipeRepository` (Domain) wrapping the new `AppDatabase.deleteAllUserData()` extension — a genuinely new capability gets a genuinely new (minimal) interface, not a shortcut around one | PASS |
| VII. Explicit Error Handling | Every new use case returns `Either<Failure, T>`; `DeleteAllUserData`'s transaction failure maps to a typed `Failure` with zero partial state (research.md Decision 5); export failures never leave a file that looks complete but isn't (research.md Decision 4) | PASS |
| VIII. Deterministic Financial Calculations | No new calculation anywhere in this feature — Reports strictly re-presents `GetSummary`/`GetCategoryBreakdown` output already computed elsewhere (FR-003); export/delete perform no arithmetic at all | PASS |
| IX. AI Isolation | Not applicable — no AI integration | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Fully local; the one exception (OS share hand-off) is explicitly scoped in FR-022 as outside the app's own control; `DeleteAllUserData` is idempotent by nature (deleting an already-empty set of tables a second time is a safe no-op) | PASS |
| XII. Security & Secrets | No secrets; the exported file is written to the app's own sandboxed storage/cache before being handed to the OS share sheet, never uploaded by this app itself (FR-012) | PASS |
| XIII. Localization & RTL/LTR | New ARB keys for Reports/Export/Delete screens; chart axis/legend mirroring is this feature's one genuinely new RTL risk area (FR-006, research.md Decision 6) — no other feature in the roadmap has shipped a chart yet | PASS |
| XIV. Dependency Injection | `GetSpendingTrend`, `ExportUserData`, `DeleteAllUserData`, `ShareService`/`SharePlusService`, and all three new Cubits registered via `get_it`/`injectable` | PASS |
| XV. Design System | Reuses `AppCard`, `AppButton`, `AppTextField` (for the typed-confirmation input), `AppConfirmDialog`, `AppEmptyView`, design tokens; the only genuinely new visual components are a simple bar/line chart pair (trend + breakdown) built in `finance/presentation/widgets/` — no charting package dependency is added; both are drawn with Flutter's own `CustomPainter`/`fl_chart`-free primitives to avoid a second new dependency beyond `share_plus` (research.md Decision 7) | PASS |
| XVI. Testability by Design | `GetSpendingTrend`/`ExportUserData`/`DeleteAllUserData` unit-tested (the latter two against an in-memory `drift` DB to prove real composition/atomicity, not just mocked calls); all three Cubits tested with `bloc_test`/`mocktail`; widget tests for chart RTL mirroring, the export flow, and the two-step delete confirmation; two `integration_test` files | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): The single new repository interface this feature introduces, `DataWipeRepository` (research.md Decision 5), is scoped to exactly one method (`deleteAllUserData()`) and is the direct, minimal implementation of FR-018's atomicity requirement — not speculative scope. `ExportUserData`'s deliberate zero-new-methods design (research.md Decision 2) was re-verified against every repository it touches during Phase 1 data-model design and confirmed sufficient. No new dependency beyond `share_plus`, no layering violation, no state-management deviation. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/013-reports-data-privacy/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/            # Phase 1 output (/speckit-plan command)
└── tasks.md               # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart          # UNCHANGED (no schema change — row wipe only)
│   │   ├── balance_queries.dart        # UNCHANGED — existing precedent this feature
│   │   │                                # mirrors for the new file below
│   │   └── data_wipe.dart              # NEW: extension on AppDatabase,
│   │                                    # `Future<void> deleteAllUserData()`,
│   │                                    # wraps every table's bulk delete in one
│   │                                    # `db.transaction()` block (research.md
│   │                                    # Decision 5) — genuinely cross-feature,
│   │                                    # same justification as balance_queries.dart
│   ├── design_system/                  # reused as-is
│   ├── di/                             # gains registrations for both features below
│   ├── error/                          # reused; no new Failure types needed beyond
│   │                                    # standard CacheFailure/UnknownFailure
│   ├── l10n/                           # gains Reports/Export/Delete ARB keys
│   └── routing/
│       └── app_router.dart              # gains /finance/reports (People branch,
│                                        # alongside 007's /finance routes) and
│                                        # /settings/export, /settings/delete-data
│                                        # (Settings branch)
│
├── features/
│   ├── people/                          # UNCHANGED — no new repository method
│   ├── transactions/                    # UNCHANGED — no new repository method
│   ├── finance/                         # gains Reports (Part A) — owned here
│   │   │                                # because it's finance data, per Principle II
│   │   ├── domain/usecases/
│   │   │   └── get_spending_trend.dart   # NEW — calls GetSummary once per month
│   │   │                                # in the requested range, concurrently
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   └── reports_cubit.dart     # NEW
│   │       ├── pages/
│   │       │   └── reports_page.dart      # NEW
│   │       └── widgets/
│   │           ├── monthly_trend_chart.dart     # NEW, CustomPainter-based, no
│   │           │                                 # new chart dependency
│   │           └── category_breakdown_chart.dart # NEW (reuses 007's
│   │                                              # CategoryBreakdownBar data
│   │                                              # shape where possible)
│   ├── settings/                        # gains the "Delete My Data" entry point
│   │   └── presentation/pages/settings_page.dart  # extended with a new Danger
│   │                                               # Zone section (not rebuilt)
│   └── data_privacy/                    # NEW (Part B)
│       ├── domain/
│       │   ├── entities/                # ExportResult (file path/size/format),
│       │   │                            # DeleteConfirmationInput (typed-phrase
│       │   │                            # value object)
│       │   ├── repositories/
│       │   │   └── data_wipe_repository.dart  # abstract, ONE method
│       │   ├── services/
│       │   │   └── share_service.dart    # abstract — Domain-facing platform
│       │   │                             # capability interface (Principle VI)
│       │   └── usecases/
│       │       ├── export_user_data.dart  # composes PeopleRepository +
│       │       │                          # TransactionsRepository +
│       │       │                          # CategoryRepository + FinanceRepository
│       │       │                          # + SettingsRepository (all pre-existing)
│       │       └── delete_all_user_data.dart  # wraps DataWipeRepository +
│       │                                       # re-runs OnboardingCubit's gate
│       ├── data/
│       │   ├── repositories/
│       │   │   └── data_wipe_repository_impl.dart  # wraps AppDatabase.deleteAllUserData()
│       │   └── services/
│       │       └── share_plus_service.dart  # ShareService impl, the ONLY file
│       │                                    # in this feature importing share_plus
│       └── presentation/
│           ├── cubit/
│           │   ├── export_cubit.dart      # idle/generating/ready/error
│           │   └── delete_account_cubit.dart  # confirming/deleting/success/error
│           ├── pages/
│           │   ├── data_export_page.dart
│           │   └── delete_data_confirmation_page.dart
│           └── widgets/
│               └── typed_confirmation_field.dart  # the phrase-matching input
│                                                   # gating the destructive button
│
└── main.dart                            # UNCHANGED

test/
├── core/database/
│   └── data_wipe_test.dart               # against an in-memory drift DB —
│                                          # proves true atomicity (a forced
│                                          # mid-wipe failure leaves every table
│                                          # fully intact)
└── features/
    ├── finance/
    │   ├── domain/usecases/get_spending_trend_test.dart
    │   └── presentation/cubit/reports_cubit_test.dart
    └── data_privacy/
        ├── domain/usecases/export_user_data_test.dart
        ├── domain/usecases/delete_all_user_data_test.dart
        └── presentation/cubit/{export_cubit_test.dart,delete_account_cubit_test.dart}

test/widget/
├── reports_page_test.dart                 # RTL chart mirroring, empty/error states
├── data_export_page_test.dart
└── delete_data_confirmation_page_test.dart # two-step confirmation gating

integration_test/
├── reports_flows_test.dart                 # trend + breakdown, period switch,
│                                            # empty/error states
└── data_privacy_flows_test.dart            # full export → verify file contents;
                                             # full delete → confirm reset to
                                             # onboarding; forced-failure delete →
                                             # confirm zero data loss
```

**Structure Decision**: Standard single Flutter app (Option 1 shape). Reports is added *inside* the existing `finance` feature module (not a new module) because it is finance data through and through, reusing 007's use cases and widgets directly, per constitution Principle II. Export/Delete get one new feature module, `lib/features/data_privacy/`, because they are the first capability in the roadmap that legitimately spans every existing feature's data equally — the same cross-feature justification already used for the Home Dashboard feature (012). One new `core/database/` file (`data_wipe.dart`) mirrors the existing `balance_queries.dart` precedent exactly, for the same reason: a genuinely cross-feature database concern that doesn't belong to any single feature's DAO. One new dependency, `share_plus`, isolated behind `ShareService`/`SharePlusService` so no other file in the codebase imports it directly.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
