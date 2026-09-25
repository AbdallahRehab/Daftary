import 'package:intl/intl.dart';

import '../l10n/numeral_locale.dart';
import 'money.dart';
import 'numeral_parser.dart';

/// Converts [Money] to/from decimal strings at the UI boundary for any
/// [Currency] (018 research.md Decision 5). Both directions are exact:
/// parsing walks the decimal string digit-by-digit instead of going through
/// a `double`, so there is no floating-point rounding step between what the
/// user types and what is stored.
///
/// Formatting always uses the formatted amount's OWN currency (FR-010: a
/// record always displays in its original currency); [currency] only decides
/// what [parse] produces.
class CurrencyFormatter {
  CurrencyFormatter({required this.currency, String locale = 'en'})
    : _majorFormat = _formatFor(numeralLocaleFor(locale));

  /// The currency [parse] produces amounts in.
  final Currency currency;

  /// The most whole-unit digits [parse] accepts (up to 999,999,999,999).
  static const int maxWholeDigits = 12;

  final NumberFormat _majorFormat;

  // `NumberFormat` construction does real locale-data lookup and pattern
  // parsing — not free. Formatters are routinely constructed fresh per
  // widget build (e.g. once per row in a scrolling list), so the underlying
  // formats are cached per locale rather than rebuilt every time.
  static final Map<String, NumberFormat> _cache = {};

  static NumberFormat _formatFor(String resolvedLocale) => _cache.putIfAbsent(
    resolvedLocale,
    () => NumberFormat.decimalPattern(resolvedLocale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 0,
  );

  /// Formats [money] as a locale-grouped decimal string, e.g. `15050` minor
  /// units -> `150.50`. Always Western digits (0-9), even under Arabic.
  String format(Money money) {
    final perMajor = money.currency.minorUnitsPerMajor;
    final isNegative = money.minorUnits < 0;
    final absMinor = money.minorUnits.abs();
    final major = absMinor ~/ perMajor;
    final minor = absMinor % perMajor;
    final sign = isNegative ? '-' : '';
    final majorText = NumeralParser.toWesternDigits(_majorFormat.format(major));
    final fractionDigits = perMajor.toString().length - 1;
    if (fractionDigits == 0) return '$sign$majorText';
    return '$sign$majorText.${minor.toString().padLeft(fractionDigits, '0')}';
  }

  /// Formats [money] with its ISO code as a suffix, e.g. `150.50 EGP`. The
  /// code (not a symbol) is used so the placement reads identically under
  /// RTL and LTR, and EGP output stays byte-identical to the pre-018
  /// `EgpFormatter` (FR-015/SC-008).
  String formatWithSymbol(Money money) =>
      '${format(money)} ${money.currency.code}';

  /// Parses a decimal string (Western digits only — run input through
  /// `NumeralParser.toWesternDigits` first if it may contain Arabic-Indic
  /// digits) into exact minor units of [currency]. Throws [FormatException]
  /// on invalid input.
  Money parse(String input) {
    final perMajor = currency.minorUnitsPerMajor;
    final fractionDigits = perMajor.toString().length - 1;
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
    if (fractionPart.length > fractionDigits) {
      throw FormatException(
        'Amount has more than $fractionDigits decimal places: $input',
      );
    }
    // Past 12 whole digits the `major * perMajor` step below (and totals
    // summed over many records) risk silently overflowing a 64-bit int into
    // a wrong or negative amount, so anything longer is rejected up front.
    final significantWhole = wholePart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (significantWhole.length > maxWholeDigits) {
      throw FormatException(
        'Amount has more than $maxWholeDigits digits: $input',
      );
    }
    fractionPart = fractionPart.padRight(fractionDigits, '0');
    final majorUnits = int.parse(wholePart);
    final minorUnitsFraction = fractionPart.isEmpty
        ? 0
        : int.parse(fractionPart);
    final totalMinor = majorUnits * perMajor + minorUnitsFraction;
    return Money.fromMinorUnits(
      isNegative ? -totalMinor : totalMinor,
      currency,
    );
  }
}
