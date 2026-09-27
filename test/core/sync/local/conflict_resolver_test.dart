import 'dart:convert';

import 'package:daftary/core/sync/local/conflict_resolver.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/sync_harness.dart';

/// 021 T072: "keep mine" and "keep theirs" (contracts/sync-rpc.md §6).
void main() {
  late SyncHarness h;

  setUp(() => h = SyncHarness());
  tearDown(() => h.close());

  const txn = SyncEntityType.moneyTransaction;

  Future<void> cycle() => h.engine.runCycle();

  /// t1 is in conflict: 9999 on the server, 1234 locally, with a local
  /// audit entry `a1` queued behind it.
  Future<int> conflictOnT1() async {
    await h.createPerson('p1');
    await h.createTransaction('t1', personId: 'p1', amount: 1500);
    await cycle();
    final revision = h.remote.seedServerRow(txn, {
      ...h.remote.rowOf(txn, 't1')!,
      'amount_minor': 9999,
    });
    await h.editTransaction('t1', amount: 1234);
    await cycle();
    expect(await h.openConflict('t1'), isNotNull);
    // Held back while t1 is blocked.
    await h.createAudit('a1', transactionId: 't1');
    await cycle();
    return revision;
  }

  test('keep mine: re-queued against the server revision; one resolution '
      'record holds the discarded server version', () async {
    final serverRevision = await conflictOnT1();
    await h.resolver.keepMine(txn, 't1');

    final op = (await h.opFor('t1'))!;
    expect(op.status, OutboxStatus.pending);
    expect(op.baseRevision, serverRevision);
    expect(jsonDecode(op.payloadJson)['amount_minor'], '1234');
    expect(await h.openConflict('t1'), isNull);

    final resolution = (await h.resolutions()).single;
    expect(resolution.chosenSide, 'local');
    expect(resolution.entityId, 't1');
    expect(jsonDecode(resolution.discardedValuesJson)['amount_minor'], 9999);

    await cycle();
    expect(h.remote.rowOf(txn, 't1')!['amount_minor'], 1234);
    expect(h.remote.rowCount(SyncEntityType.conflictResolution), 1);
    final remoteResolution = h.remote
        .rowsOf(SyncEntityType.conflictResolution)
        .single;
    expect(
      (remoteResolution['discarded_values']! as Map)['amount_minor'],
      9999,
    );
    expect((await h.metaFor('t1'))!.state, SyncRecordState.synced);
    expect(await h.outboxRows(), isEmpty);
  });

  test('keep theirs: the server version is applied locally; one resolution '
      'record holds the discarded local version; the audit entries of the '
      'discarded edit stay queued unchanged', () async {
    await conflictOnT1();
    final auditBefore = (await h.opFor('a1'))!;
    final auditRows = await h.db.select(h.db.transactionAuditEntries).get();

    await h.resolver.keepTheirs(txn, 't1');

    expect((await h.transaction('t1')).amountMinorUnits, 9999);
    expect(await h.opFor('t1'), isNull);
    expect(await h.openConflict('t1'), isNull);
    expect((await h.metaFor('t1'))!.state, SyncRecordState.synced);

    final resolution = (await h.resolutions()).single;
    expect(resolution.chosenSide, 'server');
    expect(jsonDecode(resolution.discardedValuesJson)['amount_minor'], '1234');

    final auditAfter = (await h.opFor('a1'))!;
    expect(auditAfter.payloadJson, auditBefore.payloadJson);
    expect(auditAfter.status, OutboxStatus.pending);
    expect(
      await h.db.select(h.db.transactionAuditEntries).get(),
      hasLength(auditRows.length),
    );

    await cycle();
    expect(h.remote.rowOf(txn, 't1')!['amount_minor'], 9999);
    expect(h.remote.rowOf(SyncEntityType.transactionAudit, 'a1'), isNotNull);
    expect(h.remote.rowCount(SyncEntityType.conflictResolution), 1);
    expect(await h.outboxRows(), isEmpty);
  });

  test(
    'keep mine uses the newest local edit made after the conflict',
    () async {
      await conflictOnT1();
      await h.editTransaction('t1', amount: 4321);
      await h.resolver.keepMine(txn, 't1');
      await cycle();
      expect(h.remote.rowOf(txn, 't1')!['amount_minor'], 4321);
      expect((await h.resolutions()), hasLength(1));
    },
  );

  test('without an open conflict both throw, and nothing is written', () async {
    await h.createPerson('p1');
    await h.createTransaction('t1', personId: 'p1');
    await expectLater(
      h.resolver.keepMine(txn, 't1'),
      throwsA(isA<NoOpenConflictException>()),
    );
    await expectLater(
      h.resolver.keepTheirs(txn, 't1'),
      throwsA(isA<NoOpenConflictException>()),
    );
    expect(await h.resolutions(), isEmpty);
  });
}
