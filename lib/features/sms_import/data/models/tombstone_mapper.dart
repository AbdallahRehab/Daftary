import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_import_tombstone.dart';

/// Maps `sms_import_tombstones` rows to [SmsImportTombstone] and back
/// (data-model §3.2, §4.2). Hashes, codes and dates only.
extension SmsImportTombstoneRowMapper on db.SmsImportTombstoneRow {
  SmsImportTombstone toDomain() {
    final created = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final storedPurge = DateTime.fromMillisecondsSinceEpoch(purgeAfter);
    final minimum = SmsImportTombstone.minimumPurgeAfter(created);
    return SmsImportTombstone(
      fingerprint: fingerprint,
      outcome: TombstoneOutcome.fromDb(outcome),
      bankId: bankId,
      refHash: refHash,
      refAmountHash: refAmountHash,
      savedRecordId: savedRecordId,
      savedRecordType: SavedRecordType.fromDb(savedRecordType),
      createdAt: created,
      // A row written with a shorter retention (never by this code) reads
      // as the minimum, so the entity invariant always holds.
      purgeAfter: storedPurge.isBefore(minimum) ? minimum : storedPurge,
    );
  }
}

db.SmsImportTombstonesCompanion tombstoneToCompanion(
  SmsImportTombstone tombstone,
) {
  return db.SmsImportTombstonesCompanion.insert(
    fingerprint: tombstone.fingerprint,
    outcome: tombstone.outcome.dbValue,
    bankId: tombstone.bankId,
    refHash: db.Value(tombstone.refHash),
    refAmountHash: db.Value(tombstone.refAmountHash),
    savedRecordId: db.Value(tombstone.savedRecordId),
    savedRecordType: db.Value(tombstone.savedRecordType?.dbValue),
    createdAt: tombstone.createdAt.millisecondsSinceEpoch,
    purgeAfter: tombstone.purgeAfter.millisecondsSinceEpoch,
  );
}
