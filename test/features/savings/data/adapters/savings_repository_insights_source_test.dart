import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/insights_notifications/domain/ports/savings_insights_source.dart';
import 'package:daftary/features/savings/data/adapters/savings_repository_insights_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/savings_harness.dart';
import '../../helpers/savings_test_data.dart';

/// T067 (011 FR-031): 017's savings port over the real repository. Every
/// figure on a snapshot must be exactly the repository's own — nothing is
/// recomputed by the adapter.
void main() {
  group('over the real repository', () {
    late SavingsHarness h;
    late SavingsRepositoryInsightsSource source;

    setUp(() async {
      h = await SavingsHarness.open();
      source = SavingsRepositoryInsightsSource(h.repository);
    });

    tearDown(() => h.close());

    Future<List<SavingsGoalSnapshot>> activeGoals() async =>
        (await source.activeGoals()).getOrElse(
          (f) => throw StateError(f.message),
        );

    test('no goals → an empty list', () async {
      expect(await activeGoals(), isEmpty);
    });

    test('maps each active goal from its own GoalProgress and '
        'EstimatedCompletion, including a shortfall', () async {
      // 100,000.00 target, 10,000.00 saved, 1,000.00/month → 90 months,
      // far past a target date one year out: a shortfall.
      final goal = await h.createGoal(
        name: 'House',
        target: 10000000,
        starting: 1000000,
        monthly: 100000,
        targetDate: DateTime(2027, 9, 15),
      );
      final detail = await h.detail(goal.id);
      final estimate = detail.progress.estimatedCompletion!;
      expect(estimate.hasShortfall, isTrue, reason: 'fixture sanity');

      final snapshots = await activeGoals();

      expect(snapshots, [
        SavingsGoalSnapshot(
          goalId: goal.id,
          name: 'House',
          targetAmountMinorUnits: 10000000,
          currentAmountMinorUnits: detail.progress.currentAmountMinorUnits,
          isAchieved: false,
          monthlyContributionMinorUnits: 100000,
          targetDate: goal.targetDate,
          createdAt: goal.createdAt,
          estimatedCompletion: SavingsEstimatedCompletionSnapshot(
            hasShortfall: true,
            estimatedMonths: estimate.estimatedMonths,
            estimatedDate: estimate.estimatedDate,
            shortfallMonths: estimate.shortfallMonths,
          ),
        ),
      ]);
      expect(snapshots.single.currentAmountMinorUnits, 1000000);
    });

    test('an achieved goal is reported achieved with no estimate', () async {
      final goal = await h.createGoal(target: 500000, monthly: 10000);
      await h.contribute(goal.id, 600000);

      final snapshot = (await activeGoals()).single;

      expect(snapshot.isAchieved, isTrue);
      expect(snapshot.currentAmountMinorUnits, 600000);
      expect(snapshot.estimatedCompletion, isNull);
    });

    test('archived goals are left out', () async {
      final kept = await h.createGoal(name: 'Car');
      final archived = await h.createGoal(name: 'Trip');
      await h.archiveDirectly(archived.id);

      final ids = [for (final s in await activeGoals()) s.goalId];

      expect(ids, [kept.id]);
    });

    test('goalExists: true for an existing (even archived) goal, false for '
        'an unknown id', () async {
      final goal = await h.createGoal();
      expect(await source.goalExists(goal.id), isTrue);

      await h.archiveDirectly(goal.id);
      expect(await source.goalExists(goal.id), isTrue);

      expect(await source.goalExists('missing'), isFalse);
    });
  });

  group('failure handling', () {
    late MockSavingsRepository repository;
    late SavingsRepositoryInsightsSource source;

    setUp(() {
      repository = MockSavingsRepository();
      source = SavingsRepositoryInsightsSource(repository);
    });

    test('a repository failure is passed through unchanged', () async {
      when(
        () => repository.getSavingsOverview(),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));

      final result = await source.activeGoals();
      expect(result.getLeft().toNullable(), const CacheFailure('db'));
    });

    test('a thrown error becomes a Left, never escapes', () async {
      when(() => repository.getSavingsOverview()).thenThrow(StateError('x'));
      when(() => repository.getGoalDetail(any())).thenThrow(StateError('x'));

      expect((await source.activeGoals()).isLeft(), isTrue);
      expect(await source.goalExists('g1'), isFalse);
    });

    test('goalExists is false when the repository reports a failure', () async {
      when(
        () => repository.getGoalDetail('g1'),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));

      expect(await source.goalExists('g1'), isFalse);
    });
  });
}
