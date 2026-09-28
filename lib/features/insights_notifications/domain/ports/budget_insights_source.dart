import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// Mirrors 010's `BudgetCategoryLine.status` (specs/010-household-budgets/
/// data-model.md). 010 owns the 90% near-full threshold; this feature only
/// ever reads the status it already computed (FR-003).
enum BudgetCategoryStatus { onTrack, nearFull, overBudget }

/// A read-only view of one budgeted category for one month, shaped after
/// 010's `BudgetCategoryLine`. Every figure is 010's own — nothing here is
/// recomputed by this feature (research.md Decision 2).
class BudgetCategorySnapshot extends Equatable {
  const BudgetCategorySnapshot({
    required this.categoryId,
    required this.categoryName,
    required this.month,
    required this.plannedMinorUnits,
    required this.actualMinorUnits,
    required this.percentageUsed,
    required this.status,
  });

  final String categoryId;
  final String categoryName;

  /// The budget's month, `'YYYY-MM'`.
  final String month;

  final int plannedMinorUnits;
  final int actualMinorUnits;

  /// `null` when [plannedMinorUnits] is `0` (010 data-model.md).
  final double? percentageUsed;

  final BudgetCategoryStatus status;

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    month,
    plannedMinorUnits,
    actualMinorUnits,
    percentageUsed,
    status,
  ];
}

/// Read-only port onto 010 Household Budgets' published repository
/// contract (specs/010-household-budgets/contracts/budgets_repository.md).
///
/// Declared here rather than importing 010, so this feature's Domain layer
/// stays independent of it; `BudgetsInsightsSource` is the adapter over
/// 010's `BudgetsRepository`.
abstract class BudgetInsightsSource {
  /// Every budgeted category of the current month's budget, or an empty
  /// list when no budget exists for the current month.
  Future<Either<Failure, List<BudgetCategorySnapshot>>>
  currentMonthCategories();

  /// Whether [categoryId] is still budgeted in [month] (`'YYYY-MM'`) — the
  /// stale-deep-link check (FR-014).
  Future<bool> categoryBudgetExists(String categoryId, String month);
}
