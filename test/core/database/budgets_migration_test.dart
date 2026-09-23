// `hide isNull`: drift re-exports a column helper of that name, which would
// otherwise shadow the matcher this file uses.
import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// T009 — the v7→v8 migration that adds 010's two budget tables.
///
/// What an upgrading user cares about: their 007 finance data survives
/// untouched (010 FR-022), and the UNIQUE indexes that enforce one budget
/// per month and idempotent saves exist on the upgrade path too, not only
/// on a fresh install.
///
/// Same raw-`sqlite3`-handle technique as the 008/009 migration tests. Only
/// the tables this migration and the `beforeOpen` category seed touch are
/// created — the upgrade step reads and alters nothing else.
void main() {
  Database createV7Database() {
    final raw = sqlite3.openInMemory();
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
    raw.execute(
      "INSERT INTO finance_categories (id, name, normalized_name, type, icon, "
      "is_default, is_archived, created_at, updated_at) "
      "VALUES ('c1', 'Groceries', 'groceries', 'expense', 'cart', 0, 0, "
      "100, 100);",
    );
    raw.execute(
      "INSERT INTO finance_entries (id, idempotency_key, category_id, type, "
      "amount_minor_units, date, note, created_at) "
      "VALUES ('e1', 'k1', 'c1', 'expense', 12345, 200, 'weekly shop', 200);",
    );
    raw.execute('PRAGMA user_version = 7;');
    return raw;
  }

  AppDatabase openUpgraded(Database raw) {
    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);
    return db;
  }

  test('a v7 database upgrades to v8 with both budget tables', () async {
    final db = openUpgraded(createV7Database());

    expect(await db.select(db.budgets).get(), isEmpty);
    expect(await db.select(db.budgetCategoryAllocations).get(), isEmpty);
    expect(db.schemaVersion, greaterThanOrEqualTo(8));
  });

  test(
    'existing finance data survives the upgrade untouched (FR-022)',
    () async {
      final db = openUpgraded(createV7Database());

      final entry = (await db.select(db.financeEntries).get()).single;
      expect(entry.id, 'e1');
      expect(entry.amountMinorUnits, 12345);
      expect(entry.note, 'weekly shop');
      final category = await (db.select(
        db.financeCategories,
      )..where((c) => c.id.equals('c1'))).getSingle();
      expect(category.name, 'Groceries');
    },
  );

  test('the upgrade path carries the UNIQUE indexes: one active budget per '
      'month, and a deleted one frees its month', () async {
    final db = openUpgraded(createV7Database());

    Future<void> insertBudget(String id, {int? deletedAt}) => db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: id,
            idempotencyKey: 'key-$id',
            month: '2026-03',
            createdAt: 1,
            updatedAt: 1,
            deletedAt: Value(deletedAt),
          ),
        );

    await insertBudget('b1', deletedAt: 5);
    await insertBudget('b2');
    await expectLater(insertBudget('b3'), throwsA(isA<Exception>()));
    expect(await db.select(db.budgets).get(), hasLength(2));
  });

  test(
    'the upgrade path carries the (budget, category) UNIQUE index',
    () async {
      final db = openUpgraded(createV7Database());
      await db
          .into(db.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: 'b1',
              idempotencyKey: 'kb',
              month: '2026-03',
              createdAt: 1,
              updatedAt: 1,
            ),
          );

      Future<void> allocate(String id) => db
          .into(db.budgetCategoryAllocations)
          .insert(
            BudgetCategoryAllocationsCompanion.insert(
              id: id,
              idempotencyKey: 'k-$id',
              budgetId: 'b1',
              categoryId: 'c1',
              plannedAmountMinorUnits: 100,
              createdAt: 1,
              updatedAt: 1,
            ),
          );

      await allocate('a1');
      await expectLater(allocate('a2'), throwsA(isA<Exception>()));
    },
  );

  test('a fresh install gets the budget tables from onCreate', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.select(db.budgets).get(), isEmpty);
    expect(db.schemaVersion, 8);
  });
}
