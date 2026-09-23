// `hide isNull, isNotNull`: drift re-exports column helpers of those names,
// which would otherwise shadow the matchers this file uses.
import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget_failures.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/add_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/delete_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/edit_finance_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/budgets_harness.dart';

/// T016/T029 — `BudgetsRepositoryImpl` against an in-memory database, with
/// the real 007 `FinanceRepository`/`CategoryRepository` behind it.
void main() {
  late BudgetsHarness h;

  setUp(() async => h = await BudgetsHarness.open());
  tearDown(() => h.close());

  group('schema-level guards (T016)', () {
    test('the month index refuses a second active budget even when the '
        'repository pre-check is bypassed', () async {
      await h.createBudget('2026-03');

      await expectLater(
        h.db
            .into(h.db.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: 'raw',
                idempotencyKey: 'raw-key',
                month: '2026-03',
                createdAt: 1,
                updatedAt: 1,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('the month index is partial: a deleted budget does not hold its '
        'month', () async {
      final first = await h.createBudget('2026-03');
      await h.repository.deleteBudget(first.id);
      await h.createBudget('2026-03');

      final rows = await h.db.select(h.db.budgets).get();
      expect(rows, hasLength(2));
      expect(rows.where((r) => r.deletedAt == null), hasLength(1));
    });

    test('the (budget, category) index refuses a duplicate allocation even '
        'when the repository pre-check is bypassed', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 100);

      await expectLater(
        h.db
            .into(h.db.budgetCategoryAllocations)
            .insert(
              BudgetCategoryAllocationsCompanion.insert(
                id: 'raw',
                idempotencyKey: 'raw-key',
                budgetId: budget.id,
                categoryId: groceries,
                plannedAmountMinorUnits: 1,
                createdAt: 1,
                updatedAt: 1,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('a rapid double create with one key writes exactly one row', () async {
      final results = await Future.wait([
        h.repository.createBudget(idempotencyKey: 'same', month: '2026-03'),
        h.repository.createBudget(idempotencyKey: 'same', month: '2026-03'),
      ]);

      expect(results.every((r) => r.isRight()), isTrue);
      expect(results[0].toNullable()!.id, results[1].toNullable()!.id);
      expect(await h.db.select(h.db.budgets).get(), hasLength(1));
    });

    test('a rapid double add with one key writes exactly one row', () async {
      final budget = await h.createBudget('2026-03');
      final results = await Future.wait([
        for (var i = 0; i < 2; i++)
          h.repository.addBudgetCategoryAllocation(
            idempotencyKey: 'same',
            budgetId: budget.id,
            categoryId: groceries,
            plannedAmountMinorUnits: 100,
          ),
      ]);

      expect(results.every((r) => r.isRight()), isTrue);
      expect(
        await h.db.select(h.db.budgetCategoryAllocations).get(),
        hasLength(1),
      );
    });
  });

  group('edits', () {
    test('editBudget sets and clears the expected income, bumping '
        'updatedAt', () async {
      final budget = await h.createBudget('2026-03', income: 100);

      final set = await h.repository.editBudget(
        budgetId: budget.id,
        expectedIncomeMinorUnits: 500,
      );
      expect(set.toNullable()!.expectedIncomeMinorUnits, 500);
      expect(set.toNullable()!.updatedAt.isBefore(budget.updatedAt), isFalse);

      final cleared = await h.repository.editBudget(budgetId: budget.id);
      expect(cleared.toNullable()!.expectedIncomeMinorUnits, isNull);

      final negative = await h.repository.editBudget(
        budgetId: budget.id,
        expectedIncomeMinorUnits: -5,
      );
      expect(negative.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('editBudgetCategoryAllocation changes the amount; zero is '
        'allowed, negative is not (FR-002/FR-010)', () async {
      final budget = await h.createBudget('2026-03');
      final allocation = await h.allocate(budget.id, groceries, 100);

      final zero = await h.repository.editBudgetCategoryAllocation(
        allocationId: allocation.id,
        plannedAmountMinorUnits: 0,
      );
      final negative = await h.repository.editBudgetCategoryAllocation(
        allocationId: allocation.id,
        plannedAmountMinorUnits: -1,
      );

      expect(zero.toNullable()!.plannedAmountMinorUnits, 0);
      expect(zero.toNullable()!.id, allocation.id);
      expect(negative.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('removing an allocation hard-deletes it; a second removal is '
        'BudgetAllocationNotFoundFailure', () async {
      final budget = await h.createBudget('2026-03');
      final allocation = await h.allocate(budget.id, groceries, 100);

      final first = await h.repository.removeBudgetCategoryAllocation(
        allocation.id,
      );
      final second = await h.repository.removeBudgetCategoryAllocation(
        allocation.id,
      );

      expect(first.isRight(), isTrue);
      expect(
        second.getLeft().toNullable(),
        isA<BudgetAllocationNotFoundFailure>(),
      );
      expect(await h.db.select(h.db.budgetCategoryAllocations).get(), isEmpty);
    });

    test('an edited or removed allocation of a deleted budget is refused as '
        'BudgetNotFoundFailure', () async {
      final budget = await h.createBudget('2026-03');
      final allocation = await h.allocate(budget.id, groceries, 100);
      await h.repository.deleteBudget(budget.id);

      final edit = await h.repository.editBudgetCategoryAllocation(
        allocationId: allocation.id,
        plannedAmountMinorUnits: 5,
      );
      final remove = await h.repository.removeBudgetCategoryAllocation(
        allocation.id,
      );

      expect(edit.getLeft().toNullable(), isA<BudgetNotFoundFailure>());
      expect(remove.getLeft().toNullable(), isA<BudgetNotFoundFailure>());
    });
  });

  group('deleteBudget (FR-011/FR-022)', () {
    test('soft-deletes the budget, leaves every 007 entry untouched, and '
        'the month reads as empty afterwards', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 100);
      await h.spend(groceries, 50, DateTime(2026, 3, 1));
      final entriesBefore = await h.db.select(h.db.financeEntries).get();
      final categoriesBefore = await h.db.select(h.db.financeCategories).get();

      final result = await h.repository.deleteBudget(budget.id);

      expect(result.isRight(), isTrue);
      final row = (await h.db.select(h.db.budgets).get()).single;
      expect(row.deletedAt, isNotNull);
      expect(await h.db.select(h.db.financeEntries).get(), entriesBefore);
      expect(await h.db.select(h.db.financeCategories).get(), categoriesBefore);
      final detail = (await h.repository.getBudgetForMonth(
        '2026-03',
      )).toNullable()!;
      expect(detail.hasBudget, isFalse);
    });

    test('deleting twice is BudgetNotFoundFailure', () async {
      final budget = await h.createBudget('2026-03');
      await h.repository.deleteBudget(budget.id);

      final again = await h.repository.deleteBudget(budget.id);

      expect(again.getLeft().toNullable(), isA<BudgetNotFoundFailure>());
    });
  });

  group('getMostRecentBudgetBefore', () {
    test('returns the latest active budget strictly before the month, '
        'across a year boundary', () async {
      await h.createBudget('2025-10');
      final dec = await h.createBudget('2025-12');
      await h.createBudget('2026-02'); // the month itself — excluded
      await h.createBudget('2026-05'); // later — excluded

      final result = await h.repository.getMostRecentBudgetBefore('2026-02');

      expect(result.toNullable(), dec);
    });

    test('skips deleted budgets and returns null when there is none', () async {
      final only = await h.createBudget('2026-01');
      await h.repository.deleteBudget(only.id);

      final result = await h.repository.getMostRecentBudgetBefore('2026-02');

      expect(result.isRight(), isTrue);
      expect(result.toNullable(), isNull);
    });
  });

  group('live recompute (T029)', () {
    test('actuals follow 007 entries being added, edited and deleted, with '
        'no stale cache in between', () async {
      final addEntry = AddFinanceEntry(h.finance);
      final editEntry = EditFinanceEntry(h.finance);
      final deleteEntry = DeleteFinanceEntry(h.finance);
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 1000);

      Future<(int, int)> read() async {
        final summary = (await h.repository.getBudgetForMonth(
          '2026-03',
        )).toNullable()!.summary!;
        return (
          summary.totalActualMinorUnits,
          summary.totalUnbudgetedMinorUnits,
        );
      }

      expect(await read(), (0, 0));

      final entry = (await addEntry(
        idempotencyKey: 'e1',
        categoryId: groceries,
        type: FinanceEntryType.expense,
        amountMinorUnits: 400,
        date: DateTime(2026, 3, 5),
      )).toNullable()!;
      expect(await read(), (400, 0));

      await editEntry(
        entryId: entry.id,
        categoryId: groceries,
        amountMinorUnits: 950,
        date: DateTime(2026, 3, 5),
      );
      expect(await read(), (950, 0));

      // Moved to an unbudgeted category: leaves the line, becomes
      // unbudgeted spending.
      await editEntry(
        entryId: entry.id,
        categoryId: fuel,
        amountMinorUnits: 950,
        date: DateTime(2026, 3, 5),
      );
      expect(await read(), (0, 950));

      // Moved out of the month entirely.
      await editEntry(
        entryId: entry.id,
        categoryId: groceries,
        amountMinorUnits: 950,
        date: DateTime(2026, 4, 1),
      );
      expect(await read(), (0, 0));

      await editEntry(
        entryId: entry.id,
        categoryId: groceries,
        amountMinorUnits: 950,
        date: DateTime(2026, 3, 31),
      );
      expect(await read(), (950, 0));

      await deleteEntry(entry.id);
      expect(await read(), (0, 0));
    });

    test('a category renamed in 007 shows its new name at once', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 1000);

      await h.categories.editCategory(
        categoryId: groceries,
        name: 'Supermarket',
        icon: 'cart',
      );
      final line = (await h.repository.getBudgetForMonth(
        '2026-03',
      )).toNullable()!.summary!.categoryBreakdown.single;

      expect(line.categoryName, 'Supermarket');
      expect(line.categoryIcon, 'cart');
    });

    test('an allocation whose category has since been hard-deleted in 007 '
        'still shows, flagged missing, so its plan is not silently '
        'dropped', () async {
      final custom = (await h.categories.createCategory(
        name: 'Gym',
        type: CategoryType.expense,
        icon: 'fitness',
      )).toNullable()!;
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, custom.id, 700);
      // No entries reference it, so 007 hard-deletes rather than archives.
      await h.categories.removeCategory(custom.id);

      final summary = (await h.repository.getBudgetForMonth(
        '2026-03',
      )).toNullable()!.summary!;

      final line = summary.categoryBreakdown.single;
      expect(line.isCategoryMissing, isTrue);
      expect(line.actualAmountMinorUnits, 0);
      expect(summary.totalPlannedMinorUnits, 700);
    });
  });
}
