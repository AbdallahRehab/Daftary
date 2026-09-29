import 'package:injectable/injectable.dart';

import '../../../../core/date/calendar_months.dart';
import '../entities/goal_progress.dart';
import '../entities/savings_goal.dart';
import '../entities/what_if_result.dart';

/// The single source of truth for every completion, required-contribution
/// and what-if figure (FR-010-FR-014, research.md Decision 1).
///
/// Pure: plain values in, plain values out — no repository, database,
/// Flutter or clock dependency, so every formula is exhaustively testable
/// and a what-if exploration structurally cannot write anything. Works only
/// in the goal's own currency, as integer minor units; it never converts
/// currency and never touches floating point (Principle VIII).
///
/// Rounding always errs toward reaching the goal on time: months round
/// **up** to the next whole month, a required contribution **up** to the
/// next minor unit (Assumptions). Months are calendar months, counted by
/// `wholeMonthsBetween` (research.md Decision 11). Only the calendar date of
/// `asOf` matters — its time of day is ignored.
///
/// A remaining amount at or below zero means nothing is left to save: 0
/// months, 0 required. Input validation (a non-positive target or
/// contribution, a past target date) is the calling use case's job; this
/// service only guards against dividing by zero.
abstract class SavingsCalculator {
  /// FR-010. `null` when [monthlyContributionMinorUnits] is `null` (or not
  /// positive). `estimatedMonths = ceil(remaining / monthlyContribution)`;
  /// `estimatedDate` is `asOf` plus that many calendar months.
  EstimatedCompletion? estimateFromMonthlyContribution({
    required int remainingMinorUnits,
    required int? monthlyContributionMinorUnits,
    required DateTime asOf,
  });

  /// FR-011. `null` when [targetDate] is `null`.
  /// `required = ceil(remaining / max(1, wholeMonthsBetween(asOf,
  /// targetDate)))` — a target date within the current month (or already
  /// past) still gets one month, never a division by zero.
  EstimatedCompletion? requiredContributionForTargetDate({
    required int remainingMinorUnits,
    required DateTime? targetDate,
    required DateTime asOf,
  });

  /// Both of the above combined, plus FR-012's shortfall when both a
  /// contribution and a target date are set. `null` when neither is.
  ///
  /// `shortfallMonths = estimatedMonths − max(1, wholeMonthsBetween(asOf,
  /// targetDate))` when positive — the same month count FR-011 divides by,
  /// so a shortfall is reported exactly when the contribution is below the
  /// required one.
  EstimatedCompletion? estimateCompletion({
    required int remainingMinorUnits,
    required int? monthlyContributionMinorUnits,
    required DateTime? targetDate,
    required DateTime asOf,
  });

  /// [goal]'s progress given its [currentAmountMinorUnits] (Σ contributions
  /// − Σ withdrawals). Its estimate is `null` once achieved — there is
  /// nothing left to estimate.
  GoalProgress progressFor(
    SavingsGoal goal, {
    required int currentAmountMinorUnits,
    required DateTime asOf,
  });

  /// FR-013: when the goal would be reached at a hypothetical monthly
  /// contribution. Same formula as [estimateFromMonthlyContribution].
  /// Throws [ArgumentError] for a hypothetical `<= 0` — the use case
  /// rejects that as a `ValidationFailure` before calling (FR-016).
  WhatIfResult whatIfMonthlyContribution({
    required int remainingMinorUnits,
    required int hypotheticalMonthlyContributionMinorUnits,
    required DateTime asOf,
  });

  /// FR-014: the monthly contribution needed to finish by a hypothetical
  /// target date. Same formula as [requiredContributionForTargetDate];
  /// `estimatedMonths` is how long that contribution then takes.
  WhatIfResult whatIfTargetDate({
    required int remainingMinorUnits,
    required DateTime hypotheticalTargetDate,
    required DateTime asOf,
  });
}

@LazySingleton(as: SavingsCalculator)
class DefaultSavingsCalculator implements SavingsCalculator {
  const DefaultSavingsCalculator();

  /// Beyond this many months the estimated date would overflow `DateTime`'s
  /// range (about 275,000 years), so it is left out; the month count
  /// itself is still exact.
  static const int _maxDatedMonths = 12 * 200000;

  @override
  EstimatedCompletion? estimateFromMonthlyContribution({
    required int remainingMinorUnits,
    required int? monthlyContributionMinorUnits,
    required DateTime asOf,
  }) {
    if (monthlyContributionMinorUnits == null ||
        monthlyContributionMinorUnits <= 0) {
      return null;
    }
    final months = _ceilDiv(
      _nonNegative(remainingMinorUnits),
      monthlyContributionMinorUnits,
    );
    return EstimatedCompletion(
      estimatedMonths: months,
      estimatedDate: _dateAfter(asOf, months),
    );
  }

