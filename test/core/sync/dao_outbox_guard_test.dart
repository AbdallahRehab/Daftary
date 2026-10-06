import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/currency/data/datasources/currency_dao.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/people/data/datasources/people_dao.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_daos.dart';

/// 021 T024: every mutating DAO method on a synced table queues exactly one
/// outbox operation of the expected entity and op type (plan.md §7). The
/// only exception is an idempotent insert that found its key already
/// stored: that no-op records nothing.
void main() {
  late AppDatabase db;
  late PeopleDao people;
  late TransactionsDao transactions;
  late FinanceDao finance;
  late CurrencyDao currency;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    people = testPeopleDao(db);
    transactions = testTransactionsDao(db);
    finance = testFinanceDao(db);
    currency = testCurrencyDao(db);
  });

  tearDown(() => db.close());

  final at = DateTime(2026, 9, 1);

  Future<List<SyncOutboxRow>> ops() => db.select(db.syncOutboxEntries).get();

  Future<void> clearOutbox() => db.delete(db.syncOutboxEntries).go();

  /// Runs [write] against an empty outbox and asserts it queued exactly one
  /// [type] operation of [opType].
  Future<void> expectOneOp(
    Future<void> Function() write,
    SyncEntityType type,
    OutboxOpType opType,
  ) async {
    await clearOutbox();
    await write();
    final queued = await ops();
    expect(queued, hasLength(1));
    expect(queued.single.entityType, type.wire);
    expect(queued.single.opType, opType.wire);
    expect(queued.single.status, OutboxStatus.pending);
  }

  Future<void> seedPerson(String id) =>
      people.insertPerson(id: id, name: 'Person $id', createdAt: at);

  MoneyTransactionsCompanion transaction(String id, String key) =>
      MoneyTransactionsCompanion.insert(
        id: id,
        idempotencyKey: key,
        personId: 'p1',
        amountMinorUnits: 1000,
        direction: 'given',
        kind: 'initial_exchange',
        date: at.millisecondsSinceEpoch,
        createdAt: at.millisecondsSinceEpoch,
      );

  FinanceCategoriesCompanion category(String id) =>
      FinanceCategoriesCompanion.insert(
        id: id,
        name: 'Food $id',
        normalizedName: 'food $id',
        type: 'expense',
        icon: 'restaurant',
        createdAt: at.millisecondsSinceEpoch,
        updatedAt: at.millisecondsSinceEpoch,
      );

  FinanceEntriesCompanion entry(String id, String key) =>
      FinanceEntriesCompanion.insert(
        id: id,
        idempotencyKey: key,
        categoryId: 'c1',
        type: 'expense',
        amountMinorUnits: 2500,
        date: at.millisecondsSinceEpoch,
        createdAt: at.millisecondsSinceEpoch,
      );

  test(
    'a fresh database has an empty outbox (seeding records nothing)',
    () async {
      expect(await ops(), isEmpty);
    },
  );

  group('PeopleDao', () {
    test('insertPerson queues a person upsert', () async {
      await expectOneOp(
        () => seedPerson('p1'),
        SyncEntityType.person,
        OutboxOpType.upsert,
      );
    });

    test('updatePerson queues a person upsert', () async {
      await seedPerson('p1');
      await expectOneOp(
        () => people.updatePerson(id: 'p1', name: 'Renamed', updatedAt: at),
        SyncEntityType.person,
        OutboxOpType.upsert,
      );
    });

    test('setArchived queues a person upsert', () async {
      await seedPerson('p1');
      await expectOneOp(
        () => people.setArchived('p1', true, at),
        SyncEntityType.person,
        OutboxOpType.upsert,
      );
    });

    test('deletePerson queues a person delete', () async {
      await seedPerson('p1');
      await expectOneOp(
        () => people.deletePerson('p1'),
        SyncEntityType.person,
        OutboxOpType.delete,
      );
      expect(await people.getPersonById('p1'), isNull);
    });
  });

  group('TransactionsDao', () {
    setUp(() => seedPerson('p1'));

    test('insertTransactionIdempotent queues an upsert for a new key, and '
        'nothing for a repeated key', () async {
      await expectOneOp(
        () => transactions.insertTransactionIdempotent(transaction('t1', 'k1')),
        SyncEntityType.moneyTransaction,
        OutboxOpType.upsert,
      );

      await clearOutbox();
      final again = await transactions.insertTransactionIdempotent(
        transaction('t2', 'k1'),
      );
      expect(again.id, 't1');
      expect(await ops(), isEmpty);
    });

    test('updateTransaction queues a money_transaction upsert', () async {
      await transactions.insertTransactionIdempotent(transaction('t1', 'k1'));
      await expectOneOp(
        () => transactions.updateTransaction(
          't1',
          const MoneyTransactionsCompanion(amountMinorUnits: Value(2000)),
        ),
        SyncEntityType.moneyTransaction,
        OutboxOpType.upsert,
      );
    });

    test('softDelete queues a money_transaction upsert', () async {
      await transactions.insertTransactionIdempotent(transaction('t1', 'k1'));
      await expectOneOp(
        () => transactions.softDelete('t1', at),
        SyncEntityType.moneyTransaction,
        OutboxOpType.upsert,
      );
    });

    test('insertAuditEntry queues a transaction_audit upsert', () async {
      await transactions.insertTransactionIdempotent(transaction('t1', 'k1'));
      await expectOneOp(
        () => transactions.insertAuditEntry(
          TransactionAuditEntriesCompanion.insert(
            id: 'a1',
            transactionId: 't1',
            changeType: 'created',
            changedAt: at.millisecondsSinceEpoch,
          ),
        ),
        SyncEntityType.transactionAudit,
        OutboxOpType.upsert,
      );
    });
  });

  group('FinanceDao', () {
    test('insertCategory queues a finance_category upsert', () async {
      await expectOneOp(
        () => finance.insertCategory(category('c1')),
        SyncEntityType.financeCategory,
        OutboxOpType.upsert,
      );
    });

    test('updateCategory queues a finance_category upsert', () async {
      await finance.insertCategory(category('c1'));
      await expectOneOp(
        () => finance.updateCategory(
          'c1',
          const FinanceCategoriesCompanion(name: Value('Groceries')),
        ),
        SyncEntityType.financeCategory,
        OutboxOpType.upsert,
      );
    });

    test('archiveCategory queues a finance_category upsert', () async {
      await finance.insertCategory(category('c1'));
      await expectOneOp(
        () => finance.archiveCategory('c1', at),
        SyncEntityType.financeCategory,
        OutboxOpType.upsert,
      );
    });

    test('deleteCategory queues a finance_category delete', () async {
      await finance.insertCategory(category('c1'));
      await expectOneOp(
        () => finance.deleteCategory('c1'),
        SyncEntityType.financeCategory,
        OutboxOpType.delete,
      );
      expect(await finance.getCategoryById('c1'), isNull);
    });

    group('entries', () {
      setUp(() => finance.insertCategory(category('c1')));

      EntryAuditDraft audit(String change) =>
          EntryAuditDraft(id: 'a-$change', changeType: change, changedAt: 1);

      /// 022 D2: every entry write queues the entry upsert and, from the
      /// same transaction, one `finance_entry_audit` upsert.
      Future<void> expectEntryAndAuditOps(Future<void> Function() write) async {
        await clearOutbox();
        await write();
        final queued = await ops();
        expect(
          queued.map((o) => '${o.entityType}:${o.opType}').toList()..sort(),
          [
            '${SyncEntityType.financeEntryAudit.wire}:upsert',
            '${SyncEntityType.financeEntry.wire}:upsert',
          ]..sort(),
        );
        expect(queued.every((o) => o.status == OutboxStatus.pending), isTrue);
      }

      test('insertEntryIdempotent queues an upsert for a new key, and '
          'nothing for a repeated key', () async {
        await expectEntryAndAuditOps(
          () => finance.insertEntryIdempotent(
            entry('e1', 'k1'),
            audit: audit('created'),
          ),
        );

        await clearOutbox();
        final again = await finance.insertEntryIdempotent(
          entry('e2', 'k1'),
          audit: audit('created2'),
        );
        expect(again.id, 'e1');
        expect(await ops(), isEmpty);
      });

      test('updateEntry queues a finance_entry upsert', () async {
        await finance.insertEntryIdempotent(
          entry('e1', 'k1'),
          audit: audit('created'),
        );
        await expectEntryAndAuditOps(
          () => finance.updateEntry(
            'e1',
            const FinanceEntriesCompanion(amountMinorUnits: Value(9900)),
            audit: (_) => audit('edited'),
          ),
        );
      });

      test('softDeleteEntry queues a finance_entry upsert', () async {
        await finance.insertEntryIdempotent(
          entry('e1', 'k1'),
          audit: audit('created'),
        );
        await expectEntryAndAuditOps(
          () => finance.softDeleteEntry('e1', at, audit: audit('deleted')),
        );
      });

      test('restoreEntry queues a finance_entry upsert', () async {
        await finance.insertEntryIdempotent(
          entry('e1', 'k1'),
          audit: audit('created'),
        );
        await finance.softDeleteEntry('e1', at, audit: audit('deleted'));
        await expectEntryAndAuditOps(
          () => finance.restoreEntry('e1', audit: audit('restored')),
        );
      });
    });
  });

  group('CurrencyDao', () {
    test('upsertPrimary queues a primary_currency upsert', () async {
      await expectOneOp(
        () => currency.upsertPrimary(
          currencyCode: 'USD',
          updatedAtMillis: at.millisecondsSinceEpoch,
        ),
        SyncEntityType.primaryCurrency,
        OutboxOpType.upsert,
      );
    });

    test('upsertRate queues an exchange_rate upsert, on insert and on '
        'overwrite', () async {
      Future<void> save(int micros) => currency.upsertRate(
        newId: 'rate_USD_EGP',
        currencyCode: 'USD',
        relativeToCurrencyCode: 'EGP',
        rateMicros: micros,
        lastUpdatedAtMillis: at.millisecondsSinceEpoch,
      );
      await expectOneOp(
        () => save(50000000),
        SyncEntityType.exchangeRate,
        OutboxOpType.upsert,
      );
      await expectOneOp(
        () => save(51000000),
        SyncEntityType.exchangeRate,
        OutboxOpType.upsert,
      );
    });

    test('deleteRatesFrom queues one exchange_rate delete per row', () async {
      for (final relative in ['EGP', 'EUR']) {
        await currency.upsertRate(
          newId: 'rate_USD_$relative',
          currencyCode: 'USD',
          relativeToCurrencyCode: relative,
          rateMicros: 1000000,
          lastUpdatedAtMillis: at.millisecondsSinceEpoch,
        );
      }
      await clearOutbox();

      final deleted = await currency.deleteRatesFrom('USD');

      expect(deleted, 2);
      final queued = await ops();
      expect(queued, hasLength(2));
      expect(queued.map((o) => (o.entityType, o.opType, o.entityId)).toSet(), {
        (SyncEntityType.exchangeRate.wire, 'delete', 'rate_USD_EGP'),
        (SyncEntityType.exchangeRate.wire, 'delete', 'rate_USD_EUR'),
      });
    });
  });
}
