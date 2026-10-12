import '../app_database.dart';
import 'migration_guards.dart';

/// The v12 -> v13 step (023 Bank SMS Import, data-model §11):
///
/// - five local-only tables (`pending_sms_imports`, `sms_import_tombstones`,
///   `sms_sender_mutes`, `sms_merchant_category_mappings`,
///   `sms_import_settings`) and their indexes, all empty;
/// - nullable `import_source` on `money_transactions` and `finance_entries`,
///   with no default, no backfill and no index, so every existing row reads
///   `NULL` ("not imported", FR-057).
///
/// Purely additive: no existing row is read, moved or rewritten, and the
/// settings singleton is not inserted (it is written on first save). Only
/// `sqlite_master` and `PRAGMA table_info` are read, because a Drift read of
/// a table inside `onUpgrade` can roll the migration back.
///
/// One transaction, so a failure leaves the file at v12 and the next open
/// retries cleanly. Every object is guarded, so a file that got past this
/// step without advancing its version, or whose tables an earlier step of
/// the same upgrade already created in today's shape, also re-opens.
///
/// After release this file is frozen: fix forward in v14.
Future<void> migrateToSmsImport(AppDatabase db, Migrator m) {
  return db.transaction(() async {
    await ensureTable(db, m, db.pendingSmsImports);
    await ensureTable(db, m, db.smsImportTombstones);
    await ensureTable(db, m, db.smsSenderMutes);
    await ensureTable(db, m, db.smsMerchantCategoryMappings);
    await ensureTable(db, m, db.smsImportSettings);

    await ensureIndex(db, m, db.idxSmsPendingFingerprint);
    await ensureIndex(db, m, db.idxSmsPendingStatusExpiry);
    await ensureIndex(db, m, db.idxSmsPendingRefHash);
    await ensureIndex(db, m, db.idxSmsPendingAmountPair);
    await ensureIndex(db, m, db.idxSmsTombRefHash);
    await ensureIndex(db, m, db.idxSmsTombRefAmount);
    await ensureIndex(db, m, db.idxSmsTombSavedRecord);
    await ensureIndex(db, m, db.idxSmsTombPurge);

    await ensureColumn(
      db,
      m,
      db.moneyTransactions,
      db.moneyTransactions.importSource,
    );
    await ensureColumn(
      db,
      m,
      db.financeEntries,
      db.financeEntries.importSource,
    );
  });
}
