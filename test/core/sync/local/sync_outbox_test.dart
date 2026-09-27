import 'dart:convert';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _TickingClock implements AppClock {
  var _ms = 1700000000000;

  @override
  DateTime now() => DateTime.fromMillisecondsSinceEpoch(_ms++);
}

void main() {
  late AppDatabase db;
  late DriftSyncOutbox outbox;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outbox = DriftSyncOutbox(db, _TickingClock());
  });

  tearDown(() => db.close());

  Future<List<SyncOutboxRow>> ops() => (db.select(
    db.syncOutboxEntries,
  )..orderBy([(o) => OrderingTerm.asc(o.createdAt)])).get();

  Future<SyncRecordMetaRow?> meta(SyncEntityType type, String id) =>
      (db.select(db.syncRecordMeta)..where(
            (m) => m.entityType.equals(type.wire) & m.entityId.equals(id),
          ))
          .getSingleOrNull();

  Map<String, Object?> personPayload(String id, String name) => {
    'id': id,
    'name': name,
  };

  Future<void> insertPerson(String id) => db
      .into(db.people)
      .insert(
        PeopleCompanion.insert(
          id: id,
          name: 'A',
          normalizedName: 'a',
          createdAt: 1,
          updatedAt: 1,
        ),
      );

  test('throws when called outside a transaction', () async {
    await expectLater(
      outbox.recordUpsert(SyncEntityType.person, 'p1', {}),
      throwsStateError,
    );
    expect(await ops(), isEmpty);
  });

  test(
    'records an upsert with a UUID op id, the rank and a pending meta',
    () async {
      await db.transaction(() async {
        await insertPerson('p1');
        await outbox.recordUpsert(
          SyncEntityType.person,
          'p1',
          personPayload('p1', 'A'),
        );
      });

      final op = (await ops()).single;
      expect(
        op.opId,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab]')),
      );
      expect(op.entityType, 'person');
      expect(op.entityId, 'p1');
      expect(op.opType, 'upsert');
      expect(op.dependsOnRank, 0);
      expect(op.status, OutboxStatus.pending);
      expect(op.baseRevision, isNull);
      expect(op.attemptCount, 0);
      expect(op.createdAt, greaterThanOrEqualTo(1700000000000));
      expect(jsonDecode(op.payloadJson), {'id': 'p1', 'name': 'A'});
      expect((await meta(SyncEntityType.person, 'p1'))!.state, 'pending');
    },
  );

  test('a throw after recordUpsert rolls back both the business row and the '
      'outbox row', () async {
    await expectLater(
      db.transaction(() async {
        await insertPerson('p1');
        await outbox.recordUpsert(
          SyncEntityType.person,
          'p1',
          personPayload('p1', 'A'),
        );
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(await db.select(db.people).get(), isEmpty);
    expect(await ops(), isEmpty);
    expect(await db.select(db.syncRecordMeta).get(), isEmpty);
  });

  test('three upserts of one record coalesce into one row with the latest '
      'payload', () async {
    for (final name in ['A', 'B', 'C']) {
      await db.transaction(
        () => outbox.recordUpsert(
          SyncEntityType.person,
          'p1',
          personPayload('p1', name),
        ),
      );
    }
    final rows = await ops();
    expect(rows, hasLength(1));
    expect(jsonDecode(rows.single.payloadJson), {'id': 'p1', 'name': 'C'});
  });

  test('create then delete of a never-synced person leaves no rows', () async {
    await db.transaction(
      () => outbox.recordUpsert(
        SyncEntityType.person,
        'p1',
        personPayload('p1', 'A'),
      ),
    );
    await db.transaction(
      () => outbox.recordDelete(
        SyncEntityType.person,
        'p1',
        personPayload('p1', 'A'),
      ),
    );
    expect(await ops(), isEmpty);
    expect(await meta(SyncEntityType.person, 'p1'), isNull);
  });

  test(
    'a new op on a synced record carries its server revision as base',
    () async {
      await db
          .into(db.syncRecordMeta)
          .insert(
            SyncRecordMetaCompanion.insert(
              entityType: 'person',
              entityId: 'p1',
              state: 'synced',
              serverRevision: const Value(42),
              lastSyncedAt: const Value(5),
            ),
          );
      await db.transaction(
        () => outbox.recordUpsert(SyncEntityType.person, 'p1', {'id': 'p1'}),
      );
      await db.transaction(
        () => outbox.recordDelete(SyncEntityType.person, 'p1', {'id': 'p1'}),
      );
      final op = (await ops()).single;
      expect(op.opType, 'delete');
      expect(op.baseRevision, 42);
      final m = (await meta(SyncEntityType.person, 'p1'))!;
      expect(m.state, 'pending');
      expect(m.serverRevision, 42);
      expect(m.lastSyncedAt, 5);
    },
  );

  test('a soft delete of a never-synced transaction stays an upsert', () async {
    await db.transaction(
      () => outbox.recordUpsert(SyncEntityType.moneyTransaction, 't1', {
        'id': 't1',
        'deleted_at': null,
      }),
    );
    await db.transaction(
      () => outbox.recordUpsert(SyncEntityType.moneyTransaction, 't1', {
        'id': 't1',
        'deleted_at': '2026-09-27T09:00:00.000Z',
      }),
    );
    final op = (await ops()).single;
    expect(op.opType, 'upsert');
    expect(op.dependsOnRank, 1);
    expect(jsonDecode(op.payloadJson)['deleted_at'], isNotNull);
  });

  test('audit inserts are never coalesced', () async {
    for (var i = 0; i < 2; i++) {
      await db.transaction(
        () => outbox.recordUpsert(SyncEntityType.transactionAudit, 'a1', {
          'i': i,
        }),
      );
    }
    final rows = await ops();
    expect(rows, hasLength(2));
    expect(rows.every((r) => r.dependsOnRank == 2), isTrue);
  });

  test(
    'never merges into an in_flight op; a later write queues a new one',
    () async {
      await db.transaction(
        () => outbox.recordUpsert(SyncEntityType.person, 'p1', {'v': 1}),
      );
      await db
          .update(db.syncOutboxEntries)
          .write(
            const SyncOutboxEntriesCompanion(
              status: Value(OutboxStatus.inFlight),
            ),
          );
      await db.transaction(
        () => outbox.recordUpsert(SyncEntityType.person, 'p1', {'v': 2}),
      );
      await db.transaction(
        () => outbox.recordUpsert(SyncEntityType.person, 'p1', {'v': 3}),
      );
      final rows = await ops();
      expect(rows, hasLength(2));
      expect(rows.first.status, OutboxStatus.inFlight);
      expect(jsonDecode(rows.first.payloadJson), {'v': 1});
      expect(rows.last.status, OutboxStatus.pending);
      expect(jsonDecode(rows.last.payloadJson), {'v': 3});
    },
  );

  test('an open conflict keeps its meta state on a new local write', () async {
    await db
        .into(db.syncRecordMeta)
        .insert(
          SyncRecordMetaCompanion.insert(
            entityType: 'money_transaction',
            entityId: 't1',
            state: 'conflict',
            serverRevision: const Value(9),
          ),
        );
    await db.transaction(
      () => outbox.recordUpsert(SyncEntityType.moneyTransaction, 't1', {}),
    );
    expect(
      (await meta(SyncEntityType.moneyTransaction, 't1'))!.state,
      'conflict',
    );
  });
}
