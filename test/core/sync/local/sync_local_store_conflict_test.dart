import 'dart:convert';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/local/sync_local_store.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/server_rows.dart';
import '../fakes/sync_harness.dart';

/// 021 T071: conflict, superseded and rule results are handled — never
/// dropped (contracts/sync-rpc.md §5).
void main() {
  late SyncHarness h;

  setUp(() => h = SyncHarness());
  tearDown(() => h.close());

  Future<void> cycle() => h.engine.runCycle();

  /// t1 synced, then edited on the server (another device) and locally.
  Future<int> divergeTransaction({int server = 9999, int local = 1234}) async {
    await h.createPerson('p1');
    await h.createTransaction('t1', personId: 'p1', amount: 1500);
    await cycle();
    final revision = h.remote.seedServerRow(SyncEntityType.moneyTransaction, {
      ...h.remote.rowOf(SyncEntityType.moneyTransaction, 't1')!,
      'amount_minor': server,
    });
    await h.editTransaction('t1', amount: local);
    return revision;
  }

  Future<PeopleData?> person(String id) => (h.db.select(
    h.db.people,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  test('conflict: the operation is blocked, the record is in conflict, and '
      'both versions are kept in sync_conflicts', () async {
    final serverRevision = await divergeTransaction();
    await cycle();

    final op = (await h.opFor('t1'))!;
    expect(op.status, OutboxStatus.blockedConflict);
    expect(op.errorCode, conflictErrorCode);
    expect((await h.metaFor('t1'))!.state, SyncRecordState.conflict);

    final conflict = (await h.openConflict('t1'))!;
    expect(conflict.entityType, 'money_transaction');
    expect(jsonDecode(conflict.localPayloadJson)['amount_minor'], '1234');
    expect(jsonDecode(conflict.serverPayloadJson)['amount_minor'], 9999);
    expect(conflict.serverRevision, serverRevision);
    // The local row is untouched.
    expect((await h.transaction('t1')).amountMinorUnits, 1234);

    final logged = h.logger.events.where((e) => e.$1 == SyncEvent.conflict);
    expect(logged.single.$2, {SyncLogField.entityType: 'money_transaction'});
    expect((await h.store.watchCounts().first).conflicts, 1);
  });

  test(
    'a blocked transaction stops its audit entries from being sent',
    () async {
      await divergeTransaction();
      await cycle();
      await h.createAudit('a1', transactionId: 't1');
      await cycle();
      expect(h.sentEntityIds, isNot(contains('a1')));
      expect((await h.opFor('a1'))!.status, OutboxStatus.pending);
    },
  );

  test('superseded: the delete lost to a concurrent edit, the record is '
      'restored from the server row', () async {
    await h.createPerson('p1', name: 'Amal');
    await cycle();
    h.remote.seedServerRow(SyncEntityType.person, {
      ...h.remote.rowOf(SyncEntityType.person, 'p1')!,
      'name': 'Amal (edited)',
    });
    await h.deletePerson('p1');
    await cycle();

    expect(await h.opFor('p1'), isNull);
    expect((await person('p1'))!.name, 'Amal (edited)');
    expect((await h.metaFor('p1'))!.state, SyncRecordState.synced);
  });

  test('rejected person_has_transactions: the operation is deleted and the '
      'person re-inserted from server_row', () async {
    await h.createPerson('p1', name: 'Amal');
    await h.createTransaction('t1', personId: 'p1');
    await cycle();
    await h.deletePerson('p1');
    await cycle();

    expect(await h.opFor('p1'), isNull);
    expect((await person('p1'))!.name, 'Amal');
    expect((await h.metaFor('p1'))!.state, SyncRecordState.synced);
  });

  test('applied with a server_row (category archived instead of deleted): '
      'the category is re-inserted locally as archived', () async {
    const mapper = FinanceCategorySyncMapper();
    await h.db.transaction(() async {
      await h.db
          .into(h.db.financeCategories)
          .insert(
            FinanceCategoriesCompanion.insert(
              id: 'c1',
              name: 'Books',
              normalizedName: 'books',
              type: 'expense',
              icon: 'education',
              createdAt: 1000,
              updatedAt: 1000,
            ),
          );
      final row = await (h.db.select(
        h.db.financeCategories,
      )..where((c) => c.id.equals('c1'))).getSingle();
      await h.outbox.recordUpsert(
        SyncEntityType.financeCategory,
        'c1',
        mapper.toWire(row),
      );
    });
    await cycle();
    // Another device recorded an entry in it.
    h.remote.seedServerRow(
      SyncEntityType.financeEntry,
      entryRow('e1', categoryId: 'c1'),
    );
    await h.db.transaction(() async {
      final row = await (h.db.select(
        h.db.financeCategories,
      )..where((c) => c.id.equals('c1'))).getSingle();
      await (h.db.delete(
        h.db.financeCategories,
      )..where((c) => c.id.equals('c1'))).go();
      await h.outbox.recordDelete(
        SyncEntityType.financeCategory,
        'c1',
        mapper.toWire(row),
      );
    });
    await cycle();

    final category = await (h.db.select(
      h.db.financeCategories,
    )..where((c) => c.id.equals('c1'))).getSingle();
    expect(category.isArchived, isTrue);
    expect(await h.opFor('c1'), isNull);
  });

  test('a pulled newer server version refreshes the conflict: keep-theirs '
      'applies the latest server version', () async {
    await divergeTransaction(server: 9999);
    await cycle();
    final latest = h.remote.seedServerRow(SyncEntityType.moneyTransaction, {
      ...h.remote.rowOf(SyncEntityType.moneyTransaction, 't1')!,
      'amount_minor': 7777,
    });
    await cycle();
    final conflict = (await h.openConflict('t1'))!;
    expect(conflict.serverRevision, latest);
    expect(jsonDecode(conflict.serverPayloadJson)['amount_minor'], 7777);

    await h.resolver.keepTheirs(SyncEntityType.moneyTransaction, 't1');
    expect((await h.transaction('t1')).amountMinorUnits, 7777);
    expect((await h.metaFor('t1'))!.serverRevision, latest);
  });

  test(
    'interim unhandled_conflict rows are migrated into sync_conflicts',
    () async {
      await divergeTransaction();
      // A build before T071 stored the conflict as failed.
      await (h.db.update(
        h.db.syncOutboxEntries,
      )..where((o) => o.entityId.equals('t1'))).write(
        const SyncOutboxEntriesCompanion(
          status: Value(OutboxStatus.failed),
          errorCode: Value(unhandledConflictErrorCode),
        ),
      );
      await h.db
          .into(h.db.syncRecordMeta)
          .insertOnConflictUpdate(
            SyncRecordMetaCompanion.insert(
              entityType: 'money_transaction',
              entityId: 't1',
              state: SyncRecordState.failed,
              serverRevision: const Value(2),
            ),
          );

      await h.store.resetInFlight(); // on startup
      expect((await h.opFor('t1'))!.status, OutboxStatus.pending);
      await cycle();

      expect((await h.opFor('t1'))!.status, OutboxStatus.blockedConflict);
      expect(await h.openConflict('t1'), isNotNull);
      expect((await h.metaFor('t1'))!.state, SyncRecordState.conflict);
    },
  );

  test(
    'conflict results for a replayed op_id keep a single open conflict',
    () async {
      await divergeTransaction();
      await cycle();
      final op = (await h.opFor('t1'))!;
      // Replayed (e.g. a lost response): the same result arrives again.
      await (h.db.update(
        h.db.syncOutboxEntries,
      )..where((o) => o.opId.equals(op.opId))).write(
        const SyncOutboxEntriesCompanion(status: Value(OutboxStatus.pending)),
      );
      await cycle();
      expect(await h.db.select(h.db.syncConflicts).get(), hasLength(1));
    },
  );
}
