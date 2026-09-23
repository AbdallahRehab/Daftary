import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_occasions_list.dart';
import '../../domain/usecases/restore_occasion.dart';
import 'archived_occasions_state.dart';

/// Lists archived occasions and restores one back into the active list
/// (FR-014), mirroring `ArchivedPeopleCubit`.
@injectable
class ArchivedOccasionsCubit extends Cubit<ArchivedOccasionsState> {
  ArchivedOccasionsCubit(this._getOccasionsList, this._restoreOccasion)
    : super(const ArchivedOccasionsState());

  final GetOccasionsList _getOccasionsList;
  final RestoreOccasion _restoreOccasion;

  Future<void> load() async {
    emit(state.copyWith(status: ArchivedOccasionsStatus.loading));

    final result = await _getOccasionsList(includeArchived: true);
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
  }

  /// Restores [occasionId] and refreshes the list so it disappears from
  /// here immediately (FR-014). Re-entrant taps for the same occasion are
  /// ignored while one restore is already in flight.
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
        load().then((_) {
          if (!isClosed) {
            emit(state.copyWith(clearProcessingOccasionId: true));
          }
        });
        return true;
      },
    );
  }
}
