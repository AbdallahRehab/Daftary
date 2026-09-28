import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../finance/domain/entities/category.dart';
import '../../domain/entities/budget_summary.dart';

enum BudgetFormStatus {
  loading,
  editing,
  submitting,
  success,
  deleting,
  deleted,
  failure,
}

/// Why an amount field was refused by the form's own client-side check. A
/// reason rather than a message, so the page renders it through
/// `AppLocalizations` in whichever language is active (FR-020).
enum BudgetAmountError {
  /// A planned amount was left empty. Zero is a valid plan (FR-002) — it
  /// has to be typed, not implied by a blank field.
  required,

  /// Not a number at all.
  invalid,

  /// Below zero (FR-002).
  negative,
}

/// One category row in the budget form: either an allocation already saved
/// on the budget (edit mode, FR-010) or one the user added in this session.
///
/// Carries the category's display name/icon with it rather than looking
/// them up from the picker's category list, because an already-budgeted
/// category may since have been archived — it stays on the budget and must
/// keep rendering (FR-021) even though the picker no longer offers it.
class BudgetAllocationDraft extends Equatable {
  const BudgetAllocationDraft({
    required this.idempotencyKey,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    this.isCategoryArchived = false,
    this.amountInput = '',
    this.plannedMinorUnits,
    this.amountError,
    this.persistedAllocationId,
    this.persistedPlannedMinorUnits,
  });

  /// Generated once when the row is added, so a retried save of this row
  /// resolves to the allocation it already wrote (FR-017).
  final String idempotencyKey;
  final String categoryId;
  final String categoryName;

  /// A `CategoryIconRegistry` key (007).
  final String categoryIcon;

  final bool isCategoryArchived;
  final String amountInput;

  /// [amountInput] parsed live as the user types, `null` while it does not
  /// parse. Feeds the running total and the FR-004 "exceeds income" hint.
  final int? plannedMinorUnits;
  final BudgetAmountError? amountError;

  /// The saved allocation's id once this row exists in the database —
  /// either loaded in edit mode, or written by an earlier (possibly
  /// partially failed) save in this session.
  final String? persistedAllocationId;

  /// What the saved allocation currently holds, so an unchanged row is not
  /// re-written on save.
  final int? persistedPlannedMinorUnits;

  bool get isPersisted => persistedAllocationId != null;

  bool get hasUnsavedAmountChange =>
      isPersisted && plannedMinorUnits != persistedPlannedMinorUnits;

  BudgetAllocationDraft copyWith({
    String? amountInput,
    int? plannedMinorUnits,
    bool clearPlannedMinorUnits = false,
    BudgetAmountError? amountError,
    bool clearAmountError = false,
    String? persistedAllocationId,
    int? persistedPlannedMinorUnits,
  }) {
    return BudgetAllocationDraft(
      idempotencyKey: idempotencyKey,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      isCategoryArchived: isCategoryArchived,
      amountInput: amountInput ?? this.amountInput,
      plannedMinorUnits: clearPlannedMinorUnits
          ? null
          : (plannedMinorUnits ?? this.plannedMinorUnits),
      amountError: clearAmountError ? null : (amountError ?? this.amountError),
      persistedAllocationId:
          persistedAllocationId ?? this.persistedAllocationId,
      persistedPlannedMinorUnits:
          persistedPlannedMinorUnits ?? this.persistedPlannedMinorUnits,
    );
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    categoryId,
    categoryName,
    categoryIcon,
    isCategoryArchived,
    amountInput,
    plannedMinorUnits,
    amountError,
    persistedAllocationId,
    persistedPlannedMinorUnits,
  ];
}

/// Immutable state for `BudgetFormCubit` (constitution Principle IV —
/// updated exclusively via [copyWith]).
class BudgetFormState extends Equatable {
  const BudgetFormState({
    required this.month,
    required this.idempotencyKey,
    this.status = BudgetFormStatus.loading,
    this.budgetId,
    this.isEditMode = false,
    this.incomeInput = '',
    this.expectedIncomeMinorUnits,
    this.persistedExpectedIncomeMinorUnits,
    this.incomeError,
    this.allocations = const [],
    this.removedAllocationIds = const [],
    this.categories = const [],
    this.isLoadingCategories = false,
    this.currency = Currency.egp,
    this.failure,
  });

  /// `'YYYY-MM'`.
  final String month;

  /// 018: the currency every figure on the form is in — the edited
  /// budget's own, or the primary currency for a new one.
  final Currency currency;

