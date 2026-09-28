import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/restore_occasion.dart';
import '../../domain/usecases/watch_occasions_list.dart';
import 'archived_occasions_state.dart';

/// Lists archived occasions and restores one back into the active list
/// (FR-014), mirroring `ArchivedPeopleCubit`.
///
/// 021: the list is a live [WatchOccasionsList] subscription, cancelled in
/// [close], so an archive or restore made anywhere — or applied by sync —
/// shows here with no reload (FR-031).
@injectable
class ArchivedOccasionsCubit extends Cubit<ArchivedOccasionsState> {
  ArchivedOccasionsCubit(this._watchOccasionsList, this._restoreOccasion)
    : super(const ArchivedOccasionsState());

  final WatchOccasionsList _watchOccasionsList;
  final RestoreOccasion _restoreOccasion;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to the archived list, replacing any earlier subscription.
  /// The returned future completes once the first result has been emitted.
  Future<void> subscribe() {
    _cancelSubscription();
    emit(state.copyWith(status: ArchivedOccasionsStatus.loading));

    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchOccasionsList(includeArchived: true).listen((result) {
      if (isClosed) return;
      result.match(
        (failure) => emit(
          state.copyWith(
            status: ArchivedOccasionsStatus.failure,
            failure: failure,
          ),
        ),
        (occasions) => emit(
          state.copyWith(
            status: ArchivedOccasionsStatus.success,
            // `includeArchived` widens the query to both; this screen shows
            // only the archived half.
            occasions: occasions.where((o) => o.isArchived).toList(),
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

  /// Restores [occasionId]; it leaves this list at once, and the live
  /// subscription confirms it (FR-014). Re-entrant taps for the same
  /// occasion are ignored while one restore is already in flight.
  Future<bool> restore(String occasionId) async {
    if (state.processingOccasionId == occasionId) return false;
    emit(state.copyWith(processingOccasionId: occasionId));

    final result = await _restoreOccasion(occasionId);
    if (isClosed) return false;

    return result.match(
      (failure) {
        emit(state.copyWith(failure: failure, clearProcessingOccasionId: true));
        return false;
      },
      (_) {
        emit(
          state.copyWith(
            occasions: [
              for (final occasion in state.occasions)
                if (occasion.id != occasionId) occasion,
            ],
            clearProcessingOccasionId: true,
          ),
        );
        return true;
      },
    );
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
