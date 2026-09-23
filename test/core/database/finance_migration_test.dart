import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/database/finance_category_seed.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// T005 — the v4→v5 migration is the only task in this feature that touches
/// a file `people`/`transactions` already own, so it is verified against a
/// database that already holds their rows: the two new tables must appear,
/// the starter categories must be inserted exactly once, and nothing that
/// was already there may move.
void main() {
  /// Builds a schemaVersion-4 database by hand — every table the v4 app
  /// shipped with, and no finance tables — so opening [AppDatabase] against
  /// it runs `onUpgrade(m, 4, 5)` for real rather than a simulation of it.
  ///
  /// The schema is written through a raw `sqlite3` handle that is then
  /// handed to `NativeDatabase.opened`, rather than through a
  /// `NativeDatabase` that has already been `ensureOpen`ed: drift treats a
  /// delegate as open once any user has opened it and skips the migration
  /// for every later user, so the pre-existing-executor shape would assert
  /// against a database no migration ever ran on.
  Database createV4Database() {
    final raw = sqlite3.openInMemory();
    raw.execute("""
      CREATE TABLE people (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        phone_number TEXT NULL,
        avatar_path TEXT NULL,
        relationship_tag TEXT NULL,
        notes TEXT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    """);
    raw.execute("""
      CREATE TABLE money_transactions (
        id TEXT NOT NULL PRIMARY KEY,
        idempotency_key TEXT NOT NULL UNIQUE,
        person_id TEXT NOT NULL REFERENCES people (id),
        amount_minor_units INTEGER NOT NULL,
        direction TEXT NOT NULL,
        kind TEXT NOT NULL,
        date INTEGER NOT NULL,
        note TEXT NULL,
        created_at INTEGER NOT NULL,
        edited_at INTEGER NULL,
        deleted_at INTEGER NULL
      );
    """);
    raw.execute("""
      CREATE TABLE transaction_audit_entries (
        id TEXT NOT NULL PRIMARY KEY,
        transaction_id TEXT NOT NULL REFERENCES money_transactions (id),
        change_type TEXT NOT NULL,
        previous_values_json TEXT NULL,
        changed_at INTEGER NOT NULL
      );
    """);
    raw.execute("""
      CREATE TABLE app_settings (
        id TEXT NOT NULL PRIMARY KEY,
        language_code TEXT NOT NULL,
        theme_mode TEXT NULL,
        updated_at INTEGER NOT NULL
      );
    """);
    raw.execute("""
      CREATE TABLE onboarding_status (
        id TEXT NOT NULL PRIMARY KEY,
        is_complete INTEGER NOT NULL DEFAULT 0 CHECK (is_complete IN (0, 1)),
        completed_at INTEGER NULL
      );
    """);
    raw.execute('PRAGMA user_version = 4;');
    return raw;
  }

  /// Opens the real [AppDatabase] against [raw], which triggers the v4 -> v5
  /// migration.
  AppDatabase openUpgraded(Database raw) {
    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);
    return db;
  }

  /// Pre-existing user data the migration must leave exactly as it found it.
  void insertPreExistingRows(Database raw) {
    raw.execute(
      "INSERT INTO people (id, name, normalized_name, is_archived, "
      "created_at, updated_at) "
      "VALUES ('p1', 'Ahmed', 'ahmed', 0, 100, 100);",
    );
    raw.execute(
      "INSERT INTO money_transactions (id, idempotency_key, person_id, "
      "amount_minor_units, direction, kind, date, note, created_at) "
      "VALUES ('t1', 'key-1', 'p1', 25000, 'given', 'initialExchange', "
      "200, 'lunch', 200);",
    );
    raw.execute(
      "INSERT INTO transaction_audit_entries (id, transaction_id, "
      "change_type, changed_at) VALUES ('a1', 't1', 'created', 200);",
    );
    raw.execute(
      "INSERT INTO app_settings (id, language_code, theme_mode, updated_at) "
      "VALUES ('singleton', 'ar', 'dark', 300);",
    );
  }

  test('v4 -> v5 creates both finance tables', () async {
    final raw = createV4Database();
    insertPreExistingRows(raw);
    final db = openUpgraded(raw);

    // Selecting from each table at all proves it was created; an absent
    // table would throw here.
    expect(await db.select(db.financeEntries).get(), isEmpty);
    expect(await db.select(db.financeCategories).get(), isNotEmpty);
  });

  test('v4 -> v5 seeds the 22 starter categories exactly once', () async {
    final raw = createV4Database();
    insertPreExistingRows(raw);
    final db = openUpgraded(raw);

    final categories = await db.select(db.financeCategories).get();

    expect(categories, hasLength(defaultFinanceCategorySeeds.length));
    expect(categories, hasLength(22));
    expect(
      categories.where((c) => c.type == 'expense'),
      hasLength(16),
      reason: 'data-model.md seeds 16 expense categories',
    );
    expect(
      categories.where((c) => c.type == 'income'),
      hasLength(6),
      reason: 'data-model.md seeds 6 income categories',
    );
    expect(
      categories.every((c) => c.isDefault && !c.isArchived),
      isTrue,
      reason: 'seeded rows are isDefault = true, isArchived = false',
    );

    // Exactly once: no key appears twice.
    final ids = categories.map((c) => c.id).toSet();
    expect(ids, hasLength(categories.length));
  });

  test('seeding is idempotent — re-running it over a populated table inserts '
      'nothing', () async {
    final raw = createV4Database();
    final db = openUpgraded(raw);

    final afterMigration = await db.select(db.financeCategories).get();
    await seedDefaultFinanceCategories(db);
    final afterSecondCall = await db.select(db.financeCategories).get();

    expect(afterSecondCall, hasLength(afterMigration.length));
  });

  test('v4 -> v5 leaves every pre-existing row untouched (FR-023)', () async {
    final raw = createV4Database();
    insertPreExistingRows(raw);
    final db = openUpgraded(raw);

    final person = await db.select(db.people).getSingle();
    expect(person.id, 'p1');
    expect(person.name, 'Ahmed');
    expect(person.isArchived, isFalse);
    expect(person.createdAt, 100);

    final transaction = await db.select(db.moneyTransactions).getSingle();
    expect(transaction.id, 't1');
    expect(transaction.personId, 'p1');
    expect(transaction.amountMinorUnits, 25000);
    expect(transaction.direction, 'given');
    expect(transaction.note, 'lunch');
    expect(transaction.deletedAt, null);

    final audit = await db.select(db.transactionAuditEntries).getSingle();
    expect(audit.id, 'a1');
    expect(audit.transactionId, 't1');
    expect(audit.changeType, 'created');

    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.languageCode, 'ar');
    expect(settings.themeMode, 'dark');
  });

  test('a fresh install seeds the starter categories too', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // A fresh install runs `onCreate`, which never reaches the `from < 5`
    // upgrade branch — the `beforeOpen` hook is what covers it.
    final categories = await db.select(db.financeCategories).get();
    expect(categories, hasLength(22));
  });
}
