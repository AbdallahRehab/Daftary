import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/watch_tables.dart';
import '../../../../core/sync/local/sync_outbox.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_history_filter.dart';
import '../sync/finance_category_sync_mapper.dart';
import '../sync/finance_entry_sync_mapper.dart';

/// One category's aggregate in one currency within a period, straight off
/// the `GROUP BY category_id, currency_code` — the category's display
/// fields ride along from the join so the repository needs no second lookup
/// per row.
class CategoryTotalRow {
  const CategoryTotalRow({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.currencyCode,
    required this.totalMinorUnits,
  });

  final String categoryId;
  final String categoryName;
  final String icon;
  final String currencyCode;
  final int totalMinorUnits;
}

/// One direction's aggregate in one currency, straight off the
/// `GROUP BY type, currency_code`.
class SummaryTotalRow {
  const SummaryTotalRow({
    required this.type,
    required this.currencyCode,
    required this.totalMinorUnits,
  });

  /// `'income'` or `'expense'`.
  final String type;
  final String currencyCode;
  final int totalMinorUnits;
}

/// Direct `drift` access to `finance_categories` and `finance_entries`.
///
/// Every total is computed by a SQL aggregate rather than by summing a
/// fetched list in Dart (research.md Decision 6) — the same choice
/// `BalanceQueries` already makes for the `transactions` feature, and the
/// reason a 5,000-entry period still renders inside the <1s budget.
///
/// No query in this class joins against `people` or `money_transactions`
/// (FR-023); the boundary is enforced by `isolation_from_transactions_test`.
///
/// 021: every category and entry write records its change to the
/// [SyncOutbox] inside the same `_db.transaction` (plan.md §7). The
/// first-launch category seed (`finance_category_seed.dart`) writes directly
/// and records nothing.
@injectable
class FinanceDao {
  FinanceDao(this._db, this._outbox, this._categoryMapper, this._entryMapper);

  final db.AppDatabase _db;
  final SyncOutbox _outbox;
  final FinanceCategorySyncMapper _categoryMapper;
  final FinanceEntrySyncMapper _entryMapper;

  /// Queues an upsert of entry [id]'s current row. Must run inside a
  /// transaction.
  Future<db.FinanceEntry> _recordEntryUpsert(String id) async {
    final row = (await getEntryById(id))!;
    await _outbox.recordUpsert(
      SyncEntityType.financeEntry,
      id,
      _entryMapper.toWire(row),
    );
    return row;
  }

  /// Queues an upsert of category [id]'s current row. Must run inside a
  /// transaction.
  Future<db.FinanceCategory> _recordCategoryUpsert(String id) async {
    final row = (await getCategoryById(id))!;
    await _outbox.recordUpsert(
      SyncEntityType.financeCategory,
      id,
      _categoryMapper.toWire(row),
    );
    return row;
  }

  // ---------------------------------------------------------- change signals

  /// 021: fires now and after every burst of writes to `finance_entries`.
  Stream<void> entriesChanged() => _db.changesOf({_db.financeEntries});

  /// 021: fires now and after every burst of writes to
  /// `finance_categories`.
  Stream<void> categoriesChanged() => _db.changesOf({_db.financeCategories});

  /// 021: fires now and after every burst of writes to either table a
  /// category breakdown reads — the entries it sums and the categories that
  /// name and label its rows.
  Stream<void> categoryTotalsChanged() =>
      _db.changesOf({_db.financeEntries, _db.financeCategories});

  // ---------------------------------------------------------------- entries

  /// Inserts [companion]; if a row with the same `idempotency_key` already
  /// exists (unique index — FR-021), the already-persisted row is returned
  /// instead of erroring, and nothing is queued for upload. Mirrors
  /// `TransactionsDao.insertTransactionIdempotent`.
  Future<db.FinanceEntry> insertEntryIdempotent(
    db.FinanceEntriesCompanion companion,
  ) {
    final idempotencyKey = companion.idempotencyKey.value;
    return _db.transaction(() async {
      final existing = await getEntryByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      await _db.into(_db.financeEntries).insert(companion);
      final inserted = (await getEntryByIdempotencyKey(idempotencyKey))!;
      await _outbox.recordUpsert(
        SyncEntityType.financeEntry,
        inserted.id,
        _entryMapper.toWire(inserted),
      );
      return inserted;
    });
  }

  Future<db.FinanceEntry?> getEntryByIdempotencyKey(String key) => (_db.select(
    _db.financeEntries,
  )..where((t) => t.idempotencyKey.equals(key))).getSingleOrNull();

