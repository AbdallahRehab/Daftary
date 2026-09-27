import 'dart:convert';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/currency/data/sync/exchange_rate_sync_mapper.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_sync_remote.dart';
import 'fakes/sync_harness.dart';

/// 021 T075: two devices of the same account, each with its own database,
/// sharing one server. No version of a financial record is ever lost.
void main() {
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

  const txn = SyncEntityType.moneyTransaction;

  Future<void> syncBoth() async {
    await a.engine.runCycle();
    await b.engine.runCycle();
    await a.engine.runCycle();
  }

  Future<PeopleData?> person(SyncHarness h, String id) => (h.db.select(
    h.db.people,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<FinanceCategory> category(SyncHarness h, String id) => (h.db.select(
    h.db.financeCategories,
  )..where((c) => c.id.equals(id))).getSingle();

  /// A transaction t1 of person p1, known to both devices.
  Future<void> sharedTransaction() async {
    await a.createPerson('p1', name: 'Amal');
    await a.createTransaction('t1', personId: 'p1', amount: 1000);
    await syncBoth();
    expect((await b.transaction('t1')).amountMinorUnits, 1000);
  }

  test('both edit the same transaction: the second gets a conflict, and '
      'after resolution both converge', () async {
    await sharedTransaction();
    await a.editTransaction('t1', amount: 2000);
    await a.engine.runCycle();
    await b.editTransaction('t1', amount: 3000);
    await b.engine.runCycle();

    expect((await b.opFor('t1'))!.status, OutboxStatus.blockedConflict);
    expect(await b.openConflict('t1'), isNotNull);
    expect(await a.openConflict('t1'), isNull);

    await b.resolver.keepMine(txn, 't1');
    await syncBoth();

    expect((await a.transaction('t1')).amountMinorUnits, 3000);
    expect((await b.transaction('t1')).amountMinorUnits, 3000);
    expect(server.rowOf(txn, 't1')!['amount_minor'], 3000);
    // The discarded 2000 is kept, and reached both devices.
    for (final h in [a, b]) {
      final resolution = (await h.resolutions()).single;
      expect(resolution.chosenSide, 'local');
      expect(jsonDecode(resolution.discardedValuesJson)['amount_minor'], 2000);
    }
    expect(await a.outboxRows(), isEmpty);
    expect(await b.outboxRows(), isEmpty);
  });

  test('one deletes while the other edits a transaction: a conflict; keep '
      'theirs converges on the delete', () async {
    await sharedTransaction();
    await a.softDeleteTransaction('t1');
    await a.engine.runCycle();
    await b.editTransaction('t1', amount: 5000);
    await b.engine.runCycle();

    expect(await b.openConflict('t1'), isNotNull);
    await b.resolver.keepTheirs(txn, 't1');
    await syncBoth();

    expect((await a.transaction('t1')).deletedAt, isNotNull);
    expect((await b.transaction('t1')).deletedAt, isNotNull);
    final resolution = (await a.resolutions()).single;
    expect(resolution.chosenSide, 'server');
    // B's edit is not lost: it is the discarded version.
    expect(jsonDecode(resolution.discardedValuesJson)['amount_minor'], '5000');
  });

  test('both edit the same person: last write wins and they converge, with '
      'no conflict', () async {
    await a.createPerson('p1', name: 'Amal');
    await syncBoth();
    await a.renamePerson('p1', 'Amal A');
    await a.engine.runCycle();
    await b.renamePerson('p1', 'Amal B');
    await syncBoth();

    expect((await person(a, 'p1'))!.name, 'Amal B');
    expect((await person(b, 'p1'))!.name, 'Amal B');
    expect(await a.db.select(a.db.syncConflicts).get(), isEmpty);
    expect(await b.db.select(b.db.syncConflicts).get(), isEmpty);
  });

  test('A deletes a person while B edits it: the person is restored', () async {
    await a.createPerson('p1', name: 'Amal');
    await syncBoth();

    // A's delete reaches the server first; B's later edit restores it.
    await a.deletePerson('p1');
    await a.engine.runCycle();
    expect(await person(a, 'p1'), isNull);
    await b.renamePerson('p1', 'Amal (B)');
    await syncBoth();
    expect((await person(a, 'p1'))!.name, 'Amal (B)');
    expect((await person(b, 'p1'))!.name, 'Amal (B)');

    // B's edit reaches the server first; A's stale delete is superseded.
    await b.renamePerson('p1', 'Amal (B2)');
    await b.engine.runCycle();
    await a.deletePerson('p1');
    await a.engine.runCycle();
    expect((await person(a, 'p1'))!.name, 'Amal (B2)');
    expect(server.rowOf(SyncEntityType.person, 'p1')!['deleted_at'], isNull);
  });

  test('both create the USD→EGP rate: 1 row', () async {
    Future<void> createRate(SyncHarness h, int micros) =>
        h.db.transaction(() async {
          final id = ExchangeRateSyncMapper.idFor('USD', 'EGP');
          await h.db
              .into(h.db.exchangeRates)
              .insert(
                ExchangeRatesCompanion.insert(
                  id: id,
                  currencyCode: 'USD',
                  relativeToCurrencyCode: 'EGP',
                  rateMicros: micros,
                  lastUpdatedAt: 1000,
                ),
              );
          final row = await h.db.select(h.db.exchangeRates).getSingle();
          await h.outbox.recordUpsert(
            SyncEntityType.exchangeRate,
            id,
            const ExchangeRateSyncMapper().toWire(row),
          );
        });

    await createRate(a, 50000000);
    await createRate(b, 51000000);
    await syncBoth();

    expect(server.rowCount(SyncEntityType.exchangeRate), 1);
    final aRates = await a.db.select(a.db.exchangeRates).get();
    final bRates = await b.db.select(b.db.exchangeRates).get();
    expect(aRates, hasLength(1));
    expect(bRates, hasLength(1));
    expect(aRates.single.rateMicros, bRates.single.rateMicros);
  });

  test('both keep the pristine seeds while one renames "Rent": the rename '
      'survives', () async {
    final rent = await category(a, 'seed_rent');
    expect(isPristineSeed(rent), isTrue);
    await a.db.transaction(() async {
      await (a.db.update(
        a.db.financeCategories,
      )..where((c) => c.id.equals('seed_rent'))).write(
        const FinanceCategoriesCompanion(
          name: Value('Housing'),
          normalizedName: Value('housing'),
          updatedAt: Value(5000),
        ),
      );
      await a.outbox.recordUpsert(
        SyncEntityType.financeCategory,
        'seed_rent',
        const FinanceCategorySyncMapper().toWire(
          await category(a, 'seed_rent'),
        ),
      );
    });
    await syncBoth();
    await b.engine.runCycle();

    expect((await category(a, 'seed_rent')).name, 'Housing');
    expect((await category(b, 'seed_rent')).name, 'Housing');
    expect(
      server.rowOf(SyncEntityType.financeCategory, 'seed_rent')!['name'],
      'Housing',
    );
    // B never uploaded its seeds.
    expect(server.rowCount(SyncEntityType.financeCategory), 1);
  });
}
