import 'dart:io';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_daos.dart';

/// 021 T042: the outbox is durable. Changes queued before the app closes
/// are still queued, unchanged, after it reopens — nothing is lost and
/// nothing is silently promoted or reset.
void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('outbox_persistence_');
    file = File('${dir.path}/daftary.sqlite');
  });

  tearDown(() => dir.delete(recursive: true));

  AppDatabase open() => AppDatabase.forTesting(NativeDatabase(file));

  Future<List<SyncOutboxRow>> ops(AppDatabase db) => (db.select(
    db.syncOutboxEntries,
  )..orderBy([(o) => OrderingTerm.asc(o.opId)])).get();

  test(
    'pending operations survive closing and reopening the database',
    () async {
      final at = DateTime(2026, 9, 1);
      var db = open();
      await testPeopleDao(
        db,
      ).insertPerson(id: 'p1', name: 'Mona', createdAt: at);
      await testTransactionsDao(db).insertTransactionIdempotent(
        MoneyTransactionsCompanion.insert(
          id: 't1',
          idempotencyKey: 'k1',
          personId: 'p1',
          amountMinorUnits: 1000,
          direction: 'given',
          kind: 'initial_exchange',
          date: at.millisecondsSinceEpoch,
          createdAt: at.millisecondsSinceEpoch,
        ),
      );
      await testCurrencyDao(db).upsertRate(
        newId: 'rate_USD_EGP',
        currencyCode: 'USD',
        relativeToCurrencyCode: 'EGP',
        rateMicros: 50000000,
        lastUpdatedAtMillis: at.millisecondsSinceEpoch,
      );
      final before = await ops(db);
      expect(before, hasLength(3));
      await db.close();

      db = open();
      addTearDown(db.close);
      final after = await ops(db);

      expect(after, before);
      expect(after.map((o) => o.status), everyElement(OutboxStatus.pending));
      expect(after.map((o) => o.entityType).toSet(), {
        SyncEntityType.person.wire,
        SyncEntityType.moneyTransaction.wire,
        SyncEntityType.exchangeRate.wire,
      });
    },
  );

  test('an in_flight operation stays in_flight across a restart', () async {
    var db = open();
    await testPeopleDao(
      db,
    ).insertPerson(id: 'p1', name: 'Mona', createdAt: DateTime(2026, 9, 1));
    // An upload was under way when the app was killed.
    await db
        .update(db.syncOutboxEntries)
        .write(
          const SyncOutboxEntriesCompanion(
            status: Value(OutboxStatus.inFlight),
          ),
        );
    await db.close();

    db = open();
    addTearDown(db.close);

    // Only the sync engine's resetInFlight (T056) may move it back.
    expect((await ops(db)).single.status, OutboxStatus.inFlight);
  });
}
