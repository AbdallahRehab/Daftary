import 'dart:io';

import 'package:drift/drift.dart';
export 'package:drift/drift.dart';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../sync/sync_bootstrap.dart';
import 'finance_category_seed.dart';
import 'migrations/v7_currency_support.dart';
import 'migrations/v9_sync_support.dart';
import 'sync_tables.dart';

export 'sync_tables.dart';

part 'app_database.g.dart';

@TableIndex(name: 'idx_people_normalized_name', columns: {#normalizedName})
@TableIndex(
  name: 'idx_people_archived',
  columns: {#isArchived, #normalizedName},
)
class People extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get relationshipTag => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(
  name: 'idx_transactions_person_id',
  columns: {#personId, #deletedAt},
)
@TableIndex(name: 'idx_transactions_date', columns: {#date, #deletedAt})
class MoneyTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get personId => text().references(People, #id)();
  IntColumn get amountMinorUnits => integer()();

  /// 018: ISO 4217 code of [amountMinorUnits]. Pre-018 rows are backfilled
  /// to explicit `'EGP'` by the v7 migration (FR-002).
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  TextColumn get direction => text()();
  TextColumn get kind => text()();
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_audit_transaction_id', columns: {#transactionId})
class TransactionAuditEntries extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(MoneyTransactions, #id)();
  TextColumn get changeType => text()();
  TextColumn get previousValuesJson => text().nullable()();
  IntColumn get changedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A user-facing label grouping [FinanceEntries] rows. Owned entirely by
/// the `finance` feature — never joined against [People]/[MoneyTransactions]
/// (data-model.md "Relationship to existing entities", FR-023).
@TableIndex(
  name: 'idx_finance_categories_normalized_name',
  columns: {#normalizedName, #type},
)
class FinanceCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Trimmed, whitespace-collapsed, lowercased copy of [name], indexed with
  /// [type] for the FR-008 duplicate check — same precedent as
  /// [People.normalizedName].
  TextColumn get normalizedName => text()();

  /// `'income'` | `'expense'`. Immutable after creation (data-model.md).
  TextColumn get type => text()();

  /// A key into `CategoryIconRegistry`, never a raw icon codepoint or hex
  /// color (research.md Decision 10).
  TextColumn get icon => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single recorded income or expense event belonging to the user. Shaped
/// like [MoneyTransactions] (idempotency key, soft delete, edit marker) but
/// entirely independent of it — it has no `personId` and is never joined
/// against [People] (research.md Decision 1, FR-023).
@TableIndex(
  name: 'idx_finance_entries_category_id',
  columns: {#categoryId, #deletedAt},
)
@TableIndex(name: 'idx_finance_entries_date', columns: {#date, #deletedAt})
class FinanceEntries extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get categoryId => text().references(FinanceCategories, #id)();

  /// `'income'` | `'expense'`. Always equal to the referenced category's
  /// `type` (enforced in the repository, not only by the schema).
  TextColumn get type => text()();
  IntColumn get amountMinorUnits => integer()();

  /// 018: ISO 4217 code of [amountMinorUnits] (backfilled to `'EGP'`).
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The user's language, theme and Liquid Glass preferences. Single-row
/// table (data-model.md): the app always reads/writes the fixed `id`
/// `'singleton'` — there is never more than one row.
class AppSettings extends Table {
  TextColumn get id => text()();
  TextColumn get languageCode => text()();
  TextColumn get themeMode => text().nullable()();

  /// 020: NULL = never set → default (data-model.md).
  BoolColumn get glassEnabled => boolean().nullable()();

  /// 020: a `GlassLevel.value`. NULL = never set → default (data-model.md).
  TextColumn get glassTransparency => text().nullable()();

  /// 020: a `GlassLevel.value`. NULL = never set → default (data-model.md).
  TextColumn get glassIntensity => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Whether the user has finished the onboarding sequence. Single-row table
/// (data-model.md): the app always reads/writes the fixed `id`
/// `'singleton'` — there is never more than one row, same pattern as
/// [AppSettings].
class OnboardingStatus extends Table {
  TextColumn get id => text()();
  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 017 Proactive Insights & Reminders: the device-level notification
/// configuration. Single-row table — the app always reads/writes the fixed
/// `id` `'singleton'`, same pattern as [AppSettings]. Quiet hours are
/// minutes since local midnight, both null or both set (data-model.md).
class NotificationPreferences extends Table {
  TextColumn get id => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get budgetWarningsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get savingsCheckInsEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get quietHoursStartMinutes => integer().nullable()();
  IntColumn get quietHoursEndMinutes => integer().nullable()();
  BoolColumn get osPermissionGranted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 017: the band each notification source was in when it was last notified
/// about — the cooldown bookkeeping behind FR-015/FR-016. `sourceId` is
/// deliberately not a foreign key into 010's/011's tables (data-model.md
/// "Relationships"); a stale id is handled at read time.
///
/// Unique on `(source_type, source_id, applicable_period)`. The period is
/// indexed through `COALESCE(..., '')` because SQLite treats NULLs as
/// distinct in a unique index — without it, savings-goal rows (whose period
/// is always null) could be duplicated.
@TableIndex.sql(
  'CREATE UNIQUE INDEX idx_notification_history_source '
  'ON notification_history '
  "(source_type, source_id, COALESCE(applicable_period, ''))",
)
class NotificationHistory extends Table {
  TextColumn get id => text()();

  /// `'budgetCategory'` | `'savingsGoal'`.
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text()();

  /// `'YYYY-MM'` for budget categories, null for savings goals.
  TextColumn get applicablePeriod => text().nullable()();

  /// A `ThresholdBand` name.
  TextColumn get lastNotifiedBand => text()();
  IntColumn get lastNotifiedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 018 Multi-Currency: the device-wide primary currency. Single-row table —
/// the app always reads/writes the fixed `id` `'singleton'`; an absent row
/// means the EGP default (FR-005).
class PrimaryCurrencySettings extends Table {
  TextColumn get id => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 018: user-maintained manual exchange rates — "1 [currencyCode] =
/// [rateMicros] / 10^6 [relativeToCurrencyCode]". Stored as a scaled integer,
/// never REAL (constitution Principle VIII). Unique per currency pair, so an
/// edit upserts rather than duplicating (data-model.md).
@TableIndex(
  name: 'idx_exchange_rates_pair',
  columns: {#currencyCode, #relativeToCurrencyCode},
  unique: true,
)
class ExchangeRates extends Table {
  TextColumn get id => text()();
  TextColumn get currencyCode => text()();
  TextColumn get relativeToCurrencyCode => text()();
  IntColumn get rateMicros => integer()();
  IntColumn get lastUpdatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The app's single local SQLite database. Opened against a file in the
/// app's sandboxed documents directory (OS-level storage protection —
/// research.md Decision 11), never against a network resource: this
/// feature is fully local-only.
@DriftDatabase(
  tables: [
    People,
    MoneyTransactions,
    TransactionAuditEntries,
    AppSettings,
    OnboardingStatus,
    FinanceCategories,
    FinanceEntries,
    NotificationPreferences,
    NotificationHistory,
    PrimaryCurrencySettings,
    ExchangeRates,
    // 021 Offline-First Cloud Sync (sync_tables.dart).
    SyncOutboxEntries,
    SyncRecordMeta,
    SyncConflicts,
    ConflictResolutions,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [syncBootstrap] queues the pre-existing data for upload once, in
  /// `beforeOpen` (021 T063). The app always passes it; tests that are not
  /// about sync leave it out.
  AppDatabase({SyncBootstrap? syncBootstrap})
    : _syncBootstrap = syncBootstrap,
      super(_openConnection());

  AppDatabase.forTesting(super.executor, {SyncBootstrap? syncBootstrap})
    : _syncBootstrap = syncBootstrap;

  final SyncBootstrap? _syncBootstrap;

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(appSettings);
      }
      if (from < 3) {
        await m.addColumn(appSettings, appSettings.themeMode);
      }
      if (from < 4) {
        await m.createTable(onboardingStatus);
      }
      if (from < 5) {
        await m.createTable(financeCategories);
        await m.createTable(financeEntries);
      }
      if (from < 6) {
        // 017: purely additive — no existing table is touched.
        await m.createTable(notificationPreferences);
        await m.createTable(notificationHistory);
        await m.createIndex(idxNotificationHistorySource);
      }
      if (from < 7) {
        await migrateToCurrencySupport(this, m);
      }
      if (from < 8) {
        // 020: purely additive and nullable — no backfill, so existing rows
        // read as "never set" and resolve to the glass defaults.
        await m.addColumn(appSettings, appSettings.glassEnabled);
        await m.addColumn(appSettings, appSettings.glassTransparency);
        await m.addColumn(appSettings, appSettings.glassIntensity);
      }
      if (from < 9) {
        // 021: the local sync tables, two business indexes and deterministic
        // exchange-rate ids. No reads (data-model.md §3).
        await migrateToSyncSupport(this, m);
      }
    },
    beforeOpen: (details) async {
      // The starter categories are seeded here rather than inside
      // `onUpgrade` because seeding reads the table first (to stay
      // idempotent), and a read issued while a migration is still in
      // flight rolls that migration back — taking the two `createTable`
      // calls above with it. `beforeOpen` runs after the migration has
      // committed, and covers a fresh install (`onCreate`, which never
      // reaches the `from < 5` branch) in the same step.
      //
      // Unguarded on purpose: `seedDefaultFinanceCategories` returns after
      // a single `LIMIT 1` read once the set is present, so running it on
      // every open costs almost nothing and makes the starter set
      // self-healing if an earlier seed was interrupted.
      await seedDefaultFinanceCategories(this);
      // 021: after the seed, so pristine starter categories are recognized
      // and skipped. Guarded by `sync_state.bootstrap_enqueued` alone, set
      // in the same transaction (data-model.md §3).
      await _syncBootstrap?.enqueueExistingDataIfNeeded(this);
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documentsDir.path, 'daftary.sqlite'));
    return NativeDatabase.createInBackground(dbFile);
  });
}
