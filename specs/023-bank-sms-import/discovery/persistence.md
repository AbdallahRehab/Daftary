# Discovery T004: persistence (Drift schema, migrations, wipe, local-only)

Read-only notes for T035 (`ensureColumn`), T036 (schema v13 + `v13_sms_import.dart`), T037 (migration tests), T038 (guard tests), T056 (`SmsImportSettingsDao`) and T059 (settings repository). Anchors are at commit `4a5565d` plus the working tree on `023-bank-sms-import`.

## Flags: where the plan, tasks or data-model are wrong or imprecise

| # | Claim | Reality | What to do |
|---|---|---|---|
| P1 | T035: "`ensureColumn(table, column, ddl)`" | The two existing guards take `(AppDatabase db, Migrator m, ...)` and let Drift generate the DDL (`migration_guards.dart:5-20`). A private `_ensureColumn(db, m, table, column)` already exists in `v10_merge_features.dart:108-120`, and v12 has an inline copy (`v12_finance_entry_audits.dart:24-31`). data-model §11 step 3 uses `ensureColumn(db, m, table, column)`. | Use the **data-model signature** `ensureColumn(AppDatabase db, Migrator m, TableInfo<Table, dynamic> table, GeneratedColumn<Object> column)` and call `m.addColumn(table, column)`. Do not take a raw DDL string. Leave v10 and v12 alone (they keep their private copies). |
| P2 | data-model §4.5: the settings row is "created lazily by the repository (`insertOnConflictUpdate` on first read), exactly as `NotificationPreferences`" | `NotificationPreferences` does **not** insert on first read. `getPreference()` returns `null` when the row is missing (`notifications_dao.dart:18-20`), and the repository maps `null` to `NotificationPreference.defaults` (`notification_preference_repository_impl.dart:21`). The row is written only on **save**, through `insertOnConflictUpdate(companion.copyWith(id: Value('singleton')))` (`notifications_dao.dart:22-31`). | Copy the real pattern: read returns domain defaults when there is no row, and the first write upserts. This also keeps "do not insert the settings singleton" (data-model §11 step 4) and the `data_wipe` "fresh install" equality (`data_wipe_test.dart:374-391`) true. If T056 really needs insert-on-read, do it in its own transaction, outside any migration. |
| P3 | plan.md:11 "four local-only tables, one settings singleton" vs. tasks T036 "five tables" | Both mean the same five tables: four staging tables plus `sms_import_settings`. All **five** go into `localOnlyTables` (data-model §1, line 26). | Add five names. |
| P4 | data-model §1: "`table_classification_guard_test.dart` (exact set at `:157`)" | The exact-set assertion is at `test/core/sync/table_classification_guard_test.dart:153-171` (`expect(localOnlyTables, {...})` at `:155`). | T038 adds the five names to that literal set. |
| P5 | T038: "update `watch_tables_test.dart` for the five new tables" | `watch_tables_test.dart` does not enumerate tables. It watches only `{people, moneyTransactions}` (`:31`), so a new table needs no change for it to pass. | Optional: add one case showing a write to `pending_sms_imports` does not emit on a `{people, moneyTransactions}` watch. Not required for green. |
| P6 | (not stated) the "today's schema minus N" migration fixtures | Every migration test except `v12_migration_test`/`upgrade_financial_snapshot_test` builds its old database from **today's** schema and then drops newer objects with `dropSavingsGoalsAdditions` → `dropFinanceEntryAuditAdditions` (`test/core/database/support/v11_fixture.dart:9-30`). Once v13 exists, those "v10"/"v11" files would still contain the five SMS tables and both `import_source` columns, so the v13 step would be a silent no-op in them. | T037 adds `dropSmsImportAdditions(Database raw)` (drop the five tables, then `ALTER TABLE money_transactions DROP COLUMN import_source;` and the same for `finance_entries`) and calls it **first** inside `dropFinanceEntryAuditAdditions`. Every caller then gets a truthful old shape. `DROP COLUMN` works because `import_source` has no index (the same trick already drops `b1_repull_done`, `v11_fixture.dart:28`). |
| P7 | data-model §10: "`data_wipe_test.dart` (which iterates `allTables`) must pass with them" | It passes only if the fixture fills the new tables. `fixture populates every table in AppDatabase` (`data_wipe_test.dart:340-348`) fails with "`<table>` is empty" until `populateEveryTable()` (`:58-338`) inserts one row into each new table. Foreign keys are ON in that test (`:23`). | T038 adds one insert per SMS table to `populateEveryTable()`. If `pending_sms_imports.parent_import_id` gets a `references(...)`, insert the parent first. The wipe must delete children before parents (see section 4). |
| P8 | Privacy (briefing rule 6) | The repository precedent puts the exception text into the failure: `CacheFailure('Failed to load notification preference: $e')` (`notification_preference_repository_impl.dart:23,37`). A `SqliteException` string includes the bound parameters. | SMS DAOs and repositories must **not** copy that. Use fixed-token messages (see discovery/transactions.md F5). |
| P9 | `pointycastle` "one new `pubspec.yaml` entry" (plan.md:19) | `pubspec.lock:1159-1162` already lists `pointycastle` as `direct main`, so the entry has already been added in this working tree (Phase 1 deps task). | Nothing to do for persistence. Mentioned only so no one adds it twice. |

