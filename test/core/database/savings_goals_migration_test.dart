// `hide isNull`: drift re-exports a column helper of that name, which would
// otherwise shadow the matcher this file uses.
import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/v11_fixture.dart';

/// 011 T011 — the v10→v11 step that adds the three savings tables.
///
/// What an upgrading user cares about: nothing they already have changes
/// (011 FR-026 — zero changes to any existing table), and the UNIQUE
/// idempotency indexes and the goal-id lookup index exist on the upgrade
/// path too, not only on a fresh install.
void main() {
  const savingsTables = [
    'savings_goals',
    'savings_contributions',
    'savings_contribution_audits',
  ];
  const savingsIndexes = [
    'idx_savings_goals_idempotency_key',
    'idx_savings_contributions_idempotency_key',
    'idx_savings_contributions_goal_id',
    'idx_savings_contribution_audits_contribution_id',
  ];

  Set<String> namesOf(Database raw, String type) => {
    for (final row in raw.select(
      "SELECT name FROM sqlite_master WHERE type = ? AND name NOT LIKE 'sqlite_%'",
      [type],
    ))
      row['name'] as String,
  };

  Set<String> columnsOf(Database raw, String table) => {
    for (final row in raw.select('PRAGMA table_info("$table")'))
      row['name'] as String,
  };

  /// Every table with its column set, and every index name.
  Map<String, Object> schemaOf(Database raw) => {
    for (final table in namesOf(raw, 'table')) table: columnsOf(raw, table),
    for (final index in namesOf(raw, 'index')) index: 'index',
  };

  /// Today's schema, as a fresh install creates it.
  Future<Database> createFreshDatabase() async {
    final raw = sqlite3.openInMemory();
    final bootstrap = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await bootstrap.customSelect('SELECT 1').get();
    await bootstrap.close();
    return raw;
  }

  /// A real v10 file: today's schema minus exactly what v11 adds, holding a
  /// person, a transaction and a budget the upgrade must leave alone.
  Future<Database> createV10Database() async {
    final raw = await createFreshDatabase();
    dropSavingsGoalsAdditions(raw);
    raw.execute(
      'INSERT INTO people (id, name, normalized_name, is_archived, '
      "created_at, updated_at) VALUES ('p1', 'Ahmed', 'ahmed', 0, 1, 1);",
    );
    raw.execute(
      'INSERT INTO money_transactions (id, idempotency_key, person_id, '
      'amount_minor_units, currency_code, direction, kind, date, created_at) '
      "VALUES ('t1', 'k1', 'p1', 25000, 'EGP', 'given', 'initialExchange', "
      '2, 2);',
    );
    raw.execute(
      'INSERT INTO budgets (id, idempotency_key, month, currency_code, '
      "created_at, updated_at) VALUES ('b1', 'kb', '2026-09', 'EGP', 3, 3);",
    );
    raw.execute('PRAGMA user_version = 10;');
    return raw;
  }

  AppDatabase openUpgraded(Database raw) {
    final db = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    addTearDown(() async {
      await db.close();
      raw.close();
    });
    return db;
  }

  test('the v10 fixture really lacks the savings schema', () async {
    final raw = await createV10Database();
    addTearDown(raw.close);
    expect(namesOf(raw, 'table'), isNot(anyElement(isIn(savingsTables))));
    expect(namesOf(raw, 'index'), isNot(anyElement(isIn(savingsIndexes))));
  });

  test('a v10 database upgrades to v11 with the three empty savings tables '
      'and their indexes', () async {
    final raw = await createV10Database();
    final db = openUpgraded(raw);

    expect(await db.select(db.savingsGoals).get(), isEmpty);
    expect(await db.select(db.savingsContributions).get(), isEmpty);
    expect(await db.select(db.savingsContributionAudits).get(), isEmpty);
    expect(raw.select('PRAGMA user_version').single.values.single, 12);
    expect(db.schemaVersion, 12);
    expect(namesOf(raw, 'index'), containsAll(savingsIndexes));
  });

  test('a v10 file whose v11 step already ran (user_version still 10) '
      'opens and finishes the upgrade', () async {
    // The savings objects exist but the version never advanced, as after an
    // upgrade interrupted between the two.
    final raw = await createFreshDatabase();
    dropFinanceEntryAuditAdditions(raw);
    raw.execute('PRAGMA user_version = 10;');
    final db = openUpgraded(raw);

    expect(await db.select(db.savingsGoals).get(), isEmpty);
    expect(raw.select('PRAGMA user_version').single.values.single, 12);
    expect(namesOf(raw, 'index'), containsAll(savingsIndexes));
  });

  test('the upgraded schema is exactly a fresh install\'s', () async {
    final raw = await createV10Database();
    final db = openUpgraded(raw);
    await db.customSelect('SELECT 1').get();

    final fresh = await createFreshDatabase();
    addTearDown(fresh.close);
    expect(schemaOf(raw), schemaOf(fresh));
  });

  test('existing data survives the upgrade untouched (FR-026)', () async {
    final raw = await createV10Database();
    final db = openUpgraded(raw);

    final tx = await db.select(db.moneyTransactions).getSingle();
    expect(tx.id, 't1');
    expect(tx.amountMinorUnits, 25000);
    expect((await db.select(db.people).getSingle()).name, 'Ahmed');
    expect((await db.select(db.budgets).getSingle()).month, '2026-09');
  });

  test('the upgrade path enforces the idempotency keys and the goal '
      'reference', () async {
    final raw = await createV10Database();
    final db = openUpgraded(raw);
    await db.customStatement('PRAGMA foreign_keys = ON');

    Future<void> insertGoal(String id, String key) => db
        .into(db.savingsGoals)
        .insert(
          SavingsGoalsCompanion.insert(
            id: id,
            idempotencyKey: key,
            name: 'Emergency Fund',
            targetAmountMinorUnits: 10000000,
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    Future<void> insertContribution(String id, String key, String goalId) => db
        .into(db.savingsContributions)
        .insert(
          SavingsContributionsCompanion.insert(
            id: id,
            idempotencyKey: key,
            goalId: goalId,
            type: 'contribution',
            amountMinorUnits: 500000,
            enteredAmountMinorUnits: 500000,
            enteredCurrencyCode: 'EGP',
            date: 1,
            createdAt: 1,
          ),
        );

    await insertGoal('g1', 'gk1');
    await expectLater(insertGoal('g2', 'gk1'), throwsA(isA<Exception>()));

    await insertContribution('c1', 'ck1', 'g1');
    await expectLater(
      insertContribution('c2', 'ck1', 'g1'),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      insertContribution('c3', 'ck3', 'missing-goal'),
      throwsA(isA<Exception>()),
    );

    final goal = await db.select(db.savingsGoals).getSingle();
    expect(goal.currencyCode, 'EGP');
    expect(goal.isArchived, isFalse);
    expect(goal.type, isNull);
  });

  test('a fresh install gets the savings tables from onCreate', () async {
    final raw = await createFreshDatabase();
    addTearDown(raw.close);

    expect(namesOf(raw, 'table'), containsAll(savingsTables));
    expect(namesOf(raw, 'index'), containsAll(savingsIndexes));
    expect(raw.select('PRAGMA user_version').single.values.single, 12);
  });
}
