import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../transactions/domain/entities/person_balance.dart';
import '../../../transactions/domain/usecases/get_person_balance.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/usecases/archive_person.dart';
import 'person_list_state.dart';

/// Loads active people and applies name + [RelationshipStatus] filters
/// (FR-019), using [GetPersonBalance] per person to determine each one's
/// status for both display and filtering.
@injectable
class PersonListCubit extends Cubit<PersonListState> {
  PersonListCubit(
    this._peopleRepository,
    this._getPersonBalance,
    this._archivePerson,
  ) : super(const PersonListState());

  final PeopleRepository _peopleRepository;
  final GetPersonBalance _getPersonBalance;
  final ArchivePerson _archivePerson;

  Future<void> load() async {
    emit(state.copyWith(status: PersonListStatus.loading));

    final result = await _peopleRepository.searchActivePeople(
      nameQuery: state.nameQuery.trim().isEmpty ? null : state.nameQuery,
      statusFilter: state.statusFilter,
    );

    await result.match(
      (failure) async => emit(
        state.copyWith(
          status: PersonListStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (people) async {
        final items = <PersonListItem>[];
        for (final person in people) {
          final balanceResult = await _getPersonBalance(person.id);
          balanceResult.match(
            (_) {},
            (balance) =>
                items.add(PersonListItem(person: person, balance: balance)),
          );
        }
        emit(state.copyWith(status: PersonListStatus.success, items: items));
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
  Future<void> archive(String personId) async {
    if (state.processingPersonId == personId) return;
    emit(state.copyWith(processingPersonId: personId));

    final result = await _archivePerson(personId);
    await result.match(
      (failure) async => emit(
        state.copyWith(
          errorMessage: failure.message,
          clearProcessingPersonId: true,
        ),
      ),
      (_) async {
        await load();
        emit(state.copyWith(clearProcessingPersonId: true));
      },
    );
  }
}
