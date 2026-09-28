import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/occasion.dart';
import '../../domain/entities/occasion_filter.dart';
import '../../domain/usecases/watch_occasions_list.dart';
import 'occasions_list_state.dart';

/// Drives the occasions list: reverse-chronological by default, narrowed by
/// a name search and type/date-range filters (FR-015).
///
/// Filtering is delegated to the query rather than applied to a cached list
/// in memory, so the ~2,000-occasion ceiling never has to be held in the
/// widget tree at once.
///
/// 021: the list is a live [WatchOccasionsList] subscription, so an
/// occasion created, edited, archived, restored or deleted on any screen —
/// or applied by sync — shows here with no reload (FR-031). Subscriptions
/// are cancelled in [close].
@injectable
class OccasionsListCubit extends Cubit<OccasionsListState> {
  OccasionsListCubit(this._watchOccasionsList)
    : super(const OccasionsListState());

  final WatchOccasionsList _watchOccasionsList;

  final _subscriptions = <StreamSubscription<void>>[];
  Completer<void>? _firstResult;

  /// The latest filtered read, and — only while a filter is active — the
  /// latest unfiltered one.
  Either<Failure, List<Occasion>>? _filtered;
  Either<Failure, List<Occasion>>? _unfiltered;

  /// Subscribes to the list for the current [OccasionsListState.filter],
  /// replacing any earlier subscription (a superseded one never emits
  /// again). The returned future completes once the first result has been
  /// emitted.
  Future<void> subscribe() {
    _cancelSubscriptions();
    _filtered = null;
    _unfiltered = null;
    emit(state.copyWith(status: OccasionsListStatus.loading));

    final firstResult = _firstResult = Completer<void>();
    final filter = state.filter.isEmpty ? null : state.filter;
    _subscriptions.add(
      _watchOccasionsList(
        filter: filter,
      ).listen((result) => _update(() => _filtered = result)),
    );
    // Two reads rather than one: the unfiltered read is what lets the page
    // distinguish "you have no occasions yet" from "none match this
    // search" (FR-020). It is skipped entirely when no filter is active,
    // because then the filtered read already answers both questions.
    if (filter != null) {
      _subscriptions.add(
        _watchOccasionsList().listen(
          (result) => _update(() => _unfiltered = result),
        ),
      );
    }
    return firstResult.future;
  }

  /// Retry and pull to refresh: subscribes again from scratch.
  Future<void> resubscribe() => subscribe();

  /// Records [change], then emits once every read the current filter needs
  /// has arrived.
  void _update(void Function() change) {
    if (isClosed) return;
    change();
    final filtered = _filtered;
    if (filtered == null) return;
    final filterActive = !state.filter.isEmpty;
    final unfiltered = _unfiltered;
    if (filterActive && unfiltered == null) return;

    filtered.match(
      (failure) => emit(
        state.copyWith(status: OccasionsListStatus.failure, failure: failure),
      ),
      (occasions) => emit(
        state.copyWith(
          status: OccasionsListStatus.success,
          occasions: occasions,
          hasAnyOccasion:
              occasions.isNotEmpty ||
              (filterActive &&
                  unfiltered!.getOrElse((_) => const []).isNotEmpty),
          clearFailure: true,
        ),
      ),
    );
    _completeFirstResult();
  }

  Future<void> searchChanged(String query) {
    emit(
      state.copyWith(
        filter: query.trim().isEmpty
            ? state.filter.copyWith(clearNameQuery: true)
            : state.filter.copyWith(nameQuery: query),
      ),
    );
    return subscribe();
  }

  Future<void> typeChanged(String? type) {
    emit(
      state.copyWith(
        filter: type == null
            ? state.filter.copyWith(clearType: true)
            : state.filter.copyWith(type: type),
      ),
    );
    return subscribe();
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
    return subscribe();
  }

  Future<void> clearFilters() {
    emit(state.copyWith(filter: const OccasionFilter()));
    return subscribe();
  }

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    // A superseded subscription will never deliver; release its waiter.
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
