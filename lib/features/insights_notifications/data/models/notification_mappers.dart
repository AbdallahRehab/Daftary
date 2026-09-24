import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/notification_history_entry.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/entities/notification_source_type.dart';

/// Row ⇄ domain conversion for `notification_preferences`.
extension NotificationPreferenceRowMapper on db.NotificationPreference {
  NotificationPreference toDomain() => NotificationPreference(
    isEnabled: isEnabled,
    budgetWarningsEnabled: budgetWarningsEnabled,
    savingsCheckInsEnabled: savingsCheckInsEnabled,
    // Both-or-neither (data-model.md): a half-written window reads as none.
    quietHoursStart: quietHoursEndMinutes == null
        ? null
        : quietHoursStartMinutes,
    quietHoursEnd: quietHoursStartMinutes == null ? null : quietHoursEndMinutes,
    osPermissionGranted: osPermissionGranted,
  );
}

extension NotificationPreferenceCompanionMapper on NotificationPreference {
  db.NotificationPreferencesCompanion toCompanion(String id) =>
      db.NotificationPreferencesCompanion.insert(
        id: id,
        isEnabled: db.Value(isEnabled),
        budgetWarningsEnabled: db.Value(budgetWarningsEnabled),
        savingsCheckInsEnabled: db.Value(savingsCheckInsEnabled),
        quietHoursStartMinutes: db.Value(quietHoursStart),
        quietHoursEndMinutes: db.Value(quietHoursEnd),
        osPermissionGranted: db.Value(osPermissionGranted),
      );
}

/// Row ⇄ domain conversion for `notification_history`. Both enums are
/// stored by `name`, so this is the single place that string ⇄ enum
/// conversion happens.
extension NotificationHistoryRowMapper on db.NotificationHistoryData {
  NotificationHistoryEntry toDomain() => NotificationHistoryEntry(
    id: id,
    sourceType: NotificationSourceType.values.byName(sourceType),
    sourceId: sourceId,
    applicablePeriod: applicablePeriod,
    lastNotifiedBand: ThresholdBand.values.byName(lastNotifiedBand),
    lastNotifiedAt: DateTime.fromMillisecondsSinceEpoch(lastNotifiedAt),
  );
}

extension NotificationHistoryEntryMapper on NotificationHistoryEntry {
  db.NotificationHistoryData toRow() => db.NotificationHistoryData(
    id: id,
    sourceType: sourceType.name,
    sourceId: sourceId,
    applicablePeriod: applicablePeriod,
    lastNotifiedBand: lastNotifiedBand.name,
    lastNotifiedAt: lastNotifiedAt.millisecondsSinceEpoch,
  );
}
