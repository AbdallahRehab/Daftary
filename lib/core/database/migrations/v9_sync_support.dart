import '../app_database.dart';

/// 021 Offline-First Cloud Sync — the v8 -> v9 schema step (data-model.md
/// §3). Purely additive apart from the exchange-rate id rewrite:
///
/// 1. the five local sync tables and their indexes;
/// 2. two business-table indexes for the list and date queries;
/// 3. deterministic exchange-rate ids, `rate_<CUR>_<REL>` (research.md
///    Decision 9). Nothing references `exchange_rates.id`, and the unique
///    pair index guarantees the new ids cannot collide.
///
/// It performs **no reads**: a read issued while a migration is in flight
/// rolls the migration back (see the `beforeOpen` comment in
/// `app_database.dart`). Enqueuing the pre-existing data therefore happens
/// after the migration commits, never here.
///
/// The whole step runs in one explicit transaction: drift does not wrap
/// `onUpgrade` in one on its own, so without it a failure in step 3 would
/// leave the step-1 tables behind at `user_version = 8`, and every later
/// open would fail on "index already exists". With it, any failure rolls
/// the file back to its exact v8 state and the next open retries cleanly.
Future<void> migrateToSyncSupport(AppDatabase db, Migrator m) {
  return db.transaction(() => _migrate(db, m));
}

Future<void> _migrate(AppDatabase db, Migrator m) async {
  // Step 1: the sync tables.
  await m.createTable(db.syncOutboxEntries);
  await m.createIndex(db.idxOutboxReady);
  await m.createIndex(db.idxOutboxEntity);
  await m.createTable(db.syncRecordMeta);
  await m.createIndex(db.idxMetaState);
  await m.createTable(db.syncConflicts);
  await m.createIndex(db.idxConflictsOpen);
  await m.createTable(db.conflictResolutions);
  await m.createTable(db.syncState);

  // Step 2: business-table indexes (plan §3, performance).
  await m.createIndex(db.idxTransactionsDate);
  await m.createIndex(db.idxPeopleArchived);

  // Step 3: deterministic exchange-rate ids.
  await db.customStatement(
    "UPDATE exchange_rates SET id = 'rate_' || currency_code || '_' || "
    'relative_to_currency_code',
  );
}
