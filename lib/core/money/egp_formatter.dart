import 'package:intl/intl.dart';

import '../l10n/numeral_locale.dart';
import 'money.dart';
import 'numeral_parser.dart';

/// Converts [Money] to/from decimal EGP strings at the UI boundary. Both
/// directions are exact: parsing walks the decimal string digit-by-digit
/// instead of going through a `double`, so there is no floating-point
/// rounding step between what the user types and what is stored (FR-006).
class EgpFormatter {
  EgpFormatter({String locale = 'en'})
    : _majorFormat = _formatFor(numeralLocaleFor(locale));

  final NumberFormat _majorFormat;

  // `NumberFormat` construction does real locale-data lookup and pattern
  // parsing — not free. `EgpFormatter` is routinely constructed fresh per
  // widget build (e.g. once per row in a scrolling list), so the
  // underlying formats are cached per locale rather than rebuilt every
  // time (T107 — this was a measurable contributor to scroll jank).
  static final Map<String, NumberFormat> _cache = {};

  static NumberFormat _formatFor(String resolvedLocale) => _cache.putIfAbsent(
    resolvedLocale,
    () => NumberFormat.decimalPattern(resolvedLocale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 0,
  );

  /// Formats [money] as a locale-grouped decimal string, e.g. `15050`
  /// piastres -> `150.50`. Always Western digits (0-9), even under Arabic
  /// (FR-011) — see `AppDateFormatter.format`'s doc comment for why this
  /// is guaranteed via post-processing rather than trusted to the
  /// `_u_nu_latn` locale extension alone.
  String format(Money money) {
    final isNegative = money.minorUnits < 0;
    final absMinor = money.minorUnits.abs();
    final major = absMinor ~/ Money.minorUnitsPerMajorUnit;
    final minor = absMinor % Money.minorUnitsPerMajorUnit;
    final sign = isNegative ? '-' : '';
    final majorText = NumeralParser.toWesternDigits(_majorFormat.format(major));
    return '$sign$majorText.${minor.toString().padLeft(2, '0')}';
  }

  /// Formats [money] with the "EGP" currency suffix, e.g. `150.50 EGP`.
  String formatWithSymbol(Money money) => '${format(money)} EGP';

  /// Parses a decimal EGP string (Western digits only — run input through
  /// `NumeralParser.toWesternDigits` first if it may contain Arabic-Indic
  /// digits) into exact piastres. Throws [FormatException] on invalid input.
  Money parse(String input) {
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
        majorUnits * Money.minorUnitsPerMajorUnit + minorUnitsFraction;
    return Money.fromMinorUnits(isNegative ? -totalMinor : totalMinor);
  }
}
