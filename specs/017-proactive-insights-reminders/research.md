# Phase 0 Research: Proactive Insights & Reminders/Notifications

## 1. Notification preferences/history storage: `drift`, not secure storage

**Decision**: `NotificationPreference` and `NotificationHistory` live in the existing `AppDatabase` (`drift`/SQLite), as two small new additive tables — unlike 015-app-lock-security's `AppLockConfig`, which deliberately lives in OS secure storage.

**Rationale**: 015's App Lock data governs access to `AppDatabase` itself, creating a circularity that forces it outside that database (015's research.md Decision 2). This feature's data has no such property — a notification preference or a "last notified band" record is ordinary application state, not a security secret, and gating it behind secure storage would add friction (async platform-channel reads instead of a simple query) with zero security benefit. Using `drift` also lets `NotificationHistory` participate in the same DB-transaction/query patterns already established throughout the app.

**Alternatives considered**: `flutter_secure_storage` (matching 015's pattern) — rejected as inconsistent with this data's actual sensitivity level (none) and unnecessarily complicating simple preference reads/writes; `shared_preferences` for preferences only — rejected in favor of one consistent storage mechanism (`drift`) for both the preference record and the history table, avoiding a second ad hoc local-storage mechanism for no benefit.

## 2. `NotificationEngine` never computes a financial figure itself

**Decision**: `NotificationEngine` and its two evaluators (`EvaluateBudgetNotifications`, `EvaluateSavingsGoalNotifications`) accept an already-fetched `BudgetOverview` (010) / `SavingsGoalDetail` (011) as input and perform only **threshold-band classification** (a pure comparison/categorization, not a calculation) over fields those objects already expose (`percentageUsed`, `isOverBudget`, `estimatedCompletion` vs. elapsed-time-implied pace). Neither evaluator queries `AppDatabase` directly, calls `FinanceRepository`, or re-derives spend/progress from raw transaction rows.

**Rationale**: This is the direct structural enforcement of spec FR-002/FR-003/FR-004 ("never a second, independently implemented spend/projection calculation") discussed in plan.md's Constitution Check — by construction, this feature's code has no path to compute a budget or savings figure independently, so it cannot silently drift from 010's/011's own already-tested arithmetic even under future modification.

**Alternatives considered**: Having `NotificationEngine` query `FinanceEntry`/`SavingsContribution` rows directly for "efficiency" — rejected outright, this is exactly the duplicated-computation-path anti-pattern the spec explicitly forbids and the constitution's Principle V (no duplicated sources of truth) exists to prevent.

## 3. AI phrasing is a swappable interface over already-composed values, not raw data

**Decision**: `NotificationPhrasingService.compose(ComposedNotification draft) -> ComposedNotification` takes an already-fully-computed `ComposedNotification` (built by the deterministic template path from real 010/011 values) and may return an alternate wording of the same title/body — it never receives raw `BudgetOverview`/`SavingsGoalDetail` data, and never receives a prompt-construction opportunity that could let it invent a number. `TemplateNotificationPhrasingService` (the only implementation this feature ships) simply returns its input unchanged, having already done the real composition work via `gen_l10n` parameterized message templates.

**Rationale**: This is the structural version of FR-008's "AI never supplies the number, only rephrases it." By typing the interface's input as an already-composed, already-real notification rather than raw data, a future spec-014-backed implementation is architecturally *unable* to source a different number — it can only alter phrasing/tone, which is the entire and only point of the future integration described in ROADMAP-PLAN.md §V3.3.

**Alternatives considered**: Passing raw `BudgetOverview`/goal data to a phrasing service and letting it "write a nice message" — rejected, this is exactly the kind of AI-computes-a-financial-fact risk constitution Principle VIII/IX exists to prevent, and would make the non-AI default path and the AI-enhanced path diverge in more than just wording.

## 4. Recomputation trigger: daily fixed-time schedule + foreground-driven catch-up

**Decision**: Two combined triggers, exactly as stated in spec.md's own Assumptions: (a) `flutter_local_notifications`' own local-scheduling API is used to fire a daily "recompute now" background task at a fixed local time (implemented as a zoned, repeating scheduled notification-adjacent callback, or via the platform's lightweight periodic-task API where the plugin ecosystem supports it — exact platform mechanism decided at task-planning/implementation time), and (b) `AppLifecycleObserver`-equivalent logic (reusing the same lifecycle-observation pattern introduced by 015-app-lock-security's `core/security/app_lifecycle_observer.dart`, generalized/reused rather than duplicated — research.md cross-reference) triggers an immediate recomputation on app foreground if more than 6 hours have elapsed since the last one.

**Rationale**: A pure daily-fixed-time trigger alone risks feeling stale if the user's habits don't align with it (e.g. they only ever open the app in the evening); a pure foreground-only trigger risks never firing at all for a user who rarely opens the app (defeating "proactive"). The combination guarantees at least one recomputation per day while also catching up promptly whenever the user is actually using the app — without requiring a persistent background service, consistent with this app's offline-first, no-backend architecture and avoiding the battery/complexity cost of a continuously-running background isolate (`docs/project.txt` §30 Performance: "battery efficiency").

**Alternatives considered**: A continuously-running background service polling frequently — rejected as a battery/complexity cost disproportionate to a feature whose underlying data (budgets, savings goals) changes at most a handful of times per day; foreground-only (no daily fixed-time trigger) — rejected, fails users who rarely open the app, undermining the feature's entire "proactive" premise.

## 5. Reusing `AppLifecycleObserver` from 015-app-lock-security

**Decision**: Rather than writing a second `WidgetsBindingObserver`, this feature's foreground-triggered recomputation check is registered as an additional listener on the same lifecycle-observation plumbing introduced by 015-app-lock-security (`core/security/app_lifecycle_observer.dart`), generalized at that shared location if needed (e.g. renamed/relocated to `core/lifecycle/` if a second consumer makes clear it was never truly security-specific) — decided and executed at this feature's own task-planning time, coordinated with 015's implementation status.

**Rationale**: Constitution Principle II (Feature-First Modularity) and the general "avoid duplicated sources of truth" guidance both argue against two independent `WidgetsBindingObserver` instances doing overlapping lifecycle observation. If 015 has already shipped its observer by the time this feature is implemented, promoting it to a shared `core/` location (constitution Principle XV's promotion rule: "promoted to core/ only once used by multiple features") is the correct, minimal move; if 015 has not yet shipped, this feature may need its own minimal observer initially, with the consolidation as a documented follow-up.

**Alternatives considered**: Building an entirely independent lifecycle observer now regardless of 015's status — rejected as a foreseeable near-term duplication given both features are being specified in the same session; deferring this feature's foreground-trigger capability entirely until 015 ships — rejected, unnecessarily blocks this feature on another V3 item with no hard technical dependency between them (spec.md correctly lists this feature as depending only on 010/011, not on 015).
