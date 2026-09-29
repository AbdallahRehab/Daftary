import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/savings_contribution.dart';
import '../entities/savings_goal.dart';
import '../entities/savings_goal_detail.dart';
import '../entities/savings_overview.dart';

/// Offline-first Domain/Data boundary for [SavingsGoal] and
/// [SavingsContribution], and everything derived from them
/// (contracts/savings_repository.md). No method throws to the caller
/// (constitution Principle VII).
///
/// Every local write also enqueues its 021 sync outbox row in the same
/// drift transaction; the repository never talks to Supabase directly. It
/// reads 018's conversion context (primary currency + rates) through the
/// currency feature's Domain layer, and never calls another feature's
/// repository. Every completion/required-contribution figure comes from
/// `SavingsCalculator` — the implementation never does that math itself.
///
/// Failure modes: `ValidationFailure` (non-positive target/contribution
/// amount), `InvalidTargetDateFailure`, `WithdrawalExceedsBalanceFailure`,
/// `GoalHasHistoryFailure`, `GoalArchivedFailure`, `RatesMissingFailure`
/// (018), `GoalNotFoundFailure`, `CacheFailure`, `UnknownFailure`.
abstract class SavingsRepository {
  /// Creates a new goal (FR-001). If [startingAmountMinorUnits] is provided
  /// and > 0, also creates one initial contribution row (type contribution,
  /// dated to today, note "Starting amount") in the same DB transaction
  /// (research.md Decision 3) — [SavingsGoal] itself never stores a
  /// starting/current amount. [idempotencyKey] makes a retried call a no-op
  /// returning the existing goal (FR-022). Rejects
  /// `targetAmountMinorUnits <= 0` (FR-002), a negative
  /// [monthlyContributionMinorUnits] or [startingAmountMinorUnits], and a
  /// [targetDate] on or before today (`InvalidTargetDateFailure`, FR-003).
  Future<Either<Failure, SavingsGoal>> createSavingsGoal({
    required String idempotencyKey,
    required String name,
    String? type,
    required Currency currency,
    required int targetAmountMinorUnits,
    int? startingAmountMinorUnits,
    int? monthlyContributionMinorUnits,
    DateTime? targetDate,
  });

  /// FR-029. Edits name/type/target/monthly contribution/target date —
  /// never the currency (FR-027). Editing the target after contributions
  /// exist only changes what progress is computed against; no history is
  /// altered. Same validation as [createSavingsGoal] for the fields given.
  Future<Either<Failure, SavingsGoal>> editSavingsGoal({
    required String goalId,
    required String name,
    String? type,
    required int targetAmountMinorUnits,
    int? monthlyContributionMinorUnits,
    DateTime? targetDate,
  });

  /// Archives a goal (FR-020): hidden from the active list and overview,
  /// preserved with its full history, still editable.
  Future<Either<Failure, Unit>> archiveSavingsGoal(String goalId);

  /// Restores a previously archived goal (FR-020).
  Future<Either<Failure, Unit>> restoreSavingsGoal(String goalId);

  /// Deletes a goal with zero contribution rows (including soft-deleted
  /// ones) — shown as permanent, kept as a synced tombstone. Returns
  /// `GoalHasHistoryFailure` instead if any exist; the caller should offer
  /// [archiveSavingsGoal] (FR-021).
  Future<Either<Failure, Unit>> deleteSavingsGoal(String goalId);

  /// Logs a contribution (FR-005). Same idempotency contract as
  /// [createSavingsGoal]. Rejects an amount <= 0, an archived goal
  /// (`GoalArchivedFailure`, FR-020), and a foreign-currency [amount] whose
  /// rate is missing (`RatesMissingFailure`, FR-028). [amount] is what the
  /// user entered; when its currency differs from the goal's it is
  /// converted now and both figures are stored.
  Future<Either<Failure, SavingsContribution>> logContribution({
    required String idempotencyKey,
    required String goalId,
    required Money amount,
    required DateTime date,
    String? note,
  });

  /// Logs a withdrawal (FR-006). Rejects an amount <= 0 and one exceeding
  /// the goal's current balance (`WithdrawalExceedsBalanceFailure`,
  /// research.md Decision 5). Same idempotency, archived and currency rules
  /// as [logContribution]; the balance check uses the converted amount.
  Future<Either<Failure, SavingsContribution>> logWithdrawal({
    required String idempotencyKey,
    required String goalId,
    required Money amount,
    required DateTime date,
    String? note,
  });

  /// Edits an existing entry's amount/date/note (FR-009). Its type is never
  /// editable. A withdrawal is re-validated against the balance excluding
  /// its own current value; a foreign-currency entry is re-converted at the
  /// current rate. Writes a `SavingsContributionAudit` row (edited, prior
  /// values) in the same transaction (FR-030). Allowed on an archived goal.
  Future<Either<Failure, SavingsContribution>> editContribution({
    required String contributionId,
    required Money amount,
    required DateTime date,
    String? note,
  });

  /// Soft-deletes an entry after the caller has confirmed (FR-009), writing
  /// a `SavingsContributionAudit` row (deleted) in the same transaction
  /// (FR-030). Rejected with `WithdrawalExceedsBalanceFailure` if deleting a
  /// contribution would leave the balance negative.
  Future<Either<Failure, Unit>> deleteContribution(String contributionId);

  /// One goal with its computed progress (FR-010/FR-011/FR-012/FR-017) and
  /// its non-deleted history in chronological order (FR-008).
  Future<Either<Failure, SavingsGoalDetail>> getGoalDetail(String goalId);

  /// Every active goal — archived ones too with [includeArchived] — with
  /// progress in its own currency, plus a combined total converted into the
  /// primary currency at read time (FR-019). Goals needing a missing rate
  /// are returned blocked and left out of the total
  /// (`SavingsOverview.isIncomplete`).
  Future<Either<Failure, SavingsOverview>> getSavingsOverview({
    bool includeArchived = false,
  });

  /// Live [getGoalDetail]: re-emits whenever the goal, its entries, a rate
  /// or the primary currency changes, including changes applied by sync.
  Stream<Either<Failure, SavingsGoalDetail>> watchGoalDetail(String goalId);

  /// Live [getSavingsOverview], on the same triggers.
  Stream<Either<Failure, SavingsOverview>> watchSavingsOverview({
    bool includeArchived = false,
  });
}
