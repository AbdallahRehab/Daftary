import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/finance/domain/usecases/remove_category.dart';
import 'package:daftary/features/finance/presentation/cubit/category_management_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/category_management_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository repository;

  final now = DateTime(2026);
  Category category(
    String id,
    String name, {
    CategoryType type = CategoryType.expense,
    bool isArchived = false,
  }) => Category(
    id: id,
    name: name,
    type: type,
    icon: 'other',
    isArchived: isArchived,
    createdAt: now,
    updatedAt: now,
  );

  final groceries = category('seed_groceries', 'Groceries');
  final rent = category('seed_rent', 'Rent');
  final oldFuel = category('seed_fuel', 'Fuel', isArchived: true);
  final salary = category('seed_salary', 'Salary', type: CategoryType.income);

  setUpAll(() => registerFallbackValue(CategoryType.expense));

  setUp(() {
    repository = MockCategoryRepository();
  });

  void stubList(
    CategoryType type,
    List<Category> categories, {
    bool includeArchived = true,
  }) {
    when(
      () => repository.getCategories(
        type: type,
        includeArchived: includeArchived,
      ),
    ).thenAnswer((_) async => Right(categories));
  }

  CategoryManagementCubit buildCubit() => CategoryManagementCubit(
    GetCategories(repository),
    RemoveCategory(repository),
  );

  blocTest<CategoryManagementCubit, CategoryManagementState>(
    'load() lists active and archived categories separately, asking for '
    'archived ones (FR-010/FR-011)',
    build: buildCubit,
    setUp: () => stubList(CategoryType.expense, [groceries, rent, oldFuel]),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CategoryManagementState>().having(
        (s) => s.status,
        'status',
        CategoryManagementStatus.loading,
      ),
      isA<CategoryManagementState>()
          .having((s) => s.status, 'status', CategoryManagementStatus.success)
          .having((s) => s.active, 'active', [groceries, rent])
          .having((s) => s.archived, 'archived', [oldFuel]),
    ],
    verify: (_) {
      // The management screen is the one caller that must see archived
      // categories — the entry picker must not (FR-011).
      verify(
        () => repository.getCategories(
          type: CategoryType.expense,
          includeArchived: true,
        ),
      ).called(1);
    },
  );

  blocTest<CategoryManagementCubit, CategoryManagementState>(
    'load() surfaces a failure as state with a retryable message',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.getCategories(
          type: any(named: 'type'),
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('db unavailable')));
    },
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [
      isA<CategoryManagementState>()
          .having((s) => s.status, 'status', CategoryManagementStatus.failure)
          .having(
            (s) => s.failure,
            'failure',
            const CacheFailure('db unavailable'),
          ),
    ],
  );

  blocTest<CategoryManagementCubit, CategoryManagementState>(
    'typeChanged() reloads for the new direction',
    build: buildCubit,
    setUp: () {
      stubList(CategoryType.expense, [groceries]);
      stubList(CategoryType.income, [salary]);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.typeChanged(CategoryType.income);
    },
    verify: (cubit) {
      expect(cubit.state.type, CategoryType.income);
      expect(cubit.state.active, [salary]);
    },
  );

  blocTest<CategoryManagementCubit, CategoryManagementState>(
    'typeChanged() to the already-selected type is a no-op',
    build: buildCubit,
    setUp: () => stubList(CategoryType.expense, [groceries]),
    act: (cubit) => cubit.typeChanged(CategoryType.expense),
    expect: () => <CategoryManagementState>[],
  );

  blocTest<CategoryManagementCubit, CategoryManagementState>(
    'removeCategory() on a never-used category reloads it out of the list '
    '(the hard-delete branch, decided by the repository)',
    build: buildCubit,
    setUp: () {
      var removed = false;
      when(
        () => repository.getCategories(
          type: CategoryType.expense,
          includeArchived: true,
        ),
      ).thenAnswer((_) async => Right(removed ? [rent] : [groceries, rent]));
      when(() => repository.removeCategory('seed_groceries')).thenAnswer((
        _,
      ) async {
        removed = true;
        return const Right(unit);
      });
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.removeCategory('seed_groceries');
    },
    verify: (cubit) {
      expect(cubit.state.active, [rent]);
      expect(cubit.state.archived, isEmpty);
      expect(cubit.state.processingCategoryId, equals(null));
    },
  );

  blocTest<CategoryManagementCubit, CategoryManagementState>(
    'removeCategory() on a referenced category reloads it into the archived '
    'section — the same call, the other branch, no flag passed',
    build: buildCubit,
    setUp: () {
      var removed = false;
      when(
        () => repository.getCategories(
          type: CategoryType.expense,
          includeArchived: true,
        ),
      ).thenAnswer(
        (_) async => Right(
          removed
              ? [groceries.copyWith(isArchived: true), rent]
              : [groceries, rent],
        ),
      );
      when(() => repository.removeCategory('seed_groceries')).thenAnswer((
        _,
      ) async {
        removed = true;
        return const Right(unit);
      });
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.removeCategory('seed_groceries');
    },
    verify: (cubit) {
      expect(cubit.state.active, [rent]);
      expect(cubit.state.archived.single.id, 'seed_groceries');
      // Nothing in the cubit's API or state named the branch — it only ever
      // asked for the removal and re-read the result (Decision 4).
      verify(() => repository.removeCategory('seed_groceries')).called(1);
    },
  );

  blocTest<CategoryManagementCubit, CategoryManagementState>(
    'removeCategory() reports a failure without dropping the list',
    build: buildCubit,
    setUp: () {
      stubList(CategoryType.expense, [groceries, rent]);
      when(
        () => repository.removeCategory('seed_groceries'),
      ).thenAnswer((_) async => const Left(CacheFailure('remove failed')));
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.removeCategory('seed_groceries');
    },
    verify: (cubit) {
      expect(cubit.state.failure, const CacheFailure('remove failed'));
      expect(cubit.state.active, [groceries, rent]);
      expect(cubit.state.processingCategoryId, equals(null));
    },
  );
}
