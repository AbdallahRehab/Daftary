import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/combine_latest.dart';
import '../../../../core/utils/either_equality.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../../../currency/domain/usecases/watch_conversion_context.dart';
import '../entities/finance_summary.dart';
import '../entities/spending_trend_point.dart';
import '../repositories/finance_repository.dart';
import 'get_finance_summary.dart';
import 'get_spending_trend.dart';

/// 021: the live [GetSpendingTrend] (013 FR-001, 021 FR-031). It re-emits
/// when an entry in the window changes, and when the primary currency or a
/// rate changes, because every month is converted.
///
/// The window is resolved once, when listened to; subscribing again (the
/// Reports screen's pull to refresh and retry) re-resolves it. All months
/// are re-read together from one watch, and each is converted by
/// [GetFinanceSummary.summarize] — so every point is still exactly what the
/// finance screen shows for that month (013 FR-003).
@injectable
class WatchSpendingTrend {
  const WatchSpendingTrend(
    this._repository,
    this._watchConversionContext,
    this._getFinanceSummary,
  );

  final FinanceRepository _repository;
  final WatchConversionContext _watchConversionContext;
  final GetFinanceSummary _getFinanceSummary;

  /// [monthsBack] calendar months ending with [reference]'s month (default:
  /// now), oldest first — see [GetSpendingTrend.call].
  Stream<Either<Failure, List<SpendingTrendPoint>>> call({
    int monthsBack = 6,
    DateTime? reference,
  }) {
    final periods = GetSpendingTrend.lastCalendarMonths(
      monthsBack,
      reference ?? DateTime.now(),
    );
    return combineLatest2(
      _repository.watchSummaryTotalsForPeriods(periods),
      _watchConversionContext(),
      (
        Either<Failure, List<FinancePeriodTotals>> totals,
        Either<Failure, ConversionContext> context,
      ) => context.flatMap(
        (context) => totals.flatMap(
          (totals) => GetSpendingTrend.trendFrom(periods, [
            for (var i = 0; i < periods.length; i++)
              _getFinanceSummary.summarize(
                totals: totals[i],
                context: context,
                period: periods[i],
              ),
          ]),
        ),
      ),
    ).distinct(sameResult);
  }
}
