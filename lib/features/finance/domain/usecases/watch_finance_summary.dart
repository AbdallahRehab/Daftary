import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/combine_latest.dart';
import '../../../../core/utils/either_equality.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../../../currency/domain/usecases/watch_conversion_context.dart';
import '../entities/finance_history_filter.dart';
import '../entities/finance_summary.dart';
import '../repositories/finance_repository.dart';
import 'get_finance_summary.dart';

/// 021: the live [GetFinanceSummary] for [DateRange] (FR-014, FR-031). It
/// re-emits when an entry in the period changes, and when the primary
/// currency or a rate changes, because the totals are converted.
@injectable
class WatchFinanceSummary {
  const WatchFinanceSummary(
    this._repository,
    this._watchConversionContext,
    this._getFinanceSummary,
  );

  final FinanceRepository _repository;
  final WatchConversionContext _watchConversionContext;
  final GetFinanceSummary _getFinanceSummary;

  Stream<Either<Failure, FinanceSummary>> call(DateRange period) =>
      combineLatest2(
        _repository.watchSummaryTotals(period),
        _watchConversionContext(),
        (
          Either<Failure, FinancePeriodTotals> totals,
          Either<Failure, ConversionContext> context,
        ) => context.flatMap(
          (context) => totals.map(
            (totals) => _getFinanceSummary.summarize(
              totals: totals,
              context: context,
              period: period,
            ),
          ),
        ),
      ).distinct(sameResult);
}
