import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/budgets/domain/entities/budget_trend_point.dart';
import 'package:daftary/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:daftary/features/budgets/domain/usecases/watch_budget_trend.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_trend_cubit.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_trend_state.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/usecases/watch_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';
import '../../helpers/budget_watch_stubs.dart';

class MockBudgetsRepository extends Mock implements BudgetsRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

/// `BudgetTrendCubit` (US5). 021: the categories and the trend are live
/// subscriptions — a change elsewhere redraws the chart, and changing the
/// selection replaces only the trend subscription.
void main() {
  late MockBudgetsRepository budgets;
  late MockCategoryRepository categoriesRepo;
  late FakeTableChanges changes;

  final now = DateTime(2026);
  Category category(String id, String name) => Category(
    id: id,
    name: name,
    type: CategoryType.expense,
    icon: 'other',
    createdAt: now,
    updatedAt: now,
  );

  final groceries = category('c-groceries', 'Groceries');
  final rent = category('c-rent', 'Rent');

  BudgetTrendPoint point(
    String month,
    int? planned,
    int? actual, {
    bool hasBudget = true,
    List<Currency> missingRatesFor = const [],
  }) => BudgetTrendPoint(
    month: month,
    plannedMinorUnits: planned,
    actualMinorUnits: actual,
    hasBudget: hasBudget,
    missingRatesFor: missingRatesFor,
  );

  final overall = [
    point('2026-07', 3000000, 2800000),
    point('2026-08', 3000000, 3200000),
    point('2026-09', 3000000, 1500000),
  ];
  final groceriesTrend = [
    point('2026-07', 600000, 650000),
    point('2026-08', 600000, 500000),
    point('2026-09', 600000, 200000),
  ];
  final tooShort = [
    point('2026-07', 0, 100000, hasBudget: false),
    point('2026-08', 0, 120000, hasBudget: false),
    point('2026-09', 3000000, 900000),
  ];

  /// Trend answers per selected category; `null` is the overall view.
  late Map<String?, Either<Failure, List<BudgetTrendPoint>>> trends;

  setUpAll(() => registerFallbackValue(CategoryType.expense));

  setUp(() {
    budgets = MockBudgetsRepository();
    categoriesRepo = MockCategoryRepository();
    changes = FakeTableChanges();
    trends = {null: Right(overall), groceries.id: Right(groceriesTrend)};
    stubBudgetsWatches(budgets, changes);
    stubCategoryWatches(categoriesRepo, changes);
    when(
      () => categoriesRepo.getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right([groceries, rent]));
    when(
      () => budgets.getBudgetTrend(
        categoryId: any(named: 'categoryId'),
        monthsBack: any(named: 'monthsBack'),
        endMonth: any(named: 'endMonth'),
      ),
    ).thenAnswer(
      (invocation) async =>
          trends[invocation.namedArguments[#categoryId] as String?] ??
          const Right([]),
    );
  });

  tearDown(() => changes.close());

  BudgetTrendCubit buildCubit() => BudgetTrendCubit(
    WatchBudgetTrend(budgets),
    WatchCategories(categoriesRepo),
  );

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'subscribe() watches active expense categories and the overall 6-month '
    'trend (US5 scenario 2)',
    build: buildCubit,
    act: (cubit) => cubit.subscribe(endMonth: '2026-09'),
    expect: () => [
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.loading)
          .having((s) => s.endMonth, 'endMonth', '2026-09'),
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.success)
          .having((s) => s.categories, 'categories', [groceries, rent])
          .having((s) => s.points, 'points', overall)
          .having((s) => s.selectedCategoryId, 'selected', isNull)
          .having((s) => s.showsChart, 'showsChart', isTrue)
          .having((s) => s.missingRatesFor, 'missingRatesFor', isEmpty)
          .having(
            (s) => s.isInsufficientHistory,
            'isInsufficientHistory',
            isFalse,
          ),
    ],
    verify: (_) {
      verify(
        () => categoriesRepo.watchCategories(
          type: CategoryType.expense,
          includeArchived: false,
        ),
      ).called(1);
      verify(
        () => budgets.watchBudgetTrend(
          categoryId: null,
          monthsBack: 6,
          endMonth: '2026-09',
        ),
      ).called(1);
    },
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'categoryChanged() re-subscribes to the trend for just that category '
    '(US5 scenario 1)',
    build: buildCubit,
    act: (cubit) async {
      await cubit.subscribe();
      await cubit.categoryChanged(groceries.id);
    },
    skip: 2,
    expect: () => [
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.loading)
          .having((s) => s.selectedCategoryId, 'selected', groceries.id),
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.success)
          .having((s) => s.points, 'points', groceriesTrend)
          .having((s) => s.selectedCategory, 'selectedCategory', groceries),
    ],
    verify: (_) {
      verify(
        () => budgets.watchBudgetTrend(
          categoryId: groceries.id,
          monthsBack: 6,
          endMonth: null,
        ),
      ).called(1);
      // The categories subscription is kept, not re-opened.
      verify(
        () => categoriesRepo.watchCategories(
          type: any(named: 'type'),
          includeArchived: any(named: 'includeArchived'),
        ),
      ).called(1);
    },
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'categoryChanged(null) returns to the overall view',
    build: buildCubit,
    act: (cubit) async {
      await cubit.subscribe();
      await cubit.categoryChanged(groceries.id);
      await cubit.categoryChanged(null);
    },
    skip: 4,
    expect: () => [
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.loading)
          .having((s) => s.selectedCategoryId, 'selected', isNull),
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.success)
          .having((s) => s.points, 'points', overall),
    ],
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'fewer than 2 budgeted months yields the insufficient-history state, '
    'not a chart (US5 scenario 3)',
    build: buildCubit,
    setUp: () => trends = {null: Right(tooShort)},
    act: (cubit) => cubit.subscribe(),
    skip: 1,
    expect: () => [
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.success)
          .having(
            (s) => s.isInsufficientHistory,
            'isInsufficientHistory',
            isTrue,
          )
          .having((s) => s.showsChart, 'showsChart', isFalse),
    ],
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'a trend failure surfaces as the failure state',
    build: buildCubit,
    setUp: () => trends = {null: const Left(CacheFailure('db'))},
    act: (cubit) => cubit.subscribe(),
    skip: 1,
    expect: () => [
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.failure)
          .having((s) => s.failure, 'failure', const CacheFailure('db')),
    ],
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'a category-load failure surfaces as the failure state',
    build: buildCubit,
    setUp: () => when(
      () => categoriesRepo.getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => const Left(CacheFailure('db'))),
    act: (cubit) => cubit.subscribe(),
    skip: 1,
    expect: () => [
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.failure)
          .having((s) => s.failure, 'failure', const CacheFailure('db')),
    ],
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'a selected category that is no longer offered falls back to overall',
    build: buildCubit,
    seed: () => const BudgetTrendState(selectedCategoryId: 'c-gone'),
    act: (cubit) => cubit.subscribe(),
    verify: (cubit) {
      expect(cubit.state.status, BudgetTrendStatus.success);
      expect(cubit.state.selectedCategoryId, isNull);
      expect(cubit.state.points, overall);
    },
  );

  test('a budget or expense changed elsewhere redraws the open trend '
      '(021 FR-031)', () async {
    final cubit = buildCubit();
    await cubit.subscribe();
    expect(cubit.state.points, overall);

    final updated = [...overall.take(2), point('2026-09', 3000000, 1900000)];
    trends = {null: Right(updated)};
    changes.notify();
    await flush();

    expect(cubit.state.status, BudgetTrendStatus.success);
    expect(cubit.state.points, updated);
    await cubit.close();
  });

  test('a month blocked on a missing rate is a gap, not a failure, and the '
      'state names the currency (018 FR-009)', () async {
    trends = {
      null: Right([
        overall[0],
        point('2026-08', 3000000, null, missingRatesFor: const [Currency.usd]),
        overall[2],
      ]),
    };
    final cubit = buildCubit();
    await cubit.subscribe();

    expect(cubit.state.status, BudgetTrendStatus.success);
    expect(cubit.state.showsChart, isTrue);
    expect(cubit.state.missingRatesFor, [Currency.usd]);

    trends = {null: Right(overall)}; // the USD rate was set elsewhere
    changes.notify();
    await flush();
    expect(cubit.state.missingRatesFor, isEmpty);
    await cubit.close();
  });

  test('close cancels both subscriptions', () async {
    final cubit = buildCubit();
    await cubit.subscribe();
    await cubit.close();

    changes.notify();
    await flush();
    verify(
      () => budgets.getBudgetTrend(
        categoryId: any(named: 'categoryId'),
        monthsBack: any(named: 'monthsBack'),
        endMonth: any(named: 'endMonth'),
      ),
    ).called(1);
  });
}
