import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_sync_remote.dart';
import 'fakes/sync_harness.dart';

/// 022 T053 (A3): two devices edit one savings contribution. Mirrors
/// migration 025: the `financial` policy applies from app 1.1.0; older apps
/// keep last-write-wins.
void main() {
  late FakeSyncRemote server;
  late SyncHarness a;
  late SyncHarness b;

  const type = SyncEntityType.savingsContribution;

  setUp(() async {
    server = FakeSyncRemote();
    a = SyncHarness(remote: server);
    b = SyncHarness(remote: server);
    await a.createGoal('g1');
    await a.createContribution('c1', goalId: 'g1', amount: 100000);
    await a.engine.runCycle();
    await b.engine.runCycle();
    expect((await b.contribution('c1')).amountMinorUnits, 100000);
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  Future<void> bothEdit() async {
    await a.editContribution('c1', amount: 120000);
    await a.engine.runCycle();
    await b.editContribution('c1', amount: 90000);
    await b.engine.runCycle();
  }

  group('at 1.1.0', () {
    setUp(() => server.appVersionOverride = '1.1.0');

    test('the second stale edit is blocked and a conflict opens', () async {
      await bothEdit();
      expect((await b.opFor('c1'))!.status, OutboxStatus.blockedConflict);
      expect(await b.openConflict('c1'), isNotNull);
      expect(await a.openConflict('c1'), isNull);
      // The server keeps the first edit meanwhile.
      expect(server.rowOf(type, 'c1')!['amount_minor_units'], 120000);
    });

    test('keep mine converges on the local edit: 0 open conflicts, 1 '
        'resolution', () async {
      await bothEdit();
      await b.resolver.keepMine(type, 'c1');
      await b.engine.runCycle();
      await a.engine.runCycle();

      expect(await b.openConflict('c1'), isNull);
      expect((await b.resolutions()), hasLength(1));
      expect((await b.resolutions()).single.chosenSide, 'local');
      expect(server.rowOf(type, 'c1')!['amount_minor_units'], 90000);
      expect((await a.contribution('c1')).amountMinorUnits, 90000);
      expect((await b.contribution('c1')).amountMinorUnits, 90000);
      expect(await b.outboxRows(), isEmpty);
    });

    test('keep theirs converges on the server edit: 0 open conflicts, 1 '
        'resolution', () async {
      await bothEdit();
      await b.resolver.keepTheirs(type, 'c1');
      await b.engine.runCycle();
      await a.engine.runCycle();

      expect(await b.openConflict('c1'), isNull);
      expect((await b.resolutions()), hasLength(1));
      expect((await b.resolutions()).single.chosenSide, 'server');
      expect((await a.contribution('c1')).amountMinorUnits, 120000);
      expect((await b.contribution('c1')).amountMinorUnits, 120000);
      expect(await b.outboxRows(), isEmpty);
    });
  });

  test('at 1.0.1 the stale edit is applied (last write wins), no '
      'conflict', () async {
    server.appVersionOverride = '1.0.1';
    await bothEdit();
    await a.engine.runCycle();

    expect(await b.openConflict('c1'), isNull);
    expect(await b.outboxRows(), isEmpty);
    expect(server.rowOf(type, 'c1')!['amount_minor_units'], 90000);
    expect((await a.contribution('c1')).amountMinorUnits, 90000);
  });

  test('an app that does not report a version stays last-write-wins', () async {
    await bothEdit();
    expect(await b.openConflict('c1'), isNull);
  });

  test('FakeSyncRemote.appVersionAtLeast mirrors the SQL helper', () {
    bool atLeast(String? v) => FakeSyncRemote.appVersionAtLeast(v, '1.1.0');
    expect(atLeast('1.1.0'), isTrue);
    expect(atLeast('1.1.0+3'), isTrue);
    expect(atLeast('1.10.0'), isTrue);
    expect(atLeast('2.0'), isTrue);
    expect(atLeast('1.0.1'), isFalse);
    expect(atLeast('1.0.9+99'), isFalse);
    expect(atLeast('1.1'), isTrue);
    expect(atLeast('unknown'), isFalse);
    expect(atLeast(null), isFalse);
    expect(atLeast(''), isFalse);
  });
}
