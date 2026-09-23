import '../../../../core/error/failure.dart';
import 'budget.dart';
import 'budget_category_allocation.dart';

/// A create or copy targeted a month that already has an active budget
/// (one budget per calendar month — data-model.md). Carries [existing] so
/// the caller can route the user to editing that budget instead of only
/// telling them the month is taken.
class BudgetAlreadyExistsForMonthFailure extends Failure {
  const BudgetAlreadyExistsForMonthFailure(
    super.message, {
    required this.existing,
  });

  final Budget existing;

  @override
  List<Object?> get props => [message, existing];
}

/// No active budget exists with the requested id — never created, or since
/// deleted. Distinguished from a bare [NotFoundFailure] so the UI can say
/// "this budget is gone" and tell it apart from an unknown category.
class BudgetNotFoundFailure extends NotFoundFailure {
  const BudgetNotFoundFailure(super.message);
}

/// No allocation exists with the requested id — most often because it was
/// already removed from the same budget moments earlier.
class BudgetAllocationNotFoundFailure extends NotFoundFailure {
  const BudgetAllocationNotFoundFailure(super.message);
}

/// The budget already allocates this category (FR-017). Changing its
/// amount is an edit of [existing] (FR-010), not a second row.
class DuplicateBudgetAllocationFailure extends Failure {
  const DuplicateBudgetAllocationFailure(
    super.message, {
    required this.existing,
  });

  final BudgetCategoryAllocation existing;

  @override
  List<Object?> get props => [message, existing];
}
