import 'package:daftary/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// T010 — 008's migration is the one place this feature touches a table
/// `transactions` already owns, so it is verified against a database that
/// already holds that feature's rows: the two new tables must appear, the
/// two new `money_transactions` columns must appear with defaults that keep
/// every pre-existing row correct, and nothing already there may move
/// (FR-023).
void main() {
  /// Builds a schemaVersion-5 database by hand — every table the v5 app
  /// shipped with, and no occasions tables — so opening [AppDatabase]
  /// against it runs `onUpgrade(m, 5, 6)` for real rather than a simulation
  /// of it. Same raw-`sqlite3`-handle technique as the v4→v5 test, and for
  /// the same reason: drift skips the migration for a delegate another user
  /// has already opened.
  Database createV5Database() {
    final raw = sqlite3.openInMemory();
    raw.execute('''
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
    ''');
    raw.execute('''
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
    ''');
    raw.execute('''
      CREATE TABLE transaction_audit_entries (
        id TEXT NOT NULL PRIMARY KEY,
        transaction_id TEXT NOT NULL REFERENCES money_transactions (id),
        change_type TEXT NOT NULL,
        previous_values_json TEXT NULL,
        changed_at INTEGER NOT NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE app_settings (
        id TEXT NOT NULL PRIMARY KEY,
        language_code TEXT NOT NULL,
        theme_mode TEXT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE onboarding_status (
        id TEXT NOT NULL PRIMARY KEY,
        is_complete INTEGER NOT NULL DEFAULT 0 CHECK (is_complete IN (0, 1)),
        completed_at INTEGER NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE finance_categories (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0, 1)),
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE finance_entries (
        id TEXT NOT NULL PRIMARY KEY,
        idempotency_key TEXT NOT NULL UNIQUE,
        category_id TEXT NOT NULL REFERENCES finance_categories (id),
        type TEXT NOT NULL,
        amount_minor_units INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT NULL,
        created_at INTEGER NOT NULL,
        edited_at INTEGER NULL,
        deleted_at INTEGER NULL
      );
    ''');
    raw.execute('PRAGMA user_version = 5;');
    return raw;
  }

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

  test('v5 -> v6 creates every index, not just the tables — an upgrading '
      'user must get the same schema as a fresh install', () async {
    final raw = createV5Database();
    insertPreExistingRows(raw);
    final db = openUpgraded(raw);

    final names =
        (await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='index'",
                )
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();

    expect(names, contains('idx_occasions_idempotency_key'));
    expect(names, contains('idx_occasions_date'));
    expect(names, contains('idx_occasions_type'));
    expect(names, contains('idx_occasion_attachments_occasion_id'));
    expect(names, contains('idx_transactions_occasion_id'));
  });

  test('v5 -> v6 creates both occasions tables', () async {
    final raw = createV5Database();
    insertPreExistingRows(raw);
    final db = openUpgraded(raw);

    // Selecting from each table at all proves it was created; an absent
    // table would throw here.
    expect(await db.select(db.occasions).get(), isEmpty);
    expect(await db.select(db.occasionAttachments).get(), isEmpty);
  });

  test('v5 -> v6 adds both money_transactions columns with defaults that '
      'keep every pre-existing row correct (FR-023)', () async {
    final raw = createV5Database();
    insertPreExistingRows(raw);
    final db = openUpgraded(raw);

    final transaction = await db.select(db.moneyTransactions).getSingle();

    // The whole point of the additive migration: a row written before this
    // feature existed is not linked to an occasion (it never was), and it
    // still counts toward its person's balance.
    expect(transaction.occasionId, null);
    expect(transaction.countsTowardBalance, isTrue);
  });

  test('v5 -> v6 leaves every pre-existing row untouched (FR-023)', () async {
    final raw = createV5Database();
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
    expect(transaction.kind, 'initialExchange');
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

  test('the occasions idempotency key is unique — a retried insert with the '
      'same key cannot create a second row (FR-019)', () async {
    final raw = createV5Database();
    final db = openUpgraded(raw);

    Future<void> insertOccasion(String id) => db
        .into(db.occasions)
        .insert(
          OccasionsCompanion.insert(
            id: id,
            idempotencyKey: 'same-key',
            name: "Ahmed's Wedding",
            date: 1000,
            type: 'wedding',
            createdAt: 1000,
            updatedAt: 1000,
          ),
        );

    await insertOccasion('o1');

    await expectLater(insertOccasion('o2'), throwsA(isA<Exception>()));
    expect(await db.select(db.occasions).get(), hasLength(1));
  });

  test('a fresh install starts at schemaVersion 6 with both occasions '
      'tables present', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // A fresh install runs `onCreate`, which never reaches the `from < 6`
    // upgrade branch — `createAll` is what covers it.
    expect(await db.select(db.occasions).get(), isEmpty);
    expect(await db.select(db.occasionAttachments).get(), isEmpty);
    expect(db.schemaVersion, 6);
  });
}
