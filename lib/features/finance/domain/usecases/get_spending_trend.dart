import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../entities/finance_history_filter.dart';
import '../entities/finance_summary.dart';
import '../entities/spending_trend_point.dart';
import 'get_finance_summary.dart';

/// Income and expense totals for each of the last [call]'s `monthsBack`
/// calendar months, oldest first (FR-001, contracts/get_spending_trend.md).
///
/// Coordinates [GetFinanceSummary] once per month and nothing else — no
/// new SQL, so every point is exactly what the finance screen shows for
/// that month (FR-003), converted into the primary currency (018).
@injectable
class GetSpendingTrend {
  const GetSpendingTrend(this._getFinanceSummary);

  final GetFinanceSummary _getFinanceSummary;

  /// [monthsBack] is the window size, ending with [reference]'s month
  /// (default: now) inclusive. The per-month reads run concurrently, so the
  /// load time is the slowest month rather than the sum (SC-001).
  ///
  /// A failure on any single month fails the whole trend: a trend with a
  /// silent gap in the middle would misrepresent the user's history
  /// (FR-005). A month that needs a missing exchange rate fails it the same
  /// way, as [RatesMissingFailure] naming every such currency (018 FR-009).
  Future<Either<Failure, List<SpendingTrendPoint>>> call({
    int monthsBack = 6,
    DateTime? reference,
  }) async {
    final periods = lastCalendarMonths(monthsBack, reference ?? DateTime.now());
    final results = await Future.wait(periods.map(_getFinanceSummary.call));

    final points = <SpendingTrendPoint>[];
    final missing = <Currency>{};
    for (var i = 0; i < results.length; i++) {
      final failure = results[i].getLeft().toNullable();
      if (failure != null) return Left(failure);
      final summary = results[i].toNullable()!;
      if (summary.isBlocked) {
        missing.addAll(summary.missingRatesFor);
        continue;
      }
      points.add(_pointFrom(periods[i], summary));
    }
    if (missing.isNotEmpty) return Left(RatesMissingFailure(missing.toList()));
    return Right(points);
  }

  /// The last [count] calendar months ending with [reference]'s month,
  /// oldest first. Past months are whole; the current month is
  /// `DateRange.thisMonth(reference)`. `DateTime`'s month arithmetic
  /// normalizes across year boundaries (month 0 is December of the year
  /// before).
  static List<DateRange> lastCalendarMonths(int count, DateTime reference) {
    return [
      for (var offset = count - 1; offset >= 1; offset--)
        DateRange(
          start: DateTime(reference.year, reference.month - offset),
          // Day 0 of the following month is this month's last day.
          end: DateTime(reference.year, reference.month - offset + 1, 0),
        ),
      if (count > 0) DateRange.thisMonth(reference),
    ];
  }

  /// Only called for an unblocked summary, whose totals are all set.
  static SpendingTrendPoint _pointFrom(
    DateRange period,
    FinanceSummary summary,
  ) {
    return SpendingTrendPoint(
      period: period,
      totalIncomeMinorUnits: summary.totalIncome!.minorUnits,
      totalExpenseMinorUnits: summary.totalExpense!.minorUnits,
      netMinorUnits: summary.net!.minorUnits,
      currency: summary.currency,
    );
  }
}
