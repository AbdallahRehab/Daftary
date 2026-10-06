import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/money/numeral_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumeralParser', () {
    test('converts Arabic-Indic digits to Western digits', () {
      expect(NumeralParser.toWesternDigits('١٥٠'), '150');
    });

    test('converts the Arabic decimal separator to a Western dot', () {
      expect(NumeralParser.toWesternDigits('١٥٠٫٥٠'), '150.50');
    });

    test('converts the Arabic thousands separator to a comma (RF-07)', () {
      expect(NumeralParser.toWesternDigits('١٬٥٠٠'), '1,500');
    });

    test('leaves Western-digit input unchanged', () {
      expect(NumeralParser.toWesternDigits('150.50'), '150.50');
    });

    test('handles a mix of Arabic-Indic and Western digits', () {
      expect(NumeralParser.toWesternDigits('1٥0'), '150');
    });

    test(
      'Arabic-Indic amount parses identically to the Western equivalent',
      () {
        final formatter = EgpFormatter();
        final fromArabic = formatter.parse(
          NumeralParser.toWesternDigits('١٥٠٫٥٠'),
        );
        final fromWestern = formatter.parse('150.50');
        expect(fromArabic, fromWestern);
        expect(fromArabic, const Money.egp(15050));
      },
    );
  });
}
