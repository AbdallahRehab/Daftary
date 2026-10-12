import '../../../../core/money/money.dart';
import 'sms_text_normalizer.dart';

/// Currency words and symbols -> ISO codes (FR-035, parser-contract §5).
///
/// Markers are matched on folded text, longest first, so `جنيه استرليني`
/// (GBP) wins over `جنيه` (EGP). Deliberately absent, because they are
/// ambiguous: a bare `£` (EGP or GBP), `ريال` and `درهم` without a country.
/// An unrecognized marker never produces a currency: the user chooses one.
class SmsCurrencyTable {
  const SmsCurrencyTable._();

  static const Map<String, String> _markers = {
    // EGP
    'egp': 'EGP',
    'le': 'EGP',
    'l.e': 'EGP',
    'l.e.': 'EGP',
    'e£': 'EGP',
    'egyptian pound': 'EGP',
    'egyptian pounds': 'EGP',
    'ج.م': 'EGP',
    'ج.م.': 'EGP',
    'ج م': 'EGP',
    'جنيه': 'EGP',
    'جنيها': 'EGP',
    'جنيهات': 'EGP',
    'جنيه مصري': 'EGP',
    'جنيها مصريا': 'EGP',
    // USD
    'usd': 'USD',
    'us\$': 'USD',
    r'$': 'USD',
    'us dollar': 'USD',
    'us dollars': 'USD',
    'دولار': 'USD',
    'دولارا': 'USD',
    'دولارات': 'USD',
    'دولار امريكي': 'USD',
    // EUR
    'eur': 'EUR',
    '€': 'EUR',
    'euro': 'EUR',
    'euros': 'EUR',
    'يورو': 'EUR',
    // SAR
    'sar': 'SAR',
    'saudi riyal': 'SAR',
    'ريال سعودي': 'SAR',
    'ر.س': 'SAR',
    // AED
    'aed': 'AED',
    'uae dirham': 'AED',
    'درهم اماراتي': 'AED',
    'د.ا': 'AED',
    // GBP
    'gbp': 'GBP',
    'pound sterling': 'GBP',
    'جنيه استرليني': 'GBP',
  };

  /// Active ISO 4217 codes (lower-case), used to recognize a stated
  /// currency that is outside the app catalog (FR-053).
  static const Set<String> isoCodes = {
    'aed', 'afn', 'all', 'amd', 'ang', 'aoa', 'ars', 'aud', 'awg', 'azn', //
    'bam', 'bbd', 'bdt', 'bgn', 'bhd', 'bif', 'bmd', 'bnd', 'bob', 'brl',
    'bsd', 'btn', 'bwp', 'byn', 'bzd', 'cad', 'cdf', 'chf', 'clp', 'cny',
    'cop', 'crc', 'cup', 'cve', 'czk', 'djf', 'dkk', 'dop', 'dzd', 'egp',
    'ern', 'etb', 'eur', 'fjd', 'fkp', 'gbp', 'gel', 'ghs', 'gip', 'gmd',
    'gnf', 'gtq', 'gyd', 'hkd', 'hnl', 'htg', 'huf', 'idr', 'ils', 'inr',
    'iqd', 'irr', 'isk', 'jmd', 'jod', 'jpy', 'kes', 'kgs', 'khr', 'kmf',
    'kpw', 'krw', 'kwd', 'kyd', 'kzt', 'lak', 'lbp', 'lkr', 'lrd', 'lsl',
    'lyd', 'mad', 'mdl', 'mga', 'mkd', 'mmk', 'mnt', 'mop', 'mru', 'mur',
    'mvr', 'mwk', 'mxn', 'myr', 'mzn', 'nad', 'ngn', 'nio', 'nok', 'npr',
    'nzd', 'omr', 'pab', 'pen', 'pgk', 'php', 'pkr', 'pln', 'pyg', 'qar',
    'ron', 'rsd', 'rub', 'rwf', 'sar', 'sbd', 'scr', 'sdg', 'sek', 'sgd',
    'shp', 'sle', 'sos', 'srd', 'ssp', 'stn', 'syp', 'szl', 'thb', 'tjs',
    'tmt', 'tnd', 'top', 'try', 'ttd', 'twd', 'tzs', 'uah', 'ugx', 'usd',
    'uyu', 'uzs', 'ves', 'vnd', 'vuv', 'wst', 'xaf', 'xcd', 'xof', 'xpf',
    'yer', 'zar', 'zmw', 'zwl',
  };

