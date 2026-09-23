import 'dart:io';

import 'package:drift/drift.dart';
export 'package:drift/drift.dart';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'finance_category_seed.dart';

part 'app_database.g.dart';

@TableIndex(name: 'idx_people_normalized_name', columns: {#normalizedName})
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
@TableIndex(
  name: 'idx_transactions_occasion_id',
  columns: {#occasionId, #deletedAt},
)
class MoneyTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get personId => text().references(People, #id)();
  IntColumn get amountMinorUnits => integer()();
  TextColumn get direction => text()();
  TextColumn get kind => text()();
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();

  /// The [Occasions] row this contribution was recorded under (008).
  /// `NULL` for every ordinary transaction — which is every row that
  /// existed before this feature, so the migration needs no backfill.
  TextColumn get occasionId => text().nullable().references(Occasions, #id)();

  /// Whether this row counts toward the person's net balance (008 FR-018).
  /// `TRUE` for every kind but an occasion contribution recorded as
  /// non-counting, so the default keeps all pre-existing rows correct.
  BoolColumn get countsTowardBalance =>
      boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A named social event the user tracks money around (008). Carries no
/// money of its own: its totals are always aggregated from the
/// [MoneyTransactions] rows pointing at it, never stored here
/// (008 research.md Decision 4).
@TableIndex(
  name: 'idx_occasions_idempotency_key',
  columns: {#idempotencyKey},
  unique: true,
)
@TableIndex(name: 'idx_occasions_date', columns: {#date, #deletedAt})
@TableIndex(name: 'idx_occasions_type', columns: {#type})
class Occasions extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get name => text()();

  /// Epoch millis, date-only. May be in the future (pre-planned occasions).
  IntColumn get date => integer()();

  /// A standard `OccasionType` value or free text, same open-set pattern as
  /// [People.relationshipTag] (008 research.md Decision 6).
  TextColumn get type => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A photo attached to an [Occasions] row (008 FR-017). Only a local path
/// into the app's private sandboxed storage is stored — never a remote URL,
/// and the bytes are never uploaded.
@TableIndex(
  name: 'idx_occasion_attachments_occasion_id',
  columns: {#occasionId, #deletedAt},
)
class OccasionAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get occasionId => text().references(Occasions, #id)();
  TextColumn get filePath => text()();
  IntColumn get createdAt => integer()();
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
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The user's language preference. Single-row table (data-model.md): the
/// app always reads/writes the fixed `id` `'singleton'` — there is never
/// more than one row.
class AppSettings extends Table {
  TextColumn get id => text()();
  TextColumn get languageCode => text()();
  TextColumn get themeMode => text().nullable()();
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
    Occasions,
    OccasionAttachments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

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
        await m.createTable(occasions);
        await m.createTable(occasionAttachments);
        // `createTable` does not carry a table's `@TableIndex` declarations
        // across, so an upgrading user would otherwise get the occasions
        // tables without them — including the UNIQUE index that is the whole
        // enforcement mechanism behind FR-019's idempotent create. A fresh
        // install gets them from `createAll`; these four lines are what make
        // the two paths produce the same schema.
        await m.createIndex(idxOccasionsIdempotencyKey);
        await m.createIndex(idxOccasionsDate);
        await m.createIndex(idxOccasionsType);
        await m.createIndex(idxOccasionAttachmentsOccasionId);
        // Additive only: both columns are nullable or defaulted, so every
        // pre-008 `money_transactions` row stays valid with no backfill —
        // it simply isn't linked to an occasion, which it never was.
        await m.addColumn(moneyTransactions, moneyTransactions.occasionId);
        await m.addColumn(
          moneyTransactions,
          moneyTransactions.countsTowardBalance,
        );
        await m.createIndex(idxTransactionsOccasionId);
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
