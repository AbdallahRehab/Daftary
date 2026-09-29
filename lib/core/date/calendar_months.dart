// Calendar-month arithmetic for plans measured in months (011 research.md
// Decision 11) — "10 months from now" as users count it, not a fixed number
// of days.

/// The number of whole calendar months from [from] to [to]:
/// `(Δyears × 12 + Δmonths)`, minus one when [to]'s day of the month is
/// earlier than [from]'s (that last month has not fully elapsed yet).
///
/// Only the calendar fields are compared — time of day is ignored. Zero for
/// two dates in the same month (or less than a month apart), and negative
/// when [to] is before [from]; callers that divide by the result floor it
/// themselves (e.g. `SavingsCalculator` floors at 1).
int wholeMonthsBetween(DateTime from, DateTime to) {
  final months = (to.year - from.year) * 12 + (to.month - from.month);
  return to.day < from.day ? months - 1 : months;
}

/// [date] moved by [months] calendar months (negative moves back), keeping
/// its day of the month and time of day — except that a day the target
/// month does not have is clamped to that month's last day (Jan 31 + 1 →
/// Feb 28, or Feb 29 in a leap year).
///
/// A UTC [date] stays UTC; a local one stays local.
DateTime addCalendarMonths(DateTime date, int months) {
  final monthIndex = date.year * 12 + (date.month - 1) + months;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = _daysInMonth(year, month);
  final day = date.day > lastDay ? lastDay : date.day;
  final build = date.isUtc ? DateTime.utc : DateTime.new;
  return build(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

/// Day 0 of the next month is the last day of this one; computed in UTC so
/// a daylight-saving shift can never land it on the wrong date.
int _daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;
