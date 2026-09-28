import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/sync/local/sync_outbox.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../sync/budget_sync_mapper.dart';

/// Direct `drift` access to `budgets` and `budget_category_allocations`.
///
/// Deliberately never touches `finance_entries` or `finance_categories`:
/// every actual-spend figure and every category lookup goes through 007's
/// `FinanceRepository`/`CategoryRepository` instead (FR-016, research.md
/// Decision 1), so there is exactly one spend-aggregation path in the app.
///
/// 022: every write records its change to the [SyncOutbox] in the same
/// transaction — an upsert for budgets (soft-deleted, so a tombstone is an
/// upsert too) and a delete op for a hard-deleted allocation.
@injectable
class BudgetsDao {
  BudgetsDao(
    this._db,
    this._outbox,
    this._budgetMapper,
    this._allocationMapper,
  );

  final db.AppDatabase _db;
  final SyncOutbox _outbox;
  final BudgetSyncMapper _budgetMapper;
  final BudgetAllocationSyncMapper _allocationMapper;

  Future<db.Budget> _recordBudget(String id) async {
    final row = (await getBudgetById(id))!;
    await _outbox.recordUpsert(
      SyncEntityType.budget,
      id,
      _budgetMapper.toWire(row),
    );
    return row;
  }

  Future<db.BudgetCategoryAllocation> _recordAllocation(String id) async {
    final row = (await getAllocationById(id))!;
    await _outbox.recordUpsert(
      SyncEntityType.budgetAllocation,
      id,
      _allocationMapper.toWire(row),
    );
    return row;
  }

  /// Runs [action] in one DB transaction — what keeps a copy-forward from
  /// leaving a budget behind without its allocations.
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---------------------------------------------------------------- budgets

  /// Inserts [companion]; if a row with the same `idempotency_key` already
  /// exists (unique index — FR-017), the unique-constraint violation is
  /// swallowed and the already-persisted row is returned instead. Any other
  /// violation — in practice the partial `month` index, i.e. a second
  /// active budget for the month — is rethrown for the repository to
  /// translate. Mirrors `OccasionsDao.insertOccasionIdempotent`.
  Future<db.Budget> insertBudgetIdempotent(db.BudgetsCompanion companion) {
    final idempotencyKey = companion.idempotencyKey.value;
    return _db.transaction(() async {
      final existing = await getBudgetByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      await _db.into(_db.budgets).insert(companion);
      final inserted = (await getBudgetByIdempotencyKey(idempotencyKey))!;
      return _recordBudget(inserted.id);
    });
  }

  /// Brings the soft-deleted budget [id] back as [companion] describes it —
  /// how a month is budgeted again under its derived id (`BudgetIds`). The
  /// old plan's allocations are removed first (and their removal queued),
  /// so the revived budget starts empty, exactly like a new one.
  Future<db.Budget> reviveBudget(String id, db.BudgetsCompanion companion) {
    return _db.transaction(() async {
      for (final allocation in await getAllocationsForBudget(id)) {
        await deleteAllocation(allocation.id);
      }
      await (_db.update(
        _db.budgets,
      )..where((b) => b.id.equals(id))).write(companion);
      return _recordBudget(id);
    });
  }

  Future<db.Budget?> getBudgetByIdempotencyKey(String key) => (_db.select(
    _db.budgets,
  )..where((b) => b.idempotencyKey.equals(key))).getSingleOrNull();

  /// Includes soft-deleted rows — the repository decides what a tombstoned
  /// budget means for each caller.
  Future<db.Budget?> getBudgetById(String id) => (_db.select(
    _db.budgets,
  )..where((b) => b.id.equals(id))).getSingleOrNull();

  /// The active budget for [month], if any. The partial unique index
  /// guarantees there is at most one.
  Future<db.Budget?> getActiveBudgetForMonth(String month) =>
      (_db.select(_db.budgets)
            ..where((b) => b.month.equals(month) & b.deletedAt.isNull()))
          .getSingleOrNull();

  /// The latest active budget whose month sorts strictly before [month].
  /// `'YYYY-MM'` keys order lexicographically exactly as they do
  /// chronologically, so a plain text comparison is correct here.
  Future<db.Budget?> getMostRecentActiveBudgetBefore(String month) =>
      (_db.select(_db.budgets)
            ..where(
              (b) => b.month.isSmallerThanValue(month) & b.deletedAt.isNull(),
            )
            ..orderBy([
              (b) => db.OrderingTerm(
                expression: b.month,
                mode: db.OrderingMode.desc,
              ),
            ])
            ..limit(1))
          .getSingleOrNull();

  /// Active budgets with `fromMonth <= month <= toMonth`, oldest first.
  Future<List<db.Budget>> getActiveBudgetsBetween(
    String fromMonth,
    String toMonth,
  ) {
    return (_db.select(_db.budgets)
          ..where(
            (b) =>
                b.month.isBiggerOrEqualValue(fromMonth) &
                b.month.isSmallerOrEqualValue(toMonth) &
                b.deletedAt.isNull(),
          )
          ..orderBy([(b) => db.OrderingTerm(expression: b.month)]))
        .get();
  }

