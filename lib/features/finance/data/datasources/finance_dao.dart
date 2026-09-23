import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_history_filter.dart';

/// One category's aggregate within a period, straight off the `GROUP BY`
/// — the category's display fields ride along from the join so the
/// repository needs no second lookup per row.
class CategoryTotalRow {
  const CategoryTotalRow({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.totalMinorUnits,
  });

  final String categoryId;
  final String categoryName;
  final String icon;
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
@injectable
class FinanceDao {
  FinanceDao(this._db);

  final db.AppDatabase _db;

  // ---------------------------------------------------------------- entries

  /// Inserts [companion]; if a row with the same `idempotency_key` already
  /// exists (unique index — FR-021), the unique-constraint violation is
  /// swallowed and the already-persisted row is returned instead of
  /// erroring. Mirrors `TransactionsDao.insertTransactionIdempotent`.
  Future<db.FinanceEntry> insertEntryIdempotent(
    db.FinanceEntriesCompanion companion,
  ) async {
    final idempotencyKey = companion.idempotencyKey.value;
    try {
      await _db.into(_db.financeEntries).insert(companion);
    } catch (_) {
      final existing = await getEntryByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      rethrow;
    }
    return (await getEntryByIdempotencyKey(idempotencyKey))!;
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
  ) async {
    await (_db.update(
      _db.financeEntries,
    )..where((t) => t.id.equals(id))).write(companion);
    return (await getEntryById(id))!;
  }

  Future<void> softDeleteEntry(String id, DateTime deletedAt) {
    return (_db.update(_db.financeEntries)..where((t) => t.id.equals(id)))
        .write(
          db.FinanceEntriesCompanion(
            deletedAt: db.Value(deletedAt.millisecondsSinceEpoch),
          ),
        );
  }

  /// Un-sets the soft-delete tombstone (research.md Decision 8's undo).
  Future<void> restoreEntry(String id) {
    return (_db.update(_db.financeEntries)..where((t) => t.id.equals(id)))
        .write(const db.FinanceEntriesCompanion(deletedAt: db.Value(null)));
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
        (t) =>
            db.OrderingTerm(expression: t.createdAt, mode: db.OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    return query.get();
  }

  /// `SUM(amount_minor_units) ... WHERE date BETWEEN ? AND ? AND deleted_at
  /// IS NULL GROUP BY type` — one round trip for both totals, keyed by
  /// `'income'`/`'expense'` (research.md Decision 6).
  Future<Map<String, int>> getSummaryTotals(DateRange period) async {
    final total = _db.financeEntries.amountMinorUnits.sum();
    final query = _db.selectOnly(_db.financeEntries)
      ..addColumns([_db.financeEntries.type, total])
      ..where(
        _db.financeEntries.deletedAt.isNull() &
            _db.financeEntries.date.isBetweenValues(
              period.startMillis,
              period.endMillis,
            ),
      )
      ..groupBy([_db.financeEntries.type]);

    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(_db.financeEntries.type)!: row.read(total) ?? 0,
    };
  }

  /// Per-category totals for [period], descending by amount (FR-015).
  /// Joined to `finance_categories` so an archived category's entries still
  /// resolve a name and icon — the breakdown must not drop them.
  Future<List<CategoryTotalRow>> getCategoryBreakdown(
    DateRange period, {
    FinanceEntryType? type,
  }) async {
    final total = _db.financeEntries.amountMinorUnits.sum();
    final query = _db.selectOnly(_db.financeEntries)
      ..addColumns([_db.financeEntries.categoryId, total]);

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
      ..groupBy([_db.financeEntries.categoryId])
      ..orderBy([db.OrderingTerm(expression: total, mode: db.OrderingMode.desc)]);

    final rows = await query.get();
    return [
      for (final row in rows)
        CategoryTotalRow(
          categoryId: row.read(_db.financeEntries.categoryId)!,
          categoryName: row.read(_db.financeCategories.name)!,
          icon: row.read(_db.financeCategories.icon)!,
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
  ) async {
    await _db.into(_db.financeCategories).insert(companion);
    return (await getCategoryById(companion.id.value))!;
  }

  Future<db.FinanceCategory> updateCategory(
    String id,
    db.FinanceCategoriesCompanion companion,
  ) async {
    await (_db.update(
      _db.financeCategories,
    )..where((t) => t.id.equals(id))).write(companion);
    return (await getCategoryById(id))!;
  }

  Future<void> archiveCategory(String id, DateTime updatedAt) {
    return (_db.update(_db.financeCategories)..where((t) => t.id.equals(id)))
        .write(
          db.FinanceCategoriesCompanion(
            isArchived: const db.Value(true),
            updatedAt: db.Value(updatedAt.millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> deleteCategory(String id) {
    return (_db.delete(
      _db.financeCategories,
    )..where((t) => t.id.equals(id))).go();
  }
}
