import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry_type.dart';

enum CategoryFormStatus { idle, submitting, success, failure }

/// Immutable state for `CategoryFormCubit` (constitution Principle IV).
/// Drives both create mode (name + icon + type) and edit mode (name + icon
/// only — a category's type is immutable after creation, data-model.md).
class CategoryFormState extends Equatable {
  const CategoryFormState({
    this.status = CategoryFormStatus.idle,
    this.isEditMode = false,
    this.editingCategoryId,
    this.name = '',
    this.icon,
    this.type,
    this.nameInvalid = false,
    this.iconInvalid = false,
    this.typeInvalid = false,
    this.errorMessage,
    this.duplicateExisting,
    this.savedCategory,
  });

  final CategoryFormStatus status;
  final bool isEditMode;
  final String? editingCategoryId;
  final String name;

  /// A `CategoryIconRegistry` key, never an `IconData` (research.md
  /// Decision 10). `null` until the user picks one.
  final String? icon;

  /// Required on create; carried (read-only) in edit mode purely so the
  /// page can tint the icon preview with the right direction color.
  final CategoryType? type;

  /// Flags rather than messages, so the page renders them through `l10n`
  /// and they stay correct across a language switch.
  final bool nameInvalid;
  final bool iconInvalid;
  final bool typeInvalid;

  final String? errorMessage;

  /// The active category whose name collided (FR-008). Present so the page
  /// can name it — "you already have X" beats "that name is taken".
  final Category? duplicateExisting;

  final Category? savedCategory;

  bool get isSubmitting => status == CategoryFormStatus.submitting;

  CategoryFormState copyWith({
    CategoryFormStatus? status,
    bool? isEditMode,
    String? editingCategoryId,
    String? name,
    String? icon,
    CategoryType? type,
    bool? nameInvalid,
    bool? iconInvalid,
    bool? typeInvalid,
    bool clearValidationErrors = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    Category? duplicateExisting,
    bool clearDuplicateExisting = false,
    Category? savedCategory,
  }) {
    return CategoryFormState(
      status: status ?? this.status,
      isEditMode: isEditMode ?? this.isEditMode,
      editingCategoryId: editingCategoryId ?? this.editingCategoryId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      nameInvalid: clearValidationErrors
          ? false
          : (nameInvalid ?? this.nameInvalid),
      iconInvalid: clearValidationErrors
          ? false
          : (iconInvalid ?? this.iconInvalid),
      typeInvalid: clearValidationErrors
          ? false
          : (typeInvalid ?? this.typeInvalid),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      duplicateExisting: clearDuplicateExisting
          ? null
          : (duplicateExisting ?? this.duplicateExisting),
      savedCategory: savedCategory ?? this.savedCategory,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isEditMode,
    editingCategoryId,
    name,
    icon,
    type,
    nameInvalid,
    iconInvalid,
    typeInvalid,
    errorMessage,
    duplicateExisting,
    savedCategory,
  ];
}