  /// Folded markers, longest first.
  static final List<MapEntry<String, String>> _folded = () {
    final entries = [
      for (final entry in _markers.entries)
        MapEntry(SmsTextNormalizerImpl.fold(entry.key), entry.value),
    ]..sort((a, b) => b.key.length.compareTo(a.key.length));
    return List<MapEntry<String, String>>.unmodifiable(entries);
  }();

  /// The ISO code a whole marker text names (for a template `currency`
  /// group), or `null`. A three-letter ISO code outside the catalog is
  /// returned upper-case so the caller can report it (FR-053).
  static String? codeFor(String text) {
    final folded = SmsTextNormalizerImpl.fold(text).trim();
    if (folded.isEmpty) return null;
    for (final entry in _folded) {
      if (entry.key == folded) return entry.value;
    }
    if (folded.length == 3 && isoCodes.contains(folded)) {
      return folded.toUpperCase();
    }
    return null;
  }

  /// The catalog currency for [code], or `null` outside the catalog.
  static Currency? catalogCurrency(String? code) =>
      code == null ? null : Currency.tryFromCode(code);

  /// A marker that ENDS at [end] in [folded] (the marker precedes an
  /// amount), longest first.
  static CurrencyMarker? markerEndingAt(String folded, int end) {
    for (final entry in _folded) {
      final start = end - entry.key.length;
      if (start < 0) continue;
      if (!folded.startsWith(entry.key, start)) continue;
      if (!_leftBounded(folded, start, entry.key)) continue;
      return CurrencyMarker(start, end, entry.value);
    }
    return null;
  }

  /// A marker that STARTS at [start] in [folded] (the marker follows an
  /// amount), longest first.
  static CurrencyMarker? markerStartingAt(String folded, int start) {
    for (final entry in _folded) {
      if (!folded.startsWith(entry.key, start)) continue;
      final end = start + entry.key.length;
      if (!_rightBounded(folded, end, entry.key)) continue;
      return CurrencyMarker(start, end, entry.value);
    }
    return null;
  }

  /// Whether any currency marker appears anywhere in [folded] (used by the
  /// splitter's "never strip a line with a currency token" rule).
  static bool containsMarker(String folded) {
    for (final entry in _folded) {
      var from = 0;
      while (true) {
        final index = folded.indexOf(entry.key, from);
        if (index < 0) break;
        final end = index + entry.key.length;
        if (_leftBounded(folded, index, entry.key) &&
            _rightBounded(folded, end, entry.key)) {
          return true;
        }
        from = index + 1;
      }
    }
    return false;
  }

  static bool _leftBounded(String text, int start, String marker) {
    if (start == 0) return true;
    final first = marker.codeUnitAt(0);
    final before = text.codeUnitAt(start - 1);
    if (isLatinOrDigit(first)) return !isLatinOrDigit(before);
    if (isArabicLetter(first)) return !isArabicLetter(before);
    return true;
  }

  static bool _rightBounded(String text, int end, String marker) {
    if (end >= text.length) return true;
    final last = marker.codeUnitAt(marker.length - 1);
    final after = text.codeUnitAt(end);
    if (isLatinOrDigit(last)) return !isLatinOrDigit(after);
    if (isArabicLetter(last)) return !isArabicLetter(after);
    return true;
  }

  static bool isLatinOrDigit(int unit) =>
      (unit >= 0x61 && unit <= 0x7A) ||
      (unit >= 0x41 && unit <= 0x5A) ||
      (unit >= 0x30 && unit <= 0x39);

  static bool isArabicLetter(int unit) => unit >= 0x0621 && unit <= 0x064A;
}

/// A currency marker found in folded text: `[start, end)` and its code.
class CurrencyMarker {
  const CurrencyMarker(this.start, this.end, this.code);

  final int start;
  final int end;
  final String code;
}
