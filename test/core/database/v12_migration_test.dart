import 'dart:io';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/v11_fixture.dart';

/// 022 T064: the v11 -> v12 step. It adds `finance_entry_audits` (empty) and
/// `sync_state.b1_repull_done` (false), and changes no existing row. Starts
/// from the committed real v11 database, so the upgrade runs for real.
void main() {
  final sqlFile = File('test/core/database/fixtures/financial_world_v11.sql');

  List<Map<String, Object?>> rows(Database raw, String table) => [
    for (final r in raw.select('SELECT * FROM "$table" ORDER BY rowid'))
      Map<String, Object?>.of(r),
  ];

  Database loadV11() {
    final raw = sqlite3.openInMemory();
    raw.execute(sqlFile.readAsStringSync());
    expect(raw.select('PRAGMA user_version').single.values.single, 11);
    return raw;
  }

  Future<AppDatabase> open(Database raw) async {
    final db = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await db.select(db.financeCategories).get();
    return db;
  }

  test('schemaVersion is 12', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 12);
  });

  test('v11 -> v12: the audit table and the repair flag exist, every '
      'existing row is unchanged', () async {
    final raw = loadV11();
    addTearDown(raw.close);
    const tables = [
      'people',
      'money_transactions',
      'transaction_audit_entries',
      'finance_categories',
      'finance_entries',
      'exchange_rates',
      'savings_goals',
      'savings_contributions',
      'budgets',
      'occasions',
    ];
    raw.execute(
      "INSERT INTO sync_state (id, device_id, last_pulled_revision) "
      "VALUES ('singleton', 'dev', 42)",
    );
    final before = {for (final t in tables) t: rows(raw, t)};
    final syncStateBefore = rows(raw, 'sync_state');

    final db = await open(raw);
    addTearDown(db.close);

    expect(raw.select('PRAGMA user_version').single.values.single, 12);
    for (final t in tables) {
      expect(rows(raw, t), before[t], reason: t);
    }

    final columns = [
      for (final c in raw.select('PRAGMA table_info("finance_entry_audits")'))
        c['name'] as String,
    ];
    expect(columns, [
      'id',
      'finance_entry_id',
      'change_type',
      'previous_values_json',
      'changed_at',
    ]);
    expect(rows(raw, 'finance_entry_audits'), isEmpty);
    expect(
      raw
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name = 'idx_finance_audit_entry_id'",
          )
          .length,
      1,
    );

    // Existing sync_state rows keep every old value and read "not done".
    final after = rows(raw, 'sync_state');
    expect(after.length, syncStateBefore.length);
    for (var i = 0; i < after.length; i++) {
      expect(after[i]['b1_repull_done'], 0);
      final old = Map<String, Object?>.of(after[i])..remove('b1_repull_done');
      expect(old, syncStateBefore[i]);
    }
  });

  test('the new column defaults to false on a new sync_state row', () async {
    final raw = loadV11();
    addTearDown(raw.close);
    final db = await open(raw);
    addTearDown(db.close);

    raw.execute("DELETE FROM sync_state");
    raw.execute("INSERT INTO sync_state (id, device_id) VALUES ('x', 'd')");
    expect(rows(raw, 'sync_state').single['b1_repull_done'], 0);
  });

  test('a failure inside the step leaves the file at v11', () async {
    final raw = loadV11();
    addTearDown(raw.close);
    // A table already squatting on the new name with another shape makes
    // `CREATE INDEX` fail inside the step.
    raw.execute('CREATE TABLE finance_entry_audits (x INTEGER);');

    final db = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    addTearDown(db.close);
    await expectLater(db.select(db.financeCategories).get(), throwsA(anything));
    expect(raw.select('PRAGMA user_version').single.values.single, 11);
    expect([
      for (final c in raw.select('PRAGMA table_info("sync_state")')) c['name'],
    ], isNot(contains('b1_repull_done')));
  });

  test('a database created fresh has the same two additions', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await db.select(db.financeEntryAudits).get(), isEmpty);
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(id: 's', deviceId: 'd'));
    expect((await db.select(db.syncState).getSingle()).b1RepullDone, isFalse);
  });

  test('the shared fixture helper removes the v12 additions too', () {
    final raw = sqlite3.openInMemory();
    addTearDown(raw.close);
    raw.execute('CREATE TABLE savings_contribution_audits (a);');
    raw.execute('CREATE TABLE savings_contributions (a);');
    raw.execute('CREATE TABLE savings_goals (a);');
    raw.execute('CREATE TABLE finance_entry_audits (a);');
    raw.execute('CREATE TABLE sync_state (id TEXT, b1_repull_done INTEGER);');
    dropSavingsGoalsAdditions(raw);
    expect(
      raw
          .select(
            "SELECT name FROM sqlite_master WHERE name IN "
            "('finance_entry_audits')",
          )
          .length,
      0,
    );
    expect(
      [
        for (final c in raw.select('PRAGMA table_info("sync_state")'))
          c['name'],
      ],
      ['id'],
    );
  });
}
