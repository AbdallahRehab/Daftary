import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_failures.dart';
import 'package:daftary/features/budgets/domain/usecases/add_budget_category_allocation.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/budgets_harness.dart';

/// T014 — against the real repository, real 007 category repository and an
/// in-memory database, so the expense-type check reads a real `Category`.
void main() {
  late BudgetsHarness h;
  late AddBudgetCategoryAllocation addAllocation;
  late Budget budget;

  setUp(() async {
    h = await BudgetsHarness.open();
    addAllocation = AddBudgetCategoryAllocation(h.repository);
    budget = await h.createBudget('2026-03');
  });

  tearDown(() => h.close());

  test('allocates a planned amount to an expense category', () async {
    final result = await addAllocation(
      idempotencyKey: 'a1',
      budgetId: budget.id,
      categoryId: groceries,
      plannedAmountMinorUnits: 600000,
    );

    final allocation = result.toNullable()!;
    expect(allocation.budgetId, budget.id);
    expect(allocation.categoryId, groceries);
    expect(allocation.plannedAmountMinorUnits, 600000);
  });

  test('rejects a negative planned amount but accepts zero (FR-002)', () async {
    final negative = await addAllocation(
      idempotencyKey: 'a1',
      budgetId: budget.id,
      categoryId: groceries,
      plannedAmountMinorUnits: -1,
    );
    final zero = await addAllocation(
      idempotencyKey: 'a2',
      budgetId: budget.id,
      categoryId: groceries,
      plannedAmountMinorUnits: 0,
    );

    expect(negative.getLeft().toNullable(), isA<ValidationFailure>());
    expect(zero.toNullable()!.plannedAmountMinorUnits, 0);
  });

  test('rejects a second allocation for the same category, pointing at the '
      'existing one (FR-017)', () async {
    final first = await addAllocation(
      idempotencyKey: 'a1',
      budgetId: budget.id,
      categoryId: groceries,
      plannedAmountMinorUnits: 100,
    );
    final duplicate = await addAllocation(
      idempotencyKey: 'a2',
      budgetId: budget.id,
      categoryId: groceries,
      plannedAmountMinorUnits: 200,
    );

    final failure = duplicate.getLeft().toNullable();
    expect(failure, isA<DuplicateBudgetAllocationFailure>());
    expect(
      (failure! as DuplicateBudgetAllocationFailure).existing,
      first.toNullable(),
    );
    expect(
      await h.db.select(h.db.budgetCategoryAllocations).get(),
      hasLength(1),
    );
  });

  test('a retried add with the same idempotencyKey returns the row it '
      'already wrote instead of a duplicate failure', () async {
    final first = await addAllocation(
      idempotencyKey: 'a1',
      budgetId: budget.id,
      categoryId: groceries,
      plannedAmountMinorUnits: 100,
    );
    final retried = await addAllocation(
      idempotencyKey: 'a1',
      budgetId: budget.id,
      categoryId: groceries,
      plannedAmountMinorUnits: 100,
    );

    expect(retried.toNullable(), first.toNullable());
    expect(
      await h.db.select(h.db.budgetCategoryAllocations).get(),
      hasLength(1),
    );
  });

  test('rejects an income category — budgets plan spending only', () async {
    final result = await addAllocation(
      idempotencyKey: 'a1',
      budgetId: budget.id,
      categoryId: salary,
      plannedAmountMinorUnits: 100,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    expect(await h.db.select(h.db.budgetCategoryAllocations).get(), isEmpty);
  });

  test('rejects an archived category for a new allocation (FR-021)', () async {
    // A custom category with an entry against it is archived, not deleted,
    // when removed (007 research.md Decision 4).
    final custom = (await h.categories.createCategory(
      name: 'Gym',
      type: CategoryType.expense,
      icon: 'fitness',
    )).toNullable()!;
    await h.spend(custom.id, 100, DateTime(2026, 2, 1));
    await h.categories.removeCategory(custom.id);

    final result = await addAllocation(
      idempotencyKey: 'a1',
      budgetId: budget.id,
      categoryId: custom.id,
      plannedAmountMinorUnits: 100,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('an unknown category or budget is a not-found failure', () async {
    final unknownCategory = await addAllocation(
      idempotencyKey: 'a1',
      budgetId: budget.id,
      categoryId: 'nope',
      plannedAmountMinorUnits: 100,
    );
    final unknownBudget = await addAllocation(
      idempotencyKey: 'a2',
      budgetId: 'nope',
      categoryId: groceries,
      plannedAmountMinorUnits: 100,
    );

    expect(unknownCategory.getLeft().toNullable(), isA<NotFoundFailure>());
    expect(unknownBudget.getLeft().toNullable(), isA<BudgetNotFoundFailure>());
  });
}
