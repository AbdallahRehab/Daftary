# Contract: SavingsRepository

Offline-first Domain/Data boundary (see 001's `people_repository.md` for why this replaces a network API contract). Every local write also enqueues a 021 sync outbox row in the same drift transaction; the repository never talks to Supabase directly. All methods return `Either<Failure, T>`.

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
    required Currency currency,            // FR-027, fixed for the goal's life
    required int targetAmountMinorUnits,
    int? startingAmountMinorUnits,          // in the goal's currency
    int? monthlyContributionMinorUnits,
    DateTime? targetDate,
  });

  /// FR-029. Edits name/type/target/monthly contribution/target date — never
  /// the currency (FR-027). (Edge Cases:
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
  /// createSavingsGoal. Rejects amount <= 0, an archived goal
  /// (GoalArchivedFailure, FR-020), and a foreign-currency amount whose
  /// rate is missing (RatesMissingFailure, FR-028). [amount] is what the
  /// user entered; when its currency differs from the goal's it is
  /// converted at this moment and both figures are stored.
  Future<Either<Failure, SavingsContribution>> logContribution({
    required String idempotencyKey,
    required String goalId,
    required Money amount,
    required DateTime date,
    String? note,
  });

  /// Logs a withdrawal (FR-006). Rejects amountMinorUnits <= 0 and
  /// amountMinorUnits exceeding the goal's current computed balance
  /// (WithdrawalExceedsBalanceFailure, research.md Decision 5). Same
  /// idempotency contract as createSavingsGoal. Same archived/currency
  /// rules as logContribution; the balance check uses the converted amount.
  Future<Either<Failure, SavingsContribution>> logWithdrawal({
    required String idempotencyKey,
    required String goalId,
    required Money amount,
    required DateTime date,
    String? note,
  });

  /// Edits an existing contribution/withdrawal's amount/date/note (FR-009).
  /// [type] is never accepted here — immutable after creation, same
  /// convention as MoneyTransaction.kind (data-model.md). An edit to a
  /// withdrawal is re-validated against the goal's balance excluding this
  /// row's own current value. Re-converts a foreign-currency entry at the
  /// current rate. Writes a SavingsContributionAudit row (changeType
  /// edited, prior values) in the same transaction (FR-030).
  Future<Either<Failure, SavingsContribution>> editContribution({
    required String contributionId,
    required Money amount,
    required DateTime date,
    String? note,
  });

  /// Soft-deletes a contribution/withdrawal after the caller has shown a
  /// confirmation (FR-009), writing a SavingsContributionAudit row
  /// (changeType deleted) in the same transaction (FR-030). Rejected with
  /// WithdrawalExceedsBalanceFailure if deleting a contribution would leave
  /// the goal's balance negative.
  Future<Either<Failure, Unit>> deleteContribution(String contributionId);

  /// Full detail for one goal: the SavingsGoal itself, its computed
  /// GoalProgress (FR-010/FR-011/FR-012/FR-017), and its full
  /// SavingsContribution history in chronological order (FR-008).
  Future<Either<Failure, SavingsGoalDetail>> getGoalDetail(String goalId);

  /// Overview across all active goals (FR-019): each goal's GoalProgress in
  /// its own currency, plus a combined total converted into the primary
  /// currency at read time. Goals needing a missing rate are returned
  /// blocked and excluded from the total (SavingsOverview.isIncomplete).
  Future<Either<Failure, SavingsOverview>> getSavingsOverview({
    bool includeArchived = false,
  });

  /// Live variants for the glass-shell pages' live updates (same pattern
  /// as 008/010): re-emit whenever a goal, contribution, rate or primary
  /// currency changes, including changes applied by sync.
  Stream<Either<Failure, SavingsGoalDetail>> watchGoalDetail(String goalId);
  Stream<Either<Failure, SavingsOverview>> watchSavingsOverview({
    bool includeArchived = false,
  });
}
```

## Contract: SavingsCalculator (pure Domain service, not a repository — no `Either`, no I/O)

```dart
/// Works only in goal-currency integer minor units; never converts
/// currency (018 data-model.md).
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
  ///   ceil(remainingMinorUnits / wholeMonthsBetween(asOf, targetDate)),
  /// integer ceiling; wholeMonthsBetween (core/date, research.md
  /// Decision 11) floored at 1 (never divide by zero).
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

**Failure modes**: `ValidationFailure` (non-positive target/contribution amount), `InvalidTargetDateFailure` (target date on/before today), `WithdrawalExceedsBalanceFailure`, `GoalHasHistoryFailure` (blocks delete), `GoalArchivedFailure` (new entry on an archived goal), `RatesMissingFailure` (018, foreign-currency entry without a rate), `GoalNotFoundFailure` (unknown goal/contribution id), `CacheFailure`, `UnknownFailure`.

**Idempotency note**: `createSavingsGoal`, `logContribution`, and `logWithdrawal` are the three mutation methods that take an `idempotencyKey`, for the same reason established in 001/008/009/010 — they are the calls a rapid double-tap or retry could duplicate. All other `SavingsRepository` methods act on an already-identified id and are naturally idempotent. `SavingsCalculator`'s methods are pure functions with no persistence at all, so idempotency is not a meaningful concept for them.

**Cross-feature note**: `SavingsRepository` reads 018's conversion context (primary currency + rates) through the currency feature's Domain use cases/`CurrencyConverter`, and writes 021's outbox through the shared `core/sync` store — the same two dependencies 010 Budgets has. It calls no other feature's repository. In the other direction, 017, 014 and 012 read this feature only through its use cases (research.md Decision 13).
