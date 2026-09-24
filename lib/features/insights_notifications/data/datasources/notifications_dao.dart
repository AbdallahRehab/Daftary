import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;

/// Direct `drift` access to `notification_preferences` and
/// `notification_history` (017). Touches no other table.
@injectable
class NotificationsDao {
  NotificationsDao(this._db);

  final db.AppDatabase _db;

  /// The fixed id of the single preferences row (data-model.md).
  static const preferenceRowId = 'singleton';

  // ------------------------------------------------------------ preferences

  Future<db.NotificationPreference?> getPreference() => (_db.select(
    _db.notificationPreferences,
  )..where((t) => t.id.equals(preferenceRowId))).getSingleOrNull();

  Future<db.NotificationPreference> upsertPreference(
    db.NotificationPreferencesCompanion companion,
  ) async {
    await _db
        .into(_db.notificationPreferences)
        .insertOnConflictUpdate(
          companion.copyWith(id: const db.Value(preferenceRowId)),
        );
    return (await getPreference())!;
  }

  // ---------------------------------------------------------------- history

  Future<db.NotificationHistoryData?> findHistory({
    required String sourceType,
    required String sourceId,
    required String? applicablePeriod,
  }) {
    return (_db.select(_db.notificationHistory)..where((t) {
          final period = applicablePeriod == null
              ? t.applicablePeriod.isNull()
              : t.applicablePeriod.equals(applicablePeriod);
          return t.sourceType.equals(sourceType) &
              t.sourceId.equals(sourceId) &
              period;
        }))
        .getSingleOrNull();
  }

  /// Inserts [row] when its (source, period) has no history yet, overwrites
  /// the existing row's band/timestamp when the band differs, and leaves an
  /// existing row with the same band untouched. Runs in one transaction so
  /// two overlapping recomputation passes cannot both insert.
  Future<db.NotificationHistoryData> upsertHistoryOnBandChange(
    db.NotificationHistoryData row,
  ) {
    return _db.transaction(() async {
      final existing = await findHistory(
        sourceType: row.sourceType,
        sourceId: row.sourceId,
        applicablePeriod: row.applicablePeriod,
      );
      if (existing == null) {
        await _db.into(_db.notificationHistory).insert(row);
        return row;
      }
      if (existing.lastNotifiedBand == row.lastNotifiedBand) return existing;

      final updated = existing.copyWith(
        lastNotifiedBand: row.lastNotifiedBand,
        lastNotifiedAt: row.lastNotifiedAt,
      );
      await _db.update(_db.notificationHistory).replace(updated);
      return updated;
    });
  }
}
