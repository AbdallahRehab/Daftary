import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;

/// Direct `drift` access to `sms_import_settings`, `sms_sender_mutes` and
/// `sms_merchant_category_mappings` (data-model §4.3-§4.5).
///
/// The settings singleton follows `NotificationsDao`: an absent row means
/// the defaults, and the first write creates it with
/// `insertOnConflictUpdate`. The migration never inserts it.
@injectable
class SmsImportSettingsDao {
  SmsImportSettingsDao(this._db);

  final db.AppDatabase _db;

  /// The fixed id of the single settings row.
  static const settingsRowId = 'singleton';

  db.AppDatabase get database => _db;

  // ---------------------------------------------------------------- settings

  Future<db.SmsImportSettingsRow?> getSettings() => (_db.select(
    _db.smsImportSettings,
  )..where((t) => t.id.equals(settingsRowId))).getSingleOrNull();

  /// Creates the row with its defaults when absent. Idempotent.
  Future<db.SmsImportSettingsRow> ensureSettings() async {
    await _db
        .into(_db.smsImportSettings)
        .insert(
          const db.SmsImportSettingsCompanion(id: db.Value(settingsRowId)),
          mode: db.InsertMode.insertOrIgnore,
        );
    return (await getSettings())!;
  }

  /// Writes [changes] to the singleton, creating it first when absent.
  Future<void> updateSettings(db.SmsImportSettingsCompanion changes) async {
    await _db.transaction(() async {
      await ensureSettings();
      await (_db.update(
        _db.smsImportSettings,
      )..where((t) => t.id.equals(settingsRowId))).write(changes);
    });
  }

  /// Adds the non-negative deltas to the counters in one statement, so two
  /// concurrent increments never lose one (FR-102: monotonic).
  Future<void> addCounts({
    int scanned = 0,
    int recognized = 0,
    int added = 0,
    int ignored = 0,
  }) async {
    assert(
      scanned >= 0 && recognized >= 0 && added >= 0 && ignored >= 0,
      'Counters are monotonic',
    );
    final table = _db.smsImportSettings;
    await _db.transaction(() async {
      await ensureSettings();
      await (_db.update(table)..where((t) => t.id.equals(settingsRowId))).write(
        db.SmsImportSettingsCompanion.custom(
          scannedCount: table.scannedCount + db.Constant(scanned),
          recognizedCount: table.recognizedCount + db.Constant(recognized),
          addedCount: table.addedCount + db.Constant(added),
          ignoredCount: table.ignoredCount + db.Constant(ignored),
        ),
      );
    });
  }

  // ------------------------------------------------------------------- mutes

  Future<List<db.SmsSenderMuteRow>> getMutes() =>
      _db.select(_db.smsSenderMutes).get();

  Future<void> insertMute(String senderId, int createdAt) => _db
      .into(_db.smsSenderMutes)
      .insert(
        db.SmsSenderMutesCompanion.insert(
          senderId: senderId,
          createdAt: createdAt,
        ),
        mode: db.InsertMode.insertOrIgnore,
      );

  Future<int> deleteMute(String senderId) => (_db.delete(
    _db.smsSenderMutes,
  )..where((t) => t.senderId.equals(senderId))).go();

  /// Deletes the pending (status `pending`) rows of [senderId]; no
  /// tombstones (FR-065, FR-078). Returns how many.
  Future<int> deletePendingFromSender(String senderId) =>
      (_db.delete(_db.pendingSmsImports)..where(
            (p) => p.senderId.equals(senderId) & p.status.equals('pending'),
          ))
          .go();

  // ---------------------------------------------------------------- mappings

  Future<List<db.SmsMerchantCategoryMappingRow>> getMappings() =>
      (_db.select(_db.smsMerchantCategoryMappings)..orderBy([
            (t) => db.OrderingTerm(expression: t.merchantKey),
            (t) => db.OrderingTerm(expression: t.entryType),
          ]))
          .get();

  Future<void> upsertMapping(db.SmsMerchantCategoryMappingsCompanion row) =>
      _db.into(_db.smsMerchantCategoryMappings).insertOnConflictUpdate(row);

  Future<int> deleteMapping(String merchantKey, String entryType) =>
      (_db.delete(_db.smsMerchantCategoryMappings)..where(
            (t) =>
                t.merchantKey.equals(merchantKey) &
                t.entryType.equals(entryType),
          ))
          .go();

  Future<int> clearMappings() =>
      _db.delete(_db.smsMerchantCategoryMappings).go();
}
