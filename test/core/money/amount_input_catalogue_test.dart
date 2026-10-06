import 'package:daftary/core/money/currency_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/money/numeral_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// 022 Phase 2 (T011) — amount-input catalogue: one rule set for
/// `NumeralParser` plus `CurrencyFormatter.parse`, applied the way the
/// amount forms apply it (normalize digits, parse, then require a strictly
/// positive amount). Every figure is an exact integer count of minor units.
void main() {
  final formatter = CurrencyFormatter(currency: Currency.egp);

  /// What every amount form does: `NumeralParser.toWesternDigits`, then
  /// `CurrencyFormatter.parse`, then reject anything not strictly positive.
  /// Returns `null` for a rejected input.
  ///
  /// This helper MIRRORS the parsing in the real forms; it is not the code
  /// under test there. Every form below must keep the same
  /// normalize -> parse -> isPositive sequence, or this catalogue drifts:
  /// transaction (TransactionFormCubit.submit, covered by
  /// amount_input_forms_test.dart), repayment, occasion contribution,
  /// finance entry, budget allocation, savings target, savings contribution
  /// and savings withdrawal.
  Money? acceptAmount(String input) {
    try {
      final parsed = formatter.parse(NumeralParser.toWesternDigits(input));
      return parsed.isPositive ? parsed : null;
    } on FormatException {
      return null;
    }
  }

  group('CHK116 Arabic digits and the Arabic decimal point', () {
    test('"١٥٠٠٫٥٠" is saved as 1,500.50 (150050)', () {
      expect(acceptAmount('١٥٠٠٫٥٠'), const Money.egp(150050));
    });

    test('mixed Western and Arabic-Indic digits parse the same', () {
      expect(acceptAmount('1٥00٫50'), const Money.egp(150050));
    });

    test(
      '"١٬٥٠٠" (Arabic thousands separator U+066C) is saved as 1,500.00',
      () {
        expect(acceptAmount('١٬٥٠٠'), const Money.egp(150000));
      },
    );
  });

  group('CHK136 zero, negative and empty amounts are rejected', () {
    for (final input in ['0', '0.00', '-5', '-0.01', '', '   ']) {
      test('"$input" is rejected', () {
        expect(acceptAmount(input), isNull);
      });
    }
  });

  group('CHK137 decimal places', () {
    test('0.01 EGP is accepted (1 minor unit)', () {
      expect(acceptAmount('0.01'), const Money.egp(1));
    });

    test('0.001 EGP is rejected: too many decimal places', () {
      expect(acceptAmount('0.001'), isNull);
      expect(() => formatter.parse('0.001'), throwsFormatException);
    });
  });

  group('CHK138 maximum of 12 whole digits', () {
    test('999,999,999,999.99 EGP is accepted (99999999999999)', () {
      expect(
        acceptAmount('999,999,999,999.99'),
        const Money.egp(99999999999999),
      );
    });

    test('1,000,000,000,000 EGP (13 digits) is rejected', () {
      expect(acceptAmount('1,000,000,000,000'), isNull);
      expect(CurrencyFormatter.maxWholeDigits, 12);
    });

    test('leading zeros do not count toward the 12 digits', () {
      expect(acceptAmount('0000000000001.00'), const Money.egp(100));
    });
  });

  group('CHK139 grouping separators', () {
    test('"1,500" is saved as 1,500.00 (150000)', () {
      expect(acceptAmount('1,500'), const Money.egp(150000));
    });

    test('"1 500" is saved as 1,500.00 (150000)', () {
      expect(acceptAmount('1 500'), const Money.egp(150000));
    });
  });
}