  /// Generated once when the form opens and reused by every retry of the
  /// "create budget" step, so a double-tapped Save can only ever produce
  /// one budget for the month (FR-017).
  final String idempotencyKey;
  final BudgetFormStatus status;

  /// The budget being edited, or — after the create step of a save has
  /// succeeded — the one just created. Once set, a retried save never tries
  /// to create again.
  final String? budgetId;

  /// The month already had a budget when the form opened (FR-010).
  final bool isEditMode;
  final String incomeInput;

  /// [incomeInput] parsed live; `null` when blank or unparseable.
  final int? expectedIncomeMinorUnits;

  /// The expected income currently saved on the budget, so an unchanged
  /// figure is not re-written.
  final int? persistedExpectedIncomeMinorUnits;
  final BudgetAmountError? incomeError;
  final List<BudgetAllocationDraft> allocations;

  /// Saved allocations the user removed in this session; deleted on save.
  final List<String> removedAllocationIds;

  /// Active (non-archived) expense categories — what the picker may offer
  /// (FR-021). Income categories are never budgeted (spec Assumptions).
  final List<Category> categories;
  final bool isLoadingCategories;
  final Failure? failure;

  bool get isLoading => status == BudgetFormStatus.loading;
  bool get isSubmitting => status == BudgetFormStatus.submitting;
  bool get isDeleting => status == BudgetFormStatus.deleting;
  bool get isBusy => isSubmitting || isDeleting;

  /// Categories the picker may still offer: active expense categories not
  /// already on the budget (one allocation per category, FR-017).
  List<Category> get availableCategories {
    final allocated = {for (final draft in allocations) draft.categoryId};
    return [
      for (final category in categories)
        if (!allocated.contains(category.id)) category,
    ];
  }

  /// Sum of every row that currently parses — the live figure the FR-004
  /// hint compares against expected income.
  int get totalPlannedMinorUnits =>
      allocations.fold(0, (sum, draft) => sum + (draft.plannedMinorUnits ?? 0));

  /// FR-004 — shown live, never blocks Save.
  bool get plannedExceedsIncome => budgetPlannedExceedsIncome(
    totalPlannedMinorUnits: totalPlannedMinorUnits,
    expectedIncomeMinorUnits: expectedIncomeMinorUnits,
  );

  /// How far the plan runs past the expected income; `0` when it does not.
  int get excessOverIncomeMinorUnits => plannedExceedsIncome
      ? totalPlannedMinorUnits - expectedIncomeMinorUnits!
      : 0;

  BudgetFormState copyWith({
    BudgetFormStatus? status,
    String? budgetId,
    bool? isEditMode,
    String? incomeInput,
    int? expectedIncomeMinorUnits,
    bool clearExpectedIncome = false,
    int? persistedExpectedIncomeMinorUnits,
    bool clearPersistedExpectedIncome = false,
    BudgetAmountError? incomeError,
    bool clearIncomeError = false,
    List<BudgetAllocationDraft>? allocations,
    List<String>? removedAllocationIds,
    List<Category>? categories,
    bool? isLoadingCategories,
    Currency? currency,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return BudgetFormState(
      month: month,
      idempotencyKey: idempotencyKey,
      status: status ?? this.status,
      budgetId: budgetId ?? this.budgetId,
      isEditMode: isEditMode ?? this.isEditMode,
      incomeInput: incomeInput ?? this.incomeInput,
      expectedIncomeMinorUnits: clearExpectedIncome
          ? null
          : (expectedIncomeMinorUnits ?? this.expectedIncomeMinorUnits),
      persistedExpectedIncomeMinorUnits: clearPersistedExpectedIncome
          ? null
          : (persistedExpectedIncomeMinorUnits ??
                this.persistedExpectedIncomeMinorUnits),
      incomeError: clearIncomeError ? null : (incomeError ?? this.incomeError),
      allocations: allocations ?? this.allocations,
      removedAllocationIds: removedAllocationIds ?? this.removedAllocationIds,
      categories: categories ?? this.categories,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      currency: currency ?? this.currency,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    month,
    idempotencyKey,
    status,
    budgetId,
    isEditMode,
    incomeInput,
    expectedIncomeMinorUnits,
    persistedExpectedIncomeMinorUnits,
    incomeError,
    allocations,
    removedAllocationIds,
    categories,
    isLoadingCategories,
    currency,
    failure,
  ];
}
