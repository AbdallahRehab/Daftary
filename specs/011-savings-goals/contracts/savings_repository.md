# Contract: SavingsRepository

Local-only Domain/Data boundary (see 001's `people_repository.md` for why this replaces a network API contract). All methods return `Either<Failure, T>`.

```dart
abstract class SavingsRepository {
  /// Creates a new goal (FR-001). If [startingAmountMinorUnits] is
  /// provided and > 0, also creates one initial SavingsContribution row
  /// (type=contribution, dated to today, note="Starting amount") in the
  /// same DB transaction (research.md Decision 3) — SavingsGoal itself
  /// never stores a starting/current amount field. [idempotencyKey] makes
  /// a retried call a no-op (FR-022). Rejects targetAmountMinorUnits <= 0
  /// (FR-002), a negative monthlyContributionMinorUnits, and a targetDate
  /// on or before today (FR-003).
  Future<Either<Failure, SavingsGoal>> createSavingsGoal({
    required String idempotencyKey,
    required String name,
    String? type,
    required int targetAmountMinorUnits,
    int? startingAmountMinorUnits,
    int? monthlyContributionMinorUnits,
    DateTime? targetDate,
  });

  /// Edits name/type/target/monthly contribution/target date (Edge Cases:
  /// editing the target after contributions exist simply changes what
  /// GoalProgress is computed against — no history is altered). Same
  /// validation as createSavingsGoal for whichever fields are present.
  Future<Either<Failure, SavingsGoal>> editSavingsGoal({
    required String goalId,
    required String name,
    String? type,
    required int targetAmountMinorUnits,
    int? monthlyContributionMinorUnits,
    DateTime? targetDate,
  });

  /// Archives a goal (FR-020): hides it from the active list/overview,
  /// preserves it and its full contribution history, still editable.
  Future<Either<Failure, Unit>> archiveSavingsGoal(String goalId);

  /// Restores a previously archived goal (FR-020).
  Future<Either<Failure, Unit>> restoreSavingsGoal(String goalId);

  /// Permanently deletes a goal with zero SavingsContribution rows
  /// (including soft-deleted ones). Returns GoalHasHistoryFailure instead
  /// of deleting if any exist — the caller should offer archiveSavingsGoal
  /// instead (FR-021, mirrors 001's Person-deletion rule).
  Future<Either<Failure, Unit>> deleteSavingsGoal(String goalId);

  /// Logs a contribution (FR-005). Same idempotency contract as
  /// createSavingsGoal. Rejects amountMinorUnits <= 0.
  Future<Either<Failure, SavingsContribution>> logContribution({
    required String idempotencyKey,
    required String goalId,
    required int amountMinorUnits,
    required DateTime date,
    String? note,
  });

  /// Logs a withdrawal (FR-006). Rejects amountMinorUnits <= 0 and
  /// amountMinorUnits exceeding the goal's current computed balance
  /// (WithdrawalExceedsBalanceFailure, research.md Decision 5). Same
  /// idempotency contract as createSavingsGoal.
  Future<Either<Failure, SavingsContribution>> logWithdrawal({
    required String idempotencyKey,
    required String goalId,
    required int amountMinorUnits,
    required DateTime date,
    String? note,
  });

  /// Edits an existing contribution/withdrawal's amount/date/note (FR-009).
  /// [type] is never accepted here — immutable after creation, same
  /// convention as MoneyTransaction.kind (data-model.md). An edit to a
  /// withdrawal is re-validated against the goal's balance excluding this
  /// row's own current value.
  Future<Either<Failure, SavingsContribution>> editContribution({
    required String contributionId,
    required int amountMinorUnits,
    required DateTime date,
    String? note,
  });

  /// Soft-deletes a contribution/withdrawal after the caller has shown a
  /// confirmation (FR-009).
  Future<Either<Failure, Unit>> deleteContribution(String contributionId);

  /// Full detail for one goal: the SavingsGoal itself, its computed
  /// GoalProgress (FR-010/FR-011/FR-012/FR-017), and its full
  /// SavingsContribution history in chronological order (FR-008).
  Future<Either<Failure, SavingsGoalDetail>> getGoalDetail(String goalId);

  /// Overview across all active goals (FR-019): each goal's GoalProgress
  /// plus a combined total currently saved across all of them.
  Future<Either<Failure, SavingsOverview>> getSavingsOverview({
    bool includeArchived = false,
  });
}
```

## Contract: SavingsCalculator (pure Domain service, not a repository — no `Either`, no I/O)

```dart
abstract class SavingsCalculator {
  /// FR-010. Returns null if monthlyContributionMinorUnits is null.
  /// estimatedMonths = ceil(remainingMinorUnits / monthlyContributionMinorUnits),
  /// rounded UP (research.md/Assumptions rounding convention).
  EstimatedCompletion? estimateFromMonthlyContribution({
    required int remainingMinorUnits,
    required int? monthlyContributionMinorUnits,
    required DateTime asOf,
  });

  /// FR-011. Returns null if targetDate is null.
  /// requiredMonthlyContributionMinorUnits =
  ///   ceil(remainingMinorUnits / monthsBetween(asOf, targetDate)),
  /// monthsBetween floored at 1 (never divide by zero).
  EstimatedCompletion? requiredContributionForTargetDate({
    required int remainingMinorUnits,
    required DateTime? targetDate,
    required DateTime asOf,
  });

  /// FR-013. Pure — never touches SavingsRepository (research.md
  /// Decision 1). Same formula as estimateFromMonthlyContribution, applied
  /// to a hypothetical contribution instead of the goal's stored one.
  /// Rejects a hypothetical <= 0 (surfaced as ValidationFailure by the
  /// calling use case, not thrown here — this service returns a plain
  /// nullable result, validation is the use case's job).
  WhatIfResult whatIfMonthlyContribution({
    required int remainingMinorUnits,
    required int hypotheticalMonthlyContributionMinorUnits,
    required DateTime asOf,
  });

  /// FR-014. Pure — same non-mutation guarantee as above.
  WhatIfResult whatIfTargetDate({
    required int remainingMinorUnits,
    required DateTime hypotheticalTargetDate,
    required DateTime asOf,
  });
}
```

**Failure modes**: `ValidationFailure` (non-positive target/contribution amount, past target date), `WithdrawalExceedsBalanceFailure`, `GoalHasHistoryFailure` (blocks permanent delete), `NotFoundFailure` (unknown goal/contribution id), `CacheFailure`, `UnknownFailure`.

**Idempotency note**: `createSavingsGoal`, `logContribution`, and `logWithdrawal` are the three mutation methods that take an `idempotencyKey`, for the same reason established in 001/008/009/010 — they are the calls a rapid double-tap or retry could duplicate. All other `SavingsRepository` methods act on an already-identified id and are naturally idempotent. `SavingsCalculator`'s methods are pure functions with no persistence at all, so idempotency is not a meaningful concept for them.

**Cross-feature note**: Neither `SavingsRepository` nor `SavingsCalculator` calls into any other feature's repository — this is the one contract in the V1.5 tier with zero cross-feature dependencies (plan.md Structure Decision).
