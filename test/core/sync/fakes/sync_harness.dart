import 'dart:math';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/sync/backoff_policy.dart';
import 'package:daftary/core/sync/local/conflict_resolver.dart';
import 'package:daftary/core/sync/local/sync_applier.dart';
import 'package:daftary/core/sync/local/sync_local_store.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/core/sync/sync_bootstrap.dart';
import 'package:daftary/core/sync/sync_engine.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:daftary/core/sync/sync_mapper_registry.dart';
import 'package:daftary/features/cloud_sync/data/sync/conflict_resolution_sync_mapper.dart';
import 'package:daftary/features/currency/data/sync/exchange_rate_sync_mapper.dart';
import 'package:daftary/features/currency/data/sync/primary_currency_sync_mapper.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart';
import 'package:daftary/features/finance/data/sync/finance_entry_sync_mapper.dart';
import 'package:daftary/features/people/data/sync/person_sync_mapper.dart';
import 'package:daftary/features/transactions/data/sync/money_transaction_sync_mapper.dart';
import 'package:daftary/features/transactions/data/sync/transaction_audit_sync_mapper.dart';
import 'package:drift/native.dart';

import 'fake_sync_remote.dart';
import 'sync_test_doubles.dart';

/// Every real mapper, as the app registers them.
SyncMapperRegistry realMapperRegistry() => SyncMapperRegistry(const [
  PersonSyncMapper(),
  MoneyTransactionSyncMapper(),
  TransactionAuditSyncMapper(),
  FinanceCategorySyncMapper(),
  FinanceEntrySyncMapper(),
  ExchangeRateSyncMapper(),
  PrimaryCurrencySyncMapper(),
  ConflictResolutionSyncMapper(),
]);

/// The real applier, with the app's mappers and pristine-seed rule.
DriftSyncApplier realApplier(AppDatabase db, AppClock clock) =>
    DriftSyncApplier(
      db,
      realMapperRegistry(),
      clock,
      isPristineSeed: isPristineSeed,
    );

/// The real local store, wired like the app wires it.
DriftSyncLocalStore realStore(
  AppDatabase db,
  AppClock clock,
  BackoffPolicy backoff, {
  SyncLogger? logger,
}) => DriftSyncLocalStore(
  db,
  clock,
  backoff,
  realApplier(db, clock),
  SyncBootstrap(
    realMapperRegistry(),
    logger ?? RecordingSyncLogger(),
    clock,
    isPristineSeed: isPristineSeed,
  ),
);

/// A clock for the outbox: 1 ms later on every read, so FIFO order is
/// deterministic, while following [base].
class TickingClock implements AppClock {
  TickingClock(this.base);

  final AppClock base;
  var _ticks = 0;

  @override
  DateTime now() => base.now().add(Duration(milliseconds: _ticks++));
}

/// An in-memory database, the real local store and outbox, and fakes for
/// everything remote. Local writes go through [SyncOutbox] inside a
/// transaction, exactly like the feature DAOs.
class SyncHarness {
  /// Pass one [remote] to several harnesses to simulate several devices of
  /// the same account.
  SyncHarness({AppDatabase? db, FakeClock? clock, FakeSyncRemote? remote})
    : db = db ?? AppDatabase.forTesting(NativeDatabase.memory()),
      clock = clock ?? FakeClock(),
      remote = remote ?? FakeSyncRemote() {
    backoff = BackoffPolicy.withRandom(Random(3));
    bootstrap = SyncBootstrap(
      realMapperRegistry(),
      logger,
      this.clock,
      isPristineSeed: isPristineSeed,
    );
    applier = DriftSyncApplier(
      this.db,
      realMapperRegistry(),
      this.clock,
      isPristineSeed: isPristineSeed,
    );
    store = DriftSyncLocalStore(
      this.db,
      this.clock,
      backoff,
      applier,
      bootstrap,
    );
    outbox = DriftSyncOutbox(this.db, TickingClock(this.clock));
    engine = SyncEngine(
      store,
      this.remote,
      auth,
      supabase,
      connectivity,
      backoff,
      logger,
      this.clock,
      applier,
    );
  }

  final AppDatabase db;
  final FakeClock clock;
  final FakeSyncRemote remote;
  final auth = FakeCloudAuth();
  final supabase = FakeSupabaseInitializer();
  final connectivity = FakeConnectivity();
  final logger = RecordingSyncLogger();
  late final BackoffPolicy backoff;
  late final SyncBootstrap bootstrap;
  late final DriftSyncApplier applier;
  late final DriftSyncLocalStore store;
  late final DriftSyncOutbox outbox;
  late final DriftConflictResolver resolver = DriftConflictResolver(
    db,
    outbox,
    applier,
    realMapperRegistry(),
    clock,
  );
  late final SyncEngine engine;

  static const _person = PersonSyncMapper();
  static const _txn = MoneyTransactionSyncMapper();
  static const _audit = TransactionAuditSyncMapper();

  /// The session now belongs to [uid], on this device and on the server.
  void switchAccount(String uid) {
    auth.uid = uid;
    remote.owner = uid;
  }

