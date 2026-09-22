# Implementation Plan: Proactive Insights & Reminders/Notifications

**Branch**: `017-proactive-insights-reminders` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/017-proactive-insights-reminders/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Add local, on-device-only push notifications (via `flutter_local_notifications` — this app's first-ever use of OS-level scheduled notifications) for two deterministic insight categories: budget-limit warnings (read-only over 010's existing `GetBudgetOverview`-equivalent aggregation) and savings-goal pace check-ins (read-only over 011's existing `GetSavingsGoalDetail`/`ProjectSavingsCompletion`-equivalent projection). A small `NotificationEngine` Domain service runs on a daily-plus-foreground-triggered schedule, computes each budgeted category's/goal's current threshold band, compares it against a locally-stored `NotificationHistory` record to enforce the cooldown/re-notification policy (spec Assumptions), and — when a real, materially-changed condition exists — schedules a notification composed from a deterministic, fully localized message template (with an optional, always-gracefully-degrading AI-Assistant rephrasing hook for a future spec 014). No backend, no network call anywhere in this feature.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc`, `get_it` + `injectable`, `drift` (existing, reused — gains one new small table), `fpdart`, `equatable`, `go_router`, `intl` (all existing, reused as-is), `flutter_local_notifications` (new — local notification scheduling/display/tap-handling, cross-platform). No network/HTTP dependency is introduced (FR-017). Reads (read-only) 010's `BudgetRepository`/`GetBudgetOverview`-equivalent and 011's `SavingsRepository`/`GetSavingsGoalDetail`-equivalent contracts, per those specs' own already-published `contracts/`.

**Storage**: One new small `drift` table, `NotificationHistory` (source type, source id, last-notified threshold band, applicable period, timestamp) — additive migration, `AppDatabase.schemaVersion` +1. `Notification Preference` (enabled flags, quiet-hours window) is a single small record; stored via the existing `drift` database for consistency with this app's one-source-of-truth-per-concern convention (unlike 015-app-lock-security's secure-storage choice, this data is not itself a security secret gating access to anything, so it has no reason to live outside the normal database — research.md Decision 1 documents this distinction explicitly). Zero changes to any existing table.

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail`, `integration_test` (budget crosses threshold → notification generated with correct real values → tap navigates correctly; savings goal pace changes → correct check-in; cooldown/band-change-only re-notification over a simulated multi-day period; quiet-hours deferral; feature disable/re-enable; permission-denied state).

**Target Platform**: Android and iOS mobile apps (existing app scope). `flutter_local_notifications` requires minor native setup (Android notification channel registration, iOS notification-permission entitlement) but no custom native platform code of this feature's own.

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: Daily recomputation completes in well under 1 second for a realistic data volume (dozens of budgeted categories, dozens of savings goals — well within 010/011's own existing performance envelopes, since this feature adds no new aggregation, only reads their outputs); notification delivery latency is bounded by the OS's own local-notification scheduling, not by this feature's code.

**Constraints**: Zero network calls anywhere in this feature (FR-017) — the single highest-priority architectural constraint, directly verified by a dedicated test (mirroring 016's own zero-network-activity assertion pattern). Every notification's content MUST trace back to a real 010/011 computation at generation time — enforced structurally by having `NotificationEngine` call 010's/011's repository interfaces directly rather than maintaining any cached/duplicated figure of its own (research.md Decision 2). The cooldown policy (FR-015) must be exactly band-change-triggered, not time-interval-triggered, to satisfy SC-003. OS notification permission is requested only contextually at first feature-enable (FR-011), never at app startup — this is the second (after 015-app-lock-security's biometric/camera-adjacent permissions) feature in this roadmap run to introduce a contextual OS permission prompt, and follows the exact same "ask at the point of need, explain why, handle denial gracefully" pattern.

**Scale/Scope**: Single user per device; `NotificationHistory` scales with the number of budgeted categories × months and savings goals, both small (tens, not thousands) per the existing 010/011 scale assumptions. ~2 new screens (Notification Settings, plus tap-deep-link handling into 010's/011's own already-existing detail screens — no new "notification detail" screen of its own). One new feature module (`insights_notifications`), zero changes to 010's or 011's domain/data layer (pure read-only consumption of their published contracts).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `insights_notifications` splits into `data/domain/presentation`; the notification-scheduling/OS-plugin interaction lives in Data behind a `NotificationScheduler` interface, never called directly from Domain or Presentation | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/insights_notifications/`; zero changes to 010's or 011's own domain/data layer — only read-only calls through their already-published repository interfaces | PASS |
| III. BLoC/Cubit Mandate | `NotificationSettingsCubit` for the settings screen; the background recomputation itself is a Domain/Data-layer process (`NotificationEngine`), not a Cubit, since it has no UI to drive directly (constitution: BLoC governs Presentation state, not background scheduling logic) | PASS |
| IV. Immutable State | `NotificationSettingsCubit`'s state is an `Equatable` value class updated via `copyWith()` | PASS |
| V. Domain-Driven Business Logic | Use cases/services: `EvaluateBudgetNotifications`, `EvaluateSavingsGoalNotifications` (each pure comparison logic over an already-fetched `BudgetOverview`/`SavingsGoalDetail`), `NotificationEngine` (orchestrates: fetch real data via 010/011 repos → evaluate → check `NotificationHistory` cooldown → compose message → schedule), `SetNotificationPreferences`, `RequestNotificationPermission`, `GetNotificationHistoryForSource` — each a meaningful, independently testable business action | PASS |
| VI. Repository Pattern | Domain defines `NotificationPreferenceRepository` and `NotificationHistoryRepository` (own this feature's own two small tables); Domain also defines `NotificationScheduler` (abstracts `flutter_local_notifications`) — all resolved via DI, never a concrete class depended on directly | PASS |
| VII. Explicit Error Handling | All repository/use-case calls return `Either<Failure, T>`; new typed failures `NotificationPermissionDeniedFailure`, `NotificationSchedulingFailure` alongside reused `core/error/failure.dart` types | PASS |
| VIII. Deterministic Financial Calculations | The entire point of this feature (spec FR-002/FR-003/FR-004): every notification's number traces directly to 010's/011's own already-deterministic, already-tested computation — `NotificationEngine` performs zero independent financial arithmetic of its own, only threshold-band comparison (a deterministic classification, not a calculation) over their outputs | PASS |
| IX. AI Isolation | The optional AI-phrasing hook (FR-008) sits behind a `NotificationPhrasingService` interface that defaults to the deterministic-template implementation (`TemplateNotificationPhrasingService`) and is swappable for a future spec-014-backed implementation without this feature's own code changing — AI, if ever wired in, only ever rephrases already-computed values, never supplies them (research.md Decision 3) | PASS |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is fully local; `NotificationHistory` writes are idempotent by construction (upserting the current threshold band per source+period, never appending duplicate rows for the same recomputation) | PASS |
| XII. Security & Secrets | No secrets; OS notification permission requested contextually at first enable (FR-011), never at startup, with a shown rationale, exactly per this principle's own permission-handling requirement | PASS |
| XIII. Localization & RTL/LTR | Every message template exists in both `ar`/`en` (`gen_l10n` ARB, parameterized with real computed values via `intl` message formatting, never raw string concatenation per constitution Principle XIII); Notification Settings screen fully localized/RTL-mirrored | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires `NotificationPreferenceRepository`, `NotificationHistoryRepository`, `NotificationScheduler`, `TemplateNotificationPhrasingService`, `NotificationEngine`, use cases, and `NotificationSettingsCubit`; nothing self-instantiated | PASS |
| XV. Design System | Reuses existing `core/design_system` (`AppButton`, toggles/switches already used elsewhere e.g. 003-dark-mode-theme's theme toggle, `AppCard`); no genuinely new visual component beyond a quiet-hours time-range picker, evaluated at task-planning time against whether a suitable existing component already covers it | PASS |
| XVI. Testability by Design | `EvaluateBudgetNotifications`/`EvaluateSavingsGoalNotifications`'s threshold-band classification logic is unit-tested exhaustively as pure functions over fake `BudgetOverview`/`SavingsGoalDetail` fixtures; `NotificationEngine`'s cooldown-policy orchestration tested against a fake `NotificationHistoryRepository`; `TemplateNotificationPhrasingService` tested for both locales; `NotificationSettingsCubit` tested with `bloc_test`/`mocktail`; `integration_test` for the full recompute→notify→tap→navigate flow with a `NotificationScheduler` test double (never actually spamming OS notifications during automated test runs) | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): Keeping `NotificationEngine` structurally incapable of computing its own financial figures — it only ever receives an already-computed `BudgetOverview`/`SavingsGoalDetail` from 010's/011's own repositories and classifies which threshold band that already-real data falls into — is the direct, minimal implementation of FR-002/FR-003/FR-004's "never a second computation path" requirement, not a design promise a future refactor could quietly violate. Isolating the optional AI-phrasing hook behind `NotificationPhrasingService` (research.md Decision 3) is what makes FR-008's "AI never supplies the number, only rephrases it" guarantee structural rather than aspirational: the interface's input type is the already-composed deterministic template result, not raw budget/goal data, so an AI implementation physically cannot substitute its own number. No new dependency beyond the one clearly justified local-notification package, no layering deviation. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/017-proactive-insights-reminders/
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
│   ├── database/                    # AppDatabase gains NotificationHistory +
│   │                                 # NotificationPreferences tables; schemaVersion +1,
│   │                                 # additive migration only; zero changes to any existing
│   │                                 # table (including 010's Budgets / 011's SavingsGoals)
│   ├── design_system/                # reused as-is
│   ├── di/                           # gains insights_notifications feature registrations
│   ├── error/                        # reused; gains NotificationPermissionDeniedFailure/
│   │                                 # NotificationSchedulingFailure
│   ├── l10n/                         # app_en.arb / app_ar.arb gain all notification message
│   │                                 # templates (parameterized, FR-007) + settings-screen keys
│   └── routing/                      # app_router.dart gains the notification-tap deep-link
│                                     # handler routing into 010's/011's existing detail routes
│                                     # (no new screen routes beyond Notification Settings)
│
├── features/
│   ├── budgets/                      # UNCHANGED (010) — exposes only its existing, already-
│   │                                 # public BudgetRepository/GetBudgetOverview-equivalent
│   ├── savings/                      # UNCHANGED (011) — exposes only its existing, already-
│   │                                 # public SavingsRepository/GetSavingsGoalDetail-equivalent
│   ├── settings/                     # UNCHANGED except a "Notifications" nav entry point
│   └── insights_notifications/       # NEW
│       ├── data/
│       │   ├── datasources/           # NotificationHistoryDao, NotificationPreferenceDao (drift)
│       │   ├── services/              # FlutterLocalNotificationsScheduler (implements
│       │   │                          # NotificationScheduler), TemplateNotificationPhrasingService
│       │   │                          # (implements NotificationPhrasingService)
│       │   └── repositories/          # NotificationHistoryRepositoryImpl,
│       │                              # NotificationPreferenceRepositoryImpl
│       ├── domain/
│       │   ├── entities/              # NotificationPreference, NotificationHistoryEntry,
│       │   │                          # ThresholdBand (enum: belowWarning/nearLimit/exceeded for
│       │   │                          # budgets; onPace/behindPace/aheadOfPace/achieved for
│       │   │                          # savings), ComposedNotification (title/body/deepLinkTarget)
│       │   ├── repositories/           # NotificationHistoryRepository,
│       │   │                          # NotificationPreferenceRepository (abstract)
│       │   ├── services/               # NotificationScheduler (abstract, wraps
│       │   │                          # flutter_local_notifications), NotificationPhrasingService
│       │   │                          # (abstract — TemplateNotificationPhrasingService is the
│       │   │                          # only implementation shipped by this feature)
│       │   └── usecases/               # EvaluateBudgetNotifications,
│       │                              # EvaluateSavingsGoalNotifications, NotificationEngine
│       │                              # (orchestrator, invoked by the daily/foreground trigger),
│       │                              # SetNotificationPreferences, RequestNotificationPermission,
│       │                              # HandleNotificationTap
│       └── presentation/
│           ├── cubit/                  # NotificationSettingsCubit
│           ├── pages/                   # NotificationSettingsPage
│           └── widgets/                 # QuietHoursRangePicker,
│                                       # NotificationCategoryToggleTile,
│                                       # PermissionDeniedBanner
│
└── main.dart                            # gains the daily/foreground recomputation-trigger
                                          # registration (e.g. WorkManager-equivalent or an
                                          # app-lifecycle-observer-driven check, research.md
                                          # Decision 4) alongside existing DI bootstrap

test/
├── features/
│   └── insights_notifications/
│       ├── domain/services/           # EvaluateBudgetNotifications/
│       │                              # EvaluateSavingsGoalNotifications pure-classification
│       │                              # unit tests — the most exhaustively tested files in this
│       │                              # feature (pure functions over fixture data, no I/O)
│       ├── domain/usecases/           # NotificationEngine orchestration tests (faked
│       │                              # repositories/scheduler), cooldown-policy correctness
│       ├── data/repositories/         # NotificationHistoryRepositoryImpl/
│       │                              # NotificationPreferenceRepositoryImpl tests against an
│       │                              # in-memory drift DB
│       └── presentation/cubit/        # bloc_test + mocktail
└── widget/                             # NotificationSettingsPage widget tests

integration_test/
└── insights_notifications_flows_test.dart  # budget crosses threshold -> notification with
                                             # correct real values -> tap navigates correctly;
                                             # savings goal pace change -> correct check-in;
                                             # band-unchanged-across-multiple-recomputations ->
                                             # exactly one notification (SC-003); quiet-hours
                                             # deferral; new-month band reset; permission denied
                                             # state; feature disable stops all future delivery
                                             # with zero effect on 010/011 data; zero-network-
                                             # activity assertion (mirrors 016's own pattern)
```

**Structure Decision**: Single new feature module `lib/features/insights_notifications/` following the established clean-architecture shape. Zero changes to 010's or 011's own domain/data layer — every read is through their already-published repository contracts. The only touches outside the new module are the `AppDatabase` migration (two small new tables), one Settings nav entry point, and the app-lifecycle-driven recomputation-trigger registration in `main.dart`.

## Complexity Tracking

*No Constitution Check violations — table intentionally omitted.*
