import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_failures.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/remove_category.dart';
import 'category_management_state.dart';

/// Drives the category-management screen (US4): lists one direction's
/// categories — archived ones included, so they stay visible and editable
/// (FR-010/FR-011) — and removes one on request.
///
/// Deliberately knows nothing about whether a removal archived or hard-
/// deleted the category: that branch is decided by the data inside
/// `RemoveCategory` (research.md Decision 4), and duplicating the
/// reference-count reasoning up here would give the UI a second, drift-prone
/// copy of the rule. The cubit just reloads and renders whatever the
/// repository left behind.
@injectable
class CategoryManagementCubit extends Cubit<CategoryManagementState> {
  CategoryManagementCubit(this._getCategories, this._removeCategory)
    : super(const CategoryManagementState());

  final GetCategories _getCategories;
  final RemoveCategory _removeCategory;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: CategoryManagementStatus.loading,
        clearFailure: true,
        clearDuplicateExisting: true,
      ),
    );

    final result = await _getCategories(
      type: state.type,
      includeArchived: true,
    );
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(
          status: CategoryManagementStatus.failure,
          failure: failure,
          duplicateExisting: failure is DuplicateCategoryFailure
              ? failure.existing
              : null,
        ),
      ),
      (categories) => emit(
        state.copyWith(
          status: CategoryManagementStatus.success,
          active: [
            for (final c in categories)
              if (c.isActive) c,
          ],
          archived: [
            for (final c in categories)
              if (c.isArchived) c,
          ],
        ),
      ),
    );
  }

  /// Switches which direction is listed and reloads. A no-op when [type] is
  /// already the selected one, so re-tapping the active toggle doesn't
  /// flash the list back through its loading state.
  Future<void> typeChanged(CategoryType type) async {
    if (state.type == type) return;
    emit(state.copyWith(type: type, active: const [], archived: const []));
    await load();
  }

  /// Removes [id] and reloads. Whether the category disappeared or merely
  /// moved into the archived section is visible in the reloaded lists —
  /// nothing here predicts it.
  Future<void> removeCategory(String id) async {
    if (state.processingCategoryId == id) return;
    emit(state.copyWith(processingCategoryId: id, clearFailure: true));

    final result = await _removeCategory(id);
    if (isClosed) return;

    await result.match(
      (failure) async => emit(
        state.copyWith(
          failure: failure,
          duplicateExisting: failure is DuplicateCategoryFailure
              ? failure.existing
              : null,
          clearProcessingCategoryId: true,
        ),
      ),
      (_) async {
        await load();
        if (isClosed) return;
        emit(state.copyWith(clearProcessingCategoryId: true));
      },
    );
  }
}
