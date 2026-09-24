import 'package:injectable/injectable.dart';

import '../../../../core/money/money.dart';
import '../entities/conversion_result.dart';
import '../entities/exchange_rate.dart';

/// Pure, I/O-free currency conversion (research.md Decision 6). Callers
/// fetch rates themselves and pass them in; this service never touches a
/// repository. Contract: contracts/currency_converter.md.
abstract class CurrencyConverter {
  /// Converts [amount] into [targetCurrency]:
  ///  - same currency → always succeeds unchanged (never needs a rate);
  ///  - a direct rate (amount.currency → targetCurrency) in [rates] →
  ///    converted, rounded half-up to the target's smallest unit (FR-013);
  ///  - otherwise → [ConversionRateUnavailable]. Never a 1:1 fallback.
  ConversionResult convert({
    required Money amount,
    required Currency targetCurrency,
    required List<ExchangeRate> rates,
  });

  /// Converts every amount and sums them in [targetCurrency]. If any amount
  /// cannot be converted the whole sum is [SumBlocked] (FR-009).
  SumResult sumToTargetCurrency({
    required List<Money> amounts,
    required Currency targetCurrency,
    required List<ExchangeRate> rates,
  });
}

@LazySingleton(as: CurrencyConverter)
class CurrencyConverterImpl implements CurrencyConverter {
  const CurrencyConverterImpl();

  @override
  ConversionResult convert({
    required Money amount,
    required Currency targetCurrency,
    required List<ExchangeRate> rates,
  }) {
    if (amount.currency == targetCurrency) {
      return ConversionResult.converted(amount);
    }
    final rate = _findRate(amount.currency, targetCurrency, rates);
    if (rate == null) {
      return ConversionResult.rateUnavailable(amount.currency);
    }
    // target = source × rate × (targetPerMajor / sourcePerMajor), with the
    // rate scaled by 10^6. BigInt keeps the intermediate product exact.
    final numerator =
        BigInt.from(amount.minorUnits) *
        BigInt.from(rate.rateMicros) *
        BigInt.from(targetCurrency.minorUnitsPerMajor);
    final denominator =
        BigInt.from(amount.currency.minorUnitsPerMajor) *
        BigInt.from(ExchangeRate.microsPerUnit);
    return ConversionResult.converted(
      Money.fromMinorUnits(
        _roundHalfUp(numerator, denominator),
        targetCurrency,
      ),
    );
  }

  @override
  SumResult sumToTargetCurrency({
    required List<Money> amounts,
    required Currency targetCurrency,
    required List<ExchangeRate> rates,
  }) {
    final missing = <Currency>[];
    var total = 0;
    for (final amount in amounts) {
      switch (convert(
        amount: amount,
        targetCurrency: targetCurrency,
        rates: rates,
      )) {
        case ConversionConverted(:final value):
          total += value.minorUnits;
        case ConversionRateUnavailable(:final missingRateFor):
          if (!missing.contains(missingRateFor)) missing.add(missingRateFor);
      }
    }
    if (missing.isNotEmpty) return SumResult.blocked(missing);
    return SumResult.total(Money.fromMinorUnits(total, targetCurrency));
  }

  static ExchangeRate? _findRate(
    Currency from,
    Currency to,
    List<ExchangeRate> rates,
  ) {
    for (final rate in rates) {
      if (rate.currency == from && rate.relativeTo == to) return rate;
    }
    return null;
  }

  /// Rounds `numerator / denominator` half-up by magnitude (half away from
  /// zero), so converting a negated amount yields exactly the negated
  /// result. [denominator] is always positive.
  static int _roundHalfUp(BigInt numerator, BigInt denominator) {
    final magnitude = numerator.abs();
    final rounded =
        (magnitude * BigInt.two + denominator) ~/ (denominator * BigInt.two);
    return (numerator.isNegative ? -rounded : rounded).toInt();
  }
}
