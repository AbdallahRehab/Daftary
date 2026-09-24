import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/domain/entities/primary_currency_setting.dart';
import 'package:daftary/features/currency/domain/repositories/currency_repository.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/get_primary_currency.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// Shared 018 multi-currency test doubles for the people/transactions
/// suites — no DI, just a mocktail [CurrencyRepository].
class MockCurrencyRepository extends Mock implements CurrencyRepository {}

/// A [CurrencyRepository] mock answering [primary] and [rates].
MockCurrencyRepository currencyRepositoryWith({
  Currency primary = Currency.egp,
  List<ExchangeRate> rates = const [],
}) {
  final repository = MockCurrencyRepository();
  when(
    repository.getPrimaryCurrency,
  ).thenAnswer((_) async => Right(PrimaryCurrencySetting(currency: primary)));
  when(repository.getExchangeRates).thenAnswer((_) async => Right(rates));
  return repository;
}

GetPrimaryCurrency getPrimaryCurrencyReturning([
  Currency primary = Currency.egp,
]) => GetPrimaryCurrency(currencyRepositoryWith(primary: primary));

GetConversionContext getConversionContextWith({
  Currency primary = Currency.egp,
  List<ExchangeRate> rates = const [],
}) => GetConversionContext(
  currencyRepositoryWith(primary: primary, rates: rates),
);

/// "1 [from] = [rate] [to]".
ExchangeRate rate(Currency from, Currency to, double rate) => ExchangeRate(
  currency: from,
  relativeTo: to,
  rateMicros: ExchangeRate.toMicros(rate),
  lastUpdatedAt: DateTime(2026),
);
