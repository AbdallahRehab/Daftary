import '../../../../core/money/numeral_parser.dart';
import '../../domain/services/sms_text_normalizer.dart';

/// The parser's normalization pipeline (parser-contract §3). Pure.
///
/// | Step | Operation | Output |
/// |---|---|---|
/// | 1 | Strip bidi controls and zero-width characters | both |
/// | 2 | Collapse whitespace runs to one space; trim | both |
/// | 3 | Western digits (`NumeralParser.toWesternDigits`) | both (= `forDisplay`) |
/// | 4 | Arabic folding: strip tatweel and harakat; fold alef forms, alef maqsura, ta marbuta, hamza seats | `forMatching` |
/// | 5 | Lower-case Latin letters | `forMatching` |
///
/// Never used for the fingerprint: that is the frozen
/// `FingerprintNormalizerV1`, which shares no code with this class
/// (FR-023).
class SmsTextNormalizerImpl implements SmsTextNormalizer {
  const SmsTextNormalizerImpl();

  @override
  NormalizedText normalize(String text) {
    final folded = normalizeWithMap(text);
    return NormalizedText(
      forMatching: folded.forMatching,
      forDisplay: folded.forDisplay,
    );
  }

  /// [normalize] plus an index map from `forMatching` back to
  /// `forDisplay`, so a span matched on the folded text can be shown as the
  /// bank wrote it.
  FoldedText normalizeWithMap(String text) {
    final display = displayForm(text);
    return foldWithMap(display);
  }

  /// Steps 1-3: what amounts and merchant text are read from.
  static String displayForm(String text) {
    final buffer = StringBuffer();
    var pendingSpace = false;
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      if (isInvisibleMark(unit)) continue;
      if (isWhitespace(unit)) {
        pendingSpace = buffer.isNotEmpty;
        continue;
      }
      if (pendingSpace) {
        buffer.writeCharCode(0x20);
        pendingSpace = false;
      }
      buffer.writeCharCode(unit);
    }
    return NumeralParser.toWesternDigits(buffer.toString());
  }

  /// Steps 4-5 applied to an already display-normalized string, with the
  /// index map.
  static FoldedText foldWithMap(String display) {
    final out = StringBuffer();
    final map = <int>[];
    for (var i = 0; i < display.length; i++) {
      final unit = display.codeUnitAt(i);
      final folded = _foldUnit(unit);
      if (folded == null) continue;
      out.writeCharCode(folded);
      map.add(i);
    }
    return FoldedText._(out.toString(), display, List.unmodifiable(map));
  }

  /// Folds a rule keyword or pattern text exactly as message text is
  /// folded (steps 1-5), so rule tables can be written naturally.
  static String fold(String text) => foldWithMap(displayForm(text)).forMatching;

  /// Bidi controls (U+200E, U+200F, U+061C, U+202A-202E, U+2066-2069) and
  /// zero-width characters (U+200B-200D, U+FEFF).
  static bool isInvisibleMark(int unit) =>
      unit == 0x200E ||
      unit == 0x200F ||
      unit == 0x061C ||
      (unit >= 0x202A && unit <= 0x202E) ||
      (unit >= 0x2066 && unit <= 0x2069) ||
      (unit >= 0x200B && unit <= 0x200D) ||
      unit == 0xFEFF;

  /// Whitespace, including no-break and other Unicode spaces and line
  /// separators.
  static bool isWhitespace(int unit) =>
      (unit >= 0x09 && unit <= 0x0D) ||
      unit == 0x20 ||
      unit == 0x85 ||
      unit == 0xA0 ||
      unit == 0x1680 ||
      (unit >= 0x2000 && unit <= 0x200A) ||
      unit == 0x2028 ||
      unit == 0x2029 ||
      unit == 0x202F ||
      unit == 0x205F ||
      unit == 0x3000;

  /// `null` drops the unit (tatweel, harakat).
  static int? _foldUnit(int unit) {
    // Tatweel, harakat (U+064B-065F) and the superscript alef (U+0670).
    if (unit == 0x0640 || (unit >= 0x064B && unit <= 0x065F)) return null;
    if (unit == 0x0670) return null;
    switch (unit) {
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0622: // آ
      case 0x0671: // ٱ
        return 0x0627; // ا
      case 0x0649: // ى
        return 0x064A; // ي
      case 0x0629: // ة
        return 0x0647; // ه
      case 0x0624: // ؤ
        return 0x0648; // و
      case 0x0626: // ئ
        return 0x064A; // ي
    }
    if (unit >= 0x41 && unit <= 0x5A) return unit + 0x20;
    // Other Latin capitals (Latin-1 and Latin Extended-A): lower-case only
    // when that keeps a single code unit, so the index map stays 1:1.
    if (unit >= 0xC0 && unit <= 0x24F) {
      final lower = String.fromCharCode(unit).toLowerCase();
      if (lower.length == 1) return lower.codeUnitAt(0);
    }
    return unit;
  }
}

/// The folded matching text, the display text and the map between them.
class FoldedText {
  const FoldedText._(this.forMatching, this.forDisplay, this._map);

  /// Steps 1-5.
  final String forMatching;

  /// Steps 1-3.
  final String forDisplay;

  /// `_map[i]` is the `forDisplay` index of `forMatching[i]`.
  final List<int> _map;

  /// The display index of folded index [index]; [forMatching]`.length`
  /// maps to the end of the display text.
  int displayIndex(int index) =>
      index >= _map.length ? forDisplay.length : _map[index];

  /// The display text of the folded span `[start, end)`.
  String displaySpan(int start, int end) {
    if (start >= end) return '';
    return forDisplay.substring(displayIndex(start), displayIndex(end));
  }

  @override
  String toString() => 'FoldedText(length: ${forDisplay.length})';
}
