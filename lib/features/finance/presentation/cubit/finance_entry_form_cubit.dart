import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../../currency/domain/usecases/get_primary_currency.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/usecases/add_finance_entry.dart';
import '../../domain/usecases/edit_finance_entry.dart';
import '../../domain/usecases/get_categories.dart';
import 'finance_entry_form_state.dart';

/// Drives the add/edit income-or-expense form (FR-001/FR-002/FR-019).
///
/// A fresh idempotency key is generated the moment the cubit is created
/// (i.e. when the form opens), and `submit()` ignores a re-entrant call
/// while one is already in flight — together that is what guarantees a
/// rapid double-tap records exactly one entry (FR-021).
@injectable
class FinanceEntryFormCubit extends Cubit<FinanceEntryFormState> {
  FinanceEntryFormCubit(
    this._addFinanceEntry,
    this._editFinanceEntry,
    this._getCategories,
    this._egpFormatter,
    this._getPrimaryCurrency,
  ) : super(FinanceEntryFormState(idempotencyKey: const Uuid().v4()));

  final AddFinanceEntry _addFinanceEntry;
  final EditFinanceEntry _editFinanceEntry;
  final GetCategories _getCategories;
  final EgpFormatter _egpFormatter;
  final GetPrimaryCurrency _getPrimaryCurrency;

  /// Opens the form for a new entry of [type], defaults the currency to the
  /// user's primary currency (018 FR-003), and loads that direction's
  /// active categories. Call once, right after construction.
  Future<void> initialize({required FinanceEntryType type}) async {
    emit(
      state.copyWith(
        type: type,
        isLoadingCategories: true,
        clearErrorMessage: true,
      ),
    );
    await _loadPrimaryCurrency();
    await _loadCategories(type);
  }

  /// The user picked a different currency for this entry (018 FR-001).
  void currencyChanged(Currency currency) {
    emit(state.copyWith(currency: currency, clearAmountError: true));
  }

  /// Swaps the form between income and expense (T031). The category set is
  /// reloaded for the new direction, and any category selected under the
  /// old one is dropped — it cannot belong to both.
  Future<void> typeChanged(FinanceEntryType type) async {
    if (type == state.type) return;
    emit(
      state.copyWith(
        type: type,
        isLoadingCategories: true,
        clearSelectedCategory: true,
        clearCategoryError: true,
      ),
    );
    await _loadCategories(type);
  }

  /// Switches the form into edit mode, prefilled from [entry] (T071 — US5).
  ///
  /// [category] is the entry's own category, passed in already resolved: it
  /// is appended to the loaded (active-only) set when it has since been
  /// archived, so the entry keeps displaying — and keeps — the category it
  /// was recorded against (FR-011), without that archived category leaking
  /// into the picker for any other entry.
  Future<void> loadForEdit(FinanceEntry entry, Category category) async {
    emit(
      FinanceEntryFormState(
        idempotencyKey: state.idempotencyKey,
        type: entry.type,
        isEditMode: true,
        editingEntryId: entry.id,
        isEdited: entry.isEdited,
        isLoadingCategories: true,
        selectedCategoryId: entry.categoryId,
        // An edit keeps the entry's own currency (018 FR-002) — never the
        // current primary currency.
        currency: entry.amount.currency,
        date: entry.date,
        amountInput: _egpFormatter.format(entry.amount),
        note: entry.note,
      ),
    );
    await _loadCategories(entry.type, alwaysSelectable: category);
  }

  void amountChanged(String text) {
    emit(state.copyWith(amountInput: text, clearAmountError: true));
  }

  void categorySelected(String categoryId) {
    emit(
      state.copyWith(selectedCategoryId: categoryId, clearCategoryError: true),
    );
  }

  void dateChanged(DateTime date) {
    emit(state.copyWith(date: date));
  }

  void noteChanged(String note) {
    emit(state.copyWith(note: note));
  }

  Future<void> submit() async {
    // A rapid double-tap re-enters here before the first call resolves;
    // ignoring it (rather than re-invoking the use case) is what makes the
    // single-flight guarantee hold even before the UI has re-rendered.
    if (state.isSubmitting) return;

    // Both validations emit a flag and return without touching the rest of
    // the state, so nothing the user already typed is discarded (FR-003).
    final categoryId = state.selectedCategoryId;
    if (categoryId == null) {
      emit(state.copyWith(categorySelectionRequired: true));
      return;
    }

    final Money amount;
    try {
      final normalized = NumeralParser.toWesternDigits(state.amountInput);
      final parsed = CurrencyFormatter(
        currency: state.currency,
      ).parse(normalized);
      if (!parsed.isPositive) {
        throw const FormatException('Amount must be greater than zero');
      }
      amount = parsed;
    } on FormatException {
      emit(state.copyWith(amountInvalid: true));
      return;
    }

    emit(
      state.copyWith(
        status: FinanceEntryFormStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    final result = state.isEditMode
        ? await _editFinanceEntry(
            entryId: state.editingEntryId!,
            categoryId: categoryId,
            amount: amount,
            date: state.date,
            note: state.note,
          )
        : await _addFinanceEntry(
            idempotencyKey: state.idempotencyKey,
            categoryId: categoryId,
            type: state.type,
            amount: amount,
            date: state.date,
            note: state.note,
          );

    // The form may have been popped while the save was still in flight —
    // the mutation itself already went through exactly once above, but this
    // cubit no longer has a listener to tell, and `emit` after `close()`
    // throws.
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(
          status: FinanceEntryFormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (entry) => emit(
        state.copyWith(
          status: FinanceEntryFormStatus.success,
          savedEntry: entry,
        ),
      ),
    );
  }

  /// A failed read leaves the placeholder default in place rather than
  /// blocking the form: the picker is still there for the user to choose.
  Future<void> _loadPrimaryCurrency() async {
    final result = await _getPrimaryCurrency();
    if (isClosed) return;
    result.match(
      (_) {},
      (setting) => emit(state.copyWith(currency: setting.currency)),
    );
  }

  Future<void> _loadCategories(
    FinanceEntryType type, {
    Category? alwaysSelectable,
  }) async {
    // Archived categories are excluded (FR-011) — `GetCategories` defaults
    // to `includeArchived: false`.
    final result = await _getCategories(type: type);
    if (isClosed) return;
    result.match(
      (failure) => emit(
        state.copyWith(
          isLoadingCategories: false,
          errorMessage: failure.message,
        ),
      ),
      (categories) {
        final selectable = [...categories];
        if (alwaysSelectable != null &&
            !selectable.any((c) => c.id == alwaysSelectable.id)) {
          selectable.add(alwaysSelectable);
        }
        final selectedId = state.selectedCategoryId;
        final stillSelectable =
            selectedId != null && selectable.any((c) => c.id == selectedId);
        emit(
          state.copyWith(
            categories: selectable,
            isLoadingCategories: false,
            clearSelectedCategory: !stillSelectable,
          ),
        );
      },
    );
  }
}
