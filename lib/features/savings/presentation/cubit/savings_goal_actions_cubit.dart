import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/savings_failures.dart';
import '../../domain/usecases/archive_savings_goal.dart';
import '../../domain/usecases/delete_savings_goal.dart';
import '../../domain/usecases/restore_savings_goal.dart';
import 'savings_goal_actions_state.dart';

/// Archive, restore and delete for any goal (FR-020/FR-021) — one place,
/// shared by the overview, the archived list and the goal page, so the
/// three can never treat a goal differently.
///
/// It patches no list: every page showing goals is a live subscription,
/// so the change arrives through the same re-read as any other. A second
/// action on a goal whose first is still in flight is ignored.
@injectable
class SavingsGoalActionsCubit extends Cubit<SavingsGoalActionsState> {
  SavingsGoalActionsCubit(this._archive, this._restore, this._delete)
    : super(const SavingsGoalActionsState());

  final ArchiveSavingsGoal _archive;
  final RestoreSavingsGoal _restore;
  final DeleteSavingsGoal _delete;

  Future<GoalActionResult> archive(String goalId) =>
      _run(goalId, () => _archive(goalId));

  Future<GoalActionResult> restore(String goalId) =>
      _run(goalId, () => _restore(goalId));

  /// FR-021: a goal with history comes back as
  /// [GoalActionStatus.hasHistory] — the caller offers [archive].
  Future<GoalActionResult> delete(String goalId) =>
      _run(goalId, () => _delete(goalId));

  Future<GoalActionResult> _run(
    String goalId,
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    if (state.isProcessing(goalId)) {
      return const GoalActionResult(GoalActionStatus.ignored);
    }
    emit(
      SavingsGoalActionsState(
        processingGoalIds: {...state.processingGoalIds, goalId},
      ),
    );
    final result = await action();
    if (!isClosed) {
      emit(
        SavingsGoalActionsState(
          processingGoalIds: {...state.processingGoalIds}..remove(goalId),
        ),
      );
    }
    return result.match(
      (failure) => failure is GoalHasHistoryFailure
          ? GoalActionResult(GoalActionStatus.hasHistory, failure)
          : GoalActionResult(GoalActionStatus.failed, failure),
      (_) => const GoalActionResult(GoalActionStatus.done),
    );
  }
}
