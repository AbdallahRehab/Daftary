import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../../currency/domain/usecases/get_primary_currency.dart';
import '../../../people/domain/entities/people_failures.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../people/domain/usecases/create_person.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/edit_transaction.dart';
import 'transaction_form_state.dart';

/// Drives the record/edit-transaction form. A fresh idempotency key is
/// generated the moment the cubit is created (i.e. when the form opens),
/// and `submit()` ignores a re-entrant call while already submitting — the
/// combination that guarantees FR-020/SC-006 even under a rapid double-tap.
@injectable
class TransactionFormCubit extends Cubit<TransactionFormState> {
  TransactionFormCubit(
    this._peopleRepository,
    this._createPerson,
    this._addTransaction,
    this._editTransaction,
    this._getPrimaryCurrency,
  ) : super(TransactionFormState(idempotencyKey: const Uuid().v4()));

  final PeopleRepository _peopleRepository;
  final CreatePerson _createPerson;
  final AddTransaction _addTransaction;
  final EditTransaction _editTransaction;
  final GetPrimaryCurrency _getPrimaryCurrency;

  /// Defaults the currency picker to the current primary currency (018
  /// FR-003) — never a hardcoded EGP. A no-op in edit mode (the record
  /// keeps its own currency) or once the user has picked a currency.
  Future<void> loadDefaultCurrency() async {
    if (state.isEditMode || state.currencyChosenByUser) return;
    final result = await _getPrimaryCurrency();
    if (isClosed || state.isEditMode || state.currencyChosenByUser) return;
    result.match(
      // A failed read leaves the placeholder default in place; the user can
      // still pick any currency explicitly.
      (_) {},
      (setting) => emit(state.copyWith(currency: setting.currency)),
    );
  }

  void currencyChanged(Currency currency) {
    emit(
      state.copyWith(
        currency: currency,
        currencyChosenByUser: true,
        clearAmountError: true,
      ),
    );
  }

  /// Pre-binds the form to an already-known person (e.g. opened from that
  /// person's own detail page), skipping the picker entirely.
  Future<void> initializeWithPerson(String personId) async {
    final result = await _peopleRepository.getPersonById(personId);
    result.match(
      (failure) => emit(state.copyWith(personFailure: failure)),
      selectExistingPerson,
    );
  }

  /// Switches the form into edit mode, prefilled from [transaction] (T100 —
  /// US6). Call once, right after construction.
  void loadForEdit(MoneyTransaction transaction, Person person) {
    emit(
      TransactionFormState(
        idempotencyKey: state.idempotencyKey,
        isEditMode: true,
        editingTransactionId: transaction.id,
        selectedPerson: person,
        personQuery: person.name,
        direction: transaction.direction,
        kind: transaction.kind,
        date: transaction.date,
        amountInput: CurrencyFormatter(
          currency: transaction.amount.currency,
        ).format(transaction.amount),
        currency: transaction.amount.currency,
        note: transaction.note,
      ),
    );
  }

  Future<void> onPersonQueryChanged(String query) async {
    emit(
      state.copyWith(
        personQuery: query,
        clearPersonError: true,
        clearSelectedPerson: state.selectedPerson?.name != query,
      ),
    );
    if (query.trim().isEmpty) {
      emit(state.copyWith(personSearchResults: const []));
      return;
    }
    final result = await _peopleRepository.searchActivePeople(nameQuery: query);
    result.match(
      (failure) => emit(state.copyWith(personFailure: failure)),
      (people) => emit(state.copyWith(personSearchResults: people)),
    );
  }

  void selectExistingPerson(Person person) {
    emit(
      state.copyWith(
        selectedPerson: person,
        personQuery: person.name,
        personSearchResults: const [],
        clearPersonError: true,
      ),
    );
  }

  /// Attempts to create a new person inline with the currently-typed name
  /// (FR-002). Surfaces a possible-duplicate warning instead of inserting
  /// when one is found (FR-003).
  Future<void> createNewPerson(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final result = await _createPerson(name: trimmed);
    result.match((failure) {
      if (failure is PossibleDuplicateFailure) {
        emit(
          state.copyWith(
            duplicateMatches: failure.matches,
            pendingPersonName: trimmed,
          ),
        );
      } else {
        emit(state.copyWith(personFailure: failure));
      }
    }, selectExistingPerson);
  }

  void pickDuplicateMatch(Person person) {
    selectExistingPerson(person);
    emit(
      state.copyWith(duplicateMatches: const [], clearPendingPersonName: true),
    );
  }

  /// The user explicitly confirmed the pending name is a distinct new
  /// person despite the duplicate warning — never a silent auto-merge.
  Future<void> confirmCreateDespitePendingDuplicate() async {
    final name = state.pendingPersonName;
    if (name == null) return;
    final result = await _peopleRepository.confirmCreateDespiteDuplicate(
      name: name,
    );
    result.match((failure) => emit(state.copyWith(personFailure: failure)), (
      person,
    ) {
      selectExistingPerson(person);
      emit(
        state.copyWith(
          duplicateMatches: const [],
          clearPendingPersonName: true,
        ),
      );
    });
  }

  void dismissDuplicateWarning() {
    emit(
      state.copyWith(duplicateMatches: const [], clearPendingPersonName: true),
    );
  }

  void amountChanged(String text) {
    emit(state.copyWith(amountInput: text, clearAmountError: true));
  }

  void directionChanged(TransactionDirection direction) {
    emit(state.copyWith(direction: direction));
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

    final person = state.selectedPerson;
    if (person == null) {
      emit(state.copyWith(personSelectionRequired: true));
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
        status: TransactionFormStatus.submitting,
        clearFailure: true,
      ),
    );

    final result = state.isEditMode
        ? await _editTransaction(
            transactionId: state.editingTransactionId!,
            amount: amount,
            direction: state.direction,
            date: state.date,
            note: state.note,
          )
        : await _addTransaction(
            idempotencyKey: state.idempotencyKey,
            personId: person.id,
            amount: amount,
            direction: state.direction,
            date: state.date,
            note: state.note,
          );

    // The form may have been popped (e.g. the user navigated away) while
    // the save was still in flight — the mutation itself already went
    // through exactly once above, so there is nothing to lose, but this
    // cubit no longer has a listener to tell, and `emit` after `close()`
    // throws.
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: TransactionFormStatus.failure, failure: failure),
      ),
      (transaction) => emit(
        state.copyWith(
          status: TransactionFormStatus.success,
          savedTransaction: transaction,
        ),
      ),
    );
  }
}
