import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';

/// Months with an actual budget needed before the trend view has anything
/// to compare (FR-014's "not enough history yet" state).
const int budgetTrendMinimumBudgetedMonths = 2;

/// One month's planned-vs-actual figure in the trend view (FR-014), either
/// for one category or for the budget overall.
class BudgetTrendPoint extends Equatable {
  const BudgetTrendPoint({
    required this.month,
    required this.plannedMinorUnits,
    required this.actualMinorUnits,
    required this.hasBudget,
    this.currency = Currency.egp,
  });

  /// `'YYYY-MM'`.
  final String month;

  /// That month's planned total (overall) or one allocation's planned
  /// amount (per category); `0` when the month has no budget, or its budget
  /// does not allocate the selected category.
  final int plannedMinorUnits;

  /// Real spend for the month, computed by 007 exactly as the month view
  /// does — present even for a month with no budget.
  final int actualMinorUnits;

  /// Whether an active `Budget` row exists for [month]. Carried explicitly
  /// rather than inferred from `plannedMinorUnits > 0`, since a budget whose
  /// allocations are all zero is still a budget and still counts toward the
  /// history minimum.
  final bool hasBudget;

  /// 018: the currency both figures are in (the primary currency).
  final Currency currency;

  @override
  List<Object?> get props => [
    month,
    plannedMinorUnits,
    actualMinorUnits,
    hasBudget,
    currency,
  ];
}

extension BudgetTrendHistory on List<BudgetTrendPoint> {
  /// Months in this window that had a budget. Months with spending but no
  /// plan do not count — there is nothing to compare "actual" against.
  int get budgetedMonthCount => where((point) => point.hasBudget).length;

  /// `false` drives FR-014's "not enough history yet" state.
  bool get hasEnoughHistory =>
      budgetedMonthCount >= budgetTrendMinimumBudgetedMonths;
}