## 1. Schema version and `onUpgrade`

`lib/core/database/app_database.dart`

- Imports of migration helpers: `:12-16` (`migration_guards.dart`, `v7`, `v9`, `v10`, `v12`). Add `import 'migrations/v13_sms_import.dart';` after `:16`.
- `@DriftDatabase(tables: [...])`: `:708-741`. The last entry is `FinanceEntryAudits` (`:740`). Append the five new table classes after it.
- `schemaVersion => 12`: `:756`. Set it to 13.
- `MigrationStrategy`: `:759-856`. `onCreate: (m) => m.createAll()` (`:760`), so a fresh install gets all v13 objects with no extra code.
- `onUpgrade`: `:761-835`. The last block is:

```dart
      if (from < 12) {
        // 022 D2 + B1 repair: purely additive (finance_entry_audits and
        // sync_state.b1_repull_done), no existing row touched
        // (v12_finance_entry_audits.dart).
        await migrateToFinanceEntryAudits(this, m);
      }
    },                                   // <- :835, end of onUpgrade
```

  Insert the v13 block right after the v12 block (before `:835`):

```dart
      if (from < 13) {
        // 023 Bank SMS Import: purely additive. Five local-only tables and
        // their indexes, plus nullable `import_source` on money_transactions
        // and finance_entries. No existing row is read or written
        // (v13_sms_import.dart).
        await migrateToSmsImport(this, m);
      }
```

- `beforeOpen`: `:836-855`. It seeds finance categories and runs the sync bootstrap. The comment at `:837-843` matters for v13: **a Drift read of a table during `onUpgrade` can roll the migration back**. v13 must read nothing except `sqlite_master` and `PRAGMA table_info`, which the guards already do safely.
- `_openConnection()`: `:858-864`. `NativeDatabase.createInBackground(dbFile)` without `logStatements`. Confirmed: `grep logStatements lib` finds nothing. Keep it that way (T036 Accept).
- Existing column `money_transactions.source` (`TransactionSource`, added by v10 at `v10_merge_features.dart:57`) is unrelated to the new `import_source`. Do not reuse or rename it.

### Single-row table pattern in the schema

`AppSettings` (`:517-534`), `OnboardingStatus` (`:540-547`), `NotificationPreferences` (`:553-569`), `PrimaryCurrencySettings` (`:604-611`), `AiSettings` (`:683-700`, with `@DataClassName('AiSettingsRow')` at `:683`). Shape to copy for `SmsImportSettings`:

```dart
/// 023: the device-level SMS import configuration. Single-row table: the app
/// always reads and writes the fixed `id` `'singleton'`, same pattern as
/// [NotificationPreferences]. An absent row means the defaults below.
class SmsImportSettings extends Table {
  TextColumn get id => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get scanWindowDays => integer().withDefault(const Constant(30))();
  // ... nullable ints for cursor/timestamps, `rulesSeen` text default '{}'
  @override
  Set<Column> get primaryKey => {id};
}
```

Drift names the data class by dropping a trailing "s" (`AppSettings` → `AppSetting`, `app_database.g.dart:2790`; `NotificationPreferences` → `NotificationPreference`), unless `@DataClassName` is given. The newer tables all use `@DataClassName('...Row')`: `AiConversationRow` (`:639`), `AiMessageRow` (`:651`), `AiSettingsRow` (`:683`), and every sync table (`sync_tables.dart:14,65,85,112,131`). **Use `@DataClassName('<Name>Row')` on all five SMS tables** (e.g. `PendingSmsImportRow`, `SmsImportSettingsRow`), so the Drift classes never clash with the domain entities `PendingSmsImport` / `SmsImportSettings`. The Drift `AppSettings` data class already clashes with `package:app_settings` (see permissions-lifecycle.md).

### Index declaration styles in use

