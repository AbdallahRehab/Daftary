import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_failures.dart';
import '../../domain/usecases/create_category.dart';
import '../../domain/usecases/edit_category.dart';
import 'category_form_state.dart';

/// Drives the create/edit-category form (US4, FR-007/FR-008/FR-009).
///
/// Edit mode offers no type control at all — not a disabled one — because
/// a category's type is immutable after creation: changing it would
/// silently reclassify every entry already filed under it (data-model.md),
/// which is exactly the kind of invisible mutation of financial history the
/// constitution forbids.
@injectable
class CategoryFormCubit extends Cubit<CategoryFormState> {
  CategoryFormCubit(this._createCategory, this._editCategory)
    : super(const CategoryFormState());

  final CreateCategory _createCategory;
  final EditCategory _editCategory;

  /// Opens the form in create mode for [type], the direction the management
  /// screen was showing when "add" was tapped.
  void initializeForCreate(CategoryType type) =>
      emit(state.copyWith(type: type));

  /// Switches the form into edit mode, prefilled from [category]. Call
  /// once, right after construction.
  void loadForEdit(Category category) {
    emit(
      CategoryFormState(
        isEditMode: true,
        editingCategoryId: category.id,
        name: category.name,
        icon: category.icon,
        type: category.type,
      ),
    );
  }

  /// The category an edit-mode page was opened for could not be resolved
  /// (deleted under a stale deep link, say). Surfaced as a form failure
  /// rather than silently leaving an empty create-looking form.
  void loadFailed(String message) => emit(
    state.copyWith(status: CategoryFormStatus.failure, errorMessage: message),
  );

  void nameChanged(String name) => emit(
    state.copyWith(
      name: name,
      nameInvalid: false,
      clearDuplicateExisting: true,
      clearErrorMessage: true,
    ),
  );

  void iconChanged(String icon) =>
      emit(state.copyWith(icon: icon, iconInvalid: false));

  /// Ignored in edit mode: the type control is not rendered there, so a
  /// call could only come from a stale widget.
  void typeChanged(CategoryType type) {
    if (state.isEditMode) return;
    emit(state.copyWith(type: type, typeInvalid: false));
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final trimmed = state.name.trim();
    final icon = state.icon;
    final type = state.type;
    final nameInvalid = trimmed.isEmpty;
    final iconInvalid = icon == null;
    // Only create has to establish a type; in edit mode it is whatever the
    // category was created with and is never re-sent.
    final typeInvalid = !state.isEditMode && type == null;

    if (nameInvalid || iconInvalid || typeInvalid) {
      emit(
        state.copyWith(
          nameInvalid: nameInvalid,
          iconInvalid: iconInvalid,
          typeInvalid: typeInvalid,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: CategoryFormStatus.submitting,
        clearErrorMessage: true,
        clearDuplicateExisting: true,
      ),
    );

    final result = state.isEditMode
        ? await _editCategory(
            categoryId: state.editingCategoryId!,
            name: trimmed,
            icon: icon,
          )
        : await _createCategory(name: trimmed, type: type!, icon: icon);
    if (isClosed) return;

    result.match(
      (failure) {
        if (failure is DuplicateCategoryFailure) {
          emit(
            state.copyWith(
              status: CategoryFormStatus.idle,
              duplicateExisting: failure.existing,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: CategoryFormStatus.failure,
              errorMessage: failure.message,
            ),
          );
        }
      },
      (category) => emit(
        state.copyWith(
          status: CategoryFormStatus.success,
          savedCategory: category,
        ),
      ),
    );
  }
}
