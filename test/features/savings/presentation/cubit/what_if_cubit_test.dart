import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/what_if_mode.dart';
import 'package:daftary/features/savings/domain/entities/what_if_result.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/apply_what_if_scenario.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_completion_date.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_monthly_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/edit_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/presentation/cubit/what_if_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/what_if_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/savings_harness.dart';
import '../../helpers/savings_test_data.dart';

/// T046 — `WhatIfCubit`: the hypothetical result is held apart from the
/// real goal; explore-then-apply changes the goal, explore-then-cancel
/// leaves it untouched (verified by re-fetching), and an achieved goal gets
/// the "nothing left to plan" state (FR-013-FR-016).
void main() {
  WhatIfCubit cubitOver(MockSavingsRepository repository) {
    final getDetail = GetGoalDetail(repository);
    final clock = SettableClock(testToday);
    const calculator = DefaultSavingsCalculator();
    return WhatIfCubit(
      getDetail,
      CalculateWhatIfMonthlyContribution(getDetail, calculator, clock),
      CalculateWhatIfCompletionDate(getDetail, calculator, clock),
      ApplyWhatIfScenario(getDetail, EditSavingsGoal(repository)),
    );
  }

  group('with a mocked repository', () {
    late MockSavingsRepository repository;
    final goal = testGoal(target: 10000000, monthly: 500000);
    final detail = testDetail(goal, history: [testEntry(amount: 3500000)]);
    final achieved = testDetail(
      testGoal(target: 1000000),
      history: [testEntry(amount: 1000000)],
    );

    setUp(() => repository = MockSavingsRepository());

    blocTest<WhatIfCubit, WhatIfState>(
      'load, then a monthly what-if: the result is a separate field and the '
      'real goal detail is untouched',
      setUp: () => when(
        () => repository.getGoalDetail('g1'),
      ).thenAnswer((_) async => Right(detail)),
      build: () => cubitOver(repository),
      act: (cubit) async {
        await cubit.load('g1');
        cubit.monthlyChanged('6000');
        await cubit.calculate();
      },
      expect: () => [
        const WhatIfState(goalId: 'g1'),
        WhatIfState(goalId: 'g1', status: WhatIfStatus.ready, detail: detail),
        WhatIfState(
          goalId: 'g1',
          status: WhatIfStatus.ready,
          detail: detail,
          monthlyInput: '6000',
        ),
        WhatIfState(
          goalId: 'g1',
          status: WhatIfStatus.ready,
          detail: detail,
          monthlyInput: '6000',
          isCalculating: true,
        ),
        WhatIfState(
          goalId: 'g1',
          status: WhatIfStatus.ready,
          detail: detail,
          monthlyInput: '6000',
          result: WhatIfResult(
            hypotheticalMonthlyContributionMinorUnits: 600000,
            hypotheticalTargetDate: DateTime(2027, 8, 15),
            estimatedMonths: 11,
          ),
          resultMode: WhatIfMode.monthlyContribution,
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.detail!.goal.monthlyContributionMinorUnits, 500000);
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
      },
    );

    blocTest<WhatIfCubit, WhatIfState>(
      'an achieved goal opens on the "nothing left to plan" state (FR-016)',
      setUp: () => when(
        () => repository.getGoalDetail('g1'),
      ).thenAnswer((_) async => Right(achieved)),
      build: () => cubitOver(repository),
      act: (cubit) => cubit.load('g1'),
      expect: () => [
        const WhatIfState(goalId: 'g1'),
        WhatIfState(
          goalId: 'g1',
          status: WhatIfStatus.achieved,
          detail: achieved,
        ),
      ],
    );

    blocTest<WhatIfCubit, WhatIfState>(
      'a goal that fails to load is a failure state',
      setUp: () => when(
        () => repository.getGoalDetail('g1'),
      ).thenAnswer((_) async => const Left(GoalNotFoundFailure('gone'))),
      build: () => cubitOver(repository),
      act: (cubit) => cubit.load('g1'),
      expect: () => [
        const WhatIfState(goalId: 'g1'),
        const WhatIfState(
          goalId: 'g1',
          status: WhatIfStatus.failure,
          failure: GoalNotFoundFailure('gone'),
        ),
      ],
    );
  });

  group('through the real repository', () {
    late SavingsHarness h;
    late WhatIfCubit cubit;

    setUp(() async {
      h = await SavingsHarness.open();
      final getDetail = GetGoalDetail(h.repository);
      const calculator = DefaultSavingsCalculator();
      cubit = WhatIfCubit(
        getDetail,
        CalculateWhatIfMonthlyContribution(getDetail, calculator, h.clock),
        CalculateWhatIfCompletionDate(getDetail, calculator, h.clock),
        ApplyWhatIfScenario(getDetail, EditSavingsGoal(h.repository)),
      );
    });

    tearDown(() async {
      await cubit.close();
      await h.close();
    });

    test('explore then apply: the goal takes the scenario values', () async {
      final goal = await h.createGoal(
        target: 10000000,
        starting: 3500000,
        monthly: 500000,
      );
      await cubit.load(goal.id);

      cubit.modeChanged(WhatIfMode.targetDate);
      cubit.targetDateChanged(DateTime(2027, 7, 15));
      await cubit.calculate();
      expect(
        cubit.state.result!.hypotheticalMonthlyContributionMinorUnits,
        650000,
      );
      expect((await h.detail(goal.id)).goal, goal);

      await cubit.apply();

      expect(cubit.state.applyStatus, WhatIfApplyStatus.applied);
      final applied = (await h.detail(goal.id)).goal;
      expect(applied.monthlyContributionMinorUnits, 650000);
      expect(applied.targetDate, DateTime(2027, 7, 15));
    });

    test('explore then cancel: re-fetching shows the goal unchanged', () async {
      final goal = await h.createGoal(
        target: 10000000,
        starting: 3500000,
        monthly: 500000,
      );
      await cubit.load(goal.id);
      cubit.monthlyChanged('6000');
      await cubit.calculate();
      cubit.modeChanged(WhatIfMode.targetDate);
      cubit.targetDateChanged(DateTime(2027, 7, 15));
      await cubit.calculate();
      expect(cubit.state.result, isNotNull);

      // Cancel: the page is closed without applying.
      await cubit.close();

      final after = await h.detail(goal.id);
      expect(after.goal, goal);
      expect(after.progress.estimatedCompletion!.estimatedMonths, 13);
    });

    test('invalid inputs are flagged, not calculated (FR-016)', () async {
      final goal = await h.createGoal(target: 10000000, monthly: 500000);
      await cubit.load(goal.id);

      for (final input in ['', '0', '-5', 'abc']) {
        cubit.monthlyChanged(input);
        await cubit.calculate();
        expect(cubit.state.monthlyInvalid, isTrue, reason: input);
        expect(cubit.state.result, isNull);
      }

      cubit.modeChanged(WhatIfMode.targetDate);
      await cubit.calculate();
      expect(cubit.state.targetDateInvalid, isTrue);

      cubit.targetDateChanged(h.today);
      expect(cubit.state.targetDateInvalid, isFalse);
      await cubit.calculate();
      expect(cubit.state.targetDateInvalid, isTrue);
      expect(cubit.state.result, isNull);
    });

    test('changing the input or the mode clears a stale result', () async {
      final goal = await h.createGoal(target: 10000000, monthly: 500000);
      await cubit.load(goal.id);
      cubit.monthlyChanged('6000');
      await cubit.calculate();
      expect(cubit.state.result, isNotNull);

      cubit.monthlyChanged('7000');
      expect(cubit.state.result, isNull);

      await cubit.calculate();
      cubit.modeChanged(WhatIfMode.targetDate);
      expect(cubit.state.result, isNull);
    });

    test(
      'a goal achieved since opening switches to the achieved state',
      () async {
        final goal = await h.createGoal(target: 1000000, monthly: 100000);
        await cubit.load(goal.id);
        await h.contribute(goal.id, 1000000);

        cubit.monthlyChanged('500');
        await cubit.calculate();

        expect(cubit.state.status, WhatIfStatus.achieved);
        expect(cubit.state.result, isNull);
      },
    );
  });
}
