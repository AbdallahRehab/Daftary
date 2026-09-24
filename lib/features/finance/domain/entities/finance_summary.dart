import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'finance_history_filter.dart';

/// Total income, total expenses, and net for one period (FR-014). Derived
/// on demand by SQL aggregate — never persisted as a cached column
/// (data-model.md), so it can never go stale relative to the entries.
///
/// 018: the SQL aggregate is per currency; the per-currency totals are then
/// converted into the primary [currency] by `CurrencyConverter` (FR-008).
/// When any contributing currency has no rate, the summary is *blocked*
/// (FR-009): [totalIncome]/[totalExpense]/[net] are all `null` and
/// [missingRatesFor] names every currency that needs a rate. A partial
/// total is never presented as complete, and there is never a 1:1
/// fallback.
class FinanceSummary extends Equatable {
  /// A fully-resolved summary. [totalIncome] and [totalExpense] must share
  /// one currency — the primary currency they were converted into.
  FinanceSummary({
    required Money totalIncome,
    required Money totalExpense,
    required this.period,
  }) : totalIncome = totalIncome,
       totalExpense = totalExpense,
       currency = totalIncome.currency,
       missingRatesFor = const [] {
    if (totalExpense.currency != totalIncome.currency) {
      throw ArgumentError(
        'totalIncome and totalExpense must be in the same currency',
      );
    }
  }

  /// A summary whose totals cannot be shown because at least one entry's
  /// currency has no exchange rate into [currency] (FR-009).
  const FinanceSummary.blocked({
    required this.period,
    required this.currency,
    required this.missingRatesFor,
  }) : totalIncome = null,
       totalExpense = null;

  /// An all-zero summary for a period with no entries — what the true-empty
  /// and no-match states both render against.
  FinanceSummary.empty(this.period, [this.currency = Currency.egp])
    : totalIncome = Money.zero(currency),
      totalExpense = Money.zero(currency),
      missingRatesFor = const [];

  /// Always non-negative: the income/expense split is carried by the two
  /// separate fields, not by a sign. `null` only when [isBlocked].
  final Money? totalIncome;
  final Money? totalExpense;
  final DateRange period;

  /// The currency every total is expressed in — the primary currency at
  /// the time the summary was computed.
  final Currency currency;

  /// Currencies with entries in this period but no rate into [currency].
  /// Empty unless [isBlocked].
  final List<Currency> missingRatesFor;

  bool get isBlocked => missingRatesFor.isNotEmpty;

  /// Income minus expenses — negative when the period overspent. `null`
  /// when [isBlocked].
  Money? get net {
    final income = totalIncome;
    final expense = totalExpense;
    if (income == null || expense == null) return null;
    return income.subtract(expense);
  }

  bool get isEmpty =>
      !isBlocked &&
      (totalIncome?.isZero ?? true) &&
      (totalExpense?.isZero ?? true);

  @override
  List<Object?> get props => [
    totalIncome,
    totalExpense,
    period,
    currency,
    missingRatesFor,
  ];
}

/// The raw, per-currency period totals the repository's `GROUP BY type,
/// currency_code` aggregate yields — one [Money] per currency that has at
/// least one entry of that direction. Unconverted: `GetFinanceSummary`
/// composes these with `CurrencyConverter` into a [FinanceSummary].
class FinancePeriodTotals extends Equatable {
  const FinancePeriodTotals({this.income = const [], this.expense = const []});

  final List<Money> income;
  final List<Money> expense;

  @override
  List<Object?> get props => [income, expense];
}
