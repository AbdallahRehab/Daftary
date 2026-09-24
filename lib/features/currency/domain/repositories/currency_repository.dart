import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../entities/exchange_rate.dart';
import '../entities/primary_currency_setting.dart';

/// Local-only boundary over the `PrimaryCurrencySetting`/`ExchangeRates`
/// tables and the bundled [Currency] catalog (contracts/currency_converter.md).
/// Calls no other feature's repository and makes no network call (FR-014).
abstract class CurrencyRepository {
  /// The bundled starter catalog — static at runtime.
  Future<Either<Failure, List<Currency>>> getSupportedCurrencies();

  /// Current primary currency (FR-005); EGP when never set.
  Future<Either<Failure, PrimaryCurrencySetting>> getPrimaryCurrency();

  /// Persists [currencyCode] as primary. FR-012's forced-rate check lives in
  /// the `SetPrimaryCurrency` use case, not here.
  Future<Either<Failure, Unit>> setPrimaryCurrency(String currencyCode);

  /// Every configured rate (FR-006/FR-007).
  Future<Either<Failure, List<ExchangeRate>>> getExchangeRates();

  /// Upserts the rate for (currencyCode → relativeToCurrencyCode). Rejects
  /// `rate <= 0` with `InvalidExchangeRateFailure` (FR-006).
  Future<Either<Failure, ExchangeRate>> setExchangeRate({
    required String currencyCode,
    required String relativeToCurrencyCode,
    required double rate,
  });

  /// Removes every rate converting FROM [currencyCode]. Records are never
  /// touched; dependent totals simply become blocked again.
  Future<Either<Failure, Unit>> removeExchangeRate(String currencyCode);
}