  /// Includes soft-deleted rows — a restore has to be able to find the row
  /// it is restoring.
  Future<db.FinanceEntry?> getEntryById(String id) => (_db.select(
    _db.financeEntries,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<db.FinanceEntry> updateEntry(
    String id,
    db.FinanceEntriesCompanion companion,
  ) {
    return _db.transaction(() async {
      await (_db.update(
        _db.financeEntries,
      )..where((t) => t.id.equals(id))).write(companion);
      return _recordEntryUpsert(id);
    });
  }

  /// A soft delete uploads as an upsert carrying `deleted_at`.
  Future<void> softDeleteEntry(String id, DateTime deletedAt) {
    return _db.transaction(() async {
      final updated =
          await (_db.update(
            _db.financeEntries,
          )..where((t) => t.id.equals(id))).write(
            db.FinanceEntriesCompanion(
              deletedAt: db.Value(deletedAt.millisecondsSinceEpoch),
            ),
          );
      if (updated > 0) await _recordEntryUpsert(id);
    });
  }

  /// Un-sets the soft-delete tombstone (research.md Decision 8's undo).
  Future<void> restoreEntry(String id) {
    return _db.transaction(() async {
      final updated =
          await (_db.update(
            _db.financeEntries,
          )..where((t) => t.id.equals(id))).write(
            const db.FinanceEntriesCompanion(deletedAt: db.Value(null)),
          );
      if (updated > 0) await _recordEntryUpsert(id);
    });
  }

  /// Filtered, paginated history, newest date first, soft-deleted rows
  /// excluded (FR-012/FR-013).
  ///
  /// `createdAt` is the tiebreaker after `date`: entries are day-granular,
  /// so several can share a date, and without it "the entry I just added is
  /// at the top" (US1's acceptance criterion) would hold only by accident.
  Future<List<db.FinanceEntry>> getHistory({
    FinanceHistoryFilter? filter,
    int limit = 50,
    int offset = 0,
  }) {
    final query = _db.select(_db.financeEntries)
      ..where((t) => t.deletedAt.isNull());

    final type = filter?.type;
    if (type != null) {
      query.where((t) => t.type.equals(type.dbValue));
    }
    final categoryId = filter?.categoryId;
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    final range = filter?.dateRange;
    if (range != null) {
      query.where(
        (t) => t.date.isBetweenValues(range.startMillis, range.endMillis),
      );
    }

    query
      ..orderBy([
        (t) => db.OrderingTerm(expression: t.date, mode: db.OrderingMode.desc),
        (t) => db.OrderingTerm(
          expression: t.createdAt,
          mode: db.OrderingMode.desc,
        ),
      ])
      ..limit(limit, offset: offset);

    return query.get();
  }

  /// `SUM(amount_minor_units) ... WHERE date BETWEEN ? AND ? AND deleted_at
  /// IS NULL GROUP BY type, currency_code` — one round trip for every
  /// direction/currency total (research.md Decision 6). Amounts in
  /// different currencies are never summed together here (018 FR-008): the
  /// per-currency rows are converted by the domain layer.
  Future<List<SummaryTotalRow>> getSummaryTotals(DateRange period) async {
    final total = _db.financeEntries.amountMinorUnits.sum();
    final query = _db.selectOnly(_db.financeEntries)
      ..addColumns([
        _db.financeEntries.type,
        _db.financeEntries.currencyCode,
        total,
      ])
      ..where(
        _db.financeEntries.deletedAt.isNull() &
            _db.financeEntries.date.isBetweenValues(
              period.startMillis,
              period.endMillis,
            ),
      )
      ..groupBy([_db.financeEntries.type, _db.financeEntries.currencyCode]);

    final rows = await query.get();
    return [
      for (final row in rows)
        SummaryTotalRow(
          type: row.read(_db.financeEntries.type)!,
          currencyCode: row.read(_db.financeEntries.currencyCode)!,
          totalMinorUnits: row.read(total) ?? 0,
        ),
    ];
  }

  /// Per-category, per-currency totals for [period], descending by amount
  /// (FR-015) — one row per `(category, currency)` pair (018 FR-008).
  /// Joined to `finance_categories` so an archived category's entries still
  /// resolve a name and icon — the breakdown must not drop them.
  Future<List<CategoryTotalRow>> getCategoryBreakdown(
    DateRange period, {
    FinanceEntryType? type,
  }) async {
    final total = _db.financeEntries.amountMinorUnits.sum();
    final query = _db.selectOnly(_db.financeEntries)
      ..addColumns([
        _db.financeEntries.categoryId,
        _db.financeEntries.currencyCode,
        total,
      ]);

    query.join([
      db.innerJoin(
        _db.financeCategories,
        _db.financeCategories.id.equalsExp(_db.financeEntries.categoryId),
      ),
    ]);
    query.addColumns([_db.financeCategories.name, _db.financeCategories.icon]);

    var predicate =
        _db.financeEntries.deletedAt.isNull() &
        _db.financeEntries.date.isBetweenValues(
          period.startMillis,
          period.endMillis,
        );
    if (type != null) {
      predicate = predicate & _db.financeEntries.type.equals(type.dbValue);
    }
    query
      ..where(predicate)
      ..groupBy([
        _db.financeEntries.categoryId,
        _db.financeEntries.currencyCode,
      ])
      ..orderBy([
        db.OrderingTerm(expression: total, mode: db.OrderingMode.desc),
      ]);

    final rows = await query.get();
    return [
      for (final row in rows)
        CategoryTotalRow(
          categoryId: row.read(_db.financeEntries.categoryId)!,
          categoryName: row.read(_db.financeCategories.name)!,
          icon: row.read(_db.financeCategories.icon)!,
          currencyCode: row.read(_db.financeEntries.currencyCode)!,
          totalMinorUnits: row.read(total) ?? 0,
        ),
    ];
  }

  /// Counts entries referencing [categoryId], **including soft-deleted
  /// ones** (research.md Decision 4): a restored entry must still resolve
  /// its category, so a soft-deleted entry is every bit as much a reason to
  /// archive rather than hard-delete.
  Future<int> countEntriesForCategory(String categoryId) async {
    final count = _db.financeEntries.id.count();
    final query = _db.selectOnly(_db.financeEntries)
      ..addColumns([count])
      ..where(_db.financeEntries.categoryId.equals(categoryId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// FR-017's true-empty check: whether any entry exists at all, including
  /// soft-deleted ones. A cheap `LIMIT 1`, never a full fetch.
  Future<bool> hasAnyEntry() async {
    final row = await (_db.select(
      _db.financeEntries,
    )..limit(1)).getSingleOrNull();
    return row != null;
  }

  // ------------------------------------------------------------- categories

  Future<List<db.FinanceCategory>> getCategoriesByType(
    FinanceEntryType type, {
    bool includeArchived = false,
  }) {
    final query = _db.select(_db.financeCategories)
      ..where((t) => t.type.equals(type.dbValue));
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([(t) => db.OrderingTerm(expression: t.name)]);
    return query.get();
  }

  Future<db.FinanceCategory?> getCategoryById(String id) => (_db.select(
    _db.financeCategories,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The FR-008 duplicate lookup: an **active** category of the same
  /// [type] carrying [normalizedName]. Archived rows are deliberately out of
  /// scope — re-creating a name after archiving it is explicitly allowed
  /// (research.md Decision 5).
  Future<db.FinanceCategory?> findActiveCategoryByNormalizedName({
    required String normalizedName,
    required FinanceEntryType type,
  }) {
    return (_db.select(_db.financeCategories)..where(
          (t) =>
              t.normalizedName.equals(normalizedName) &
              t.type.equals(type.dbValue) &
              t.isArchived.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<db.FinanceCategory> insertCategory(
    db.FinanceCategoriesCompanion companion,
  ) {
    return _db.transaction(() async {
      await _db.into(_db.financeCategories).insert(companion);
      return _recordCategoryUpsert(companion.id.value);
    });
  }

  Future<db.FinanceCategory> updateCategory(
    String id,
    db.FinanceCategoriesCompanion companion,
  ) {
    return _db.transaction(() async {
      await (_db.update(
        _db.financeCategories,
      )..where((t) => t.id.equals(id))).write(companion);
      return _recordCategoryUpsert(id);
    });
  }

  Future<void> archiveCategory(String id, DateTime updatedAt) {
    return _db.transaction(() async {
      final updated =
          await (_db.update(
            _db.financeCategories,
          )..where((t) => t.id.equals(id))).write(
            db.FinanceCategoriesCompanion(
              isArchived: const db.Value(true),
              updatedAt: db.Value(updatedAt.millisecondsSinceEpoch),
            ),
          );
      if (updated > 0) await _recordCategoryUpsert(id);
    });
  }

  /// Hard-deletes [id] locally and queues a cloud tombstone carrying the
  /// row's last snapshot (read first, in the same transaction).
  Future<void> deleteCategory(String id) {
    return _db.transaction(() async {
      final existing = await getCategoryById(id);
      if (existing == null) return;
      await (_db.delete(
        _db.financeCategories,
      )..where((t) => t.id.equals(id))).go();
      await _outbox.recordDelete(
        SyncEntityType.financeCategory,
        id,
        _categoryMapper.toWire(existing),
      );
    });
  }
}
