import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../../../currency/domain/entities/conversion_result.dart';
import '../../../currency/domain/services/currency_converter.dart';
import '../../../currency/domain/usecases/get_conversion_context.dart';
import '../entities/category_breakdown_item.dart';
import '../entities/finance_entry_type.dart';
import '../entities/finance_history_filter.dart';
import '../repositories/finance_repository.dart';

/// Per-category totals for a period, largest first, each carrying its share
/// of the period (FR-015), in the primary currency (018 FR-008).
///
/// Each category's per-currency totals are converted with
/// [CurrencyConverter.sumToTargetCurrency]. A category with an unconvertible
/// currency keeps a `null` total; if any category is blocked, the whole
/// breakdown is blocked and no row carries a share — every share would be
/// of an incomplete period total (FR-009).
@injectable
class GetCategoryBreakdown {
  const GetCategoryBreakdown(
    this._repository,
    this._getConversionContext,
    this._converter,
  );

  final FinanceRepository _repository;
  final GetConversionContext _getConversionContext;
  final CurrencyConverter _converter;

  Future<Either<Failure, CategoryBreakdown>> call(
    DateRange period, {
    FinanceEntryType? type,
  }) async {
    final contextResult = await _getConversionContext();
    return contextResult.fold(left, (context) async {
      final rowsResult = await _repository.getCategoryTotals(
        period,
        type: type,
      );
      return rowsResult.map((rows) => breakdown(rows: rows, context: context));
    });
  }

  /// Converts one period's per-category, per-currency [rows] into
  /// [context]'s primary currency — the pure step `WatchCategoryBreakdown`
  /// (021) reuses.
  CategoryBreakdown breakdown({
    required List<CategoryCurrencyTotals> rows,
    required ConversionContext context,
  }) {
    final missing = <Currency>[];
    final converted = <(CategoryCurrencyTotals, Money?)>[];
    for (final row in rows) {
      final sum = _converter.sumToTargetCurrency(
        amounts: row.totals,
        targetCurrency: context.primary,
        rates: context.rates,
      );
      switch (sum) {
        case SumTotal(:final value):
          converted.add((row, value));
        case SumBlocked(:final missingRatesFor):
          converted.add((row, null));
          for (final currency in missingRatesFor) {
            if (!missing.contains(currency)) missing.add(currency);
          }
      }
    }

    // Stable largest-first ordering on the converted totals: rows that
    // tie keep the repository's order (so an EGP-only breakdown orders
    // exactly as the SQL `ORDER BY` did before 018), and blocked rows
    // sort after every resolved one.
    final indexed = converted.indexed.toList()
      ..sort((a, b) {
        final aTotal = a.$2.$2?.minorUnits;
        final bTotal = b.$2.$2?.minorUnits;
        if (aTotal != null && bTotal != null && aTotal != bTotal) {
          return bTotal.compareTo(aTotal);
        }
        if (aTotal == null && bTotal != null) return 1;
        if (aTotal != null && bTotal == null) return -1;
        return a.$1.compareTo(b.$1);
      });

    final isBlocked = missing.isNotEmpty;
    final periodTotal = isBlocked
        ? 0
        : converted.fold<int>(0, (sum, e) => sum + e.$2!.minorUnits);

    return CategoryBreakdown(
      currency: context.primary,
      missingRatesFor: missing,
      items: [
        for (final (_, (row, total)) in indexed)
          CategoryBreakdownItem(
            categoryId: row.categoryId,
            categoryName: row.categoryName,
            icon: row.icon,
            total: total,
            // Zero rather than a division by zero when the period is
            // empty — which can only happen if every row summed to 0.
            shareOfPeriod: isBlocked
                ? null
                : periodTotal == 0
                ? 0
                : total!.minorUnits / periodTotal,
          ),
      ],
    );
  }
}
