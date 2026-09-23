import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/occasion.dart';
import '../../domain/usecases/create_occasion.dart';
import '../../domain/usecases/edit_occasion.dart';
import 'occasion_form_state.dart';

/// Drives the create/edit-occasion form (FR-001/FR-002/FR-012).
///
/// A fresh idempotency key is generated the moment the cubit is created
/// (i.e. when the form opens), and `submit()` ignores a re-entrant call
/// while one is already in flight — together that is what guarantees a
/// rapid double-tap creates exactly one occasion (FR-019).
@injectable
class OccasionFormCubit extends Cubit<OccasionFormState> {
  OccasionFormCubit(this._createOccasion, this._editOccasion)
    : super(OccasionFormState(idempotencyKey: const Uuid().v4()));

  final CreateOccasion _createOccasion;
  final EditOccasion _editOccasion;

  /// Switches the form into edit mode, prefilled from [occasion] (FR-012).
  /// Call once, right after construction.
  void loadForEdit(Occasion occasion) {
    emit(
      OccasionFormState(
        idempotencyKey: state.idempotencyKey,
        isEditMode: true,
        editingOccasionId: occasion.id,
        name: occasion.name,
        date: occasion.date,
        type: occasion.type,
        notes: occasion.notes,
      ),
    );
  }

  void nameChanged(String name) {
    emit(state.copyWith(name: name, clearNameError: true));
  }

  void dateChanged(DateTime date) {
    emit(state.copyWith(date: date));
  }

  void typeChanged(String type) {
    emit(state.copyWith(type: type, clearTypeError: true));
  }

  void notesChanged(String notes) {
    emit(state.copyWith(notes: notes));
  }

  Future<void> submit() async {
    // A rapid double-tap re-enters here before the first call resolves;
    // ignoring it (rather than re-invoking the use case) is what makes the
    // single-flight guarantee hold even before the UI has re-rendered.
    if (state.isSubmitting) return;

    // Both validations emit a flag and return without touching anything
    // else, so nothing the user already typed is discarded.
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(nameInvalid: true));
      return;
    }
    final type = state.type?.trim() ?? '';
    if (type.isEmpty) {
      emit(state.copyWith(typeInvalid: true));
      return;
    }

    emit(
      state.copyWith(status: OccasionFormStatus.submitting, clearFailure: true),
    );

    final notes = state.notes?.trim();
    final result = state.isEditMode
        ? await _editOccasion(
            occasionId: state.editingOccasionId!,
            name: name,
            date: state.date,
            type: type,
            notes: (notes?.isEmpty ?? true) ? null : notes,
          )
        : await _createOccasion(
            idempotencyKey: state.idempotencyKey,
            name: name,
            date: state.date,
            type: type,
            notes: (notes?.isEmpty ?? true) ? null : notes,
          );

    // The form may have been popped while the save was still in flight —
    // the mutation itself already went through exactly once above, but this
    // cubit no longer has a listener to tell, and `emit` after `close()`
    // throws.
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: OccasionFormStatus.failure, failure: failure),
      ),
      (occasion) => emit(
        state.copyWith(
          // A brand-new key: the save that just succeeded is done, so a
          // subsequent create from the same open form is a deliberate
          // second occasion, not a retry the repository should swallow
          // (FR-019).
          idempotencyKey: const Uuid().v4(),
          status: OccasionFormStatus.success,
          savedOccasion: occasion,
        ),
      ),
    );
  }
}
