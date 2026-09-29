import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_type.dart';
import 'package:daftary/features/savings/domain/entities/what_if_mode.dart';
import 'package:daftary/features/savings/domain/entities/what_if_result.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/apply_what_if_scenario.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_completion_date.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_monthly_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/edit_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/savings_harness.dart';
import '../../helpers/savings_test_data.dart';

/// T045 — critical path (SC-004): exploring a what-if never writes; only
/// `ApplyWhatIfScenario` changes the real goal, and only to the scenario's
/// values (FR-015).
void main() {
  group('exploring makes zero repository writes (mock verification)', () {
    late MockSavingsRepository repository;
    final goal = testGoal(
      target: 10000000,
      monthly: 500000,
      targetDate: DateTime(2027, 12, 1),
    );
    final detail = testDetail(goal, history: [testEntry(amount: 3500000)]);

    setUp(() {
      repository = MockSavingsRepository();
      when(
        () => repository.getGoalDetail('g1'),
      ).thenAnswer((_) async => Right(detail));
    });

    test('CalculateWhatIfMonthlyContribution only reads the goal', () async {
      final calculate = CalculateWhatIfMonthlyContribution(
        GetGoalDetail(repository),
        const DefaultSavingsCalculator(),
        SettableClock(testToday),
      );

      final result = await calculate(
        goalId: 'g1',
        hypotheticalMonthlyContributionMinorUnits: 600000,
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.getGoalDetail('g1')).called(1);
      // Nothing else — no edit, create, log, archive or delete of any kind.
      verifyNoMoreInteractions(repository);
    });

    test('CalculateWhatIfCompletionDate only reads the goal', () async {
      final calculate = CalculateWhatIfCompletionDate(
        GetGoalDetail(repository),
        const DefaultSavingsCalculator(),
        SettableClock(testToday),
      );

      final result = await calculate(
        goalId: 'g1',
        hypotheticalTargetDate: DateTime(2027, 7, 15),
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.getGoalDetail('g1')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('applying the same scenario is the one call that edits', () async {
      final clock = SettableClock(testToday);
      final getDetail = GetGoalDetail(repository);
      final scenario =
          (await CalculateWhatIfMonthlyContribution(
                getDetail,
                const DefaultSavingsCalculator(),
                clock,
              )(
                goalId: 'g1',
                hypotheticalMonthlyContributionMinorUnits: 600000,
              ))
              .toNullable()!;
      verifyNever(
        () => repository.editSavingsGoal(
          goalId: any(named: 'goalId'),
          name: any(named: 'name'),
          type: any(named: 'type'),
          targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
          monthlyContributionMinorUnits: any(
            named: 'monthlyContributionMinorUnits',
          ),
          targetDate: any(named: 'targetDate'),
        ),
      );

      when(
        () => repository.editSavingsGoal(
          goalId: any(named: 'goalId'),
          name: any(named: 'name'),
          type: any(named: 'type'),
          targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
          monthlyContributionMinorUnits: any(
            named: 'monthlyContributionMinorUnits',
          ),
          targetDate: any(named: 'targetDate'),
        ),
      ).thenAnswer((_) async => Right(goal));

      await ApplyWhatIfScenario(getDetail, EditSavingsGoal(repository))(
        goalId: 'g1',
        mode: WhatIfMode.monthlyContribution,
        scenario: scenario,
      );

      verify(
        () => repository.editSavingsGoal(
          goalId: 'g1',
          name: goal.name,
          type: goal.type,
          targetAmountMinorUnits: goal.targetAmountMinorUnits,
          monthlyContributionMinorUnits: 600000,
          targetDate: DateTime(2027, 12, 1),
        ),
      ).called(1);
    });
  });

  group('through the real repository', () {
    late SavingsHarness h;
    late GetGoalDetail getDetail;
    late ApplyWhatIfScenario apply;

    setUp(() async {
      h = await SavingsHarness.open();
      getDetail = GetGoalDetail(h.repository);
      apply = ApplyWhatIfScenario(getDetail, EditSavingsGoal(h.repository));
    });

    tearDown(() => h.close());

    test('a monthly-contribution scenario sets the monthly contribution and '
        'keeps everything else, including the stored target date', () async {
      final goal = await h.createGoal(
        name: 'Car',
        type: SavingsGoalType.newCar,
        target: 10000000,
        starting: 3500000,
        monthly: 500000,
        targetDate: DateTime(2027, 12, 1),
      );
      final scenario =
          (await CalculateWhatIfMonthlyContribution(
                getDetail,
                const DefaultSavingsCalculator(),
                h.clock,
              )(
                goalId: goal.id,
                hypotheticalMonthlyContributionMinorUnits: 600000,
              ))
              .toNullable()!;
      // Exploring alone changed nothing.
      expect((await h.detail(goal.id)).goal, goal);

      final result = await apply(
        goalId: goal.id,
        mode: WhatIfMode.monthlyContribution,
        scenario: scenario,
      );

      final applied = result.toNullable()!;
      expect(applied.monthlyContributionMinorUnits, 600000);
      expect(applied.targetDate, DateTime(2027, 12, 1));
      expect(applied.name, 'Car');
      expect(applied.type, SavingsGoalType.newCar);
      expect(applied.targetAmountMinorUnits, 10000000);
      final detail = await h.detail(goal.id);
      expect(detail.progress.estimatedCompletion!.estimatedMonths, 11);
      expect(detail.progress.currentAmountMinorUnits, 3500000);
    });

    test('a target-date scenario sets the target date and the monthly '
        'contribution it requires', () async {
      final goal = await h.createGoal(
        target: 10000000,
        starting: 3500000,
        monthly: 500000,
      );
      final scenario =
          (await CalculateWhatIfCompletionDate(
                getDetail,
                const DefaultSavingsCalculator(),
                h.clock,
              )(goalId: goal.id, hypotheticalTargetDate: DateTime(2027, 7, 15)))
              .toNullable()!;
      expect((await h.detail(goal.id)).goal, goal);

      final applied = (await apply(
        goalId: goal.id,
        mode: WhatIfMode.targetDate,
        scenario: scenario,
      )).toNullable()!;

      expect(applied.targetDate, DateTime(2027, 7, 15));
      expect(applied.monthlyContributionMinorUnits, 650000);
      final estimate = (await h.detail(goal.id)).progress.estimatedCompletion!;
      expect(estimate.requiredMonthlyContributionMinorUnits, 650000);
      expect(estimate.hasShortfall, isFalse);
    });

    test('a scenario date that has since become past is rejected and '
        'nothing changes', () async {
      final goal = await h.createGoal(target: 1000000, monthly: 100000);

      final result = await apply(
        goalId: goal.id,
        mode: WhatIfMode.targetDate,
        scenario: WhatIfResult(
          hypotheticalMonthlyContributionMinorUnits: 200000,
          hypotheticalTargetDate: h.today,
          estimatedMonths: 5,
        ),
      );

      expect(result.getLeft().toNullable(), isA<InvalidTargetDateFailure>());
      expect((await h.detail(goal.id)).goal, goal);
    });

    test('a scenario missing the value its mode applies is a '
        'ValidationFailure', () async {
      final goal = await h.createGoal(target: 1000000);

      final result = await apply(
        goalId: goal.id,
        mode: WhatIfMode.targetDate,
        scenario: const WhatIfResult(
          hypotheticalMonthlyContributionMinorUnits: 100000,
        ),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect((await h.detail(goal.id)).goal, goal);
    });

    test('an achieved goal is GoalAlreadyAchievedFailure and nothing '
        'changes', () async {
      final goal = await h.createGoal(target: 1000000, starting: 1000000);

      final result = await apply(
        goalId: goal.id,
        mode: WhatIfMode.monthlyContribution,
        scenario: const WhatIfResult(
          hypotheticalMonthlyContributionMinorUnits: 100000,
        ),
      );

      expect(result.getLeft().toNullable(), isA<GoalAlreadyAchievedFailure>());
      expect((await h.detail(goal.id)).goal, goal);
    });
  });
}
