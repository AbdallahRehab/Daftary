import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/watch_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../../../currency/domain/entities/conversion_result.dart';
import '../../../currency/domain/services/currency_converter.dart';
import '../../../currency/domain/usecases/get_conversion_context.dart';
import '../../../finance/domain/entities/category.dart';
import '../../../finance/domain/entities/category_breakdown_item.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/repositories/category_repository.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category_allocation.dart';
import '../../domain/entities/budget_category_line.dart';
import '../../domain/entities/budget_failures.dart';
import '../../domain/entities/budget_month.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/entities/budget_trend_point.dart';
import '../../domain/repositories/budgets_repository.dart';
import '../datasources/budgets_dao.dart';
import '../models/budget_category_allocation_mapper.dart';
import '../models/budget_ids.dart';
import '../models/budget_mapper.dart';

/// Composes this feature's own tables with 007's `FinanceRepository` and
/// `CategoryRepository` interfaces (research.md Decision 1). Depends on
/// the interfaces, never on their `*Impl`s, and never reads 007's tables
/// directly — which is what FR-016's "no second spend-aggregation path"
/// comes down to in code.
///
/// 018: a budget is planned in one currency — the primary currency when it
/// was created — and 007's per-currency spend is converted into it here
/// through [CurrencyConverter]. Spend that needs a missing rate never fails
/// the month: it blocks exactly the figures that depend on it (018 FR-009 —
/// see `BudgetSummary` and `BudgetTrendPoint` for the rules).
///
/// 021: the `watch*` reads re-run their `get*` on every write to a table
/// the figures depend on ([_monthTables]), locally or through sync.
@LazySingleton(as: BudgetsRepository)
class BudgetsRepositoryImpl implements BudgetsRepository {
  BudgetsRepositoryImpl(
    this._dao,
    this._db,
    this._financeRepository,
    this._categoryRepository,
    this._getConversionContext,
    this._converter,
  );

  final BudgetsDao _dao;
  final db.AppDatabase _db;
  final FinanceRepository _financeRepository;
  final CategoryRepository _categoryRepository;
  final GetConversionContext _getConversionContext;
  final CurrencyConverter _converter;

  // ---------------------------------------------------------------- budgets

  @override
  Future<Either<Failure, Budget>> createBudget({
    required String idempotencyKey,
    required String month,
    int? expectedIncomeMinorUnits,
  }) async {
    final validation =
        _validateMonth(month) ?? _validateIncome(expectedIncomeMinorUnits);
    if (validation != null) return Left(validation);
    try {
      // Checked before the month clash: a retried save of a budget that was
      // just created *is* the month's budget, and must come back as the
      // success it originally was, not as "this month already has one".
      final retried = await _dao.getBudgetByIdempotencyKey(idempotencyKey);
      if (retried != null) return Right(retried.toDomain());

      final clash = await _monthClash(month);
      if (clash != null) return Left(clash);

      final contextResult = await _getConversionContext();
      if (contextResult.isLeft()) {
        return Left(contextResult.getLeft().toNullable()!);
      }
      final primary = contextResult.toNullable()!.primary;

      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final companion = db.BudgetsCompanion.insert(
        id: BudgetIds.budget(month),
        idempotencyKey: idempotencyKey,
        month: month,
        expectedIncomeMinorUnits: db.Value(expectedIncomeMinorUnits),
        currencyCode: db.Value(primary.code),
        createdAt: nowMillis,
        updatedAt: nowMillis,
      );
      return Right((await _insertBudget(companion, month)).toDomain());
    } on _MonthTaken catch (e) {
      return Left(e.failure);
    } catch (e) {
      return Left(CacheFailure('Failed to create budget: $e'));
    }
  }

