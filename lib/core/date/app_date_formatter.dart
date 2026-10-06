import 'package:intl/intl.dart';

import '../l10n/numeral_locale.dart';
import '../money/numeral_parser.dart';

/// Locale-aware date formatting, centralized here (mirrors `EgpFormatter`'s
/// shape) instead of duplicated across call sites — replaces the app's
/// previous locale-blind `'${date.year}-${date.month}-${date.day}'`
/// strings (research.md Decision 8). Always renders Western digits (0-9),
/// even under Arabic (FR-011).
class AppDateFormatter {
  AppDateFormatter({String locale = 'en'})
    : _resolved = numeralLocaleFor(locale),
      _format = _formatFor(numeralLocaleFor(locale));

  final DateFormat _format;
  late final DateFormat _dateTimeFormat = _dateTimeFor(_resolved);
  final String _resolved;

  // `DateFormat` construction does real locale-data lookup — not free, and
  // this is routinely constructed fresh per widget build (T107's lesson
  // for `EgpFormatter` applies here too), so cache per resolved locale.
  static final Map<String, DateFormat> _cache = {};

  static final Map<String, DateFormat> _dateTimeCache = {};

  static DateFormat _dateTimeFor(String resolvedLocale) =>
      _dateTimeCache.putIfAbsent(
        resolvedLocale,
        () => DateFormat.yMd(resolvedLocale).add_jm(),
      );

  static DateFormat _formatFor(String resolvedLocale) =>
      _cache.putIfAbsent(resolvedLocale, () => DateFormat.yMd(resolvedLocale));

  /// Formats [date] as a locale-appropriate `y/M/d`-style string, always
  /// with Western digits.
  ///
  /// The `_u_nu_latn` locale extension (see `numeralLocaleFor`) is `intl`'s
  /// documented mechanism for this, but `DateFormat`'s locale-fallback
  /// resolution was found (by an integration test running against real
  /// `flutter_localizations` locale loading, not just this package's own
  /// `initializeDateFormatting`) to sometimes silently drop the extension
  /// and fall back to plain `'ar'`, which renders Eastern Arabic-Indic
  /// digits. Post-processing through the same digit-substitution utility
  /// already used for input normalization guarantees the FR-011 output
  /// requirement regardless of that resolution quirk.
  String format(DateTime date) =>
      NumeralParser.toWesternDigits(_format.format(date));

  /// Like [format] plus the time of day (`y/M/d` and `h:mm a`), still with
  /// Western digits (022 C3 change-history timestamps).
  String formatDateTime(DateTime date) =>
      NumeralParser.toWesternDigits(_dateTimeFormat.format(date));
}
