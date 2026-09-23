import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/usecases/get_budget_for_month.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_month_cubit.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_month_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetForMonth extends Mock implements GetBudgetForMonth {}

/// T030 — `BudgetMonthCubit`: loads and exposes `BudgetMonthDetail`,
/// refreshes correctly, and reports the FR-018 empty state (not an error)
/// when the month has no budget.
void main() {
  late MockGetBudgetForMonth getBudgetForMonth;

  const month = '2026-09';
  final now = DateTime(2026, 9, 1);

  BudgetMonthDetail detailWithActual(int actual) => BudgetMonthDetail(
    month: month,
    budget: Budget(
      id: 'b1',
      idempotencyKey: 'k',
      month: month,
      createdAt: now,
      updatedAt: now,
    ),
    summary: BudgetSummary(
      budgetId: 'b1',
      categoryBreakdown: [
        BudgetCategoryLine(
          allocationId: 'a1',
          categoryId: 'seed_groceries',
          categoryName: 'Groceries',
          categoryIcon: 'groceries',
          plannedAmountMinorUnits: 600000,
          actualAmountMinorUnits: actual,
        ),
      ],
      unbudgetedSpending: const [],
    ),
  );

  setUp(() {
    getBudgetForMonth = MockGetBudgetForMonth();
  });

  blocTest<BudgetMonthCubit, BudgetMonthState>(
    'load emits loading then success with the month detail',
    setUp: () => when(
      () => getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWithActual(350000))),
    build: () => BudgetMonthCubit(getBudgetForMonth),
    act: (cubit) => cubit.load(month),
    expect: () => [
      const BudgetMonthState(month: month),
      BudgetMonthState(
        month: month,
        status: BudgetMonthStatus.success,
        detail: detailWithActual(350000),
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.hasBudget, isTrue);
      expect(cubit.state.isEmpty, isFalse);
      final line = cubit.state.detail!.summary!.categoryBreakdown.single;
      expect(line.remainingMinorUnits, 250000);
    },
  );

  blocTest<BudgetMonthCubit, BudgetMonthState>(
    'a month with no budget is the FR-018 empty state, not a failure',
    setUp: () => when(
      () => getBudgetForMonth(month),
    ).thenAnswer((_) async => const Right(BudgetMonthDetail.empty(month))),
    build: () => BudgetMonthCubit(getBudgetForMonth),
    act: (cubit) => cubit.load(month),
    skip: 1,
    expect: () => [
      isA<BudgetMonthState>()
          .having((s) => s.status, 'status', BudgetMonthStatus.success)
          .having((s) => s.isEmpty, 'isEmpty', isTrue)
          .having((s) => s.hasBudget, 'hasBudget', isFalse),
    ],
  );

  blocTest<BudgetMonthCubit, BudgetMonthState>(
    'a read failure is exposed as failure',
    setUp: () => when(
      () => getBudgetForMonth(month),
    ).thenAnswer((_) async => const Left(CacheFailure('boom'))),
    build: () => BudgetMonthCubit(getBudgetForMonth),
    act: (cubit) => cubit.load(month),
    skip: 1,
    expect: () => [
      const BudgetMonthState(
        month: month,
        status: BudgetMonthStatus.failure,
        failure: CacheFailure('boom'),
      ),
    ],
  );

  test('reload re-reads live figures after an expense changed elsewhere '
      '(US2 scenario 4)', () async {
    var actual = 350000;
    when(
      () => getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWithActual(actual)));
    final cubit = BudgetMonthCubit(getBudgetForMonth);
    await cubit.load(month);
    expect(cubit.state.detail!.summary!.totalActualMinorUnits, 350000);

    actual = 400000; // the 3,500 expense was edited to 4,000 in 007
    await cubit.reload();

    expect(cubit.state.status, BudgetMonthStatus.success);
    expect(cubit.state.detail!.summary!.totalActualMinorUnits, 400000);
    verify(() => getBudgetForMonth(month)).called(2);
    await cubit.close();
  });

  test('reload keeps the current detail on screen while in flight', () async {
    when(
      () => getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWithActual(1)));
    final cubit = BudgetMonthCubit(getBudgetForMonth);
    await cubit.load(month);

    final gate = Completer<Either<Failure, BudgetMonthDetail>>();
    when(() => getBudgetForMonth(month)).thenAnswer((_) => gate.future);
    final pending = cubit.reload();
    expect(cubit.state.detail, isNotNull);
    gate.complete(Right(detailWithActual(2)));
    await pending;
    expect(cubit.state.detail!.summary!.totalActualMinorUnits, 2);
    await cubit.close();
  });

  test('monthChanged loads the new month and ignores a stale answer for '
      'the old one', () async {
    final slow = Completer<Either<Failure, BudgetMonthDetail>>();
    when(() => getBudgetForMonth(month)).thenAnswer((_) => slow.future);
    when(
      () => getBudgetForMonth('2026-10'),
    ).thenAnswer((_) async => const Right(BudgetMonthDetail.empty('2026-10')));

    final cubit = BudgetMonthCubit(getBudgetForMonth);
    final first = cubit.load(month);
    await cubit.monthChanged('2026-10');
    slow.complete(Right(detailWithActual(5)));
    await first;

    expect(cubit.state.month, '2026-10');
    expect(cubit.state.isEmpty, isTrue);
    await cubit.close();
  });
}
