import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_failures.dart';
import '../../domain/usecases/remove_category.dart';
import '../../domain/usecases/watch_categories.dart';
import 'category_management_state.dart';

/// Drives the category-management screen (US4): lists one direction's
/// categories — archived ones included, so they stay visible and editable
/// (FR-010/FR-011) — and removes one on request.
///
/// Deliberately knows nothing about whether a removal archived or hard-
/// deleted the category: that branch is decided by the data inside
/// `RemoveCategory` (research.md Decision 4), and duplicating the
/// reference-count reasoning up here would give the UI a second, drift-prone
/// copy of the rule. The cubit just renders whatever the repository left
/// behind.
///
/// 021: the list is a live [WatchCategories] subscription, cancelled in
/// [close] — a create or edit in the form, a removal here, or a synced
/// change shows with no reload (FR-031).
@injectable
class CategoryManagementCubit extends Cubit<CategoryManagementState> {
  CategoryManagementCubit(this._watchCategories, this._removeCategory)
    : super(const CategoryManagementState());

  final WatchCategories _watchCategories;
  final RemoveCategory _removeCategory;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to the selected direction's categories, replacing any
  /// earlier subscription. The returned future completes once the first
  /// result has been emitted.
  Future<void> subscribe() {
    _cancelSubscription();
    emit(
      state.copyWith(
        status: CategoryManagementStatus.loading,
        clearFailure: true,
        clearDuplicateExisting: true,
      ),
    );

    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchCategories(type: state.type, includeArchived: true)
        .listen((result) {
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
          _completeFirstResult();
        });
    return firstResult.future;
  }

  /// Retry: subscribes again from scratch.
  Future<void> resubscribe() => subscribe();

  /// Switches which direction is listed and resubscribes. A no-op when
  /// [type] is already the selected one, so re-tapping the active toggle
  /// doesn't flash the list back through its loading state.
  Future<void> typeChanged(CategoryType type) async {
    if (state.type == type) return;
    emit(state.copyWith(type: type, active: const [], archived: const []));
    await subscribe();
  }

  /// Removes [id]. Whether the category disappeared or merely moved into
  /// the archived section is visible in the lists the subscription then
  /// emits — nothing here predicts it.
  Future<void> removeCategory(String id) async {
    if (state.processingCategoryId == id) return;
    emit(state.copyWith(processingCategoryId: id, clearFailure: true));

    final result = await _removeCategory(id);
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(
          failure: failure,
          duplicateExisting: failure is DuplicateCategoryFailure
              ? failure.existing
              : null,
          clearProcessingCategoryId: true,
        ),
      ),
      (_) => emit(state.copyWith(clearProcessingCategoryId: true)),
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
