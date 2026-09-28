import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/sync/local/sync_outbox.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../sync/occasion_sync_mapper.dart';

/// Direct `drift` access to `occasions` and `occasion_attachments`.
///
/// Deliberately never touches `money_transactions`: a participant
/// contribution is an ordinary transaction row owned by the `transactions`
/// feature, and routing every contribution write through
/// `TransactionsRepository` is what keeps one occasion row and one person's
/// history reading from the same record (008 FR-005/FR-010).
///
/// 022: every occasion write records its change to the [SyncOutbox] in the
/// same transaction. Attachments are local-only (their photos never leave
/// the device, FR-017), so their writes queue nothing.
@injectable
class OccasionsDao {
  OccasionsDao(this._db, this._outbox, this._mapper);

  final db.AppDatabase _db;
  final SyncOutbox _outbox;
  final OccasionSyncMapper _mapper;

  /// Queues an upsert of occasion [id]'s current row. Must run inside a
  /// transaction.
  Future<db.Occasion> _recordUpsert(String id) async {
    final row = (await getById(id))!;
    await _outbox.recordUpsert(
      SyncEntityType.occasion,
      id,
      _mapper.toWire(row),
    );
    return row;
  }

  // -------------------------------------------------------------- occasions

  /// Inserts [companion]; if a row with the same `idempotency_key` already
  /// exists (unique index — FR-019), the unique-constraint violation is
  /// swallowed and the already-persisted row is returned instead of
  /// erroring. Mirrors `TransactionsDao.insertTransactionIdempotent`.
  Future<db.Occasion> insertOccasionIdempotent(
    db.OccasionsCompanion companion,
  ) {
    final idempotencyKey = companion.idempotencyKey.value;
    return _db.transaction(() async {
      // Checked first rather than caught: a failed insert inside a
      // transaction would roll the whole transaction back.
      final existing = await getByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      await _db.into(_db.occasions).insert(companion);
      final inserted = (await getByIdempotencyKey(idempotencyKey))!;
      return _recordUpsert(inserted.id);
    });
  }

  Future<db.Occasion?> getByIdempotencyKey(String key) => (_db.select(
    _db.occasions,
  )..where((o) => o.idempotencyKey.equals(key))).getSingleOrNull();

  /// Includes soft-deleted rows — the repository decides what a tombstoned
  /// occasion means for each caller, rather than this query hiding it.
  Future<db.Occasion?> getById(String id) => (_db.select(
    _db.occasions,
  )..where((o) => o.id.equals(id))).getSingleOrNull();

  Future<db.Occasion> updateOccasion(
    String id,
    db.OccasionsCompanion companion,
  ) {
    return _db.transaction(() async {
      await (_db.update(
        _db.occasions,
      )..where((o) => o.id.equals(id))).write(companion);
      return _recordUpsert(id);
    });
  }

  /// Archiving preserves everything (FR-014), so it only flips the flag and
  /// bumps `updated_at` — the contributions keep counting toward balances.
  Future<void> setArchived(String id, bool isArchived, DateTime updatedAt) {
    return _db.transaction(() async {
      await (_db.update(_db.occasions)..where((o) => o.id.equals(id))).write(
        db.OccasionsCompanion(
          isArchived: db.Value(isArchived),
          updatedAt: db.Value(updatedAt.millisecondsSinceEpoch),
        ),
      );
      await _recordUpsert(id);
    });
  }

  Future<void> softDeleteOccasion(String id, DateTime deletedAt) {
    return _db.transaction(() async {
      await (_db.update(_db.occasions)..where((o) => o.id.equals(id))).write(
        db.OccasionsCompanion(
          deletedAt: db.Value(deletedAt.millisecondsSinceEpoch),
          updatedAt: db.Value(deletedAt.millisecondsSinceEpoch),
        ),
      );
      await _recordUpsert(id);
    });
  }

  /// The occasions list, newest occasion date first (FR-015). Soft-deleted
  /// rows are never returned; archived ones only when [includeArchived].
  ///
  /// [fromDate]/[toDate] are inclusive bounds already reduced to date-only
  /// epoch millis by the caller, matching how `date` is stored.
  Future<List<db.Occasion>> getOccasions({
    String? nameQuery,
    String? type,
    int? fromDateMillis,
    int? toDateMillis,
    bool includeArchived = false,
  }) {
    final query = _db.select(_db.occasions)..where((o) => o.deletedAt.isNull());

    if (!includeArchived) {
      query.where((o) => o.isArchived.equals(false));
    }
    final trimmedName = nameQuery?.trim() ?? '';
    if (trimmedName.isNotEmpty) {
      final needle = trimmedName.toLowerCase();
      query.where((o) => o.name.lower().like('%$needle%'));
    }
    final trimmedType = type?.trim() ?? '';
    if (trimmedType.isNotEmpty) {
      query.where((o) => o.type.equals(trimmedType));
    }
    if (fromDateMillis != null) {
      query.where((o) => o.date.isBiggerOrEqualValue(fromDateMillis));
    }
    if (toDateMillis != null) {
      query.where((o) => o.date.isSmallerOrEqualValue(toDateMillis));
    }

    // `createdAt` breaks the tie: occasion dates are day-granular, so
    // several can share one date and the most recently added would
    // otherwise surface in an arbitrary position.
    query.orderBy([
      (o) => db.OrderingTerm(expression: o.date, mode: db.OrderingMode.desc),
      (o) =>
          db.OrderingTerm(expression: o.createdAt, mode: db.OrderingMode.desc),
    ]);
    return query.get();
  }

  // ------------------------------------------------------------ attachments

  Future<db.OccasionAttachment> insertAttachment(
    db.OccasionAttachmentsCompanion companion,
  ) async {
    await _db.into(_db.occasionAttachments).insert(companion);
    return (await getAttachmentById(companion.id.value))!;
  }

  Future<db.OccasionAttachment?> getAttachmentById(String id) => (_db.select(
    _db.occasionAttachments,
  )..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<void> softDeleteAttachment(String id, DateTime deletedAt) {
    return (_db.update(
      _db.occasionAttachments,
    )..where((a) => a.id.equals(id))).write(
      db.OccasionAttachmentsCompanion(
        deletedAt: db.Value(deletedAt.millisecondsSinceEpoch),
      ),
    );
  }

  /// Active attachments for one occasion, oldest first — the order they
  /// were added, which is the order the detail screen shows them in.
  Future<List<db.OccasionAttachment>> getAttachmentsForOccasion(
    String occasionId,
  ) {
    return (_db.select(_db.occasionAttachments)
          ..where((a) => a.occasionId.equals(occasionId) & a.deletedAt.isNull())
          ..orderBy([(a) => db.OrderingTerm(expression: a.createdAt)]))
        .get();
  }
}
