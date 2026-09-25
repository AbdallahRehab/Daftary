import 'package:daftary/core/money/currency_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final formatter = CurrencyFormatter(currency: Currency.egp);

  group('CurrencyFormatter.parse digit limit', () {
    test('accepts the largest 12-digit amount exactly', () {
      expect(
        formatter.parse('999999999999.99'),
        const Money.egp(99999999999999),
      );
    });

    test('rejects 13 whole digits instead of risking int overflow', () {
      expect(
        () => formatter.parse('1000000000000'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a 20-digit amount that would wrap into a wrong value', () {
      expect(
        () => formatter.parse('99999999999999999999'),
        throwsA(isA<FormatException>()),
      );
    });

    test('ignores leading zeros when counting digits', () {
      expect(formatter.parse('0000000000001'), const Money.egp(100));
    });
  });
}
