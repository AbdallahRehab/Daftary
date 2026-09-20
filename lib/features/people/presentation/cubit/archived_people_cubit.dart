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
        state.copyWith(
          status: ArchivedPeopleStatus.failure,
          errorMessage: failure.message,
        ),
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
  /// immediately (FR-018, Acceptance Scenario 4).
  Future<bool> restore(String personId) async {
    final result = await _restorePerson(personId);
    return result.match(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        load();
        return true;
      },
    );
  }
}
