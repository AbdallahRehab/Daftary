# Contract: NotificationEngine (Domain orchestrator — the recomputation entry point)

Invoked by the daily/foreground trigger (research.md Decision 4/5); not itself a repository, but the single orchestration use case tying everything else together. Returns `Either<Failure, NotificationRunSummary>` (a summary for diagnostics/testing, never surfaced directly to the user).

```dart
abstract class NotificationEngine {
  /// Runs one full recomputation pass: fetches NotificationPreference; if
  /// disabled, returns immediately with an empty summary (FR-018). If
  /// enabled, calls EvaluateBudgetNotifications and/or
  /// EvaluateSavingsGoalNotifications per the enabled categories
  /// (FR-009), compares each result's band against NotificationHistory
  /// (upserting it either way — even a no-change evaluation still
  /// refreshes lastNotifiedAt bookkeeping is NOT done, only a band CHANGE
  /// upserts, per research.md Decision 2/spec Assumptions), composes a
  /// ComposedNotification via NotificationPhrasingService for each real
  /// band change, defers delivery if within quiet hours (FR-013) or
  /// schedules immediately otherwise via NotificationScheduler.
  Future<Either<Failure, NotificationRunSummary>> run();
}
```

## Contract: EvaluateBudgetNotifications (pure Domain service — no repository, no I/O)

```dart
abstract class EvaluateBudgetNotifications {
  /// Pure classification over an ALREADY-FETCHED BudgetOverview (010) —
  /// never queries anything itself (research.md Decision 2). Returns one
  /// BudgetNotificationCandidate per budgeted category, each carrying its
  /// newly-computed ThresholdBand (belowWarning/nearLimit/exceeded, using
  /// 010's own already-established near-full threshold, spec FR-003) and
  /// the real values needed for template composition (category name,
  /// percentageUsed, actual/planned amounts) — NOT yet compared against
  /// NotificationHistory; that comparison is NotificationEngine's job.
  List<BudgetNotificationCandidate> evaluate(BudgetOverview overview);
}
```

## Contract: EvaluateSavingsGoalNotifications (pure Domain service — no repository, no I/O)

```dart
abstract class EvaluateSavingsGoalNotifications {
  /// Pure classification over an ALREADY-FETCHED SavingsGoalDetail (011).
  /// Returns null (no candidate at all) if the goal has no monthly
  /// contribution and no target date (FR-005 — noEstimateAvailable is not
  /// even a candidate, since there is nothing to notify about). Otherwise
  /// compares the goal's actual logged-contribution-implied pace (derived
  /// from its own already-published GoalProgress/EstimatedCompletion,
  /// 011's data-model.md) against what its stored plan implies for the
  /// elapsed time, classifying onPace/behindPace/aheadOfPace, or
  /// `achieved` if GoalProgress.isAchieved is true (011).
  SavingsGoalNotificationCandidate? evaluate(SavingsGoalDetail detail);
}
```

## Value Object: BudgetNotificationCandidate / SavingsGoalNotificationCandidate *(ephemeral)*

```dart
class BudgetNotificationCandidate {
  final String categoryId;
  final String categoryName;
  final String applicablePeriod;       // e.g. '2026-09'
  final ThresholdBand band;            // belowWarning | nearLimit | exceeded
  final double percentageUsed;
  final int actualMinorUnits;
  final int plannedMinorUnits;
}

class SavingsGoalNotificationCandidate {
  final String goalId;
  final String goalName;
  final ThresholdBand band;            // onPace | behindPace | aheadOfPace | achieved
  final int monthsAheadOrBehind;       // signed: negative = behind, positive = ahead
}
```

## Contract: NotificationPhrasingService (abstract — research.md Decision 3)

```dart
abstract class NotificationPhrasingService {
  /// Takes an ALREADY-COMPOSED ComposedNotification (built by the caller
  /// from real values via gen_l10n templates) and MAY return an
  /// alternately-worded version of the SAME underlying facts. Never
  /// receives raw BudgetNotificationCandidate/SavingsGoalNotificationCandidate
  /// data — structurally cannot substitute a different number (FR-008,
  /// constitution Principle VIII/IX). TemplateNotificationPhrasingService
  /// (this feature's only shipped implementation) returns [draft]
  /// unchanged.
  Future<ComposedNotification> compose(ComposedNotification draft);
}
```

## Contract: NotificationScheduler (abstract — wraps `flutter_local_notifications`)

```dart
abstract class NotificationScheduler {
  /// Requests OS notification permission; returns the granted state.
  /// Called only at first feature-enable (FR-011), never at startup.
  Future<bool> requestPermission();

  /// Live permission check (not cached), used to refresh
  /// NotificationPreference.osPermissionGranted (FR-012).
  Future<bool> hasPermission();

  /// Delivers (or, if [deliverAt] is in the future — used for quiet-hours
  /// deferral, FR-013 — schedules) a notification carrying
  /// [notification]'s title/body and enough payload to resolve
  /// [notification.deepLinkTarget] on tap.
  Future<void> scheduleOrDeliver(
    ComposedNotification notification, {
    DateTime? deliverAt,
  });
}
```

**Failure modes**: `NotificationPermissionDeniedFailure`, `NotificationSchedulingFailure` (an OS-level scheduling error — rare, surfaced only in diagnostics, never blocks the rest of `NotificationEngine.run()`'s pass for other candidates), `CacheFailure` (drift read/write error), `UnknownFailure`.

**Idempotency note**: `NotificationEngine.run()` is safe to invoke repeatedly (e.g. both the daily trigger and a foreground catch-up firing close together) — a band that hasn't changed since the last `NotificationHistoryEntry` upsert produces zero new candidates to notify, by construction of the band-comparison logic, not by a separate duplicate-submission guard.

**Cross-feature note**: `NotificationEngine`, `EvaluateBudgetNotifications`, and `EvaluateSavingsGoalNotifications` collectively read 010's `BudgetRepository` and 011's `SavingsRepository` — both read-only, both through those features' own already-published Domain interfaces (010's `budget_repository.md`-equivalent contract, 011's `savings_repository.md`) — never a raw `AppDatabase` query against `Budgets`/`SavingsGoals`/`SavingsContributions` tables directly.