- Plain: `@TableIndex(name: 'idx_audit_transaction_id', columns: {#transactionId})` (`:246`), with generated getter `db.idxAuditTransactionId`.
- Unique: `@TableIndex(name: ..., columns: {...}, unique: true)` (`:617-621`, `idx_exchange_rates_pair`).
- Raw SQL (partial or expression): `@TableIndex.sql('CREATE UNIQUE INDEX ... WHERE deleted_at IS NULL')` (`:349-352`, `idx_budgets_month`; `:577-582`, `idx_notification_history_source`). `ensureIndex` works for both, through `index.entityName`.
- `UNIQUE(fingerprint)` can be `text().unique()()` on the column (precedent `idempotencyKey => text().unique()()`, `:59`) or a named unique `@TableIndex`. Prefer the named index, because the plan names it and `ensureIndex` can then guard it.

## 2. Migration guards

`lib/core/database/migrations/migration_guards.dart` (30 lines)

```dart
Future<void> ensureTable(AppDatabase db, Migrator m, TableInfo<Table, dynamic> table)  // :5-13
Future<void> ensureIndex(AppDatabase db, Migrator m, Index index)                      // :16-20
Future<bool> _exists(AppDatabase db, String type, String name)                         // :22-30 (sqlite_master)
```

Body for T035 to add, lifted from `v10_merge_features.dart:108-120` (also matches `v12_finance_entry_audits.dart:24-31`):

```dart
/// Adds [column] to [table] unless `PRAGMA table_info` already lists it, so
/// a step interrupted after adding it (but before the version advanced) can
/// run again.
Future<void> ensureColumn(
  AppDatabase db,
  Migrator m,
  TableInfo<Table, dynamic> table,
  GeneratedColumn<Object> column,
) async {
  final rows = await db
      .customSelect('PRAGMA table_info("${table.actualTableName}")')
      .get();
  if (!rows.any((row) => row.read<String>('name') == column.name)) {
    await m.addColumn(table, column);
  }
}
```

There is no existing `migration_guards_test.dart`. T035 creates it. A pattern to copy: open `AppDatabase.forTesting(NativeDatabase.opened(raw, closeUnderlyingOnClose: false))` over an `sqlite3.openInMemory()`, drop the column with raw SQL, run the guard twice, and assert the column exists once.

## 3. The v12 migration as a template for v13

`lib/core/database/migrations/v12_finance_entry_audits.dart` (43 lines). **Do not edit it** (T036 Accept).

- `migrateToFinanceEntryAudits(AppDatabase db, Migrator m)` returns `db.transaction(() async { ... })` (`:16-33`). One transaction, so a failure leaves the file at the old `user_version` and the next open retries (proved by `v12_migration_test.dart:116-132`).
- Uses `m.createTable`/`m.createIndex` behind a private `_exists`, plus a `PRAGMA table_info` column check.

Template for `lib/core/database/migrations/v13_sms_import.dart`:

```dart
import '../app_database.dart';
import 'migration_guards.dart';

/// The v12 -> v13 step (023 Bank SMS Import): five local-only tables and
/// their indexes, plus nullable `import_source` on `money_transactions` and
/// `finance_entries` (no default, no backfill, no index). Purely additive:
/// no existing row is read, moved or rewritten, and the settings singleton
/// is not inserted (it is created lazily). One transaction, so a failure
/// leaves the file at v12 and the next open retries cleanly. Every object
/// is guarded, so a file that got past this step without advancing its
/// version also re-opens.
Future<void> migrateToSmsImport(AppDatabase db, Migrator m) {
  return db.transaction(() async {
    await ensureTable(db, m, db.pendingSmsImports);
    await ensureTable(db, m, db.smsImportTombstones);
    await ensureTable(db, m, db.smsSenderMutes);
    await ensureTable(db, m, db.smsMerchantCategoryMappings);
    await ensureTable(db, m, db.smsImportSettings);
    await ensureIndex(db, m, db.idxSmsPendingStatusExpiry);
    // ... every other idx_sms_* index
    await ensureColumn(db, m, db.moneyTransactions, db.moneyTransactions.importSource);
    await ensureColumn(db, m, db.financeEntries, db.financeEntries.importSource);
  });
}
```

The v11 block in `app_database.dart:809-828` uses the same `transaction` + `ensureTable`/`ensureIndex` approach inline. Either style works. A separate file matches v12 and the plan.

## 4. Data wipe

`lib/core/database/data_wipe.dart`, `extension DataWipe on AppDatabase`.

