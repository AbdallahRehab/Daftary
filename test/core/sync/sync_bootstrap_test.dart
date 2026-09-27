import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/local/sync_local_store.dart';
import 'package:daftary/core/sync/sync_bootstrap.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:daftary/core/sync/sync_mapper_registry.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart'
    show isPristineSeed;
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/data/sync/money_transaction_sync_mapper.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/sync_harness.dart';
import 'fakes/sync_test_doubles.dart';

/// 021 T064: the one-time enqueue of pre-existing data (plan §16).
void main() {
  late AppDatabase db;
  late RecordingSyncLogger logger;

  SyncBootstrap bootstrap([SyncMapperRegistry? mappers]) => SyncBootstrap(
    mappers ?? realMapperRegistry(),
    logger,
    FakeClock(),
    isPristineSeed: isPristineSeed,
  );

  Future<int> outboxCount() async =>
      (await db.select(db.syncOutboxEntries).get()).length;

  /// Existing (pre-sync) data: 3 people, 6 transactions (1 soft-deleted),
  /// 6 audits, 4 seeded categories — 3 pristine and 1 renamed — plus a
  /// custom one, 2 entries, 1 rate and the primary currency.
  Future<int> seedExistingData() async {
    // Opening runs the seed (22 categories); keep 4 of them.
    await db.customStatement(
      "DELETE FROM finance_categories WHERE id NOT IN "
      "('seed_rent', 'seed_water', 'seed_phone', 'seed_salary')",
    );
    await db.customStatement(
      "UPDATE finance_categories SET name = 'Home rent' WHERE id = 'seed_rent'",
    );
    await db
        .into(db.financeCategories)
        .insert(
          FinanceCategoriesCompanion.insert(
            id: 'c1',
            name: 'Pets',
            normalizedName: 'pets',
            type: 'expense',
            icon: 'other',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    for (var p = 0; p < 3; p++) {
      await db
          .into(db.people)
          .insert(
            PeopleCompanion.insert(
              id: 'p$p',
              name: 'P$p',
              normalizedName: 'p$p',
              createdAt: 1,
              updatedAt: 1,
            ),
          );
    }
    for (var t = 0; t < 6; t++) {
      await db
          .into(db.moneyTransactions)
          .insert(
            MoneyTransactionsCompanion.insert(
              id: 't$t',
              idempotencyKey: 'k$t',
              personId: 'p${t % 3}',
              amountMinorUnits: 1000 * (t + 1),
              direction: t.isEven ? 'given' : 'received',
              kind: t < 3 ? 'initialExchange' : 'repayment',
              date: 1700000000000 + t,
              createdAt: 1700000000000 + t,
              deletedAt: Value(t == 5 ? 1700000009999 : null),
            ),
          );
      await db
          .into(db.transactionAuditEntries)
          .insert(
            TransactionAuditEntriesCompanion.insert(
              id: 'a$t',
              transactionId: 't$t',
              changeType: 'created',
              changedAt: 1700000000000 + t,
            ),
          );
    }
    for (var e = 0; e < 2; e++) {
      await db
          .into(db.financeEntries)
          .insert(
            FinanceEntriesCompanion.insert(
              id: 'e$e',
              idempotencyKey: 'ek$e',
              categoryId: 'c1',
              type: 'expense',
              amountMinorUnits: 700,
              date: 1700000000000,
              createdAt: 1700000000000,
            ),
          );
    }
    await db
        .into(db.exchangeRates)
        .insert(
          ExchangeRatesCompanion.insert(
            id: 'rate_USD_EGP',
            currencyCode: 'USD',
            relativeToCurrencyCode: 'EGP',
            rateMicros: 48500000,
            lastUpdatedAt: 1,
          ),
        );
    await db
        .into(db.primaryCurrencySettings)
        .insert(
          PrimaryCurrencySettingsCompanion.insert(
            id: 'singleton',
            updatedAt: 1,
          ),
        );
    // Total synced rows N = 3 + 6 + 6 + 5 categories + 2 + 1 + 1 = 24;
    // the 3 pristine seeds are skipped.
    return 24 - 3;
  }

  setUp(() async {
    logger = RecordingSyncLogger();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  test('N synced rows with 3 pristine seeds give N − 3 upserts, rank '
      'ordered, never-synced, with pending meta', () async {
    final expected = await seedExistingData();
    expect(await bootstrap().enqueueExistingDataIfNeeded(db), expected);

    final ops = await (db.select(
      db.syncOutboxEntries,
    )..orderBy([(o) => OrderingTerm.asc(o.rowId)])).get();
    expect(ops, hasLength(expected));
    expect(ops.every((o) => o.opType == 'upsert'), isTrue);
    expect(ops.every((o) => o.baseRevision == null), isTrue);
    expect(ops.every((o) => o.status == 'pending'), isTrue);
    final ranks = [for (final o in ops) o.dependsOnRank];
    expect(ranks, [...ranks]..sort());
    final ids = {for (final o in ops) o.entityId};
    expect(ids, containsAll(['seed_rent', 'c1', 't5', 'rate_USD_EGP']));
    expect(ids, isNot(contains('seed_water')));
    expect(ids, isNot(contains('seed_salary')));

    final meta = await db.select(db.syncRecordMeta).get();
    expect(meta, hasLength(expected));
    expect(meta.every((m) => m.state == 'pending'), isTrue);

    final state = await (db.select(db.syncState)).getSingle();
    expect(state.bootstrapEnqueued, isTrue);
    expect(state.initialUploadDone, isFalse);

    final logged = {
      for (final (e, f) in logger.events)
        if (e == SyncEvent.migrationEnqueued)
          f[SyncLogField.entityType]: f[SyncLogField.count],
    };
    expect(logged['money_transaction'], 6);
    expect(logged['finance_category'], 2);
  });

  test('a second open adds nothing', () async {
    final expected = await seedExistingData();
    await bootstrap().enqueueExistingDataIfNeeded(db);
    expect(await bootstrap().enqueueExistingDataIfNeeded(db), 0);
    expect(await outboxCount(), expected);
  });

  test('a drained outbox with initial_upload_done still false re-enqueues '
      'nothing', () async {
    await seedExistingData();
    await bootstrap().enqueueExistingDataIfNeeded(db);
    await db.delete(db.syncOutboxEntries).go();
    expect(
      (await db.select(db.syncState).getSingle()).initialUploadDone,
      isFalse,
    );
    expect(await bootstrap().enqueueExistingDataIfNeeded(db), 0);
    expect(await outboxCount(), 0);
  });

  test('a crash mid-transaction leaves 0 rows; the next open queues them '
      'all', () async {
    final expected = await seedExistingData();
    final crashing = SyncMapperRegistry([
      for (final type in SyncEntityType.values)
        if (type == SyncEntityType.moneyTransaction)
          const _CrashingTransactionMapper()
        else
          realMapperRegistry().mapperFor(type),
    ]);
    await expectLater(
      bootstrap(crashing).enqueueExistingDataIfNeeded(db),
      throwsStateError,
    );
    expect(await outboxCount(), 0);
    expect(await db.select(db.syncRecordMeta).get(), isEmpty);
    expect(
      (await db.select(db.syncState).getSingleOrNull())?.bootstrapEnqueued ??
          false,
      isFalse,
    );

    expect(await bootstrap().enqueueExistingDataIfNeeded(db), expected);
  });

  test('the bootstrap runs from beforeOpen, after the seed', () async {
    final raw = AppDatabase.forTesting(
      NativeDatabase.memory(),
      syncBootstrap: bootstrap(),
    );
    addTearDown(raw.close);
    // A fresh install: only pristine seeds exist, so nothing is queued.
    expect(await raw.select(raw.syncOutboxEntries).get(), isEmpty);
    final state = await raw.select(raw.syncState).getSingle();
    expect(state.id, syncStateId);
    expect(state.bootstrapEnqueued, isTrue);
    expect(await raw.select(raw.financeCategories).get(), hasLength(22));
  });

  test('balances and the overview are identical before and after', () async {
    await seedExistingData();
    final repo = TransactionsRepositoryImpl(TransactionsDao(db), db);
    final overview = await repo.getOverview();
    final balances = await repo.getPersonBalances(['p0', 'p1', 'p2']);

    await bootstrap().enqueueExistingDataIfNeeded(db);

    expect(await repo.getOverview(), overview);
    Map<String, Object?> unwrap(Object either) =>
        (either as dynamic).toNullable() as Map<String, Object?>;
    final after = await repo.getPersonBalances(['p0', 'p1', 'p2']);
    expect(unwrap(after), unwrap(balances));
    expect(unwrap(after), hasLength(3));
  });
}

class _CrashingTransactionMapper extends MoneyTransactionSyncMapper {
  const _CrashingTransactionMapper();

  @override
  Map<String, Object?> toWire(MoneyTransaction row) {
    if (row.id == 't4') throw StateError('simulated crash');
    return super.toWire(row);
  }
}
