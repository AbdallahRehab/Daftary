import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money arithmetic', () {
    test('add sums minor units exactly', () {
      final result = const Money.egp(200000).add(const Money.egp(50000));
      expect(result, const Money.egp(250000));
    });

    test('subtract can go negative (you-owe-them direction)', () {
      final result = const Money.egp(50000).subtract(const Money.egp(70000));
      expect(result, const Money.egp(-20000));
    });

    test('negate flips the sign', () {
      expect(const Money.egp(15050).negate(), const Money.egp(-15050));
    });

    test('abs always returns a non-negative amount', () {
      expect(const Money.egp(-15050).abs(), const Money.egp(15050));
    });

    test('compareTo and comparison operators order by minor units', () {
      const smaller = Money.egp(100);
      const larger = Money.egp(200);
      expect(smaller.compareTo(larger), lessThan(0));
      expect(smaller < larger, isTrue);
      expect(larger > smaller, isTrue);
      expect(smaller <= smaller, isTrue);
      expect(larger >= larger, isTrue);
    });

    test('isZero/isPositive/isNegative reflect the sign', () {
      expect(Money.zero(Currency.egp).isZero, isTrue);
      expect(const Money.egp(1).isPositive, isTrue);
      expect(const Money.egp(-1).isNegative, isTrue);
    });
  });

  group('EgpFormatter decimal conversion', () {
    final formatter = EgpFormatter();

    test('parses 150.50 EGP to exactly 15050 piastres', () {
      expect(formatter.parse('150.50'), const Money.egp(15050));
    });

    test('formats 15050 piastres back to 150.50', () {
      expect(formatter.format(const Money.egp(15050)), '150.50');
    });

    test('round-trips a large amount with no truncation (5,000,000 EGP)', () {
      const fiveMillionEgpInPiastres = 500000000;
      final money = formatter.parse('5000000');
      expect(money, const Money.egp(fiveMillionEgpInPiastres));
      expect(formatter.format(money), '5,000,000.00');
    });

    test('does not overflow for very large amounts', () {
      final money = formatter.parse('9000000000');
      expect(money.minorUnits, 900000000000);
    });

    test('pads a single decimal digit to two places', () {
      expect(formatter.parse('10.5'), const Money.egp(1050));
    });

    test('parses a whole-number amount with no decimal part', () {
      expect(formatter.parse('2000'), const Money.egp(200000));
    });

    test('rejects more than two decimal places', () {
      expect(() => formatter.parse('10.505'), throwsFormatException);
    });

    test('rejects non-numeric input', () {
      expect(() => formatter.parse('abc'), throwsFormatException);
    });

    test('rejects empty input', () {
      expect(() => formatter.parse(''), throwsFormatException);
    });
  });

  group('EgpFormatter under the ar locale (FR-011)', () {
    final formatter = EgpFormatter(locale: 'ar');

    test('formats with Western digits, never Arabic-Indic glyphs', () {
      final formatted = formatter.format(const Money.egp(15050));
      expect(formatted, '150.50');
      expect(RegExp(r'[٠-٩]').hasMatch(formatted), isFalse);
    });

    test(
      'formats a grouped amount with Western digits and correct grouping',
      () {
        final formatted = formatter.format(const Money.egp(500000000));
        expect(formatted, contains('5,000,000'));
        expect(RegExp(r'[٠-٩]').hasMatch(formatted), isFalse);
      },
    );
  });

  group('Money currency awareness (018 T005)', () {
    test('Money.egp is shorthand for fromMinorUnits with EGP', () {
      expect(
        const Money.egp(1234),
        const Money.fromMinorUnits(1234, Currency.egp),
      );
      expect(const Money.egp(1234).currency, Currency.egp);
    });

    test('Money.zero carries the requested currency', () {
      final zero = Money.zero(Currency.usd);
      expect(zero.isZero, isTrue);
      expect(zero.currency, Currency.usd);
      expect(zero, isNot(Money.zero(Currency.egp)));
    });

    test('same-currency add/subtract succeed and keep the currency', () {
      const a = Money.fromMinorUnits(1050, Currency.usd);
      const b = Money.fromMinorUnits(250, Currency.usd);
      expect(a.add(b), const Money.fromMinorUnits(1300, Currency.usd));
      expect(a.subtract(b), const Money.fromMinorUnits(800, Currency.usd));
      expect(a.add(b).currency, Currency.usd);
      expect(b.subtract(a), const Money.fromMinorUnits(-800, Currency.usd));
    });

    test('negate and abs preserve the currency', () {
      const eur = Money.fromMinorUnits(-500, Currency.eur);
      expect(eur.negate(), const Money.fromMinorUnits(500, Currency.eur));
      expect(eur.abs(), const Money.fromMinorUnits(500, Currency.eur));
    });

    test('same-currency comparison orders by minor units', () {
      const small = Money.fromMinorUnits(100, Currency.sar);
      const big = Money.fromMinorUnits(200, Currency.sar);
      expect(small.compareTo(big), lessThan(0));
      expect(big.compareTo(small), greaterThan(0));
      expect(small.compareTo(small), 0);
      expect(small < big, isTrue);
      expect(big >= small, isTrue);
    });

    test('cross-currency add throws ArgumentError', () {
      expect(
        () => const Money.egp(
          100,
        ).add(const Money.fromMinorUnits(100, Currency.usd)),
        throwsArgumentError,
      );
    });

    test('cross-currency subtract throws ArgumentError', () {
      expect(
        () => const Money.fromMinorUnits(
          100,
          Currency.usd,
        ).subtract(const Money.fromMinorUnits(100, Currency.eur)),
        throwsArgumentError,
      );
    });

    test('cross-currency compareTo and operators throw ArgumentError', () {
      const egp = Money.egp(100);
      const usd = Money.fromMinorUnits(100, Currency.usd);
      expect(() => egp.compareTo(usd), throwsArgumentError);
      expect(() => egp < usd, throwsArgumentError);
      expect(() => egp <= usd, throwsArgumentError);
      expect(() => egp > usd, throwsArgumentError);
      expect(() => egp >= usd, throwsArgumentError);
    });

    test('cross-currency throw even when one side is zero', () {
      expect(
        () => Money.zero(Currency.egp).add(Money.zero(Currency.usd)),
        throwsArgumentError,
      );
    });

    test('equality includes the currency', () {
      const egp = Money.egp(100);
      const usd = Money.fromMinorUnits(100, Currency.usd);
      expect(egp == usd, isFalse);
      expect(egp, isNot(usd));
      expect(const Money.fromMinorUnits(100, Currency.usd), usd);
      expect(
        const Money.fromMinorUnits(100, Currency.usd).hashCode,
        usd.hashCode,
      );
    });
  });
}
