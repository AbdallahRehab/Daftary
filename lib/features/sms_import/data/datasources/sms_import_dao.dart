import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;

/// Direct `drift` access to `pending_sms_imports` and
/// `sms_import_tombstones` (data-model §4.1, §4.2).
///
/// Reads and writes only. Every rule about when a row may change status
/// lives in `SmsImportRepositoryImpl`, so there is one place that answers
/// "how can a pending import become money?" (constitution X).
@injectable
class SmsImportDao {
  SmsImportDao(this._db);

  final db.AppDatabase _db;

  /// SQLite bound-variable budget per `IN (...)` list, well under the
  /// 999-variable minimum of older SQLite builds.
  static const int _inChunk = 400;

  db.AppDatabase get database => _db;

  // ------------------------------------------------------------ pending rows

  /// Inserts [row] unless its id or fingerprint already exists. Returns
  /// whether a row was inserted (the UNIQUE fingerprint index makes
  /// ingestion idempotent, FR-023).
  Future<bool> insertPendingIfAbsent(db.PendingSmsImportsCompanion row) async {
    final inserted = await _db
        .into(_db.pendingSmsImports)
        .insertReturningOrNull(row, mode: db.InsertMode.insertOrIgnore);
    return inserted != null;
  }

  Future<db.PendingSmsImportRow?> getPendingById(String id) => (_db.select(
    _db.pendingSmsImports,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Every row with [status].
  Future<List<db.PendingSmsImportRow>> getByStatus(String status) =>
      (_db.select(
        _db.pendingSmsImports,
      )..where((p) => p.status.equals(status))).get();

  /// One keyset page of rows with [status], ordered `(created_at, id)`
  /// ascending, strictly after the `(afterCreatedAt, afterId)` cursor.
  Future<List<db.PendingSmsImportRow>> pageByStatus(
    String status, {
    int? afterCreatedAt,
    String? afterId,
    int limit = 200,
  }) {
    final query = _db.select(_db.pendingSmsImports)
      ..where((p) {
        var predicate = p.status.equals(status);
        if (afterCreatedAt != null) {
          predicate =
              predicate &
              (p.createdAt.isBiggerThanValue(afterCreatedAt) |
                  (p.createdAt.equals(afterCreatedAt) &
                      p.id.isBiggerThanValue(afterId ?? '')));
        }
        return predicate;
      })
      ..orderBy([
        (p) => db.OrderingTerm(expression: p.createdAt),
        (p) => db.OrderingTerm(expression: p.id),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<int> countByStatus(String status) async {
    final count = _db.pendingSmsImports.id.count();
    final query = _db.selectOnly(_db.pendingSmsImports)
      ..addColumns([count])
      ..where(_db.pendingSmsImports.status.equals(status));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Rows with any of [statuses] decided at or after [decidedSince].
  Future<List<db.PendingSmsImportRow>> decidedSince(
    Set<String> statuses,
    int decidedSince,
  ) {
    return (_db.select(_db.pendingSmsImports)
          ..where(
            (p) =>
                p.status.isIn(statuses) &
                p.decidedAt.isBiggerOrEqualValue(decidedSince),
          )
          ..orderBy([
            (p) => db.OrderingTerm(
              expression: p.decidedAt,
              mode: db.OrderingMode.desc,
            ),
          ]))
        .get();
  }

  /// Writes [changes] to row [id]; returns how many rows changed.
  Future<int> updatePending(String id, db.PendingSmsImportsCompanion changes) =>
      (_db.update(
        _db.pendingSmsImports,
      )..where((p) => p.id.equals(id))).write(changes);

  /// Nulls the sealed original of [id] only while it is still pending
  /// (FR-074a, FR-075).
  Future<int> clearRawBlobIfPending(String id) =>
      (_db.update(_db.pendingSmsImports)
            ..where((p) => p.id.equals(id) & p.status.equals('pending')))
          .write(const db.PendingSmsImportsCompanion(rawBlob: db.Value(null)));

  /// Deletes every row with [status]; returns how many.
  Future<int> deleteByStatus(String status) => (_db.delete(
    _db.pendingSmsImports,
  )..where((p) => p.status.equals(status))).go();

  Future<int> deletePendingRow(String id) =>
      (_db.delete(_db.pendingSmsImports)..where((p) => p.id.equals(id))).go();

  /// Pending (status `pending`) rows whose `expires_at <= nowMillis`.
  Future<List<db.PendingSmsImportRow>> pendingExpiredBy(int nowMillis) =>
      (_db.select(_db.pendingSmsImports)..where(
            (p) =>
                p.status.equals('pending') &
                p.expiresAt.isSmallerOrEqualValue(nowMillis),
          ))
          .get();

  /// Deletes decided rows (any status but `pending`) decided at or before
  /// [cutoffMillis]; returns how many (FR-067).
  Future<int> deleteDecidedBy(int cutoffMillis) =>
      (_db.delete(_db.pendingSmsImports)..where(
            (p) =>
                p.status.equals('pending').not() &
                p.decidedAt.isSmallerOrEqualValue(cutoffMillis),
          ))
          .go();

  /// Fingerprints among [fingerprints] present in pending rows (any status).
  Future<Set<String>> pendingFingerprintsIn(Set<String> fingerprints) =>
      _chunked(fingerprints, (chunk) async {
        final rows = await (_db.select(
          _db.pendingSmsImports,
        )..where((p) => p.fingerprint.isIn(chunk))).get();
        return rows.map((r) => r.fingerprint);
      });

  /// Reference-amount hashes among [hashes] present in pending rows.
  Future<Set<String>> pendingRefAmountHashesIn(Set<String> hashes) =>
      _chunked(hashes, (chunk) async {
        final rows = await (_db.select(
          _db.pendingSmsImports,
        )..where((p) => p.refAmountHash.isIn(chunk))).get();
        return rows.map((r) => r.refAmountHash).whereType<String>();
      });

  /// Pending rows (any status) carrying [refAmountHash].
  Future<List<db.PendingSmsImportRow>> pendingWithRefAmountHash(
    String refAmountHash,
  ) => (_db.select(
    _db.pendingSmsImports,
  )..where((p) => p.refAmountHash.equals(refAmountHash))).get();

  /// Distinct reference hashes of pending rows (any status) for [bankId].
  Future<Set<String>> pendingRefHashesForBank(String bankId) async {
    final rows =
        await (_db.selectOnly(_db.pendingSmsImports, distinct: true)
              ..addColumns([_db.pendingSmsImports.refHash])
              ..where(
                _db.pendingSmsImports.bankId.equals(bankId) &
                    _db.pendingSmsImports.refHash.isNotNull(),
              ))
            .get();
    return {for (final row in rows) ?row.read(_db.pendingSmsImports.refHash)};
  }

  // -------------------------------------------------------------- tombstones

  Future<db.SmsImportTombstoneRow?> getTombstone(String fingerprint) =>
      (_db.select(
        _db.smsImportTombstones,
      )..where((t) => t.fingerprint.equals(fingerprint))).getSingleOrNull();

  Future<void> insertTombstone(db.SmsImportTombstonesCompanion row) =>
      _db.into(_db.smsImportTombstones).insertOnConflictUpdate(row);

  /// Fingerprints among [fingerprints] that are tombstoned.
  Future<Set<String>> tombstonedFingerprintsIn(Set<String> fingerprints) =>
      _chunked(fingerprints, (chunk) async {
        final rows = await (_db.select(
          _db.smsImportTombstones,
        )..where((t) => t.fingerprint.isIn(chunk))).get();
        return rows.map((r) => r.fingerprint);
      });

  /// Reference-amount hashes among [hashes] that are tombstoned.
  Future<Set<String>> tombstonedRefAmountHashesIn(Set<String> hashes) =>
      _chunked(hashes, (chunk) async {
        final rows = await (_db.select(
          _db.smsImportTombstones,
        )..where((t) => t.refAmountHash.isIn(chunk))).get();
        return rows.map((r) => r.refAmountHash).whereType<String>();
      });

  Future<List<db.SmsImportTombstoneRow>> tombstonesWithRefAmountHash(
    String refAmountHash,
  ) => (_db.select(
    _db.smsImportTombstones,
  )..where((t) => t.refAmountHash.equals(refAmountHash))).get();

  /// Distinct reference hashes of tombstones for [bankId].
  Future<Set<String>> tombstoneRefHashesForBank(String bankId) async {
    final rows =
        await (_db.selectOnly(_db.smsImportTombstones, distinct: true)
              ..addColumns([_db.smsImportTombstones.refHash])
              ..where(
                _db.smsImportTombstones.bankId.equals(bankId) &
                    _db.smsImportTombstones.refHash.isNotNull(),
              ))
            .get();
    return {for (final row in rows) ?row.read(_db.smsImportTombstones.refHash)};
  }

  /// Deletes the tombstones whose `purge_after <= nowMillis` (FR-066).
  Future<int> deleteTombstonesDueBy(int nowMillis) => (_db.delete(
    _db.smsImportTombstones,
  )..where((t) => t.purgeAfter.isSmallerOrEqualValue(nowMillis))).go();

  Future<int> deleteTombstone(String fingerprint) => (_db.delete(
    _db.smsImportTombstones,
  )..where((t) => t.fingerprint.equals(fingerprint))).go();

  // ------------------------------------------------------------------ helper

  Future<Set<String>> _chunked(
    Set<String> values,
    Future<Iterable<String>> Function(List<String> chunk) run,
  ) async {
    final result = <String>{};
    if (values.isEmpty) return result;
    final list = values.toList();
    for (var start = 0; start < list.length; start += _inChunk) {
      final end = start + _inChunk > list.length
          ? list.length
          : start + _inChunk;
      result.addAll(await run(list.sublist(start, end)));
    }
    return result;
  }
}
