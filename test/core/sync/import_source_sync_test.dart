import 'dart:convert';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/sync_engine.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart';
import 'package:daftary/features/finance/data/sync/finance_entry_sync_mapper.dart';
import 'package:daftary/features/transactions/data/sync/money_transaction_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_sync_remote.dart';
import 'fakes/sync_harness.dart';

/// 023 T150 (sync-wire-027 §3, §4, §6): the optional `import_source`
/// provenance on `money_transaction` and `finance_entry`, end to end through
/// the real outbox, engine, applier and conflict resolver, against
/// [FakeSyncRemote] (whose financial business lists include the column,
/// as migration 027's `v_business` arrays do).
///
/// A non-null local provenance is never downgraded by a pull, whether the
/// server row lacks the key (a server before 027) or carries it as null (a
/// row stored before 027, or `keepTheirs` on one).
void main() {
  const txn = SyncEntityType.moneyTransaction;
  const entry = SyncEntityType.financeEntry;
  const txnMapper = MoneyTransactionSyncMapper();
  const entryMapper = FinanceEntrySyncMapper();
  const categoryMapper = FinanceCategorySyncMapper();

  late FakeSyncRemote server;
  late SyncHarness a;
  late SyncHarness b;

  setUp(() {
    server = FakeSyncRemote();
    a = SyncHarness(remote: server);
    b = SyncHarness(remote: server);
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  // --- local writes, the way the DAOs record them -------------------------

  /// A people-ledger record saved by an SMS Add: `source` stays 'manual'
  /// (FR-086), provenance is the separate column.
  Future<void> addSmsTransaction(SyncHarness h, String id) =>
      h.db.transaction(() async {
        await h.db
            .into(h.db.moneyTransactions)
            .insert(
              MoneyTransactionsCompanion.insert(
                id: id,
                idempotencyKey: 'sms-import:$id',
                personId: 'p1',
                amountMinorUnits: 12550,
                direction: 'given',
                kind: 'initialExchange',
                date: 1000,
                createdAt: 1000,
                importSource: const Value('sms'),
              ),
            );
        final row = await h.transaction(id);
        await h.outbox.recordUpsert(txn, id, txnMapper.toWire(row));
      });

  Future<FinanceEntry> financeEntry(SyncHarness h, String id) => (h.db.select(
    h.db.financeEntries,
  )..where((e) => e.id.equals(id))).getSingle();

  Future<void> createCategory(SyncHarness h, String id) =>
      h.db.transaction(() async {
        await h.db
            .into(h.db.financeCategories)
            .insert(
              FinanceCategoriesCompanion.insert(
                id: id,
                name: 'Groceries',
                normalizedName: 'groceries',
                type: 'expense',
                icon: 'rent',
                createdAt: 1000,
                updatedAt: 1000,
              ),
            );
        final row = await (h.db.select(
          h.db.financeCategories,
        )..where((c) => c.id.equals(id))).getSingle();
        await h.outbox.recordUpsert(
          SyncEntityType.financeCategory,
          id,
          categoryMapper.toWire(row),
        );
      });

  /// An own expense saved by an SMS Add.
  Future<void> addSmsEntry(SyncHarness h, String id) =>
      h.db.transaction(() async {
        await h.db
            .into(h.db.financeEntries)
            .insert(
              FinanceEntriesCompanion.insert(
                id: id,
                idempotencyKey: 'sms-import:$id',
                categoryId: 'c1',
                type: 'expense',
                amountMinorUnits: 12550,
                date: 1000,
                createdAt: 1000,
                importSource: const Value('sms'),
              ),
            );
        await h.outbox.recordUpsert(
          entry,
          id,
          entryMapper.toWire(await financeEntry(h, id)),
        );
      });

  /// An ordinary edit through the 1.2 mapper: the column is not touched,
  /// and the push re-sends the existing value.
  Future<void> editTransaction(SyncHarness h, String id, int amount) =>
      h.editTransaction(id, amount: amount);

  /// An edit pushed by a v1.0.1 device: its payload has no `import_source`
  /// (v1.0.1's `toWire` is today's minus that one conditional key).
  Future<void> legacyEditTransaction(SyncHarness h, String id, int amount) =>
      h.db.transaction(() async {
        await (h.db.update(
          h.db.moneyTransactions,
        )..where((t) => t.id.equals(id))).write(
          MoneyTransactionsCompanion(
            amountMinorUnits: Value(amount),
            editedAt: const Value(3000),
          ),
        );
        final wire = txnMapper.toWire(await h.transaction(id))
          ..remove('import_source');
        await h.outbox.recordUpsert(txn, id, wire);
      });

  Future<void> legacyEditEntry(SyncHarness h, String id, int amount) =>
      h.db.transaction(() async {
        await (h.db.update(
          h.db.financeEntries,
        )..where((e) => e.id.equals(id))).write(
          FinanceEntriesCompanion(
            amountMinorUnits: Value(amount),
            editedAt: const Value(3000),
          ),
        );
        final wire = entryMapper.toWire(await financeEntry(h, id))
          ..remove('import_source');
        await h.outbox.recordUpsert(entry, id, wire);
      });

  /// Another device rewrites the server row of [id] at a new revision, as a
  /// pre-027 row looks to a 1.2 pull: [importSource] is either absent
  /// (`absent: true`, a server before 027) or present (`null` after 027).
  void serverRewrite(
    SyncEntityType type,
    String id, {
    required int amount,
    bool absent = false,
  }) {
    final row = Map.of(server.rowOf(type, id)!)
      ..['amount_minor'] = amount
      ..['edited_at'] = '2026-01-05T00:00:00.000Z';
    if (absent) {
      row.remove('import_source');
    } else {
      row['import_source'] = null;
    }
    server.seedServerRow(type, row);
  }

  Future<void> sharedSmsTransaction() async {
    await a.createPerson('p1', name: 'Amal');
    await addSmsTransaction(a, 't1');
    expect(await a.engine.runCycle(), SyncCycleOutcome.completed);
    expect(await b.engine.runCycle(), SyncCycleOutcome.completed);
  }

  Future<void> sharedSmsEntry() async {
    await createCategory(a, 'c1');
    await addSmsEntry(a, 'e1');
    expect(await a.engine.runCycle(), SyncCycleOutcome.completed);
    expect(await b.engine.runCycle(), SyncCycleOutcome.completed);
  }

  group('two devices', () {
    test('A saves an SMS-sourced transaction; B pulls it with provenance, '
        "and source stays 'manual'", () async {
      await sharedSmsTransaction();

      expect(server.rowOf(txn, 't1')!['import_source'], 'sms');
      final pushed = server.committedBatches
          .expand((ops) => ops)
          .singleWhere((op) => op.entityId == 't1');
      expect(pushed.payload['import_source'], 'sms');
      expect(pushed.payload['source'], 'manual');

      final onB = await b.transaction('t1');
      expect(onB.importSource, 'sms');
      expect(onB.source, 'manual');
      expect(onB.amountMinorUnits, 12550);
    });

    test(
      'A saves an SMS-sourced own expense; B pulls it with provenance',
      () async {
        await sharedSmsEntry();

        expect(server.rowOf(entry, 'e1')!['import_source'], 'sms');
        expect((await financeEntry(b, 'e1')).importSource, 'sms');
      },
    );

    test(
      'a manual record carries no key and stays null on both devices',
      () async {
        await a.createPerson('p1');
        await a.createTransaction('t2', personId: 'p1');
        await a.engine.runCycle();
        await b.engine.runCycle();

        final pushed = server.committedBatches
            .expand((ops) => ops)
            .singleWhere((op) => op.entityId == 't2');
        expect(pushed.payload.containsKey('import_source'), isFalse);
        expect(server.rowOf(txn, 't2')!.containsKey('import_source'), isFalse);
        expect((await b.transaction('t2')).importSource, isNull);
      },
    );

    test('an edit on B re-sends the same value and keeps provenance '
        'everywhere', () async {
      await sharedSmsTransaction();
      await editTransaction(b, 't1', 20000);
      expect((await b.opFor('t1'))!.payloadJson, contains('"import_source"'));
      await b.engine.runCycle();
      await a.engine.runCycle();

      expect(server.rowOf(txn, 't1')!['import_source'], 'sms');
      for (final h in [a, b]) {
        final row = await h.transaction('t1');
        expect(row.amountMinorUnits, 20000);
        expect(row.importSource, 'sms');
      }
    });
  });

  group('a pull never downgrades local provenance', () {
    for (final absent in [true, false]) {
      final shape = absent ? 'absent' : 'present and null';

      test('transaction: server key $shape keeps a local sms', () async {
        await sharedSmsTransaction();
        serverRewrite(txn, 't1', amount: 30000, absent: absent);
        expect(await b.engine.runCycle(), SyncCycleOutcome.completed);

        final row = await b.transaction('t1');
        expect(row.amountMinorUnits, 30000, reason: 'the pull was applied');
        expect(row.importSource, 'sms');
      });

      test('finance entry: server key $shape keeps a local sms', () async {
        await sharedSmsEntry();
        serverRewrite(entry, 'e1', amount: 30000, absent: absent);
        expect(await b.engine.runCycle(), SyncCycleOutcome.completed);

        final row = await financeEntry(b, 'e1');
        expect(row.amountMinorUnits, 30000, reason: 'the pull was applied');
        expect(row.importSource, 'sms');
      });
    }
  });

  group('ConflictResolver.keepTheirs', () {
    test(
      "transaction: a server row with a null key keeps a local 'sms'",
      () async {
        await sharedSmsTransaction();
        // Another device's edit lands first, stored as a pre-027 row.
        serverRewrite(txn, 't1', amount: 30000);
        await editTransaction(b, 't1', 40000);
        await b.engine.runCycle();
        final conflict = await b.openConflict('t1');
        expect(conflict, isNotNull);
        expect(
          jsonDecode(conflict!.serverPayloadJson),
          containsPair('import_source', null),
        );

        await b.resolver.keepTheirs(txn, 't1');

        final row = await b.transaction('t1');
        expect(row.amountMinorUnits, 30000, reason: 'theirs was applied');
        expect(row.importSource, 'sms');
      },
    );

    test(
      "finance entry: a server row with a null key keeps a local 'sms'",
      () async {
        await sharedSmsEntry();
        serverRewrite(entry, 'e1', amount: 30000);
        await b.db.transaction(() async {
          await (b.db.update(
            b.db.financeEntries,
          )..where((e) => e.id.equals('e1'))).write(
            const FinanceEntriesCompanion(
              amountMinorUnits: Value(40000),
              editedAt: Value(3000),
            ),
          );
          await b.outbox.recordUpsert(
            entry,
            'e1',
            entryMapper.toWire(await financeEntry(b, 'e1')),
          );
        });
        await b.engine.runCycle();
        expect(await b.openConflict('e1'), isNotNull);

        await b.resolver.keepTheirs(entry, 'e1');

        final row = await financeEntry(b, 'e1');
        expect(row.amountMinorUnits, 30000, reason: 'theirs was applied');
        expect(row.importSource, 'sms');
      },
    );
  });

  group('a legacy (v1.0.1) edit-push', () {
    test('leaves the transaction provenance intact on the server and on '
        'other devices', () async {
      await sharedSmsTransaction();
      await legacyEditTransaction(b, 't1', 50000);
      expect(
        (await b.opFor('t1'))!.payloadJson,
        isNot(contains('import_source')),
      );
      await b.engine.runCycle();
      await a.engine.runCycle();

      final onServer = server.rowOf(txn, 't1')!;
      expect(onServer['amount_minor'], 50000);
      expect(onServer['import_source'], 'sms');
      expect((await a.transaction('t1')).importSource, 'sms');
    });

    test('leaves the finance entry provenance intact on the server and on '
        'other devices', () async {
      await sharedSmsEntry();
      await legacyEditEntry(b, 'e1', 50000);
      await b.engine.runCycle();
      await a.engine.runCycle();

      final onServer = server.rowOf(entry, 'e1')!;
      expect(onServer['amount_minor'], 50000);
      expect(onServer['import_source'], 'sms');
      expect((await financeEntry(a, 'e1')).importSource, 'sms');
    });
  });

  group('offline: Add, then sync later', () {
    test('an SMS Add made offline waits in the outbox with its provenance '
        'and reaches the other device once online', () async {
      a.connectivity.online = false;
      await a.createPerson('p1');
      await addSmsTransaction(a, 't1');
      await createCategory(a, 'c1');
      await addSmsEntry(a, 'e1');

      expect(await a.engine.runCycle(), SyncCycleOutcome.offline);
      expect(server.pushCalls, 0);
      expect((await a.transaction('t1')).importSource, 'sms');
      final queued = {
        for (final op in await a.outboxRows())
          op.entityId: jsonDecode(op.payloadJson) as Map<String, Object?>,
      };
      expect(queued['t1']!['import_source'], 'sms');
      expect(queued['e1']!['import_source'], 'sms');

      a.connectivity.online = true;
      expect(await a.engine.runCycle(), SyncCycleOutcome.completed);
      expect(await a.outboxRows(), isEmpty);
      expect(await b.engine.runCycle(), SyncCycleOutcome.completed);

      expect((await b.transaction('t1')).importSource, 'sms');
      expect((await financeEntry(b, 'e1')).importSource, 'sms');
    });
  });

  /// sync-wire-027 §6 case 7, as clarified in decisions/phase11a (#5): the
  /// SAME op is answered from the ledger (`already_applied`); only the same
  /// create under a NEW op id reaches the "same create" comparison, which
  /// now includes `import_source`, and answers `conflict`.
  group('create retry spanning the 027 deploy', () {
    test('same op id: already_applied from the ledger; local provenance '
        'kept', () async {
      await a.createPerson('p1');
      await a.engine.runCycle();
      await addSmsTransaction(a, 't1');
      server.dropResponseAfterCommit();
      expect(
        (await a.engine.runCycle()).result,
        SyncCycleResult.retryScheduled,
      );
      // The server predated 027 and dropped the key.
      server.rowOf(txn, 't1')!['import_source'] = null;
      final opId = (await a.opFor('t1'))!.opId;

      a.skipBackoff();
      expect(await a.engine.runCycle(), SyncCycleOutcome.completed);

      expect(server.ledgerHas(opId), isTrue);
      expect(await a.openConflict('t1'), isNull);
      expect(await a.outboxRows(), isEmpty);
      expect(server.rowOf(txn, 't1')!['import_source'], isNull);
      expect((await a.transaction('t1')).importSource, 'sms');
    });

    test(
      "new op id, key differs: conflict; keepTheirs keeps the local 'sms'",
      () async {
        await a.createPerson('p1');
        await a.engine.runCycle();
        await addSmsTransaction(a, 't1');
        // The same create already stored by a pre-027 server (key dropped),
        // with no acknowledgement on this device.
        final wire = txnMapper.toWire(await a.transaction('t1'))
          ..remove('import_source');
        server.seedServerRow(txn, wire);

        await a.engine.runCycle();

        expect((await a.opFor('t1'))!.status, OutboxStatus.blockedConflict);
        final conflict = await a.openConflict('t1');
        expect(conflict, isNotNull);
        expect(
          jsonDecode(conflict!.serverPayloadJson)['import_source'],
          isNull,
        );

        await a.resolver.keepTheirs(txn, 't1');
        expect((await a.transaction('t1')).importSource, 'sms');
        expect(await a.openConflict('t1'), isNull);
      },
    );

    test(
      'control: the same create with no provenance is already_applied',
      () async {
        await a.createPerson('p1');
        await a.engine.runCycle();
        await a.createTransaction('t1', personId: 'p1');
        server.seedServerRow(txn, txnMapper.toWire(await a.transaction('t1')));

        expect(await a.engine.runCycle(), SyncCycleOutcome.completed);
        expect(await a.openConflict('t1'), isNull);
        expect(await a.outboxRows(), isEmpty);
      },
    );
  });
}
