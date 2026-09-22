# Implementation Plan: Home Dashboard

**Branch**: `012-home-dashboard` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/012-home-dashboard/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Turn the existing `/overview` screen into the app's real "financial snapshot + quick actions" home, per `docs/project.txt` §12 and roadmap §V1.5.2: one screen presenting the existing person-to-person balance totals (`GetOverview`, unchanged) side by side with this month's income/expense/net (`GetFinanceSummary`, from feature 007, unchanged), five one-tap quick actions into existing forms, and two honest placeholder sections (Insights, Upcoming) that show real "not yet available" copy instead of any fabricated content. A new `lib/features/dashboard/` feature module owns the one genuinely new piece of logic — `GetDashboardSnapshot`, a Domain use case that coordinates `GetOverview` + `GetFinanceSummary` in parallel and determines the single combined first-run empty state — because that coordination legitimately belongs to neither `transactions` nor `finance` alone (mirrors 007's own precedent of keeping `finance` structurally separate from `transactions` rather than forcing a merge, research.md Decision 1 in 007). The existing `OverviewPage`/`OverviewCubit`/`OverviewState`/`OverviewSummaryCard` are relocated into this new feature (renamed `HomePage`/`DashboardCubit`/`DashboardState`, widget kept as-is) rather than left split across two feature folders. No new database tables/columns; no new dependency; reuses `core/design_system` throughout. `/overview`'s route path is kept unchanged (only its builder and the bottom-nav label change) so this reads as an in-place extension, not a new destination.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc` (state management, per constitution Principle III), `get_it` + `injectable` for dependency injection, `fpdart` for `Either<Failure, Success>` result flow, `equatable` for value equality, `intl` (`flutter_localizations`/`gen_l10n`) for Arabic/English localization and EGP formatting, `go_router` for declarative navigation. No new package dependency is required for this feature — it is pure coordination and presentation over two already-existing repositories.

**Storage**: No new storage. Reads (never writes) via the existing `TransactionsRepository.getOverview()` (unchanged) and the existing `FinanceRepository.getSummary()`/`getHistory()` (from feature 007, unchanged). This feature adds zero tables, columns, or migrations.

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail` (Cubit unit tests with faked use cases), `integration_test` (critical end-to-end flow: open Home → see snapshot → tap a quick action → return → snapshot reflects the change).

**Target Platform**: Android and iOS mobile apps (existing app scope).

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: Both aggregates load and render within 1s of a warm app start (SC-001), matching the existing `OverviewPage`'s already-proven load time for `GetOverview` alone, now run in parallel with `GetFinanceSummary` rather than added serially. Quick-action navigation must feel instantaneous (<100ms to route push) since these are the app's highest-frequency taps.

**Constraints**: Fully offline-capable (no network dependency at all, FR-015); this feature MUST NOT alter the calculation logic of `GetOverview` or `GetFinanceSummary` (FR-016) — it only coordinates and presents already-correct data; the two aggregates MUST fail/succeed/retry independently (FR-003); Insights/Upcoming MUST never render fabricated content (FR-009/FR-010, constitution Principle IX's non-authoritative-AI spirit applied here even though no AI is involved yet — the rule is "never simulate a capability that doesn't exist").

**Scale/Scope**: Single user per device; 1 feature module (`dashboard`), 1 screen (`HomePage`, the relabeled/extended `/overview` route), no new backend/API surface.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `dashboard` splits into `domain/presentation` (no `data/` — it has no repository or datasource of its own, it only composes existing use cases from `transactions`/`finance`); screens never touch a repository/DB directly | PASS |
| II. Feature-First Modularity | New `lib/features/dashboard/` is justified as genuine cross-feature coordination (composes `transactions` + `finance`), not a catch-all; no code moves into `core/` except the small, genuinely-shared `FeatureFlags` (Decision 4) | PASS |
| III. BLoC/Cubit Mandate | `DashboardCubit` (replaces `OverviewCubit` 1:1, per roadmap §V1.5.2); immutable state, explicit loading/success/partial-error/empty transitions | PASS |
| IV. Immutable State | `DashboardState` is an `Equatable` value class updated via `copyWith()`; two independent sub-statuses (Decision 2) are plain enum fields, never mutated in place | PASS |
| V. Domain-Driven Business Logic | `GetDashboardSnapshot` is a genuine multi-use-case coordinator (parallel `GetOverview` + `GetFinanceSummary` + an existence check for the combined empty state) — not a trivial passthrough, satisfies Principle V's "real architectural value" bar explicitly | PASS |
| VI. Repository Pattern | Not applicable at the `dashboard` layer — it has no repository of its own by design (Decision 1); it depends only on the existing `GetOverview`/`GetFinanceSummary`/`GetFinanceHistory` use case abstractions, injected via DI, never a concrete repository impl | PASS (N/A for a new repository) |
| VII. Explicit Error Handling | `GetDashboardSnapshot` surfaces each sub-result's `Either<Failure, T>` independently (Decision 2) rather than collapsing both into one failure; no empty catches | PASS |
| VIII. Deterministic Financial Calculations | No new calculation — this feature strictly re-presents `GetOverview`/`GetFinanceSummary` output; FR-016 makes this an explicit, testable requirement | PASS |
| IX. AI Isolation | Not applicable — no AI integration; the Insights section's "not yet available" copy is static, honest UI text, not an AI output | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — the Scan Paper quick-action slot is a hidden/disabled placeholder only, no OCR logic exists or is stubbed here | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is local-only, read-only; no mutation happens on this screen (quick actions navigate to existing forms that already handle their own idempotency) | PASS |
| XII. Security & Secrets | No secrets; no new data at rest | PASS (N/A) |
| XIII. Localization & RTL/LTR | New ARB keys for Home/snapshot/quick-action/Insights/Upcoming labels; ambient `Directionality` continues to drive card/quick-action-row mirroring with no custom RTL logic, consistent with `MainShell`'s existing precedent | PASS |
| XIV. Dependency Injection | `GetDashboardSnapshot` and `DashboardCubit` registered via `get_it`/`injectable`; nothing self-instantiated | PASS |
| XV. Design System | Reuses `AppCard`, `AppEmptyView`, `AppButton`, design tokens, and the existing `OverviewSummaryCard` widget (relocated, not duplicated, Decision 1); the only genuinely new widgets are a `QuickActionButton`/`QuickActionRow` and two placeholder-section widgets (Insights/Upcoming), built in `features/dashboard/presentation/widgets/` first, promoted to `core/` only if a later feature needs the same ones | PASS |
| XVI. Testability by Design | `GetDashboardSnapshot` unit-tested with faked use cases; `DashboardCubit` tested with `bloc_test`/`mocktail` covering loading/success/partial-error (both directions)/full-failure/combined-empty; widget tests for `HomePage`'s quick actions and empty/error states; one `integration_test/dashboard_flows_test.dart` | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): Relocating `OverviewPage`/`OverviewCubit`/`OverviewState`/`OverviewSummaryCard` from `transactions/presentation/` into `dashboard/presentation/` (Decision 1) is a mechanical move + rename, not a rewrite — existing behavior (balance totals, "all settled" state, person rows) is preserved exactly, satisfying the constitution's Refactoring Discipline ("preserve required functionality... avoid unrelated changes"). `GetOverview` itself, its entity (`OverviewSummary`), and its repository stay in `transactions/domain/` untouched — only the *presentation* layer that renders it moves, because presentation is where cross-feature composition with `finance` actually happens. No new dependency, layering violation, or state-management deviation was introduced; all gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/012-home-dashboard/
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
│   ├── config/                    # NEW: feature_flags.dart (Decision 4) — the only
│   │                                # genuinely cross-feature addition, since Occasions
│   │                                # and OCR (future features) will each flip one flag
│   │                                # here when they ship
│   ├── database/                   # UNCHANGED — no schema change
│   ├── design_system/              # reused as-is
│   ├── di/                         # gains dashboard feature registrations (generated)
│   ├── error/                      # reused; no new Failure types needed
│   ├── l10n/                       # app_en.arb / app_ar.arb gain Home/dashboard keys
│   └── routing/
│       ├── app_router.dart          # /overview route's builder swapped to HomePage;
│       │                            # path string itself is unchanged (spec Assumption)
│       └── main_shell.dart          # bottom-nav label swapped from l10n.overviewTitle
│                                     # to l10n.homeTitle; People remains tab index 0
│
├── features/
│   ├── people/                     # UNCHANGED
│   ├── transactions/                # `GetOverview`, `OverviewSummary`, `PersonSummary`,
│   │   │                            # `TransactionsRepository` all UNCHANGED and stay here
│   │   ├── domain/                  # (this feature only ever calls GetOverview.call())
│   │   └── presentation/            # loses overview_page.dart/overview_cubit.dart/
│   │                                # overview_state.dart/overview_summary_card.dart
│   │                                # (relocated to dashboard/, Decision 1) — every other
│   │                                # transactions screen (person detail, transaction
│   │                                # forms) is untouched
│   ├── finance/                     # NOT part of this feature — feature 007 owns it;
│   │                                # this feature only calls its GetFinanceSummary and
│   │                                # GetFinanceHistory use cases once 007 ships
│   ├── settings/                    # UNCHANGED
│   ├── onboarding/                  # UNCHANGED
│   └── dashboard/                   # NEW
│       ├── domain/
│       │   ├── entities/            # DashboardSnapshot (composes OverviewSummary? +
│       │   │                        # FinanceSummary?, each independently nullable/
│       │   │                        # failed per Decision 2)
│       │   └── usecases/            # GetDashboardSnapshot (coordinates GetOverview +
│       │                            # GetFinanceSummary + a GetFinanceHistory(limit:1)
│       │                            # existence check, Decision 3)
│       └── presentation/
│           ├── cubit/               # DashboardCubit, DashboardState (was OverviewCubit/
│           │                        # OverviewState, relocated + extended)
│           ├── pages/                # HomePage (was OverviewPage, relocated + extended
│           │                        # with Quick Actions/Insights/Upcoming sections)
│           └── widgets/              # OverviewSummaryCard (relocated as-is),
│                                     # FinanceSnapshotCard, QuickActionRow,
│                                     # QuickActionButton, InsightsPlaceholderCard,
│                                     # UpcomingPlaceholderCard
│
└── main.dart                        # UNCHANGED (dashboard Cubit resolved per-screen via
                                      # DI like every other feature's Cubit already is)

test/
├── core/config/                     # feature_flags_test.dart (trivial, documents the
│                                     # two flags default to false/hidden)
└── features/
    └── dashboard/
        ├── domain/usecases/          # get_dashboard_snapshot_test.dart (faked use cases)
        └── presentation/cubit/       # dashboard_cubit_test.dart (bloc_test + mocktail)

test/widget/
└── home_page_test.dart               # quick actions, partial-error, combined-empty,
                                       # full-failure, Insights/Upcoming honesty (SC-004)

integration_test/
└── dashboard_flows_test.dart          # open Home → snapshot renders → tap each quick
                                        # action → return → snapshot reflects the change;
                                        # simulated single-source failure → retry
```

**Structure Decision**: Standard single Flutter app (Option 1 shape), one new feature-first module `lib/features/dashboard/` added alongside the five existing features, per constitution Principle II — justified because it is the first genuine cross-feature coordination point in the app (composes `transactions` + `finance`), which neither existing feature should own. The existing `OverviewPage`/`OverviewCubit`/`OverviewState`/`OverviewSummaryCard` relocate here (renamed) rather than being duplicated or left split across two folders; `GetOverview` and its entities stay in `transactions/domain/` since balance calculation is still legitimately owned there. One new tiny cross-cutting file, `lib/core/config/feature_flags.dart`, is added to `core/` — justified per Principle II because the two flags it holds (Occasions, Scan Paper quick actions) are read by this feature today and will be *written to* (flipped on) by two entirely separate future features (Occasions, OCR) when they ship, making it a genuine shared, stable, cross-feature concern rather than a premature abstraction.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
