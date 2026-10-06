import 'dart:convert';

import 'package:daftary/core/database/app_database.dart'
    hide FinanceEntry, isNull;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_audit.dart'
    show FinanceAuditChange;
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_daos.dart';

void main() {
  late AppDatabase db;
  late FinanceRepositoryImpl repository;

  // The 22 starter categories are seeded when the database opens, so the
  // ids below are real rows rather than fixtures this test inserts.
  const expenseCategoryId = 'seed_groceries';
  const incomeCategoryId = 'seed_salary';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinanceRepositoryImpl(testFinanceDao(db));
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

  group('change history (022 D2, T063)', () {
    Future<List<FinanceEntryAudit>> auditsOf(String entryId) =>
        (db.select(db.financeEntryAudits)
              ..where((a) => a.financeEntryId.equals(entryId))
              ..orderBy([(a) => OrderingTerm(expression: a.changedAt)]))
            .get();

    Future<FinanceEntry> add({
      String key = 'audit-1',
      String categoryId = expenseCategoryId,
      FinanceEntryType type = FinanceEntryType.expense,
      int minor = 30000,
    }) async => (await repository.addEntry(
      idempotencyKey: key,
      categoryId: categoryId,
      type: type,
      amount: Money.egp(minor),
      date: DateTime(2026, 1, 15),
      note: 'first',
    )).toNullable()!;

    Future<void> tick() =>
        Future<void>.delayed(const Duration(milliseconds: 3));

    test('add appends one `created` row with no previous values', () async {
      final entry = await add();

      final audits = await auditsOf(entry.id);
      expect(audits, hasLength(1));
      expect(audits.single.changeType, 'created');
      expect(audits.single.previousValuesJson, isNull);
    });

    test('a retried add (idempotency key) appends no second row', () async {
      final entry = await add();
      await add();

      expect(await auditsOf(entry.id), hasLength(1));
    });

    test('edit 300 -> 450 appends one `edited` row holding 30000', () async {
      final entry = await add();
      await tick();

      await repository.editEntry(
        entryId: entry.id,
        categoryId: expenseCategoryId,
        amount: const Money.egp(45000),
        date: DateTime(2026, 1, 15),
        note: 'first',
      );

      final audits = await auditsOf(entry.id);
      expect(audits.map((a) => a.changeType), ['created', 'edited']);
      final previous =
          jsonDecode(audits.last.previousValuesJson!) as Map<String, Object?>;
      expect(previous['amountMinorUnits'], 30000);
      expect(previous['currencyCode'], 'EGP');
      expect(previous['type'], 'expense');
      expect(previous['categoryId'], expenseCategoryId);
      // A calendar day, so it reads the same in any time zone.
      expect(previous['date'], '2026-01-15');
      expect(previous['note'], 'first');
    });

    test('editing an expense into an income category keeps the previous '
        'type and category (RF-08)', () async {
      final entry = await add();

      final edited = (await repository.editEntry(
        entryId: entry.id,
        categoryId: incomeCategoryId,
        amount: const Money.egp(30000),
        date: DateTime(2026, 1, 15),
      )).toNullable()!;

      expect(edited.type, FinanceEntryType.income);
      final audits = await auditsOf(entry.id);
      expect(audits.last.changeType, 'edited');
      final previous =
          jsonDecode(audits.last.previousValuesJson!) as Map<String, Object?>;
      expect(previous['type'], 'expense');
      expect(previous['categoryId'], expenseCategoryId);
    });

    test('delete appends one `deleted` row; restore one `restored` row; '
        'a no-op restore appends none', () async {
      final entry = await add();

      await tick();
      await repository.deleteEntry(entry.id);
      await tick();
      await repository.restoreEntry(entry.id);
      await repository.restoreEntry(entry.id);

      final audits = await auditsOf(entry.id);
      expect(audits.map((a) => a.changeType), [
        'created',
        'deleted',
        'restored',
      ]);
    });

    test('a failed edit appends nothing and every audit row is queued as '
        '`finance_entry_audit`', () async {
      final entry = await add();
      await repository.editEntry(
        entryId: entry.id,
        categoryId: 'missing-category',
        amount: const Money.egp(1),
        date: DateTime(2026, 1, 15),
      );
      expect(await auditsOf(entry.id), hasLength(1));

      final outbox = await (db.select(
        db.syncOutboxEntries,
      )..where((o) => o.entityType.equals('finance_entry_audit'))).get();
      expect(outbox, hasLength(1));
      expect(outbox.single.entityId, (await auditsOf(entry.id)).single.id);
    });

    test('audit and entry change commit atomically: if the audit write '
        'fails the entry is unchanged', () async {
      final entry = await add();
      await db.customStatement('DROP TABLE finance_entry_audits');

      final result = await repository.editEntry(
        entryId: entry.id,
        categoryId: expenseCategoryId,
        amount: const Money.egp(99900),
        date: DateTime(2026, 1, 15),
      );

      expect(result.isLeft(), isTrue);
      final row = await (db.select(
        db.financeEntries,
      )..where((t) => t.id.equals(entry.id))).getSingle();
      expect(row.amountMinorUnits, 30000);
    });

    test('a double delete appends exactly one `deleted` row and queues one '
        'audit op for it', () async {
      final entry = await add();

      final first = await repository.deleteEntry(entry.id);
      final second = await repository.deleteEntry(entry.id);

      expect(first.isRight(), isTrue);
      expect(second.isLeft(), isTrue);
      final audits = await auditsOf(entry.id);
      expect(audits.where((a) => a.changeType == 'deleted'), hasLength(1));
    });

    test('an edit of a deleted entry appends nothing', () async {
      final entry = await add();
      await repository.deleteEntry(entry.id);

      final result = await repository.editEntry(
        entryId: entry.id,
        categoryId: expenseCategoryId,
        amount: const Money.egp(1),
        date: DateTime(2026, 1, 15),
      );

      expect(result.isLeft(), isTrue);
      expect((await auditsOf(entry.id)).map((a) => a.changeType).toSet(), {
        'created',
        'deleted',
      });
    });

    test('watchEntryAuditHistory emits the rows oldest first (T069)', () async {
      final entry = await add();
      await tick();
      await repository.editEntry(
        entryId: entry.id,
        categoryId: expenseCategoryId,
        amount: const Money.egp(45000),
        date: DateTime(2026, 1, 15),
      );

      final history = (await repository.watchEntryAuditHistory(entry.id).first)
          .toNullable()!;
      expect(history.map((a) => a.changeType), [
        FinanceAuditChange.created,
        FinanceAuditChange.edited,
      ]);
      expect(history.first.previousValuesJson, isNull);
    });
  });
}
