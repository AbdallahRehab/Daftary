import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// How far through its plan a budgeted category (or the whole budget) is
/// (FR-008/FR-009).
enum BudgetCategoryStatus { onTrack, nearFull, overBudget }

/// The "near full" threshold, in percent of planned (spec Assumptions: a
/// fixed 90% default, not user-configurable in this version).
const int budgetNearFullThresholdPercent = 90;

/// The single status rule, shared by per-category lines and the overall
/// summary so the two can never disagree about what "over" means:
///
/// - `overBudget` when [actualMinorUnits] > [plannedMinorUnits] — which
///   makes *any* spend against a zero plan over budget immediately, rather
///   than an undefined percentage (FR-002 Edge Case);
/// - else `nearFull` at or above [budgetNearFullThresholdPercent];
/// - else `onTrack`.
///
/// Compared in integers (`actual * 100 >= planned * 90`) rather than
/// through [BudgetCategoryLine.percentageUsed], so the threshold is exact
/// and never subject to floating-point rounding (FR-015).
BudgetCategoryStatus budgetStatusFor({
  required int plannedMinorUnits,
  required int actualMinorUnits,
}) {
  if (actualMinorUnits > plannedMinorUnits) {
    return BudgetCategoryStatus.overBudget;
  }
  if (plannedMinorUnits > 0 &&
      actualMinorUnits * 100 >=
          plannedMinorUnits * budgetNearFullThresholdPercent) {
    return BudgetCategoryStatus.nearFull;
  }
  return BudgetCategoryStatus.onTrack;
}

/// `actual / planned * 100`, or `null` when nothing was planned — shown as
/// "n/a" rather than dividing by zero. A display ratio only: every money
/// figure itself stays in integer minor units (FR-015).
double? budgetPercentageUsed({
  required int plannedMinorUnits,
  required int actualMinorUnits,
}) {
  if (plannedMinorUnits == 0) return null;
  return actualMinorUnits * 100 / plannedMinorUnits;
}

/// One row of a budget's per-category breakdown (FR-005): an allocation's
/// plan beside the category's real spend for the budget's month.
///
/// Derived on every read, never persisted. [remainingMinorUnits],
/// [percentageUsed] and [status] are getters over the two stored inputs
/// rather than fields, so a line can never carry a status that contradicts
/// its own numbers.
class BudgetCategoryLine extends Equatable {
  const BudgetCategoryLine({
    required this.allocationId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.plannedAmountMinorUnits,
    required this.actualAmountMinorUnits,
    this.isCategoryArchived = false,
    this.isCategoryMissing = false,
  });

  /// The underlying `BudgetCategoryAllocation.id` — what an edit/remove of
  /// this line acts on.
  final String allocationId;
  final String categoryId;

  /// Resolved from 007's `Category` on every read, archived or not
  /// (FR-021). Empty only when [isCategoryMissing].
  final String categoryName;

  /// A `CategoryIconRegistry` key (007). Empty only when
  /// [isCategoryMissing].
  final String categoryIcon;

  /// The category has been archived in 007 since it was allocated. The
  /// line still displays and counts normally (FR-021); only the picker for
  /// *new* allocations hides archived categories.
  final bool isCategoryArchived;

  /// The referenced category no longer exists at all. 007 hard-deletes a
  /// category only when no entry references it, so such a line can never
  /// have spend — it is kept rather than silently dropped so its planned
  /// amount still counts and the user can still remove it.
  final bool isCategoryMissing;
  final int plannedAmountMinorUnits;

  /// Sum of this category's non-deleted expense entries dated within the
  /// budget's month, as computed by 007 (FR-005/FR-016).
  final int actualAmountMinorUnits;

  /// `planned − actual`; negative once over budget.
  int get remainingMinorUnits =>
      plannedAmountMinorUnits - actualAmountMinorUnits;

  double? get percentageUsed => budgetPercentageUsed(
    plannedMinorUnits: plannedAmountMinorUnits,
    actualMinorUnits: actualAmountMinorUnits,
  );

  BudgetCategoryStatus get status => budgetStatusFor(
    plannedMinorUnits: plannedAmountMinorUnits,
    actualMinorUnits: actualAmountMinorUnits,
  );

  Money get plannedAmount => Money.fromMinorUnits(plannedAmountMinorUnits);
  Money get actualAmount => Money.fromMinorUnits(actualAmountMinorUnits);
  Money get remaining => Money.fromMinorUnits(remainingMinorUnits);

  @override
  List<Object?> get props => [
    allocationId,
    categoryId,
    categoryName,
    categoryIcon,
    isCategoryArchived,
    isCategoryMissing,
    plannedAmountMinorUnits,
    actualAmountMinorUnits,
  ];
}