  @override
  Future<Either<Failure, Budget>> editBudget({
    required String budgetId,
    int? expectedIncomeMinorUnits,
  }) async {
    final validation = _validateIncome(expectedIncomeMinorUnits);
    if (validation != null) return Left(validation);
    try {
      final existing = await _activeBudgetOrNull(budgetId);
      if (existing == null) {
        return const Left(BudgetNotFoundFailure('Budget not found'));
      }
      final updated = await _dao.updateBudget(
        budgetId,
        db.BudgetsCompanion(
          expectedIncomeMinorUnits: db.Value(expectedIncomeMinorUnits),
          updatedAt: db.Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      return Right(updated.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to edit budget: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteBudget(String budgetId) async {
    try {
      final existing = await _activeBudgetOrNull(budgetId);
      if (existing == null) {
        return const Left(BudgetNotFoundFailure('Budget not found'));
      }
      // Touches this feature's own row only: the expense entries that were
      // counted against the budget are 007's, and stay exactly as they were
      // (FR-011/FR-022).
      await _dao.softDeleteBudget(budgetId, DateTime.now());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to delete budget: $e'));
    }
  }

  @override
  Future<Either<Failure, Budget>> copyBudgetToMonth({
    required String idempotencyKey,
    required String sourceBudgetId,
    required String targetMonth,
  }) async {
    final validation = _validateMonth(targetMonth);
    if (validation != null) return Left(validation);
    try {
      final retried = await _dao.getBudgetByIdempotencyKey(idempotencyKey);
      if (retried != null) return Right(retried.toDomain());

      final source = await _activeBudgetOrNull(sourceBudgetId);
      if (source == null) {
        return const Left(BudgetNotFoundFailure('Source budget not found'));
      }
      final clash = await _monthClash(targetMonth);
      if (clash != null) return Left(clash);

      final sourceAllocations = await _dao.getAllocationsForBudget(source.id);
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final newBudgetId = BudgetIds.budget(targetMonth);

      // One transaction: a copy that wrote the budget and then failed half
      // way through its allocations would leave a month that looks
      // budgeted but silently plans less than the source did.
      final created = await _dao.transaction(() async {
        final budget = await _insertBudget(
          db.BudgetsCompanion.insert(
            id: newBudgetId,
            idempotencyKey: idempotencyKey,
            month: targetMonth,
            expectedIncomeMinorUnits: db.Value(source.expectedIncomeMinorUnits),
            // The copy plans the same figures, so in the same currency.
            currencyCode: db.Value(source.currencyCode),
            createdAt: nowMillis,
            updatedAt: nowMillis,
          ),
          targetMonth,
        );
        for (final allocation in sourceAllocations) {
          // Fresh ids: the copy shares no row — and so no ongoing link —
          // with the source (FR-012). The keys are derived rather than
          // random so they stay unique yet traceable to this copy action.
          await _dao.insertAllocationIdempotent(
            db.BudgetCategoryAllocationsCompanion.insert(
              id: BudgetIds.allocation(newBudgetId, allocation.categoryId),
              idempotencyKey: '$idempotencyKey:${allocation.id}',
              budgetId: newBudgetId,
              categoryId: allocation.categoryId,
              plannedAmountMinorUnits: allocation.plannedAmountMinorUnits,
              createdAt: nowMillis,
              updatedAt: nowMillis,
            ),
          );
        }
        return budget;
      });
      return Right(created.toDomain());
    } on _MonthTaken catch (e) {
      return Left(e.failure);
    } catch (e) {
      return Left(CacheFailure('Failed to copy budget: $e'));
    }
  }

  // ------------------------------------------------------------ allocations

  @override
  Future<Either<Failure, BudgetCategoryAllocation>>
  addBudgetCategoryAllocation({
    required String idempotencyKey,
    required String budgetId,
    required String categoryId,
    required int plannedAmountMinorUnits,
  }) async {
    final amountValidation = _validatePlannedAmount(plannedAmountMinorUnits);
    if (amountValidation != null) return Left(amountValidation);
    try {
      final retried = await _dao.getAllocationByIdempotencyKey(idempotencyKey);
      if (retried != null) {
        return Right(retried.toDomain(await _currencyOf(retried.budgetId)));
      }

      final budget = await _activeBudgetOrNull(budgetId);
      if (budget == null) {
        return const Left(BudgetNotFoundFailure('Budget not found'));
      }

      final categoryResult = await _categoryRepository.getCategoryById(
        categoryId,
      );
      if (categoryResult.isLeft()) {
        return Left(categoryResult.getLeft().toNullable()!);
      }
      final categoryFailure = _validateAllocatableCategory(
        categoryResult.toNullable()!,
      );
      if (categoryFailure != null) return Left(categoryFailure);

      final duplicate = await _dao.getAllocationForCategory(
        budgetId: budgetId,
        categoryId: categoryId,
      );
      if (duplicate != null) {
        return Left(_duplicateAllocation(duplicate, _currencyOfRow(budget)));
      }

      final now = DateTime.now();
      final row = await _dao.transaction(() async {
        final inserted = await _dao.insertAllocationIdempotent(
          db.BudgetCategoryAllocationsCompanion.insert(
            id: BudgetIds.allocation(budgetId, categoryId),
            idempotencyKey: idempotencyKey,
            budgetId: budgetId,
            categoryId: categoryId,
            plannedAmountMinorUnits: plannedAmountMinorUnits,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ),
        );
        await _dao.touchBudget(budgetId, now);
        return inserted;
      });
      return Right(row.toDomain(_currencyOfRow(budget)));
    } catch (e) {
      // The pre-check above makes this reachable only by a concurrent
      // insert slipping between check and write; the unique index still
      // refuses it, and this turns that refusal into the same typed answer.
      final raced = await _dao
          .getAllocationForCategory(budgetId: budgetId, categoryId: categoryId)
          .catchError((_) => null);
      if (raced != null) {
        return Left(_duplicateAllocation(raced, await _currencyOf(budgetId)));
      }
      return Left(CacheFailure('Failed to add allocation: $e'));
    }
  }

  @override
  Future<Either<Failure, BudgetCategoryAllocation>>
  editBudgetCategoryAllocation({
    required String allocationId,
    required int plannedAmountMinorUnits,
  }) async {
    final validation = _validatePlannedAmount(plannedAmountMinorUnits);
    if (validation != null) return Left(validation);
    try {
      final existing = await _dao.getAllocationById(allocationId);
      if (existing == null) {
        return const Left(
          BudgetAllocationNotFoundFailure('Budget allocation not found'),
        );
      }
      final budget = await _activeBudgetOrNull(existing.budgetId);
      if (budget == null) {
        return const Left(BudgetNotFoundFailure('Budget not found'));
      }
      final now = DateTime.now();
      final updated = await _dao.transaction(() async {
        final row = await _dao.updateAllocationAmount(
          allocationId,
          plannedAmountMinorUnits: plannedAmountMinorUnits,
          updatedAt: now,
        );
        await _dao.touchBudget(existing.budgetId, now);
        return row;
      });
      return Right(updated.toDomain(_currencyOfRow(budget)));
    } catch (e) {
      return Left(CacheFailure('Failed to edit allocation: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeBudgetCategoryAllocation(
    String allocationId,
  ) async {
    try {
      final existing = await _dao.getAllocationById(allocationId);
      if (existing == null) {
        return const Left(
          BudgetAllocationNotFoundFailure('Budget allocation not found'),
        );
      }
      if (await _activeBudgetOrNull(existing.budgetId) == null) {
        return const Left(BudgetNotFoundFailure('Budget not found'));
      }
      await _dao.transaction(() async {
        await _dao.deleteAllocation(allocationId);
        await _dao.touchBudget(existing.budgetId, DateTime.now());
      });
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to remove allocation: $e'));
    }
  }

  // ------------------------------------------------------------------ reads

  @override
  Future<Either<Failure, BudgetMonthDetail>> getBudgetForMonth(
    String month,
  ) async {
    final validation = _validateMonth(month);
    if (validation != null) return Left(validation);
    try {
      final budgetRow = await _dao.getActiveBudgetForMonth(month);
      if (budgetRow == null) return Right(BudgetMonthDetail.empty(month));

      // No cache anywhere on this path (T031): both 007 reads below run
      // against the live tables on every call, so an expense added, edited
      // or deleted a moment ago is already reflected.
      final currency = _currencyOfRow(budgetRow);
      final spendResult = await _monthSpendByCategory(month, currency);
      if (spendResult.isLeft()) {
        return Left(spendResult.getLeft().toNullable()!);
      }
      final spend = spendResult.toNullable()!;

      final categoriesResult = await _categoryRepository.getCategories(
        type: CategoryType.expense,
        // Archived categories must still resolve for the allocations that
        // already reference them (FR-021).
        includeArchived: true,
      );
      if (categoriesResult.isLeft()) {
        return Left(categoriesResult.getLeft().toNullable()!);
      }
      final categoriesById = {
        for (final category in categoriesResult.toNullable()!)
          category.id: category,
      };

      final allocations = await _dao.getAllocationsForBudget(budgetRow.id);
      final allocatedIds = {for (final a in allocations) a.categoryId};

      final lines = [
        for (final allocation in allocations)
          _toLine(
            allocation,
            categoriesById[allocation.categoryId],
            spend[allocation.categoryId],
            currency,
          ),
      ];
      final unbudgeted = [
        // Largest first, as 007 orders its breakdown; blocked ones last.
        for (final item in spend.values)
          // A blocked item always has real spend behind it — it is listed
          // with its amount unknown rather than dropped (FR-007).
          if (!allocatedIds.contains(item.categoryId) &&
              (item.amount?.isPositive ?? true))
            UnbudgetedCategorySpend(
              categoryId: item.categoryId,
              categoryName: item.categoryName,
              categoryIcon: item.icon,
              amountMinorUnits: item.amount?.minorUnits,
              currency: currency,
              missingRatesFor: item.missingRatesFor,
            ),
      ];

      return Right(
        BudgetMonthDetail(
          month: month,
          budget: budgetRow.toDomain(),
          summary: BudgetSummary(
            budgetId: budgetRow.id,
            categoryBreakdown: lines,
            unbudgetedSpending: unbudgeted,
            currency: currency,
          ),
        ),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to load budget: $e'));
    }
  }

  @override
  Stream<Either<Failure, BudgetMonthDetail>> watchBudgetForMonth(
    String month,
  ) => _db.watchEither(_monthTables, () => getBudgetForMonth(month));

  @override
  Future<Either<Failure, Budget?>> getMostRecentBudgetBefore(
    String month,
  ) async {
    final validation = _validateMonth(month);
    if (validation != null) return Left(validation);
    try {
      final row = await _dao.getMostRecentActiveBudgetBefore(month);
      return Right(row?.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to load previous budget: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BudgetTrendPoint>>> getBudgetTrend({
    String? categoryId,
    int monthsBack = 6,
    String? endMonth,
  }) async {
    if (monthsBack < 1) {
      return const Left(ValidationFailure('monthsBack must be at least 1'));
    }
    final lastMonth = endMonth ?? BudgetMonth.current();
    final validation = _validateMonth(lastMonth);
    if (validation != null) return Left(validation);
    try {
      final contextResult = await _getConversionContext();
      if (contextResult.isLeft()) {
        return Left(contextResult.getLeft().toNullable()!);
      }
      final context = contextResult.toNullable()!;
      final months = [
        for (var offset = monthsBack - 1; offset >= 0; offset--)
          BudgetMonth.shift(lastMonth, -offset),
      ];
      final budgets = await _dao.getActiveBudgetsBetween(
        months.first,
        months.last,
      );
      final budgetByMonth = {for (final b in budgets) b.month: b};
      final allocations = await _dao.getAllocationsForBudgets(
        budgets.map((b) => b.id),
      );
      final allocationsByBudget = <String, List<db.BudgetCategoryAllocation>>{};
      for (final allocation in allocations) {
        (allocationsByBudget[allocation.budgetId] ??= []).add(allocation);
      }

      // The trend compares months that may have been planned in different
      // currencies, so every figure is shown in the primary currency (018).
      final primary = context.primary;
      final points = <BudgetTrendPoint>[];
      for (final month in months) {
        final spendResult = await _monthSpendByCategory(
          month,
          primary,
          context: context,
        );
        if (spendResult.isLeft()) {
          return Left(spendResult.getLeft().toNullable()!);
        }
        final spend = spendResult.toNullable()!;
        final budget = budgetByMonth[month];
        final planned = <String, _Converted>{
          if (budget != null)
            for (final allocation
                in allocationsByBudget[budget.id] ??
                    const <db.BudgetCategoryAllocation>[])
              allocation.categoryId: _Converted.of(
                _convert(
                  Money.fromMinorUnits(
                    allocation.plannedAmountMinorUnits,
                    _currencyOfRow(budget),
                  ),
                  context,
                ),
              ),
        };
        points.add(
          categoryId == null
              ? _overallPoint(month, budget != null, planned, spend, primary)
              : _categoryPoint(
                  month,
                  budget != null,
                  categoryId,
                  planned,
                  spend,
                  primary,
                ),
        );
      }
      return Right(points);
    } catch (e) {
      return Left(CacheFailure('Failed to load budget trend: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<BudgetTrendPoint>>> watchBudgetTrend({
    String? categoryId,
    int monthsBack = 6,
    String? endMonth,
  }) => _db.watchEither(
    _monthTables,
    () => getBudgetTrend(
      categoryId: categoryId,
      monthsBack: monthsBack,
      endMonth: endMonth,
    ),
  );

  // --------------------------------------------------------------- helpers

  /// 021: every table a month's figures are read from — this feature's own
  /// two, 007's entries and categories (read through its repositories, but
  /// still what the figures depend on), and 018's rates and primary
  /// currency, since spend is converted. A write to any of them, local or
  /// applied by sync, re-reads the open budget screens (FR-031).
  Set<db.TableInfo<db.Table, Object?>> get _monthTables => {
    _db.budgets,
    _db.budgetCategoryAllocations,
    _db.financeEntries,
    _db.financeCategories,
    _db.exchangeRates,
    _db.primaryCurrencySettings,
  };

  /// For a budgeted month, "actual" is the budgeted categories' spend —
  /// exactly `BudgetSummary.totalActualMinorUnits`, so the trend bar and
  /// the month screen show the same number. For a month with no budget
  /// there are no budgeted categories, so the month's whole expense total
  /// is shown instead: the only meaningful "spending with no plan" figure
  /// (data-model.md BudgetTrendPoint).
  ///
  /// 018: either total is unknown (`null`) if any figure it sums is.
  BudgetTrendPoint _overallPoint(
    String month,
    bool hasBudget,
    Map<String, _Converted> plannedByCategory,
    Map<String, _CategorySpend> spend,
    Currency currency,
  ) {
    final planned = _Converted.sum(plannedByCategory.values);
    final actual = _Converted.sum(
      hasBudget
          ? [
              for (final id in plannedByCategory.keys)
                if (spend[id] case final item?) item.converted,
            ]
          : [for (final item in spend.values) item.converted],
    );
    return BudgetTrendPoint(
      month: month,
      plannedMinorUnits: planned.minorUnits,
      actualMinorUnits: actual.minorUnits,
      hasBudget: hasBudget,
      currency: currency,
      missingRatesFor: unionOfMissingRates([
        planned.missingRatesFor,
        actual.missingRatesFor,
      ]),
    );
  }

  BudgetTrendPoint _categoryPoint(
    String month,
    bool hasBudget,
    String categoryId,
    Map<String, _Converted> plannedByCategory,
    Map<String, _CategorySpend> spend,
    Currency currency,
  ) {
    final planned = plannedByCategory[categoryId] ?? _Converted.zero;
    final actual = spend[categoryId]?.converted ?? _Converted.zero;
    return BudgetTrendPoint(
      month: month,
      plannedMinorUnits: planned.minorUnits,
      actualMinorUnits: actual.minorUnits,
      hasBudget: hasBudget,
      currency: currency,
      missingRatesFor: unionOfMissingRates([
        planned.missingRatesFor,
        actual.missingRatesFor,
      ]),
    );
  }

  /// [month]'s expense spend per category, from 007's per-currency
  /// `getCategoryTotals` (research.md Decision 2's zero-change default) —
  /// one SQL aggregate for the whole month rather than a query per
  /// budgeted category — converted into [currency] (018). Keyed by category
  /// id, largest first.
  ///
  /// A category whose spend needs a missing rate is kept with an unknown
  /// amount and the currencies it needs (sorted last), rather than failing
  /// the month: only the figures that depend on it are blocked (018
  /// FR-009), never a partial actual.
  Future<Either<Failure, Map<String, _CategorySpend>>> _monthSpendByCategory(
    String month,
    Currency currency, {
    ConversionContext? context,
  }) async {
    final ConversionContext rates;
    if (context != null) {
      rates = context;
    } else {
      final contextResult = await _getConversionContext();
      if (contextResult.isLeft()) {
        return Left(contextResult.getLeft().toNullable()!);
      }
      rates = contextResult.toNullable()!;
    }
    final result = await _financeRepository.getCategoryTotals(
      BudgetMonth.toDateRange(month),
      type: FinanceEntryType.expense,
    );
    return result.map((rows) {
      final spend = [
        for (final row in rows)
          _CategorySpend(row, switch (_converter.sumToTargetCurrency(
            amounts: row.totals,
            targetCurrency: currency,
            rates: rates.rates,
          )) {
            SumTotal(:final value) => _Converted(value.minorUnits),
            SumBlocked(:final missingRatesFor) => _Converted.blocked(
              missingRatesFor,
            ),
          }, currency),
      ];
      // Stable: equal totals keep 007's order, and blocked rows sort after
      // every known one.
      final ordered = spend.indexed.toList()
        ..sort((a, b) {
          final aTotal = a.$2.converted.minorUnits;
          final bTotal = b.$2.converted.minorUnits;
          if (aTotal != null && bTotal != null && aTotal != bTotal) {
            return bTotal.compareTo(aTotal);
          }
          if (aTotal == null && bTotal != null) return 1;
          if (aTotal != null && bTotal == null) return -1;
          return a.$1.compareTo(b.$1);
        });
      return {for (final (_, item) in ordered) item.categoryId: item};
    });
  }

  ConversionResult _convert(Money amount, ConversionContext context) =>
      _converter.convert(
        amount: amount,
        targetCurrency: context.primary,
        rates: context.rates,
      );

  Currency _currencyOfRow(db.Budget budget) =>
      Currency.fromCode(budget.currencyCode);

  /// The currency of [budgetId]'s budget, deleted or not; EGP if the row is
  /// gone, which only an allocation orphaned by a hard wipe could hit.
  Future<Currency> _currencyOf(String budgetId) async {
    final row = await _dao.getBudgetById(budgetId);
    return row == null ? Currency.egp : _currencyOfRow(row);
  }

  BudgetCategoryLine _toLine(
    db.BudgetCategoryAllocation allocation,
    Category? category,
    _CategorySpend? spend,
    Currency currency,
  ) {
    return BudgetCategoryLine(
      allocationId: allocation.id,
      categoryId: allocation.categoryId,
      categoryName: category?.name ?? '',
      categoryIcon: category?.icon ?? '',
      isCategoryArchived: category?.isArchived ?? false,
      isCategoryMissing: category == null,
      plannedAmountMinorUnits: allocation.plannedAmountMinorUnits,
      // No spend row at all means nothing was spent: a known zero.
      actualAmountMinorUnits: spend == null ? 0 : spend.amount?.minorUnits,
      missingRatesFor: spend?.missingRatesFor ?? const [],
      currency: currency,
    );
  }

  /// Inserts a budget row, translating a refusal by the partial `month`
  /// unique index into [_MonthTaken] so both callers — and a copy running
  /// inside a transaction, which must roll back — see the typed failure.
  ///
  /// 022: a month's budget has a derived id, so budgeting a month again after
  /// deleting its budget revives that row (starting empty) rather than
  /// inserting a second one under the same id.
  Future<db.Budget> _insertBudget(
    db.BudgetsCompanion companion,
    String month,
  ) async {
    final retried = await _dao.getBudgetByIdempotencyKey(
      companion.idempotencyKey.value,
    );
    if (retried != null) return retried;
    final previous = await _dao.getBudgetById(companion.id.value);
    if (previous != null && previous.deletedAt != null) {
      return _dao.reviveBudget(
        previous.id,
        companion.copyWith(deletedAt: const db.Value(null)),
      );
    }
    try {
      return await _dao.insertBudgetIdempotent(companion);
    } catch (_) {
      final clash = await _monthClash(month);
      if (clash != null) throw _MonthTaken(clash);
      rethrow;
    }
  }

  Future<BudgetAlreadyExistsForMonthFailure?> _monthClash(String month) async {
    final existing = await _dao.getActiveBudgetForMonth(month);
    if (existing == null) return null;
    return BudgetAlreadyExistsForMonthFailure(
      'A budget already exists for $month',
      existing: existing.toDomain(),
    );
  }

  Future<db.Budget?> _activeBudgetOrNull(String budgetId) async {
    final row = await _dao.getBudgetById(budgetId);
    if (row == null || row.deletedAt != null) return null;
    return row;
  }

  DuplicateBudgetAllocationFailure _duplicateAllocation(
    db.BudgetCategoryAllocation existing,
    Currency currency,
  ) => DuplicateBudgetAllocationFailure(
    'This category is already in the budget',
    existing: existing.toDomain(currency),
  );

  ValidationFailure? _validateMonth(String month) => BudgetMonth.isValid(month)
      ? null
      : ValidationFailure('Invalid budget month: $month');

  ValidationFailure? _validateIncome(int? expectedIncomeMinorUnits) =>
      expectedIncomeMinorUnits != null && expectedIncomeMinorUnits < 0
      ? const ValidationFailure('Expected income cannot be negative')
      : null;

  /// FR-002: zero is a valid plan; only a negative amount is refused.
  ValidationFailure? _validatePlannedAmount(int plannedAmountMinorUnits) =>
      plannedAmountMinorUnits < 0
      ? const ValidationFailure('Planned amount cannot be negative')
      : null;

  /// Budgets plan spending, so only expense categories qualify (spec
  /// Assumptions); an archived one is refused for a *new* allocation the
  /// same way 007's picker hides it (FR-021), while allocations made before
  /// it was archived keep working.
  ValidationFailure? _validateAllocatableCategory(Category category) {
    if (category.type != CategoryType.expense) {
      return const ValidationFailure('Only expense categories can be budgeted');
    }
    if (category.isArchived) {
      return const ValidationFailure(
        'An archived category cannot be added to a budget',
      );
    }
    return null;
  }
}

/// Carries a [BudgetAlreadyExistsForMonthFailure] out of an insert — and,
/// for a copy, out of the enclosing `_dao.transaction` so the whole copy
/// rolls back rather than leaving a half-written budget.
class _MonthTaken implements Exception {
  const _MonthTaken(this.failure);

  final BudgetAlreadyExistsForMonthFailure failure;
}

/// One category's expense spend for a month, converted into the requested
/// currency (018) — or blocked, when that needs a missing rate.
class _CategorySpend {
  _CategorySpend(CategoryCurrencyTotals row, this.converted, this._currency)
    : categoryId = row.categoryId,
      categoryName = row.categoryName,
      icon = row.icon;

  final String categoryId;
  final String categoryName;
  final String icon;
  final _Converted converted;
  final Currency _currency;

  /// `null` when blocked.
  Money? get amount => switch (converted.minorUnits) {
    final minorUnits? => Money.fromMinorUnits(minorUnits, _currency),
    null => null,
  };

  List<Currency> get missingRatesFor => converted.missingRatesFor;
}

/// One converted figure in exact minor units, or — when converting it
/// needs a missing rate — `null` with the currencies it needs (018
/// FR-009).
class _Converted {
  const _Converted(int this.minorUnits) : missingRatesFor = const [];

  const _Converted.blocked(this.missingRatesFor) : minorUnits = null;

  factory _Converted.of(ConversionResult result) => switch (result) {
    ConversionConverted(:final value) => _Converted(value.minorUnits),
    ConversionRateUnavailable(:final missingRateFor) => _Converted.blocked([
      missingRateFor,
    ]),
  };

  static const zero = _Converted(0);

  /// The exact sum of [figures], or blocked — naming every currency any of
  /// them needs — if any one is: never a partial sum.
  static _Converted sum(Iterable<_Converted> figures) {
    final missing = unionOfMissingRates([
      for (final figure in figures) figure.missingRatesFor,
    ]);
    if (missing.isNotEmpty || figures.any((f) => f.minorUnits == null)) {
      return _Converted.blocked(missing);
    }
    return _Converted(
      figures.fold<int>(0, (sum, figure) => sum + figure.minorUnits!),
    );
  }

  final int? minorUnits;
  final List<Currency> missingRatesFor;
}
