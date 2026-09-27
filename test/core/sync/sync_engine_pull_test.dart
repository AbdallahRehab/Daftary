import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/core/sync/sync_engine.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_sync_remote.dart';
import 'fakes/server_rows.dart';
import 'fakes/sync_harness.dart';

/// 021 T069: the pull phase and re-owning, against [FakeSyncRemote].
void main() {
  late SyncHarness h;

  setUp(() => h = SyncHarness());
  tearDown(() => h.close());

  Future<List<PeopleData>> people() => h.db.select(h.db.people).get();

  test('pulls every page until has_more is false (3 pages)', () async {
    for (var i = 0; i < 1100; i++) {
      h.remote.seedServerRow(SyncEntityType.person, personRow('p$i'));
    }
    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);
    expect(h.remote.pullCalls, 3);
    expect(await people(), hasLength(1100));
    expect((await h.state()).lastPulledRevision, 1100);
    expect(
      h.logger.names.where((e) => e == SyncEvent.cursorAdvanced),
      hasLength(3),
    );
    expect(await h.outboxRows(), isEmpty);
  });

  test('a tombstone is applied', () async {
    h.remote.seedServerRow(SyncEntityType.person, personRow('p1'));
    await h.engine.runCycle();
    expect(await people(), hasLength(1));

    h.remote.seedServerRow(
      SyncEntityType.person,
      personRow('p1'),
      deleted: true,
    );
    await h.engine.runCycle();
    expect(await people(), isEmpty);
  });

  test('the cursor persists across a restart', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final remote = FakeSyncRemote();
    final first = SyncHarness(db: db, remote: remote);
    remote.seedServerRow(SyncEntityType.person, personRow('p1'));
    remote.seedServerRow(SyncEntityType.person, personRow('p2'));
    await first.engine.runCycle();
    expect((await first.state()).lastPulledRevision, 2);

    // A new engine on the same database file (the app restarted).
    final restarted = SyncHarness(db: db, remote: remote);
    remote.seedServerRow(SyncEntityType.person, personRow('p3'));
    await restarted.engine.runCycle();
    final started = restarted.logger.events.firstWhere(
      (e) => e.$1 == SyncEvent.downloadStarted,
    );
    expect(started.$2[SyncLogField.revision], 2);
    expect((await restarted.state()).lastPulledRevision, 3);
    expect(await db.select(db.people).get(), hasLength(3));
    await first.connectivity.close();
    await restarted.close();
  });

  test('an unreadable pulled row is recorded, never skipped: the cursor '
      'stays and the cycle backs off with a distinct code', () async {
    h.remote.seedServerRow(SyncEntityType.person, personRow('p1'));
    h.remote.seedServerRow(SyncEntityType.person, {
      ...personRow('p2'),
      'name': 42,
    });
    final outcome = await h.engine.runCycle();
    expect(outcome.result, SyncCycleResult.retryScheduled);
    expect(outcome.errorCode, 'download_unreadable_row');
    final state = await h.state();
    expect(state.lastErrorCode, 'download_unreadable_row');
    expect(state.lastPulledRevision, 0);
    expect(state.consecutiveFailures, 1);
    expect(state.lastSuccessAt, isNull);
    // The page was rolled back as a whole: p1 waits with p2.
    expect(await people(), isEmpty);
    final aborted = h.logger.events.lastWhere(
      (e) => e.$1 == SyncEvent.syncAborted,
    );
    expect(aborted.$2[SyncLogField.errorCode], 'download_unreadable_row');

    // Once the server row is readable again, the next cycle applies both
    // and clears the error.
    h.remote.seedServerRow(SyncEntityType.person, personRow('p2'));
    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);
    expect(await people(), hasLength(2));
    expect((await h.state()).lastErrorCode, isNull);
  });

  test('a pull failure backs off and keeps the cursor', () async {
    h.remote.seedServerRow(SyncEntityType.person, personRow('p1'));
    h.remote.failNextPulls(1);
    final outcome = await h.engine.runCycle();
    expect(outcome.result, SyncCycleResult.retryScheduled);
    expect((await h.state()).lastPulledRevision, 0);
    expect((await h.state()).consecutiveFailures, 1);
    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);
    expect((await h.state()).lastPulledRevision, 1);
  });

  test('owner_id null (fresh database with a kept session) adopts the uid '
      'without re-queueing, then restores the data from cursor 0', () async {
    h.remote.seedServerRow(SyncEntityType.person, personRow('p1'));
    h.remote.seedServerRow(
      SyncEntityType.moneyTransaction,
      transactionRow('t1', personId: 'p1'),
    );
    expect((await h.state()).ownerId, isNull);

    await h.engine.runCycle();
    final state = await h.state();
    expect(state.ownerId, h.auth.uid);
    expect(h.remote.pushCalls, 0);
    expect(await people(), hasLength(1));
    expect(await h.db.select(h.db.moneyTransactions).get(), hasLength(1));
  });

  test('a uid change re-uploads everything to the new account, then pulls '
      'from 0, with 0 duplicates and no local data deleted', () async {
    await h.createPerson('p1');
    await h.createTransaction('t1', personId: 'p1');
    await h.engine.runCycle();
    expect((await h.state()).lastPulledRevision, 2);
    const newUid = '00000000-0000-4000-8000-0000000000bb';

    h.switchAccount(newUid);
    await h.createPerson('p2'); // queued against the old account's base
    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);

    final state = await h.state();
    expect(state.ownerId, newUid);
    expect(h.remote.rowCount(SyncEntityType.person), 2);
    expect(h.remote.rowCount(SyncEntityType.moneyTransaction), 1);
    expect(
      h.remote.duplicateIdempotencyKeys(SyncEntityType.moneyTransaction),
      0,
    );
    expect(await people(), hasLength(2));
    expect(await h.db.select(h.db.moneyTransactions).get(), hasLength(1));
    expect(await h.outboxRows(), isEmpty);
    // The new account's revisions, pulled from 0.
    expect(state.lastPulledRevision, h.remote.lastRevision);
    final meta = await h.metaFor('t1');
    expect(meta!.state, SyncRecordState.synced);
    expect(
      meta.serverRevision,
      h.remote.rowOf(SyncEntityType.moneyTransaction, 't1')!['revision'],
    );

    // The same account again: nothing is re-queued.
    final pushes = h.remote.pushCalls;
    await h.engine.runCycle();
    expect(h.remote.pushCalls, pushes);
  });
}
