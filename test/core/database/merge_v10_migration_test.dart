// `hide isNull`: drift re-exports a column helper of that name, which would
// otherwise shadow the matcher this file uses.
import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/feature_line_fixture.dart';
import 'support/v11_fixture.dart';

/// The v10 step that joins the two pre-merge lines (v10_merge_features.dart):
/// a `main` v9 file and a feature-line v9 file both end with exactly the
/// schema a fresh install has, and keep every row they held.
void main() {
  Set<String> columnsOf(Database raw, String table) => {
    for (final row in raw.select('PRAGMA table_info("$table")'))
      row['name'] as String,
  };

  /// Every table with its column set, and every index name — the schema's
  /// identity. Column order is left out: an upgrade appends added columns,
  /// which changes nothing the app reads.
  Map<String, Object> schemaOf(Database raw) => {
    for (final row in raw.select(
      "SELECT name, type FROM sqlite_master WHERE type IN ('table', 'index') "
      "AND name NOT LIKE 'sqlite_%'",
    ))
      row['name'] as String: row['type'] == 'table'
          ? columnsOf(raw, row['name'] as String)
          : 'index',
  };

  Future<Map<String, Object>> freshSchema() async {
    final raw = sqlite3.openInMemory();
    final db = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await db.customSelect('SELECT 1').get();
    await db.close();
    final schema = schemaOf(raw);
    raw.close();
    return schema;
  }

  /// A `main` v9 file: today's schema minus exactly what v10 adds.
  Future<Database> createMainV9Database() async {
    final raw = sqlite3.openInMemory();
    final bootstrap = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await bootstrap.customSelect('SELECT 1').get();
    await bootstrap.close();
    for (final table in [
      'ai_messages',
      'ai_conversations',
      'ai_settings',
      'budget_category_allocations',
      'budgets',
      'candidate_entries',
      'ocr_scans',
      'occasion_attachments',
    ]) {
      raw.execute('DROP TABLE $table;');
    }
    raw.execute('DROP INDEX idx_transactions_occasion_id;');
    raw.execute('DROP INDEX idx_transactions_ocr_scan_id;');
    for (final column in [
      'occasion_id',
      'counts_toward_balance',
      'source',
      'ocr_scan_id',
    ]) {
      raw.execute('ALTER TABLE money_transactions DROP COLUMN $column;');
    }
    raw.execute('DROP TABLE occasions;');
    dropSavingsGoalsAdditions(raw);
    raw.execute('PRAGMA user_version = 9;');
    return raw;
  }

  void seedPersonAndTransaction(Database raw, {bool withCurrency = true}) {
    raw.execute(
      'INSERT INTO people (id, name, normalized_name, is_archived, '
      "created_at, updated_at) VALUES ('p1', 'Ahmed', 'ahmed', 0, 1, 1)",
    );
    raw.execute(
      'INSERT INTO money_transactions (id, idempotency_key, person_id, '
      'amount_minor_units, ${withCurrency ? 'currency_code, ' : ''}direction, '
      'kind, date, created_at) VALUES '
      "('t1', 'k1', 'p1', 25000, ${withCurrency ? "'USD', " : ''}'given', "
      "'initialExchange', 2, 2)",
    );
  }

  test('a main v9 file gains the merged features and matches a fresh '
      'install exactly', () async {
    final raw = await createMainV9Database();
    seedPersonAndTransaction(raw);
    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final row = await db.select(db.moneyTransactions).getSingle();
    expect(raw.select('PRAGMA user_version').single.values.single, 11);
    expect(schemaOf(raw), await freshSchema());
    // The existing row reads as what it always was.
    expect(row.currencyCode, 'USD');
    expect(row.occasionId, isNull);
    expect(row.countsTowardBalance, isTrue);
    expect(row.source, 'manual');
  });

  test('a feature-line v9 file replays main\'s v6..v9 and matches a fresh '
      'install exactly', () async {
    final raw = await createFeatureLineDatabase(9);
    seedPersonAndTransaction(raw, withCurrency: false);
    raw.execute(
      'INSERT INTO occasions (id, idempotency_key, name, date, type, '
      "created_at, updated_at) VALUES ('o1', 'ok1', 'Wedding', 3, "
      "'wedding', 3, 3)",
    );
    raw.execute(
      'INSERT INTO budgets (id, idempotency_key, month, created_at, '
      "updated_at) VALUES ('b1', 'bk1', '2026-03', 4, 4)",
    );
    expect(columnsOf(raw, 'app_settings'), isNot(contains('glass_enabled')));

    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();

    expect(raw.select('PRAGMA user_version').single.values.single, 11);
    expect(schemaOf(raw), await freshSchema());
    // main's steps ran: the pre-merge amounts are labelled EGP (018) and the
    // budget, planned when EGP was the only currency, is in EGP too.
    expect(
      (await db.select(db.moneyTransactions).getSingle()).currencyCode,
      'EGP',
    );
    expect((await db.select(db.budgets).getSingle()).currencyCode, 'EGP');
    expect((await db.select(db.occasions).getSingle()).name, 'Wedding');
  });

  for (final version in [6, 7, 8]) {
    test('a feature-line v$version file also reaches the fresh-install '
        'schema', () async {
      final raw = await createFeatureLineDatabase(version);
      final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();

      expect(schemaOf(raw), await freshSchema());
    });
  }
}
