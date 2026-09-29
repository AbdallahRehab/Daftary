import 'package:equatable/equatable.dart';

import 'goal_progress.dart';
import 'savings_contribution.dart';
import 'savings_goal.dart';

/// Everything the goal detail page shows (FR-008/FR-010-FR-012/FR-017):
/// the goal, its computed progress, and its non-deleted history.
class SavingsGoalDetail extends Equatable {
  const SavingsGoalDetail({
    required this.goal,
    required this.progress,
    required this.history,
  });

  final SavingsGoal goal;
  final GoalProgress progress;

  /// Non-deleted contributions and withdrawals, oldest first: by `date`,
  /// then `createdAt` (FR-008).
  final List<SavingsContribution> history;

  @override
  List<Object?> get props => [goal, progress, history];
}
