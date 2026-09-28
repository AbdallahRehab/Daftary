import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'budget.dart';
import 'budget_category_line.dart';

/// Whether a budget's planned total is more than the expected income the
/// user recorded for it (FR-004). Always `false` when no income figure was
/// recorded. An indication only — it never blocks a save.
///
/// A free function rather than only a [BudgetSummary] getter so the budget
/// form can compute the same answer live, before anything is persisted.
bool budgetPlannedExceedsIncome({
  required int totalPlannedMinorUnits,
  required int? expectedIncomeMinorUnits,
}) =>
    expectedIncomeMinorUnits != null &&
    totalPlannedMinorUnits > expectedIncomeMinorUnits;

/// An expense category with spend in the budget's month that the budget
/// has no allocation for (FR-007) — shown separately, never folded into a
/// budgeted line or dropped.
///
/// 018 FR-009: [isBlocked] when its spend needs a missing exchange rate —
/// still listed (the spending exists), with its amount unknown.
class UnbudgetedCategorySpend extends Equatable {
  const UnbudgetedCategorySpend({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.amountMinorUnits,
    this.currency = Currency.egp,
    this.missingRatesFor = const [],
  });

  final String categoryId;
  final String categoryName;

  /// A `CategoryIconRegistry` key (007).
  final String categoryIcon;

  /// `null` when converting it needs a missing rate (018 FR-009).
  final int? amountMinorUnits;

  /// 018: the budget's currency; [amountMinorUnits] is converted into it.
  final Currency currency;

  /// The currencies this spend needs a rate for; empty unless [isBlocked].
  final List<Currency> missingRatesFor;

  bool get isBlocked => amountMinorUnits == null;

  Money? get amount => switch (amountMinorUnits) {
    final amount? => Money.fromMinorUnits(amount, currency),
    null => null,
  };

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    categoryIcon,
    amountMinorUnits,
    currency,
    missingRatesFor,
  ];
}

/// A budget's computed totals and breakdown (FR-005/FR-006/FR-007/FR-009).
///
/// Derived on every read, never persisted. The totals are getters over
/// [categoryBreakdown] rather than separately supplied fields, so the
/// overall card can never disagree with the rows beneath it.
///
/// 018 FR-009 — what a missing exchange rate blocks, and nothing more:
/// - the planned total is the budget's own figures, so it always shows;
/// - the actual-side totals (actual, remaining, percentage, over-budget,
///   overall status) are `null` as soon as any budgeted line
///   [BudgetCategoryLine.isBlocked] — a total that silently left a line
///   out would be wrong ([isActualBlocked]);
/// - [totalUnbudgetedMinorUnits] is `null` when any unbudgeted item is
///   blocked;
/// - [missingRatesFor] names every currency needed anywhere on the month,
///   for the screen's single `RateNeededBanner`.
class BudgetSummary extends Equatable {
  const BudgetSummary({
    required this.budgetId,
    required this.categoryBreakdown,
    required this.unbudgetedSpending,
    this.currency = Currency.egp,
  });

  final String budgetId;

  /// One line per allocation, in the order the repository returns them
  /// (largest planned amount first).
  final List<BudgetCategoryLine> categoryBreakdown;

  /// Largest amount first; blocked items last.
  final List<UnbudgetedCategorySpend> unbudgetedSpending;

  /// 018: the budget's currency — every figure here is in it.
  final Currency currency;

  /// Every currency a blocked line or unbudgeted item needs a rate for,
  /// once each; empty when nothing is blocked.
  List<Currency> get missingRatesFor => unionOfMissingRates([
    for (final line in categoryBreakdown) line.missingRatesFor,
    for (final item in unbudgetedSpending) item.missingRatesFor,
  ]);

  /// Anything on the month needs a rate — drives the banner.
  bool get isBlocked =>
      isActualBlocked || unbudgetedSpending.any((item) => item.isBlocked);

  /// Some budgeted line's actual is unknown, so every actual-side total is.
  bool get isActualBlocked => categoryBreakdown.any((line) => line.isBlocked);

