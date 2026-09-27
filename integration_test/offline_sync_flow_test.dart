import 'dart:async';
import 'dart:io';

import 'package:daftary/core/config/cloud_config.dart';
import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/core/sync/connectivity_monitor.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart'
    show OutboxStatus;
import 'package:daftary/core/sync/local/sync_local_store.dart';
import 'package:daftary/core/sync/remote/cloud_auth_data_source.dart';
import 'package:daftary/core/sync/remote/supabase_initializer.dart';
import 'package:daftary/core/sync/remote/sync_error_mapper.dart';
import 'package:daftary/core/sync/remote/sync_remote_data_source.dart';
import 'package:daftary/core/sync/sync_bootstrap.dart';
import 'package:daftary/core/sync/sync_models.dart';
import 'package:daftary/core/sync/sync_scheduler.dart';
import 'package:daftary/core/sync/sync_trigger.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/main.dart';
import 'package:drift/native.dart';
import 'package:fpdart/fpdart.dart' show Either, Unit;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// 021 T062: offline changes reach the cloud, end to end, on a device
/// against the local Supabase stack.
///
/// Run with the cloud config (never committed):
///
///     flutter test integration_test/offline_sync_flow_test.dart \
///       --dart-define-from-file=config/supabase.local.json
///
/// Connectivity is driven through [_FakeConnectivityMonitor] (a simulator
/// cannot toggle airplane mode). The remote data source is wrapped in
/// [_ControllableRemote], which can force the backend "down" or lose the
/// response of a push that the server did apply. Cloud state is read back
/// over REST with the app's own session (publishable key + its JWT), so
/// row-level security scopes every query to this test's anonymous user.
///
/// The scenarios run in order and share one database file and one cloud
/// account: each builds on the previous one's data.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  // Without the cloud config (e.g. a plain `flutter test integration_test/`,
  // the T043 offline regression) there is no backend to sync with.
  if (!CloudConfig.isConfigured) {
    testWidgets(
      'offline sync flow (needs the cloud config)',
      (_) async {},
      skip: true,
    );
    return;
  }

  const uuid = Uuid();
  final run = DateTime.now().millisecondsSinceEpoch;
  late File dbFile;
  late _FakeConnectivityMonitor connectivity;
  late _ControllableRemote remote;

  // Shared across the ordered scenarios.
  late Person person;
  late MoneyTransaction transaction;

  /// Wires the real app (real DI) onto [dbFile], with the fake connectivity
  /// and the controllable remote swapped in before anything resolves them.
  Future<void> bootApp({required bool online}) async {
    await configureDependencies();
    getIt
      ..unregister<db.AppDatabase>()
      ..registerSingleton<db.AppDatabase>(
        db.AppDatabase.forTesting(
          NativeDatabase(dbFile),
          syncBootstrap: getIt<SyncBootstrap>(),
        ),
      );
    connectivity = _FakeConnectivityMonitor(online);
    getIt
      ..unregister<ConnectivityMonitor>()
      ..registerSingleton<ConnectivityMonitor>(connectivity);
    remote = _ControllableRemote(getIt<SyncRemoteDataSource>());
    getIt
      ..unregister<SyncRemoteDataSource>()
      ..registerSingleton<SyncRemoteDataSource>(remote);

    await getIt<OnboardingRepository>().completeOnboarding();
    await getIt<AppStartupCubit>().start();
    // What `main()` does once startup is ready.
    await getIt<SyncScheduler>().start();
  }

  /// Simulates an app restart: everything is torn down and the database
  /// file is reopened by a brand-new container.
  Future<void> restartApp({required bool online}) async {
    await getIt<SyncScheduler>().dispose();
    await getIt<db.AppDatabase>().close();
    await getIt.reset();
    await bootApp(online: online);
  }

  SyncScheduler scheduler() => getIt<SyncScheduler>();
  SyncLocalStore store() => getIt<SyncLocalStore>();
  PeopleRepository people() => getIt<PeopleRepository>();
  TransactionsRepository transactions() => getIt<TransactionsRepository>();
  SupabaseClient cloud() => getIt<SupabaseInitializer>().client;
  String uid() => getIt<CloudAuthDataSource>().currentUserId!;

  Future<List<db.SyncOutboxRow>> outbox() {
    final database = getIt<db.AppDatabase>();
    return database.select(database.syncOutboxEntries).get();
  }

  /// Polls [condition] in real time until it holds.
  Future<void> waitUntil(
    Future<bool> Function() condition, {
    Duration timeout = const Duration(seconds: 60),
    String reason = 'condition',
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!await condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail(
          'timed out waiting for $reason '
          '(status: ${scheduler().currentStatus}, '
          'outbox: ${(await outbox()).map((o) => '${o.entityType}:${o.status}:${o.errorCode}').toList()})',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  /// The outbox is empty and the scheduler rests: everything was sent.
  Future<void> waitForSynced() => waitUntil(
    () async =>
        await store().openOpCount() == 0 &&
        scheduler().currentStatus == SchedulerState.idle,
    reason: 'the outbox to drain',
  );

  Future<void> goOnline() async {
    connectivity.set(true);
    await waitForSynced();
  }

  Future<List<Map<String, dynamic>>> cloudRows(String table) async =>
      List<Map<String, dynamic>>.from(await cloud().from(table).select());

  Future<Map<String, dynamic>> cloudRow(String table, String id) async =>
      Map<String, dynamic>.from(
        await cloud().from(table).select().eq('id', id).single(),
      );

  T right<T>(Either<Failure, T> either) =>
      either.getOrElse((f) => fail('unexpected failure $f'));

  Future<MoneyTransaction> addTransaction(String personId, int minor) async =>
      right<MoneyTransaction>(
        await transactions().addTransaction(
          idempotencyKey: uuid.v4(),
          personId: personId,
          amount: Money.egp(minor),
          direction: TransactionDirection.given,
          date: DateTime.now(),
          note: 'T062 $run',
        ),
      );

  setUpAll(() async {
    // A private database file (never the app's own `daftary.sqlite`) and a
    // fresh anonymous cloud account for every run, so "exactly one" below
    // means exactly what this test created.
    final dir = await getTemporaryDirectory();
    dbFile = File(p.join(dir.path, 't062_offline_sync_$run.sqlite'));
    await const FlutterSecureStorage().deleteAll();
    await bootApp(online: false);
  });

  tearDownAll(() async {
    await getIt<SyncScheduler>().dispose();
    await getIt<db.AppDatabase>().close();
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  testWidgets('offline create → restart → online: exactly 1 person and 1 '
      'transaction reach the cloud', (tester) async {
    expect(scheduler().currentStatus, SchedulerState.offline);

    person = right<Person>(
      await people().createPerson(name: 'Offline Person $run'),
    );
    transaction = await addTransaction(person.id, 12345);

    // Queued durably; nothing may leave the device while offline.
    final queued = await outbox();
    expect(
      queued.map((o) => o.entityId),
      containsAll([person.id, transaction.id]),
    );
    expect(queued.every((o) => o.status == OutboxStatus.pending), isTrue);
    expect(remote.pushCalls, 0);
    expect(getIt<SupabaseInitializer>().isInitialized, isFalse);

    await restartApp(online: false);

    // The data survived the restart, locally and in the UI.
    expect(
      right<Person>(await people().getPersonById(person.id)).name,
      person.name,
    );
    final history = right<List<MoneyTransaction>>(
      await transactions().getPersonHistory(person.id),
    );
    expect(history.map((t) => t.id), [transaction.id]);
    appRouter.go('/people');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(person.name), findsWidgets);
    expect(await store().openOpCount(), greaterThanOrEqualTo(2));
    expect(remote.pushCalls, 0);

    await goOnline();

    final cloudPeople = await cloudRows('people');
    final cloudTx = await cloudRows('money_transactions');
    expect(cloudPeople, hasLength(1));
    expect(cloudPeople.single['id'], person.id);
    expect(cloudPeople.single['name'], person.name);
    expect(cloudTx, hasLength(1));
    expect(cloudTx.single['id'], transaction.id);
    expect(cloudTx.single['person_id'], person.id);
    expect(cloudTx.single['amount_minor'], 12345);
    expect(cloudTx.single['idempotency_key'], transaction.idempotencyKey);
    expect(cloudTx.single['owner_id'], uid());
  });

  testWidgets('offline update: edited transaction and person reach the '
      'cloud with the audit row', (tester) async {
    connectivity.set(false);
    await waitUntil(
      () async => scheduler().currentStatus == SchedulerState.offline,
      reason: 'offline status',
    );
    final pushesBefore = remote.pushCalls;

    right<Person>(
      await people().editPerson(
        personId: person.id,
        name: 'Edited Person $run',
        notes: 'edited offline',
      ),
    );
    transaction = right<MoneyTransaction>(
      await transactions().editTransaction(
        transactionId: transaction.id,
        amount: const Money.egp(67890),
        direction: TransactionDirection.received,
        date: transaction.date,
        note: 'edited offline $run',
      ),
    );
    expect(await store().openOpCount(), greaterThanOrEqualTo(3));
    await Future<void>.delayed(const Duration(seconds: 4));
    expect(remote.pushCalls, pushesBefore, reason: 'nothing sent offline');

    await goOnline();

    final p1 = await cloudRow('people', person.id);
    expect(p1['name'], 'Edited Person $run');
    expect(p1['notes'], 'edited offline');
    final t1 = await cloudRow('money_transactions', transaction.id);
    expect(t1['amount_minor'], 67890);
    expect(t1['direction'], 'received');
    expect(t1['note'], 'edited offline $run');
    expect(t1['edited_at'], isNotNull);
    final audits = await cloud()
        .from('transaction_audit_entries')
        .select()
        .eq('transaction_id', transaction.id)
        .eq('change_type', 'edited');
    expect(audits, hasLength(1));
    // The audit keeps the pre-edit values.
    expect(audits.single['previous_values'], isNotNull);
    // Still exactly one of each: the edits updated, never duplicated.
    expect(await cloudRows('people'), hasLength(1));
    expect(await cloudRows('money_transactions'), hasLength(1));
  });

  testWidgets('offline delete and archive: the cloud shows deleted_at and '
      'is_archived', (tester) async {
    connectivity.set(false);
    right<Unit>(await transactions().deleteTransaction(transaction.id));
    right<Unit>(await people().archivePerson(person.id));
    expect(await store().openOpCount(), greaterThanOrEqualTo(2));

    await goOnline();

    final t1 = await cloudRow('money_transactions', transaction.id);
    expect(t1['deleted_at'], isNotNull);
    final p1 = await cloudRow('people', person.id);
    expect(p1['is_archived'], isTrue);
    expect(p1['deleted_at'], isNull);
    final deletedAudits = await cloud()
        .from('transaction_audit_entries')
        .select()
        .eq('transaction_id', transaction.id)
        .eq('change_type', 'deleted');
    expect(deletedAudits, hasLength(1));
  });

  testWidgets('failed sync: the remote is down → operations stay pending → '
      'restored → retry → synced', (tester) async {
    remote.down = true;
    final failuresBefore = remote.failedCalls;
    final second = right<Person>(
      await people().createPerson(name: 'Retry Person $run'),
    );
    final tx = await addTransaction(second.id, 500);

    // The write trigger (3 s debounce) sends the batch, which fails.
    await waitUntil(
      () async =>
          remote.failedCalls > failuresBefore &&
          scheduler().currentStatus == SchedulerState.backingOff,
      reason: 'the forced failure and backoff',
    );
    final pending = (await outbox())
        .where((o) => o.entityId == second.id || o.entityId == tx.id)
        .toList();
    expect(pending, isNotEmpty);
    expect(pending.every((o) => o.status == OutboxStatus.pending), isTrue);
    expect(pending.every((o) => o.errorCode == SyncErrorCode.network), isTrue);
    expect(await cloud().from('people').select().eq('id', second.id), isEmpty);
    expect((await store().readState()).consecutiveFailures, greaterThan(0));

    // The backend comes back; "Sync now" retries without waiting out the
    // backoff.
    remote.down = false;
    scheduler().request(SyncTrigger.manual);
    await scheduler().idle;
    await waitForSynced();

    expect((await cloudRow('people', second.id))['name'], second.name);
    expect((await cloudRow('money_transactions', tx.id))['amount_minor'], 500);
    expect((await store().readState()).consecutiveFailures, 0);
  });

  testWidgets('duplicate prevention: an upload interrupted after the server '
      'applied it and repeated creates no duplicate', (tester) async {
    final people_ = await cloudRows('people');
    final retryPerson = people_.firstWhere(
      (row) => (row['name'] as String).startsWith('Retry Person'),
    );
    remote.dropNextResponse = true;
    final applied = remote.appliedButLost;
    final tx = await addTransaction(retryPerson['id'] as String, 777);

    // The server applies the batch but the response never arrives.
    await waitUntil(
      () async => remote.appliedButLost > applied,
      reason: 'the interrupted upload',
    );
    await waitUntil(
      () async => scheduler().currentStatus == SchedulerState.backingOff,
      reason: 'backoff after the lost response',
    );
    final open = (await outbox()).where((o) => o.entityId == tx.id).toList();
    expect(open, hasLength(1));
    expect(open.single.status, OutboxStatus.pending);
    // It already is in the cloud, once.
    expect(
      await cloud().from('money_transactions').select().eq('id', tx.id),
      hasLength(1),
    );

    // Repeat the upload with the same operations.
    scheduler().request(SyncTrigger.manual);
    await scheduler().idle;
    await waitForSynced();

    expect(
      remote.lastResults.whereType<PushApplied>().any((r) => r.alreadyApplied),
      isTrue,
      reason: 'the server recognized the replay (already_applied)',
    );
    final all = await cloudRows('money_transactions');
    expect(all.where((row) => row['id'] == tx.id), hasLength(1));
    // GROUP BY idempotency_key HAVING count(*) > 1 → no rows.
    final byKey = <String, int>{};
    for (final row in all) {
      final key = row['idempotency_key'] as String;
      byKey[key] = (byKey[key] ?? 0) + 1;
    }
    expect(byKey.entries.where((e) => e.value > 1), isEmpty);
    expect(all, hasLength(3));
    expect(await cloudRows('people'), hasLength(2));
    // ignore: avoid_print
    print('T062 cloud owner_id: ${uid()}');
  });
}

/// Connectivity the test controls (the simulator cannot toggle airplane
/// mode).
class _FakeConnectivityMonitor implements ConnectivityMonitor {
  _FakeConnectivityMonitor(this._value);

  bool _value;
  final _changes = StreamController<bool>.broadcast();

  void set(bool value) {
    if (value == _value) return;
    _value = value;
    _changes.add(value);
  }

  @override
  Stream<bool> get hasNetwork => _changes.stream;

  @override
  Future<bool> currentHasNetwork() async => _value;
}

/// The real remote data source, with two failure switches.
class _ControllableRemote implements SyncRemoteDataSource {
  _ControllableRemote(this._real);

  final SyncRemoteDataSource _real;

  /// Every call fails as if the backend were unreachable.
  bool down = false;

  /// The next push reaches the server, which applies it, but its response
  /// is lost (an interrupted upload).
  bool dropNextResponse = false;

  int pushCalls = 0;
  int failedCalls = 0;
  int appliedButLost = 0;
  List<PushResult> lastResults = const [];

  SyncRemoteException _unreachable() =>
      SyncErrorMapper.map(const SocketException('T062: backend forced down'));

  @override
  Future<List<PushResult>> push(List<OutboxOp> ops, DeviceInfo device) async {
    pushCalls++;
    if (down) {
      failedCalls++;
      throw _unreachable();
    }
    final results = await _real.push(ops, device);
    if (dropNextResponse) {
      dropNextResponse = false;
      appliedButLost++;
      throw _unreachable();
    }
    lastResults = results;
    return results;
  }

  @override
  Future<PullPage> pull({required int since, int limit = 500}) {
    if (down) {
      failedCalls++;
      throw _unreachable();
    }
    return _real.pull(since: since, limit: limit);
  }
}
