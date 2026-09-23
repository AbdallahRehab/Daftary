import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_failures.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/usecases/create_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository repository;
  late CreateCategory createCategory;

  final now = DateTime(2026);
  final existingGroceries = Category(
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
    createCategory = CreateCategory(repository);
  });

  test('rejects an empty-after-trim name (FR-007)', () async {
    when(
      () => repository.createCategory(
        name: any(named: 'name'),
        type: any(named: 'type'),
        icon: any(named: 'icon'),
      ),
    ).thenAnswer(
      (_) async => const Left(ValidationFailure('Category name is required')),
    );

    final result = await createCategory(
      name: '   ',
      type: CategoryType.expense,
      icon: 'other',
    );

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('expected a ValidationFailure'),
    );
  });

  test(
    'surfaces DuplicateCategoryFailure carrying the existing active category '
    'of the same type (FR-008)',
    () async {
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
            existing: existingGroceries,
          ),
        ),
      );

      final result = await createCategory(
        name: 'groceries',
        type: CategoryType.expense,
        icon: 'groceries',
      );

      result.match((failure) {
        expect(failure, isA<DuplicateCategoryFailure>());
        // The failure names the category the user already has — the form
        // can point at it rather than only saying the name is taken.
        expect(
          (failure as DuplicateCategoryFailure).existing,
          existingGroceries,
        );
      }, (_) => fail('expected a DuplicateCategoryFailure'));
    },
  );

  test('creates the category when nothing collides', () async {
    final created = Category(
      id: 'c1',
      name: 'Gym',
      type: CategoryType.expense,
      icon: 'fitness',
      createdAt: now,
      updatedAt: now,
    );
    when(
      () => repository.createCategory(
        name: 'Gym',
        type: CategoryType.expense,
        icon: 'fitness',
      ),
    ).thenAnswer((_) async => Right(created));

    final result = await createCategory(
      name: 'Gym',
      type: CategoryType.expense,
      icon: 'fitness',
    );

    expect(result, Right<Failure, Category>(created));
  });
}