  Future<db.Budget> updateBudget(String id, db.BudgetsCompanion companion) {
    return _db.transaction(() async {
      await (_db.update(
        _db.budgets,
      )..where((b) => b.id.equals(id))).write(companion);
      return _recordBudget(id);
    });
  }

  /// Bumps `updated_at` — every allocation change is an edit of the budget
  /// it belongs to (data-model.md).
  Future<void> touchBudget(String id, DateTime updatedAt) {
    return _db.transaction(() async {
      await (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
        db.BudgetsCompanion(
          updatedAt: db.Value(updatedAt.millisecondsSinceEpoch),
        ),
      );
      await _recordBudget(id);
    });
  }

  /// Tombstones the budget only. Its allocations are left in place: they
  /// are unreachable through an inactive budget, and keeping them costs
  /// nothing while leaving the row set intact should a restore ever be
  /// specified.
  Future<void> softDeleteBudget(String id, DateTime deletedAt) {
    return _db.transaction(() async {
      await (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
        db.BudgetsCompanion(
          deletedAt: db.Value(deletedAt.millisecondsSinceEpoch),
          updatedAt: db.Value(deletedAt.millisecondsSinceEpoch),
        ),
      );
      await _recordBudget(id);
    });
  }

  // ------------------------------------------------------------ allocations

  /// Same idempotent-insert shape as [insertBudgetIdempotent]: a retried
  /// key returns the existing row; any other constraint violation — the
  /// `(budget_id, category_id)` duplicate guard — is rethrown.
  Future<db.BudgetCategoryAllocation> insertAllocationIdempotent(
    db.BudgetCategoryAllocationsCompanion companion,
  ) {
    final idempotencyKey = companion.idempotencyKey.value;
    return _db.transaction(() async {
      final existing = await getAllocationByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      await _db.into(_db.budgetCategoryAllocations).insert(companion);
      final inserted = (await getAllocationByIdempotencyKey(idempotencyKey))!;
      return _recordAllocation(inserted.id);
    });
  }

  Future<db.BudgetCategoryAllocation?> getAllocationByIdempotencyKey(
    String key,
  ) => (_db.select(
    _db.budgetCategoryAllocations,
  )..where((a) => a.idempotencyKey.equals(key))).getSingleOrNull();

  Future<db.BudgetCategoryAllocation?> getAllocationById(String id) =>
      (_db.select(
        _db.budgetCategoryAllocations,
      )..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<db.BudgetCategoryAllocation?> getAllocationForCategory({
    required String budgetId,
    required String categoryId,
  }) =>
      (_db.select(_db.budgetCategoryAllocations)..where(
            (a) =>
                a.budgetId.equals(budgetId) & a.categoryId.equals(categoryId),
          ))
          .getSingleOrNull();

  /// Every allocation of [budgetId], largest planned amount first
  /// (`created_at` breaks ties so the order is stable across reads).
  Future<List<db.BudgetCategoryAllocation>> getAllocationsForBudget(
    String budgetId,
  ) {
    return (_db.select(_db.budgetCategoryAllocations)
          ..where((a) => a.budgetId.equals(budgetId))
          ..orderBy([
            (a) => db.OrderingTerm(
              expression: a.plannedAmountMinorUnits,
              mode: db.OrderingMode.desc,
            ),
            (a) => db.OrderingTerm(expression: a.createdAt),
          ]))
        .get();
  }

  /// Allocations of several budgets in one query — what the trend view
  /// reads instead of one query per month.
  Future<List<db.BudgetCategoryAllocation>> getAllocationsForBudgets(
    Iterable<String> budgetIds,
  ) {
    final ids = budgetIds.toList();
    if (ids.isEmpty) return Future.value(const []);
    return (_db.select(
      _db.budgetCategoryAllocations,
    )..where((a) => a.budgetId.isIn(ids))).get();
  }

  Future<db.BudgetCategoryAllocation> updateAllocationAmount(
    String id, {
    required int plannedAmountMinorUnits,
    required DateTime updatedAt,
  }) {
    return _db.transaction(() async {
      await (_db.update(
        _db.budgetCategoryAllocations,
      )..where((a) => a.id.equals(id))).write(
        db.BudgetCategoryAllocationsCompanion(
          plannedAmountMinorUnits: db.Value(plannedAmountMinorUnits),
          updatedAt: db.Value(updatedAt.millisecondsSinceEpoch),
        ),
      );
      return _recordAllocation(id);
    });
  }

  /// Hard delete (research.md Decision 5): plan data with no financial
  /// history of its own. Queued as a delete op carrying the final row.
  Future<void> deleteAllocation(String id) {
    return _db.transaction(() async {
      final row = await getAllocationById(id);
      if (row == null) return;
      await (_db.delete(
        _db.budgetCategoryAllocations,
      )..where((a) => a.id.equals(id))).go();
      await _outbox.recordDelete(
        SyncEntityType.budgetAllocation,
        id,
        _allocationMapper.toWire(row),
      );
    });
  }
}