- `deleteAllUserData()` at `:28-75`, one `transaction`. The contract comment at `:16-19` says every table in `@DriftDatabase` must appear, children before parents (FK-safe).
- Group comments: people/transactions/OCR `:30-37`, finance/budgets `:38-43`, savings `:44-47`, AI `:48-53`, notifications `:54-56`, currency `:57-59`, sync `:60-68`, single-row prefs `:69-71`, then `seedDefaultFinanceCategories(this)` at `:73`.
- Insert the SMS block before `// single-row preference tables` (`:69`):

```dart
      // bank SMS import (023): staging rows, tombstones, mutes, learned
      // mappings and the settings singleton. All local-only. The two
      // secure-storage keys are purged by `DeleteAllUserData` through
      // `PurgeSmsImportKeys`, not here.
      await delete(pendingSmsImports).go();
      await delete(smsImportTombstones).go();
      await delete(smsSenderMutes).go();
      await delete(smsMerchantCategoryMappings).go();
      await delete(smsImportSettings).go();
```

  Delete `pending_sms_imports` before anything it references. `parent_import_id` is self-referencing, so if it is declared with `references(PendingSmsImports, #id)`, a single `DELETE FROM pending_sms_imports` is still fine in SQLite (the whole statement is checked at the end). No SMS table should reference `money_transactions`/`finance_entries` by FK: `saved_record_id` is a plain text id, like `ocr_scan_id`.
- `userFilePaths()` (`:85-92`) needs no change, because SMS stores no files.
- The secure-storage purge is in the use case `lib/features/data_privacy/domain/usecases/delete_all_user_data.dart:64-66` (`_purgeAIAssistantCredentials()` runs first, then `_secureStorageWiper.wipe()` at `:68`). `PurgeSmsImportKeys` goes beside the AI purge (data-model §10).

## 5. Local-only classification

`lib/core/sync/sync_entity_type.dart`, `const Set<String> localOnlyTables` at `:55-77`. Groups: device prefs (`:56-60`), device files (`:61-66`), AI (`:67-71`), sync machinery (`:72-76`). Add a group:

```dart
  // Bank SMS import (023): staging, decisions and settings never leave the
  // device. Only the confirmed record's `import_source` syncs, on the
  // record itself.
  'pending_sms_imports',
  'sms_import_tombstones',
  'sms_sender_mutes',
  'sms_merchant_category_mappings',
  'sms_import_settings',
```

Enforced by `test/core/sync/table_classification_guard_test.dart`:
- `every table is synced or local-only, and never both` (`:124-143`) iterates `db.allTables`. It fails until the names are added.
- `both lists name only tables that exist` (`:145-149`).
- The exact-set literal at `:153-171` must gain the five names (T038).
- The test calls `configureDependencies()` (`:43`), so the DI graph must also resolve on the host test platform (see di.md).

## 6. Singleton DAO and repository pattern (`NotificationPreferences`)

DAO, `lib/features/insights_notifications/data/datasources/notifications_dao.dart`:

```dart
@injectable
class NotificationsDao {
  NotificationsDao(this._db);
  final db.AppDatabase _db;                       // imported `as db` (:3)
  static const preferenceRowId = 'singleton';     // :14

  Future<db.NotificationPreference?> getPreference() => (_db.select(
    _db.notificationPreferences,
  )..where((t) => t.id.equals(preferenceRowId))).getSingleOrNull();   // :18-20

  Future<db.NotificationPreference> upsertPreference(
    db.NotificationPreferencesCompanion companion,
  ) async {
    await _db
        .into(_db.notificationPreferences)
        .insertOnConflictUpdate(
          companion.copyWith(id: const db.Value(preferenceRowId)),
        );
    return (await getPreference())!;              // :22-31
  }
}
```

Repository, `lib/features/insights_notifications/data/repositories/notification_preference_repository_impl.dart`: `@LazySingleton(as: NotificationPreferenceRepository)` (`:10`); `getPreference()` returns `row?.toDomain() ?? NotificationPreference.defaults` (`:18-25`); `savePreference()` calls `upsertPreference(preference.toCompanion(NotificationsDao.preferenceRowId))` (`:28-39`). Mappers are extensions in `data/models/notification_mappers.dart` (`toCompanion(String id)` at `:22`).

Notes for T056/T059:
- Import the database `as db`, as `NotificationsDao` does. That avoids the Drift `AppSettings` name in scope and keeps `package:app_settings` usable elsewhere.
- Other singletons with the same shape: `SettingsDao._singletonId` (`lib/features/settings/data/datasources/settings_dao.dart:14`), `CurrencyDao.primaryRowId` (`currency_dao.dart:25`), `syncStateId` (`lib/core/sync/local/sync_local_store.dart:84`).
- Counters must be monotonic (T059). Do the increment as one SQL `UPDATE ... SET x = x + ?` (or read-modify-write inside `_db.transaction`), never as a read-then-upsert pair across two awaits.

