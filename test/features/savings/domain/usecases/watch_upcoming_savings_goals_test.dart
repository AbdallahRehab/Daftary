import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/goal_progress.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/features/savings/domain/usecases/watch_upcoming_savings_goals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/savings_test_data.dart';

/// T069 (011 FR-031 / 012 FR-010): what Home's Upcoming section lists.
void main() {
  GoalOverviewLine line(
    String id, {
    DateTime? targetDate,
    int current = 0,
    bool isArchived = false,
    DateTime? createdAt,
  }) {
    final goal = SavingsGoal(
      id: id,
      idempotencyKey: 'k-$id',
      name: id,
      currency: Currency.egp,
      targetAmountMinorUnits: 100000,
      targetDate: targetDate,
      isArchived: isArchived,
      createdAt: createdAt ?? testToday,
      updatedAt: testToday,
    );
    return GoalOverviewLine(
      goal: goal,
      progress: GoalProgress(
        goalId: id,
        currency: Currency.egp,
        targetAmountMinorUnits: 100000,
        currentAmountMinorUnits: current,
      ),
      primaryCurrencyAmountMinorUnits: current,
    );
  }

  SavingsOverview overview(List<GoalOverviewLine> goals) =>
      SavingsOverview(goals: goals, primaryCurrency: Currency.egp);

  test('keeps only active, not-achieved goals with a target date, soonest '
      'first', () {
    final result = WatchUpcomingSavingsGoals.upcoming(
      overview([
        line('late', targetDate: DateTime(2028)),
        line('no-date'),
        line('achieved', targetDate: DateTime(2027), current: 100000),
        line('archived', targetDate: DateTime(2027), isArchived: true),
        line('soon', targetDate: DateTime(2027, 2)),
      ]),
    );

    expect([for (final l in result) l.goal.id], ['soon', 'late']);
  });

  test('caps the list, ties broken by creation order', () {
    final date = DateTime(2027);
    final result = WatchUpcomingSavingsGoals.upcoming(
      overview([
        for (var i = 5; i >= 1; i--)
          line('g$i', targetDate: date, createdAt: DateTime(2026, 1, i)),
      ]),
    );

    expect([for (final l in result) l.goal.id], ['g1', 'g2', 'g3']);
  });

  test('streams the live overview through the rule; a failure passes '
      'through', () async {
    final repository = MockSavingsRepository();
    final controller =
        StreamController<Either<Failure, SavingsOverview>>.broadcast();
    addTearDown(controller.close);
    when(
      () => repository.watchSavingsOverview(),
    ).thenAnswer((_) => controller.stream);

    final emitted = <Either<Failure, List<GoalOverviewLine>>>[];
    final sub = WatchUpcomingSavingsGoals(repository)().listen(emitted.add);
    addTearDown(sub.cancel);

    controller
      ..add(Right(overview([line('a', targetDate: DateTime(2027))])))
      ..add(const Left(CacheFailure('db')));
    await Future<void>.delayed(Duration.zero);

    expect(emitted.first.getOrElse((_) => const []).single.goal.id, 'a');
    expect(emitted.last.getLeft().toNullable(), const CacheFailure('db'));
  });
}
