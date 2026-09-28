import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/occasion_filter.dart';
import '../../domain/usecases/get_occasions_list.dart';
import 'occasions_list_state.dart';

/// Drives the occasions list: reverse-chronological by default, narrowed by
/// a name search and type/date-range filters (FR-015).
///
/// Filtering is delegated to the query rather than applied to a cached list
/// in memory, so the ~2,000-occasion ceiling never has to be held in the
/// widget tree at once.
@injectable
class OccasionsListCubit extends Cubit<OccasionsListState> {
  OccasionsListCubit(this._getOccasionsList)
    : super(const OccasionsListState());

  final GetOccasionsList _getOccasionsList;

  Future<void> load() async {
    emit(state.copyWith(status: OccasionsListStatus.loading));

    // Two reads rather than one: the unfiltered read is what lets the page
    // distinguish "you have no occasions yet" from "none match this
    // search" (FR-020). It is skipped entirely when no filter is active,
    // because then the filtered read already answers both questions.
    final result = await _getOccasionsList(
      filter: state.filter.isEmpty ? null : state.filter,
    );
    if (isClosed) return;

    await result.match(
      (failure) async => emit(
        state.copyWith(status: OccasionsListStatus.failure, failure: failure),
      ),
      (occasions) async {
        var hasAny = occasions.isNotEmpty;
        if (!hasAny && !state.filter.isEmpty) {
          final unfiltered = await _getOccasionsList();
          if (isClosed) return;
          hasAny = unfiltered.getOrElse((_) => const []).isNotEmpty;
        }
        emit(
          state.copyWith(
            status: OccasionsListStatus.success,
            occasions: occasions,
            hasAnyOccasion: hasAny,
            clearFailure: true,
          ),
        );
      },
    );
  }

  Future<void> searchChanged(String query) {
    emit(
      state.copyWith(
        filter: query.trim().isEmpty
            ? state.filter.copyWith(clearNameQuery: true)
            : state.filter.copyWith(nameQuery: query),
      ),
    );
    return load();
  }

  Future<void> typeChanged(String? type) {
    emit(
      state.copyWith(
        filter: type == null
            ? state.filter.copyWith(clearType: true)
            : state.filter.copyWith(type: type),
      ),
    );
    return load();
  }

  Future<void> dateRangeChanged({DateTime? from, DateTime? to}) {
    emit(
      state.copyWith(
        filter: state.filter.copyWith(
          fromDate: from,
          toDate: to,
          clearFromDate: from == null,
          clearToDate: to == null,
        ),
      ),
    );
    return load();
  }

  Future<void> clearFilters() {
    emit(state.copyWith(filter: const OccasionFilter()));
    return load();
  }
}
