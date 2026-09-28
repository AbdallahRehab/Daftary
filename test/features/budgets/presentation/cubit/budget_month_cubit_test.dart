import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:daftary/features/budgets/domain/usecases/watch_budget_for_month.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_month_cubit.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_month_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';
import '../../helpers/budget_watch_stubs.dart';

class MockBudgetsRepository extends Mock implements BudgetsRepository {}

/// T030 — `BudgetMonthCubit`: subscribes to and exposes `BudgetMonthDetail`,
/// and reports the FR-018 empty state (not an error) when the month has no
/// budget.
///
/// 021: the subscription is live — a change elsewhere re-emits with no
/// reload, a month switch replaces it, and [BudgetMonthCubit.close]
/// cancels it.
void main() {
  late MockBudgetsRepository repository;
  late FakeTableChanges changes;

  const month = '2026-09';
  final now = DateTime(2026, 9, 1);

  BudgetMonthDetail detailWithActual(int? actual) => BudgetMonthDetail(
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
    repository = MockBudgetsRepository();
    changes = FakeTableChanges();
    stubBudgetsWatches(repository, changes);
  });

  tearDown(() => changes.close());

  BudgetMonthCubit buildCubit() =>
      BudgetMonthCubit(WatchBudgetForMonth(repository));

  /// Lets a notified re-read deliver.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  blocTest<BudgetMonthCubit, BudgetMonthState>(
    'subscribe emits loading then success with the month detail',
    setUp: () => when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWithActual(350000))),
    build: buildCubit,
    act: (cubit) => cubit.subscribe(month),
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
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => const Right(BudgetMonthDetail.empty(month))),
    build: buildCubit,
    act: (cubit) => cubit.subscribe(month),
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
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => const Left(CacheFailure('boom'))),
    build: buildCubit,
    act: (cubit) => cubit.subscribe(month),
    skip: 1,
    expect: () => [
      const BudgetMonthState(
        month: month,
        status: BudgetMonthStatus.failure,
        failure: CacheFailure('boom'),
      ),
    ],
  );

  test('an expense recorded elsewhere updates the open month with no '
      'reload (021 FR-031, US2 scenario 4)', () async {
    var actual = 350000;
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWithActual(actual)));
    final cubit = buildCubit();
    await cubit.subscribe(month);
    expect(cubit.state.detail!.summary!.totalActualMinorUnits, 350000);

    actual = 400000; // the 3,500 expense was edited to 4,000 in 007
    changes.notify();
    await flush();

    expect(cubit.state.status, BudgetMonthStatus.success);
    expect(cubit.state.detail!.summary!.totalActualMinorUnits, 400000);
    verify(() => repository.getBudgetForMonth(month)).called(2);
    await cubit.close();
  });

  test('a rate set elsewhere unblocks a line on the open month', () async {
    int? actual; // spend in a currency with no rate yet
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWithActual(actual)));
    final cubit = buildCubit();
    await cubit.subscribe(month);
    final summary = cubit.state.detail!.summary!;
    expect(summary.isActualBlocked, isTrue);
    expect(summary.totalActualMinorUnits, isNull);
    // Planned amounts are never blocked.
    expect(summary.totalPlannedMinorUnits, 600000);

    actual = 250000; // the rate was set in settings
    changes.notify();
    await flush();

    expect(cubit.state.detail!.summary!.isActualBlocked, isFalse);
    expect(cubit.state.detail!.summary!.totalActualMinorUnits, 250000);
    await cubit.close();
  });

  test('resubscribe keeps the current detail on screen while in '
      'flight', () async {
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWithActual(1)));
    final cubit = buildCubit();
    await cubit.subscribe(month);

    final gate = Completer<Either<Failure, BudgetMonthDetail>>();
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) => gate.future);
    final pending = cubit.resubscribe();
    expect(cubit.state.isLoading, isTrue);
    expect(cubit.state.detail, isNotNull);
    gate.complete(Right(detailWithActual(2)));
    await pending;
    expect(cubit.state.detail!.summary!.totalActualMinorUnits, 2);
    await cubit.close();
  });

  test('monthChanged subscribes to the new month; the old one never '
      'delivers again', () async {
    final slow = Completer<Either<Failure, BudgetMonthDetail>>();
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) => slow.future);
    when(
      () => repository.getBudgetForMonth('2026-10'),
    ).thenAnswer((_) async => const Right(BudgetMonthDetail.empty('2026-10')));

    final cubit = buildCubit();
    final first = cubit.subscribe(month);
    await cubit.monthChanged('2026-10');
    slow.complete(Right(detailWithActual(5)));
    await first;
    await flush();

    expect(cubit.state.month, '2026-10');
    expect(cubit.state.isEmpty, isTrue);
    await cubit.close();
  });

  test('close cancels the subscription', () async {
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWithActual(1)));
    final cubit = buildCubit();
    await cubit.subscribe(month);
    await cubit.close();

    changes.notify();
    await flush();
    verify(() => repository.getBudgetForMonth(month)).called(1);
  });
}
