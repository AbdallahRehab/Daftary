import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/what_if_result.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_completion_date.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_monthly_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/savings_harness.dart';
import '../../helpers/savings_test_data.dart';

/// T044 — `CalculateWhatIfMonthlyContribution` / `CalculateWhatIfCompletionDate`
/// (FR-013/FR-014/FR-016) against the spec's worked examples (US3 AS-1/2).
void main() {
  late MockSavingsRepository repository;
  late CalculateWhatIfMonthlyContribution byMonthly;
  late CalculateWhatIfCompletionDate byDate;

  // 100,000 EGP target, 35,000 saved → 65,000 remaining; 5,000/month is
  // 13 months today (US3 AS-1's starting point).
  final goal = testGoal(target: 10000000, monthly: 500000);
  final detail = testDetail(goal, history: [testEntry(amount: 3500000)]);
  final achieved = testDetail(
    testGoal(target: 1000000, monthly: 100000),
    history: [testEntry(amount: 1000000)],
  );

  setUp(() {
    repository = MockSavingsRepository();
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(detail));
    final getDetail = GetGoalDetail(repository);
    final clock = SettableClock(testToday);
    byMonthly = CalculateWhatIfMonthlyContribution(
      getDetail,
      const DefaultSavingsCalculator(),
      clock,
    );
    byDate = CalculateWhatIfCompletionDate(
      getDetail,
      const DefaultSavingsCalculator(),
      clock,
    );
  });

  group('CalculateWhatIfMonthlyContribution (FR-013)', () {
    test('US3 AS-1: 1,000 EGP more per month (6,000) finishes in 11 months '
        'instead of 13', () async {
      expect(detail.progress.remainingMinorUnits, 6500000);
      expect(detail.progress.estimatedCompletion!.estimatedMonths, 13);

      final result = await byMonthly(
        goalId: 'g1',
        hypotheticalMonthlyContributionMinorUnits: 600000,
      );

      expect(
        result.toNullable(),
        WhatIfResult(
          hypotheticalMonthlyContributionMinorUnits: 600000,
          hypotheticalTargetDate: DateTime(2027, 8, 15),
          estimatedMonths: 11,
        ),
      );
    });

    test('rounds a partial month up', () async {
      final result = await byMonthly(
        goalId: 'g1',
        hypotheticalMonthlyContributionMinorUnits: 700000,
      );
      // 65,000 / 7,000 = 9.28… → 10 months.
      expect(result.toNullable()!.estimatedMonths, 10);
    });

    for (final amount in [0, -100]) {
      test('rejects a non-positive hypothetical ($amount) as '
          'ValidationFailure (FR-016), without reading the goal', () async {
        final result = await byMonthly(
          goalId: 'g1',
          hypotheticalMonthlyContributionMinorUnits: amount,
        );
        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        verifyNever(() => repository.getGoalDetail(any()));
      });
    }

    test('an achieved goal is GoalAlreadyAchievedFailure (FR-016)', () async {
      when(
        () => repository.getGoalDetail('g1'),
      ).thenAnswer((_) async => Right(achieved));

      final result = await byMonthly(
        goalId: 'g1',
        hypotheticalMonthlyContributionMinorUnits: 100000,
      );

      expect(result.getLeft().toNullable(), isA<GoalAlreadyAchievedFailure>());
    });

    test('an unknown goal passes GoalNotFoundFailure through', () async {
      when(() => repository.getGoalDetail('missing')).thenAnswer(
        (_) async => const Left(GoalNotFoundFailure('Savings goal not found')),
      );

      final result = await byMonthly(
        goalId: 'missing',
        hypotheticalMonthlyContributionMinorUnits: 100000,
      );

      expect(result.getLeft().toNullable(), isA<GoalNotFoundFailure>());
    });
  });

  group('CalculateWhatIfCompletionDate (FR-014)', () {
    test('US3 AS-2: finishing in 10 months needs 6,500 EGP a month', () async {
      final result = await byDate(
        goalId: 'g1',
        hypotheticalTargetDate: DateTime(2027, 7, 15),
      );

      expect(
        result.toNullable(),
        WhatIfResult(
          hypotheticalMonthlyContributionMinorUnits: 650000,
          hypotheticalTargetDate: DateTime(2027, 7, 15),
          estimatedMonths: 10,
        ),
      );
    });

    test(
      'rounds the required contribution up to the next minor unit',
      () async {
        // 65,000 over 3 months = 21,666.66… → 21,666.67.
        final result = await byDate(
          goalId: 'g1',
          hypotheticalTargetDate: DateTime(2026, 12, 15),
        );
        expect(
          result.toNullable()!.hypotheticalMonthlyContributionMinorUnits,
          2166667,
        );
      },
    );

    test(
      'a date later this month still gets one month, never infinity',
      () async {
        final result = await byDate(
          goalId: 'g1',
          hypotheticalTargetDate: DateTime(2026, 9, 30),
        );
        expect(
          result.toNullable()!.hypotheticalMonthlyContributionMinorUnits,
          6500000,
        );
      },
    );

    for (final date in [DateTime(2026, 9, 15), DateTime(2025, 1, 1)]) {
      test('rejects today or a past date ($date) as InvalidTargetDateFailure '
          '(FR-016), without reading the goal', () async {
        final result = await byDate(goalId: 'g1', hypotheticalTargetDate: date);
        expect(result.getLeft().toNullable(), isA<InvalidTargetDateFailure>());
        verifyNever(() => repository.getGoalDetail(any()));
      });
    }

    test('an achieved goal is GoalAlreadyAchievedFailure (FR-016)', () async {
      when(
        () => repository.getGoalDetail('g1'),
      ).thenAnswer((_) async => Right(achieved));

      final result = await byDate(
        goalId: 'g1',
        hypotheticalTargetDate: DateTime(2027, 7, 15),
      );

      expect(result.getLeft().toNullable(), isA<GoalAlreadyAchievedFailure>());
    });
  });
}
