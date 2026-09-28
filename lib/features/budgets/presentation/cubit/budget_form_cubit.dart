import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../../currency/domain/usecases/get_primary_currency.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/usecases/get_categories.dart';
import '../../domain/entities/budget_category_line.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/usecases/add_budget_category_allocation.dart';
import '../../domain/usecases/create_budget.dart';
import '../../domain/usecases/delete_budget.dart';
import '../../domain/usecases/edit_budget.dart';
import '../../domain/usecases/edit_budget_category_allocation.dart';
import '../../domain/usecases/get_budget_for_month.dart';
import '../../domain/usecases/remove_budget_category_allocation.dart';
import 'budget_form_state.dart';

/// Drives the create/edit budget form for one month (FR-001–FR-004,
/// FR-010, FR-011, FR-017).
///
/// Opens in create mode for a month with no budget and in edit mode for a
/// month that has one — the same screen either way, so "edit" is never a
/// second, subtly different form.
///
/// Duplicate protection (FR-017) is layered: [submit] ignores a re-entrant
/// call while one is in flight; the budget's idempotency key is generated
/// once when the form opens; and each added row carries its own key, so
/// even a retry after a partially failed save resolves to the rows already
/// written instead of duplicating them.
@injectable
class BudgetFormCubit extends Cubit<BudgetFormState> {
  BudgetFormCubit(
    this._getBudgetForMonth,
    this._createBudget,
    this._editBudget,
    this._deleteBudget,
    this._addAllocation,
    this._editAllocation,
    this._removeAllocation,
    this._getCategories,
    this._egpFormatter,
    this._getPrimaryCurrency,
  ) : super(BudgetFormState(month: '', idempotencyKey: const Uuid().v4()));

  final GetBudgetForMonth _getBudgetForMonth;
  final CreateBudget _createBudget;
  final EditBudget _editBudget;
  final DeleteBudget _deleteBudget;
  final AddBudgetCategoryAllocation _addAllocation;
  final EditBudgetCategoryAllocation _editAllocation;
  final RemoveBudgetCategoryAllocation _removeAllocation;
  final GetCategories _getCategories;
  final EgpFormatter _egpFormatter;
  final GetPrimaryCurrency _getPrimaryCurrency;

  /// Opens the form for [month] (`'YYYY-MM'`): loads the pickable
  /// categories and, when the month already has a budget, prefills from it.
  /// Call once, right after construction.
  Future<void> initialize(String month) async {
    emit(
      BudgetFormState(
        month: month,
        idempotencyKey: state.idempotencyKey,
        isLoadingCategories: true,
      ),
    );

    final results = [
      ...await Future.wait([_loadCategories(), _loadPrimaryCurrency()]),
      // After the primary currency, so an existing budget's own currency
      // wins.
      _applyExistingBudget(await _getBudgetForMonth(month)),
    ];
    if (isClosed) return;
    final failure = results.whereType<Failure>().firstOrNull;
    emit(
      state.copyWith(
        status: failure == null
            ? BudgetFormStatus.editing
            : BudgetFormStatus.failure,
        failure: failure,
      ),
    );
  }

  /// A new budget is planned in the primary currency (018) — what the
  /// repository records it in on create.
  Future<Failure?> _loadPrimaryCurrency() async {
    final result = await _getPrimaryCurrency();
    if (isClosed) return null;
    return result.match((failure) => failure, (setting) {
      emit(state.copyWith(currency: setting.currency));
      return null;
    });
  }

  /// Re-reads the category list — after the user has been to category
  /// management and may have created a new expense category there
  /// (spec US1 scenario 4).
  Future<void> reloadCategories() async {
    emit(state.copyWith(isLoadingCategories: true));
    final failure = await _loadCategories();
    if (isClosed || failure == null) return;
    emit(state.copyWith(status: BudgetFormStatus.failure, failure: failure));
  }

  void expectedIncomeChanged(String text) {
    final parsed = _parse(text, allowEmpty: true);
    emit(
      state.copyWith(
        incomeInput: text,
        expectedIncomeMinorUnits: parsed.minorUnits,
        clearExpectedIncome: parsed.minorUnits == null,
        clearIncomeError: true,
      ),
    );
  }

  /// Adds [categoryId] to the budget as a new row with a blank amount. A
  /// category already on the budget is ignored — one allocation per
  /// category (FR-017).
  void categoryAdded(String categoryId) {
    if (state.allocations.any((draft) => draft.categoryId == categoryId)) {
      return;
    }
    final category = state.categories
        .where((c) => c.id == categoryId)
        .firstOrNull;
    if (category == null) return;

    emit(
      state.copyWith(
        allocations: [
          ...state.allocations,
          BudgetAllocationDraft(
            idempotencyKey: const Uuid().v4(),
            categoryId: category.id,
            categoryName: category.name,
            categoryIcon: category.icon,
          ),
        ],
      ),
    );
  }

