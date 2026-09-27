import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/remote/sync_error_mapper.dart';
import 'package:daftary/core/sync/sync_engine.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/sync_harness.dart';

/// 021 T058: the push phase of the engine, against [FakeSyncRemote].
void main() {
  late SyncHarness h;

  setUp(() => h = SyncHarness());
  tearDown(() => h.close());

  Future<SyncCycleOutcome> cycle({bool ignoreBackoff = false}) =>
      h.engine.runCycle(ignoreBackoff: ignoreBackoff);

  group('early returns send nothing', () {
    test('not configured → disabled', () async {
      h.supabase.configured = false;
      await h.createPerson('p1');
      expect(await cycle(), SyncCycleOutcome.disabled);
      expect(h.remote.pushCalls, 0);
      expect(h.auth.ensureCalls, 0);
    });

    test('switched off → disabled', () async {
      await h.store.writeState((s) => s.copyWith(enabled: false));
      await h.createPerson('p1');
      expect(await cycle(), SyncCycleOutcome.disabled);
      expect(h.remote.pushCalls, 0);
    });

    test('no network → offline', () async {
      h.connectivity.online = false;
      await h.createPerson('p1');
      expect(await cycle(), SyncCycleOutcome.offline);
      expect(h.remote.pushCalls, 0);
      expect(h.auth.ensureCalls, 0);
    });
  });

  test('create, update and delete reach the server', () async {
    await h.createPerson('p1', name: 'Amal');
    await h.createTransaction('t1', personId: 'p1', amount: 1500);
    expect(await cycle(), SyncCycleOutcome.completed);
    expect(h.auth.ensureCalls, 1);
    expect(await h.outboxRows(), isEmpty);
    expect(h.remote.rowOf(SyncEntityType.person, 'p1')!['name'], 'Amal');
    expect(
      h.remote.rowOf(SyncEntityType.moneyTransaction, 't1')!['amount_minor'],
      1500,
    );
    final meta = await h.metaFor('t1');
    expect(meta!.state, SyncHarness.synced);
    expect(meta.serverRevision, 2);

    await h.renamePerson('p1', 'Amal K');
    await h.editTransaction('t1', amount: 2500);
    expect((await h.opFor('t1'))!.baseRevision, 2);
    expect(await cycle(), SyncCycleOutcome.completed);
    expect(h.remote.rowOf(SyncEntityType.person, 'p1')!['name'], 'Amal K');
    expect(
      h.remote.rowOf(SyncEntityType.moneyTransaction, 't1')!['amount_minor'],
      2500,
    );

    await h.softDeleteTransaction('t1');
    await h.createPerson('p2');
    await cycle();
    await h.deletePerson('p2');
    await cycle();
    expect(
      h.remote.rowOf(SyncEntityType.moneyTransaction, 't1')!['deleted_at'],
      isNotNull,
    );
    expect(
      h.remote.rowOf(SyncEntityType.person, 'p2')!['deleted_at'],
      isNotNull,
    );
    expect(await h.outboxRows(), isEmpty);
    expect(h.remote.lastDevice!.platform, anyOf('android', 'ios'));
    expect(h.remote.lastDevice!.deviceId, (await h.state()).deviceId);
  });

  test(
    'partial failure: A applied, B rejected and failed, C still pending',
    () async {
      await h.createPerson('A');
      await h.createTransaction('B', personId: 'A', amount: 0); // invalid
      await h.createAudit('C', transactionId: 'B');

      expect(await cycle(), SyncCycleOutcome.completed);

      expect(await h.opFor('A'), isNull);
      expect((await h.metaFor('A'))!.state, 'synced');

      final b = await h.opFor('B');
      expect(b!.status, OutboxStatus.failed);
      expect(b.errorCode, 'validation');
      expect((await h.metaFor('B'))!.state, 'failed');

      // C went out in the same batch as B, before B's rejection was known:
      // the server refused it as missing_parent (transient, not ledgered).
      final c = await h.opFor('C');
      expect(c!.status, OutboxStatus.pending);
      expect(c.errorCode, 'missing_parent');
      expect(h.remote.rowCount(SyncEntityType.transactionAudit), 0);

      // From now on B is failed, so C is held back, never resent.
      h.skipBackoff();
      await cycle();
      expect(h.sentEntityIds.where((id) => id == 'C'), hasLength(1));
      expect((await h.opFor('C'))!.status, OutboxStatus.pending);
    },
  );

  test('a dropped response after commit is replayed as already_applied: '
      '1 server row', () async {
    await h.createPerson('p1');
    await h.createTransaction('t1', personId: 'p1');
    h.remote.dropResponseAfterCommit();

    final first = await cycle();
    expect(first.result, SyncCycleResult.retryScheduled);
    expect(h.remote.rowCount(SyncEntityType.moneyTransaction), 1);
    expect((await h.opFor('t1'))!.status, OutboxStatus.pending);

    h.skipBackoff();
    expect(await cycle(), SyncCycleOutcome.completed);
    expect(h.remote.rowCount(SyncEntityType.moneyTransaction), 1);
    expect(h.remote.rowCount(SyncEntityType.person), 1);
    expect((await h.metaFor('t1'))!.state, 'synced');
    expect(await h.outboxRows(), isEmpty);
  });

  test('the same operation executed 3 times gives 1 server row', () async {
    await h.createPerson('p1');
    await h.createTransaction('t1', personId: 'p1');
    final opId = (await h.opFor('t1'))!.opId;

    for (var i = 0; i < 2; i++) {
      h.remote.dropResponseAfterCommit();
      await cycle();
      h.skipBackoff();
    }
    await cycle();

    final sends = [
      for (final batch in h.remote.committedBatches)
        for (final op in batch)
          if (op.opId == opId) op,
    ];
    expect(sends, hasLength(3));
    expect(h.remote.rowCount(SyncEntityType.moneyTransaction), 1);
    expect(
      h.remote.duplicateIdempotencyKeys(SyncEntityType.moneyTransaction),
      0,
    );
    expect(await h.outboxRows(), isEmpty);
  });

  test(
    'a dependent transaction stays unsent while its person op is failed',
    () async {
      await h.createPerson('p1', name: ''); // the server rejects an empty name
      await h.createTransaction('t1', personId: 'p1');
      await h.createPerson('p2');
      await h.createTransaction('t2', personId: 'p2');

      await cycle();
      h.skipBackoff();
      await cycle();
      h.skipBackoff();
      await cycle();

      expect((await h.opFor('p1'))!.status, OutboxStatus.failed);
      expect((await h.opFor('t1'))!.status, OutboxStatus.pending);
      // Only the first batch (which carried p1 too) included t1.
      expect(h.sentEntityIds.where((id) => id == 't1'), hasLength(1));
      expect(h.remote.rowOf(SyncEntityType.moneyTransaction, 't1'), isNull);
      expect(h.remote.rowOf(SyncEntityType.moneyTransaction, 't2'), isNotNull);
    },
  );

  test('missing_parent is retried with backoff, then applies', () async {
    // The person reached the server through another path… not yet.
    await h.createTransaction('t1', personId: 'p-later');
    await cycle();
    final op = await h.opFor('t1');
    expect(op!.status, OutboxStatus.pending);
    expect(op.errorCode, 'missing_parent');
    expect(op.nextAttemptAt, greaterThan(h.clock.now().millisecondsSinceEpoch));

    h.remote.seedServerRow(SyncEntityType.person, {
      'id': 'p-later',
      'name': 'L',
    });
    h.skipBackoff();
    await cycle();
    expect(await h.opFor('t1'), isNull);
  });

  test('network failure backs off, persists the count, and a later success '
      'resets it', () async {
    await h.createPerson('p1');
    h.remote.failNextCalls(2);

    final first = await cycle();
    expect(first.result, SyncCycleResult.retryScheduled);
    expect(first.errorCode, SyncErrorCode.network);
    expect(first.retryAfter!.inMilliseconds, inInclusiveRange(4000, 6000));
    var op = await h.opFor('p1');
    expect(op!.status, OutboxStatus.pending);
    expect(op.errorCode, 'network');
    expect(
      op.nextAttemptAt,
      h.clock.now().millisecondsSinceEpoch + first.retryAfter!.inMilliseconds,
    );
    expect((await h.state()).consecutiveFailures, 1);
    expect((await h.state()).lastErrorCode, 'network');

    // Before the delay: nothing is sent, and the count is kept.
    expect(await cycle(), SyncCycleOutcome.completed);
    expect(h.remote.pushCalls, 1);
    expect((await h.state()).consecutiveFailures, 1);

    h.skipBackoff();
    final second = await cycle();
    expect(second.retryAfter!.inMilliseconds, inInclusiveRange(8000, 12000));
    expect((await h.state()).consecutiveFailures, 2);

    // "Sync now" ignores the delay.
    expect(await cycle(ignoreBackoff: true), SyncCycleOutcome.completed);
    op = await h.opFor('p1');
    expect(op, isNull);
    final state = await h.state();
    expect(state.consecutiveFailures, 0);
    expect(state.lastErrorCode, isNull);
    expect(state.lastSuccessAt, h.clock.now().millisecondsSinceEpoch);
  });

  test(
    'an expired token is refreshed once, then the batch is resent',
    () async {
      await h.createPerson('p1');
      h.remote.failNextCalls(1, const UnauthorizedFailure('expired'));
      expect(await cycle(), SyncCycleOutcome.completed);
      expect(h.auth.refreshCalls, 1);
      expect(await h.outboxRows(), isEmpty);
    },
  );

  test('42501 pauses with authRequired and leaves the batch pending', () async {
    await h.createPerson('p1');
    h.remote.failNextCalls(1, const ForbiddenFailure('rls'), false);
    final outcome = await cycle();
    expect(outcome.result, SyncCycleResult.authRequired);
    final op = await h.opFor('p1');
    expect(op!.status, OutboxStatus.pending);
    expect(
      op.nextAttemptAt,
      lessThanOrEqualTo(h.clock.now().millisecondsSinceEpoch),
    );
    expect((await h.state()).consecutiveFailures, 0);
  });

  test('a failed session sign-in is a transient retry', () async {
    await h.createPerson('p1');
    h.auth.ensureFailures.add(
      const SyncRemoteException(
        NetworkFailure('x'),
        transient: true,
        errorCode: 'network',
      ),
    );
    expect((await cycle()).result, SyncCycleResult.retryScheduled);
    expect(h.remote.pushCalls, 0);
  });

  test('conflict and superseded are kept (failed unhandled_conflict) until '
      'T071', () async {
    await h.createPerson('p1');
    await h.createTransaction('t1', personId: 'p1');
    await cycle();
    // Another device edits t1 on the server.
    h.remote.seedServerRow(SyncEntityType.moneyTransaction, {
      ...h.remote.rowOf(SyncEntityType.moneyTransaction, 't1')!,
      'amount_minor': 9999,
    });
    await h.editTransaction('t1', amount: 1234);
    expect(await cycle(), SyncCycleOutcome.completed);

    final op = await h.opFor('t1');
    expect(op!.status, OutboxStatus.failed);
    expect(op.errorCode, SyncHarness.unhandledConflict);
    expect(op.payloadJson, contains('1234'));
    expect(h.logger.names, contains(SyncEvent.conflict));
  });

  test('logs the lifecycle with allowed fields only', () async {
    await h.createPerson('p1');
    await cycle();
    expect(h.logger.names, [
      SyncEvent.syncStarted,
      SyncEvent.uploadStarted,
      SyncEvent.uploadSuccess,
      SyncEvent.syncCompleted,
    ]);
    final (_, started) = h.logger.events[1];
    expect(started, {SyncLogField.count: 1});
    for (final (_, fields) in h.logger.events) {
      for (final value in fields.values) {
        expect('$value', isNot(contains('p1')));
      }
    }
  });
}
