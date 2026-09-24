import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_result.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:flutter_test/flutter_test.dart';

/// 018 T011 — CurrencyConverter contract (contracts/currency_converter.md,
/// FR-009, FR-013). Every expected value below is hand-computed.
void main() {
  const converter = CurrencyConverterImpl();
  final updatedAt = DateTime.utc(2026, 1, 1);

  ExchangeRate rate(Currency from, Currency to, int rateMicros) => ExchangeRate(
    currency: from,
    relativeTo: to,
    rateMicros: rateMicros,
    lastUpdatedAt: updatedAt,
  );

  Money usd(int minor) => Money.fromMinorUnits(minor, Currency.usd);
  Money eur(int minor) => Money.fromMinorUnits(minor, Currency.eur);
  Money sar(int minor) => Money.fromMinorUnits(minor, Currency.sar);

  ConversionResult convert(
    Money amount,
    Currency target,
    List<ExchangeRate> rates,
  ) => converter.convert(amount: amount, targetCurrency: target, rates: rates);

  Money convertedValue(ConversionResult result) {
    expect(result, isA<ConversionConverted>());
    return (result as ConversionConverted).value;
  }

  group('same-currency passthrough', () {
    test('returns the amount unchanged with no rates at all', () {
      const amount = Money.egp(12345);
      expect(
        convert(amount, Currency.egp, const []),
        const ConversionResult.converted(amount),
      );
    });

    test('ignores even a (nonsensical) self-rate', () {
      final result = convert(usd(500), Currency.usd, [
        rate(Currency.usd, Currency.usd, 2000000),
      ]);
      expect(convertedValue(result), usd(500));
    });

    test('passes through zero and negative amounts unchanged', () {
      expect(convertedValue(convert(eur(0), Currency.eur, const [])), eur(0));
      expect(
        convertedValue(convert(eur(-999), Currency.eur, const [])),
        eur(-999),
      );
    });
  });

  group('direct-rate conversion', () {
    // 1 USD = 48.50 EGP
    final usdToEgp = rate(Currency.usd, Currency.egp, 48500000);

    test('100.00 USD at 48.50 -> 4,850.00 EGP', () {
      final value = convertedValue(
        convert(usd(10000), Currency.egp, [usdToEgp]),
      );
      expect(value, const Money.egp(485000));
      expect(value.currency, Currency.egp);
    });

    test('0.01 USD at 48.50 -> 0.485 EGP -> rounds to 0.49 EGP', () {
      expect(
        convertedValue(convert(usd(1), Currency.egp, [usdToEgp])),
        const Money.egp(49),
      );
    });

    test('12.34 USD at 48.50 -> 598.49 EGP exactly', () {
      // 1234 × 48.5 = 59849
      expect(
        convertedValue(convert(usd(1234), Currency.egp, [usdToEgp])),
        const Money.egp(59849),
      );
    });

    test('a rate with six decimals is applied exactly', () {
      // 1 EUR = 1.083217 USD; 250.00 EUR -> 270.80425 USD -> 270.80
      final result = convert(eur(25000), Currency.usd, [
        rate(Currency.eur, Currency.usd, 1083217),
      ]);
      expect(convertedValue(result), usd(27080));
    });

    test('a rate below 1 converts downward', () {
      // 1 EGP = 0.020619 USD; 1,000.00 EGP -> 20.619 USD -> 20.62
      final result = convert(const Money.egp(100000), Currency.usd, [
        rate(Currency.egp, Currency.usd, 20619),
      ]);
      expect(convertedValue(result), usd(2062));
    });

    test('zero converts to zero in the target currency', () {
      expect(
        convertedValue(convert(usd(0), Currency.egp, [usdToEgp])),
        Money.zero(Currency.egp),
      );
    });

    test('picks the rate for the exact pair among many', () {
      final rates = [
        rate(Currency.eur, Currency.egp, 52000000),
        rate(Currency.usd, Currency.sar, 3750000),
        usdToEgp,
        rate(Currency.sar, Currency.egp, 12930000),
      ];
      expect(
        convertedValue(convert(usd(200), Currency.egp, rates)),
        const Money.egp(9700),
      );
      expect(convertedValue(convert(usd(200), Currency.sar, rates)), sar(750));
    });
  });

  group('missing rate', () {
    test('returns ConversionRateUnavailable naming the source currency', () {
      final result = convert(usd(100), Currency.egp, const []);
      expect(result, const ConversionResult.rateUnavailable(Currency.usd));
      expect(result, isA<ConversionRateUnavailable>());
      expect(
        (result as ConversionRateUnavailable).missingRateFor,
        Currency.usd,
      );
    });

    test('never falls back to 1:1 even when only the reverse rate '
        'exists', () {
      final result = convert(usd(100), Currency.egp, [
        rate(Currency.egp, Currency.usd, 20619),
      ]);
      expect(result, const ConversionResult.rateUnavailable(Currency.usd));
    });

    test('a rate into a different target does not apply', () {
      final result = convert(usd(100), Currency.egp, [
        rate(Currency.usd, Currency.eur, 920000),
      ]);
      expect(result, const ConversionResult.rateUnavailable(Currency.usd));
    });

    test('never chains through an intermediate currency', () {
      final result = convert(sar(100), Currency.egp, [
        rate(Currency.sar, Currency.usd, 266667),
        rate(Currency.usd, Currency.egp, 48500000),
      ]);
      expect(result, const ConversionResult.rateUnavailable(Currency.sar));
    });

    test('a zero amount still requires a rate', () {
      expect(
        convert(usd(0), Currency.egp, const []),
        const ConversionResult.rateUnavailable(Currency.usd),
      );
    });
  });

  group('rounding (half-up by magnitude, FR-013)', () {
    // 1 USD = 1.5 EGP: odd minor amounts land exactly on .5
    final oneAndHalf = [rate(Currency.usd, Currency.egp, 1500000)];

    test('an exact .5 rounds up', () {
      // 1 × 1.5 = 1.5 -> 2
      expect(
        convertedValue(convert(usd(1), Currency.egp, oneAndHalf)),
        const Money.egp(2),
      );
      // 3 × 1.5 = 4.5 -> 5
      expect(
        convertedValue(convert(usd(3), Currency.egp, oneAndHalf)),
        const Money.egp(5),
      );
    });

    test('just below .5 rounds down', () {
      // 1 × 1.499999 = 1.499999 -> 1
      expect(
        convertedValue(
          convert(usd(1), Currency.egp, [
            rate(Currency.usd, Currency.egp, 1499999),
          ]),
        ),
        const Money.egp(1),
      );
    });

    test('just above .5 rounds up', () {
      // 1 × 1.500001 = 1.500001 -> 2
      expect(
        convertedValue(
          convert(usd(1), Currency.egp, [
            rate(Currency.usd, Currency.egp, 1500001),
          ]),
        ),
        const Money.egp(2),
      );
    });

    test('negative .5 rounds away from zero (symmetric)', () {
      expect(
        convertedValue(convert(usd(-1), Currency.egp, oneAndHalf)),
        const Money.egp(-2),
      );
      expect(
        convertedValue(convert(usd(-3), Currency.egp, oneAndHalf)),
        const Money.egp(-5),
      );
    });

    test('negative just below .5 rounds toward zero (symmetric)', () {
      expect(
        convertedValue(
          convert(usd(-1), Currency.egp, [
            rate(Currency.usd, Currency.egp, 1499999),
          ]),
        ),
        const Money.egp(-1),
      );
    });

    test('converting a negated amount yields exactly the negated result', () {
      final rates = [rate(Currency.usd, Currency.egp, 48537219)];
      for (final minor in [1, 7, 33, 99, 101, 12345, 987654321]) {
        final pos = convertedValue(convert(usd(minor), Currency.egp, rates));
        final neg = convertedValue(convert(usd(-minor), Currency.egp, rates));
        expect(neg, pos.negate(), reason: 'minor=$minor');
      }
    });

    test('a result below half a minor unit rounds to zero', () {
      // 1 × 0.000001 = 0.000001 -> 0
      expect(
        convertedValue(
          convert(usd(1), Currency.egp, [rate(Currency.usd, Currency.egp, 1)]),
        ),
        const Money.egp(0),
      );
    });
  });

  group('large values', () {
    test('a large amount times a large rate does not overflow', () {
      // 90,000,000,000.00 USD × 1,000,000 = 9e18 EGP minor units, which
      // fits in int64 but whose intermediate (× 10^6 scaling) would not.
      final result = convert(usd(9000000000000), Currency.egp, [
        rate(Currency.usd, Currency.egp, 1000000 * 1000000),
      ]);
      expect(convertedValue(result), const Money.egp(9000000000000000000));
    });

    test('a large amount at a fractional rate is exact', () {
      // 123,456,789,012.34 USD × 48.5 = 5,987,654,267,098.49 EGP
      final result = convert(usd(12345678901234), Currency.egp, [
        rate(Currency.usd, Currency.egp, 48500000),
      ]);
      expect(convertedValue(result), const Money.egp(598765426709849));
    });

    test('a large negative amount is exact', () {
      final result = convert(usd(-12345678901234), Currency.egp, [
        rate(Currency.usd, Currency.egp, 48500000),
      ]);
      expect(convertedValue(result), const Money.egp(-598765426709849));
    });
  });

  group('sumToTargetCurrency', () {
    final rates = [
      rate(Currency.usd, Currency.egp, 48500000),
      rate(Currency.eur, Currency.egp, 52250000),
    ];

    SumResult sum(List<Money> amounts, [Currency target = Currency.egp]) =>
        converter.sumToTargetCurrency(
          amounts: amounts,
          targetCurrency: target,
          rates: rates,
        );

    test('an empty list sums to zero in the target currency', () {
      expect(sum(const []), SumResult.total(Money.zero(Currency.egp)));
      expect(
        sum(const [], Currency.usd),
        SumResult.total(Money.zero(Currency.usd)),
      );
    });

    test('same-currency amounts need no rates', () {
      expect(
        converter.sumToTargetCurrency(
          amounts: const [Money.egp(100), Money.egp(250), Money.egp(-50)],
          targetCurrency: Currency.egp,
          rates: const [],
        ),
        const SumResult.total(Money.egp(300)),
      );
    });

    test('sums all-convertible amounts correctly', () {
      // 100.00 EGP              -> 10000
      // 10.00 USD × 48.50       -> 48500
      // 2.00 EUR × 52.25        -> 10450
      // 0.01 USD × 48.50 = 0.485 -> 49 (each amount rounds on its own)
      final result = sum([const Money.egp(10000), usd(1000), eur(200), usd(1)]);
      expect(result, const SumResult.total(Money.egp(68999)));
    });

    test('negative amounts (e.g. owed) net out', () {
      expect(
        sum([usd(1000), usd(-400), const Money.egp(-100)]),
        const SumResult.total(Money.egp(29000)),
      );
    });

    test('one missing rate blocks the whole sum and names it', () {
      final result = sum([const Money.egp(10000), usd(1000), sar(500)]);
      expect(result, const SumResult.blocked([Currency.sar]));
      expect(result, isNot(isA<SumTotal>()));
    });

    test('multiple missing rates are listed distinct, in first-seen '
        'order', () {
      final result = sum([
        sar(1),
        usd(1000),
        Money.fromMinorUnits(5, Currency.gbp),
        sar(2),
        Money.fromMinorUnits(7, Currency.aed),
        Money.fromMinorUnits(9, Currency.gbp),
      ]);
      expect(result, isA<SumBlocked>());
      expect((result as SumBlocked).missingRatesFor, [
        Currency.sar,
        Currency.gbp,
        Currency.aed,
      ]);
    });

    test('never returns a partial sum, even if only the last amount is '
        'unconvertible', () {
      final result = sum([
        for (var i = 0; i < 50; i++) usd(100),
        Money.fromMinorUnits(1, Currency.aed),
      ]);
      expect(result, const SumResult.blocked([Currency.aed]));
    });

    test('a reverse-direction rate does not unblock the sum', () {
      final result = converter.sumToTargetCurrency(
        amounts: [usd(100)],
        targetCurrency: Currency.egp,
        rates: [rate(Currency.egp, Currency.usd, 20619)],
      );
      expect(result, const SumResult.blocked([Currency.usd]));
    });

    test('sums into a non-EGP target', () {
      final result = converter.sumToTargetCurrency(
        amounts: [usd(100), const Money.egp(4850)],
        targetCurrency: Currency.usd,
        rates: [rate(Currency.egp, Currency.usd, 20619)],
      );
      // 4850 × 0.020619 = 100.00215 -> 100; + 100
      expect(result, SumResult.total(usd(200)));
    });
  });
}
