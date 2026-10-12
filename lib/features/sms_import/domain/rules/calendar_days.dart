/// Calendar-day arithmetic for the duplicate rules (FR-059a, FR-059b,
/// FR-060): "within one day" compares local calendar days, never
/// `Duration` math, so a 23- or 25-hour DST day still counts as one day.
library;

/// How many calendar days lie between [a] and [b] (always >= 0).
int calendarDaysApart(DateTime a, DateTime b) {
  final dayA = DateTime.utc(a.year, a.month, a.day);
  final dayB = DateTime.utc(b.year, b.month, b.day);
  return dayA.difference(dayB).inDays.abs();
}

/// Whether [a] and [b] are at most one calendar day apart.
bool withinOneCalendarDay(DateTime a, DateTime b) =>
    calendarDaysApart(a, b) <= 1;
