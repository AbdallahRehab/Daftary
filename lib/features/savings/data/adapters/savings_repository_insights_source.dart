import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../insights_notifications/domain/ports/savings_insights_source.dart';
import '../../domain/entities/goal_progress.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_repository.dart';

/// 017's [SavingsInsightsSource] over this feature's [SavingsRepository]
/// (FR-031, research.md Decision 13) — the adapter that port was declared
/// for. Read-only, and a pure copy: every figure is the repository's own
/// `GoalProgress`/`EstimatedCompletion`, never recomputed here.
@LazySingleton(as: SavingsInsightsSource)
class SavingsRepositoryInsightsSource implements SavingsInsightsSource {
  const SavingsRepositoryInsightsSource(this._repository);

  final SavingsRepository _repository;

  /// The overview's active lines — non-archived, non-deleted — each in the
  /// goal's own currency. A line blocked only on a primary-currency rate
  /// still carries its own-currency progress, so it is included: check-ins
  /// never depend on the combined total.
  @override
  Future<Either<Failure, List<SavingsGoalSnapshot>>> activeGoals() async {
    try {
      final result = await _repository.getSavingsOverview();
      return result.map(
        (overview) => [
          for (final line in overview.goals)
            if (!line.goal.isArchived && !line.goal.isDeleted)
              _snapshot(line.goal, line.progress),
        ],
      );
    } catch (e) {
      return Left(UnknownFailure('Failed to read savings goals: $e'));
    }
  }

  /// A goal "exists" for a deep link while it is not deleted — an archived
  /// goal still opens its detail page (FR-020), so it counts.
  @override
  Future<bool> goalExists(String goalId) async {
    try {
      final result = await _repository.getGoalDetail(goalId);
      return result.isRight();
    } catch (_) {
      return false;
    }
  }

  static SavingsGoalSnapshot _snapshot(
    SavingsGoal goal,
    GoalProgress progress,
  ) {
    final estimate = progress.estimatedCompletion;
    return SavingsGoalSnapshot(
      goalId: goal.id,
      name: goal.name,
      targetAmountMinorUnits: progress.targetAmountMinorUnits,
      currentAmountMinorUnits: progress.currentAmountMinorUnits,
      isAchieved: progress.isAchieved,
      monthlyContributionMinorUnits: goal.monthlyContributionMinorUnits,
      targetDate: goal.targetDate,
      createdAt: goal.createdAt,
      estimatedCompletion: estimate == null
          ? null
          : SavingsEstimatedCompletionSnapshot(
              hasShortfall: estimate.hasShortfall,
              estimatedMonths: estimate.estimatedMonths,
              estimatedDate: estimate.estimatedDate,
              shortfallMonths: estimate.shortfallMonths,
            ),
    );
  }
}
