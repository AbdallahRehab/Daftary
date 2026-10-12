import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';

/// Reads amounts from normalized text (FR-030, FR-034, FR-039a,
/// parser-contract §5, orchestrator decision CHK045).
///
/// Never produces a silently wrong amount:
/// - a comma is a thousands separator only when followed by exactly three
///   digits, in a `1,234,567(.89)` shape; anything else (`100,50`,
///   `1.234,50`, `1,23`) is malformed;
/// - a space groups thousands only in a `1 500(.00)` shape;
/// - more decimals than the currency allows, or more than 12 whole digits,
///   is malformed, never clamped or rounded;
/// - zero is malformed (a pending amount is always positive).
///
/// Separators are validated here BEFORE `CurrencyFormatter.parse` is
/// called, because `parse` strips every comma. Its `FormatException` is
/// caught and its message, which embeds the input, is never copied.
class SmsAmountReader {
  const SmsAmountReader._();

  static final RegExp _commaGrouped = RegExp(r'^\d{1,3}(?:,\d{3})+(?:\.\d+)?$');
  static final RegExp _spaceGrouped = RegExp(r'^\d{1,3}(?: \d{3})+(?:\.\d+)?$');
  static final RegExp _plain = RegExp(r'^\d+(?:\.\d+)?$');

  /// Validates a captured amount token and converts it to minor units of
  /// [currency]. Returns `null` when the token is malformed.
  static Money? parse(String token, Currency currency) {
    final plain = _plainDecimal(
      token,
      fractionDigits: _fractionDigits(currency),
    );
    if (plain == null) return null;
    try {
      final money = CurrencyFormatter(currency: currency).parse(plain);
      if (money.minorUnits <= 0) return null;
      return money;
    } on FormatException {
      // The message embeds the input: never copied, never logged.
      return null;
    }
  }

  /// Validates the token's shape without a currency (for a stated currency
  /// outside the catalog, whose amount is never reinterpreted, FR-053).
  /// Up to three decimals are structurally accepted.
  static bool isWellFormed(String token) =>
      _plainDecimal(token, fractionDigits: 3) != null;

  /// Minor units assuming two decimals, used only when no currency is
  /// stated. Every catalog currency has 100 minor units per major unit
  /// (asserted by a test), so the value is exact for whichever catalog
  /// currency the user then chooses.
  static int? minorAssumingTwoDecimals(String token) =>
      parse(token, Currency.egp)?.minorUnits;

  /// The token without grouping, or `null` when malformed.
  static String? _plainDecimal(String token, {required int fractionDigits}) {
    // The Arabic comma (U+060C) between digits is read exactly like `,`
    // (`1،500` is 1500, `1،50` is malformed), never as a stop that drops
    // the leading group.
    var text = token.trim().replaceAll('\u060C', ',');
    if (text.isEmpty) return null;
    if (text.contains(' ')) {
      if (!_spaceGrouped.hasMatch(text)) return null;
      text = text.replaceAll(' ', '');
    }
    if (text.contains(',')) {
      if (!_commaGrouped.hasMatch(text)) return null;
      text = text.replaceAll(',', '');
    }
    if (!_plain.hasMatch(text)) return null;
    final dot = text.indexOf('.');
    if (dot >= 0 && text.length - dot - 1 > fractionDigits) return null;
    final whole = (dot >= 0 ? text.substring(0, dot) : text).replaceFirst(
      RegExp(r'^0+(?=\d)'),
      '',
    );
    if (whole.length > CurrencyFormatter.maxWholeDigits) return null;
    return text;
  }

  static int _fractionDigits(Currency currency) =>
      currency.minorUnitsPerMajor.toString().length - 1;

  /// Every numeric token in [folded]: a maximal run of digits joined by
  /// `.` or `,` between digits, or by a single space before exactly three
  /// digits in a `1 500` shape. Tokens glued to a mask (`****1234`,
  /// `x1234`, `•`), to a date (`/`) or forming a time (`10:15`) are
  /// skipped. Linear in the text length.
  static List<NumericToken> scan(String folded) {
    final tokens = <NumericToken>[];
    var i = 0;
    final n = folded.length;
    while (i < n) {
      if (!_isDigit(folded.codeUnitAt(i))) {
        i++;
        continue;
      }
      final start = i;
      var end = i;
      var groupDigits = 0;
      var firstGroupDigits = -1;
      var spaced = false;
      var sawPunct = false;
      while (end < n) {
        final unit = folded.codeUnitAt(end);
        if (_isDigit(unit)) {
          groupDigits++;
          end++;
          continue;
        }
        final next = end + 1 < n ? folded.codeUnitAt(end + 1) : -1;
        if ((unit == 0x2E || unit == 0x2C || unit == 0x060C) &&
            _isDigit(next)) {
          if (firstGroupDigits < 0) firstGroupDigits = groupDigits;
          sawPunct = true;
          groupDigits = 0;
          end++;
          continue;
        }
        if (unit == 0x20 &&
            !sawPunct &&
            (spaced || groupDigits <= 3) &&
            (!spaced || groupDigits == 3) &&
            _threeDigitsThenStop(folded, end + 1)) {
          if (firstGroupDigits < 0) firstGroupDigits = groupDigits;
          spaced = true;
          groupDigits = 0;
          end++;
          continue;
        }
        break;
      }
      i = end;
      if (_skip(folded, start, end)) continue;
      tokens.add(NumericToken(start, end, folded.substring(start, end)));
    }
    return tokens;
  }

  /// Exactly three digits at [from], then a non-digit (or the end); a
  /// following `.d`/`,d` is allowed (`1 500.00`).
  static bool _threeDigitsThenStop(String text, int from) {
    if (from + 3 > text.length) return false;
    for (var k = from; k < from + 3; k++) {
      if (!_isDigit(text.codeUnitAt(k))) return false;
    }
    if (from + 3 == text.length) return true;
    final after = text.codeUnitAt(from + 3);
    if (_isDigit(after)) return false;
    if (after == 0x2C) return false; // `1 500,00` is never a space group
    return true;
  }

  static bool _skip(String text, int start, int end) {
    final before = start > 0 ? text.codeUnitAt(start - 1) : -1;
    final after = end < text.length ? text.codeUnitAt(end) : -1;
    // Masked card or account (`****1234`, `xx1234`, `•1234`, `#1234`).
    if (before == 0x2A || before == 0x2022 || before == 0x23) return true;
    if (before == 0x78 && start >= 2 && text.codeUnitAt(start - 2) == 0x78) {
      return true;
    }
    if (before == 0x2E && start >= 2 && text.codeUnitAt(start - 2) == 0x2E) {
      return true; // `...1234`
    }
    // Part of a date or a time.
    if (before == 0x2F || after == 0x2F) return true;
    if (after == 0x3A && end + 1 < text.length) {
      if (_isDigit(text.codeUnitAt(end + 1))) return true;
    }
    if (before == 0x3A && start >= 2 && _isDigit(text.codeUnitAt(start - 2))) {
      return true;
    }
    // A date written with `-` or `.` (`04-03-2026`) is scanned as
    // `04`, `03`, `2026` or `04.03.2026`; the amount rules never pick them
    // because they carry no currency marker.
    return false;
  }

  static bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;
}

/// A numeric token in folded text: `[start, end)`.
class NumericToken {
  const NumericToken(this.start, this.end, this.text);

  final int start;
  final int end;
  final String text;
}
