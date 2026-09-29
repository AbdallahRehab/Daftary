import 'package:daftary/core/date/calendar_months.dart';
import 'package:flutter_test/flutter_test.dart';

/// 011 research.md Decision 11: the month counting behind every savings
/// estimate and required contribution.
void main() {
  group('wholeMonthsBetween', () {
    final cases = <(String, DateTime, DateTime, int)>[
      ('same day', DateTime(2026, 3, 15), DateTime(2026, 3, 15), 0),
      ('same month, later day', DateTime(2026, 3, 5), DateTime(2026, 3, 28), 0),
      (
        'same day of the next month',
        DateTime(2026, 3, 15),
        DateTime(2026, 4, 15),
        1,
      ),
      (
        'later day of the next month',
        DateTime(2026, 3, 15),
        DateTime(2026, 4, 20),
        1,
      ),
      // 20th → 5th: the last month has not fully elapsed.
      ('day-of-month earlier', DateTime(2026, 3, 20), DateTime(2026, 4, 5), 0),
      (
        'day-of-month earlier, ten months on',
        DateTime(2026, 1, 20),
        DateTime(2026, 11, 5),
        9,
      ),
      ('ten whole months', DateTime(2026, 1, 20), DateTime(2026, 11, 20), 10),
      ('year rollover', DateTime(2026, 11, 10), DateTime(2027, 2, 10), 3),
      (
        'year rollover, earlier day',
        DateTime(2026, 11, 10),
        DateTime(2027, 2, 9),
        2,
      ),
      ('several years', DateTime(2026, 6, 1), DateTime(2030, 6, 1), 48),
      (
        'month-end to shorter month-end',
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        0,
      ),
      (
        'time of day is ignored',
        DateTime(2026, 3, 15, 23, 59),
        DateTime(2026, 4, 15, 0, 1),
        1,
      ),
      (
        'target before start is negative',
        DateTime(2026, 5, 10),
        DateTime(2026, 3, 10),
        -2,
      ),
    ];
    for (final (name, from, to, expected) in cases) {
      test(name, () => expect(wholeMonthsBetween(from, to), expected));
    }
  });

  group('addCalendarMonths', () {
    final cases = <(String, DateTime, int, DateTime)>[
      ('zero months', DateTime(2026, 3, 15), 0, DateTime(2026, 3, 15)),
      ('one month', DateTime(2026, 3, 15), 1, DateTime(2026, 4, 15)),
      ('year rollover', DateTime(2026, 11, 15), 3, DateTime(2027, 2, 15)),
      ('twenty months', DateTime(2026, 9, 29), 20, DateTime(2028, 5, 29)),
      (
        'Jan 31 + 1 clamps to Feb 28',
        DateTime(2026, 1, 31),
        1,
        DateTime(2026, 2, 28),
      ),
      (
        'Jan 31 + 1 clamps to Feb 29 in a leap year',
        DateTime(2028, 1, 31),
        1,
        DateTime(2028, 2, 29),
      ),
      (
        'Mar 31 + 1 clamps to Apr 30',
        DateTime(2026, 3, 31),
        1,
        DateTime(2026, 4, 30),
      ),
      (
        'clamping does not carry forward',
        DateTime(2026, 1, 31),
        2,
        DateTime(2026, 3, 31),
      ),
      ('backwards', DateTime(2026, 3, 31), -1, DateTime(2026, 2, 28)),
      (
        'backwards across a year',
        DateTime(2026, 1, 15),
        -2,
        DateTime(2025, 11, 15),
      ),
      (
        'keeps the time of day',
        DateTime(2026, 3, 15, 9, 30),
        1,
        DateTime(2026, 4, 15, 9, 30),
      ),
    ];
    for (final (name, date, months, expected) in cases) {
      test(name, () => expect(addCalendarMonths(date, months), expected));
    }

    test('a UTC date stays UTC', () {
      final result = addCalendarMonths(DateTime.utc(2026, 1, 31), 1);
      expect(result.isUtc, isTrue);
      expect(result, DateTime.utc(2026, 2, 28));
    });

    test('round-trips with wholeMonthsBetween', () {
      final start = DateTime(2026, 1, 20);
      for (var months = 0; months <= 60; months++) {
        expect(
          wholeMonthsBetween(start, addCalendarMonths(start, months)),
          months,
        );
      }
    });
  });
}
