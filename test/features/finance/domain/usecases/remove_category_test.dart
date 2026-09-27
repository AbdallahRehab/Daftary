import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/remove_category.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_daos.dart';

/// The archive-vs-hard-delete branch (FR-010, research.md Decision 4) is
/// decided by a reference count against the real `finance_entries` table,
/// so it is tested against a real in-memory database — a mocked repository
/// would let the test assert the branch it had itself stubbed.
void main() {
  late AppDatabase db;
  late FinanceDao dao;
  late CategoryRepositoryImpl repository;
  late RemoveCategory removeCategory;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    dao = testFinanceDao(db);
    repository = CategoryRepositoryImpl(dao);
    removeCategory = RemoveCategory(repository);
  });

  Future<void> insertEntry({
    required String id,
    required String categoryId,
    DateTime? deletedAt,
  }) async {
    await db
        .into(db.financeEntries)
        .insert(
          FinanceEntriesCompanion.insert(
            id: id,
            idempotencyKey: 'idem_$id',
            categoryId: categoryId,
            type: FinanceEntryType.expense.dbValue,
            amountMinorUnits: 5000,
            date: DateTime(2026, 2, 5).millisecondsSinceEpoch,
            createdAt: DateTime(2026, 2, 5).millisecondsSinceEpoch,
            deletedAt: Value(deletedAt?.millisecondsSinceEpoch),
          ),
        );
  }

  Future<List<Category>> expenseCategories() async {
    final result = await repository.getCategories(
      type: CategoryType.expense,
      includeArchived: true,
    );
    return result.getOrElse((_) => <Category>[]);
  }

  test('a never-used category is hard-deleted', () async {
    final result = await removeCategory('seed_groceries');

    expect(result.isRight(), isTrue);
    final all = await expenseCategories();
    expect(all.where((c) => c.id == 'seed_groceries'), isEmpty);
  });

  test('a referenced category is archived, never deleted', () async {
    await insertEntry(id: 'e1', categoryId: 'seed_groceries');

    final result = await removeCategory('seed_groceries');

    expect(result.isRight(), isTrue);
    final all = await expenseCategories();
    final groceries = all.firstWhere((c) => c.id == 'seed_groceries');
    // Still resolvable, so the entry's history keeps rendering (FR-011).
    expect(groceries.isArchived, isTrue);
  });

  test('a soft-deleted entry still counts as a reference, so the category is '
      'archived rather than deleted', () async {
    // A soft-deleted entry can be restored within the undo window
    // (research.md Decision 8) and has to find its category again — so it
    // must keep the category alive exactly like a live entry does.
    await insertEntry(
      id: 'e1',
      categoryId: 'seed_groceries',
      deletedAt: DateTime(2026, 2, 6),
    );

    await removeCategory('seed_groceries');

    final all = await expenseCategories();
    final groceries = all.firstWhere((c) => c.id == 'seed_groceries');
    expect(groceries.isArchived, isTrue);
  });

  test('removing an already-archived referenced category keeps it', () async {
    await insertEntry(id: 'e1', categoryId: 'seed_groceries');
    await removeCategory('seed_groceries');

    final result = await removeCategory('seed_groceries');

    expect(result.isRight(), isTrue);
    final all = await expenseCategories();
    expect(all.where((c) => c.id == 'seed_groceries'), hasLength(1));
  });

  test('an unknown category id is reported, not silently ignored', () async {
    final result = await removeCategory('does_not_exist');
    expect(result.isLeft(), isTrue);
  });
}
