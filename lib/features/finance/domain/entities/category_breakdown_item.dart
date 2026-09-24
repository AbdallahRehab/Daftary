import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// One category's total within a period, plus its share of that period's
/// total (FR-015). Derived, never persisted — same rationale as
/// `FinanceSummary`.
class CategoryBreakdownItem extends Equatable {
  const CategoryBreakdownItem({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.total,
    required this.shareOfPeriod,
  });

  final String categoryId;
  final String categoryName;

  /// A `CategoryIconRegistry` key, carried through from the category so the
  /// breakdown row can render without a second lookup.
  final String icon;

  /// This category's total, converted into the primary currency (018
  /// FR-008). `null` when one of this category's own currencies has no
  /// rate (FR-009) — never a partial or 1:1-converted figure.
  final Money? total;

  /// `0.0`-`1.0`. `0` when the period total is zero, rather than a division
  /// by zero. `null` whenever the breakdown as a whole is blocked: a share
  /// of an incomplete period total would be wrong for every row (FR-009).
  final double? shareOfPeriod;

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    icon,
    total,
    shareOfPeriod,
  ];
}

/// The per-category breakdown for a period (FR-015), in the primary
/// [currency]. [missingRatesFor] is non-empty when any entry in the period
/// is in a currency without a rate — the breakdown is then [isBlocked]:
/// rows whose own total is still fully convertible keep it, but no row
/// carries a share (018 FR-009).
class CategoryBreakdown extends Equatable {
  const CategoryBreakdown({
    required this.items,
    this.currency = Currency.egp,
    this.missingRatesFor = const [],
  });

  static const CategoryBreakdown empty = CategoryBreakdown(items: []);

  /// Largest converted total first; rows with a blocked total last.
  final List<CategoryBreakdownItem> items;
  final Currency currency;
  final List<Currency> missingRatesFor;

  bool get isBlocked => missingRatesFor.isNotEmpty;
  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, currency, missingRatesFor];
}

/// One category's raw per-currency totals within a period, straight off
/// the repository's `GROUP BY category_id, currency_code` aggregate.
/// Unconverted: `GetCategoryBreakdown` composes these with
/// `CurrencyConverter` into a [CategoryBreakdown].
class CategoryCurrencyTotals extends Equatable {
  const CategoryCurrencyTotals({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.totals,
  });

  final String categoryId;
  final String categoryName;
  final String icon;

  /// One amount per currency this category has entries in.
  final List<Money> totals;

  @override
  List<Object?> get props => [categoryId, categoryName, icon, totals];
}
