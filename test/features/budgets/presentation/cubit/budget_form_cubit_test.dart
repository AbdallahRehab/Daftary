import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_allocation.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart';
import 'package:daftary/features/budgets/domain/entities/budget_failures.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/usecases/add_budget_category_allocation.dart';
import 'package:daftary/features/budgets/domain/usecases/create_budget.dart';
import 'package:daftary/features/budgets/domain/usecases/delete_budget.dart';
import 'package:daftary/features/budgets/domain/usecases/edit_budget.dart';
import 'package:daftary/features/budgets/domain/usecases/edit_budget_category_allocation.dart';
import 'package:daftary/features/budgets/domain/usecases/get_budget_for_month.dart';
import 'package:daftary/features/budgets/domain/usecases/remove_budget_category_allocation.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_form_state.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import '../../../transactions/helpers/currency_test_doubles.dart';

class MockGetBudgetForMonth extends Mock implements GetBudgetForMonth {}

class MockCreateBudget extends Mock implements CreateBudget {}

class MockEditBudget extends Mock implements EditBudget {}

class MockDeleteBudget extends Mock implements DeleteBudget {}

class MockAddAllocation extends Mock implements AddBudgetCategoryAllocation {}

class MockEditAllocation extends Mock implements EditBudgetCategoryAllocation {}

class MockRemoveAllocation extends Mock
    implements RemoveBudgetCategoryAllocation {}

class MockGetCategories extends Mock implements GetCategories {}

