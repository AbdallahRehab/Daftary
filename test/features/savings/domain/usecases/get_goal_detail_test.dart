import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/domain/usecases/watch_goal_detail.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/savings_harness.dart';

/// T033 — `GetGoalDetail`'s `GoalProgress`/`isAchieved` derivation and
/// history ordering, through the real repository.
void main() {
  late SavingsHarness h;
  late GetGoalDetail getDetail;

  setUp(() async {
    h = await SavingsHarness.open();
    getDetail = GetGoalDetail(h.repository);
  });

  tearDown(() => h.close());

  test('FR-017: achieved exactly when current reaches the target, with '
      'nothing left to estimate', () async {
    final goal = await h.createGoal(target: 10000, monthly: 1000);
    await h.contribute(goal.id, 9999);
    var progress = (await getDetail(goal.id)).toNullable()!.progress;
    expect(progress.isAchieved, isFalse);
    expect(progress.estimatedCompletion!.estimatedMonths, 1);

    await h.contribute(goal.id, 1);
    progress = (await getDetail(goal.id)).toNullable()!.progress;
    expect(progress.isAchieved, isTrue);
    expect(progress.percentageProgress, 100);
    expect(progress.remainingMinorUnits, 0);
    expect(progress.estimatedCompletion, isNull);
  });

  test('FR-018: a withdrawal, an edit or a delete that brings current '
      'below target un-achieves the goal automatically', () async {
    final goal = await h.createGoal(target: 10000);
    final c = await h.contribute(goal.id, 10000);
    expect((await h.detail(goal.id)).progress.isAchieved, isTrue);

    final w = await h.withdraw(goal.id, 1);
    expect((await h.detail(goal.id)).progress.isAchieved, isFalse);

    await h.repository.deleteContribution(w.id);
    expect((await h.detail(goal.id)).progress.isAchieved, isTrue);

    await h.repository.editContribution(
      contributionId: c.id,
      amount: Money.egp(9999),
      date: h.today,
    );
    expect((await h.detail(goal.id)).progress.isAchieved, isFalse);
  });

  test(
    'FR-008: history is ordered by entry date, then creation time',
    () async {
      final goal = await h.createGoal(target: 1000000);
      h.clock.current = DateTime(2026, 9, 15, 9);
      final late1 = await h.contribute(goal.id, 1, date: DateTime(2026, 9, 10));
      h.clock.current = DateTime(2026, 9, 15, 10);
      final early = await h.contribute(goal.id, 2, date: DateTime(2026, 8, 1));
      h.clock.current = DateTime(2026, 9, 15, 11);
      final late2 = await h.contribute(goal.id, 3, date: DateTime(2026, 9, 10));
      h.clock.current = DateTime(2026, 9, 15, 12);
      final latest = await h.contribute(
        goal.id,
        4,
        date: DateTime(2026, 9, 12),
      );

      final history = (await getDetail(goal.id)).toNullable()!.history;
      expect(history.map((e) => e.id), [
        early.id,
        late1.id,
        late2.id,
        latest.id,
      ]);
    },
  );

  test('FR-012: a contribution too low for the target date reports the '
      'shortfall in whole months', () async {
    final goal = await h.createGoal(
      target: 1000000,
      monthly: 50000,
      // 10 whole months away; 1,000,000 / 50,000 = 20 months.
      targetDate: DateTime(2027, 7, 15),
    );

    final estimate = (await getDetail(
      goal.id,
    )).toNullable()!.progress.estimatedCompletion!;
    expect(estimate.estimatedMonths, 20);
    expect(estimate.requiredMonthlyContributionMinorUnits, 100000);
    expect(estimate.hasShortfall, isTrue);
    expect(estimate.shortfallMonths, 10);
  });

  test('a deleted or unknown goal is GoalNotFoundFailure', () async {
    final result = await getDetail('missing');
    expect(result.getLeft().toNullable(), isA<GoalNotFoundFailure>());
  });

  test('WatchGoalDetail re-emits after a write', () async {
    final goal = await h.createGoal(target: 10000);
    final emissions = <int>[];
    final sub = WatchGoalDetail(h.repository)(goal.id).listen(
      (r) => emissions.add(r.toNullable()!.progress.currentAmountMinorUnits),
    );
    await pumpUntil(() => emissions.isNotEmpty);

    await h.contribute(goal.id, 700);
    await pumpUntil(() => emissions.length >= 2);
    await sub.cancel();

    expect(emissions, [0, 700]);
  });
}

Future<void> pumpUntil(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
