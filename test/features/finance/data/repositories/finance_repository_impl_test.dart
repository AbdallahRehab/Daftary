import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
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
        amount: Money.egp(15050),
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
        amount: Money.egp(15050),
        date: DateTime(2026, 1, 15),
      );
      final retried = await repository.addEntry(
        idempotencyKey: 'key-1',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        // Deliberately different: the retry must return the persisted row
        // untouched, not overwrite it.
        amount: Money.egp(999999),
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
          amount: Money.egp(15050),
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
        amount: Money.egp(0),
        date: DateTime(2026, 1, 15),
      );
      final negative = await repository.addEntry(
        idempotencyKey: 'key-4',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        amount: Money.egp(-500),
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
        amount: Money.egp(800000),
        date: DateTime(2026, 1, 1),
      );

      expect(result.toNullable()!.type, FinanceEntryType.income);
    });
  });

  group('currency_code (018, T026)', () {
    test('a non-EGP amount round-trips its currency through the column '
        'and back into the domain', () async {
      final added = (await repository.addEntry(
        idempotencyKey: 'usd-1',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        amount: Money.fromMinorUnits(4999, Currency.usd),
        date: DateTime(2026, 2, 1),
      )).toNullable()!;

      expect(added.amount, Money.fromMinorUnits(4999, Currency.usd));
      final row = await (db.select(
        db.financeEntries,
      )..where((t) => t.id.equals(added.id))).getSingle();
      expect(row.currencyCode, 'USD');
      expect(row.amountMinorUnits, 4999);

      final reloaded = (await repository.getEntryById(added.id)).toNullable()!;
      expect(reloaded.amount.currency, Currency.usd);
    });

    test('an EGP amount is stored as EGP, exactly as before 018', () async {
      final added = (await repository.addEntry(
        idempotencyKey: 'egp-1',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        amount: const Money.egp(15050),
        date: DateTime(2026, 2, 1),
      )).toNullable()!;

      final row = await (db.select(
        db.financeEntries,
      )..where((t) => t.id.equals(added.id))).getSingle();
      expect(row.currencyCode, 'EGP');
      expect(added.amount, const Money.egp(15050));
    });

    test('a row inserted without a currency (pre-018 shape) reads back as '
        'EGP via the column default (FR-002)', () async {
      await db
          .into(db.financeEntries)
          .insert(
            FinanceEntriesCompanion.insert(
              id: 'legacy',
              idempotencyKey: 'legacy',
              categoryId: expenseCategoryId,
              type: FinanceEntryType.expense.dbValue,
              amountMinorUnits: 700,
              date: DateTime(2026, 2, 1).millisecondsSinceEpoch,
              createdAt: DateTime(2026, 2, 1).millisecondsSinceEpoch,
              note: const Value(null),
            ),
          );

      final entry = (await repository.getEntryById('legacy')).toNullable()!;
      expect(entry.amount, const Money.egp(700));
    });

    test('editing an entry can change its currency — only by the user\'s '
        'direct edit (FR-004)', () async {
      final added = (await repository.addEntry(
        idempotencyKey: 'edit-ccy',
        categoryId: expenseCategoryId,
        type: FinanceEntryType.expense,
        amount: const Money.egp(1000),
        date: DateTime(2026, 2, 1),
      )).toNullable()!;

      final edited = (await repository.editEntry(
        entryId: added.id,
        categoryId: expenseCategoryId,
        amount: Money.fromMinorUnits(1000, Currency.sar),
        date: DateTime(2026, 2, 1),
      )).toNullable()!;

      expect(edited.amount, Money.fromMinorUnits(1000, Currency.sar));
      final row = await (db.select(
        db.financeEntries,
      )..where((t) => t.id.equals(added.id))).getSingle();
      expect(row.currencyCode, 'SAR');
    });
  });
}
