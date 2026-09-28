import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget_trend_point.dart';
import 'package:daftary/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:daftary/features/budgets/domain/usecases/get_budget_trend.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_trend_cubit.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_trend_state.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetsRepository extends Mock implements BudgetsRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockBudgetsRepository budgets;
  late MockCategoryRepository categoriesRepo;

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
    int planned,
    int actual, {
    bool hasBudget = true,
  }) => BudgetTrendPoint(
    month: month,
    plannedMinorUnits: planned,
    actualMinorUnits: actual,
    hasBudget: hasBudget,
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

  setUpAll(() => registerFallbackValue(CategoryType.expense));

  setUp(() {
    budgets = MockBudgetsRepository();
    categoriesRepo = MockCategoryRepository();
    when(
      () => categoriesRepo.getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right([groceries, rent]));
  });

  void stubTrend(String? categoryId, List<BudgetTrendPoint> points) {
    when(
      () => budgets.getBudgetTrend(
        categoryId: categoryId,
        monthsBack: any(named: 'monthsBack'),
        endMonth: any(named: 'endMonth'),
      ),
    ).thenAnswer((_) async => Right(points));
  }

  BudgetTrendCubit buildCubit() =>
      BudgetTrendCubit(GetBudgetTrend(budgets), GetCategories(categoriesRepo));

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'load() fetches active expense categories and the overall 6-month trend '
    '(US5 scenario 2)',
    build: buildCubit,
    setUp: () => stubTrend(null, overall),
    act: (cubit) => cubit.load(endMonth: '2026-09'),
    expect: () => [
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.loading)
          .having((s) => s.endMonth, 'endMonth', '2026-09'),
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.loading)
          .having((s) => s.categories, 'categories', [groceries, rent]),
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.success)
          .having((s) => s.points, 'points', overall)
          .having((s) => s.selectedCategoryId, 'selected', isNull)
          .having((s) => s.showsChart, 'showsChart', isTrue)
          .having(
            (s) => s.isInsufficientHistory,
            'isInsufficientHistory',
            isFalse,
          ),
    ],
    verify: (_) {
      verify(
        () => categoriesRepo.getCategories(
          type: CategoryType.expense,
          includeArchived: false,
        ),
      ).called(1);
      verify(
        () => budgets.getBudgetTrend(
          categoryId: null,
          monthsBack: 6,
          endMonth: '2026-09',
        ),
      ).called(1);
    },
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'categoryChanged() re-queries the trend for just that category '
    '(US5 scenario 1)',
    build: buildCubit,
    setUp: () {
      stubTrend(null, overall);
      stubTrend(groceries.id, groceriesTrend);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.categoryChanged(groceries.id);
    },
    skip: 3,
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
        () => budgets.getBudgetTrend(
          categoryId: groceries.id,
          monthsBack: 6,
          endMonth: null,
        ),
      ).called(1);
    },
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'categoryChanged(null) returns to the overall view',
    build: buildCubit,
    setUp: () {
      stubTrend(null, overall);
      stubTrend(groceries.id, groceriesTrend);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.categoryChanged(groceries.id);
      await cubit.categoryChanged(null);
    },
    skip: 5,
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
    setUp: () => stubTrend(null, tooShort),
    act: (cubit) => cubit.load(),
    skip: 2,
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
    setUp: () => when(
      () => budgets.getBudgetTrend(
        categoryId: any(named: 'categoryId'),
        monthsBack: any(named: 'monthsBack'),
        endMonth: any(named: 'endMonth'),
      ),
    ).thenAnswer((_) async => const Left(CacheFailure('db'))),
    act: (cubit) => cubit.load(),
    skip: 2,
    expect: () => [
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.failure)
          .having((s) => s.failure, 'failure', const CacheFailure('db')),
    ],
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'a category-load failure surfaces as the failure state without querying '
    'the trend',
    build: buildCubit,
    setUp: () => when(
      () => categoriesRepo.getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => const Left(CacheFailure('db'))),
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [
      isA<BudgetTrendState>().having(
        (s) => s.status,
        'status',
        BudgetTrendStatus.failure,
      ),
    ],
    verify: (_) {
      verifyNever(
        () => budgets.getBudgetTrend(
          categoryId: any(named: 'categoryId'),
          monthsBack: any(named: 'monthsBack'),
          endMonth: any(named: 'endMonth'),
        ),
      );
    },
  );

  blocTest<BudgetTrendCubit, BudgetTrendState>(
    'a selected category that is no longer offered falls back to overall on '
    'reload',
    build: buildCubit,
    seed: () => const BudgetTrendState(selectedCategoryId: 'c-gone'),
    setUp: () => stubTrend(null, overall),
    act: (cubit) => cubit.load(),
    // The seed already is the "loading" state, so the first emission is the
    // post-category one.
    skip: 1,
    expect: () => [
      isA<BudgetTrendState>()
          .having((s) => s.status, 'status', BudgetTrendStatus.success)
          .having((s) => s.selectedCategoryId, 'selected', isNull)
          .having((s) => s.points, 'points', overall),
    ],
  );
}
