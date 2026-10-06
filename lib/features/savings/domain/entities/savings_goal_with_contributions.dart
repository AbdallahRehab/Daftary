import 'package:equatable/equatable.dart';

import 'savings_contribution.dart';
import 'savings_goal.dart';

/// One goal with all of its non-deleted contributions and withdrawals,
/// oldest first (022 D1). A plain pairing for the data export: it carries
/// no progress and does no conversion.
class SavingsGoalWithContributions extends Equatable {
  const SavingsGoalWithContributions({
    required this.goal,
    required this.contributions,
  });

  final SavingsGoal goal;
  final List<SavingsContribution> contributions;

  @override
  List<Object?> get props => [goal, contributions];
}
