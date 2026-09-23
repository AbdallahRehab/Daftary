import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_failures.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FinanceDao dao;
  late CategoryRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    dao = FinanceDao(db);
    repository = CategoryRepositoryImpl(dao);
  });

  Future<void> insertEntry({
    required String id,
    required String categoryId,
    required FinanceEntryType type,
  }) async {
    await db
        .into(db.financeEntries)
        .insert(
          FinanceEntriesCompanion.insert(
            id: id,
            idempotencyKey: 'idem_$id',
            categoryId: categoryId,
            type: type.dbValue,
            amountMinorUnits: 25000,
            date: DateTime(2026, 4).millisecondsSinceEpoch,
            createdAt: DateTime(2026, 4).millisecondsSinceEpoch,
          ),
        );
  }

  Future<List<Category>> categoriesOf(
    CategoryType type, {
    bool includeArchived = true,
  }) async {
    final result = await repository.getCategories(
      type: type,
      includeArchived: includeArchived,
    );
    return result.getOrElse((_) => <Category>[]);
  }

  group('seeding', () {
    test('the 22 starter categories are available on open (FR-006)', () async {
      final expenses = await categoriesOf(CategoryType.expense);
      final income = await categoriesOf(CategoryType.income);

      expect(expenses.length + income.length, 22);
      expect(expenses.every((c) => c.isDefault), isTrue);
      expect(expenses.every((c) => c.isArchived), isFalse);
    });
  });

  group('createCategory duplicate-check scoping (research.md Decision 5)', () {
    test('blocks a case- and whitespace-insensitive same-type match', () async {
      final result = await repository.createCategory(
        name: '  gROCeries  ',
        type: CategoryType.expense,
        icon: 'groceries',
      );

      result.match((failure) {
        expect(failure, isA<DuplicateCategoryFailure>());
        expect(
          (failure as DuplicateCategoryFailure).existing.id,
          'seed_groceries',
        );
      }, (_) => fail('expected a DuplicateCategoryFailure'));
    });

    test(
      'the same name under a different type is allowed — "Gift" can be both '
      'an income source and an expense',
      () async {
        // 'Gift' ships as an income category; creating an expense one is a
        // legitimate, distinct category, not a near-duplicate.
        final result = await repository.createCategory(
          name: 'Gift',
          type: CategoryType.expense,
          icon: 'gift',
        );

        expect(result.isRight(), isTrue);
        final expenses = await categoriesOf(CategoryType.expense);
        final income = await categoriesOf(CategoryType.income);
        expect(expenses.where((c) => c.name == 'Gift'), hasLength(1));
        expect(income.where((c) => c.name == 'Gift'), hasLength(1));
      },
    );

    test('a name freed by archiving can be taken again', () async {
      // Archiving retires a name from active use; it does not reserve it
      // forever, so the duplicate check only looks at active rows.
      await insertEntry(
        id: 'e1',
        categoryId: 'seed_groceries',
        type: FinanceEntryType.expense,
      );
      await repository.removeCategory('seed_groceries');

      final result = await repository.createCategory(
        name: 'Groceries',
        type: CategoryType.expense,
        icon: 'groceries',
      );

      expect(result.isRight(), isTrue);
      final created = result.getOrElse(
        (_) => throw StateError('expected Right'),
      );
      expect(created.id, isNot('seed_groceries'));

      final all = await categoriesOf(CategoryType.expense);
      final groceries = all.where((c) => c.name == 'Groceries').toList();
      // Both rows survive: the archived original (still resolving for the
      // entry that references it) and the new active one.
      expect(groceries, hasLength(2));
      expect(groceries.where((c) => c.isArchived), hasLength(1));
      expect(groceries.where((c) => c.isActive), hasLength(1));
    });

    test('rejects an empty-after-trim name without inserting', () async {
      final before = await categoriesOf(CategoryType.expense);

      final result = await repository.createCategory(
        name: '   ',
        type: CategoryType.expense,
        icon: 'other',
      );

      expect(result.isLeft(), isTrue);
      expect(await categoriesOf(CategoryType.expense), hasLength(before.length));
    });
  });

  group('removeCategory archive-vs-delete branch (Decision 4)', () {
    test('zero references → hard delete', () async {
      final result = await repository.removeCategory('seed_bonus');

      expect(result.isRight(), isTrue);
      final income = await categoriesOf(CategoryType.income);
      expect(income.where((c) => c.id == 'seed_bonus'), isEmpty);
      expect(await dao.getCategoryById('seed_bonus'), equals(null));
    });

    test('one or more references → archived and still resolvable', () async {
      await insertEntry(
        id: 'e1',
        categoryId: 'seed_salary',
        type: FinanceEntryType.income,
      );

      final result = await repository.removeCategory('seed_salary');

      expect(result.isRight(), isTrue);
      final resolved = await repository.getCategoryById('seed_salary');
      expect(
        resolved
            .getOrElse((_) => throw StateError('expected Right'))
            .isArchived,
        isTrue,
      );
    });

    test('an archived category drops out of the entry picker (FR-011)', () async {
      await insertEntry(
        id: 'e1',
        categoryId: 'seed_salary',
        type: FinanceEntryType.income,
      );
      await repository.removeCategory('seed_salary');

      final picker = await categoriesOf(
        CategoryType.income,
        includeArchived: false,
      );
      final management = await categoriesOf(CategoryType.income);

      expect(picker.where((c) => c.id == 'seed_salary'), isEmpty);
      expect(management.where((c) => c.id == 'seed_salary'), hasLength(1));
    });
  });
}
