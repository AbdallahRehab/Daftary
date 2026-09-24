import 'package:daftary/features/insights_notifications/domain/entities/notification_preference.dart';
import 'package:daftary/features/insights_notifications/domain/services/quiet_hours.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationPreference window(int startHour, int endHour) =>
    NotificationPreference.defaults.copyWith(
      quietHoursStart: startHour * 60,
      quietHoursEnd: endHour * 60,
    );

void main() {
  test('no window configured delivers now', () {
    expect(
      quietHoursDeliveryTime(
        NotificationPreference.defaults,
        DateTime(2026, 9, 24, 23),
      ),
      isNull,
    );
  });

  group('window crossing midnight (22:00–08:00)', () {
    final pref = window(22, 8);

    test('late evening defers to tomorrow 08:00', () {
      expect(
        quietHoursDeliveryTime(pref, DateTime(2026, 9, 24, 22)),
        DateTime(2026, 9, 25, 8),
      );
    });

    test('early morning defers to today 08:00', () {
      expect(
        quietHoursDeliveryTime(pref, DateTime(2026, 9, 25, 3, 30)),
        DateTime(2026, 9, 25, 8),
      );
    });

    test('the end bound itself is outside the window', () {
      expect(quietHoursDeliveryTime(pref, DateTime(2026, 9, 25, 8)), isNull);
    });

    test('daytime delivers now', () {
      expect(
        quietHoursDeliveryTime(pref, DateTime(2026, 9, 25, 21, 59)),
        isNull,
      );
    });

    test('month end rolls into the next month', () {
      expect(
        quietHoursDeliveryTime(pref, DateTime(2026, 9, 30, 23)),
        DateTime(2026, 10, 1, 8),
      );
    });
  });

  group('same-day window (13:00–15:00)', () {
    final pref = window(13, 15);

    test('inside defers to today 15:00', () {
      expect(
        quietHoursDeliveryTime(pref, DateTime(2026, 9, 24, 14)),
        DateTime(2026, 9, 24, 15),
      );
    });

    test('outside delivers now', () {
      expect(quietHoursDeliveryTime(pref, DateTime(2026, 9, 24, 16)), isNull);
      expect(quietHoursDeliveryTime(pref, DateTime(2026, 9, 24, 12)), isNull);
    });
  });

  test('equal bounds are an empty window', () {
    expect(
      quietHoursDeliveryTime(window(9, 9), DateTime(2026, 9, 24, 9)),
      isNull,
    );
  });
}