  int get totalPlannedMinorUnits => categoryBreakdown.fold(
    0,
    (sum, line) => sum + line.plannedAmountMinorUnits,
  );

  /// Budgeted categories' actual spend only — unbudgeted spending is
  /// reported beside it ([totalUnbudgetedMinorUnits]), not mixed in, so
  /// "remaining" compares like with like. `null` when [isActualBlocked].
  int? get totalActualMinorUnits => isActualBlocked
      ? null
      : categoryBreakdown.fold<int>(
          0,
          (sum, line) => sum + line.actualAmountMinorUnits!,
        );

  /// May be negative — over budget overall (FR-009). `null` when
  /// [isActualBlocked].
  int? get totalRemainingMinorUnits => switch (totalActualMinorUnits) {
    final actual? => totalPlannedMinorUnits - actual,
    null => null,
  };

  /// `null` when nothing is planned in total (shown as "n/a"), and when
  /// [isActualBlocked] (checked first by callers).
  double? get overallPercentageUsed => switch (totalActualMinorUnits) {
    final actual? => budgetPercentageUsed(
      plannedMinorUnits: totalPlannedMinorUnits,
      actualMinorUnits: actual,
    ),
    null => null,
  };

  /// FR-009: judged on the totals, independent of the individual lines —
  /// one category far over and several comfortably under can still net out
  /// under overall, and that case must read as *not* over. `null` (unknown)
  /// when [isActualBlocked].
  bool? get isOverBudgetOverall => switch (totalActualMinorUnits) {
    final actual? => actual > totalPlannedMinorUnits,
    null => null,
  };

  /// The same three-state rule as a line, applied to the totals — what the
  /// overall summary card's badge shows. `null` when [isActualBlocked].
  BudgetCategoryStatus? get overallStatus => switch (totalActualMinorUnits) {
    final actual? => budgetStatusFor(
      plannedMinorUnits: totalPlannedMinorUnits,
      actualMinorUnits: actual,
    ),
    null => null,
  };

  /// `null` when any unbudgeted item is blocked.
  int? get totalUnbudgetedMinorUnits =>
      unbudgetedSpending.any((item) => item.isBlocked)
      ? null
      : unbudgetedSpending.fold<int>(
          0,
          (sum, item) => sum + item.amountMinorUnits!,
        );

  Money get totalPlanned =>
      Money.fromMinorUnits(totalPlannedMinorUnits, currency);
  Money? get totalActual => _money(totalActualMinorUnits);
  Money? get totalRemaining => _money(totalRemainingMinorUnits);
  Money? get totalUnbudgeted => _money(totalUnbudgetedMinorUnits);

  Money? _money(int? minorUnits) => switch (minorUnits) {
    final value? => Money.fromMinorUnits(value, currency),
    null => null,
  };

  @override
  List<Object?> get props => [
    budgetId,
    categoryBreakdown,
    unbudgetedSpending,
    currency,
  ];
}

/// Everything the budget month screen renders for one month, assembled in
/// one read.
///
/// [budget] is `null` when the month has no budget yet — a normal outcome
/// that drives the FR-018 empty/offer-to-copy state, not an error. In that
/// case [summary] is `null` too.
class BudgetMonthDetail extends Equatable {
  const BudgetMonthDetail({required this.month, this.budget, this.summary});

  const BudgetMonthDetail.empty(this.month) : budget = null, summary = null;

  /// `'YYYY-MM'`.
  final String month;
  final Budget? budget;
  final BudgetSummary? summary;

  bool get hasBudget => budget != null;

  /// FR-004's non-blocking hint for the persisted budget.
  bool get plannedExceedsExpectedIncome =>
      summary != null &&
      budgetPlannedExceedsIncome(
        totalPlannedMinorUnits: summary!.totalPlannedMinorUnits,
        expectedIncomeMinorUnits: budget?.expectedIncomeMinorUnits,
      );

  @override
  List<Object?> get props => [month, budget, summary];
}
