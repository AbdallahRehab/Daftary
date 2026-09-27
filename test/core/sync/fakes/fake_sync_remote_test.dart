import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/remote/sync_error_mapper.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_sync_remote.dart';

/// 021 T055: the fake reproduces the `sync_push` / `sync_pull` semantics
/// the engine tests rely on.
void main() {
  const device = DeviceInfo(
    deviceId: 'device-1',
    platform: 'android',
    appVersion: 'test',
  );
  late FakeSyncRemote remote;
  var nextOp = 0;

  setUp(() {
    remote = FakeSyncRemote();
    nextOp = 0;
  });

  OutboxOp op(
    SyncEntityType type,
    String id,
    Map<String, Object?> payload, {
    OutboxOpType opType = OutboxOpType.upsert,
    int? base,
    String? opId,
  }) => OutboxOp(
    opId: opId ?? 'op-${nextOp++}',
    entityType: type,
    entityId: id,
    opType: opType,
    payload: {'id': id, ...payload},
    baseRevision: base,
  );

  OutboxOp person(String id, {String name = 'A', int? base, String? opId}) =>
      op(SyncEntityType.person, id, {'name': name}, base: base, opId: opId);

  OutboxOp txn(
    String id, {
    String personId = 'p1',
    String amount = '100',
    String key = 'k1',
    int? base,
    String? opId,
  }) => op(
    SyncEntityType.moneyTransaction,
    id,
    {'person_id': personId, 'amount_minor': amount, 'idempotency_key': key},
    base: base,
    opId: opId,
  );

  Future<PushResult> push1(OutboxOp o) async =>
      (await remote.push([o], device)).single;

  test('insert is applied, a replayed op_id is already_applied', () async {
    final o = person('p1');
    expect(await push1(o), const PushApplied('op-0', revision: 1));
    expect(
      await push1(o),
      const PushApplied('op-0', revision: 1, alreadyApplied: true),
    );
    expect(remote.rowCount(SyncEntityType.person), 1);
  });

  test('a new op_id with the same idempotency_key is already_applied, '
      'and money comes back as a number', () async {
    await push1(person('p1'));
    await push1(txn('t1'));
    final replay = await push1(txn('t1-other-id', key: 'k1'));
    expect(
      replay,
      isA<PushApplied>().having((r) => r.alreadyApplied, 'already', true),
    );
    expect(remote.rowCount(SyncEntityType.moneyTransaction), 1);
    expect(
      remote.rowOf(SyncEntityType.moneyTransaction, 't1')!['amount_minor'],
      100,
    );
  });

  test('stale financial update is a conflict with no write; stale LWW '
      'update is applied', () async {
    await push1(person('p1'));
    await push1(txn('t1')); // rev 2
    await push1(txn('t1', amount: '200', base: 2)); // rev 3
    final stale = await push1(txn('t1', amount: '300', base: 2));
    expect(stale, isA<PushConflict>().having((r) => r.revision, 'rev', 3));
    expect(
      remote.rowOf(SyncEntityType.moneyTransaction, 't1')!['amount_minor'],
      200,
    );

    final lww = await push1(person('p1', name: 'B', base: 0));
    expect(lww, isA<PushApplied>());
    expect(remote.rowOf(SyncEntityType.person, 'p1')!['name'], 'B');
  });

  test('a stale delete is superseded; a replayed conflict stays a '
      'conflict', () async {
    await push1(person('p1')); // rev 1
    await push1(person('p1', name: 'B', base: 1)); // rev 2
    final delete = await push1(
      op(SyncEntityType.person, 'p1', {}, opType: OutboxOpType.delete, base: 1),
    );
    expect(delete, isA<PushSuperseded>());
    expect(remote.rowOf(SyncEntityType.person, 'p1')!['deleted_at'], isNull);

    await push1(txn('t1')); // rev 3
    final conflictOp = txn('t1', amount: '999', base: 1, opId: 'c1');
    expect(await push1(conflictOp), isA<PushConflict>());
    expect(await push1(conflictOp), isA<PushConflict>());
  });

  test('person delete with transactions is rejected with the server row; '
      'category delete with entries archives it', () async {
    await push1(person('p1'));
    await push1(txn('t1'));
    final rejected = await push1(
      op(SyncEntityType.person, 'p1', {}, opType: OutboxOpType.delete, base: 1),
    );
    expect(
      rejected,
      isA<PushRejected>()
          .having((r) => r.reason, 'reason', 'person_has_transactions')
          .having((r) => r.serverRow?['id'], 'row', 'p1'),
    );

    await push1(op(SyncEntityType.financeCategory, 'c1', {'type': 'expense'}));
    await push1(
      op(SyncEntityType.financeEntry, 'e1', {
        'category_id': 'c1',
        'type': 'expense',
        'amount_minor': '5',
        'idempotency_key': 'ek',
      }),
    );
    final archive = await push1(
      op(SyncEntityType.financeCategory, 'c1', {}, opType: OutboxOpType.delete),
    );
    expect(
      archive,
      isA<PushApplied>().having(
        (r) => r.serverRow?['is_archived'],
        'archived',
        true,
      ),
    );
  });

  test(
    'missing_parent is rejected but never ledgered, so a retry applies',
    () async {
      final orphan = txn('t1', personId: 'p-missing', opId: 'orphan');
      expect(
        await push1(orphan),
        const PushRejected('orphan', reason: 'missing_parent'),
      );
      expect(remote.ledgerHas('orphan'), isFalse);

      await push1(person('p-missing'));
      expect(await push1(orphan), isA<PushApplied>());
    },
  );

  test('validation and type mismatch are rejected', () async {
    await push1(person('p1'));
    expect(
      await push1(txn('t0', amount: '0')),
      isA<PushRejected>().having((r) => r.reason, 'reason', 'validation'),
    );
    await push1(op(SyncEntityType.financeCategory, 'c1', {'type': 'income'}));
    expect(
      await push1(
        op(SyncEntityType.financeEntry, 'e1', {
          'category_id': 'c1',
          'type': 'expense',
          'amount_minor': '5',
          'idempotency_key': 'ek',
        }),
      ),
      isA<PushRejected>().having(
        (r) => r.reason,
        'reason',
        'category_type_mismatch',
      ),
    );
  });

  test(
    'scripted failures: failNextCalls and dropResponseAfterCommit',
    () async {
      remote.failNextCalls(1, const TimeoutFailure('t'));
      await expectLater(
        remote.push([person('p1')], device),
        throwsA(
          isA<SyncRemoteException>().having((e) => e.transient, 't', true),
        ),
      );
      expect(remote.rowCount(SyncEntityType.person), 0);

      remote.dropResponseAfterCommit();
      await expectLater(
        remote.push([person('p1', opId: 'x')], device),
        throwsA(isA<SyncRemoteException>()),
      );
      expect(remote.rowCount(SyncEntityType.person), 1);
      expect(
        await push1(person('p1', opId: 'x')),
        isA<PushApplied>().having((r) => r.alreadyApplied, 'already', true),
      );
    },
  );

  test('pull returns pages in revision order, tombstones included', () async {
    for (var i = 0; i < 5; i++) {
      remote.seedServerRow(SyncEntityType.person, {'id': 'p$i', 'name': 'P'});
    }
    remote.seedServerRow(SyncEntityType.person, {
      'id': 'gone',
      'name': 'G',
    }, deleted: true);
    final first = await remote.pull(since: 0, limit: 4);
    expect(first.changes.map((c) => c.revision), [1, 2, 3, 4]);
    expect(first.hasMore, isTrue);
    final second = await remote.pull(since: first.maxRevision, limit: 4);
    expect(second.changes.map((c) => c.revision), [5, 6]);
    expect(second.changes.last.row['deleted_at'], isNotNull);
    expect(second.hasMore, isFalse);
    final empty = await remote.pull(since: 6);
    expect(empty.maxRevision, 6);
    expect(empty.changes, isEmpty);
  });
}
