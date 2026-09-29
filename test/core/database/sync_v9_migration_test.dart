import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/sync/sync_bootstrap.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart'
    show isPristineSeed;

import '../sync/fakes/sync_harness.dart';
import 'support/v11_fixture.dart';
import 'support/v9_fixture.dart';

/// 021 T012 — the v8 -> v9 migration (data-model.md §3): every business
/// column of every row is preserved, only `exchange_rates.id` is rewritten
/// to `rate_<CUR>_<REL>`, the five sync tables appear empty, and a failure
/// inside the step leaves the file at v8 with its data intact.
void main() {
  const businessTables = [
    'people',
    'money_transactions',
    'transaction_audit_entries',
    'finance_categories',
    'finance_entries',
    'exchange_rates',
    'primary_currency_settings',
  ];
  const syncTables = [
    'sync_outbox',
    'sync_record_meta',
    'sync_conflicts',
    'conflict_resolutions',
    'sync_state',
  ];

  /// A schemaVersion-8 database: today's schema minus exactly what 021
  /// added, the same "today minus N" approach as the other migration tests.
  Future<Database> createV8Database() async {
    final raw = sqlite3.openInMemory();
    final bootstrap = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    // Opening runs onCreate + beforeOpen, which seeds the 22 categories.
    await bootstrap.select(bootstrap.financeCategories).get();
    await bootstrap.close();
    dropSyncSupportAdditions(raw);
    dropSavingsGoalsAdditions(raw);
    raw.execute('PRAGMA user_version = 8;');
    return raw;
  }

  void seed(Database raw) {
    for (var p = 0; p < 5; p++) {
      raw.execute(
        'INSERT INTO people (id, name, normalized_name, phone_number, '
        'avatar_path, relationship_tag, notes, is_archived, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'p$p',
          'Person $p',
          'person $p',
          p.isEven ? '+2010000000$p' : null,
          p == 1 ? '/data/avatars/p1.jpg' : null,
          p == 2 ? 'family' : null,
          p == 3 ? 'note $p' : null,
          p == 4 ? 1 : 0,
          100 + p,
          200 + p,
        ],
      );
    }
    for (var t = 0; t < 12; t++) {
      raw.execute(
        'INSERT INTO money_transactions (id, idempotency_key, person_id, '
        'amount_minor_units, currency_code, direction, kind, date, note, '
        'created_at, edited_at, deleted_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          't$t',
          'tk$t',
          'p${t % 5}',
          t == 0 ? 9007199254740993 : 1000 * (t + 1),
          t.isEven ? 'EGP' : 'USD',
          t.isEven ? 'given' : 'received',
          t % 3 == 0 ? 'initialExchange' : 'repayment',
          1700000000000 + t,
          t % 2 == 0 ? null : 'note $t',
          1700000000000 + t,
          t % 4 == 0 ? 1700000100000 + t : null,
          // Soft-deleted rows must survive untouched.
          t % 5 == 0 ? 1700000200000 + t : null,
        ],
      );
      raw.execute(
        'INSERT INTO transaction_audit_entries (id, transaction_id, '
        'change_type, previous_values_json, changed_at) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          'a$t',
          't$t',
          t % 5 == 0 ? 'deleted' : 'created',
          t % 5 == 0 ? '{"amountMinorUnits":1000}' : null,
          1700000000000 + t,
        ],
      );
    }
    // A custom category, and one seeded category the user renamed.
    raw.execute(
      'INSERT INTO finance_categories (id, name, normalized_name, type, '
      'icon, is_default, is_archived, created_at, updated_at) '
      "VALUES ('c1', 'Pets', 'pets', 'expense', 'other', 0, 0, 1, 2)",
    );
    raw.execute(
      "UPDATE finance_categories SET name = 'Home rent', "
      "normalized_name = 'home rent', updated_at = 5 WHERE id = 'seed_rent'",
    );
    for (var e = 0; e < 6; e++) {
      raw.execute(
        'INSERT INTO finance_entries (id, idempotency_key, category_id, type, '
        'amount_minor_units, currency_code, date, note, created_at, '
        'edited_at, deleted_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'e$e',
          'ek$e',
          e.isEven ? 'c1' : 'seed_salary',
          e.isEven ? 'expense' : 'income',
          500 * (e + 1),
          'EGP',
          1700000000000 + e,
          e == 1 ? 'bonus' : null,
          1700000000000 + e,
          e == 2 ? 1700000300000 : null,
          e == 3 ? 1700000400000 : null,
        ],
      );
    }
    raw.execute(
      'INSERT INTO exchange_rates (id, currency_code, '
      'relative_to_currency_code, rate_micros, last_updated_at) '
      "VALUES ('5f0c-uuid-1', 'USD', 'EGP', 48500000, 10)",
    );
    raw.execute(
      'INSERT INTO exchange_rates (id, currency_code, '
      'relative_to_currency_code, rate_micros, last_updated_at) '
      "VALUES ('9a1d-uuid-2', 'SAR', 'EGP', 12930000, 11)",
    );
    raw.execute(
      'INSERT INTO primary_currency_settings (id, currency_code, updated_at) '
      "VALUES ('singleton', 'USD', 12)",
    );
  }

  /// Every row of [table], as full column maps, in a stable order.
  List<Map<String, Object?>> rowsOf(Database raw, String table) => [
    for (final row in raw.select('SELECT * FROM $table ORDER BY rowid'))
      {for (final key in row.keys) key: row[key]},
  ];

  List<String> tablesOf(Database raw) => [
    for (final r in raw.select(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ))
      r['name'] as String,
  ];

  List<String> indexesOf(Database raw) => [
    for (final r in raw.select(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    ))
      r['name'] as String,
  ];

  test('the hand-built v8 fixture really is pre-021', () async {
    final raw = await createV8Database();
    addTearDown(raw.close);
    expect(tablesOf(raw), isNot(anyElement(isIn(syncTables))));
    expect(indexesOf(raw), isNot(contains('idx_transactions_date')));
    expect(indexesOf(raw), isNot(contains('idx_people_archived')));
  });

  group('v8 -> v9 with existing data', () {
    late Database raw;
    late AppDatabase db;
    late Map<String, List<Map<String, Object?>>> before;

    setUp(() async {
      raw = await createV8Database();
      seed(raw);
      before = {for (final t in businessTables) t: rowsOf(raw, t)};
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);
      // Any query opens the database, which runs the migration.
      await db.customSelect('SELECT 1').get();
    });

    test('reaches the latest user_version (11)', () {
      expect(raw.select('PRAGMA user_version').single.values.single, 11);
    });

    test('every business column of every row is unchanged, except '
        'exchange_rates.id', () {
      for (final table in businessTables) {
        final after = rowsOf(raw, table);
        expect(after, hasLength(before[table]!.length), reason: table);
        if (table == 'exchange_rates') continue;
        expect(after, before[table], reason: table);
      }
      Map<String, Object?> withoutId(Map<String, Object?> r) =>
          Map.of(r)..remove('id');
      expect(
        rowsOf(raw, 'exchange_rates').map(withoutId).toList(),
        before['exchange_rates']!.map(withoutId).toList(),
      );
    });

    test('rewrites exchange-rate ids to rate_<CUR>_<REL>', () async {
      final rates = await db.select(db.exchangeRates).get();
      expect({for (final r in rates) r.id}, {'rate_USD_EGP', 'rate_SAR_EGP'});
      final usd = rates.singleWhere((r) => r.currencyCode == 'USD');
      expect(usd.id, 'rate_USD_EGP');
      expect(usd.rateMicros, 48500000);
    });

    test('a > 2^53 amount survives byte-identical', () async {
      final t0 = await (db.select(
        db.moneyTransactions,
      )..where((t) => t.id.equals('t0'))).getSingle();
      expect(t0.amountMinorUnits, 9007199254740993);
    });

    test('creates the five sync tables, empty', () {
      expect(tablesOf(raw), containsAll(syncTables));
      for (final table in syncTables) {
        expect(
          raw.select('SELECT COUNT(*) AS n FROM $table').single['n'],
          0,
          reason: table,
        );
      }
    });

    test('creates the sync and business indexes', () {
      expect(
        indexesOf(raw),
        containsAll([
          'idx_outbox_ready',
          'idx_outbox_entity',
          'idx_meta_state',
          'idx_conflicts_open',
          'idx_transactions_date',
          'idx_people_archived',
        ]),
      );
    });

    test('sync_state columns carry the data-model defaults', () async {
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(id: 'singleton', deviceId: 'device-1'),
          );
      final row = await db.select(db.syncState).getSingle();
      expect(row.enabled, isTrue);
      expect(row.noticeShown, isFalse);
      expect(row.ownerId, isNull);
      expect(row.lastPulledRevision, 0);
      expect(row.bootstrapEnqueued, isFalse);
      expect(row.initialUploadDone, isFalse);
      expect(row.consecutiveFailures, 0);
      expect(row.lastErrorCode, isNull);
    });
  });

  test('a failure inside the v9 step leaves the file at v8 with its data '
      'intact', () async {
    final raw = await createV8Database();
    addTearDown(raw.close);
    seed(raw);
    // Forces step 3 (the rate-id rewrite) to fail after step 1 already
    // created the sync tables — the whole step must roll back.
    raw.execute(
      'CREATE TRIGGER force_v9_failure BEFORE UPDATE ON exchange_rates '
      "BEGIN SELECT RAISE(ABORT, 'forced v9 failure'); END;",
    );
    final before = {for (final t in businessTables) t: rowsOf(raw, t)};

    final db = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
    await db.close();

    expect(raw.select('PRAGMA user_version').single.values.single, 8);
    expect(tablesOf(raw), isNot(anyElement(isIn(syncTables))));
    expect(indexesOf(raw), isNot(contains('idx_transactions_date')));
    for (final table in businessTables) {
      expect(rowsOf(raw, table), before[table], reason: table);
    }

    // Once the cause is gone, the next open retries the step cleanly.
    raw.execute('DROP TRIGGER force_v9_failure;');
    final retry = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await retry.customSelect('SELECT 1').get();
    await retry.close();
    expect(raw.select('PRAGMA user_version').single.values.single, 11);
    expect(tablesOf(raw), containsAll(syncTables));
  });

  group('T064: v8 -> v9 then the bootstrap in beforeOpen', () {
    SyncBootstrap bootstrap() => SyncBootstrap(
      realMapperRegistry(),
      _SilentLogger(),
      const SystemAppClock(),
      isPristineSeed: isPristineSeed,
    );

    int count(Database raw, String sql) =>
        raw.select(sql).single.values.single! as int;

    test('queues every synced row once, skipping pristine seeds; reopening '
        'queues nothing more', () async {
      final raw = await createV8Database();
      seed(raw);
      final db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
        syncBootstrap: bootstrap(),
      );
      await db.customSelect('SELECT 1').get();
      await db.close();

      // 5 people + 12 transactions + 12 audits + 2 categories (the custom
      // one and the renamed seed; 21 pristine seeds skipped) + 6 entries +
      // 2 rates + 1 primary currency.
      const expected = 5 + 12 + 12 + 2 + 6 + 2 + 1;
      expect(count(raw, 'SELECT COUNT(*) FROM sync_outbox'), expected);
      expect(
        count(
          raw,
          "SELECT COUNT(*) FROM sync_record_meta WHERE state = 'pending'",
        ),
        expected,
      );
      expect(
        count(
          raw,
          "SELECT COUNT(*) FROM sync_outbox WHERE entity_id = 'seed_rent'",
        ),
        1,
      );
      expect(
        count(
          raw,
          "SELECT COUNT(*) FROM sync_outbox WHERE entity_id = 'seed_food'",
        ),
        0,
      );
      expect(
        count(
          raw,
          'SELECT COUNT(*) FROM sync_outbox WHERE base_revision IS NOT NULL',
        ),
        0,
      );

      final again = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
        syncBootstrap: bootstrap(),
      );
      await again.customSelect('SELECT 1').get();
      await again.close();
      expect(count(raw, 'SELECT COUNT(*) FROM sync_outbox'), expected);
      raw.close();
    });
  });

  test('a fresh install creates the sync tables at v9', () async {
    final raw = sqlite3.openInMemory();
    final db = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    addTearDown(() async {
      await db.close();
      raw.close();
    });
    await db.customSelect('SELECT 1').get();
    expect(tablesOf(raw), containsAll(syncTables));
    expect(raw.select('PRAGMA user_version').single.values.single, 11);
    expect(db.schemaVersion, 11);
  });
}

class _SilentLogger implements SyncLogger {
  @override
  void event(SyncEvent e, {Map<SyncLogField, Object> fields = const {}}) {}
}
