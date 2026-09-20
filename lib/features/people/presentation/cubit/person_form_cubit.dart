import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/people_failures.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/usecases/archive_person.dart';
import '../../domain/usecases/create_person.dart';
import '../../domain/usecases/delete_person.dart';
import '../../domain/usecases/edit_person.dart';
import 'person_form_state.dart';

/// Drives the create/edit-person form (US1's inline "create new person" and
/// US5's full profile management). Create mode delegates to [CreatePerson]
/// (surfacing a [PossibleDuplicateFailure] instead of inserting, per FR-003)
/// and edit mode delegates to [EditPerson]; edit mode also exposes archive
/// and delete actions.
@injectable
class PersonFormCubit extends Cubit<PersonFormState> {
  PersonFormCubit(
    this._peopleRepository,
    this._createPerson,
    this._editPerson,
    this._archivePerson,
    this._deletePerson,
  ) : super(const PersonFormState());

  final PeopleRepository _peopleRepository;
  final CreatePerson _createPerson;
  final EditPerson _editPerson;
  final ArchivePerson _archivePerson;
  final DeletePerson _deletePerson;

  /// Switches the form into edit mode, prefilled from [person]. Call once,
  /// right after construction.
  void loadForEdit(Person person) {
    emit(
      PersonFormState(
        isEditMode: true,
        editingPersonId: person.id,
        name: person.name,
        phoneNumber: person.phoneNumber,
        relationshipTag: person.relationshipTag,
        notes: person.notes,
      ),
    );
  }

  void nameChanged(String name) =>
      emit(state.copyWith(name: name, clearNameError: true));

  void phoneNumberChanged(String value) =>
      emit(state.copyWith(phoneNumber: value.isEmpty ? null : value));

  void relationshipTagChanged(String? tag) =>
      emit(state.copyWith(relationshipTag: tag));

  void notesChanged(String value) =>
      emit(state.copyWith(notes: value.isEmpty ? null : value));

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final trimmed = state.name.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(nameInvalid: true));
      return;
    }

    emit(
      state.copyWith(
        status: PersonFormStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    final result = state.isEditMode
        ? await _editPerson(
            personId: state.editingPersonId!,
            name: trimmed,
            phoneNumber: state.phoneNumber,
            relationshipTag: state.relationshipTag,
            notes: state.notes,
          )
        : await _createPerson(
            name: trimmed,
            phoneNumber: state.phoneNumber,
            relationshipTag: state.relationshipTag,
            notes: state.notes,
          );

    result.match(
      (failure) {
        if (failure is PossibleDuplicateFailure) {
          emit(
            state.copyWith(
              status: PersonFormStatus.idle,
              duplicateMatches: failure.matches,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: PersonFormStatus.failure,
              errorMessage: failure.message,
            ),
          );
        }
      },
      (person) => emit(
        state.copyWith(status: PersonFormStatus.success, savedPerson: person),
      ),
    );
  }

  /// The user explicitly confirmed the pending name is a distinct new
  /// person despite the duplicate warning — never a silent auto-merge
  /// (FR-003, Edge Cases).
  Future<void> confirmCreateDespiteDuplicate() async {
    final trimmed = state.name.trim();
    if (trimmed.isEmpty) return;

    emit(
      state.copyWith(
        status: PersonFormStatus.submitting,
        duplicateMatches: const [],
      ),
    );

    final result = await _peopleRepository.confirmCreateDespiteDuplicate(
      name: trimmed,
      phoneNumber: state.phoneNumber,
      relationshipTag: state.relationshipTag,
      notes: state.notes,
    );

    result.match(
      (failure) => emit(
        state.copyWith(
          status: PersonFormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (person) => emit(
        state.copyWith(status: PersonFormStatus.success, savedPerson: person),
      ),
    );
  }

  void dismissDuplicateWarning() =>
      emit(state.copyWith(duplicateMatches: const []));

  Future<void> archive() async {
    final id = state.editingPersonId;
    if (id == null) return;
    final result = await _archivePerson(id);
    result.match(
      (failure) => emit(
        state.copyWith(
          status: PersonFormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: PersonFormStatus.archived)),
    );
  }

  /// Attempts a permanent delete; surfaces [PersonFormStatus.deleteBlocked]
  /// (rather than a generic failure) when the person has recorded
  /// transactions, so the page can offer archiving instead (FR-017).
  Future<void> delete() async {
    final id = state.editingPersonId;
    if (id == null) return;
    final result = await _deletePerson(id);
    result.match((failure) {
      if (failure is PersonHasTransactionsFailure) {
        emit(state.copyWith(status: PersonFormStatus.deleteBlocked));
      } else {
        emit(
          state.copyWith(
            status: PersonFormStatus.failure,
            errorMessage: failure.message,
          ),
        );
      }
    }, (_) => emit(state.copyWith(status: PersonFormStatus.deleted)));
  }
}
