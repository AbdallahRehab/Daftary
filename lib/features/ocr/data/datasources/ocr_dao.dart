import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;

/// Direct `drift` access to `ocr_scans` and `candidate_entries`.
///
/// Reads and writes only — every rule about *when* a row may change status
/// lives in `OcrRepositoryImpl`, so there is one place to look for the
/// answer to "how can a candidate entry become confirmed?" (constitution
/// Principle X).
@injectable
class OcrDao {
  OcrDao(this._db);

  final db.AppDatabase _db;

  Future<void> insertScan(db.OcrScansCompanion companion) =>
      _db.into(_db.ocrScans).insert(companion);

  Future<db.OcrScan?> getScanById(String id) => (_db.select(
    _db.ocrScans,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<db.OcrScan?> getScanByIdempotencyKey(String key) => (_db.select(
    _db.ocrScans,
  )..where((s) => s.idempotencyKey.equals(key))).getSingleOrNull();

  Future<void> updateScan(String id, db.OcrScansCompanion changes) =>
      (_db.update(_db.ocrScans)..where((s) => s.id.equals(id))).write(changes);

  /// Newest first (FR-018), excluding deleted scans.
  Future<List<db.OcrScan>> getScanHistory() {
    return (_db.select(_db.ocrScans)
          ..where((s) => s.deletedAt.isNull())
          ..orderBy([
            (s) => db.OrderingTerm(
              expression: s.createdAt,
              mode: db.OrderingMode.desc,
            ),
          ]))
        .get();
  }

  /// Written in one statement rather than a loop: a partially-inserted
  /// batch would leave a scan showing some of the page's lines and silently
  /// missing others, which is worse than failing outright.
  Future<void> insertCandidateEntries(
    List<db.CandidateEntriesCompanion> companions,
  ) async {
    if (companions.isEmpty) return;
    await _db.batch(
      (batch) => batch.insertAll(_db.candidateEntries, companions),
    );
  }

  /// Entries for one scan in insertion (page) order, so the review screen's
  /// default ordering matches the paper the user is holding.
  Future<List<db.CandidateEntry>> getEntriesForScan(String scanId) {
    return (_db.select(_db.candidateEntries)
          ..where((e) => e.scanId.equals(scanId))
          ..orderBy([(e) => db.OrderingTerm(expression: e.createdAt)]))
        .get();
  }

  Future<db.CandidateEntry?> getEntryById(String id) => (_db.select(
    _db.candidateEntries,
  )..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<void> updateEntry(String id, db.CandidateEntriesCompanion changes) =>
      (_db.update(
        _db.candidateEntries,
      )..where((e) => e.id.equals(id))).write(changes);

  Future<void> deleteEntriesForScan(String scanId) => (_db.delete(
    _db.candidateEntries,
  )..where((e) => e.scanId.equals(scanId))).go();

  Future<void> deleteScanRow(String scanId) =>
      (_db.delete(_db.ocrScans)..where((s) => s.id.equals(scanId))).go();

  /// Runs [action] inside one database transaction. Used by
  /// `confirmScanBatch` so a batch either lands whole or not at all
  /// (FR-011).
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);
}
