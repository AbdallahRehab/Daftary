/// Normalizes Arabic-Indic numerals (٠-٩) and the Arabic decimal separator
/// (٫) to their Western equivalents (0-9, `.`) so both numeral systems are
/// accepted as equivalent input everywhere an amount is parsed (FR-023).
class NumeralParser {
  const NumeralParser._();

  static const String _arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';
  static const String _westernDigits = '0123456789';

  /// Converts any Arabic-Indic digits (and the Arabic decimal separator)
  /// found in [input] to their Western equivalents. Western-digit input is
  /// returned unchanged.
  static String toWesternDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final arabicIndex = _arabicIndicDigits.indexOf(char);
      if (arabicIndex != -1) {
        buffer.write(_westernDigits[arabicIndex]);
      } else if (char == '٫') {
        buffer.write('.');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
