import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/savings_overview.dart';

enum ArchivedGoalsStatus { loading, success, failure }

/// Immutable state for `ArchivedGoalsCubit`, mirroring
/// `ArchivedOccasionsState`.
class ArchivedGoalsState extends Equatable {
  const ArchivedGoalsState({
    this.status = ArchivedGoalsStatus.loading,
    this.goals = const [],
    this.failure,
  });

  final ArchivedGoalsStatus status;

  /// Only the archived goals, each with its progress in its own currency.
  final List<GoalOverviewLine> goals;
  final Failure? failure;

  bool get isLoading => status == ArchivedGoalsStatus.loading;
  bool get isEmpty => status == ArchivedGoalsStatus.success && goals.isEmpty;

  ArchivedGoalsState copyWith({
    ArchivedGoalsStatus? status,
    List<GoalOverviewLine>? goals,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ArchivedGoalsState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, goals, failure];
}
