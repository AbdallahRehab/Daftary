import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget_failures.dart';
import 'package:daftary/features/budgets/domain/usecases/copy_budget_to_month.dart';
import 'package:daftary/features/budgets/domain/usecases/get_budget_for_month.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/budgets_harness.dart';

/// T042 — copy-forward (FR-012), against the real repository and an
/// in-memory database.
void main() {
  late BudgetsHarness h;
  late CopyBudgetToMonth copy;
  late GetBudgetForMonth getMonth;

  setUp(() async {
    h = await BudgetsHarness.open();
    copy = CopyBudgetToMonth(h.repository);
    getMonth = GetBudgetForMonth(h.repository);
  });

  tearDown(() => h.close());

  Future<Map<String, int>> plannedByCategory(String month) async {
    final summary = (await getMonth(month)).toNullable()!.summary!;
    return {
      for (final l in summary.categoryBreakdown)
        l.categoryId: l.plannedAmountMinorUnits,
    };
  }

  test('produces a new budget for the target month with matching '
      'allocations and the source income', () async {
    final source = await h.createBudget('2026-03', income: 900000);
    await h.allocate(source.id, groceries, 600000);
    await h.allocate(source.id, rent, 250000);
    await h.allocate(source.id, fuel, 0);

    final result = await copy(
      idempotencyKey: 'c1',
      sourceBudgetId: source.id,
      targetMonth: '2026-04',
    );

    final copied = result.toNullable()!;
    expect(copied.id, isNot(source.id));
    expect(copied.month, '2026-04');
    expect(copied.expectedIncomeMinorUnits, 900000);
    expect(await plannedByCategory('2026-04'), {
      groceries: 600000,
      rent: 250000,
      fuel: 0,
    });
  });

  test('has no ongoing link to the source: editing the copy leaves the '
      'source untouched, and vice versa', () async {
    final source = await h.createBudget('2026-03', income: 1000);
    await h.allocate(source.id, groceries, 500);
    await h.allocate(source.id, rent, 300);
    final copied = (await copy(
      idempotencyKey: 'c1',
      sourceBudgetId: source.id,
      targetMonth: '2026-04',
    )).toNullable()!;

    final copyLines = (await getMonth(
      '2026-04',
    )).toNullable()!.summary!.categoryBreakdown;
    final copyGroceries = copyLines.firstWhere(
      (l) => l.categoryId == groceries,
    );
    final copyRent = copyLines.firstWhere((l) => l.categoryId == rent);
    await h.repository.editBudgetCategoryAllocation(
      allocationId: copyGroceries.allocationId,
      plannedAmountMinorUnits: 999,
    );
    await h.repository.removeBudgetCategoryAllocation(copyRent.allocationId);
    await h.allocate(copied.id, fuel, 50);
    await h.repository.editBudget(
      budgetId: copied.id,
      expectedIncomeMinorUnits: 2000,
    );

    expect(await plannedByCategory('2026-03'), {groceries: 500, rent: 300});
    expect(
      (await getMonth(
        '2026-03',
      )).toNullable()!.budget!.expectedIncomeMinorUnits,
      1000,
    );
    expect(await plannedByCategory('2026-04'), {groceries: 999, fuel: 50});

    // And the other direction.
    await h.allocate(source.id, restaurants, 10);
    expect(await plannedByCategory('2026-04'), isNot(contains(restaurants)));
  });

  test('rejects a target month that already has a budget, writing '
      'nothing', () async {
    final source = await h.createBudget('2026-03');
    await h.allocate(source.id, groceries, 500);
    final target = await h.createBudget('2026-04');

    final result = await copy(
      idempotencyKey: 'c1',
      sourceBudgetId: source.id,
      targetMonth: '2026-04',
    );

    final failure = result.getLeft().toNullable();
    expect(failure, isA<BudgetAlreadyExistsForMonthFailure>());
    expect((failure! as BudgetAlreadyExistsForMonthFailure).existing, target);
    expect(await h.db.select(h.db.budgets).get(), hasLength(2));
    expect(
      await h.db.select(h.db.budgetCategoryAllocations).get(),
      hasLength(1),
    );
  });

  test('is idempotent on retry: the same key returns the first copy and '
      'writes nothing more (FR-017)', () async {
    final source = await h.createBudget('2026-03');
    await h.allocate(source.id, groceries, 500);
    await h.allocate(source.id, rent, 300);

    final first = await copy(
      idempotencyKey: 'c1',
      sourceBudgetId: source.id,
      targetMonth: '2026-04',
    );
    final retried = await copy(
      idempotencyKey: 'c1',
      sourceBudgetId: source.id,
      targetMonth: '2026-04',
    );

    expect(retried.toNullable(), first.toNullable());
    expect(await h.db.select(h.db.budgets).get(), hasLength(2));
    expect(
      await h.db.select(h.db.budgetCategoryAllocations).get(),
      hasLength(4),
    );
  });

  test('an unknown or deleted source is BudgetNotFoundFailure; a malformed '
      'target month is a ValidationFailure', () async {
    final source = await h.createBudget('2026-03');
    await h.repository.deleteBudget(source.id);

    final deleted = await copy(
      idempotencyKey: 'c1',
      sourceBudgetId: source.id,
      targetMonth: '2026-04',
    );
    final malformed = await copy(
      idempotencyKey: 'c2',
      sourceBudgetId: source.id,
      targetMonth: '2026/04',
    );

    expect(deleted.getLeft().toNullable(), isA<BudgetNotFoundFailure>());
    expect(malformed.getLeft().toNullable(), isA<ValidationFailure>());
  });
}
