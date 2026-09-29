import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/savings_failures.dart';
import '../../domain/entities/savings_goal_detail.dart';
import '../../domain/usecases/delete_contribution.dart';
import '../../domain/usecases/watch_goal_detail.dart';
import 'goal_detail_state.dart';

/// Drives the goal page: its progress, its history, and deleting entries.
///
/// 021: the detail is a live [WatchGoalDetail] subscription, cancelled in
/// [close]. No action patches the in-memory detail: every figure is an
/// aggregate over the same rows, so a change made here, on the entry form,
/// or applied by sync reaches the page through the one re-read — which is
/// what makes FR-009's "recalculate immediately" exact.
@injectable
class GoalDetailCubit extends Cubit<GoalDetailState> {
  GoalDetailCubit(this._watchGoalDetail, this._deleteContribution)
    : super(const GoalDetailState(goalId: ''));

  final WatchGoalDetail _watchGoalDetail;
  final DeleteContribution _deleteContribution;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to [goalId], replacing any earlier subscription. Completes
  /// once the first result has been emitted.
  Future<void> subscribe(String goalId) {
    _cancelSubscription();
    emit(GoalDetailState(goalId: goalId));
    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchGoalDetail(goalId).listen(_onDetail);
    return firstResult.future;
  }

  /// Retry: subscribes again, from scratch, to the displayed goal.
  Future<void> resubscribe() => subscribe(state.goalId);

  void _onDetail(Either<Failure, SavingsGoalDetail> result) {
    if (isClosed || state.isDeleted) return;
    result.match(
      (failure) {
        // A goal that was on screen and now reads as "not found" was
        // deleted (here or on another device): the page closes, rather
        // than reporting an error.
        if (failure is GoalNotFoundFailure && state.detail != null) {
          _cancelSubscription();
          emit(state.copyWith(isDeleted: true));
          return;
        }
        emit(
          state.copyWith(status: GoalDetailStatus.failure, failure: failure),
        );
      },
      (detail) => emit(
        state.copyWith(
          status: GoalDetailStatus.success,
          detail: detail,
          clearFailure: true,
        ),
      ),
    );
    _completeFirstResult();
  }

  /// Deletes entry [contributionId] after the page has confirmed (FR-009).
  /// The live subscription recalculates the figures; a rejection (e.g. it
  /// would leave the balance negative) is surfaced as [GoalDetailState.failure].
  Future<bool> deleteEntry(String contributionId) async {
    if (state.deletingEntryIds.contains(contributionId)) return false;
    emit(
      state.copyWith(
        deletingEntryIds: {...state.deletingEntryIds, contributionId},
        clearFailure: true,
      ),
    );
    final result = await _deleteContribution(contributionId);
    if (isClosed) return false;
    final remaining = {...state.deletingEntryIds}..remove(contributionId);
    return result.match(
      (failure) {
        emit(state.copyWith(failure: failure, deletingEntryIds: remaining));
        return false;
      },
      (_) {
        emit(state.copyWith(deletingEntryIds: remaining));
        return true;
      },
    );
  }

  /// Clears a surfaced action failure once the page has shown it.
  void failureShown() {
    if (state.detail != null) emit(state.copyWith(clearFailure: true));
  }

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
