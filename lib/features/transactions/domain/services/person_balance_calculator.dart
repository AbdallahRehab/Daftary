import '../../../../core/money/money.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../../../currency/domain/entities/conversion_result.dart';
import '../../../currency/domain/services/currency_converter.dart';
import '../entities/person_balance.dart';

/// Turns a person's per-currency native nets (as aggregated by
/// `BalanceQueries`) into a [PersonBalance] in the primary currency, by
/// composing [CurrencyConverter.sumToTargetCurrency] (018 FR-008/FR-009).
///
/// Pure and I/O-free: the caller supplies the [ConversionContext].
class PersonBalanceCalculator {
  const PersonBalanceCalculator([
    this._converter = const CurrencyConverterImpl(),
  ]);

  final CurrencyConverter _converter;

  /// [nativeNetsByCode] maps currency code → net minor units (the shape
  /// `BalanceQueries` returns). Zero nets are dropped first: a currency the
  /// person is settled in contributes nothing and must not block the total
  /// just because it has no rate.
  PersonBalance calculate({
    required String personId,
    required Map<String, int> nativeNetsByCode,
    required ConversionContext context,
  }) {
    final nativeNets = [
      for (final entry in nativeNetsByCode.entries)
        if (entry.value != 0)
          Money.fromMinorUnits(entry.value, Currency.fromCode(entry.key)),
    ];
    final result = _converter.sumToTargetCurrency(
      amounts: nativeNets,
      targetCurrency: context.primary,
      rates: context.rates,
    );
    return switch (result) {
      SumTotal(:final value) => PersonBalance(personId: personId, net: value),
      SumBlocked(:final missingRatesFor) => PersonBalance.blocked(
        personId: personId,
        nativeNets: nativeNets,
        missingRatesFor: missingRatesFor,
      ),
    };
  }
}
