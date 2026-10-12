import '../../domain/services/sms_masker.dart';

/// Masks long digit groups and Egyptian mobile numbers in the ORIGINAL
/// message text before it is sealed (FR-031a, research Decision 7,
/// parser-contract §3). Pure.
///
/// - A digit is ASCII `0-9`, Arabic-Indic `U+0660-0669` or Eastern
///   Arabic-Indic `U+06F0-06F9`.
/// - A digit group is a run of digits, optionally joined by single spaces or
///   hyphens between digits. Commas and periods never join, so grouped
///   amounts such as `1,234,567.50` are never masked.
/// - A group of at least `threshold` digits (default 12, never above 12)
///   keeps only its last four digits; every other digit becomes `•`.
///   Separators and all non-digit characters are kept, so the length and
///   the text direction do not change.
/// - Egyptian mobile numbers (`(\+?20|0)1[0125]` plus 8 digits) keep only
///   their last four. The mobile rules run first, on a digit-normalized
///   shadow copy of the text; every digit is one UTF-16 unit, so the shadow
///   index map is the identity. A contiguous mobile is masked on its own
///   even next to an amount (`EGP 1500 01012345678` keeps the amount); a
///   spaced mobile (`010 1234 5678`) is matched only when no other digit
///   group is joined to it, so a spaced card is never half-masked.
/// - Already-masked tokens (`XXXX1234`, `****1234`) hold at most four
///   digits and are untouched.
class SmsMaskerImpl implements SmsMasker {
  const SmsMaskerImpl();

  /// The mask character.
  static const int maskChar = 0x2022; // •

  /// The default and the maximum threshold (FR-031a).
  static const int maxThreshold = 12;

  static final RegExp _contiguousMobile = RegExp(
    r'(?<![0-9])(?:\+?20|0)1[0125][0-9]{8}(?![0-9])',
  );

  static final RegExp _separatedMobile = RegExp(
    r'(?<![0-9+]|[0-9][ \-])(?:\+?20[ \-]?|0)1[0125](?:[ \-]?[0-9]){8}'
    r'(?![ \-]?[0-9])',
  );

  @override
  String mask(String original, {int threshold = maxThreshold}) {
    if (original.isEmpty) return original;
    final limit = threshold > maxThreshold
        ? maxThreshold
        : (threshold < 1 ? 1 : threshold);
    final units = original.codeUnits.toList();
    final shadow = String.fromCharCodes(units.map(_westernOrSelf));

    for (final pattern in [_contiguousMobile, _separatedMobile]) {
      for (final match in pattern.allMatches(shadow)) {
        _keepLastFour(units, match.start, match.end);
      }
    }

    var i = 0;
    while (i < units.length) {
      if (!isDigit(units[i])) {
        i++;
        continue;
      }
      final start = i;
      var digits = 0;
      var end = i;
      while (end < units.length) {
        if (isDigit(units[end])) {
          digits++;
          end++;
          continue;
        }
        final isJoiner = units[end] == 0x20 || units[end] == 0x2D;
        if (isJoiner && end + 1 < units.length && isDigit(units[end + 1])) {
          end++;
          continue;
        }
        break;
      }
      if (digits >= limit) _keepLastFour(units, start, end);
      i = end;
    }
    return String.fromCharCodes(units);
  }

  /// ASCII, Arabic-Indic or Eastern Arabic-Indic digit.
  static bool isDigit(int unit) =>
      (unit >= 0x30 && unit <= 0x39) ||
      (unit >= 0x0660 && unit <= 0x0669) ||
      (unit >= 0x06F0 && unit <= 0x06F9);

  static int _westernOrSelf(int unit) {
    if (unit >= 0x0660 && unit <= 0x0669) return 0x30 + unit - 0x0660;
    if (unit >= 0x06F0 && unit <= 0x06F9) return 0x30 + unit - 0x06F0;
    return unit;
  }

  /// Replaces every digit in `[start, end)` except the last four with `•`.
  static void _keepLastFour(List<int> units, int start, int end) {
    var toKeep = 4;
    for (var i = end - 1; i >= start; i--) {
      if (!isDigit(units[i])) continue;
      if (toKeep > 0) {
        toKeep--;
      } else {
        units[i] = maskChar;
      }
    }
  }
}
