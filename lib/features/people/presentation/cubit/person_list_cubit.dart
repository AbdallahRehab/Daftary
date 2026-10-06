import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../transactions/domain/entities/person_balance.dart';
import '../../../transactions/domain/usecases/watch_person_balances.dart';
import '../../domain/entities/person.dart';
import '../../domain/usecases/archive_person.dart';
import '../../domain/usecases/restore_person.dart';
import '../../domain/usecases/watch_active_people.dart';
import 'person_list_state.dart';

/// Lists active people with name + [RelationshipStatus] filters (FR-019),
/// each with its balance from one batched [WatchPersonBalances] read.
///
/// 021: the list is live. The Cubit subscribes to [WatchActivePeople] and,
/// for the people it lists, to [WatchPersonBalances], so any change —
/// made on this screen, on another screen, or applied by sync — reaches the
/// list with no reload (FR-031). Both subscriptions are cancelled in
/// [close].
@injectable
class PersonListCubit extends Cubit<PersonListState> {
  PersonListCubit(
    this._watchActivePeople,
    this._watchPersonBalances,
    this._archivePerson,
    this._restorePerson,
  ) : super(const PersonListState());

  final WatchActivePeople _watchActivePeople;
  final WatchPersonBalances _watchPersonBalances;
  final ArchivePerson _archivePerson;
  final RestorePerson _restorePerson;

  StreamSubscription<void>? _peopleSubscription;
  StreamSubscription<void>? _balancesSubscription;

  /// Completes on the first result of the current subscription, so pull to
  /// refresh (and tests) can await it.
  Completer<void>? _firstResult;

  /// Subscribes to the list for the current [PersonListState.nameQuery] and
  /// [PersonListState.statusFilter], replacing any earlier subscription (a
  /// superseded one never emits again). The returned future completes once
  /// the first result has been emitted.
  Future<void> subscribe() {
    _cancelSubscriptions();
    emit(state.copyWith(status: PersonListStatus.loading));

    final firstResult = _firstResult = Completer<void>();
    final nameQuery = state.nameQuery.trim().isEmpty ? null : state.nameQuery;
    _peopleSubscription =
        _watchActivePeople(
          nameQuery: nameQuery,
          statusFilter: state.statusFilter,
        ).listen((result) {
          if (isClosed) return;
          result.match((failure) {
            _balancesSubscription?.cancel();
            _balancesSubscription = null;
            emit(
              state.copyWith(
                status: PersonListStatus.failure,
                failure: failure,
              ),
            );
            _completeFirstResult();
          }, _watchBalancesFor);
        });
    return firstResult.future;
  }

  /// Retry and pull to refresh: subscribes again from scratch.
  Future<void> resubscribe() => subscribe();

  void _watchBalancesFor(List<Person> people) {
    _balancesSubscription?.cancel();
    _balancesSubscription =
        _watchPersonBalances([for (final person in people) person.id]).listen((
          result,
        ) {
          if (isClosed) return;
          result.match(
            (failure) => emit(
              state.copyWith(
                status: PersonListStatus.failure,
                failure: failure,
              ),
            ),
            (balances) => emit(
              state.copyWith(
                status: PersonListStatus.success,
                items: [
                  for (final person in people)
                    if (balances[person.id] case final balance?)
                      PersonListItem(person: person, balance: balance),
                ],
              ),
            ),
          );
          _completeFirstResult();
        });
  }

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscriptions() {
    _peopleSubscription?.cancel();
    _balancesSubscription?.cancel();
    _peopleSubscription = null;
    _balancesSubscription = null;
    // A superseded subscription will never deliver; release its waiter.
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }

  void nameQueryChanged(String query) {
    emit(state.copyWith(nameQuery: query));
    subscribe();
  }

  /// Resets the name search and the status filter, then reloads.
  void clearFilters() {
    emit(state.copyWith(nameQuery: '', clearStatusFilter: true));
    subscribe();
  }

  void statusFilterChanged(RelationshipStatus? filter) {
    emit(
      state.copyWith(statusFilter: filter, clearStatusFilter: filter == null),
    );
    subscribe();
  }

  /// Archives [personId] (FR-017/FR-018). The row leaves the list at once;
  /// the live subscription then confirms it. A no-op re-entrancy guard
  /// while an archive call for the same [personId] is already in flight
  /// (FR-006).
  ///
  /// On success, [PersonListState.lastArchived] carries the archived person
  /// for one emission so the page can offer an Undo snackbar; on failure,
  /// [PersonListState.failure] is set while the list stays on screen.
  Future<void> archive(String personId) async {
    if (state.processingPersonId == personId) return;
    final archived = state.items
        .where((item) => item.person.id == personId)
        .map((item) => item.person)
        .firstOrNull;
    emit(state.copyWith(processingPersonId: personId));

    final result = await _archivePerson(personId);
    if (isClosed) return;
    result.match(
      (failure) =>
          emit(state.copyWith(failure: failure, clearProcessingPersonId: true)),
      (_) => emit(
        state.copyWith(
          items: [
            for (final item in state.items)
              if (item.person.id != personId) item,
          ],
          clearProcessingPersonId: true,
          lastArchived: archived,
        ),
      ),
    );
  }

  /// Reverses an [archive] from its Undo snackbar by restoring [personId]
  /// to the active list (FR-018); the live subscription brings it back.
  Future<void> undoArchive(String personId) async {
    final result = await _restorePerson(personId);
    if (isClosed) return;
    result.match((failure) => emit(state.copyWith(failure: failure)), (_) {});
  }
}
