import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'budget.dart';
import 'budget_category_line.dart';

/// Whether a budget's planned total is more than the expected income the
/// user recorded for it (FR-004). Always `false` when no income figure was
/// recorded. An indication only — it never blocks a save.
///
/// A free function rather than only a [BudgetSummary] getter so the budget
/// form can compute the same answer live, before anything is persisted.
bool budgetPlannedExceedsIncome({
  required int totalPlannedMinorUnits,
  required int? expectedIncomeMinorUnits,
}) =>
    expectedIncomeMinorUnits != null &&
    totalPlannedMinorUnits > expectedIncomeMinorUnits;

/// An expense category with spend in the budget's month that the budget
/// has no allocation for (FR-007) — shown separately, never folded into a
/// budgeted line or dropped.
class UnbudgetedCategorySpend extends Equatable {
  const UnbudgetedCategorySpend({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.amountMinorUnits,
  });

  final String categoryId;
  final String categoryName;

  /// A `CategoryIconRegistry` key (007).
  final String categoryIcon;
  final int amountMinorUnits;

  Money get amount => Money.fromMinorUnits(amountMinorUnits);

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    categoryIcon,
    amountMinorUnits,
  ];
}

/// A budget's computed totals and breakdown (FR-005/FR-006/FR-007/FR-009).
///
/// Derived on every read, never persisted. The totals are getters over
/// [categoryBreakdown] rather than separately supplied fields, so the
/// overall card can never disagree with the rows beneath it.
class BudgetSummary extends Equatable {
  const BudgetSummary({
    required this.budgetId,
    required this.categoryBreakdown,
    required this.unbudgetedSpending,
  });

  final String budgetId;

  /// One line per allocation, in the order the repository returns them
  /// (largest planned amount first).
  final List<BudgetCategoryLine> categoryBreakdown;

  /// Largest amount first.
  final List<UnbudgetedCategorySpend> unbudgetedSpending;

  int get totalPlannedMinorUnits => categoryBreakdown.fold(
    0,
    (sum, line) => sum + line.plannedAmountMinorUnits,
  );

  /// Budgeted categories' actual spend only — unbudgeted spending is
  /// reported beside it ([totalUnbudgetedMinorUnits]), not mixed in, so
  /// "remaining" compares like with like.
  int get totalActualMinorUnits => categoryBreakdown.fold(
    0,
    (sum, line) => sum + line.actualAmountMinorUnits,
  );

  /// May be negative — over budget overall (FR-009).
  int get totalRemainingMinorUnits =>
      totalPlannedMinorUnits - totalActualMinorUnits;

  /// `null` when nothing is planned in total (shown as "n/a").
  double? get overallPercentageUsed => budgetPercentageUsed(
    plannedMinorUnits: totalPlannedMinorUnits,
    actualMinorUnits: totalActualMinorUnits,
  );

  /// FR-009: judged on the totals, independent of the individual lines —
  /// one category far over and several comfortably under can still net out
  /// under overall, and that case must read as *not* over.
  bool get isOverBudgetOverall =>
      totalActualMinorUnits > totalPlannedMinorUnits;

  /// The same three-state rule as a line, applied to the totals — what the
  /// overall summary card's badge shows.
  BudgetCategoryStatus get overallStatus => budgetStatusFor(
    plannedMinorUnits: totalPlannedMinorUnits,
    actualMinorUnits: totalActualMinorUnits,
  );

  int get totalUnbudgetedMinorUnits =>
      unbudgetedSpending.fold(0, (sum, item) => sum + item.amountMinorUnits);

  Money get totalPlanned => Money.fromMinorUnits(totalPlannedMinorUnits);
  Money get totalActual => Money.fromMinorUnits(totalActualMinorUnits);
  Money get totalRemaining => Money.fromMinorUnits(totalRemainingMinorUnits);

  @override
  List<Object?> get props => [budgetId, categoryBreakdown, unbudgetedSpending];
}

/// Everything the budget month screen renders for one month, assembled in
/// one read.
///
/// [budget] is `null` when the month has no budget yet — a normal outcome
/// that drives the FR-018 empty/offer-to-copy state, not an error. In that
/// case [summary] is `null` too.
class BudgetMonthDetail extends Equatable {
  const BudgetMonthDetail({required this.month, this.budget, this.summary});

  const BudgetMonthDetail.empty(this.month) : budget = null, summary = null;

  /// `'YYYY-MM'`.
  final String month;
  final Budget? budget;
  final BudgetSummary? summary;

  bool get hasBudget => budget != null;

  /// FR-004's non-blocking hint for the persisted budget.
  bool get plannedExceedsExpectedIncome =>
      summary != null &&
      budgetPlannedExceedsIncome(
        totalPlannedMinorUnits: summary!.totalPlannedMinorUnits,
        expectedIncomeMinorUnits: budget?.expectedIncomeMinorUnits,
      );

  @override
  List<Object?> get props => [month, budget, summary];
}
