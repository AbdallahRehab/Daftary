import '../../../finance/domain/entities/finance_history_filter.dart';

/// Helpers for the `'YYYY-MM'` month key every budget is scoped to.
///
/// A plain string rather than a `DateTime` because a budget belongs to a
/// calendar month, not to an instant: storing a `DateTime` would invite
/// timezone and day-of-month drift into what is meant to be an exact key,
/// and the `budgets.month` unique index compares it byte for byte.
abstract final class BudgetMonth {
  static final RegExp _pattern = RegExp(r'^(\d{4})-(0[1-9]|1[0-2])$');

  /// Whether [month] is a well-formed `'YYYY-MM'` value.
  static bool isValid(String month) => _pattern.hasMatch(month);

  /// The month key [date] falls in.
  static String fromDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';

  /// The current calendar month, per the device clock.
  static String current() => fromDate(DateTime.now());

  /// The first day of [month]. Throws [FormatException] for a malformed
  /// key — callers validate with [isValid] first wherever the value came
  /// from user input.
  static DateTime toDate(String month) {
    final match = _pattern.firstMatch(month);
    if (match == null) {
      throw FormatException('Invalid budget month: $month');
    }
    return DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  /// [month] moved by [delta] months (negative for the past) — what month
  /// navigation and the trend window step with.
  static String shift(String month, int delta) {
    final start = toDate(month);
    return fromDate(DateTime(start.year, start.month + delta));
  }

  /// The whole of [month], first day through last day inclusive — the
  /// period 007's `getCategoryBreakdown` is asked about, so "actual spend"
  /// counts exactly the entries dated within the budget's month (FR-005).
  static DateRange toDateRange(String month) {
    final start = toDate(month);
    return DateRange(
      start: start,
      // Day 0 of the next month is the last day of this one.
      end: DateTime(start.year, start.month + 1, 0),
    );
  }
}
