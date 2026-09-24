import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// Mirrors 011's `EstimatedCompletion` (specs/011-savings-goals/
/// data-model.md).
class SavingsEstimatedCompletionSnapshot extends Equatable {
  const SavingsEstimatedCompletionSnapshot({
    required this.hasShortfall,
    this.estimatedMonths,
    this.estimatedDate,
    this.shortfallMonths,
  });

  /// Present only when the goal has a monthly contribution.
  final int? estimatedMonths;

  /// Present only when [estimatedMonths] is.
  final DateTime? estimatedDate;

  /// `true` when both a monthly contribution and a target date are set and
  /// [estimatedDate] falls after the target date (011 FR-012).
  final bool hasShortfall;

  /// Whole months between [estimatedDate] and the target date, when
  /// [hasShortfall].
  final int? shortfallMonths;

  @override
  List<Object?> get props => [
    estimatedMonths,
    estimatedDate,
    hasShortfall,
    shortfallMonths,
  ];
}

/// A read-only view of one active savings goal, shaped after 011's
/// `SavingsGoal` + `GoalProgress` + `EstimatedCompletion`. Every figure is
/// 011's own — nothing here is recomputed by this feature (research.md
/// Decision 2).
class SavingsGoalSnapshot extends Equatable {
  const SavingsGoalSnapshot({
    required this.goalId,
    required this.name,
    required this.targetAmountMinorUnits,
    required this.currentAmountMinorUnits,
    required this.isAchieved,
    required this.createdAt,
    this.monthlyContributionMinorUnits,
    this.targetDate,
    this.estimatedCompletion,
  });

  final String goalId;
  final String name;
  final int targetAmountMinorUnits;
  final int currentAmountMinorUnits;
  final bool isAchieved;
  final int? monthlyContributionMinorUnits;
  final DateTime? targetDate;
  final DateTime createdAt;

  /// `null` when the goal has neither a monthly contribution nor a target
  /// date, or is already achieved (011 data-model.md).
  final SavingsEstimatedCompletionSnapshot? estimatedCompletion;

  @override
  List<Object?> get props => [
    goalId,
    name,
    targetAmountMinorUnits,
    currentAmountMinorUnits,
    isAchieved,
    monthlyContributionMinorUnits,
    targetDate,
    createdAt,
    estimatedCompletion,
  ];
}

/// Read-only port onto 011 Savings Goals' published repository contract
/// (specs/011-savings-goals/contracts/savings_repository.md).
///
/// Declared here rather than importing 011 because 011 is specified but not
/// yet implemented in code; once it ships, an adapter over its
/// `SavingsRepository` replaces `UnavailableSavingsInsightsSource` and
/// nothing in this feature's Domain layer changes.
abstract class SavingsInsightsSource {
  /// Every active (non-archived, non-deleted) goal.
  Future<Either<Failure, List<SavingsGoalSnapshot>>> activeGoals();

  /// Whether [goalId] still exists — the stale-deep-link check (FR-014).
  Future<bool> goalExists(String goalId);
}