/// T017 — `BudgetFormCubit`: happy-path create + allocate, negative-amount
/// rejection, duplicate-tap producing exactly one saved budget/allocation
/// (FR-002/FR-004/FR-010/FR-011/FR-017).
void main() {
  late MockGetBudgetForMonth getBudgetForMonth;
  late MockCreateBudget createBudget;
  late MockEditBudget editBudget;
  late MockDeleteBudget deleteBudget;
  late MockAddAllocation addAllocation;
  late MockEditAllocation editAllocation;
  late MockRemoveAllocation removeAllocation;
  late MockGetCategories getCategories;

  const month = '2026-09';
  final now = DateTime(2026, 9, 1);

  Category expense(String id, String name, String icon) => Category(
    id: id,
    name: name,
    type: CategoryType.expense,
    icon: icon,
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  );

  final rent = expense('seed_rent', 'Rent', 'rent');
  final groceries = expense('seed_groceries', 'Groceries', 'groceries');
  final fuel = expense('seed_fuel', 'Fuel', 'fuel');

  final budget = Budget(
    id: 'b1',
    idempotencyKey: 'k',
    month: month,
    createdAt: now,
    updatedAt: now,
  );

  BudgetCategoryAllocation allocation(String id, String categoryId, int p) =>
      BudgetCategoryAllocation(
        id: id,
        idempotencyKey: 'key-$id',
        budgetId: budget.id,
        categoryId: categoryId,
        plannedAmountMinorUnits: p,
        createdAt: now,
        updatedAt: now,
      );

  void stubAdd() {
    when(
      () => addAllocation(
        idempotencyKey: any(named: 'idempotencyKey'),
        budgetId: any(named: 'budgetId'),
        categoryId: any(named: 'categoryId'),
        plannedAmountMinorUnits: any(named: 'plannedAmountMinorUnits'),
      ),
    ).thenAnswer((invocation) async {
      final categoryId = invocation.namedArguments[#categoryId] as String;
      return Right(
        allocation(
          'a-$categoryId',
          categoryId,
          invocation.namedArguments[#plannedAmountMinorUnits] as int,
        ),
      );
    });
  }

  setUp(() {
    getBudgetForMonth = MockGetBudgetForMonth();
    createBudget = MockCreateBudget();
    editBudget = MockEditBudget();
    deleteBudget = MockDeleteBudget();
    addAllocation = MockAddAllocation();
    editAllocation = MockEditAllocation();
    removeAllocation = MockRemoveAllocation();
    getCategories = MockGetCategories();

    when(
      () => getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right([rent, groceries, fuel]));
    when(
      () => getBudgetForMonth(any()),
    ).thenAnswer((_) async => const Right(BudgetMonthDetail.empty(month)));
    when(
      () => createBudget(
        idempotencyKey: any(named: 'idempotencyKey'),
        month: any(named: 'month'),
        expectedIncomeMinorUnits: any(named: 'expectedIncomeMinorUnits'),
      ),
    ).thenAnswer((_) async => Right(budget));
    stubAdd();
  });

  setUpAll(() {
    registerFallbackValue(CategoryType.expense);
  });

  BudgetFormCubit buildCubit() => BudgetFormCubit(
    getBudgetForMonth,
    createBudget,
    editBudget,
    deleteBudget,
    addAllocation,
    editAllocation,
    removeAllocation,
    getCategories,
    EgpFormatter(),
    getPrimaryCurrencyReturning(),
  );

  group('initialize', () {
    test('create mode: loads active expense categories only', () async {
      final cubit = buildCubit();
      await cubit.initialize(month);

      expect(cubit.state.status, BudgetFormStatus.editing);
      expect(cubit.state.isEditMode, isFalse);
      expect(cubit.state.month, month);
      expect(cubit.state.categories, [rent, groceries, fuel]);
      verify(() => getCategories(type: CategoryType.expense)).called(1);
      await cubit.close();
    });

    test('edit mode: prefills income and saved allocations', () async {
      when(() => getBudgetForMonth(month)).thenAnswer(
        (_) async => Right(
          BudgetMonthDetail(
            month: month,
            budget: Budget(
              id: budget.id,
              idempotencyKey: 'k',
              month: month,
              expectedIncomeMinorUnits: 3000000,
              createdAt: now,
              updatedAt: now,
            ),
            summary: const BudgetSummary(
              budgetId: 'b1',
              categoryBreakdown: [
                BudgetCategoryLine(
                  allocationId: 'a1',
                  categoryId: 'seed_rent',
                  categoryName: 'Rent',
                  categoryIcon: 'rent',
                  plannedAmountMinorUnits: 700000,
                  actualAmountMinorUnits: 0,
                ),
              ],
              unbudgetedSpending: [],
            ),
          ),
        ),
      );

      final cubit = buildCubit();
      await cubit.initialize(month);

      expect(cubit.state.isEditMode, isTrue);
      expect(cubit.state.budgetId, 'b1');
      expect(cubit.state.expectedIncomeMinorUnits, 3000000);
      expect(cubit.state.allocations.single.persistedAllocationId, 'a1');
      expect(cubit.state.allocations.single.plannedMinorUnits, 700000);
      // Rent is already on the budget, so the picker no longer offers it.
      expect(cubit.state.availableCategories, [groceries, fuel]);
      await cubit.close();
    });
  });

  blocTest<BudgetFormCubit, BudgetFormState>(
    'happy path: creates the budget once, then one allocation per row',
    build: buildCubit,
    act: (cubit) async {
      await cubit.initialize(month);
      cubit
        ..expectedIncomeChanged('30000')
        ..categoryAdded(rent.id)
        ..categoryAdded(groceries.id)
        ..allocationAmountChanged(rent.id, '7000')
        ..allocationAmountChanged(groceries.id, '6000');
      await cubit.submit();
    },
    skip: 8,
    expect: () => [
      isA<BudgetFormState>().having(
        (s) => s.status,
        'status',
        BudgetFormStatus.submitting,
      ),
      // budget id recorded, then each allocation marked persisted.
      isA<BudgetFormState>().having((s) => s.budgetId, 'budgetId', 'b1'),
      isA<BudgetFormState>(),
      isA<BudgetFormState>(),
      isA<BudgetFormState>()
          .having((s) => s.status, 'status', BudgetFormStatus.success)
          .having(
            (s) => s.allocations.every((d) => d.isPersisted),
            'all persisted',
            isTrue,
          ),
    ],
    verify: (cubit) {
      verify(
        () => createBudget(
          idempotencyKey: cubit.state.idempotencyKey,
          month: month,
          expectedIncomeMinorUnits: 3000000,
        ),
      ).called(1);
      verify(
        () => addAllocation(
          idempotencyKey: any(named: 'idempotencyKey'),
          budgetId: 'b1',
          categoryId: rent.id,
          plannedAmountMinorUnits: 700000,
        ),
      ).called(1);
      verify(
        () => addAllocation(
          idempotencyKey: any(named: 'idempotencyKey'),
          budgetId: 'b1',
          categoryId: groceries.id,
          plannedAmountMinorUnits: 600000,
        ),
      ).called(1);
    },
  );

  test('zero is a valid planned amount (FR-002)', () async {
    final cubit = buildCubit();
    await cubit.initialize(month);
    cubit
      ..categoryAdded(fuel.id)
      ..allocationAmountChanged(fuel.id, '0');
    await cubit.submit();

    expect(cubit.state.status, BudgetFormStatus.success);
    verify(
      () => addAllocation(
        idempotencyKey: any(named: 'idempotencyKey'),
        budgetId: 'b1',
        categoryId: fuel.id,
        plannedAmountMinorUnits: 0,
      ),
    ).called(1);
    await cubit.close();
  });

  test('a negative amount is rejected and nothing is saved (FR-002)', () async {
    final cubit = buildCubit();
    await cubit.initialize(month);
    cubit
      ..categoryAdded(rent.id)
      ..allocationAmountChanged(rent.id, '-50');
    await cubit.submit();

    expect(
      cubit.state.allocations.single.amountError,
      BudgetAmountError.negative,
    );
    // What the user typed is kept, and it never counts toward the total.
    expect(cubit.state.allocations.single.amountInput, '-50');
    expect(cubit.state.totalPlannedMinorUnits, 0);
    expect(cubit.state.status, BudgetFormStatus.editing);
    verifyNever(
      () => createBudget(
        idempotencyKey: any(named: 'idempotencyKey'),
        month: any(named: 'month'),
        expectedIncomeMinorUnits: any(named: 'expectedIncomeMinorUnits'),
      ),
    );
    await cubit.close();
  });

  test('a blank amount is flagged as required', () async {
    final cubit = buildCubit();
    await cubit.initialize(month);
    cubit.categoryAdded(rent.id);
    await cubit.submit();

    expect(
      cubit.state.allocations.single.amountError,
      BudgetAmountError.required,
    );
    await cubit.close();
  });

  test('a rapid double tap saves exactly one budget and allocation', () async {
    final createGate = Completer<Either<Failure, Budget>>();
    when(
      () => createBudget(
        idempotencyKey: any(named: 'idempotencyKey'),
        month: any(named: 'month'),
        expectedIncomeMinorUnits: any(named: 'expectedIncomeMinorUnits'),
      ),
    ).thenAnswer((_) => createGate.future);

    final cubit = buildCubit();
    await cubit.initialize(month);
    cubit
      ..categoryAdded(rent.id)
      ..allocationAmountChanged(rent.id, '7000');

    final first = cubit.submit();
    final second = cubit.submit(); // re-entrant tap while the first is busy
    expect(cubit.state.isSubmitting, isTrue);
    createGate.complete(Right(budget));
    await Future.wait([first, second]);

    expect(cubit.state.status, BudgetFormStatus.success);
    verify(
      () => createBudget(
        idempotencyKey: any(named: 'idempotencyKey'),
        month: any(named: 'month'),
        expectedIncomeMinorUnits: any(named: 'expectedIncomeMinorUnits'),
      ),
    ).called(1);
    verify(
      () => addAllocation(
        idempotencyKey: any(named: 'idempotencyKey'),
        budgetId: any(named: 'budgetId'),
        categoryId: any(named: 'categoryId'),
        plannedAmountMinorUnits: any(named: 'plannedAmountMinorUnits'),
      ),
    ).called(1);
    await cubit.close();
  });

  test('a retry after a failed allocation does not re-create the budget and '
      'reuses the row idempotency key', () async {
    var attempts = 0;
    final keys = <String>[];
    when(
      () => addAllocation(
        idempotencyKey: any(named: 'idempotencyKey'),
        budgetId: any(named: 'budgetId'),
        categoryId: any(named: 'categoryId'),
        plannedAmountMinorUnits: any(named: 'plannedAmountMinorUnits'),
      ),
    ).thenAnswer((invocation) async {
      keys.add(invocation.namedArguments[#idempotencyKey] as String);
      attempts++;
      if (attempts == 1) return const Left(CacheFailure('disk full'));
      return Right(allocation('a1', rent.id, 700000));
    });

    final cubit = buildCubit();
    await cubit.initialize(month);
    cubit
      ..categoryAdded(rent.id)
      ..allocationAmountChanged(rent.id, '7000');

    await cubit.submit();
    expect(cubit.state.status, BudgetFormStatus.failure);
    expect(cubit.state.budgetId, 'b1');

    await cubit.submit();
    expect(cubit.state.status, BudgetFormStatus.success);
    verify(
      () => createBudget(
        idempotencyKey: any(named: 'idempotencyKey'),
        month: any(named: 'month'),
        expectedIncomeMinorUnits: any(named: 'expectedIncomeMinorUnits'),
      ),
    ).called(1);
    expect(keys, hasLength(2));
    expect(keys.toSet(), hasLength(1));
    await cubit.close();
  });

  test('the "exceeds income" hint is live and never blocks save '
      '(FR-004)', () async {
    final cubit = buildCubit();
    await cubit.initialize(month);
    cubit
      ..expectedIncomeChanged('10000')
      ..categoryAdded(rent.id)
      ..allocationAmountChanged(rent.id, '7000');
    expect(cubit.state.plannedExceedsIncome, isFalse);

    cubit
      ..categoryAdded(groceries.id)
      ..allocationAmountChanged(groceries.id, '6000');
    expect(cubit.state.plannedExceedsIncome, isTrue);
    expect(cubit.state.excessOverIncomeMinorUnits, 300000);

    await cubit.submit();
    expect(cubit.state.status, BudgetFormStatus.success);
    await cubit.close();
  });

  test('a duplicate-month failure surfaces as a failure state', () async {
    when(
      () => createBudget(
        idempotencyKey: any(named: 'idempotencyKey'),
        month: any(named: 'month'),
        expectedIncomeMinorUnits: any(named: 'expectedIncomeMinorUnits'),
      ),
    ).thenAnswer(
      (_) async =>
          Left(BudgetAlreadyExistsForMonthFailure('taken', existing: budget)),
    );
    final cubit = buildCubit();
    await cubit.initialize(month);
    await cubit.submit();

    expect(cubit.state.status, BudgetFormStatus.failure);
    expect(cubit.state.failure, isA<BudgetAlreadyExistsForMonthFailure>());
    await cubit.close();
  });

  group('edit mode (FR-010/FR-011)', () {
    setUp(() {
      when(() => getBudgetForMonth(month)).thenAnswer(
        (_) async => Right(
          BudgetMonthDetail(
            month: month,
            budget: budget,
            summary: const BudgetSummary(
              budgetId: 'b1',
              categoryBreakdown: [
                BudgetCategoryLine(
                  allocationId: 'a-rent',
                  categoryId: 'seed_rent',
                  categoryName: 'Rent',
                  categoryIcon: 'rent',
                  plannedAmountMinorUnits: 700000,
                  actualAmountMinorUnits: 0,
                ),
                BudgetCategoryLine(
                  allocationId: 'a-groceries',
                  categoryId: 'seed_groceries',
                  categoryName: 'Groceries',
                  categoryIcon: 'groceries',
                  plannedAmountMinorUnits: 600000,
                  actualAmountMinorUnits: 0,
                ),
              ],
              unbudgetedSpending: [],
            ),
          ),
        ),
      );
      when(
        () => editAllocation(
          allocationId: any(named: 'allocationId'),
          plannedAmountMinorUnits: any(named: 'plannedAmountMinorUnits'),
        ),
      ).thenAnswer((_) async => Right(allocation('a-rent', rent.id, 800000)));
      when(
        () => removeAllocation(any()),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => editBudget(
          budgetId: any(named: 'budgetId'),
          expectedIncomeMinorUnits: any(named: 'expectedIncomeMinorUnits'),
        ),
      ).thenAnswer((_) async => Right(budget));
      when(
        () => deleteBudget(any()),
      ).thenAnswer((_) async => const Right(unit));
    });

    test('edits changed rows, removes dropped ones, adds new ones — and '
        'never creates a second budget', () async {
      final cubit = buildCubit();
      await cubit.initialize(month);
      cubit
        ..allocationAmountChanged(rent.id, '8000')
        ..allocationRemoved(groceries.id)
        ..categoryAdded(fuel.id)
        ..allocationAmountChanged(fuel.id, '1500')
        ..expectedIncomeChanged('25000');
      await cubit.submit();

      expect(cubit.state.status, BudgetFormStatus.success);
      verifyNever(
        () => createBudget(
          idempotencyKey: any(named: 'idempotencyKey'),
          month: any(named: 'month'),
          expectedIncomeMinorUnits: any(named: 'expectedIncomeMinorUnits'),
        ),
      );
      verify(
        () => editBudget(budgetId: 'b1', expectedIncomeMinorUnits: 2500000),
      ).called(1);
      verify(
        () => editAllocation(
          allocationId: 'a-rent',
          plannedAmountMinorUnits: 800000,
        ),
      ).called(1);
      verify(() => removeAllocation('a-groceries')).called(1);
      verify(
        () => addAllocation(
          idempotencyKey: any(named: 'idempotencyKey'),
          budgetId: 'b1',
          categoryId: fuel.id,
          plannedAmountMinorUnits: 150000,
        ),
      ).called(1);
      await cubit.close();
    });

    test('unchanged rows are not re-written', () async {
      final cubit = buildCubit();
      await cubit.initialize(month);
      await cubit.submit();

      expect(cubit.state.status, BudgetFormStatus.success);
      verifyNever(
        () => editAllocation(
          allocationId: any(named: 'allocationId'),
          plannedAmountMinorUnits: any(named: 'plannedAmountMinorUnits'),
        ),
      );
      verifyNever(
        () => editBudget(
          budgetId: any(named: 'budgetId'),
          expectedIncomeMinorUnits: any(named: 'expectedIncomeMinorUnits'),
        ),
      );
      await cubit.close();
    });

    blocTest<BudgetFormCubit, BudgetFormState>(
      'deleteBudget deletes the loaded budget',
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize(month);
        await cubit.deleteBudget();
      },
      verify: (cubit) {
        expect(cubit.state.status, BudgetFormStatus.deleted);
        verify(() => deleteBudget('b1')).called(1);
      },
    );
  });
}
