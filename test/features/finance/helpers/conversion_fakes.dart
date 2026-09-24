import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_context.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/get_primary_currency.dart';
import 'package:daftary/features/currency/domain/entities/primary_currency_setting.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:fpdart/fpdart.dart';

/// A [GetConversionContext] that answers with a fixed [ConversionContext]
/// (EGP-only by default) — no `CurrencyRepository`, no DI.
class FakeGetConversionContext implements GetConversionContext {
  FakeGetConversionContext([this.context = ConversionContext.egpOnly]);

  ConversionContext context;
  Failure? failure;

  @override
  Future<Either<Failure, ConversionContext>> call() async {
    final f = failure;
    return f == null ? Right(context) : Left(f);
  }
}

/// A [GetPrimaryCurrency] that answers with a fixed primary currency.
class FakeGetPrimaryCurrency implements GetPrimaryCurrency {
  FakeGetPrimaryCurrency([this.currency = Currency.egp]);

  Currency currency;

  @override
  Future<Either<Failure, PrimaryCurrencySetting>> call() async =>
      Right(PrimaryCurrencySetting(currency: currency));
}

/// `1 [from] = [rate] [to]`, as the converter consumes it.
ExchangeRate rate(Currency from, Currency to, double rate) => ExchangeRate(
  currency: from,
  relativeTo: to,
  rateMicros: ExchangeRate.toMicros(rate),
  lastUpdatedAt: DateTime(2026),
);

GetFinanceSummary summaryUseCase(
  FinanceRepository repository, [
  ConversionContext context = ConversionContext.egpOnly,
]) => GetFinanceSummary(
  repository,
  FakeGetConversionContext(context),
  const CurrencyConverterImpl(),
);

GetCategoryBreakdown breakdownUseCase(
  FinanceRepository repository, [
  ConversionContext context = ConversionContext.egpOnly,
]) => GetCategoryBreakdown(
  repository,
  FakeGetConversionContext(context),
  const CurrencyConverterImpl(),
);
