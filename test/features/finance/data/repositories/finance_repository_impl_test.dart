import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FinanceRepositoryImpl repository;

  // The 22 starter categories are seeded when the database opens, so the
  // ids below are real rows rather than fixtures this test inserts.
  const expenseCategoryId = 'seed_groceries';
  const incomeCategoryId = 'seed_salary';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinanceRepositoryImpl(FinanceDao(db));
    // Forces `beforeOpen` (and therefore the category seed) to run before
    // the first assertion.
    await db.select(db.financeCategories).get();
  });

  tearDown(() => db.close());

  test('the starter categories are seeded on open', () async {
    final categories = await db.select(db.financeCategories).get();

    expect(categories, hasLength(22));
    expect(
      categories.map((c) => c.id),
      containsAll([expenseCategoryId, incomeCategoryId]),
    );
  });

  group('addEntry', () {
    test('records an expense against a seeded category', () async {
      final result = await repository.addEntry(
        idempotencyKey: 'key-1',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        amountMinorUnits: 15050,
        date: DateTime(2026, 1, 15),
        note: 'Weekly shop',
      );

      final entry = result.toNullable()!;
      expect(entry.amount.minorUnits, 15050);
      expect(entry.type, FinanceEntryType.expense);
      expect(entry.categoryId, expenseCategoryId);
      expect(entry.note, 'Weekly shop');
    });

    test('a retried insert with the same idempotencyKey is a no-op that '
        'returns the existing row (FR-021)', () async {
      final first = await repository.addEntry(
        idempotencyKey: 'key-1',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        amountMinorUnits: 15050,
        date: DateTime(2026, 1, 15),
      );
      final retried = await repository.addEntry(
        idempotencyKey: 'key-1',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        // Deliberately different: the retry must return the persisted row
        // untouched, not overwrite it.
        amountMinorUnits: 999999,
        date: DateTime(2026, 2, 20),
      );

      final firstEntry = first.toNullable()!;
      final retriedEntry = retried.toNullable()!;
      expect(retriedEntry.id, firstEntry.id);
      expect(retriedEntry.amount, firstEntry.amount);

      final rows = await db.select(db.financeEntries).get();
      expect(rows, hasLength(1));
    });

    test(
      'rejects an entry whose category type does not match its own type',
      () async {
        final result = await repository.addEntry(
          idempotencyKey: 'key-2',
          // An income category on an expense entry.
          categoryId: incomeCategoryId,
          type: FinanceEntryType.expense,
          amountMinorUnits: 15050,
          date: DateTime(2026, 1, 15),
        );

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        expect(await db.select(db.financeEntries).get(), isEmpty);
      },
    );

    test('rejects a zero or negative amount (FR-003)', () async {
      final zero = await repository.addEntry(
        idempotencyKey: 'key-3',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        amountMinorUnits: 0,
        date: DateTime(2026, 1, 15),
      );
      final negative = await repository.addEntry(
        idempotencyKey: 'key-4',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        amountMinorUnits: -500,
        date: DateTime(2026, 1, 15),
      );

      expect(zero.getLeft().toNullable(), isA<ValidationFailure>());
      expect(negative.getLeft().toNullable(), isA<ValidationFailure>());
      expect(await db.select(db.financeEntries).get(), isEmpty);
    });

    test('an income entry against an income category is recorded by the '
        'same path (FR-002)', () async {
      final result = await repository.addEntry(
        idempotencyKey: 'key-5',
        categoryId: incomeCategoryId,
        type: FinanceEntryType.income,
        amountMinorUnits: 800000,
        date: DateTime(2026, 1, 1),
      );

      expect(result.toNullable()!.type, FinanceEntryType.income);
    });
  });
}