  Future<void> close() async {
    await connectivity.close();
    await db.close();
  }

  // --- local writes, the way the DAOs record them -------------------------

  Future<void> createPerson(String id, {String name = 'Person'}) =>
      db.transaction(() async {
        await db
            .into(db.people)
            .insert(
              PeopleCompanion.insert(
                id: id,
                name: name,
                normalizedName: name.toLowerCase(),
                createdAt: 1000,
                updatedAt: 1000,
              ),
            );
        await _recordPerson(id);
      });

  Future<void> renamePerson(String id, String name) => db.transaction(() async {
    await (db.update(db.people)..where((p) => p.id.equals(id))).write(
      PeopleCompanion(
        name: Value(name),
        normalizedName: Value(name.toLowerCase()),
        updatedAt: const Value(2000),
      ),
    );
    await _recordPerson(id);
  });

  Future<void> deletePerson(String id) => db.transaction(() async {
    final row = await (db.select(
      db.people,
    )..where((p) => p.id.equals(id))).getSingle();
    await (db.delete(db.people)..where((p) => p.id.equals(id))).go();
    await outbox.recordDelete(SyncEntityType.person, id, _person.toWire(row));
  });

  Future<void> _recordPerson(String id) async {
    final row = await (db.select(
      db.people,
    )..where((p) => p.id.equals(id))).getSingle();
    await outbox.recordUpsert(SyncEntityType.person, id, _person.toWire(row));
  }

  Future<void> createTransaction(
    String id, {
    required String personId,
    int amount = 1500,
    String? key,
  }) => db.transaction(() async {
    await db
        .into(db.moneyTransactions)
        .insert(
          MoneyTransactionsCompanion.insert(
            id: id,
            idempotencyKey: key ?? 'key-$id',
            personId: personId,
            amountMinorUnits: amount,
            direction: 'given',
            kind: 'initialExchange',
            date: 1000,
            createdAt: 1000,
          ),
        );
    await _recordTransaction(id);
  });

  Future<void> editTransaction(String id, {required int amount}) =>
      db.transaction(() async {
        await (db.update(
          db.moneyTransactions,
        )..where((t) => t.id.equals(id))).write(
          MoneyTransactionsCompanion(
            amountMinorUnits: Value(amount),
            editedAt: const Value(3000),
          ),
        );
        await _recordTransaction(id);
      });

  Future<void> softDeleteTransaction(String id) => db.transaction(() async {
    await (db.update(db.moneyTransactions)..where((t) => t.id.equals(id)))
        .write(const MoneyTransactionsCompanion(deletedAt: Value(4000)));
    await _recordTransaction(id);
  });

  Future<void> _recordTransaction(String id) async {
    final row = await (db.select(
      db.moneyTransactions,
    )..where((t) => t.id.equals(id))).getSingle();
    await outbox.recordUpsert(
      SyncEntityType.moneyTransaction,
      id,
      _txn.toWire(row),
    );
  }

  Future<void> createAudit(String id, {required String transactionId}) =>
      db.transaction(() async {
        await db
            .into(db.transactionAuditEntries)
            .insert(
              TransactionAuditEntriesCompanion.insert(
                id: id,
                transactionId: transactionId,
                changeType: 'created',
                changedAt: 1000,
              ),
            );
        final row = await (db.select(
          db.transactionAuditEntries,
        )..where((a) => a.id.equals(id))).getSingle();
        await outbox.recordUpsert(
          SyncEntityType.transactionAudit,
          id,
          _audit.toWire(row),
        );
      });

  // --- inspection ---------------------------------------------------------

  Future<List<SyncOutboxRow>> outboxRows() =>
      db.select(db.syncOutboxEntries).get();

  Future<SyncOutboxRow?> opFor(String entityId) => (db.select(
    db.syncOutboxEntries,
  )..where((o) => o.entityId.equals(entityId))).getSingleOrNull();

  Future<SyncRecordMetaRow?> metaFor(String entityId) => (db.select(
    db.syncRecordMeta,
  )..where((m) => m.entityId.equals(entityId))).getSingleOrNull();

  Future<SyncStateRow> state() => store.readState();

  /// The open conflict of [entityId], if any.
  Future<SyncConflictRow?> openConflict(String entityId) =>
      (db.select(db.syncConflicts)
            ..where((c) => c.entityId.equals(entityId) & c.resolvedAt.isNull()))
          .getSingleOrNull();

  Future<List<ConflictResolutionRow>> resolutions() =>
      db.select(db.conflictResolutions).get();

  Future<MoneyTransaction> transaction(String id) => (db.select(
    db.moneyTransactions,
  )..where((t) => t.id.equals(id))).getSingle();

  /// Moves the clock past every scheduled retry.
  void skipBackoff() => clock.advance(const Duration(minutes: 20));

  /// The entity ids of every committed push, in order.
  List<String> get sentEntityIds => [
    for (final batch in remote.committedBatches)
      for (final op in batch) op.entityId,
  ];

  static String get synced => SyncRecordState.synced;
}
