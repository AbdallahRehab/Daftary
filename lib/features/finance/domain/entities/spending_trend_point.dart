import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';
import 'finance_history_filter.dart';

/// One calendar month of the Reports trend (FR-001, data-model.md "Entity:
/// SpendingTrendPoint"). Produced by `GetSpendingTrend`, never persisted.
///
/// A thin re-shaping of that month's `FinanceSummary` for the chart's
/// convenience — every figure is copied from the summary unchanged, never
/// recomputed (FR-003).
class SpendingTrendPoint extends Equatable {
  const SpendingTrendPoint({
    required this.period,
    required this.totalIncomeMinorUnits,
    required this.totalExpenseMinorUnits,
    required this.netMinorUnits,
    this.currency = Currency.egp,
  });

  /// One calendar month. The current month runs only to today, matching
  /// `DateRange.thisMonth()` so its point equals what every other screen
  /// shows for "this month".
  final DateRange period;

  final int totalIncomeMinorUnits;
  final int totalExpenseMinorUnits;

  /// Income minus expenses — negative when the month overspent.
  final int netMinorUnits;

  /// 018: the currency all three figures are in (the primary currency).
  final Currency currency;

  @override
  List<Object?> get props => [
    period,
    totalIncomeMinorUnits,
    totalExpenseMinorUnits,
    netMinorUnits,
    currency,
  ];
}
