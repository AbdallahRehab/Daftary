import '../entities/notification_preference.dart';

/// When a notification evaluated at [now] should be delivered under
/// [preference]'s quiet-hours window (FR-013): `null` to deliver right away,
/// or the next occurrence of `quietHoursEnd` when [now] falls inside
/// `[quietHoursStart, quietHoursEnd)`.
///
/// Both bounds are minutes since local midnight; a start later than the end
/// is a window that crosses midnight (e.g. 22:00–08:00). Equal bounds are an
/// empty window.
DateTime? quietHoursDeliveryTime(
  NotificationPreference preference,
  DateTime now,
) {
  final start = preference.quietHoursStart;
  final end = preference.quietHoursEnd;
  if (start == null || end == null || start == end) return null;

  final minute = now.hour * 60 + now.minute;
  final inWindow = start < end
      ? minute >= start && minute < end
      : minute >= start || minute < end;
  if (!inWindow) return null;

  var deliverAt = DateTime(now.year, now.month, now.day, end ~/ 60, end % 60);
  if (!deliverAt.isAfter(now)) {
    // Calendar-day arithmetic (not `add(Duration(days: 1))`) keeps the
    // wall-clock time right across a DST change.
    deliverAt = DateTime(now.year, now.month, now.day + 1, end ~/ 60, end % 60);
  }
  return deliverAt;
}
