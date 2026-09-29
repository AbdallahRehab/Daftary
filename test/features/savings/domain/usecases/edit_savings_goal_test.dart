import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_type.dart';
import 'package:daftary/features/savings/domain/usecases/edit_savings_goal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/savings_harness.dart';

/// T018 — `EditSavingsGoal` (FR-029), through the real repository.
void main() {
  late SavingsHarness h;
  late EditSavingsGoal edit;

  setUp(() async {
    h = await SavingsHarness.open();
    edit = EditSavingsGoal(h.repository);
  });

  tearDown(() => h.close());

  test('edits name, type, target, monthly contribution and target date; '
      'derived figures recompute; history is untouched', () async {
    final goal = await h.createGoal(
      target: 10000000,
      starting: 3500000,
      monthly: 500000,
    );
    final historyBefore = (await h.detail(goal.id)).history;

    final result = await edit(
      goalId: goal.id,
      name: 'Rainy day',
      type: SavingsGoalType.other,
      targetAmountMinorUnits: 5000000,
      monthlyContributionMinorUnits: 1000000,
      targetDate: DateTime(2027, 9, 1),
    );

    final edited = result.toNullable()!;
    expect(edited.name, 'Rainy day');
    expect(edited.type, SavingsGoalType.other);
    expect(edited.targetAmountMinorUnits, 5000000);
    expect(edited.monthlyContributionMinorUnits, 1000000);
    expect(edited.targetDate, DateTime(2027, 9, 1));
    expect(edited.updatedAt, h.clock.current);

    final detail = await h.detail(goal.id);
    expect(detail.history, historyBefore);
    // 50,000 − 35,000 = 15,000 remaining at 10,000/month → 2 months.
    expect(detail.progress.remainingMinorUnits, 1500000);
    expect(detail.progress.estimatedCompletion!.estimatedMonths, 2);
  });

  test('the currency cannot change (FR-027): the edit has no currency, and '
      'the stored one is kept', () async {
    final goal = await h.createGoal(currency: Currency.usd, target: 100);

    final edited = (await edit(
      goalId: goal.id,
      name: goal.name,
      targetAmountMinorUnits: 200,
    )).toNullable()!;

    expect(edited.currency, Currency.usd);
    expect((await h.goalRows()).single.currencyCode, 'USD');
  });

  test('clearing the plan removes the estimate (US1 AS-6)', () async {
    final goal = await h.createGoal(monthly: 100, target: 1000);

    await edit(goalId: goal.id, name: 'Goal', targetAmountMinorUnits: 1000);

    expect((await h.detail(goal.id)).progress.estimatedCompletion, isNull);
  });

  test('raising the target past an achieved goal un-achieves it; lowering '
      'it achieves it (FR-018)', () async {
    final goal = await h.createGoal(target: 1000, starting: 1000);
    expect((await h.detail(goal.id)).progress.isAchieved, isTrue);

    await edit(goalId: goal.id, name: 'Goal', targetAmountMinorUnits: 2000);
    expect((await h.detail(goal.id)).progress.isAchieved, isFalse);

    await edit(goalId: goal.id, name: 'Goal', targetAmountMinorUnits: 500);
    final progress = (await h.detail(goal.id)).progress;
    expect(progress.isAchieved, isTrue);
    expect(progress.remainingMinorUnits, 0);
  });

  group('same validation as create — nothing changes', () {
    test(
      'zero target, blank name, non-positive monthly contribution',
      () async {
        final goal = await h.createGoal(target: 1000);
        final attempts = [
          () => edit(goalId: goal.id, name: 'x', targetAmountMinorUnits: 0),
          () => edit(goalId: goal.id, name: ' ', targetAmountMinorUnits: 10),
          () => edit(
            goalId: goal.id,
            name: 'x',
            targetAmountMinorUnits: 10,
            monthlyContributionMinorUnits: 0,
          ),
        ];
        for (final attempt in attempts) {
          expect(
            (await attempt()).getLeft().toNullable(),
            isA<ValidationFailure>(),
          );
        }
        expect((await h.goalRows()).single.targetAmountMinorUnits, 1000);
      },
    );

    test('a newly set target date on or before today', () async {
      final goal = await h.createGoal(target: 1000);

      final result = await edit(
        goalId: goal.id,
        name: 'Goal',
        targetAmountMinorUnits: 1000,
        targetDate: h.today,
      );

      expect(result.getLeft().toNullable(), isA<InvalidTargetDateFailure>());
      expect((await h.goalRows()).single.targetDate, isNull);
    });
  });

  test(
    'an unchanged target date that has since passed does not block '
    'editing the rest of the goal (data-model.md: checked when set)',
    () async {
      final targetDate = DateTime(2026, 10, 1);
      final goal = await h.createGoal(target: 1000, targetDate: targetDate);
      h.clock.current = DateTime(2026, 11, 20);

      final result = await edit(
        goalId: goal.id,
        name: 'Renamed',
        targetAmountMinorUnits: 1000,
        targetDate: targetDate,
      );

      expect(result.toNullable()!.name, 'Renamed');
      expect(result.toNullable()!.targetDate, targetDate);
    },
  );

  test('an unknown goal is GoalNotFoundFailure', () async {
    final result = await edit(
      goalId: 'missing',
      name: 'x',
      targetAmountMinorUnits: 1,
    );

    expect(result.getLeft().toNullable(), isA<GoalNotFoundFailure>());
  });
}
