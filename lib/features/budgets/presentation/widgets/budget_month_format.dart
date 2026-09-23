import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/numeral_locale.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/budget_month.dart';

/// Localized labels for a `'YYYY-MM'` budget month, always with Western
/// digits (FR-011) — resolved through the same `numeralLocaleFor` +
/// digit-normalization path as `AppDateFormatter`, for the same reason.
abstract final class BudgetMonthFormat {
  static final Map<String, DateFormat> _cache = {};

  static DateFormat _format(
    String key,
    String locale,
    DateFormat Function(String) build,
  ) => _cache.putIfAbsent('$key|$locale', () => build(locale));

  static String _locale(BuildContext context) =>
      numeralLocaleFor(Localizations.localeOf(context).languageCode);

  /// e.g. "September 2026" / "سبتمبر 2026".
  static String long(BuildContext context, String month) =>
      NumeralParser.toWesternDigits(
        _format(
          'yMMMM',
          _locale(context),
          DateFormat.yMMMM,
        ).format(BudgetMonth.toDate(month)),
      );

  /// e.g. "Sep" / "سبتمبر" — for chart axis labels, where the year is
  /// shown separately (or implied by the window).
  static String short(BuildContext context, String month) =>
      NumeralParser.toWesternDigits(
        _format(
          'MMM',
          _locale(context),
          DateFormat.MMM,
        ).format(BudgetMonth.toDate(month)),
      );

  /// e.g. "Sep 2026" — for tooltips and accessibility labels.
  static String medium(BuildContext context, String month) =>
      NumeralParser.toWesternDigits(
        _format(
          'yMMM',
          _locale(context),
          DateFormat.yMMM,
        ).format(BudgetMonth.toDate(month)),
      );
}
