import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/people_repository.dart';
import '../../domain/usecases/restore_person.dart';
import 'archived_people_state.dart';

/// Lists/searches archived people (FR-018) and restores one back into the
/// active list.
@injectable
class ArchivedPeopleCubit extends Cubit<ArchivedPeopleState> {
  ArchivedPeopleCubit(this._peopleRepository, this._restorePerson)
    : super(const ArchivedPeopleState());

  final PeopleRepository _peopleRepository;
  final RestorePerson _restorePerson;

  Future<void> load() async {
    emit(state.copyWith(status: ArchivedPeopleStatus.loading));

    final result = await _peopleRepository.searchArchivedPeople(
      nameQuery: state.nameQuery.trim().isEmpty ? null : state.nameQuery,
    );

    result.match(
      (failure) => emit(
        state.copyWith(status: ArchivedPeopleStatus.failure, failure: failure),
      ),
      (people) => emit(
        state.copyWith(status: ArchivedPeopleStatus.success, people: people),
      ),
    );
  }

  void nameQueryChanged(String query) {
    emit(state.copyWith(nameQuery: query));
    load();
  }

  /// Restores [personId] and refreshes the archived list so it disappears
  /// immediately (FR-018, Acceptance Scenario 4). A no-op re-entrancy guard
  /// while a restore call for the same [personId] is already in flight
  /// (FR-006).
  Future<bool> restore(String personId) async {
    if (state.processingPersonId == personId) return false;
    emit(state.copyWith(processingPersonId: personId));

    final result = await _restorePerson(personId);
    return result.match(
      (failure) {
        emit(state.copyWith(failure: failure, clearProcessingPersonId: true));
        return false;
      },
      (_) {
        load().then((_) => emit(state.copyWith(clearProcessingPersonId: true)));
        return true;
      },
    );
  }
}
