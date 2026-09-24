import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/exchange_rate.dart';

/// Parsing and display helpers for a user-entered exchange rate.
abstract final class RateInput {
  static final RegExp _pattern = RegExp(r'^\d+(\.\d+)?$|^\.\d+$|^\d+\.$');

  /// Parses [text] — Western or Arabic-Indic digits, `.` or `٫` or `,` as
  /// the decimal separator — into a positive rate, or `null` when it is
  /// empty, malformed, zero/negative or rounds to zero at 6 decimals
  /// (FR-006).
  static double? parse(String text) {
    final normalized = NumeralParser.toWesternDigits(
      text.trim(),
    ).replaceAll(',', '.');
    if (!_pattern.hasMatch(normalized)) return null;
    final value = double.tryParse(normalized);
    if (value == null || !value.isFinite) return null;
    if (ExchangeRate.toMicros(value) <= 0) return null;
    return value;
  }

  /// Formats a scaled rate exactly (integer arithmetic), trimming trailing
  /// zeros: 50250000 → `50.25`, 1000000 → `1`. Always Western digits.
  static String format(int rateMicros) {
    const scale = ExchangeRate.microsPerUnit;
    final whole = rateMicros ~/ scale;
    final fraction = (rateMicros % scale)
        .toString()
        .padLeft(6, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? '$whole' : '$whole.$fraction';
  }
}
