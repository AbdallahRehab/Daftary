import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/database/watch_tables.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/sync/sync_bootstrap.dart';
import 'package:daftary/core/sync/sync_engine.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_models.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart'
    show isPristineSeed;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../core/sync/fakes/fake_sync_remote.dart';
import '../core/sync/fakes/sync_harness.dart';

/// A [FakeSyncRemote] whose every push takes [latency], like a slow
/// mobile network.
class _SlowRemote extends FakeSyncRemote {
  _SlowRemote(this.latency);

  final Duration latency;

  @override
  Future<List<PushResult>> push(List<OutboxOp> ops, DeviceInfo device) async {
    await Future<void>.delayed(latency);
    return super.push(ops, device);
  }
}

/// The standard harness, with [_SlowRemote] in place of the instant fake.
/// The engine reads `remote` when the harness builds it, so it gets this
/// one.
class _SlowHarness extends SyncHarness {
  _SlowHarness(Duration latency) : _remote = _SlowRemote(latency);

  final _SlowRemote _remote;

  @override
  FakeSyncRemote get remote => _remote;
}

/// 021 T085: sync performance on large local datasets (SC-004).
///
/// Real (not fake) time is used throughout: the in-memory database does
/// real work, and the simulated latency adds only ~10 × 150 ms.
void main() {
  test('bootstrapping 5,000 existing transactions takes under 5 s', () async {
    final h = SyncHarness();
    addTearDown(h.close);
    final db = h.db;
    const people = 50;
    const transactions = 5000;
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
            direction: t.isEven ? 'given' : 'received',
            kind: 'initialExchange',
            date: 1700000000000 + t,
            createdAt: 1700000000000 + t,
          ),
      ]);
    });

    final stopwatch = Stopwatch()..start();
    final queued = await SyncBootstrap(
      realMapperRegistry(),
      h.logger,
      h.clock,
      isPristineSeed: isPristineSeed,
    ).enqueueExistingDataIfNeeded(db);
    stopwatch.stop();

    expect(queued, people + transactions);
    expect(await h.outboxRows(), hasLength(people + transactions));
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 5)),
      reason: 'bootstrap took ${stopwatch.elapsedMilliseconds} ms',
    );
  });

  test('1,000 operations drain with 150 ms latency per call in under 60 s '
      '(SC-004)', () async {
    const latency = Duration(milliseconds: 150);
    final h = _SlowHarness(latency);
    addTearDown(h.close);
    const people = 100;
    const transactions = 900;
    for (var p = 0; p < people; p++) {
      await h.createPerson('p$p', name: 'Person $p');
    }
    for (var t = 0; t < transactions; t++) {
      await h.createTransaction('t$t', personId: 'p${t % people}');
    }
    expect(await h.outboxRows(), hasLength(people + transactions));

    final stopwatch = Stopwatch()..start();
    final outcome = await h.engine.runCycle();
    stopwatch.stop();

    expect(outcome, SyncCycleOutcome.completed);
    expect(await h.outboxRows(), isEmpty);
    expect(h.remote.rowCount(SyncEntityType.person), people);
    expect(h.remote.rowCount(SyncEntityType.moneyTransaction), transactions);
    // 1,000 ops / 100 per call: the latency is paid once per batch.
    expect(h.remote.pushCalls, 10);
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 60)),
      reason: 'drain took ${stopwatch.elapsedMilliseconds} ms',
    );
  });

  test('watch re-queries are debounced during bulk writes: at most one per '
      '50 ms', () async {
    final h = SyncHarness();
    addTearDown(h.close);
    final db = h.db;
    // Open (and seed) before listening, so setup writes are not counted.
    await db.customSelect('SELECT 1').get();

    final queryTimes = <Duration>[];
    final clock = Stopwatch()..start();
    final sub = db
        .watchEither({db.people, db.moneyTransactions}, () async {
          queryTimes.add(clock.elapsed);
          final rows = await db.select(db.people).get();
          return right<Failure, int>(rows.length);
        })
        .listen((_) {});
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(queryTimes, hasLength(1), reason: 'the initial read');

    // Bulk writes, each its own transaction (like a download applied one
    // record at a time), with the outbox bookkeeping the DAOs do.
    const people = 50;
    const transactions = 450;
    final writesStart = clock.elapsed;
    for (var p = 0; p < people; p++) {
      await h.createPerson('p$p');
    }
    for (var t = 0; t < transactions; t++) {
      await h.createTransaction('t$t', personId: 'p${t % people}');
    }
    final writesTook = clock.elapsed - writesStart;
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final reQueries = queryTimes.skip(1).toList();
    expect(reQueries, isNotEmpty, reason: 'the final state is re-read');
    // Never two re-queries within 50 ms of each other.
    for (var i = 1; i < queryTimes.length; i++) {
      expect(
        queryTimes[i] - queryTimes[i - 1],
        greaterThanOrEqualTo(const Duration(milliseconds: 50)),
        reason: 'query $i ran too soon after query ${i - 1}',
      );
    }
    // At most one re-query per 50 ms of writing, plus the trailing one —
    // far fewer than the ${people + transactions} writes.
    expect(
      reQueries.length,
      lessThanOrEqualTo(writesTook.inMilliseconds ~/ 50 + 1),
    );
    expect(reQueries.length, lessThan(people + transactions));
  });
}
