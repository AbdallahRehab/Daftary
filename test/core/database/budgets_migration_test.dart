// `hide isNull`: drift re-exports a column helper of that name, which would
// otherwise shadow the matcher this file uses.
import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/feature_line_fixture.dart';

/// T009 — the v7→v8 migration that adds 010's two budget tables.
///
/// What an upgrading user cares about: their 007 finance data survives
/// untouched (010 FR-022), and the UNIQUE indexes that enforce one budget
/// per month and idempotent saves exist on the upgrade path too, not only
/// on a fresh install.
///
/// Since the merge the budget tables arrive in v10, after `main`'s v6..v9
/// are replayed on a feature-line file (v10_merge_features.dart), so the
/// fixture is a real pre-merge v7 rather than a hand-typed subset.
void main() {
  /// A real pre-merge v7 (008 + 009, no budgets yet) holding one 007
  /// category and entry the upgrade must leave alone.
  Future<Database> createV7Database() async {
    final raw = await createFeatureLineDatabase(7);
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
    return raw;
  }

  AppDatabase openUpgraded(Database raw) {
    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);
    return db;
  }

  test('a v7 database upgrades to v8 with both budget tables', () async {
    final db = openUpgraded(await createV7Database());

    expect(await db.select(db.budgets).get(), isEmpty);
    expect(await db.select(db.budgetCategoryAllocations).get(), isEmpty);
    expect(db.schemaVersion, greaterThanOrEqualTo(8));
  });

  test(
    'existing finance data survives the upgrade untouched (FR-022)',
    () async {
      final db = openUpgraded(await createV7Database());

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
    final db = openUpgraded(await createV7Database());

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
      final db = openUpgraded(await createV7Database());
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
    expect(db.schemaVersion, greaterThanOrEqualTo(8));
  });
}
