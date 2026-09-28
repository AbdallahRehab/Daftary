import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/combine_latest.dart';
import '../../../../core/utils/either_equality.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../../../currency/domain/usecases/watch_conversion_context.dart';
import '../entities/category_breakdown_item.dart';
import '../entities/finance_entry_type.dart';
import '../entities/finance_history_filter.dart';
import '../repositories/finance_repository.dart';
import 'get_category_breakdown.dart';

/// 021: the live [GetCategoryBreakdown] for [DateRange] (FR-015, FR-031).
/// It re-emits when an entry in the period or a category changes, and when
/// the primary currency or a rate changes, because the totals are
/// converted.
@injectable
class WatchCategoryBreakdown {
  const WatchCategoryBreakdown(
    this._repository,
    this._watchConversionContext,
    this._getCategoryBreakdown,
  );

  final FinanceRepository _repository;
  final WatchConversionContext _watchConversionContext;
  final GetCategoryBreakdown _getCategoryBreakdown;

  Stream<Either<Failure, CategoryBreakdown>> call(
    DateRange period, {
    FinanceEntryType? type,
  }) => combineLatest2(
    _repository.watchCategoryTotals(period, type: type),
    _watchConversionContext(),
    (
      Either<Failure, List<CategoryCurrencyTotals>> rows,
      Either<Failure, ConversionContext> context,
    ) => context.flatMap(
      (context) => rows.map(
        (rows) => _getCategoryBreakdown.breakdown(rows: rows, context: context),
      ),
    ),
  ).distinct(sameResult);
}
