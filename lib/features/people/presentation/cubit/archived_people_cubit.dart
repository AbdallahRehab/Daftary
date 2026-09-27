import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/restore_person.dart';
import '../../domain/usecases/watch_archived_people.dart';
import 'archived_people_state.dart';

/// Lists/searches archived people (FR-018) and restores one back into the
/// active list.
///
/// 021: the list is a live [WatchArchivedPeople] subscription, cancelled in
/// [close], so an archive or restore made anywhere — or applied by sync —
/// shows here with no reload (FR-031).
@injectable
class ArchivedPeopleCubit extends Cubit<ArchivedPeopleState> {
  ArchivedPeopleCubit(this._watchArchivedPeople, this._restorePerson)
    : super(const ArchivedPeopleState());

  final WatchArchivedPeople _watchArchivedPeople;
  final RestorePerson _restorePerson;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to the archived list for the current
  /// [ArchivedPeopleState.nameQuery], replacing any earlier subscription.
  /// The returned future completes once the first result has been emitted.
  Future<void> subscribe() {
    _cancelSubscription();
    emit(state.copyWith(status: ArchivedPeopleStatus.loading));

    final firstResult = _firstResult = Completer<void>();
    _subscription =
        _watchArchivedPeople(
          nameQuery: state.nameQuery.trim().isEmpty ? null : state.nameQuery,
        ).listen((result) {
          if (isClosed) return;
          result.match(
            (failure) => emit(
              state.copyWith(
                status: ArchivedPeopleStatus.failure,
                failure: failure,
              ),
            ),
            (people) => emit(
              state.copyWith(
                status: ArchivedPeopleStatus.success,
                people: people,
              ),
            ),
          );
          _completeFirstResult();
        });
    return firstResult.future;
  }

  /// Retry: subscribes again from scratch.
  Future<void> resubscribe() => subscribe();

  void nameQueryChanged(String query) {
    emit(state.copyWith(nameQuery: query));
    subscribe();
  }

  /// Restores [personId]; it leaves this list at once, and the live
  /// subscription confirms it (FR-018, Acceptance Scenario 4). A no-op
  /// re-entrancy guard while a restore call for the same [personId] is
  /// already in flight (FR-006).
  Future<bool> restore(String personId) async {
    if (state.processingPersonId == personId) return false;
    emit(state.copyWith(processingPersonId: personId));

    final result = await _restorePerson(personId);
    if (isClosed) return result.isRight();
    return result.match(
      (failure) {
        emit(state.copyWith(failure: failure, clearProcessingPersonId: true));
        return false;
      },
      (_) {
        emit(
          state.copyWith(
            people: [
              for (final person in state.people)
                if (person.id != personId) person,
            ],
            clearProcessingPersonId: true,
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
