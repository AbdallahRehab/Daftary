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
///
/// 018 FR-009: a line whose spend includes a currency with no exchange rate
/// [isBlocked] — its actual is unknown ([actualAmountMinorUnits] is `null`),
/// and so are everything derived from it (remaining, percentage, status).
/// Its planned amount is the budget's own figure and always shows. Only
/// that line is blocked: every other line keeps its figures.
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
    this.currency = Currency.egp,
    this.missingRatesFor = const [],
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
  /// budget's month, as computed by 007 (FR-005/FR-016), converted into
  /// [currency]. `null` when that needs a missing exchange rate (018
  /// FR-009) — never a partial or 1:1-converted figure.
  final int? actualAmountMinorUnits;

  /// 018: the budget's currency; [actualAmountMinorUnits] is already
  /// converted into it.
  final Currency currency;

  /// 018 FR-009: the currencies this line's spend needs a rate for; empty
  /// unless [isBlocked].
  final List<Currency> missingRatesFor;

  /// The actual spend is unknowable until a rate is set (018 FR-009).
  bool get isBlocked => actualAmountMinorUnits == null;

  /// `planned − actual`; negative once over budget. `null` when
  /// [isBlocked].
  int? get remainingMinorUnits => switch (actualAmountMinorUnits) {
    final actual? => plannedAmountMinorUnits - actual,
    null => null,
  };

  /// `null` when nothing was planned ("n/a") — and when [isBlocked], which
  /// callers check first.
  double? get percentageUsed => switch (actualAmountMinorUnits) {
    final actual? => budgetPercentageUsed(
      plannedMinorUnits: plannedAmountMinorUnits,
      actualMinorUnits: actual,
    ),
    null => null,
  };

  /// `null` when [isBlocked]: an unknown actual is neither on track nor
  /// over.
  BudgetCategoryStatus? get status => switch (actualAmountMinorUnits) {
    final actual? => budgetStatusFor(
      plannedMinorUnits: plannedAmountMinorUnits,
      actualMinorUnits: actual,
    ),
    null => null,
  };

  Money get plannedAmount =>
      Money.fromMinorUnits(plannedAmountMinorUnits, currency);
  Money? get actualAmount => switch (actualAmountMinorUnits) {
    final actual? => Money.fromMinorUnits(actual, currency),
    null => null,
  };
  Money? get remaining => switch (remainingMinorUnits) {
    final remaining? => Money.fromMinorUnits(remaining, currency),
    null => null,
  };

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
    currency,
    missingRatesFor,
  ];
}

/// Every currency in [lists], once each, in first-seen order — how a
/// summary or trend names the rates its blocked parts need (018 FR-009).
List<Currency> unionOfMissingRates(Iterable<List<Currency>> lists) => [
  ...{for (final list in lists) ...list},
];
