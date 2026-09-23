import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'finance_history_filter.dart';

/// Total income, total expenses, and net for one period (FR-014). Derived
/// on demand by SQL aggregate — never persisted as a cached column
/// (data-model.md), so it can never go stale relative to the entries.
class FinanceSummary extends Equatable {
  const FinanceSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.period,
  });

  /// An all-zero summary for a period with no entries — what the true-empty
  /// and no-match states both render against.
  const FinanceSummary.empty(this.period)
    : totalIncome = const Money.fromMinorUnits(0),
      totalExpense = const Money.fromMinorUnits(0);

  /// Always non-negative: the income/expense split is carried by the two
  /// separate fields, not by a sign.
  final Money totalIncome;
  final Money totalExpense;
  final DateRange period;

  /// Income minus expenses — negative when the period overspent.
  Money get net => totalIncome.subtract(totalExpense);

  bool get isEmpty => totalIncome.isZero && totalExpense.isZero;

  @override
  List<Object?> get props => [totalIncome, totalExpense, period];
}