## 7. Migration fixtures and tests

### A committed v11 fixture exists

- `test/core/database/fixtures/financial_world_v11.sql` (306 lines): a real schema-v11 dump with every table, index and row, ending `PRAGMA user_version = 11`. Generated by `upgrade_financial_snapshot_test.dart` (`:189`).
- `test/core/database/fixtures/financial_snapshot_v11.json`: the figures captured from it.
- Loaded by `v12_migration_test.dart:14-26` (`sqlite3.openInMemory()` then `raw.execute(sqlFile.readAsStringSync())`), by `upgrade_financial_snapshot_test.dart:40,224-246`, and by `test/features/data_privacy/export_sections_test.dart:42`.
- **No v12 fixture is committed.** For the 12 → 13 case, T037 can either open the v11 SQL once (which yields v12 today, v13 after T036), or build "today's schema minus v13" with the new `dropSmsImportAdditions` helper (P6) and set `PRAGMA user_version = 12`. The second is a true 12 → 13 run.
- Do not regenerate `financial_world_v11.sql`. Its doc (`upgrade_financial_snapshot_test.dart:26-29`) says regeneration is only valid "while the schema is still v11".

Helpers in `test/core/database/support/`:
- `v11_fixture.dart`: `dropSavingsGoalsAdditions(raw)` (`:9-14`) → `dropFinanceEntryAuditAdditions(raw)` (`:19-30`). Extend this chain (P6).
- `v9_fixture.dart`: `dropSyncSupportAdditions(raw)` (`:7-15`).
- `feature_line_fixture.dart`: `createFeatureLineDatabase(version)` (`:17`), which calls `dropSavingsGoalsAdditions` at `:28`.

### Tests that hard-code `schemaVersion`/`user_version` 12 (all must become 13 in T037)

| File | Lines |
|---|---|
| `test/core/database/v12_migration_test.dart` | `:36` (test name "schemaVersion is 12"), `:39`, `:68` |
| `test/core/database/app_database_migration_test.dart` | `:102`, `:103` |
| `test/core/database/migration_currency_support_test.dart` | `:308`, `:350`, `:358` (test name at `:354` lists the history; append "023 to 13") |
| `test/core/database/savings_goals_migration_test.dart` | `:108`, `:109`, `:123`, `:207` |
| `test/core/database/notifications_migration_test.dart` | `:87` |
| `test/core/database/sync_v9_migration_test.dart` | `:198` (test name "(12)"), `:199`, `:309`, `:391`, `:392` |
| `test/core/database/merge_v10_migration_test.dart` | `:103`, `:131` |

Command used: `grep -rnE "schemaVersion, 12|values.single, 12" test`. There are no hits outside `test/core/database/`.

Assertions that stay as they are:
- `v12_migration_test.dart:24` and `:128` assert **11** for the loaded fixture and for the rollback case. Leave them. Note that `:128` ("a failure inside the step leaves the file at v11") still holds after v13, because the v12 step fails first.
- `upgrade_financial_snapshot_test.dart:204` (`== 11`) runs only under `UPDATE_FINANCIAL_SNAPSHOT=1`. `:240-244` uses `greaterThanOrEqualTo(11)` and `== env.db.schemaVersion`, so it adapts by itself. After v13 it also proves that 11 → 13 moves no financial figure.
- `ocr_migration_test.dart:165,218` (`>= 7`), `ai_assistant_migration_test.dart:38` (`>= 9`), `occasions_migration_test.dart:249` (`>= 6`) use `greaterThanOrEqualTo`.
- `app_database_migration_test.dart:128` is a test subclass that overrides `schemaVersion => 2`. Leave it.

### v13 test pattern (T037), cloned from `v12_migration_test.dart`

- `loadV11()` (`:21-26`), `open(raw)` (`:28-34`, it forces the open with `db.select(db.financeCategories).get()`).
- Row-equality helper `rows(raw, table)` (`:16-19`) with a before/after compare per table (`:46-71`). For v13, compare every pre-existing table after removing the `import_source` key from the two changed tables, then assert `import_source IS NULL` on every row of both.
- Rollback case (`:116-132`): squat a wrongly shaped `pending_sms_imports` so `CREATE INDEX` fails, then assert `user_version` stays 12 and `import_source` is absent.
- Idempotent re-open: close, open a new `AppDatabase.forTesting` over the same `raw`, and assert `user_version` 13 with unchanged rows.
