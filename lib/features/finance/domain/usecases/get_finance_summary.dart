import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../currency/domain/entities/conversion_result.dart';
import '../../../currency/domain/services/currency_converter.dart';
import '../../../currency/domain/usecases/get_conversion_context.dart';
import '../entities/finance_history_filter.dart';
import '../entities/finance_summary.dart';
import '../repositories/finance_repository.dart';

/// Total income, total expenses, and net for a period (FR-014), in the
/// primary currency (018 FR-008).
///
/// The repository sums per currency; this use case converts each
/// direction's per-currency totals into the primary currency with
/// [CurrencyConverter.sumToTargetCurrency]. If any contributing currency
/// lacks a rate the whole summary is blocked, naming every missing
/// currency (FR-009) — income, expense, and net are all withheld, since a
/// net over a partial total would be as misleading as the partial total.
@injectable
class GetFinanceSummary {
  const GetFinanceSummary(
    this._repository,
    this._getConversionContext,
    this._converter,
  );

  final FinanceRepository _repository;
  final GetConversionContext _getConversionContext;
  final CurrencyConverter _converter;

  Future<Either<Failure, FinanceSummary>> call(DateRange period) async {
    final contextResult = await _getConversionContext();
    return contextResult.fold(left, (context) async {
      final totalsResult = await _repository.getSummaryTotals(period);
      return totalsResult.map((totals) {
        final income = _converter.sumToTargetCurrency(
          amounts: totals.income,
          targetCurrency: context.primary,
          rates: context.rates,
        );
        final expense = _converter.sumToTargetCurrency(
          amounts: totals.expense,
          targetCurrency: context.primary,
          rates: context.rates,
        );
        return switch ((income, expense)) {
          (SumTotal(value: final income), SumTotal(value: final expense)) =>
            FinanceSummary(
              totalIncome: income,
              totalExpense: expense,
              period: period,
            ),
          _ => FinanceSummary.blocked(
            period: period,
            currency: context.primary,
            missingRatesFor: {
              if (income case SumBlocked(:final missingRatesFor))
                ...missingRatesFor,
              if (expense case SumBlocked(:final missingRatesFor))
                ...missingRatesFor,
            }.toList(),
          ),
        };
      });
    });
  }
}
