import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../transactions/domain/entities/person_balance.dart';
import '../../../transactions/domain/usecases/get_person_balances.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/usecases/archive_person.dart';
import '../../domain/usecases/restore_person.dart';
import 'person_list_state.dart';

/// Loads active people and applies name + [RelationshipStatus] filters
/// (FR-019), reading every listed person's balance in one batched
/// [GetPersonBalances] call for display.
@injectable
class PersonListCubit extends Cubit<PersonListState> {
  PersonListCubit(
    this._peopleRepository,
    this._getPersonBalances,
    this._archivePerson,
    this._restorePerson,
  ) : super(const PersonListState());

  final PeopleRepository _peopleRepository;
  final GetPersonBalances _getPersonBalances;

  /// Bumped by every [load]; a load whose number is no longer current was
  /// superseded (a newer keystroke or filter) and must not emit its stale
  /// results over the newer ones.
  int _loadGeneration = 0;
  final ArchivePerson _archivePerson;
  final RestorePerson _restorePerson;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    emit(state.copyWith(status: PersonListStatus.loading));

    final result = await _peopleRepository.searchActivePeople(
      nameQuery: state.nameQuery.trim().isEmpty ? null : state.nameQuery,
      statusFilter: state.statusFilter,
    );
    if (generation != _loadGeneration || isClosed) return;

    await result.match(
      (failure) async => emit(
        state.copyWith(status: PersonListStatus.failure, failure: failure),
      ),
      (people) async {
        final balancesResult = await _getPersonBalances([
          for (final person in people) person.id,
        ]);
        if (generation != _loadGeneration || isClosed) return;
        balancesResult.match(
          (failure) => emit(
            state.copyWith(status: PersonListStatus.failure, failure: failure),
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
      },
    );
  }

  void nameQueryChanged(String query) {
    emit(state.copyWith(nameQuery: query));
    load();
  }

  void statusFilterChanged(RelationshipStatus? filter) {
    emit(
      state.copyWith(statusFilter: filter, clearStatusFilter: filter == null),
    );
    load();
  }

  /// Archives [personId] (FR-017/FR-018) and reloads so it drops out of the
  /// active list immediately. A no-op re-entrancy guard while an archive
  /// call for the same [personId] is already in flight (FR-006).
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
    await result.match(
      (failure) async =>
          emit(state.copyWith(failure: failure, clearProcessingPersonId: true)),
      (_) async {
        await load();
        emit(
          state.copyWith(clearProcessingPersonId: true, lastArchived: archived),
        );
      },
    );
  }

  /// Reverses an [archive] from its Undo snackbar by restoring [personId]
  /// to the active list (FR-018), then reloads.
  Future<void> undoArchive(String personId) async {
    final result = await _restorePerson(personId);
    await result.match(
      (failure) async => emit(state.copyWith(failure: failure)),
      (_) => load(),
    );
  }
}
