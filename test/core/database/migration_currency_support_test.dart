import 'package:daftary/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/v9_fixture.dart';

/// 018 T020 + T056 — the v6 -> v7 migration (research.md Decision 3,
/// FR-002/SC-001): every pre-existing amount is labelled `'EGP'`, nothing
/// else about any row changes, the two new tables (and the unique pair
/// index) appear, and a fresh install ends up with the same shape.
void main() {
  const personCount = 20;
  const transactionCount = 50;
  const customCategoryCount = 3;
  const entryCount = 40;

  /// A schemaVersion-6 database. Built by letting drift create today's
  /// schema and then removing exactly what 018 added, so it cannot drift
  /// from the real v6 tables the way a hand-written copy could (same
  /// approach as notifications_migration_test.dart). The raw handle is
  /// later handed to `NativeDatabase.opened` so `onUpgrade(m, 6, 7)` runs
  /// for real.
  Future<Database> createV6Database() async {
    final raw = sqlite3.openInMemory();
    final bootstrap = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await bootstrap.select(bootstrap.financeCategories).get();
    await bootstrap.close();

    raw.execute('DROP INDEX idx_exchange_rates_pair;');
    raw.execute('DROP TABLE exchange_rates;');
    raw.execute('DROP TABLE primary_currency_settings;');
    raw.execute('ALTER TABLE money_transactions DROP COLUMN currency_code;');
    raw.execute('ALTER TABLE finance_entries DROP COLUMN currency_code;');
    // 020 (v8) additions, so the upgrade runs v6 -> v7 -> v8 for real.
    raw.execute('ALTER TABLE app_settings DROP COLUMN glass_enabled;');
    raw.execute('ALTER TABLE app_settings DROP COLUMN glass_transparency;');
    raw.execute('ALTER TABLE app_settings DROP COLUMN glass_intensity;');
    // 021 (v9) additions, so the upgrade runs through v9 for real.
    dropSyncSupportAdditions(raw);
    raw.execute('PRAGMA user_version = 6;');
    return raw;
  }

  List<String> columnsOf(Database raw, String table) => [
    for (final row in raw.select('PRAGMA table_info("$table")'))
      row['name'] as String,
  ];

  int amountFor(int i) => switch (i % 5) {
    0 => 0,
    1 => 1,
    2 => -(i * 1234567),
    3 => 99,
    _ => 900000000000 + i,
  };

  /// Seeds 20 people, 50 transactions (some soft-deleted / edited), 3
  /// custom categories on top of the 22 seeded ones, and 40 finance
  /// entries — 135 records in total across the four tables.
  void seed(Database raw) {
    for (var p = 0; p < personCount; p++) {
      raw.execute(
        'INSERT INTO people (id, name, normalized_name, is_archived, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        ['p$p', 'Person $p', 'person $p', p.isEven ? 0 : 1, p, p],
      );
    }
    for (var t = 0; t < transactionCount; t++) {
      raw.execute(
        'INSERT INTO money_transactions (id, idempotency_key, person_id, '
        'amount_minor_units, direction, kind, date, note, created_at, '
        'edited_at, deleted_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          't$t',
          'tk$t',
          'p${t % personCount}',
          amountFor(t),
          t.isEven ? 'given' : 'received',
          'initialExchange',
          1000 + t,
          t % 3 == 0 ? null : 'note $t',
          1000 + t,
          t % 7 == 0 ? 2000 + t : null,
          t % 11 == 0 ? 3000 + t : null,
        ],
      );
    }
    for (var c = 0; c < customCategoryCount; c++) {
      raw.execute(
        'INSERT INTO finance_categories (id, name, normalized_name, type, '
        'icon, is_default, is_archived, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?)',
        ['c$c', 'Custom $c', 'custom $c', 'expense', 'other', c, c],
      );
    }
    for (var e = 0; e < entryCount; e++) {
      raw.execute(
        'INSERT INTO finance_entries (id, idempotency_key, category_id, type, '
        'amount_minor_units, date, note, created_at, edited_at, deleted_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'e$e',
          'ek$e',
          'c${e % customCategoryCount}',
          'expense',
          amountFor(e).abs() + 1,
          5000 + e,
          e.isOdd ? 'entry $e' : null,
          5000 + e,
          e % 4 == 0 ? 6000 + e : null,
          e % 9 == 0 ? 7000 + e : null,
        ],
      );
    }
  }

  /// Every pre-existing column value of [table], keyed by id, excluding
  /// the new currency column — the snapshot the migration must preserve.
  Map<String, Map<String, Object?>> snapshot(Database raw, String table) => {
    for (final row in raw.select('SELECT * FROM $table'))
      row['id'] as String: {
        for (final key in row.keys)
          if (key != 'currency_code') key: row[key],
      },
  };

  Future<AppDatabase> openUpgraded(Database raw) async {
    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);
    // Any query opens the database, which runs the migration.
    await db.customSelect('SELECT 1').get();
    return db;
  }

  test('the hand-built v6 fixture really is pre-018', () async {
    final raw = await createV6Database();
    addTearDown(raw.close);
    expect(
      columnsOf(raw, 'money_transactions'),
      isNot(contains('currency_code')),
    );
    expect(columnsOf(raw, 'finance_entries'), isNot(contains('currency_code')));
    final tables = raw
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((r) => r['name'])
        .toList();
    expect(tables, isNot(contains('exchange_rates')));
    expect(tables, isNot(contains('primary_currency_settings')));
    expect(tables, contains('notification_history'));
  });

  group('v6 -> v7 with ≥100 pre-existing records', () {
    late Database raw;
    late AppDatabase db;
    late Map<String, Map<String, Map<String, Object?>>> before;

    const tables = [
      'people',
      'money_transactions',
      'finance_categories',
      'finance_entries',
    ];

    setUp(() async {
      raw = await createV6Database();
      seed(raw);
      before = {for (final t in tables) t: snapshot(raw, t)};
      db = await openUpgraded(raw);
    });

    test('the fixture seeds at least 100 records', () {
      final total = before.values.fold<int>(0, (sum, t) => sum + t.length);
      expect(total, greaterThanOrEqualTo(100));
      expect(before['money_transactions'], hasLength(transactionCount));
      expect(before['finance_entries'], hasLength(entryCount));
    });

    test('every money_transactions row is labelled EGP, zero NULLs', () async {
      final rows = await db.select(db.moneyTransactions).get();
      expect(rows, hasLength(transactionCount));
      expect(rows.every((r) => r.currencyCode == 'EGP'), isTrue);
      final nulls = raw.select(
        'SELECT COUNT(*) AS n FROM money_transactions '
        'WHERE currency_code IS NULL',
      );
      expect(nulls.single['n'], 0);
      final notEgp = raw.select(
        "SELECT COUNT(*) AS n FROM money_transactions "
        "WHERE currency_code <> 'EGP'",
      );
      expect(notEgp.single['n'], 0);
    });

    test('every finance_entries row is labelled EGP, zero NULLs', () async {
      final rows = await db.select(db.financeEntries).get();
      expect(rows, hasLength(entryCount));
      expect(rows.every((r) => r.currencyCode == 'EGP'), isTrue);
      final nulls = raw.select(
        'SELECT COUNT(*) AS n FROM finance_entries WHERE currency_code IS NULL',
      );
      expect(nulls.single['n'], 0);
    });

    test('row counts and every pre-existing value (amounts included) are '
        'unchanged', () {
      for (final table in tables) {
        final after = snapshot(raw, table);
        expect(after.length, before[table]!.length, reason: table);
        expect(after, before[table], reason: table);
      }
    });

    test('the sum of amounts is unchanged', () {
      int sumOf(String table) =>
          raw
                  .select('SELECT SUM(amount_minor_units) AS s FROM $table')
                  .single['s']
              as int;
      int beforeSum(String table) => before[table]!.values.fold<int>(
        0,
        (s, r) => s + (r['amount_minor_units']! as int),
      );
      expect(sumOf('money_transactions'), beforeSum('money_transactions'));
      expect(sumOf('finance_entries'), beforeSum('finance_entries'));
    });

    test('creates primary_currency_settings and exchange_rates', () async {
      expect(await db.select(db.primaryCurrencySettings).get(), isEmpty);
      expect(await db.select(db.exchangeRates).get(), isEmpty);
    });

    test('the unique pair index rejects a duplicate currency pair', () {
      final index = raw.select(
        "SELECT sql FROM sqlite_master WHERE type = 'index' "
        "AND name = 'idx_exchange_rates_pair'",
      );
      expect(index.single['sql'] as String, contains('UNIQUE'));

      raw.execute(
        'INSERT INTO exchange_rates (id, currency_code, '
        'relative_to_currency_code, rate_micros, last_updated_at) '
        "VALUES ('r1', 'USD', 'EGP', 48500000, 1)",
      );
      // The reverse pair is a different pair and is allowed.
      raw.execute(
        'INSERT INTO exchange_rates (id, currency_code, '
        'relative_to_currency_code, rate_micros, last_updated_at) '
        "VALUES ('r2', 'EGP', 'USD', 20619, 1)",
      );
      expect(
        () => raw.execute(
          'INSERT INTO exchange_rates (id, currency_code, '
          'relative_to_currency_code, rate_micros, last_updated_at) '
          "VALUES ('r3', 'USD', 'EGP', 50000000, 2)",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('new writes after the upgrade default to EGP', () {
      raw.execute(
        'INSERT INTO money_transactions (id, idempotency_key, person_id, '
        'amount_minor_units, direction, kind, date, created_at) '
        "VALUES ('new', 'new-key', 'p0', 1, 'given', 'initialExchange', 1, 1)",
      );
      final row = raw.select(
        "SELECT currency_code FROM money_transactions WHERE id = 'new'",
      );
      expect(row.single['currency_code'], 'EGP');
    });
  });

  test(
    'upgrading straight from v4 (finance tables created in the same '
    'run) reaches the latest version without a duplicate-column failure',
    () async {
      // Regression: `from < 5` creates finance_entries with today's schema
      // (already holding currency_code), so the v7 step must not add it again.
      final raw = await createV6Database();
      raw.execute('DROP INDEX idx_notification_history_source;');
      raw.execute('DROP TABLE notification_history;');
      raw.execute('DROP TABLE notification_preferences;');
      raw.execute('DROP TABLE finance_entries;');
      raw.execute('DROP TABLE finance_categories;');
      raw.execute(
        'INSERT INTO people (id, name, normalized_name, is_archived, '
        "created_at, updated_at) VALUES ('p1', 'A', 'a', 0, 1, 1)",
      );
      raw.execute(
        'INSERT INTO money_transactions (id, idempotency_key, person_id, '
        'amount_minor_units, direction, kind, date, created_at) '
        "VALUES ('t1', 'k1', 'p1', 25000, 'given', 'initialExchange', 1, 1)",
      );
      raw.execute('PRAGMA user_version = 4;');

      final db = await openUpgraded(raw);

      final tx = await db.select(db.moneyTransactions).getSingle();
      expect(tx.currencyCode, 'EGP');
      expect(tx.amountMinorUnits, 25000);
      expect(columnsOf(raw, 'finance_entries'), contains('currency_code'));
      expect(await db.select(db.exchangeRates).get(), isEmpty);
      expect(raw.select('PRAGMA user_version').single.values.single, 9);
    },
  );

  group('fresh install (onCreate)', () {
    test('has the currency columns, NOT NULL with an EGP default', () async {
      final raw = sqlite3.openInMemory();
      final db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      addTearDown(() async {
        await db.close();
        raw.close();
      });
      await db.customSelect('SELECT 1').get();

      for (final table in ['money_transactions', 'finance_entries']) {
        final column = raw
            .select('PRAGMA table_info("$table")')
            .singleWhere((r) => r['name'] == 'currency_code');
        expect(column['notnull'], 1, reason: table);
        expect(column['dflt_value'], "'EGP'", reason: table);
      }
      expect(
        columnsOf(raw, 'exchange_rates'),
        containsAll([
          'id',
          'currency_code',
          'relative_to_currency_code',
          'rate_micros',
          'last_updated_at',
        ]),
      );
      expect(
        columnsOf(raw, 'primary_currency_settings'),
        containsAll(['id', 'currency_code', 'updated_at']),
      );
      final index = raw.select(
        "SELECT sql FROM sqlite_master WHERE type = 'index' "
        "AND name = 'idx_exchange_rates_pair'",
      );
      expect(index.single['sql'] as String, contains('UNIQUE'));
      expect(raw.select('PRAGMA user_version').single.values.single, 9);
    });

    test('schemaVersion is 9 (018 bumped it to 7; 020 to 8; 021 to 9)', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 9);
    });
  });
}
