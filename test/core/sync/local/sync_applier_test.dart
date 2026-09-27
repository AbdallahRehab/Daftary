import 'dart:convert';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/database/watch_tables.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/local/sync_applier.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/server_rows.dart';
import '../fakes/sync_harness.dart';

/// 021 T068: every row of contracts/sync-rpc.md §4.
void main() {
  late SyncHarness h;

  setUp(() => h = SyncHarness());
  tearDown(() => h.close());

  PulledChange change(SyncEntityType type, Map<String, Object?> row) =>
      PulledChange(
        entityType: type,
        revision: row['revision']! as int,
        row: row,
      );

  Future<void> apply(List<PulledChange> changes, {bool hasMore = false}) =>
      h.applier.applyPage(
        PullPage(
          changes: changes,
          maxRevision: changes.isEmpty ? 0 : changes.last.revision,
          hasMore: hasMore,
        ),
      );

  Future<PeopleData?> person(String id) => (h.db.select(
    h.db.people,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<MoneyTransaction?> txn(String id) => (h.db.select(
    h.db.moneyTransactions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<FinanceCategory?> category(String id) => (h.db.select(
    h.db.financeCategories,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> outboxCount() async => (await h.outboxRows()).length;

  test('no local row: inserts it and marks it synced at the revision; '
      'never records an outbox entry', () async {
    await apply([
      change(SyncEntityType.person, personRow('p1', name: 'Amal')),
      change(
        SyncEntityType.moneyTransaction,
        transactionRow('t1', personId: 'p1', amount: 150000, revision: 2),
      ),
    ]);
    expect((await person('p1'))!.name, 'Amal');
    expect((await txn('t1'))!.amountMinorUnits, 150000);
    final meta = await h.metaFor('t1');
    expect(meta!.state, SyncRecordState.synced);
    expect(meta.serverRevision, 2);
    expect(await outboxCount(), 0);
    expect((await h.state()).lastPulledRevision, 2);
  });

  test('local row without an open operation: business fields overwritten, '
      'the local avatarPath kept', () async {
    await h.createPerson('p1', name: 'Old');
    await h.engine.runCycle();
    await (h.db.update(h.db.people)..where((p) => p.id.equals('p1'))).write(
      const PeopleCompanion(avatarPath: Value('/local/avatar.png')),
    );

    await apply([
      change(
        SyncEntityType.person,
        personRow('p1', name: 'New', archived: true, revision: 9),
      ),
    ]);
    final row = (await person('p1'))!;
    expect(row.name, 'New');
    expect(row.isArchived, isTrue);
    expect(row.avatarPath, '/local/avatar.png');
    expect((await h.metaFor('p1'))!.serverRevision, 9);
    expect(await outboxCount(), 0);
  });

  test(
    'local row with an open operation: the business row is skipped',
    () async {
      await h.createPerson('p1', name: 'Mine');
      final outcome = await h.applier.applyServerRow(
        SyncEntityType.person,
        personRow('p1', name: 'Theirs', revision: 4),
      );
      expect(outcome, ApplyOutcome.skipped);
      expect((await person('p1'))!.name, 'Mine');
      expect((await h.metaFor('p1'))!.state, SyncRecordState.pending);
      expect(await outboxCount(), 1);
    },
  );

  test('an open blocked_conflict operation: the conflict is refreshed to the '
      'newer server version, the local row kept', () async {
    await h.createPerson('p1');
    await h.createTransaction('t1', personId: 'p1', amount: 100);
    await (h.db.update(
      h.db.syncOutboxEntries,
    )..where((o) => o.entityId.equals('t1'))).write(
      const SyncOutboxEntriesCompanion(
        status: Value(OutboxStatus.blockedConflict),
      ),
    );
    await h.db
        .into(h.db.syncConflicts)
        .insert(
          SyncConflictsCompanion.insert(
            id: 'c1',
            entityType: 'money_transaction',
            entityId: 't1',
            localPayloadJson: '{}',
            serverPayloadJson: '{"amount_minor":200}',
            serverRevision: 3,
            detectedAt: 0,
          ),
        );

    await apply([
      change(
        SyncEntityType.moneyTransaction,
        transactionRow('t1', personId: 'p1', amount: 300, revision: 7),
      ),
    ]);
    final conflict = await h.db.select(h.db.syncConflicts).getSingle();
    expect(conflict.serverRevision, 7);
    expect(jsonDecode(conflict.serverPayloadJson)['amount_minor'], 300);
    expect((await txn('t1'))!.amountMinorUnits, 100);
    expect((await h.state()).lastPulledRevision, 7);
  });

  group('tombstones', () {
    test('hard-delete people, categories and rates', () async {
      await apply([
        change(SyncEntityType.person, personRow('p1', revision: 1)),
        change(SyncEntityType.financeCategory, categoryRow('c1', revision: 2)),
        change(SyncEntityType.exchangeRate, rateRow('USD', 'EGP', revision: 3)),
      ]);
      expect(await person('p1'), isNotNull);

      await apply([
        change(
          SyncEntityType.person,
          personRow('p1', revision: 4, deletedAt: '2026-02-01T00:00:00Z'),
        ),
        change(
          SyncEntityType.financeCategory,
          categoryRow('c1', revision: 5, deletedAt: '2026-02-01T00:00:00Z'),
        ),
        change(
          SyncEntityType.exchangeRate,
          rateRow('USD', 'EGP', revision: 6, deletedAt: '2026-02-01T00:00:00Z'),
        ),
      ]);
      expect(await person('p1'), isNull);
      expect(await category('c1'), isNull);
      expect(await h.db.select(h.db.exchangeRates).get(), isEmpty);
      expect((await h.metaFor('p1'))!.serverRevision, 4);
      expect(await outboxCount(), 0);
    });

    test(
      'a person tombstone is not applied while an operation is open',
      () async {
        await h.createPerson('p1');
        await apply([
          change(
            SyncEntityType.person,
            personRow('p1', revision: 4, deletedAt: '2026-02-01T00:00:00Z'),
          ),
        ]);
        expect(await person('p1'), isNotNull);
      },
    );

    test('soft-delete transactions and entries', () async {
      await apply([
        change(SyncEntityType.person, personRow('p1', revision: 1)),
        change(
          SyncEntityType.moneyTransaction,
          transactionRow('t1', personId: 'p1', revision: 2),
        ),
        change(
          SyncEntityType.financeEntry,
          entryRow('e1', categoryId: 'seed_rent', revision: 3),
        ),
        change(
          SyncEntityType.moneyTransaction,
          transactionRow(
            't1',
            personId: 'p1',
            revision: 4,
            deletedAt: '2026-02-01T00:00:00.000Z',
          ),
        ),
        change(
          SyncEntityType.financeEntry,
          entryRow(
            'e1',
            categoryId: 'seed_rent',
            revision: 5,
            deletedAt: '2026-02-01T00:00:00.000Z',
          ),
        ),
      ]);
      expect((await txn('t1'))!.deletedAt, isNotNull);
      final entry = await h.db.select(h.db.financeEntries).getSingle();
      expect(entry.deletedAt, isNotNull);
    });
  });

  test('a pristine seed category is overwritten by the downloaded row, even '
      'with a no-op operation open', () async {
    final seed = (await category('seed_rent'))!;
    // Changed and changed back: still pristine, but an upsert is queued.
    await h.db.transaction(
      () => h.outbox.recordUpsert(
        SyncEntityType.financeCategory,
        'seed_rent',
        const {'id': 'seed_rent'},
      ),
    );
    await apply([
      change(
        SyncEntityType.financeCategory,
        categoryRow(
          'seed_rent',
          name: 'Housing',
          icon: seed.icon,
          isDefault: true,
          revision: 3,
        ),
      ),
    ]);
    expect((await category('seed_rent'))!.name, 'Housing');
    expect(await outboxCount(), 0);
  });

  test('a failure mid-page rolls the page back and leaves the cursor '
      'unchanged', () async {
    await expectLater(
      apply([
        change(SyncEntityType.person, personRow('p1', revision: 1)),
        change(SyncEntityType.person, {
          ...personRow('p2', revision: 2),
          'name': 42,
        }),
      ]),
      throwsFormatException,
    );
    expect(await person('p1'), isNull);
    expect(await h.metaFor('p1'), isNull);
    expect((await h.state()).lastPulledRevision, 0);
  });

  test('an empty page still advances the cursor to max_revision', () async {
    await h.applier.applyPage(
      const PullPage(changes: [], maxRevision: 12, hasMore: false),
    );
    expect((await h.state()).lastPulledRevision, 12);
  });

  test('a watch stream emits after applyPage', () async {
    final events = <void>[];
    final sub = h.db
        .changesOf({h.db.moneyTransactions}, debounce: Duration.zero)
        .listen(events.add);
    await pumpEventQueue();
    expect(events, hasLength(1));

    await apply([
      change(SyncEntityType.person, personRow('p1')),
      change(
        SyncEntityType.moneyTransaction,
        transactionRow('t1', personId: 'p1'),
      ),
    ]);
    await pumpEventQueue();
    expect(events.length, greaterThanOrEqualTo(2));
    await sub.cancel();
  });

  test('applied rows record no outbox entries for any type', () async {
    await apply([
      change(SyncEntityType.person, personRow('p1', revision: 1)),
      change(
        SyncEntityType.moneyTransaction,
        transactionRow('t1', personId: 'p1', revision: 2),
      ),
      change(SyncEntityType.transactionAudit, {
        'id': 'a1',
        'revision': 3,
        'transaction_id': 't1',
        'change_type': 'created',
        'previous_values': null,
        'changed_at': '2026-01-02T10:00:00.000Z',
      }),
      change(SyncEntityType.financeCategory, categoryRow('c1', revision: 4)),
      change(
        SyncEntityType.financeEntry,
        entryRow('e1', categoryId: 'c1', revision: 5),
      ),
      change(SyncEntityType.exchangeRate, rateRow('USD', 'EGP', revision: 6)),
      change(SyncEntityType.primaryCurrency, {
        'id': 'singleton',
        'revision': 7,
        'currency_code': 'USD',
        'client_updated_at': '2026-01-02T10:00:00.000Z',
      }),
      change(SyncEntityType.conflictResolution, {
        'id': 'r1',
        'revision': 8,
        'entity_type': 'money_transaction',
        'entity_id': 't1',
        'chosen_side': 'local',
        'discarded_values': {'amount_minor': 1},
        'resolved_at': '2026-01-02T10:00:00.000Z',
      }),
    ]);
    expect(await outboxCount(), 0);
    expect(
      (await h.db.select(h.db.primaryCurrencySettings).getSingle())
          .currencyCode,
      'USD',
    );
    expect(await h.db.select(h.db.conflictResolutions).get(), hasLength(1));
    expect((await h.state()).lastPulledRevision, 8);
  });
}