  void allocationAmountChanged(String categoryId, String text) {
    final parsed = _parse(text, allowEmpty: false);
    emit(
      state.copyWith(
        allocations: [
          for (final draft in state.allocations)
            if (draft.categoryId == categoryId)
              draft.copyWith(
                amountInput: text,
                plannedMinorUnits: parsed.minorUnits,
                clearPlannedMinorUnits: parsed.minorUnits == null,
                clearAmountError: true,
              )
            else
              draft,
        ],
      ),
    );
  }

  /// Takes a category off the budget (FR-010). A saved allocation is only
  /// queued for removal — nothing is deleted until Save.
  void allocationRemoved(String categoryId) {
    final removed = state.allocations
        .where((draft) => draft.categoryId == categoryId)
        .firstOrNull;
    if (removed == null) return;
    emit(
      state.copyWith(
        allocations: [
          for (final draft in state.allocations)
            if (draft.categoryId != categoryId) draft,
        ],
        removedAllocationIds: [
          ...state.removedAllocationIds,
          if (removed.persistedAllocationId != null)
            removed.persistedAllocationId!,
        ],
      ),
    );
  }

  Future<void> submit() async {
    // A rapid double-tap re-enters before the first call resolves; ignoring
    // it here, not only by disabling the button, is what makes the
    // single-flight guarantee hold before the UI has re-rendered (FR-017).
    if (state.isBusy || state.isLoading) return;
    if (!_validate()) return;

    emit(
      state.copyWith(status: BudgetFormStatus.submitting, clearFailure: true),
    );

    final failure = await _save();
    if (isClosed) return;
    emit(
      failure == null
          ? state.copyWith(status: BudgetFormStatus.success)
          : state.copyWith(status: BudgetFormStatus.failure, failure: failure),
    );
  }

  /// Deletes the whole budget (FR-011). The page shows the confirmation
  /// first; the 007 expense entries are never touched.
  Future<void> deleteBudget() async {
    final budgetId = state.budgetId;
    if (budgetId == null || state.isBusy) return;
    emit(state.copyWith(status: BudgetFormStatus.deleting, clearFailure: true));
    final result = await _deleteBudget(budgetId);
    if (isClosed) return;
    result.match(
      (failure) => emit(
        state.copyWith(status: BudgetFormStatus.failure, failure: failure),
      ),
      (_) => emit(state.copyWith(status: BudgetFormStatus.deleted)),
    );
  }

  /// Flags every field that would be refused, without discarding anything
  /// the user typed. Returns whether the form may be saved.
  bool _validate() {
    var isValid = true;
    final income = _parse(state.incomeInput, allowEmpty: true);
    if (income.error != null) isValid = false;

    final allocations = [
      for (final draft in state.allocations)
        () {
          final parsed = _parse(draft.amountInput, allowEmpty: false);
          if (parsed.error != null) isValid = false;
          return parsed.error == null
              ? draft
              : draft.copyWith(amountError: parsed.error);
        }(),
    ];

    if (!isValid) {
      emit(
        state.copyWith(
          incomeError: income.error,
          clearIncomeError: income.error == null,
          allocations: allocations,
        ),
      );
    }
    return isValid;
  }

  /// Runs the save as a sequence of idempotent steps, recording progress in
  /// state after each one — so if a step fails, a retry picks up where this
  /// attempt stopped instead of repeating what already succeeded.
  Future<Failure?> _save() async {
    // 1. The budget itself.
    var budgetId = state.budgetId;
    if (budgetId == null) {
      final created = await _createBudget(
        idempotencyKey: state.idempotencyKey,
        month: state.month,
        expectedIncomeMinorUnits: state.expectedIncomeMinorUnits,
      );
      switch (created) {
        case Left(value: final failure):
          return failure;
        case Right(value: final budget):
          budgetId = budget.id;
      }
      if (isClosed) return null;
      emit(
        state.copyWith(
          budgetId: budgetId,
          persistedExpectedIncomeMinorUnits: state.expectedIncomeMinorUnits,
          clearPersistedExpectedIncome: state.expectedIncomeMinorUnits == null,
        ),
      );
    } else if (state.expectedIncomeMinorUnits !=
        state.persistedExpectedIncomeMinorUnits) {
      final edited = await _editBudget(
        budgetId: budgetId,
        expectedIncomeMinorUnits: state.expectedIncomeMinorUnits,
      );
      if (edited case Left(value: final failure)) return failure;
      if (isClosed) return null;
      emit(
        state.copyWith(
          persistedExpectedIncomeMinorUnits: state.expectedIncomeMinorUnits,
          clearPersistedExpectedIncome: state.expectedIncomeMinorUnits == null,
        ),
      );
    }

    // 2. Removals first, so a category removed and re-added in the same
    // session never collides with its own old row.
    for (final allocationId in [...state.removedAllocationIds]) {
      final removed = await _removeAllocation(allocationId);
      if (removed case Left(value: final failure)) {
        // Already gone (e.g. removed from another screen) is the outcome
        // the user asked for, not an error.
        if (failure is! NotFoundFailure) return failure;
      }
      if (isClosed) return null;
      emit(
        state.copyWith(
          removedAllocationIds: [
            for (final id in state.removedAllocationIds)
              if (id != allocationId) id,
          ],
        ),
      );
    }

    // 3. Edited and added rows, in the order they are shown.
    for (final draft in [...state.allocations]) {
      final planned = draft.plannedMinorUnits!;
      if (draft.isPersisted) {
        if (!draft.hasUnsavedAmountChange) continue;
        final edited = await _editAllocation(
          allocationId: draft.persistedAllocationId!,
          plannedAmountMinorUnits: planned,
        );
        if (edited case Left(value: final failure)) return failure;
        if (isClosed) return null;
        _markPersisted(draft.categoryId, draft.persistedAllocationId!, planned);
      } else {
        final added = await _addAllocation(
          idempotencyKey: draft.idempotencyKey,
          budgetId: budgetId,
          categoryId: draft.categoryId,
          plannedAmountMinorUnits: planned,
        );
        switch (added) {
          case Left(value: final failure):
            return failure;
          case Right(value: final allocation):
            if (isClosed) return null;
            _markPersisted(draft.categoryId, allocation.id, planned);
        }
      }
    }
    return null;
  }

