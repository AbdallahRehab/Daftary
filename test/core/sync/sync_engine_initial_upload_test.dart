import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/sync_bootstrap.dart';
import 'package:daftary/core/sync/sync_engine.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart'
    show isPristineSeed;
import 'package:flutter_test/flutter_test.dart';

import 'fakes/sync_harness.dart';

/// 021 T065: an upgraded device uploads its existing data once, resumes
/// after an interruption, and marks the initial upload complete only at
/// the end.
void main() {
  const people = 10;
  const transactions = 5000;
  late SyncHarness h;

  setUp(() async {
    h = SyncHarness();
    final db = h.db;
    await db.batch((batch) {
      batch.insertAll(db.people, [
        for (var p = 0; p < people; p++)
          PeopleCompanion.insert(
            id: 'p$p',
            name: 'P$p',
            normalizedName: 'p$p',
            createdAt: 1,
            updatedAt: 1,
          ),
      ]);
      batch.insertAll(db.moneyTransactions, [
        for (var t = 0; t < transactions; t++)
          MoneyTransactionsCompanion.insert(
            id: 't$t',
            idempotencyKey: 'k$t',
            personId: 'p${t % people}',
            amountMinorUnits: 100 + t,
            direction: 'given',
            kind: 'initialExchange',
            date: 1700000000000 + t,
            createdAt: 1700000000000 + t,
          ),
      ]);
    });
    final queued = await SyncBootstrap(
      realMapperRegistry(),
      h.logger,
      h.clock,
      isPristineSeed: isPristineSeed,
    ).enqueueExistingDataIfNeeded(db);
    expect(queued, people + transactions);
  });

  tearDown(() => h.close());

  Future<void> expectServerMatchesLocal() async {
    expect(h.remote.rowCount(SyncEntityType.person), people);
    expect(h.remote.rowCount(SyncEntityType.moneyTransaction), transactions);
    expect(
      h.remote.duplicateIdempotencyKeys(SyncEntityType.moneyTransaction),
      0,
    );
    expect(await h.outboxRows(), isEmpty);
  }

  test('a failure at batch 20 resumes on the next cycle; done only at the '
      'end', () async {
    h.remote.failOnCall(20);

    final first = await h.engine.runCycle();
    expect(first.result, SyncCycleResult.retryScheduled);
    expect(h.remote.committedBatches, hasLength(19));
    expect((await h.state()).initialUploadDone, isFalse);
    expect(await h.outboxRows(), hasLength(people + transactions - 1900));

    h.skipBackoff();
    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);
    // 51 batches in total: nothing that was acknowledged is sent again.
    expect(h.remote.committedBatches, hasLength(51));
    await expectServerMatchesLocal();
    expect((await h.state()).initialUploadDone, isTrue);

    final counts = {
      for (final (e, f) in h.logger.events)
        if (e == SyncEvent.uploadSuccess && f[SyncLogField.entityType] != null)
          f[SyncLogField.entityType]: f[SyncLogField.count],
    };
    expect(counts['person'], people);
    expect(counts['money_transaction'], transactions);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a response lost at batch 20 is replayed: 0 duplicates', () async {
    h.remote.dropResponseOnCall(20);
    expect((await h.engine.runCycle()).result, SyncCycleResult.retryScheduled);
    // Batch 20 committed on the server although the device never heard.
    expect(h.remote.rowCount(SyncEntityType.moneyTransaction), 2000 - people);
    expect((await h.state()).initialUploadDone, isFalse);

    h.skipBackoff();
    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);
    await expectServerMatchesLocal();
    expect((await h.state()).initialUploadDone, isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('initial_upload_done stays false while any operation is left', () async {
    // A permanently rejected transaction keeps the upload incomplete.
    await h.db.customStatement(
      "UPDATE sync_outbox SET payload_json = "
      "replace(payload_json, '\"amount_minor\":\"100\"', '\"amount_minor\":\"0\"') "
      "WHERE entity_id = 't0'",
    );
    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);
    expect((await h.state()).initialUploadDone, isFalse);
    expect((await h.opFor('t0'))!.status, 'failed');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
