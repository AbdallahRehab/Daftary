import 'package:daftary/core/l10n/numeral_locale.dart';
import 'package:daftary/core/money/currency_formatter.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/money/numeral_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// 018 T007 — FR-015/SC-008: for EGP amounts the post-018 [EgpFormatter]
/// must produce byte-identical output to the pre-018 one. The pre-018
/// implementation (`git show d4c2515~1:lib/core/money/egp_formatter.dart`)
/// is frozen below as [_LegacyEgpFormatter], operating on raw int minor
/// units (the pre-018 `Money` had no currency), and every output is
/// compared against it rather than against hand-written expectations.
void main() {
  const amounts = <int>[
    0,
    1,
    -1,
    5,
    9,
    10,
    50,
    99,
    -99,
    100,
    101,
    199,
    1050,
    -1050,
    15050,
    99999,
    100000,
    123456,
    1000000,
    -2500075,
    99999999,
    123456789,
    -123456789,
    500000000,
    900000000000,
    9007199254740991 ~/ 1000,
  ];

  const parseInputs = <String>[
    '0',
    '0.00',
    '1',
    '0.01',
    '0.1',
    '10.5',
    '10.50',
    '150.50',
    '-150.50',
    '-0.99',
    '1,234,567.89',
    '1 234',
    '  42.00  ',
    '2000',
    '5000000',
    '9000000000',
    '.5',
    '',
    '   ',
    'abc',
    '10.505',
    '1.2.3',
    '12a',
    '1.a',
    '-',
    '--5',
  ];

  for (final locale in const ['en', 'ar']) {
    group('EgpFormatter is byte-identical to pre-018 under "$locale"', () {
      final current = EgpFormatter(locale: locale);
      final legacy = _LegacyEgpFormatter(locale: locale);

      for (final minor in amounts) {
        test('format($minor)', () {
          expect(current.format(Money.egp(minor)), legacy.format(minor));
        });

        test('formatWithSymbol($minor)', () {
          expect(
            current.formatWithSymbol(Money.egp(minor)),
            legacy.formatWithSymbol(minor),
          );
        });

        test('parse(format($minor)) round-trips identically', () {
          final text = legacy.format(minor);
          final parsed = current.parse(text);
          expect(parsed.minorUnits, legacy.parse(text));
          expect(parsed.minorUnits, minor);
          expect(parsed.currency, Currency.egp);
        });
      }

      for (final input in parseInputs) {
        test('parse(${_quote(input)}) matches the legacy outcome', () {
          int? legacyResult;
          Object? legacyError;
          try {
            legacyResult = legacy.parse(input);
          } on FormatException catch (e) {
            legacyError = e;
          }

          if (legacyError != null) {
            expect(() => current.parse(input), throwsFormatException);
          } else {
            final parsed = current.parse(input);
            expect(parsed.minorUnits, legacyResult);
            expect(parsed.currency, Currency.egp);
          }
        });
      }
    });
  }

  test('the amount list exercises at least 20 distinct values', () {
    expect(amounts.toSet().length, greaterThanOrEqualTo(20));
  });

  group('CurrencyFormatter for a non-EGP currency', () {
    test('formats USD with a "USD" suffix', () {
      final formatter = CurrencyFormatter(currency: Currency.usd);
      const money = Money.fromMinorUnits(123456, Currency.usd);
      expect(formatter.format(money), '1,234.56');
      expect(formatter.formatWithSymbol(money), '1,234.56 USD');
    });

    test('formats USD under "ar" with Western digits', () {
      final formatter = CurrencyFormatter(currency: Currency.usd, locale: 'ar');
      const money = Money.fromMinorUnits(-5, Currency.usd);
      final text = formatter.formatWithSymbol(money);
      expect(text, '-0.05 USD');
      expect(RegExp(r'[٠-٩]').hasMatch(text), isFalse);
    });

    test('parses into USD, not EGP', () {
      final formatter = CurrencyFormatter(currency: Currency.usd);
      final parsed = formatter.parse('1,234.56');
      expect(parsed, const Money.fromMinorUnits(123456, Currency.usd));
      expect(parsed.currency, Currency.usd);
      expect(parsed, isNot(const Money.egp(123456)));
    });

    test('rejects more than two decimals for USD', () {
      final formatter = CurrencyFormatter(currency: Currency.usd);
      expect(() => formatter.parse('1.234'), throwsFormatException);
    });

    test('formats each amount in its own currency regardless of the '
        'formatter currency (FR-010)', () {
      final egpFormatter = EgpFormatter();
      expect(
        egpFormatter.formatWithSymbol(
          const Money.fromMinorUnits(1050, Currency.usd),
        ),
        '10.50 USD',
      );
    });
  });
}

String _quote(String s) => "'$s'";

/// Verbatim copy of the pre-018 `EgpFormatter` (only the class name changed
/// and `Money` replaced by raw `int` piastres, since pre-018 `Money` was a
/// bare wrapper around them). DO NOT edit to match new behavior — this is
/// the reference the new implementation must reproduce byte-for-byte.
class _LegacyEgpFormatter {
  _LegacyEgpFormatter({String locale = 'en'})
    : _majorFormat = _formatFor(numeralLocaleFor(locale));

  static const int _minorUnitsPerMajorUnit = 100;

  final NumberFormat _majorFormat;

  static final Map<String, NumberFormat> _cache = {};

  static NumberFormat _formatFor(String resolvedLocale) => _cache.putIfAbsent(
    resolvedLocale,
    () => NumberFormat.decimalPattern(resolvedLocale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 0,
  );

  String format(int minorUnits) {
    final isNegative = minorUnits < 0;
    final absMinor = minorUnits.abs();
    final major = absMinor ~/ _minorUnitsPerMajorUnit;
    final minor = absMinor % _minorUnitsPerMajorUnit;
    final sign = isNegative ? '-' : '';
    final majorText = NumeralParser.toWesternDigits(_majorFormat.format(major));
    return '$sign$majorText.${minor.toString().padLeft(2, '0')}';
  }

  String formatWithSymbol(int minorUnits) => '${format(minorUnits)} EGP';

  int parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Amount is empty');
    }
    final isNegative = trimmed.startsWith('-');
    final unsigned = isNegative ? trimmed.substring(1) : trimmed;
    final parts = unsigned.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid amount: $input');
    }
    final wholePart = parts[0].replaceAll(RegExp(r'[,\s]'), '');
    if (wholePart.isEmpty || !RegExp(r'^\d+$').hasMatch(wholePart)) {
      throw FormatException('Invalid amount: $input');
    }
    var fractionPart = parts.length == 2 ? parts[1] : '';
    if (fractionPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fractionPart)) {
      throw FormatException('Invalid amount: $input');
    }
    if (fractionPart.length > 2) {
      throw FormatException('Amount has more than 2 decimal places: $input');
    }
    fractionPart = fractionPart.padRight(2, '0');
    final majorUnits = int.parse(wholePart);
    final minorUnitsFraction = int.parse(fractionPart);
    final totalMinor =
        majorUnits * _minorUnitsPerMajorUnit + minorUnitsFraction;
    return isNegative ? -totalMinor : totalMinor;
  }
}
