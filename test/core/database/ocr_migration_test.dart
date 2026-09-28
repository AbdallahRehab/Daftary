// `hide isNull`: drift re-exports a column helper of that name, which would
// otherwise shadow the matcher this file uses.
import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// T009 — the v6→v7 migration that adds 009's two tables and the two
/// additive columns on `money_transactions`.
///
/// The property under test is the one an upgrading user actually cares
/// about: their existing transactions must survive untouched and keep
/// reporting themselves as manually entered, because they were. An
/// additive migration that silently relabelled historical rows as
/// OCR-sourced would be a quiet lie about where someone's records came
/// from — which is exactly the kind of thing 009 FR-012 exists to prevent.
///
/// Same raw-`sqlite3`-handle technique as the 008 migration test, and for
/// the same reason: drift skips the migration for a delegate another user
/// has already opened.
void main() {
  /// Builds a schemaVersion-6 database by hand — every table the v6 app
  /// shipped with, and no OCR tables — so opening [AppDatabase] against it
  /// runs `onUpgrade(m, 6, 7)` for real rather than a simulation of it.
  Database createV6Database() {
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
      CREATE TABLE occasions (
        id TEXT NOT NULL PRIMARY KEY,
        idempotency_key TEXT NOT NULL,
        name TEXT NOT NULL,
        date INTEGER NOT NULL,
        type TEXT NOT NULL,
        notes TEXT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      );
    ''');
    // v6's shape: 008's two columns present, 009's two absent.
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
        occasion_id TEXT NULL REFERENCES occasions (id),
        counts_toward_balance INTEGER NOT NULL DEFAULT 1
          CHECK (counts_toward_balance IN (0, 1)),
        created_at INTEGER NOT NULL,
        edited_at INTEGER NULL,
        deleted_at INTEGER NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE occasion_attachments (
        id TEXT NOT NULL PRIMARY KEY,
        occasion_id TEXT NOT NULL REFERENCES occasions (id),
        file_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
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
    raw.execute('PRAGMA user_version = 6;');
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
      "VALUES ('t1', 'k1', 'p1', 50000, 'given', 'initialExchange', 200, "
      "'lunch', 200);",
    );
  }

  test('a v6 database upgrades to v7 with both OCR tables created', () async {
    final raw = createV6Database();
    final db = openUpgraded(raw);

    expect(await db.select(db.ocrScans).get(), isEmpty);
    expect(await db.select(db.candidateEntries).get(), isEmpty);
    expect(db.schemaVersion, greaterThanOrEqualTo(7));
  });

  test('an existing transaction survives the upgrade and reports itself as '
      'manually entered, because it was (FR-012)', () async {
    final raw = createV6Database();
    insertPreExistingRows(raw);
    final db = openUpgraded(raw);

    final rows = await db.select(db.moneyTransactions).get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.id, 't1');
    expect(row.amountMinorUnits, 50000);
    expect(row.note, 'lunch');
    expect(row.occasionId, isNull);
    expect(row.countsTowardBalance, isTrue);
    // The two new columns, defaulted rather than backfilled.
    expect(row.source, 'manual');
    expect(row.ocrScanId, isNull);
  });

  test("the scans table's idempotency-key index is UNIQUE — the whole "
      'mechanism behind an idempotent batch confirm (FR-021)', () async {
    final raw = createV6Database();
    final db = openUpgraded(raw);

    Future<void> insertScan(String id) => db
        .into(db.ocrScans)
        .insert(
          OcrScansCompanion.insert(
            id: id,
            idempotencyKey: 'same-key',
            sourceImagePath: '/tmp/$id.png',
            status: 'needsReview',
            createdAt: 100,
          ),
        );

    await insertScan('s1');
    // Without the index carried across by the migration this second insert
    // would succeed, and a double-tapped confirm would save twice.
    await expectLater(insertScan('s2'), throwsA(isA<Exception>()));
    expect(await db.select(db.ocrScans).get(), hasLength(1));
  });

  test('a fresh install gets the OCR tables from onCreate, not from the '
      'upgrade branch', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.select(db.ocrScans).get(), isEmpty);
    expect(await db.select(db.candidateEntries).get(), isEmpty);
    expect(db.schemaVersion, greaterThanOrEqualTo(7));
  });
}
