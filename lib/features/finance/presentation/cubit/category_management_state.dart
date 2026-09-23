import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry_type.dart';

enum CategoryManagementStatus { loading, success, failure }

/// Immutable state for `CategoryManagementCubit` (constitution Principle
/// IV).
///
/// Active and archived categories are kept as two lists rather than one
/// flat list the page re-partitions: the management screen renders them as
/// two distinct sections (FR-010/FR-011), and splitting once here keeps
/// that grouping testable without a widget tree.
class CategoryManagementState extends Equatable {
  const CategoryManagementState({
    this.status = CategoryManagementStatus.loading,
    this.type = CategoryType.expense,
    this.active = const [],
    this.archived = const [],
    this.errorMessage,
    this.duplicateExisting,
    this.processingCategoryId,
  });

  final CategoryManagementStatus status;

  /// Which direction's categories are listed. A category's own type is
  /// immutable, so switching this is a different query, never an edit.
  final CategoryType type;

  final List<Category> active;

  /// Listed — and editable — rather than hidden: archiving removes a
  /// category from the *entry* picker (FR-011), not from the screen whose
  /// whole job is managing categories.
  final List<Category> archived;

  final String? errorMessage;

  /// The category a `DuplicateCategoryFailure` pointed at, so the page can
  /// name it instead of only reporting that a name is taken (FR-008).
  final Category? duplicateExisting;

  /// Non-null while a `removeCategory()` call is in flight for that id;
  /// a second call with the same id is a no-op while it is set.
  final String? processingCategoryId;

  bool get isLoading => status == CategoryManagementStatus.loading;

  bool get isEmpty => active.isEmpty && archived.isEmpty;

  CategoryManagementState copyWith({
    CategoryManagementStatus? status,
    CategoryType? type,
    List<Category>? active,
    List<Category>? archived,
    String? errorMessage,
    bool clearErrorMessage = false,
    Category? duplicateExisting,
    bool clearDuplicateExisting = false,
    String? processingCategoryId,
    bool clearProcessingCategoryId = false,
  }) {
    return CategoryManagementState(
      status: status ?? this.status,
      type: type ?? this.type,
      active: active ?? this.active,
      archived: archived ?? this.archived,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      duplicateExisting: clearDuplicateExisting
          ? null
          : (duplicateExisting ?? this.duplicateExisting),
      processingCategoryId: clearProcessingCategoryId
          ? null
          : (processingCategoryId ?? this.processingCategoryId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    type,
    active,
    archived,
    errorMessage,
    duplicateExisting,
    processingCategoryId,
  ];
}
