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

    group('Extended Arabic-Indic digits U+06F0-U+06F9 (023 T017)', () {
      test('converts every Extended Arabic-Indic digit', () {
        expect(NumeralParser.toWesternDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
      });

      test('keeps the Arabic decimal separator mapping', () {
        expect(NumeralParser.toWesternDigits('۱۲۳٫۴۵'), '123.45');
      });

      test('keeps the Arabic thousands separator mapping', () {
        expect(NumeralParser.toWesternDigits('۱٬۵۰۰'), '1,500');
      });

      test('handles Extended, Arabic-Indic and Western digits mixed', () {
        expect(NumeralParser.toWesternDigits('۱٥0٫۵٠'), '150.50');
      });

      test('leaves surrounding non-digit text untouched', () {
        expect(NumeralParser.toWesternDigits('EGP ۱۲۳ ج.م'), 'EGP 123 ج.م');
      });

      test('Western strings are unchanged', () {
        const western = 'EGP 1,234.50 on 07/10';
        expect(NumeralParser.toWesternDigits(western), western);
      });

      test('۱۲۳٫۴۵ parses identically to 123.45', () {
        final formatter = EgpFormatter();
        final fromExtended = formatter.parse(
          NumeralParser.toWesternDigits('۱۲۳٫۴۵'),
        );
        expect(fromExtended, formatter.parse('123.45'));
        expect(fromExtended, const Money.egp(12345));
      });
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