  void _markPersisted(String categoryId, String allocationId, int planned) {
    emit(
      state.copyWith(
        allocations: [
          for (final draft in state.allocations)
            if (draft.categoryId == categoryId)
              draft.copyWith(
                persistedAllocationId: allocationId,
                persistedPlannedMinorUnits: planned,
              )
            else
              draft,
        ],
      ),
    );
  }

  /// Returns the failure, if any, rather than emitting it — [initialize]
  /// runs this alongside the budget read and settles the status once.
  Future<Failure?> _loadCategories() async {
    // Expense only (spec Assumptions: income is never budgeted), active
    // only (FR-021) — `GetCategories` defaults to `includeArchived: false`.
    final result = await _getCategories(type: CategoryType.expense);
    if (isClosed) return null;
    return result.match(
      (failure) {
        emit(state.copyWith(isLoadingCategories: false));
        return failure;
      },
      (categories) {
        emit(
          state.copyWith(categories: categories, isLoadingCategories: false),
        );
        return null;
      },
    );
  }

  Failure? _applyExistingBudget(Either<Failure, BudgetMonthDetail> result) {
    if (isClosed) return null;
    return result.match((failure) => failure, (detail) {
      final budget = detail.budget;
      if (budget == null) return null;
      final income = budget.expectedIncomeMinorUnits;
      emit(
        state.copyWith(
          budgetId: budget.id,
          isEditMode: true,
          currency: budget.currency,
          incomeInput: income == null
              ? ''
              : _egpFormatter.format(
                  Money.fromMinorUnits(income, budget.currency),
                ),
          expectedIncomeMinorUnits: income,
          persistedExpectedIncomeMinorUnits: income,
          allocations: [
            for (final line
                in detail.summary?.categoryBreakdown ??
                    const <BudgetCategoryLine>[])
              BudgetAllocationDraft(
                // A saved row is never re-added, so its key is never used;
                // the allocation id keeps it unique and stable.
                idempotencyKey: line.allocationId,
                categoryId: line.categoryId,
                categoryName: line.categoryName,
                categoryIcon: line.categoryIcon,
                isCategoryArchived: line.isCategoryArchived,
                amountInput: _egpFormatter.format(line.plannedAmount),
                plannedMinorUnits: line.plannedAmountMinorUnits,
                persistedAllocationId: line.allocationId,
                persistedPlannedMinorUnits: line.plannedAmountMinorUnits,
              ),
          ],
        ),
      );
      return null;
    });
  }

  /// Parses a typed amount into exact minor units. Arabic-Indic digits are
  /// accepted (normalized first); zero is accepted, a negative is refused
  /// (FR-002). Only a non-negative, parseable value is ever returned as
  /// [_Parsed.minorUnits], so a half-typed or refused figure never leaks
  /// into the running total.
  _Parsed _parse(String input, {required bool allowEmpty}) {
    if (input.trim().isEmpty) {
      return allowEmpty
          ? const _Parsed()
          : const _Parsed(error: BudgetAmountError.required);
    }
    try {
      final money = _egpFormatter.parse(NumeralParser.toWesternDigits(input));
      if (money.isNegative) {
        return const _Parsed(error: BudgetAmountError.negative);
      }
      return _Parsed(minorUnits: money.minorUnits);
    } on FormatException {
      return const _Parsed(error: BudgetAmountError.invalid);
    }
  }
}

class _Parsed {
  const _Parsed({this.minorUnits, this.error});

  final int? minorUnits;
  final BudgetAmountError? error;
}
