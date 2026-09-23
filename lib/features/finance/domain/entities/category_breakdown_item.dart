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
  final Money total;

  /// `0.0`-`1.0`. `0` when the period total is zero, rather than a division
  /// by zero.
  final double shareOfPeriod;

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    icon,
    total,
    shareOfPeriod,
  ];
}
