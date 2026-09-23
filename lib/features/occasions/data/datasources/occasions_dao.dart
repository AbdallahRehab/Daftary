import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;

/// Direct `drift` access to `occasions` and `occasion_attachments`.
///
/// Deliberately never touches `money_transactions`: a participant
/// contribution is an ordinary transaction row owned by the `transactions`
/// feature, and routing every contribution write through
/// `TransactionsRepository` is what keeps one occasion row and one person's
/// history reading from the same record (008 FR-005/FR-010).
@injectable
class OccasionsDao {
  OccasionsDao(this._db);

  final db.AppDatabase _db;

  // -------------------------------------------------------------- occasions

  /// Inserts [companion]; if a row with the same `idempotency_key` already
  /// exists (unique index — FR-019), the unique-constraint violation is
  /// swallowed and the already-persisted row is returned instead of
  /// erroring. Mirrors `TransactionsDao.insertTransactionIdempotent`.
  Future<db.Occasion> insertOccasionIdempotent(
    db.OccasionsCompanion companion,
  ) async {
    final idempotencyKey = companion.idempotencyKey.value;
    try {
      await _db.into(_db.occasions).insert(companion);
    } catch (_) {
      final existing = await getByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      rethrow;
    }
    return (await getByIdempotencyKey(idempotencyKey))!;
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
  ) async {
    await (_db.update(
      _db.occasions,
    )..where((o) => o.id.equals(id))).write(companion);
    return (await getById(id))!;
  }

  /// Archiving preserves everything (FR-014), so it only flips the flag and
  /// bumps `updated_at` — the contributions keep counting toward balances.
  Future<void> setArchived(String id, bool isArchived, DateTime updatedAt) {
    return (_db.update(_db.occasions)..where((o) => o.id.equals(id))).write(
      db.OccasionsCompanion(
        isArchived: db.Value(isArchived),
        updatedAt: db.Value(updatedAt.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> softDeleteOccasion(String id, DateTime deletedAt) {
    return (_db.update(_db.occasions)..where((o) => o.id.equals(id))).write(
      db.OccasionsCompanion(
        deletedAt: db.Value(deletedAt.millisecondsSinceEpoch),
        updatedAt: db.Value(deletedAt.millisecondsSinceEpoch),
      ),
    );
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