  @override
  EstimatedCompletion? requiredContributionForTargetDate({
    required int remainingMinorUnits,
    required DateTime? targetDate,
    required DateTime asOf,
  }) {
    if (targetDate == null) return null;
    return EstimatedCompletion(
      requiredMonthlyContributionMinorUnits: _ceilDiv(
        _nonNegative(remainingMinorUnits),
        _monthsUntil(asOf, targetDate),
      ),
    );
  }

  @override
  EstimatedCompletion? estimateCompletion({
    required int remainingMinorUnits,
    required int? monthlyContributionMinorUnits,
    required DateTime? targetDate,
    required DateTime asOf,
  }) {
    final byContribution = estimateFromMonthlyContribution(
      remainingMinorUnits: remainingMinorUnits,
      monthlyContributionMinorUnits: monthlyContributionMinorUnits,
      asOf: asOf,
    );
    final byDate = requiredContributionForTargetDate(
      remainingMinorUnits: remainingMinorUnits,
      targetDate: targetDate,
      asOf: asOf,
    );
    if (byContribution == null) return byDate;
    if (byDate == null) return byContribution;

    final shortfall =
        byContribution.estimatedMonths! - _monthsUntil(asOf, targetDate!);
    return EstimatedCompletion(
      estimatedMonths: byContribution.estimatedMonths,
      estimatedDate: byContribution.estimatedDate,
      requiredMonthlyContributionMinorUnits:
          byDate.requiredMonthlyContributionMinorUnits,
      shortfallMonths: shortfall > 0 ? shortfall : null,
    );
  }

  @override
  GoalProgress progressFor(
    SavingsGoal goal, {
    required int currentAmountMinorUnits,
    required DateTime asOf,
  }) {
    final remaining = goal.targetAmountMinorUnits - currentAmountMinorUnits;
    return GoalProgress(
      goalId: goal.id,
      currency: goal.currency,
      targetAmountMinorUnits: goal.targetAmountMinorUnits,
      currentAmountMinorUnits: currentAmountMinorUnits,
      estimatedCompletion: remaining <= 0
          ? null
          : estimateCompletion(
              remainingMinorUnits: remaining,
              monthlyContributionMinorUnits: goal.monthlyContributionMinorUnits,
              targetDate: goal.targetDate,
              asOf: asOf,
            ),
    );
  }

  @override
  WhatIfResult whatIfMonthlyContribution({
    required int remainingMinorUnits,
    required int hypotheticalMonthlyContributionMinorUnits,
    required DateTime asOf,
  }) {
    if (hypotheticalMonthlyContributionMinorUnits <= 0) {
      throw ArgumentError.value(
        hypotheticalMonthlyContributionMinorUnits,
        'hypotheticalMonthlyContributionMinorUnits',
        'must be positive',
      );
    }
    final estimate = estimateFromMonthlyContribution(
      remainingMinorUnits: remainingMinorUnits,
      monthlyContributionMinorUnits: hypotheticalMonthlyContributionMinorUnits,
      asOf: asOf,
    )!;
    return WhatIfResult(
      hypotheticalMonthlyContributionMinorUnits:
          hypotheticalMonthlyContributionMinorUnits,
      hypotheticalTargetDate: estimate.estimatedDate,
      estimatedMonths: estimate.estimatedMonths,
    );
  }

  @override
  WhatIfResult whatIfTargetDate({
    required int remainingMinorUnits,
    required DateTime hypotheticalTargetDate,
    required DateTime asOf,
  }) {
    final remaining = _nonNegative(remainingMinorUnits);
    final required = _ceilDiv(
      remaining,
      _monthsUntil(asOf, hypotheticalTargetDate),
    );
    return WhatIfResult(
      hypotheticalMonthlyContributionMinorUnits: required,
      hypotheticalTargetDate: hypotheticalTargetDate,
      estimatedMonths: required == 0 ? 0 : _ceilDiv(remaining, required),
    );
  }

  /// Whole calendar months from [asOf] to [targetDate], floored at 1.
  static int _monthsUntil(DateTime asOf, DateTime targetDate) {
    final months = wholeMonthsBetween(asOf, targetDate);
    return months < 1 ? 1 : months;
  }

  /// [asOf]'s calendar date plus [months], or `null` past `DateTime`'s range.
  static DateTime? _dateAfter(DateTime asOf, int months) {
    if (months > _maxDatedMonths) return null;
    final day = asOf.isUtc
        ? DateTime.utc(asOf.year, asOf.month, asOf.day)
        : DateTime(asOf.year, asOf.month, asOf.day);
    return addCalendarMonths(day, months);
  }

  static int _nonNegative(int value) => value > 0 ? value : 0;

  /// `ceil(numerator / denominator)` for `numerator >= 0`,
  /// `denominator > 0`, in integers only — and without the `n + d − 1`
  /// form, which could overflow near the money ceiling.
  static int _ceilDiv(int numerator, int denominator) {
    final quotient = numerator ~/ denominator;
    return numerator % denominator == 0 ? quotient : quotient + 1;
  }
}
