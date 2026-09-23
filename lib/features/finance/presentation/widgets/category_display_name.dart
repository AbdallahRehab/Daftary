import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/category.dart';

/// The name to show for [category], localized when it is one of the seeded
/// starter categories.
///
/// The seed rows store their English name, which is the right thing to
/// persist — a user who renames "Groceries" owns that string, and a rename
/// must survive a language switch. So localization is resolved at display
/// time and only while the row is still untouched: a default category is
/// matched by its stable seed [Category.icon] key, and the moment the user
/// renames it, [Category.name] is theirs and is shown verbatim.
String categoryDisplayName(AppLocalizations l10n, Category category) {
  if (!category.isDefault) return category.name;
  return categoryDisplayNameFor(
    l10n,
    iconKey: category.icon,
    name: category.name,
  );
}

/// Same resolution keyed directly by a seed key — for callers that hold an
/// icon key and a name but not a whole [Category], such as a breakdown row.
String categoryDisplayNameFor(
  AppLocalizations l10n, {
  required String iconKey,
  required String name,
}) {
  final localized = defaultCategoryName(l10n, iconKey);
  // A custom category may legitimately reuse a seed icon, so the localized
  // name is only correct when the stored name still matches the seed's own
  // English name — otherwise the user's name wins.
  if (localized == null) return name;
  return _seedEnglishNames[iconKey] == name ? localized : name;
}

/// The localized name for a seed key, or `null` if the key is not one of
/// the 22 seeded categories.
String? defaultCategoryName(AppLocalizations l10n, String seedKey) =>
    switch (seedKey) {
      'rent' => l10n.financeCategoryRent,
      'electricity' => l10n.financeCategoryElectricity,
      'water' => l10n.financeCategoryWater,
      'internet' => l10n.financeCategoryInternet,
      'phone' => l10n.financeCategoryPhone,
      'groceries' => l10n.financeCategoryGroceries,
      'transportation' => l10n.financeCategoryTransportation,
      'fuel' => l10n.financeCategoryFuel,
      'medical' => l10n.financeCategoryMedical,
      'education' => l10n.financeCategoryEducation,
      'entertainment' => l10n.financeCategoryEntertainment,
      'shopping' => l10n.financeCategoryShopping,
      'restaurants' => l10n.financeCategoryRestaurants,
      'subscriptions' => l10n.financeCategorySubscriptions,
      'family' => l10n.financeCategoryFamily,
      'other' => l10n.financeCategoryOther,
      'salary' => l10n.financeCategorySalary,
      'freelance' => l10n.financeCategoryFreelance,
      'business' => l10n.financeCategoryBusiness,
      'bonus' => l10n.financeCategoryBonus,
      'gift' => l10n.financeCategoryGift,
      'other_income' => l10n.financeCategoryOtherIncome,
      _ => null,
    };

/// The English names the seed inserted, keyed by seed key — used to tell an
/// untouched default category from a renamed one.
const Map<String, String> _seedEnglishNames = {
  'rent': 'Rent',
  'electricity': 'Electricity',
  'water': 'Water',
  'internet': 'Internet',
  'phone': 'Phone',
  'groceries': 'Groceries',
  'transportation': 'Transportation',
  'fuel': 'Fuel',
  'medical': 'Medical',
  'education': 'Education',
  'entertainment': 'Entertainment',
  'shopping': 'Shopping',
  'restaurants': 'Restaurants',
  'subscriptions': 'Subscriptions',
  'family': 'Family',
  'other': 'Other',
  'salary': 'Salary',
  'freelance': 'Freelance',
  'business': 'Business',
  'bonus': 'Bonus',
  'gift': 'Gift',
  'other_income': 'Other Income',
};
