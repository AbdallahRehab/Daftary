import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_failures.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/usecases/create_category.dart';
import 'package:daftary/features/finance/domain/usecases/edit_category.dart';
import 'package:daftary/features/finance/presentation/cubit/category_form_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/category_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository repository;

  final now = DateTime(2026);
  final gym = Category(
    id: 'c1',
    name: 'Gym',
    type: CategoryType.expense,
    icon: 'fitness',
    createdAt: now,
    updatedAt: now,
  );
  final groceries = Category(
    id: 'seed_groceries',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: 'groceries',
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() => registerFallbackValue(CategoryType.expense));

  setUp(() {
    repository = MockCategoryRepository();
  });

  CategoryFormCubit buildCubit() =>
      CategoryFormCubit(CreateCategory(repository), EditCategory(repository));

  group('create mode', () {
    blocTest<CategoryFormCubit, CategoryFormState>(
      'submits name + icon + type and reports success with the saved category',
      build: buildCubit,
      setUp: () {
        when(
          () => repository.createCategory(
            name: 'Gym',
            type: CategoryType.expense,
            icon: 'fitness',
          ),
        ).thenAnswer((_) async => Right(gym));
      },
      act: (cubit) async {
        cubit
          ..initializeForCreate(CategoryType.expense)
          ..nameChanged('  Gym  ')
          ..iconChanged('fitness');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, CategoryFormStatus.success);
        expect(cubit.state.savedCategory, gym);
        // The name is trimmed before it reaches the use case, not stored
        // with the user's stray spaces.
        verify(
          () => repository.createCategory(
            name: 'Gym',
            type: CategoryType.expense,
            icon: 'fitness',
          ),
        ).called(1);
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'blocks an empty-after-trim name without calling the use case',
      build: buildCubit,
      act: (cubit) async {
        cubit
          ..initializeForCreate(CategoryType.expense)
          ..nameChanged('   ')
          ..iconChanged('fitness');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.nameInvalid, isTrue);
        expect(cubit.state.status, CategoryFormStatus.idle);
        verifyNever(
          () => repository.createCategory(
            name: any(named: 'name'),
            type: any(named: 'type'),
            icon: any(named: 'icon'),
          ),
        );
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'blocks a submit with no icon selected',
      build: buildCubit,
      act: (cubit) async {
        cubit
          ..initializeForCreate(CategoryType.expense)
          ..nameChanged('Gym');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.iconInvalid, isTrue);
        expect(cubit.state.nameInvalid, isFalse);
        expect(cubit.state.status, CategoryFormStatus.idle);
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'blocks a create with no type chosen — type is required on create only',
      build: buildCubit,
      act: (cubit) async {
        cubit
          ..nameChanged('Gym')
          ..iconChanged('fitness');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.typeInvalid, isTrue);
        expect(cubit.state.status, CategoryFormStatus.idle);
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'a DuplicateCategoryFailure exposes the conflicting existing category '
      '(FR-008), not just an error message',
      build: buildCubit,
      setUp: () {
        when(
          () => repository.createCategory(
            name: 'groceries',
            type: CategoryType.expense,
            icon: 'groceries',
          ),
        ).thenAnswer(
          (_) async => Left(
            DuplicateCategoryFailure(
              'A category named "Groceries" already exists',
              existing: groceries,
            ),
          ),
        );
      },
      act: (cubit) async {
        cubit
          ..initializeForCreate(CategoryType.expense)
          ..nameChanged('groceries')
          ..iconChanged('groceries');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.duplicateExisting, groceries);
        // Idle, not failure: the form stays usable so the user can rename.
        expect(cubit.state.status, CategoryFormStatus.idle);
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'editing the name clears a standing duplicate warning',
      build: buildCubit,
      seed: () => CategoryFormState(
        type: CategoryType.expense,
        name: 'groceries',
        icon: 'groceries',
        duplicateExisting: groceries,
      ),
      act: (cubit) => cubit.nameChanged('Groceries 2'),
      verify: (cubit) => expect(cubit.state.duplicateExisting, equals(null)),
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'a non-duplicate failure is surfaced as a form failure',
      build: buildCubit,
      setUp: () {
        when(
          () => repository.createCategory(
            name: any(named: 'name'),
            type: any(named: 'type'),
            icon: any(named: 'icon'),
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('write failed')));
      },
      act: (cubit) async {
        cubit
          ..initializeForCreate(CategoryType.expense)
          ..nameChanged('Gym')
          ..iconChanged('fitness');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, CategoryFormStatus.failure);
        expect(cubit.state.failure, const CacheFailure('write failed'));
      },
    );
  });

  group('edit mode', () {
    blocTest<CategoryFormCubit, CategoryFormState>(
      'loadForEdit() prefills name, icon and the (read-only) type',
      build: buildCubit,
      act: (cubit) => cubit.loadForEdit(groceries),
      verify: (cubit) {
        expect(cubit.state.isEditMode, isTrue);
        expect(cubit.state.editingCategoryId, 'seed_groceries');
        expect(cubit.state.name, 'Groceries');
        expect(cubit.state.icon, 'groceries');
        expect(cubit.state.type, CategoryType.expense);
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'submits a rename/re-icon through EditCategory, which takes no type',
      build: buildCubit,
      setUp: () {
        when(
          () => repository.editCategory(
            categoryId: 'seed_groceries',
            name: 'Supermarket',
            icon: 'shopping',
          ),
        ).thenAnswer(
          (_) async =>
              Right(groceries.copyWith(name: 'Supermarket', icon: 'shopping')),
        );
      },
      act: (cubit) async {
        cubit
          ..loadForEdit(groceries)
          ..nameChanged('Supermarket')
          ..iconChanged('shopping');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, CategoryFormStatus.success);
        expect(cubit.state.savedCategory?.name, 'Supermarket');
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'typeChanged() is ignored — a category type is immutable after creation',
      build: buildCubit,
      act: (cubit) => cubit
        ..loadForEdit(groceries)
        ..typeChanged(CategoryType.income),
      verify: (cubit) => expect(cubit.state.type, CategoryType.expense),
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'still blocks an empty-after-trim name',
      build: buildCubit,
      act: (cubit) async {
        cubit
          ..loadForEdit(groceries)
          ..nameChanged('  ');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.nameInvalid, isTrue);
        verifyNever(
          () => repository.editCategory(
            categoryId: any(named: 'categoryId'),
            name: any(named: 'name'),
            icon: any(named: 'icon'),
          ),
        );
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'loadFailed() reports an unresolvable category instead of silently '
      'showing a blank create form',
      build: buildCubit,
      act: (cubit) =>
          cubit.loadFailed(const NotFoundFailure('Category not found')),
      verify: (cubit) {
        expect(cubit.state.status, CategoryFormStatus.failure);
        expect(
          cubit.state.failure,
          const NotFoundFailure('Category not found'),
        );
      },
    );
  });

  blocTest<CategoryFormCubit, CategoryFormState>(
    'a second submit while one is in flight is ignored (single-flight guard)',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.createCategory(
          name: any(named: 'name'),
          type: any(named: 'type'),
          icon: any(named: 'icon'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return Right(gym);
      });
    },
    act: (cubit) async {
      cubit
        ..initializeForCreate(CategoryType.expense)
        ..nameChanged('Gym')
        ..iconChanged('fitness');
      await Future.wait([cubit.submit(), cubit.submit()]);
    },
    verify: (_) {
      verify(
        () => repository.createCategory(
          name: 'Gym',
          type: CategoryType.expense,
          icon: 'fitness',
        ),
      ).called(1);
    },
  );
}
