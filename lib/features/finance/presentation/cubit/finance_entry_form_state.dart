import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/finance_entry_type.dart';

enum FinanceEntryFormStatus { editing, submitting, success, failure }

/// Immutable state for `FinanceEntryFormCubit` (constitution Principle IV —
/// updated exclusively via [copyWith]).
class FinanceEntryFormState extends Equatable {
  FinanceEntryFormState({
    required this.idempotencyKey,
    this.status = FinanceEntryFormStatus.editing,
    this.type = FinanceEntryType.expense,
    this.isEditMode = false,
    this.editingEntryId,
    this.isEdited = false,
    this.categories = const [],
    this.isLoadingCategories = false,
    this.selectedCategoryId,
    DateTime? date,
    this.amountInput = '',
    this.note,
    this.amountInvalid = false,
    this.categorySelectionRequired = false,
    this.errorMessage,
    this.savedEntry,
  }) : date = date ?? DateTime.now();

  /// Generated once when the form opens, so a retried save resolves to the
  /// same entry instead of a second one (FR-021).
  final String idempotencyKey;
  final FinanceEntryFormStatus status;

  /// Which direction the form is currently recording. Swapping it reloads
  /// the category set (FR-002, T031).
  final FinanceEntryType type;
  final bool isEditMode;
  final String? editingEntryId;

  /// Whether the entry being edited already carries an `editedAt` marker.
  final bool isEdited;

  /// The categories currently offered by the picker: active categories of
  /// [type], plus — in edit mode only — the entry's own category even when
  /// it has since been archived (FR-011).
  final List<Category> categories;
  final bool isLoadingCategories;
  final String? selectedCategoryId;
  final DateTime date;
  final String amountInput;
  final String? note;

  /// Set by this cubit's own client-side "amount must be > 0" check
  /// (FR-003) — a flag rather than a message so the page renders it via
  /// `l10n.amountInvalidError` regardless of locale.
  final bool amountInvalid;

  /// Set by this cubit's own client-side "a category must be selected"
  /// check (FR-003) — same localization rationale as [amountInvalid].
  final bool categorySelectionRequired;
  final String? errorMessage;
  final FinanceEntry? savedEntry;

  bool get isSubmitting => status == FinanceEntryFormStatus.submitting;
  bool get isSuccess => status == FinanceEntryFormStatus.success;

  Category? get selectedCategory {
    final id = selectedCategoryId;
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  FinanceEntryFormState copyWith({
    FinanceEntryFormStatus? status,
    FinanceEntryType? type,
    List<Category>? categories,
    bool? isLoadingCategories,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    DateTime? date,
    String? amountInput,
    String? note,
    bool? amountInvalid,
    bool clearAmountError = false,
    bool? categorySelectionRequired,
    bool clearCategoryError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    FinanceEntry? savedEntry,
  }) {
    return FinanceEntryFormState(
      idempotencyKey: idempotencyKey,
      status: status ?? this.status,
      type: type ?? this.type,
      isEditMode: isEditMode,
      editingEntryId: editingEntryId,
      isEdited: isEdited,
      categories: categories ?? this.categories,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      date: date ?? this.date,
      amountInput: amountInput ?? this.amountInput,
      note: note ?? this.note,
      amountInvalid: clearAmountError
          ? false
          : (amountInvalid ?? this.amountInvalid),
      categorySelectionRequired: clearCategoryError
          ? false
          : (categorySelectionRequired ?? this.categorySelectionRequired),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      savedEntry: savedEntry ?? this.savedEntry,
    );
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    status,
    type,
    isEditMode,
    editingEntryId,
    isEdited,
    categories,
    isLoadingCategories,
    selectedCategoryId,
    date,
    amountInput,
    note,
    amountInvalid,
    categorySelectionRequired,
    errorMessage,
    savedEntry,
  ];
}
