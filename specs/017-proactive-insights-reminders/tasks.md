---

description: "Task list template for feature implementation"
---

# Tasks: Proactive Insights & Reminders/Notifications

**Input**: Design documents from `/specs/017-proactive-insights-reminders/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present). **Note**: meaningful `integration_test` execution requires Budgets (010) and Savings Goals (011) implemented in code, not just spec'd — see quickstart.md Prerequisites. Unit/Cubit tasks below do not require this.

**Tests**: Included — the deterministic-observation guarantee (FR-002/FR-003/FR-004) and the cooldown policy (FR-015) are this feature's core compliance mechanisms and warrant explicit automated coverage, matching the precedent set by 011-savings-goals and 016-financial-education-wealth-planning.

**Organization**: Tasks are grouped by user story (spec.md) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US3)
- Include exact file paths in descriptions

## Path Conventions

Mobile Flutter app (existing structure): `lib/features/insights_notifications/{data,domain,presentation}/`, `test/features/insights_notifications/`, `integration_test/`.

---

## Phase 1: Setup

**Purpose**: Project initialization and dependency setup

- [ ] T001 Create the directory skeleton: `lib/features/insights_notifications/{data/{datasources,services,repositories},domain/{entities,repositories,services,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/features/insights_notifications/{domain/services,domain/usecases,data/repositories,presentation/cubit}/`.
- [ ] T002 Add `flutter_local_notifications` to `pubspec.yaml`; run `fvm flutter pub get`. Add Android notification-channel setup and iOS notification-capability entries per the plugin's own setup requirements.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core entities, the two new `drift` tables, the pure classification services, and the notification/phrasing abstractions that MUST exist before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 [P] Define the `NotificationPreference` entity (`isEnabled`, `budgetWarningsEnabled`, `savingsCheckInsEnabled`, `quietHoursStart?`, `quietHoursEnd?`, `osPermissionGranted`) in `lib/features/insights_notifications/domain/entities/notification_preference.dart`, per data-model.md.
- [ ] T004 [P] Define the `ThresholdBand` enum (`belowWarning`/`nearLimit`/`exceeded` for budgets; `onPace`/`behindPace`/`aheadOfPace`/`achieved`/`noEstimateAvailable` for savings) and the `NotificationHistoryEntry` entity (`id`, `sourceType`, `sourceId`, `applicablePeriod?`, `lastNotifiedBand`, `lastNotifiedAt`) in `lib/features/insights_notifications/domain/entities/notification_history_entry.dart`, per data-model.md.
- [ ] T005 [P] Define `ComposedNotification` (`title`, `body`, `deepLinkTarget: NotificationDeepLinkTarget`) and `NotificationDeepLinkTarget` (`type: budgetCategory|savingsGoal`, `id`) in `lib/features/insights_notifications/domain/entities/composed_notification.dart`, per data-model.md.
- [ ] T006 [P] Define `BudgetNotificationCandidate` and `SavingsGoalNotificationCandidate` value objects in `lib/features/insights_notifications/domain/entities/notification_candidate.dart`, per contracts/notification_engine.md.
- [ ] T007 [P] Add `NotificationPermissionDeniedFailure`, `NotificationSchedulingFailure` to `lib/features/insights_notifications/domain/entities/notification_failures.dart`, extending the core `Failure`.
- [ ] T008 Update `lib/core/database/app_database.dart`: add `NotificationPreferences` and `NotificationHistory` drift tables per data-model.md's Drift Schema Sketch (`UNIQUE INDEX idx_notification_history_source` on `(source_type, source_id, applicable_period)`); bump `schemaVersion` by 1 with the additive `onUpgrade` step. **Zero changes to any existing table.** Run `dart run build_runner build --delete-conflicting-outputs`.
- [ ] T009 Implement the pure `EvaluateBudgetNotifications` interface and implementation in `lib/features/insights_notifications/domain/services/evaluate_budget_notifications.dart`: classifies each budgeted category from an already-fetched `BudgetOverview` (010) into a `ThresholdBand` using 010's own near-full threshold (spec FR-003), taking zero repository/I/O dependency (research.md Decision 2) — per `contracts/notification_engine.md`.
- [ ] T010 [P] **Exhaustive unit test** `EvaluateBudgetNotifications` against fixture `BudgetOverview` data covering every band boundary (just below warning threshold, exactly at threshold, between threshold and 100%, exactly 100%, above 100%) — in `test/features/insights_notifications/domain/services/evaluate_budget_notifications_test.dart`. Confirms via mock/fixture inspection that the service never imports or calls `FinanceRepository`/`AppDatabase` directly (structural non-duplication check).
- [ ] T011 Implement the pure `EvaluateSavingsGoalNotifications` interface and implementation in `lib/features/insights_notifications/domain/services/evaluate_savings_goal_notifications.dart`: returns `null` for a goal with no monthly contribution and no target date (FR-005), classifies `onPace`/`behindPace`/`aheadOfPace`/`achieved` from an already-fetched `SavingsGoalDetail` (011)'s own `GoalProgress`/`EstimatedCompletion`, zero repository dependency — per `contracts/notification_engine.md`.
- [ ] T012 [P] **Exhaustive unit test** `EvaluateSavingsGoalNotifications`: behind-pace, ahead-of-pace, achieved, no-estimate-available (returns null, not a candidate) cases — in `test/features/insights_notifications/domain/services/evaluate_savings_goal_notifications_test.dart`.
- [ ] T013 Define the `NotificationScheduler` abstract interface (`requestPermission`, `hasPermission`, `scheduleOrDeliver`) in `lib/features/insights_notifications/domain/services/notification_scheduler.dart` per `contracts/notification_engine.md`, and implement `FlutterLocalNotificationsScheduler` in `lib/features/insights_notifications/data/services/flutter_local_notifications_scheduler.dart` wrapping the `flutter_local_notifications` plugin, encoding `deepLinkTarget` into the platform payload for tap-handling.
- [ ] T014 [P] Test `FlutterLocalNotificationsScheduler` against the plugin's own test/mock channel (no real OS notification spam during automated test runs, per plan.md Testability gate) — in `test/features/insights_notifications/data/services/flutter_local_notifications_scheduler_test.dart`.
- [ ] T015 Define the `NotificationPhrasingService` abstract interface (`compose(ComposedNotification draft) -> ComposedNotification`) in `lib/features/insights_notifications/domain/services/notification_phrasing_service.dart` per `contracts/notification_engine.md`/research.md Decision 3, and implement `TemplateNotificationPhrasingService` in `lib/features/insights_notifications/data/services/template_notification_phrasing_service.dart` returning its input unchanged (the real composition work happens via `gen_l10n` templates before this service is ever called, per FR-007).
- [ ] T016 [P] Test `TemplateNotificationPhrasingService`: confirms `compose()` is a pure identity pass-through, and confirms — by type-signature/structural review documented as a test assertion — that this interface's parameter type makes it impossible to accept raw `BudgetNotificationCandidate`/`SavingsGoalNotificationCandidate` data (FR-008's structural guarantee) — in `test/features/insights_notifications/domain/services/notification_phrasing_service_test.dart`.
- [ ] T017 [P] Repository test against an in-memory `NativeDatabase.memory()`: `NotificationHistoryRepositoryImpl`'s upsert-on-band-change-only behavior and its `UNIQUE(source_type, source_id, applicable_period)` uniqueness — in `test/features/insights_notifications/data/repositories/notification_history_repository_impl_test.dart`.
- [ ] T018 Define `NotificationHistoryRepository` and `NotificationPreferenceRepository` abstract interfaces in `lib/features/insights_notifications/domain/repositories/`, and implement `NotificationHistoryRepositoryImpl`/`NotificationPreferenceRepositoryImpl` in `lib/features/insights_notifications/data/repositories/` composing drift DAOs (T008).
- [ ] T019 Register `NotificationHistoryRepositoryImpl`, `NotificationPreferenceRepositoryImpl`, `FlutterLocalNotificationsScheduler` (as `NotificationScheduler`), `TemplateNotificationPhrasingService` (as `NotificationPhrasingService`), `EvaluateBudgetNotifications`, `EvaluateSavingsGoalNotifications` with `@injectable`/`@LazySingleton(as: ...)` in `lib/core/di/`; run `fvm dart run build_runner build --delete-conflicting-outputs`.
- [ ] T020 Add all notification message templates (near-limit, exceeded, behind-pace, ahead-of-pace, achieved) as parameterized `gen_l10n` messages to `lib/core/l10n/app_en.arb`/`app_ar.arb` (FR-007, constitution Principle XIII — never raw string concatenation); regenerate `AppLocalizations`.

**Checkpoint**: Foundation ready — both new tables, the two exhaustively-tested pure classification services, the scheduler/phrasing abstractions, and localized templates all exist. User story implementation can now begin.

---

## Phase 3: User Story 1 - Receive a Budget-Limit Warning (Priority: P1) 🎯 MVP (part 1 of 2)

**Goal**: A real over-threshold budget condition generates a correctly-worded notification, sourced entirely from 010's existing aggregation, with correct cooldown and deep-link behavior.

**Independent Test**: Push a budgeted category's actual spend past a warning/exceeded threshold, trigger recomputation, confirm the notification's values match the Budgets screen exactly, and confirm tapping it navigates correctly; confirm no duplicate fires on an unchanged band.

### Tests for User Story 1 ⚠️

- [ ] T021 [P] [US1] Unit test `NotificationEngine.run()`'s budget-category path: calls `BudgetRepository` (010, mocked) read-only, calls `EvaluateBudgetNotifications` (T009), compares against `NotificationHistoryRepository` (mocked), composes via `TemplateNotificationPhrasingService`, calls `NotificationScheduler.scheduleOrDeliver` only for a real band change — verified via mock interaction assertions — in `test/features/insights_notifications/domain/usecases/notification_engine_budget_test.dart`.
- [ ] T022 [P] [US1] Unit test confirming a repeated `run()` call with an unchanged budget band produces zero additional `NotificationScheduler.scheduleOrDeliver` calls (the cooldown policy, FR-015) — extend `test/features/insights_notifications/domain/usecases/notification_engine_budget_test.dart`.
- [ ] T023 [P] [US1] Unit test `HandleNotificationTap` for a `budgetCategory` deep-link target: resolves to the correct navigation target; resolves to a graceful "no longer exists" state when the underlying budget/category has since been deleted (FR-014, Edge Cases) — in `test/features/insights_notifications/domain/usecases/handle_notification_tap_test.dart`.

### Implementation for User Story 1

- [ ] T024 [US1] Implement `lib/features/insights_notifications/domain/usecases/notification_engine.dart` (the `NotificationEngine` implementation): fetches `NotificationPreference`, short-circuits if disabled (FR-018) or if `budgetWarningsEnabled` is false, otherwise fetches each current-period `BudgetOverview` from `BudgetRepository` (010), runs `EvaluateBudgetNotifications` (T009), and for each candidate whose band differs from its `NotificationHistoryEntry`, composes via `gen_l10n` (T020) + `TemplateNotificationPhrasingService` (T015), applies quiet-hours deferral logic (checks `NotificationPreference.quietHoursStart/End`), and calls `NotificationScheduler.scheduleOrDeliver` (depends on T009, T015, T018, T020).
- [ ] T025 [P] [US1] Implement `lib/features/insights_notifications/domain/usecases/handle_notification_tap.dart`: resolves a `NotificationDeepLinkTarget` into a concrete navigation action, checking the source still exists via a read-only `BudgetRepository`/`SavingsRepository` call and returning a "no longer exists" signal otherwise (FR-014).
- [ ] T026 Annotate the US1 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T024, T025).
- [ ] T027 [US1] Wire `NotificationEngine.run()` (T024) into the recomputation trigger scaffold (research.md Decision 4/5 — daily fixed-time + foreground catch-up), registered in `lib/main.dart` alongside existing DI bootstrap. If 015-app-lock-security's `AppLifecycleObserver` already exists in the codebase at this point, extend/reuse it per research.md Decision 5; otherwise implement a minimal local lifecycle listener here with a documented follow-up to consolidate later.
- [ ] T028 [US1] Wire `HandleNotificationTap` (T025) into `lib/core/routing/app_router.dart`'s notification-tap payload handler (from `FlutterLocalNotificationsScheduler`'s tap callback), navigating into 010's existing budget-category-detail route.

**Checkpoint**: User Story 1 fully functional and independently testable — budget-limit warnings fire correctly from real data, respect cooldown, and deep-link correctly.

---

## Phase 4: User Story 2 - Receive a Savings-Goal Check-In (Priority: P1) 🎯 MVP (part 2 of 2)

**Goal**: A real pace divergence on a savings goal generates a correctly-worded check-in, sourced entirely from 011's existing projection, with correct achieved-state handling and deep-link behavior.

**Independent Test**: Create a savings goal, diverge its real contribution pace from its plan, trigger recomputation, confirm the notification's values match the goal detail screen's own projection exactly.

### Tests for User Story 2 ⚠️

- [ ] T029 [P] [US2] Unit test `NotificationEngine.run()`'s savings-goal path: calls `SavingsRepository` (011, mocked) read-only, calls `EvaluateSavingsGoalNotifications` (T011), skips goals with `noEstimateAvailable`/null candidates (FR-005), composes and schedules only for a real band change, generates the one-time achievement notification exactly once per goal newly reaching achieved (FR-006) — extend `test/features/insights_notifications/domain/usecases/notification_engine_savings_test.dart`.
- [ ] T030 [P] [US2] Unit test confirming an already-achieved goal at the time this feature is first enabled does NOT fire a spurious first-ever achievement notification (data-model.md's "no transition from unknown" resolution) — extend the same test file.
- [ ] T031 [P] [US2] Unit test `HandleNotificationTap` for a `savingsGoal` deep-link target, including the stale-goal "no longer exists" case — extend `test/features/insights_notifications/domain/usecases/handle_notification_tap_test.dart` (T023).

### Implementation for User Story 2

- [ ] T032 [US2] Extend `NotificationEngine` (T024) with the savings-goal evaluation path: fetches each active `SavingsGoalDetail` from `SavingsRepository` (011) when `savingsCheckInsEnabled` is true, runs `EvaluateSavingsGoalNotifications` (T011), applies the same band-change/cooldown/quiet-hours/compose/schedule pipeline as the budget path (depends on T011, T015, T018, T020, T024).
- [ ] T033 Extend `HandleNotificationTap` (T025) for `savingsGoal` targets, checking existence via `SavingsRepository` (depends on T025).
- [ ] T034 Wire the savings-goal deep-link case into `lib/core/routing/app_router.dart`'s notification-tap handler, navigating into 011's existing goal-detail route (depends on T028, T033).

**Checkpoint**: User Stories 1 AND 2 together deliver the full P1 MVP — both notification categories fire correctly from real data with correct cooldown, quiet-hours, and deep-link behavior.

---

## Phase 5: User Story 3 - Control Notification Settings (Priority: P2)

**Goal**: The user can enable/disable the feature and each category, handle OS permission contextually, and configure quiet hours, all correctly reflected in behavior.

**Independent Test**: Open settings, enable the feature (triggering the contextual permission prompt), toggle a category off, set quiet hours, and confirm each control's effect matches exactly.

### Tests for User Story 3 ⚠️

- [ ] T035 [P] [US3] Unit test `SetNotificationPreferences`: persists enable/disable, per-category toggles, quiet-hours window; rejects a quiet-hours configuration with only one of start/end set (data-model.md pairing rule) — in `test/features/insights_notifications/domain/usecases/set_notification_preferences_test.dart`.
- [ ] T036 [P] [US3] Unit test `RequestNotificationPermission`: calls `NotificationScheduler.requestPermission()` only when invoked (never proactively), persists the resulting `osPermissionGranted` state — in `test/features/insights_notifications/domain/usecases/request_notification_permission_test.dart`.
- [ ] T037 [P] [US3] `bloc_test` for `NotificationSettingsCubit`: first-open default-off state, enable-triggers-permission-request flow, denied-state banner display, quiet-hours set/clear, category toggles, disable-stops-future-delivery (verified via a mock `NotificationEngine`/preference check, not a live scheduled run) — in `test/features/insights_notifications/presentation/cubit/notification_settings_cubit_test.dart`.

### Implementation for User Story 3

- [ ] T038 [P] [US3] Implement `lib/features/insights_notifications/domain/usecases/set_notification_preferences.dart` wrapping `NotificationPreferenceRepository` (T018).
- [ ] T039 [P] [US3] Implement `lib/features/insights_notifications/domain/usecases/request_notification_permission.dart` wrapping `NotificationScheduler.requestPermission()` (T013) + persisting the result via `NotificationPreferenceRepository`.
- [ ] T040 Annotate the US3 use cases with `@injectable`; re-run `fvm dart run build_runner build --delete-conflicting-outputs` (depends on T038, T039).
- [ ] T041 [US3] Implement `lib/features/insights_notifications/presentation/cubit/notification_settings_cubit.dart` + state: loads current preferences, enable action triggers `RequestNotificationPermission` (T039) contextually (FR-011), denied-state handling, category toggles, quiet-hours set/clear, all persisted via `SetNotificationPreferences` (T038) (depends on T038-T040).
- [ ] T042 [P] [US3] Implement `lib/features/insights_notifications/presentation/widgets/quiet_hours_range_picker.dart` (pre-fills the suggested 22:00–08:00 device-local default per spec.md Assumptions "Quiet hours default", fully user-editable — never hardcoded behavior), `notification_category_toggle_tile.dart`, and `permission_denied_banner.dart` (with a link to device app-permission settings, FR-012).
- [ ] T043 [US3] Implement `lib/features/insights_notifications/presentation/pages/notification_settings_page.dart` using T041/T042 (depends on T041, T042).
- [ ] T044 Register `/settings/notifications` route in `lib/core/routing/app_router.dart`, and add a "Notifications" entry point from `lib/features/settings/presentation/pages/settings_page.dart` (research.md/spec.md Assumptions) (depends on T043).

**Checkpoint**: User Story 3 independently testable — full user control over the feature exists, with correct contextual-permission and quiet-hours behavior.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Localization completeness, theming, performance, full regression, and final constitution compliance pass

- [ ] T045 [P] Add all remaining UI-chrome strings (settings screen labels, toggle descriptions, quiet-hours picker copy, permission-denied banner copy) to `lib/core/l10n/app_en.arb`/`app_ar.arb`, alongside the notification templates already added in T020 (FR-020).
- [ ] T046 [P] RTL/LTR and theme pass: verify `NotificationSettingsPage` (including the quiet-hours picker and permission-denied banner) renders correctly in Arabic RTL and English LTR, and in both light and dark mode (FR-020, SC-007).
- [ ] T047 [P] Zero-network-activity audit pass across a full recomputation cycle (mirroring 016-financial-education-wealth-planning's own pattern) confirming this feature makes no network call anywhere (FR-017).
- [ ] T048 Write `integration_test/insights_notifications_flows_test.dart` covering: budget crosses threshold → correct notification → correct tap navigation (US1); savings goal pace change → correct check-in → achievement one-time firing (US2); band-unchanged-across-multiple-recomputations → exactly one notification total (SC-003); new-month band reset (FR-016); quiet-hours deferral; permission-denied state; feature disable stops all future delivery with zero effect on 010/011 data (US3) — per quickstart.md's manual scenarios. **Requires 010/011 implemented in code** (plan.md/quickstart.md note) — if not yet implemented at the time this task runs, stub against their published contracts and flag the gap explicitly rather than skipping silently.
- [ ] T049 Run `fvm flutter analyze` and `fvm flutter format`, fix all warnings (no `// ignore` suppressions without a documented reason).
- [ ] T050 Run the full `fvm flutter test` suite and `fvm flutter test integration_test`; confirm all pass, with special attention to T010/T012 (the two exhaustive classification suites) and T022/T030 (cooldown and no-spurious-first-achievement correctness).
- [ ] T051 Code-review pass against the constitution's Definition of Done checklist and Principle VIII specifically: grep `lib/features/insights_notifications/domain/services/` to confirm `EvaluateBudgetNotifications`/`EvaluateSavingsGoalNotifications` never import `FinanceRepository`, `AppDatabase`, or any DAO directly (structural non-duplication guarantee, research.md Decision 2); confirm `NotificationPhrasingService`'s only shipped implementation is a pure identity pass-through (research.md Decision 3); confirm zero changes were made to any existing feature's table, entity, or calculation (FR-021) outside `lib/features/insights_notifications/`, `lib/core/database/app_database.dart` (additive only), `lib/core/di/`, `lib/core/l10n/`, `lib/core/routing/`, `lib/features/settings/` (one entry point), and `lib/main.dart` (one trigger registration).

---

## Dependencies & Execution Order

- **Phase 1 (Setup)** → **Phase 2 (Foundational)**: strictly sequential; Phase 2 blocks every user story.
- **Phase 3 (US1)** and **Phase 4 (US2)** together form the P1 MVP; US2 extends `NotificationEngine`/`HandleNotificationTap` created in US1, so US2 has a soft dependency on US1's implementation existing, though its own evaluation service (T011/T012, built in Phase 2) is independent.
- **Phase 5 (US3)** is P2 and depends on `NotificationPreference` (Phase 2, T003/T018) but is otherwise independent of US1/US2's own implementation — could be built in parallel with US1/US2 by a different contributor, since its Cubit reads/writes preferences without needing the engine's evaluation paths to exist yet (though end-to-end enable→notification-fires testing naturally waits for US1/US2).
- **Phase 6 (Polish)** runs last, after all desired user stories are implemented.

## Parallel Execution Examples

- Within Phase 2: T003-T007 (entities/failures) in parallel; T010, T012, T014, T016, T017 (test tasks) in parallel with each other once their respective implementation tasks land.
- Within Phase 3 (US1): T021-T023 in parallel; T024-T025 can proceed in parallel with each other (different files) though T024 is the larger task.
- Across phases: once Phase 2 is complete, US1 (Phase 3), US2's evaluation-layer tests (already covered in Phase 2 via T011/T012), and US3 (Phase 5) can be staffed in parallel by different contributors, since US3 depends only on Phase 2's `NotificationPreference`/`NotificationPreferenceRepository`, not on US1/US2's engine implementation landing first.

## Implementation Strategy

**MVP first**: Phases 1-4 (Setup, Foundational, US1, US2) deliver the feature's core promise — real, deterministic budget and savings-goal notifications firing correctly with cooldown and deep-linking — and are independently demoable/testable per quickstart.md Scenarios 1-2 (once 010/011 are implemented). Phase 5 (user control/settings) is additive and can ship in either order relative to US1/US2 given its independence, though it is sequenced last here to match its P2 priority in spec.md. Phase 6 always runs last regardless of how many user-story phases have shipped so far.
