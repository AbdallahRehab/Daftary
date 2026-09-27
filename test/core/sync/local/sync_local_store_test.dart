import 'dart:math';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/backoff_policy.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/local/sync_local_store.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/sync_harness.dart';
import '../fakes/sync_test_doubles.dart';

/// 021 T056: the engine's view of the local sync tables.
void main() {
  late AppDatabase db;
  late FakeClock clock;
  late DriftSyncLocalStore store;
  late DriftSyncOutbox outbox;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = FakeClock();
    store = realStore(db, clock, BackoffPolicy.withRandom(Random(7)));
    outbox = DriftSyncOutbox(db, _Ticking(clock));
  });

  tearDown(() => db.close());

  Future<void> upsert(
    SyncEntityType type,
    String id, [
    Map<String, Object?> extra = const {},
  ]) =>
      db.transaction(() => outbox.recordUpsert(type, id, {'id': id, ...extra}));

  Future<List<SyncOutboxRow>> rows() => (db.select(
    db.syncOutboxEntries,
  )..orderBy([(o) => OrderingTerm.asc(o.createdAt)])).get();

  Future<SyncOutboxRow> rowFor(String entityId) => (db.select(
    db.syncOutboxEntries,
  )..where((o) => o.entityId.equals(entityId))).getSingle();

  Future<SyncRecordMetaRow?> meta(String entityId) => (db.select(
    db.syncRecordMeta,
  )..where((m) => m.entityId.equals(entityId))).getSingleOrNull();

  Future<void> setStatus(String entityId, String status) =>
      (db.update(db.syncOutboxEntries)
            ..where((o) => o.entityId.equals(entityId)))
          .write(SyncOutboxEntriesCompanion(status: Value(status)));

  group('nextBatch', () {
    test('orders by rank, then FIFO, and honours the limit', () async {
      await upsert(SyncEntityType.exchangeRate, 'rate'); // rank 3
      await upsert(SyncEntityType.moneyTransaction, 't1', {'person_id': 'p1'});
      await upsert(SyncEntityType.person, 'p1'); // rank 0
      await upsert(SyncEntityType.person, 'p2');

      final all = await store.nextBatch(limit: 10, now: clock.now());
      expect(all.map((o) => o.entityId), ['p1', 'p2', 't1', 'rate']);
      expect(all.first.payload, {'id': 'p1'});
      expect(all.first.opType, OutboxOpType.upsert);

      final two = await store.nextBatch(limit: 2, now: clock.now());
      expect(two.map((o) => o.entityId), ['p1', 'p2']);
    });

    test('skips operations that are not due yet', () async {
      await upsert(SyncEntityType.person, 'p1');
      final op = await rowFor('p1');
      await (db.update(
        db.syncOutboxEntries,
      )..where((o) => o.opId.equals(op.opId))).write(
        SyncOutboxEntriesCompanion(
          nextAttemptAt: Value(
            clock.now().add(const Duration(seconds: 10)).millisecondsSinceEpoch,
          ),
        ),
      );
      expect(await store.nextBatch(limit: 10, now: clock.now()), isEmpty);
      clock.advance(const Duration(seconds: 10));
      expect(await store.nextBatch(limit: 10, now: clock.now()), hasLength(1));
    });

    test('a failed or blocked parent holds back only its dependents, '
        'transitively', () async {
      await upsert(SyncEntityType.person, 'p1');
      await upsert(SyncEntityType.person, 'p2');
      await upsert(SyncEntityType.moneyTransaction, 't1', {'person_id': 'p1'});
      await upsert(SyncEntityType.moneyTransaction, 't2', {'person_id': 'p2'});
      await upsert(SyncEntityType.transactionAudit, 'a1', {
        'transaction_id': 't1',
      });
      await upsert(SyncEntityType.financeCategory, 'c1');
      await upsert(SyncEntityType.financeEntry, 'e1', {'category_id': 'c1'});

      await setStatus('p1', OutboxStatus.failed);
      await setStatus('c1', OutboxStatus.blockedConflict);

      final batch = await store.nextBatch(limit: 100, now: clock.now());
      expect(batch.map((o) => o.entityId), ['p2', 't2']);
    });

    test('a record in conflict sends nothing more until resolved', () async {
      await upsert(SyncEntityType.moneyTransaction, 't1', {'person_id': 'p'});
      await setStatus('t1', OutboxStatus.blockedConflict);
      await upsert(SyncEntityType.moneyTransaction, 't1', {'person_id': 'p'});
      expect(await store.nextBatch(limit: 10, now: clock.now()), isEmpty);
    });
  });

  test(
    'markInFlight counts the attempt; resetInFlight recovers a restart',
    () async {
      await upsert(SyncEntityType.person, 'p1');
      final op = (await store.nextBatch(limit: 1, now: clock.now())).single;
      await store.markInFlight([op.opId]);

      var row = await rowFor('p1');
      expect(row.status, OutboxStatus.inFlight);
      expect(row.attemptCount, 1);
      expect(row.lastAttemptAt, clock.now().millisecondsSinceEpoch);
      expect(await store.nextBatch(limit: 1, now: clock.now()), isEmpty);

      // The app is killed mid-upload; a new store on the same file restarts.
      final restarted = realStore(db, clock, BackoffPolicy());
      await restarted.resetInFlight();
      row = await rowFor('p1');
      expect(row.status, OutboxStatus.pending);
      expect(
        await restarted.nextBatch(limit: 1, now: clock.now()),
        hasLength(1),
      );
    },
  );

  group('applyPushResults', () {
    Future<List<String>> sendAll() async {
      final batch = await store.nextBatch(limit: 100, now: clock.now());
      final ids = [for (final o in batch) o.opId];
      await store.markInFlight(ids);
      return ids;
    }

    test('applied and already_applied delete the op and mark synced', () async {
      await upsert(SyncEntityType.person, 'p1');
      await upsert(SyncEntityType.person, 'p2');
      final ids = await sendAll();
      await store.applyPushResults([
        PushApplied(ids[0], revision: 5),
        PushApplied(ids[1], revision: 6, alreadyApplied: true),
      ], clock.now());

      expect(await rows(), isEmpty);
      final m = await meta('p1');
      expect(m!.state, SyncRecordState.synced);
      expect(m.serverRevision, 5);
      expect(m.lastSyncedAt, clock.now().millisecondsSinceEpoch);
      expect((await meta('p2'))!.serverRevision, 6);
    });

    test(
      'a change queued while in flight is rebased onto the new revision',
      () async {
        await upsert(SyncEntityType.moneyTransaction, 't1', {'person_id': 'p'});
        final ids = await sendAll();
        // Edited while the first upload is in flight: a second op is queued
        // against the old (null) base.
        await upsert(SyncEntityType.moneyTransaction, 't1', {'note': 'x'});
        await store.applyPushResults([
          PushApplied(ids.single, revision: 9),
        ], clock.now());

        final remaining = (await rows()).single;
        expect(remaining.baseRevision, 9);
        expect(remaining.status, OutboxStatus.pending);
        final m = await meta('t1');
        expect(m!.state, SyncRecordState.pending);
        expect(m.serverRevision, 9);
      },
    );

    test(
      'rejected marks the op and the record failed with the reason',
      () async {
        await upsert(SyncEntityType.person, 'p1');
        final ids = await sendAll();
        await store.applyPushResults([
          PushRejected(ids.single, reason: 'validation'),
        ], clock.now());

        final row = await rowFor('p1');
        expect(row.status, OutboxStatus.failed);
        expect(row.errorCode, 'validation');
        expect((await meta('p1'))!.state, SyncRecordState.failed);
      },
    );

    test('rejected missing_parent is transient: pending again, after a '
        'backoff delay', () async {
      await upsert(SyncEntityType.moneyTransaction, 't1', {'person_id': 'p'});
      final ids = await sendAll();
      await store.applyPushResults([
        PushRejected(ids.single, reason: 'missing_parent'),
      ], clock.now());

      final row = await rowFor('t1');
      expect(row.status, OutboxStatus.pending);
      expect(row.errorCode, 'missing_parent');
      final delay = row.nextAttemptAt! - clock.now().millisecondsSinceEpoch;
      expect(delay, inInclusiveRange(4000, 6000));
      expect((await meta('t1'))!.state, SyncRecordState.pending);
    });

    test(
      'runs in one transaction: a failure rolls every result back',
      () async {
        await upsert(SyncEntityType.person, 'p1');
        await upsert(SyncEntityType.person, 'p2');
        final ids = await sendAll();
        await db.customStatement(
          "CREATE TEMP TRIGGER boom BEFORE INSERT ON sync_record_meta "
          "WHEN NEW.entity_id = 'p2' AND NEW.state = 'synced' "
          "BEGIN SELECT RAISE(ABORT, 'boom'); END;",
        );
        await expectLater(
          store.applyPushResults([
            PushApplied(ids[0], revision: 1),
            PushApplied(ids[1], revision: 2),
          ], clock.now()),
          throwsA(anything),
        );
        expect(await rows(), hasLength(2));
        expect((await meta('p1'))!.state, SyncRecordState.pending);
      },
    );
  });

  test('rescheduleBatch only touches operations still in flight', () async {
    await upsert(SyncEntityType.person, 'p1');
    await upsert(SyncEntityType.person, 'p2');
    final batch = await store.nextBatch(limit: 1, now: clock.now());
    await store.markInFlight([batch.single.opId]);
    final other = await rowFor('p2');

    await store.rescheduleBatch(
      [batch.single.opId, other.opId],
      const Duration(seconds: 30),
      'network',
    );
    final p1 = await rowFor('p1');
    expect(p1.status, OutboxStatus.pending);
    expect(p1.errorCode, 'network');
    expect(
      p1.nextAttemptAt,
      clock.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch,
    );
    expect((await rowFor('p2')).nextAttemptAt, isNull);
  });

  test('readState creates the singleton with a device id once; writeState '
      'updates it', () async {
    final first = await store.readState();
    expect(first.id, syncStateId);
    expect(first.enabled, isTrue);
    expect(first.deviceId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect((await store.readState()).deviceId, first.deviceId);

    await store.writeState((s) => s.copyWith(consecutiveFailures: 3));
    final updated = await store.readState();
    expect(updated.consecutiveFailures, 3);
    expect(updated.deviceId, first.deviceId);
  });

  test('watchCounts reports pending, failed and conflict records', () async {
    final counts = <SyncCounts>[];
    final sub = store.watchCounts().listen(counts.add);
    await pumpEventQueue();
    expect(counts.last, SyncCounts.zero);

    await upsert(SyncEntityType.person, 'p1');
    await upsert(SyncEntityType.person, 'p2');
    await upsert(SyncEntityType.person, 'p3');
    await (db.update(db.syncRecordMeta)..where((m) => m.entityId.equals('p2')))
        .write(const SyncRecordMetaCompanion(state: Value('failed')));
    await (db.update(db.syncRecordMeta)..where((m) => m.entityId.equals('p3')))
        .write(const SyncRecordMetaCompanion(state: Value('conflict')));
    await pumpEventQueue();

    expect(counts.last, const SyncCounts(pending: 1, failed: 1, conflicts: 1));
    await sub.cancel();
  });

  test('openOpCount and syncedCountsByType', () async {
    await upsert(SyncEntityType.person, 'p1');
    await upsert(SyncEntityType.person, 'p2');
    expect(await store.openOpCount(), 2);
    final batch = await store.nextBatch(limit: 10, now: clock.now());
    await store.markInFlight([for (final o in batch) o.opId]);
    await store.applyPushResults([
      for (final o in batch) PushApplied(o.opId, revision: 1),
    ], clock.now());
    expect(await store.openOpCount(), 0);
    expect(await store.syncedCountsByType(), {SyncEntityType.person: 2});
  });
}

/// A clock for the outbox that ticks 1 ms per read, so FIFO order is
/// deterministic, while staying close to [base].
class _Ticking extends FakeClock {
  _Ticking(this.base);

  final FakeClock base;
  var _ticks = 0;

  @override
  DateTime now() => base.now().add(Duration(milliseconds: _ticks++));
}
