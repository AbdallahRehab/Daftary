import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/watch_savings_overview.dart';
import 'archived_goals_state.dart';

/// Lists archived goals (FR-020), mirroring `ArchivedOccasionsCubit`.
/// Restoring and deleting go through `SavingsGoalActionsCubit`.
///
/// 021: a live [WatchSavingsOverview] subscription (with archived goals),
/// so an archive or restore made anywhere — or applied by sync — shows
/// here with no reload.
@injectable
class ArchivedGoalsCubit extends Cubit<ArchivedGoalsState> {
  ArchivedGoalsCubit(this._watchSavingsOverview)
    : super(const ArchivedGoalsState());

  final WatchSavingsOverview _watchSavingsOverview;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to the archived goals, replacing any earlier subscription.
  /// Completes once the first result has been emitted.
  Future<void> subscribe() {
    _cancelSubscription();
    emit(state.copyWith(status: ArchivedGoalsStatus.loading));
    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchSavingsOverview(includeArchived: true).listen((
      result,
    ) {
      if (isClosed) return;
      result.match(
        (failure) => emit(
          state.copyWith(status: ArchivedGoalsStatus.failure, failure: failure),
        ),
        (overview) => emit(
          state.copyWith(
            status: ArchivedGoalsStatus.success,
            // `includeArchived` widens the read to both; this screen shows
            // only the archived half.
            goals: [
              for (final line in overview.goals)
                if (line.goal.isArchived) line,
            ],
            clearFailure: true,
          ),
        ),
      );
      _completeFirstResult();
    });
    return firstResult.future;
  }

  /// Retry: subscribes again from scratch.
  Future<void> resubscribe() => subscribe();

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
