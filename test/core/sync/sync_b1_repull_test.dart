import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:daftary/core/sync/sync_engine.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:daftary/features/finance/data/sync/finance_entry_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/server_rows.dart';
import 'fakes/sync_harness.dart';

/// 022 T044 (B1 repair, research R7): the download position only moves
/// forward, so rows downloaded before the date fix stay one day off. The
/// first cycle of the fixed app resets the position to 0 once
/// (`sync_state.b1_repull_done`), re-applying every server row; rows with
/// pending local changes keep their local value.
void main() {
  late SyncHarness h;

  setUp(() => h = SyncHarness());
  tearDown(() => h.close());

  final sept30 = DateTime(2026, 9, 30).millisecondsSinceEpoch;
  final oct1 = DateTime(2026, 10, 1).millisecondsSinceEpoch;

  /// A server row dated 2026-10-01 entered on a UTC+3 device.
  Map<String, Object?> serverEntry(String id) => {
    ...entryRow(id, categoryId: 'seed_groceries'),
    'occurred_on': '2026-10-01',
    'occurred_at': '2026-09-30T21:00:00.000Z',
    'tz_offset_minutes': 180,
  };

  Future<void> localEntry(String id, {bool pending = false}) async {
    await h.db
        .into(h.db.financeEntries)
        .insert(
          FinanceEntriesCompanion.insert(
            id: id,
            idempotencyKey: 'key-$id',
            categoryId: 'seed_groceries',
            type: 'expense',
            amountMinorUnits: 2500,
            date: sept30,
            note: const Value('local'),
            createdAt: 1000,
          ),
        );
    if (!pending) return;
    final row = await (h.db.select(
      h.db.financeEntries,
    )..where((e) => e.id.equals(id))).getSingle();
    await h.db.transaction(
      () => h.outbox.recordUpsert(
        SyncEntityType.financeEntry,
        id,
        const FinanceEntrySyncMapper().toWire(row),
      ),
    );
    // Not due yet, so the push phase leaves it pending.
    await (h.db.update(h.db.syncOutboxEntries)).write(
      SyncOutboxEntriesCompanion(
        nextAttemptAt: Value(
          h.clock.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
        ),
      ),
    );
  }

  Future<int> dateOf(String id) async => (await (h.db.select(
    h.db.financeEntries,
  )..where((e) => e.id.equals(id))).getSingle()).date;

  Future<void> seedAlreadyPulled() async {
    // The cursor is past the row's revision, as on an installed app.
    await h.store.writeState((s) => s.copyWith(lastPulledRevision: 500));
  }

  List<int> pullStarts() => [
    for (final e in h.logger.events)
      if (e.$1 == SyncEvent.downloadStarted)
        e.$2[SyncLogField.revision]! as int,
  ];

  test('the first cycle re-pulls from 0: the row shows the server day, the '
      'flag is set, and the second cycle does no full re-pull', () async {
    await localEntry('e1');
    h.remote.seedServerRow(SyncEntityType.financeEntry, serverEntry('e1'));
    await seedAlreadyPulled();
    expect((await h.state()).b1RepullDone, isFalse);

    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);

    expect(await dateOf('e1'), oct1);
    expect((await h.state()).b1RepullDone, isTrue);
    expect(pullStarts().first, 0);

    final before = pullStarts().length;
    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);
    final second = pullStarts().sublist(before);
    expect(second, isNotEmpty);
    expect(second.first, isNot(0));
  });

  test('a row with a pending outbox operation keeps its local value', () async {
    await localEntry('e1', pending: true);
    h.remote.seedServerRow(SyncEntityType.financeEntry, serverEntry('e1'));
    await seedAlreadyPulled();

    await h.engine.runCycle();

    expect(await dateOf('e1'), sept30);
    expect((await h.opFor('e1'))!.status, 'pending');
    expect((await h.state()).b1RepullDone, isTrue);
  });

  test(
    'the flag is not set while sync cannot reach the pull (offline)',
    () async {
      h.connectivity.online = false;
      await h.engine.runCycle();
      expect((await h.state()).b1RepullDone, isFalse);
    },
  );

  test('a re-pull that fails on page 2 resumes from page 1, not from 0, and '
      'the flag stays set', () async {
    // 600 server rows: page 1 (500) then page 2 (100).
    for (var i = 0; i < 600; i++) {
      h.remote.seedServerRow(
        SyncEntityType.person,
        personRow('p$i', revision: 1),
      );
    }
    await seedAlreadyPulled();
    h.remote.failPullOnCall(2);

    final first = await h.engine.runCycle();
    expect(first.result, SyncCycleResult.retryScheduled);
    final afterFailure = await h.state();
    expect(afterFailure.b1RepullDone, isTrue);
    expect(afterFailure.lastPulledRevision, 500);

    h.skipBackoff();
    final before = pullStarts().length;
    expect(await h.engine.runCycle(), SyncCycleOutcome.completed);
    expect(pullStarts().sublist(before).first, 500);
    expect((await h.state()).lastPulledRevision, 600);
    expect((await h.state()).b1RepullDone, isTrue);
  });
}
