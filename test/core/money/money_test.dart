import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money arithmetic', () {
    test('add sums minor units exactly', () {
      final result = const Money.fromMinorUnits(
        200000,
      ).add(const Money.fromMinorUnits(50000));
      expect(result, const Money.fromMinorUnits(250000));
    });

    test('subtract can go negative (you-owe-them direction)', () {
      final result = const Money.fromMinorUnits(
        50000,
      ).subtract(const Money.fromMinorUnits(70000));
      expect(result, const Money.fromMinorUnits(-20000));
    });

    test('negate flips the sign', () {
      expect(
        const Money.fromMinorUnits(15050).negate(),
        const Money.fromMinorUnits(-15050),
      );
    });

    test('abs always returns a non-negative amount', () {
      expect(
        const Money.fromMinorUnits(-15050).abs(),
        const Money.fromMinorUnits(15050),
      );
    });

    test('compareTo and comparison operators order by minor units', () {
      const smaller = Money.fromMinorUnits(100);
      const larger = Money.fromMinorUnits(200);
      expect(smaller.compareTo(larger), lessThan(0));
      expect(smaller < larger, isTrue);
      expect(larger > smaller, isTrue);
      expect(smaller <= smaller, isTrue);
      expect(larger >= larger, isTrue);
    });

    test('isZero/isPositive/isNegative reflect the sign', () {
      expect(Money.zero().isZero, isTrue);
      expect(const Money.fromMinorUnits(1).isPositive, isTrue);
      expect(const Money.fromMinorUnits(-1).isNegative, isTrue);
    });
  });

  group('EgpFormatter decimal conversion', () {
    final formatter = EgpFormatter();

    test('parses 150.50 EGP to exactly 15050 piastres', () {
      expect(formatter.parse('150.50'), const Money.fromMinorUnits(15050));
    });

    test('formats 15050 piastres back to 150.50', () {
      expect(formatter.format(const Money.fromMinorUnits(15050)), '150.50');
    });

    test('round-trips a large amount with no truncation (5,000,000 EGP)', () {
      const fiveMillionEgpInPiastres = 500000000;
      final money = formatter.parse('5000000');
      expect(money, const Money.fromMinorUnits(fiveMillionEgpInPiastres));
      expect(formatter.format(money), '5,000,000.00');
    });

    test('does not overflow for very large amounts', () {
      final money = formatter.parse('9000000000');
      expect(money.minorUnits, 900000000000);
    });

    test('pads a single decimal digit to two places', () {
      expect(formatter.parse('10.5'), const Money.fromMinorUnits(1050));
    });

    test('parses a whole-number amount with no decimal part', () {
      expect(formatter.parse('2000'), const Money.fromMinorUnits(200000));
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
      final formatted = formatter.format(const Money.fromMinorUnits(15050));
      expect(formatted, '150.50');
      expect(RegExp(r'[٠-٩]').hasMatch(formatted), isFalse);
    });

    test(
      'formats a grouped amount with Western digits and correct grouping',
      () {
        final formatted = formatter.format(
          const Money.fromMinorUnits(500000000),
        );
        expect(formatted, contains('5,000,000'));
        expect(RegExp(r'[٠-٩]').hasMatch(formatted), isFalse);
      },
    );
  });
}
