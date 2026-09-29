import '../../../../core/error/failure.dart';

/// No goal (or contribution) exists with the requested id — never created,
/// or deleted. Distinguished from a bare [NotFoundFailure] so the UI can say
/// "this goal is gone".
class GoalNotFoundFailure extends NotFoundFailure {
  const GoalNotFoundFailure(super.message);
}

/// A withdrawal (or an edit/delete) would take the goal's balance below
/// zero (FR-006, research.md Decision 5). Carries the balance available so
/// the UI can say how much can be withdrawn.
class WithdrawalExceedsBalanceFailure extends Failure {
  const WithdrawalExceedsBalanceFailure(
    super.message, {
    required this.availableMinorUnits,
  });

  /// The goal's balance the withdrawal was checked against, in the goal's
  /// currency.
  final int availableMinorUnits;

  @override
  List<Object?> get props => [message, availableMinorUnits];
}

/// The goal still has contribution history, so it cannot be deleted — only
/// archived (FR-021).
class GoalHasHistoryFailure extends Failure {
  const GoalHasHistoryFailure(super.message);
}

/// A target date on or before today (FR-003), or a past what-if date
/// (FR-016).
class InvalidTargetDateFailure extends Failure {
  const InvalidTargetDateFailure(super.message);
}

/// A new contribution or withdrawal on an archived goal (FR-020). Editing
/// or deleting its existing entries stays allowed.
class GoalArchivedFailure extends Failure {
  const GoalArchivedFailure(super.message);
}

/// A what-if was asked of (or applied to) a goal that is already achieved
/// (FR-016): there is nothing left to plan for, so no recalculation is
/// offered rather than a misleading "0 months".
class GoalAlreadyAchievedFailure extends Failure {
  const GoalAlreadyAchievedFailure(super.message);
}
