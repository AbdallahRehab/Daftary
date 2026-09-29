import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

/// How an archive, restore or delete request ended.
enum GoalActionStatus {
  /// Done; the live pages pick the change up on their own.
  done,

  /// FR-021: the goal has history, so it was not deleted — offer archiving.
  hasHistory,

  /// Refused or failed; [GoalActionResult.failure] says why.
  failed,

  /// The same action on the same goal was already in flight (a repeated
  /// tap), so nothing was sent.
  ignored,
}

class GoalActionResult extends Equatable {
  const GoalActionResult(this.status, [this.failure]);

  final GoalActionStatus status;
  final Failure? failure;

  @override
  List<Object?> get props => [status, failure];
}

/// Immutable state for `SavingsGoalActionsCubit`: the goals with an action
/// in flight, so their controls can be disabled.
class SavingsGoalActionsState extends Equatable {
  const SavingsGoalActionsState({this.processingGoalIds = const {}});

  final Set<String> processingGoalIds;

  bool isProcessing(String goalId) => processingGoalIds.contains(goalId);

  @override
  List<Object?> get props => [processingGoalIds];
}
