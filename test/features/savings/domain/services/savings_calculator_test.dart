import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/savings/domain/entities/goal_progress.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal.dart';
import 'package:daftary/features/savings/domain/entities/what_if_result.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// EGP major units → minor units, so the table reads like the spec.
int egp(int major) => major * 100;

/// The largest amount the app accepts: 999,999,999,999.99
/// (`CurrencyFormatter.maxWholeDigits`).
const int moneyCeiling = 99999999999999;

/// One row of the SC-003 table.
typedef _Case = ({
  String name,
  int remaining,
  int? monthly,
  DateTime? targetDate,
  int? months,
  DateTime? estimatedDate,
  int? required,
  int? shortfall,
});

/// T010 — SC-003's release-blocking anchor: every estimated-completion,
/// required-contribution and shortfall figure matches FR-010/FR-011/FR-012
/// exactly, with integer-only arithmetic (Principle VIII).
void main() {
  const calculator = DefaultSavingsCalculator();

  // "Today" in every case: 20 January 2026.
  final asOf = DateTime(2026, 1, 20);

  final cases = <_Case>[
    // --- The spec's worked examples (US1 AS-1/AS-2, US3 AS-1/AS-2).
    (
      name: 'spec: 100,000 / 5,000 per month → 20 months',
      remaining: egp(100000),
      monthly: egp(5000),
      targetDate: null,
      months: 20,
      estimatedDate: DateTime(2027, 9, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: 'spec: 65,000 remaining (35,000 saved) / 5,000 → 13 months',
      remaining: egp(65000),
      monthly: egp(5000),
      targetDate: null,
      months: 13,
      estimatedDate: DateTime(2027, 2, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: 'spec: +1,000 per month → 6,000 → 11 months',
      remaining: egp(65000),
      monthly: egp(6000),
      targetDate: null,
      months: 11,
      estimatedDate: DateTime(2026, 12, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: 'spec: finish in 10 months → 6,500 per month',
      remaining: egp(65000),
      monthly: null,
      targetDate: DateTime(2026, 11, 20),
      months: null,
      estimatedDate: null,
      required: egp(6500),
      shortfall: null,
    ),
    // --- Nothing left to save.
    (
      name: 'remaining 0 with a contribution → 0 months, today',
      remaining: 0,
      monthly: egp(5000),
      targetDate: null,
      months: 0,
      estimatedDate: DateTime(2026, 1, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: 'remaining 0 with a target date → 0 required',
      remaining: 0,
      monthly: null,
      targetDate: DateTime(2026, 6, 20),
      months: null,
      estimatedDate: null,
      required: 0,
      shortfall: null,
    ),
    (
      name: 'over-achieved (negative remaining) is treated as 0',
      remaining: -egp(500),
      monthly: egp(5000),
      targetDate: DateTime(2026, 6, 20),
      months: 0,
      estimatedDate: DateTime(2026, 1, 20),
      required: 0,
      shortfall: null,
    ),
    // --- Rounding up (Assumptions: never over-promise).
    (
      name: 'contribution larger than remaining → 1 month',
      remaining: egp(1000),
      monthly: egp(5000),
      targetDate: null,
      months: 1,
      estimatedDate: DateTime(2026, 2, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: 'contribution exactly equal to remaining → 1 month',
      remaining: egp(5000),
      monthly: egp(5000),
      targetDate: null,
      months: 1,
      estimatedDate: DateTime(2026, 2, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: 'one minor unit over a whole month count rounds up',
      remaining: egp(10000) + 1,
      monthly: egp(10000),
      targetDate: null,
      months: 2,
      estimatedDate: DateTime(2026, 3, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: '12.1 months displays as 13',
      remaining: egp(12100),
      monthly: egp(1000),
      targetDate: null,
      months: 13,
      estimatedDate: DateTime(2027, 2, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: 'required contribution rounds up to the next minor unit',
      remaining: egp(1000),
      monthly: null,
      targetDate: DateTime(2026, 4, 20),
      months: null,
      estimatedDate: null,
      required: 33334, // 100,000 / 3 = 33,333.3…
      shortfall: null,
    ),
    (
      name: 'required contribution that divides exactly is not bumped',
      remaining: egp(900),
      monthly: null,
      targetDate: DateTime(2026, 4, 20),
      months: null,
      estimatedDate: null,
      required: egp(300),
      shortfall: null,
    ),
    // --- Month counting (research.md Decision 11).
    (
      name: 'target date within the current month → 1 month, all of it',
      remaining: egp(65000),
      monthly: null,
      targetDate: DateTime(2026, 1, 28),
      months: null,
      estimatedDate: null,
      required: egp(65000),
      shortfall: null,
    ),
    (
      name: 'target day-of-month earlier than today counts one month less',
      remaining: egp(65000),
      monthly: null,
      targetDate: DateTime(2026, 11, 5), // 9 whole months, not 10
      months: null,
      estimatedDate: null,
      required: 722223, // 6,500,000 / 9 = 722,222.2…
      shortfall: null,
    ),
    (
      name: 'an overdue target date floors at 1 month',
      remaining: egp(2000),
      monthly: null,
      targetDate: DateTime(2025, 12, 1),
      months: null,
      estimatedDate: null,
      required: egp(2000),
      shortfall: null,
    ),
    // --- FR-012: both set.
    (
      name: 'shortfall: 13 months against a 10-month target → 3 months late',
      remaining: egp(65000),
      monthly: egp(5000),
      targetDate: DateTime(2026, 11, 20),
      months: 13,
      estimatedDate: DateTime(2027, 2, 20),
      required: egp(6500),
      shortfall: 3,
    ),
    (
      name: 'shortfall: the "4 months after your target date" edge case',
      remaining: egp(70000),
      monthly: egp(5000),
      targetDate: DateTime(2026, 11, 20),
      months: 14,
      estimatedDate: DateTime(2027, 3, 20),
      required: egp(7000),
      shortfall: 4,
    ),
    (
      name: 'shortfall counted against a day-of-month-earlier target',
      remaining: egp(65000),
      monthly: egp(5000),
      targetDate: DateTime(2026, 11, 5),
      months: 13,
      estimatedDate: DateTime(2027, 2, 20),
      required: 722223,
      shortfall: 4,
    ),
    (
      name: 'contribution exactly meeting the target date → no shortfall',
      remaining: egp(65000),
      monthly: egp(6500),
      targetDate: DateTime(2026, 11, 20),
      months: 10,
      estimatedDate: DateTime(2026, 11, 20),
      required: egp(6500),
      shortfall: null,
    ),
    (
      name: 'contribution beating the target date → no shortfall',
      remaining: egp(65000),
      monthly: egp(10000),
      targetDate: DateTime(2026, 11, 20),
      months: 7,
      estimatedDate: DateTime(2026, 8, 20),
      required: egp(6500),
      shortfall: null,
    ),
    (
      name: 'one minor unit short of the required contribution → 1 month late',
      remaining: egp(65000),
      monthly: egp(6500) - 1,
      targetDate: DateTime(2026, 11, 20),
      months: 11,
      estimatedDate: DateTime(2026, 12, 20),
      required: egp(6500),
      shortfall: 1,
    ),
    // --- Extremes.
    (
      name: 'very long timeline: 1 EGP a month toward 1,000,000 EGP',
      remaining: egp(1000000),
      monthly: egp(1),
      targetDate: null,
      months: 1000000,
      estimatedDate: DateTime(85359, 5, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: 'the money ceiling: 999,999,999,999.99 at 10,000,000,000 a month',
      remaining: moneyCeiling,
      monthly: egp(10000000000),
      targetDate: null,
      months: 100,
      estimatedDate: DateTime(2034, 5, 20),
      required: null,
      shortfall: null,
    ),
    (
      name: 'the money ceiling: required contribution over 7 months',
      remaining: moneyCeiling,
      monthly: null,
      targetDate: DateTime(2026, 8, 20),
      months: null,
      estimatedDate: null,
      required: 14285714285715, // 99,999,999,999,999 / 7 = …714.1
      shortfall: null,
    ),
    (
      name: 'the money ceiling at 1 minor unit a month has no calendar date',
      remaining: moneyCeiling,
      monthly: 1,
      targetDate: null,
      months: moneyCeiling,
      estimatedDate: null,
      required: null,
      shortfall: null,
    ),
  ];

  test('SC-003: the table has at least 20 cases', () {
    expect(cases.length, greaterThanOrEqualTo(20));
  });

  group('estimateCompletion (FR-010/FR-011/FR-012)', () {
    for (final c in cases) {
      test(c.name, () {
        final result = calculator.estimateCompletion(
          remainingMinorUnits: c.remaining,
          monthlyContributionMinorUnits: c.monthly,
          targetDate: c.targetDate,
          asOf: asOf,
        );
        expect(
          result,
          EstimatedCompletion(
            estimatedMonths: c.months,
            estimatedDate: c.estimatedDate,
            requiredMonthlyContributionMinorUnits: c.required,
            shortfallMonths: c.shortfall,
          ),
        );
        expect(result!.hasShortfall, c.shortfall != null);
      });
    }

    test('neither a contribution nor a target date → no estimate', () {
      expect(
        calculator.estimateCompletion(
          remainingMinorUnits: egp(65000),
          monthlyContributionMinorUnits: null,
          targetDate: null,
          asOf: asOf,
        ),
        isNull,
      );
    });

    test('a non-positive stored contribution is treated as unset', () {
      expect(
        calculator.estimateCompletion(
          remainingMinorUnits: egp(65000),
          monthlyContributionMinorUnits: 0,
          targetDate: null,
          asOf: asOf,
        ),
        isNull,
      );
    });

    test('shortfall ⇔ the contribution is below the required one', () {
      // FR-012's month-count definition agrees with FR-011's figure for
      // every contribution around the break-even point.
      final target = DateTime(2026, 11, 20);
      for (var monthly = egp(6400); monthly <= egp(6600); monthly += 7) {
        final result = calculator.estimateCompletion(
          remainingMinorUnits: egp(65000),
          monthlyContributionMinorUnits: monthly,
          targetDate: target,
          asOf: asOf,
        )!;
        expect(
          result.hasShortfall,
          monthly < result.requiredMonthlyContributionMinorUnits!,
          reason: 'monthly $monthly',
        );
      }
    });

    test('the time of day of "today" never changes the estimate', () {
      final late = calculator.estimateCompletion(
        remainingMinorUnits: egp(65000),
        monthlyContributionMinorUnits: egp(5000),
        targetDate: DateTime(2026, 11, 20),
        asOf: DateTime(2026, 1, 20, 23, 59),
      );
      final early = calculator.estimateCompletion(
        remainingMinorUnits: egp(65000),
        monthlyContributionMinorUnits: egp(5000),
        targetDate: DateTime(2026, 11, 20),
        asOf: asOf,
      );
      expect(late, early);
    });
  });

  group('the single-plan estimates', () {
    test('estimateFromMonthlyContribution carries months and date only', () {
      expect(
        calculator.estimateFromMonthlyContribution(
          remainingMinorUnits: egp(100000),
          monthlyContributionMinorUnits: egp(5000),
          asOf: asOf,
        ),
        EstimatedCompletion(
          estimatedMonths: 20,
          estimatedDate: DateTime(2027, 9, 20),
        ),
      );
      expect(
        calculator.estimateFromMonthlyContribution(
          remainingMinorUnits: egp(100000),
          monthlyContributionMinorUnits: null,
          asOf: asOf,
        ),
        isNull,
      );
    });

    test('requiredContributionForTargetDate carries the amount only', () {
      expect(
        calculator.requiredContributionForTargetDate(
          remainingMinorUnits: egp(65000),
          targetDate: DateTime(2026, 11, 20),
          asOf: asOf,
        ),
        EstimatedCompletion(requiredMonthlyContributionMinorUnits: egp(6500)),
      );
      expect(
        calculator.requiredContributionForTargetDate(
          remainingMinorUnits: egp(65000),
          targetDate: null,
          asOf: asOf,
        ),
        isNull,
      );
    });
  });

  group('what-if (FR-013/FR-014)', () {
    test('what if I save 6,000 a month → 11 months', () {
      expect(
        calculator.whatIfMonthlyContribution(
          remainingMinorUnits: egp(65000),
          hypotheticalMonthlyContributionMinorUnits: egp(6000),
          asOf: asOf,
        ),
        WhatIfResult(
          hypotheticalMonthlyContributionMinorUnits: egp(6000),
          hypotheticalTargetDate: DateTime(2026, 12, 20),
          estimatedMonths: 11,
        ),
      );
    });

    test('what do I need to finish in 10 months → 6,500 a month', () {
      expect(
        calculator.whatIfTargetDate(
          remainingMinorUnits: egp(65000),
          hypotheticalTargetDate: DateTime(2026, 11, 20),
          asOf: asOf,
        ),
        WhatIfResult(
          hypotheticalMonthlyContributionMinorUnits: egp(6500),
          hypotheticalTargetDate: DateTime(2026, 11, 20),
          estimatedMonths: 10,
        ),
      );
    });

    test('a rounded-up requirement can finish a little early', () {
      // 6,500,000 / 9 → 722,223 a month, which still needs all 9 months.
      expect(
        calculator
            .whatIfTargetDate(
              remainingMinorUnits: egp(65000),
              hypotheticalTargetDate: DateTime(2026, 11, 5),
              asOf: asOf,
            )
            .estimatedMonths,
        9,
      );
    });

    test('nothing left to save → nothing required, 0 months', () {
      expect(
        calculator.whatIfTargetDate(
          remainingMinorUnits: 0,
          hypotheticalTargetDate: DateTime(2026, 11, 20),
          asOf: asOf,
        ),
        WhatIfResult(
          hypotheticalMonthlyContributionMinorUnits: 0,
          hypotheticalTargetDate: DateTime(2026, 11, 20),
          estimatedMonths: 0,
        ),
      );
    });

    test('a non-positive hypothetical contribution is a caller bug', () {
      for (final monthly in [0, -1]) {
        expect(
          () => calculator.whatIfMonthlyContribution(
            remainingMinorUnits: egp(65000),
            hypotheticalMonthlyContributionMinorUnits: monthly,
            asOf: asOf,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('progressFor', () {
    SavingsGoal goal({
      int target = 10000000,
      int? monthly,
      DateTime? targetDate,
    }) => SavingsGoal(
      id: 'g1',
      idempotencyKey: 'k1',
      name: 'Emergency Fund',
      currency: Currency.egp,
      targetAmountMinorUnits: target,
      monthlyContributionMinorUnits: monthly,
      targetDate: targetDate,
      createdAt: asOf,
      updatedAt: asOf,
    );

    test('spec: 35,000 of 100,000 saved at 5,000 a month', () {
      final progress = calculator.progressFor(
        goal(monthly: egp(5000)),
        currentAmountMinorUnits: egp(35000),
        asOf: asOf,
      );
      expect(progress.remainingMinorUnits, egp(65000));
      expect(progress.percentageProgress, 35);
      expect(progress.isAchieved, isFalse);
      expect(progress.estimatedCompletion?.estimatedMonths, 13);
      expect(progress.currency, Currency.egp);
    });

    test('an achieved goal has nothing left to estimate', () {
      final progress = calculator.progressFor(
        goal(monthly: egp(5000), targetDate: DateTime(2026, 11, 20)),
        currentAmountMinorUnits: egp(120000),
        asOf: asOf,
      );
      expect(progress.isAchieved, isTrue);
      expect(progress.remainingMinorUnits, 0);
      expect(progress.percentageProgress, 100);
      expect(progress.estimatedCompletion, isNull);
    });

    test('a goal with no plan shows no estimate', () {
      final progress = calculator.progressFor(
        goal(),
        currentAmountMinorUnits: egp(1000),
        asOf: asOf,
      );
      expect(progress.estimatedCompletion, isNull);
      expect(progress.percentageProgress, closeTo(1, 1e-9));
    });

    test('an empty goal is at 0%', () {
      final progress = calculator.progressFor(
        goal(targetDate: DateTime(2026, 11, 20)),
        currentAmountMinorUnits: 0,
        asOf: asOf,
      );
      expect(progress.percentageProgress, 0);
      expect(
        progress.estimatedCompletion?.requiredMonthlyContributionMinorUnits,
        egp(10000),
      );
    });
  });
}
