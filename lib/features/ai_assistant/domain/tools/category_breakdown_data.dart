import '../../../finance/domain/entities/category_breakdown_item.dart';

/// Keys of one category entry in `getCategorySpend`/`getTopSpendingCategory`
/// results.
abstract final class AICategoryDataKeys {
  static const String categories = 'categories';
  static const String category = 'category';
  static const String name = 'name';
  static const String amountMinorUnits = 'amountMinorUnits';

  /// `0.0`-`1.0`, exactly `CategoryBreakdownItem.shareOfPeriod` — a
  /// fraction, not a percentage.
  static const String shareOfPeriod = 'shareOfPeriod';
}

/// One [CategoryBreakdownItem] copied field-for-field: no rounding, no
/// scaling, no recomputed share.
Map<String, Object?> categoryBreakdownItemData(CategoryBreakdownItem item) => {
  AICategoryDataKeys.name: item.categoryName,
  AICategoryDataKeys.amountMinorUnits: item.total.minorUnits,
  AICategoryDataKeys.shareOfPeriod: item.shareOfPeriod,
};
