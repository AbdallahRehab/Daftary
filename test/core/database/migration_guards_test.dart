import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/database/migrations/migration_guards.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// 023 T035: `ensureColumn` adds a missing column once and is a no-op when
/// the column is already there, so an interrupted step can re-run.
void main() {
  late Database raw;
  late AppDatabase db;

  List<String> columnsOf(String table) => [
    for (final c in raw.select('PRAGMA table_info("$table")'))
      c['name'] as String,
  ];

  setUp(() async {
    raw = sqlite3.openInMemory();
    db = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    // Force the open (onCreate) so the schema exists.
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
    raw.close();
  });

  test('adds a missing column, and a second run changes nothing', () async {
    raw.execute('ALTER TABLE sync_state DROP COLUMN b1_repull_done;');
    expect(columnsOf('sync_state'), isNot(contains('b1_repull_done')));

    final m = db.createMigrator();
    await ensureColumn(db, m, db.syncState, db.syncState.b1RepullDone);
    final afterFirst = columnsOf('sync_state');
    expect(afterFirst.where((c) => c == 'b1_repull_done'), hasLength(1));

    await ensureColumn(db, m, db.syncState, db.syncState.b1RepullDone);
    expect(columnsOf('sync_state'), afterFirst);
  });

  test('a column that already exists is left alone (no duplicate-column '
      'error)', () async {
    final before = columnsOf('money_transactions');
    expect(before, contains('import_source'));

    await ensureColumn(
      db,
      db.createMigrator(),
      db.moneyTransactions,
      db.moneyTransactions.importSource,
    );

    expect(columnsOf('money_transactions'), before);
  });

  test('existing rows keep their values and read NULL in the added nullable '
      'column', () async {
    raw.execute('ALTER TABLE finance_entries DROP COLUMN import_source;');
    raw.execute(
      'INSERT INTO finance_categories (id, name, normalized_name, type, icon, '
      "created_at, updated_at) VALUES ('c1', 'Food', 'food', 'expense', "
      "'food', 1, 1)",
    );
    raw.execute(
      'INSERT INTO finance_entries (id, idempotency_key, category_id, type, '
      "amount_minor_units, date, created_at) VALUES ('e1', 'k1', 'c1', "
      "'expense', 1500, 1, 1)",
    );

    await ensureColumn(
      db,
      db.createMigrator(),
      db.financeEntries,
      db.financeEntries.importSource,
    );

    final row = raw.select('SELECT * FROM finance_entries').single;
    expect(row['import_source'], isNull);
    expect(row['amount_minor_units'], 1500);
    expect(row['idempotency_key'], 'k1');
  });
}
