import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/savings_goal_detail.dart';

enum GoalDetailStatus { loading, success, failure }

/// Immutable state for `GoalDetailCubit` (constitution Principle IV).
class GoalDetailState extends Equatable {
  const GoalDetailState({
    required this.goalId,
    this.status = GoalDetailStatus.loading,
    this.detail,
    this.failure,
    this.isDeleted = false,
    this.deletingEntryIds = const {},
  });

  final String goalId;
  final GoalDetailStatus status;

  /// The goal, its progress and its history, loaded together so the card
  /// and the list beneath it can never disagree.
  final SavingsGoalDetail? detail;

  /// A load failure (with no [detail]) or a failed action (with one).
  final Failure? failure;

  /// Set once the goal is gone (deleted here or applied by sync), so the
  /// page can close rather than show an error.
  final bool isDeleted;

  /// Entries whose delete is in flight — a second tap on the same one is
  /// ignored (duplicate-action protection).
  final Set<String> deletingEntryIds;

  bool get isLoading => status == GoalDetailStatus.loading;

  /// Loaded, with no entries yet — the history's empty state.
  bool get isEmpty =>
      status == GoalDetailStatus.success && (detail?.history.isEmpty ?? true);

  bool get isArchived => detail?.goal.isArchived ?? false;

  GoalDetailState copyWith({
    GoalDetailStatus? status,
    SavingsGoalDetail? detail,
    Failure? failure,
    bool clearFailure = false,
    bool? isDeleted,
    Set<String>? deletingEntryIds,
  }) {
    return GoalDetailState(
      goalId: goalId,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      failure: clearFailure ? null : (failure ?? this.failure),
      isDeleted: isDeleted ?? this.isDeleted,
      deletingEntryIds: deletingEntryIds ?? this.deletingEntryIds,
    );
  }

  @override
  List<Object?> get props => [
    goalId,
    status,
    detail,
    failure,
    isDeleted,
    deletingEntryIds,
  ];
}
