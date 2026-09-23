import 'app_database.dart';

/// One row of the starter category set inserted during the v5 migration
/// (data-model.md "Seed data", research.md Decision 3).
///
/// [key] doubles as the row's `icon` — a `CategoryIconRegistry` key — and as
/// the stable identifier the UI localizes a default category's name by
/// (`defaultCategoryNameKey`), so the seeded English [name] below is only a
/// fallback for a key the l10n layer does not know.
class DefaultFinanceCategorySeed {
  const DefaultFinanceCategorySeed({
    required this.key,
    required this.name,
    required this.isIncome,
  });

  final String key;
  final String name;
  final bool isIncome;
}

/// The fixed, versioned starter set: 16 expense + 6 income categories,
/// inserted once with `isDefault = true`. "Default" means "pre-populated",
/// never "protected" — every one of these is renameable, re-iconable, and
/// removable exactly like a custom category (FR-009/FR-010).
const List<DefaultFinanceCategorySeed> defaultFinanceCategorySeeds = [
  DefaultFinanceCategorySeed(key: 'rent', name: 'Rent', isIncome: false),
  DefaultFinanceCategorySeed(
    key: 'electricity',
    name: 'Electricity',
    isIncome: false,
  ),
  DefaultFinanceCategorySeed(key: 'water', name: 'Water', isIncome: false),
  DefaultFinanceCategorySeed(
    key: 'internet',
    name: 'Internet',
    isIncome: false,
  ),
  DefaultFinanceCategorySeed(key: 'phone', name: 'Phone', isIncome: false),
  DefaultFinanceCategorySeed(
    key: 'groceries',
    name: 'Groceries',
    isIncome: false,
  ),
  DefaultFinanceCategorySeed(
    key: 'transportation',
    name: 'Transportation',
    isIncome: false,
  ),
  DefaultFinanceCategorySeed(key: 'fuel', name: 'Fuel', isIncome: false),
  DefaultFinanceCategorySeed(key: 'medical', name: 'Medical', isIncome: false),
  DefaultFinanceCategorySeed(
    key: 'education',
    name: 'Education',
    isIncome: false,
  ),
  DefaultFinanceCategorySeed(
    key: 'entertainment',
    name: 'Entertainment',
    isIncome: false,
  ),
  DefaultFinanceCategorySeed(
    key: 'shopping',
    name: 'Shopping',
    isIncome: false,
  ),
  DefaultFinanceCategorySeed(
    key: 'restaurants',
    name: 'Restaurants',
    isIncome: false,
  ),
  DefaultFinanceCategorySeed(
    key: 'subscriptions',
    name: 'Subscriptions',
    isIncome: false,
  ),
  DefaultFinanceCategorySeed(key: 'family', name: 'Family', isIncome: false),
  DefaultFinanceCategorySeed(key: 'other', name: 'Other', isIncome: false),
  DefaultFinanceCategorySeed(key: 'salary', name: 'Salary', isIncome: true),
  DefaultFinanceCategorySeed(
    key: 'freelance',
    name: 'Freelance',
    isIncome: true,
  ),
  DefaultFinanceCategorySeed(key: 'business', name: 'Business', isIncome: true),
  DefaultFinanceCategorySeed(key: 'bonus', name: 'Bonus', isIncome: true),
  DefaultFinanceCategorySeed(key: 'gift', name: 'Gift', isIncome: true),
  DefaultFinanceCategorySeed(
    key: 'other_income',
    name: 'Other Income',
    isIncome: true,
  ),
];

/// Inserts [defaultFinanceCategorySeeds] into `finance_categories`, once.
///
/// Idempotent by design: it returns immediately if the table already holds
/// any row, so running it from both the v5 upgrade branch and `beforeOpen`
/// (fresh install) can never produce a second copy of the starter set.
Future<void> seedDefaultFinanceCategories(AppDatabase db) async {
  final existing = await (db.select(
    db.financeCategories,
  )..limit(1)).getSingleOrNull();
  if (existing != null) return;

  final now = DateTime.now().millisecondsSinceEpoch;
  await db.batch((batch) {
    batch.insertAll(db.financeCategories, [
      for (final seed in defaultFinanceCategorySeeds)
        FinanceCategoriesCompanion.insert(
          // The seed key doubles as the row id: stable across installs, and
          // it makes the "is this the seeded Rent row?" question answerable
          // without a name comparison that a rename would break.
          id: 'seed_${seed.key}',
          name: seed.name,
          normalizedName: seed.name.toLowerCase(),
          type: seed.isIncome ? 'income' : 'expense',
          icon: seed.key,
          isDefault: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
    ]);
  });
}
