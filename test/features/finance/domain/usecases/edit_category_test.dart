import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_failures.dart';
import 'package:daftary/features/finance/domain/usecases/edit_category.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// `EditCategory` is exercised against a real in-memory database rather
/// than a mock repository, because the property under test (FR-009) is a
/// storage property: entries reference a category by id, so a rename is
/// visible to every past entry without touching a single entry row. A
/// mocked repository could only restate the assumption.
void main() {
  late AppDatabase db;
  late FinanceDao dao;
  late CategoryRepositoryImpl repository;
  late EditCategory editCategory;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    dao = FinanceDao(db);
    repository = CategoryRepositoryImpl(dao);
    editCategory = EditCategory(repository);
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
            amountMinorUnits: 12345,
            date: DateTime(2026, 3, 10).millisecondsSinceEpoch,
            createdAt: DateTime(2026, 3, 10).millisecondsSinceEpoch,
          ),
        );
  }

  test('renames and re-icons without changing the type', () async {
    final result = await editCategory(
      categoryId: 'seed_groceries',
      name: 'Supermarket',
      icon: 'shopping',
    );

    final category = result.getOrElse((_) => throw StateError('expected Right'));
    expect(category.name, 'Supermarket');
    expect(category.icon, 'shopping');
    // Type is not a parameter of the use case at all — it is immutable
    // after creation (data-model.md), so this asserts it survived an edit
    // that had every chance to disturb it.
    expect(category.type, CategoryType.expense);
  });

  test(
    'entries referencing the category reflect the new name on the next read '
    '(live FK, not a name snapshot — FR-009)',
    () async {
      await insertEntry(
        id: 'e1',
        categoryId: 'seed_groceries',
        type: FinanceEntryType.expense,
      );
      await insertEntry(
        id: 'e2',
        categoryId: 'seed_groceries',
        type: FinanceEntryType.expense,
      );

      await editCategory(
        categoryId: 'seed_groceries',
        name: 'Supermarket',
        icon: 'shopping',
      );

      final entries = await dao.getHistory();
      expect(entries, hasLength(2));
      for (final entry in entries) {
        // No entry row was rewritten; each still points at the same id.
        expect(entry.categoryId, 'seed_groceries');
        final resolved = await repository.getCategoryById(entry.categoryId);
        expect(
          resolved.getOrElse((_) => throw StateError('expected Right')).name,
          'Supermarket',
        );
      }
    },
  );

  test('rejects an empty-after-trim name', () async {
    final result = await editCategory(
      categoryId: 'seed_groceries',
      name: '   ',
      icon: 'groceries',
    );
    expect(result.isLeft(), isTrue);
  });

  test('re-iconing without renaming is not a self-collision', () async {
    final result = await editCategory(
      categoryId: 'seed_groceries',
      name: 'Groceries',
      icon: 'restaurants',
    );

    final category = result.getOrElse((_) => throw StateError('expected Right'));
    expect(category.icon, 'restaurants');
    expect(category.name, 'Groceries');
  });

  test(
    'a rename onto another active same-type name returns '
    'DuplicateCategoryFailure naming that category',
    () async {
      final result = await editCategory(
        categoryId: 'seed_groceries',
        name: 'restaurants',
        icon: 'groceries',
      );

      result.match((failure) {
        expect(failure, isA<DuplicateCategoryFailure>());
        expect(
          (failure as DuplicateCategoryFailure).existing.id,
          'seed_restaurants',
        );
      }, (_) => fail('expected a DuplicateCategoryFailure'));

      final unchanged = await repository.getCategoryById('seed_groceries');
      expect(
        unchanged.getOrElse((_) => throw StateError('expected Right')).name,
        'Groceries',
      );
    },
  );

  test('a missing category is reported, never silently created', () async {
    final result = await editCategory(
      categoryId: 'does_not_exist',
      name: 'Ghost',
      icon: 'other',
    );

    expect(result.isLeft(), isTrue);
    final all = await repository.getCategories(
      type: CategoryType.expense,
      includeArchived: true,
    );
    expect(
      all
          .getOrElse((_) => <Category>[])
          .where((c) => c.name == 'Ghost'),
      isEmpty,
    );
  });
}
