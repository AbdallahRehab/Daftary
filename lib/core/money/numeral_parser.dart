/// Normalizes Arabic-Indic numerals (٠-٩, U+0660-U+0669), Extended
/// Arabic-Indic (Persian/Urdu) numerals (۰-۹, U+06F0-U+06F9), the Arabic
/// decimal separator (٫) and the Arabic thousands separator (٬, U+066C) to
/// their Western equivalents (0-9, `.`, `,`) so every numeral system is
/// accepted as equivalent input everywhere an amount is parsed (FR-023;
/// 023 T017).
class NumeralParser {
  const NumeralParser._();

  static const String _arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';
  static const String _extendedArabicIndicDigits = '۰۱۲۳۴۵۶۷۸۹';
  static const String _westernDigits = '0123456789';

  /// Converts any Arabic-Indic or Extended Arabic-Indic digits (and the
  /// Arabic decimal and thousands separators) found in [input] to their
  /// Western equivalents. Western-digit input is returned unchanged.
  static String toWesternDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final arabicIndex = _arabicIndicDigits.indexOf(char);
      final extendedIndex = arabicIndex == -1
          ? _extendedArabicIndicDigits.indexOf(char)
          : -1;
      if (arabicIndex != -1) {
        buffer.write(_westernDigits[arabicIndex]);
      } else if (extendedIndex != -1) {
        buffer.write(_westernDigits[extendedIndex]);
      } else if (char == '٫') {
        buffer.write('.');
      } else if (char == '٬') {
        buffer.write(',');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
