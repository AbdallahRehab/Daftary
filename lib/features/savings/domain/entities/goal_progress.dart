import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// When a goal is expected to be reached, per its plan (FR-010/FR-011/
/// FR-012). Derived by `SavingsCalculator`, never persisted.
///
/// Carries whichever figures the goal's plan supports: [estimatedMonths] and
/// [estimatedDate] when a monthly contribution is set,
/// [requiredMonthlyContributionMinorUnits] when a target date is set, and
/// both when both are — in which case [shortfallMonths] says honestly how
/// far the contribution misses the date, never silently picking one.
class EstimatedCompletion extends Equatable {
  const EstimatedCompletion({
    this.estimatedMonths,
    this.estimatedDate,
    this.requiredMonthlyContributionMinorUnits,
    this.shortfallMonths,
  });

  /// `ceil(remaining / monthlyContribution)` — always rounded up (FR-010).
  /// `null` when the goal has no monthly contribution.
  final int? estimatedMonths;

  /// Today plus [estimatedMonths] calendar months; `null` alongside it.
  final DateTime? estimatedDate;

  /// `ceil(remaining / max(1, wholeMonthsBetween(today, targetDate)))`,
  /// rounded up to the next minor unit (FR-011). `null` when the goal has
  /// no target date.
  final int? requiredMonthlyContributionMinorUnits;

  /// By how many whole months the monthly contribution misses the target
  /// date (FR-012); `null` when it does not, or when either is unset.
  final int? shortfallMonths;

  /// The monthly contribution and target date disagree (FR-012).
  bool get hasShortfall => shortfallMonths != null;

  @override
  List<Object?> get props => [
    estimatedMonths,
    estimatedDate,
    requiredMonthlyContributionMinorUnits,
    shortfallMonths,
  ];
}

/// One goal's computed figures (FR-004/FR-010/FR-011/FR-012/FR-017),
/// derived from its contribution history on every read and never persisted.
///
/// Only [currentAmountMinorUnits] and [targetAmountMinorUnits] are inputs;
/// remaining, percentage and achieved are getters over them, so no two
/// figures on screen can ever disagree.
class GoalProgress extends Equatable {
  const GoalProgress({
    required this.goalId,
    required this.currency,
    required this.targetAmountMinorUnits,
    required this.currentAmountMinorUnits,
    this.estimatedCompletion,
  });

  final String goalId;

  /// The goal's own currency; every figure here is in it.
  final Currency currency;
  final int targetAmountMinorUnits;

  /// Σ contributions − Σ withdrawals over the goal's non-deleted entries
  /// (research.md Decision 2).
  final int currentAmountMinorUnits;

  /// `null` when the goal has neither a monthly contribution nor a target
  /// date, or is already achieved (nothing left to estimate).
  final EstimatedCompletion? estimatedCompletion;

  /// Never negative: an over-achieved goal has `0` remaining.
  int get remainingMinorUnits {
    final remaining = targetAmountMinorUnits - currentAmountMinorUnits;
    return remaining > 0 ? remaining : 0;
  }

  /// `0..100`, capped at 100 even when over-achieved. For display only —
  /// no money figure is ever derived from it.
  double get percentageProgress {
    if (targetAmountMinorUnits <= 0 || currentAmountMinorUnits <= 0) return 0;
    if (currentAmountMinorUnits >= targetAmountMinorUnits) return 100;
    return currentAmountMinorUnits / targetAmountMinorUnits * 100;
  }

  /// Reversible: a later withdrawal, edit or delete that brings the current
  /// amount below target un-achieves the goal (FR-017/FR-018).
  bool get isAchieved => currentAmountMinorUnits >= targetAmountMinorUnits;

  Money get currentAmount =>
      Money.fromMinorUnits(currentAmountMinorUnits, currency);

  Money get remainingAmount =>
      Money.fromMinorUnits(remainingMinorUnits, currency);

  Money get targetAmount =>
      Money.fromMinorUnits(targetAmountMinorUnits, currency);

  @override
  List<Object?> get props => [
    goalId,
    currency,
    targetAmountMinorUnits,
    currentAmountMinorUnits,
    estimatedCompletion,
  ];
}
