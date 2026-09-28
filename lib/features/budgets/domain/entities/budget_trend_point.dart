import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';
import 'budget_category_line.dart';

/// Months with an actual budget needed before the trend view has anything
/// to compare (FR-014's "not enough history yet" state).
const int budgetTrendMinimumBudgetedMonths = 2;

/// One month's planned-vs-actual figure in the trend view (FR-014), either
/// for one category or for the budget overall.
///
/// 018 FR-009 — the trend's missing-rate rule: a month is never dropped
/// and the trend never fails as a whole. Each of a month's two figures is
/// independently `null` (unknown) when producing it needs a missing
/// exchange rate — [actualMinorUnits] when a counted category's spend
/// does, [plannedMinorUnits] when the budget was planned in a currency
/// that no longer converts into the primary one. The chart leaves an
/// unknown figure's bar out and marks the month, and the screen names
/// [BudgetTrendHistory.missingRatesFor] in one `RateNeededBanner`.
/// [hasBudget] is unaffected, so the history minimum still counts the
/// month.
class BudgetTrendPoint extends Equatable {
  const BudgetTrendPoint({
    required this.month,
    required this.plannedMinorUnits,
    required this.actualMinorUnits,
    required this.hasBudget,
    this.currency = Currency.egp,
    this.missingRatesFor = const [],
  });

  /// `'YYYY-MM'`.
  final String month;

  /// That month's planned total (overall) or one allocation's planned
  /// amount (per category); `0` when the month has no budget, or its budget
  /// does not allocate the selected category. `null` when converting it
  /// into [currency] needs a missing rate.
  final int? plannedMinorUnits;

  /// Real spend for the month, computed by 007 exactly as the month view
  /// does — present even for a month with no budget. `null` when
  /// converting it needs a missing rate.
  final int? actualMinorUnits;

  /// Whether an active `Budget` row exists for [month]. Carried explicitly
  /// rather than inferred from `plannedMinorUnits > 0`, since a budget whose
  /// allocations are all zero is still a budget and still counts toward the
  /// history minimum.
  final bool hasBudget;

  /// 018: the currency both figures are in (the primary currency).
  final Currency currency;

  /// The currencies this month's unknown figures need a rate for; empty
  /// unless [isBlocked].
  final List<Currency> missingRatesFor;

  bool get isPlannedBlocked => plannedMinorUnits == null;
  bool get isActualBlocked => actualMinorUnits == null;

  /// Either figure is unknown, so the month's comparison is too.
  bool get isBlocked => isPlannedBlocked || isActualBlocked;

  /// Actual above plan in a budgeted month — only ever judged on two known
  /// figures.
  bool get isOverPlan => switch ((plannedMinorUnits, actualMinorUnits)) {
    (final planned?, final actual?) => hasBudget && actual > planned,
    _ => false,
  };

  @override
  List<Object?> get props => [
    month,
    plannedMinorUnits,
    actualMinorUnits,
    hasBudget,
    currency,
    missingRatesFor,
  ];
}

extension BudgetTrendHistory on List<BudgetTrendPoint> {
  /// Months in this window that had a budget. Months with spending but no
  /// plan do not count — there is nothing to compare "actual" against.
  int get budgetedMonthCount => where((point) => point.hasBudget).length;

  /// `false` drives FR-014's "not enough history yet" state.
  bool get hasEnoughHistory =>
      budgetedMonthCount >= budgetTrendMinimumBudgetedMonths;

  /// Every currency a month in the window needs a rate for, once each.
  List<Currency> get missingRatesFor =>
      unionOfMissingRates([for (final point in this) point.missingRatesFor]);
}
