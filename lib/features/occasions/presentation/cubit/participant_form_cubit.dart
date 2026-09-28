import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../../currency/domain/usecases/get_primary_currency.dart';
import '../../../people/domain/entities/people_failures.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../people/domain/usecases/create_person.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../domain/entities/occasion_type.dart';
import '../../domain/usecases/add_participant_contribution.dart';
import '../../domain/usecases/edit_participant_contribution.dart';
import 'participant_form_state.dart';

/// Drives the add/edit-contribution form for one participant at an occasion
/// (FR-003/FR-004/FR-010).
///
/// Person selection deliberately reuses 001's search / inline-create /
/// duplicate-warning flow verbatim: a contribution is an ordinary
/// `MoneyTransaction` against an ordinary `Person`, so a second way to pick
/// or create a person would be a second place for the duplicate rules to
/// drift.
@injectable
class ParticipantFormCubit extends Cubit<ParticipantFormState> {
  ParticipantFormCubit(
    this._peopleRepository,
    this._createPerson,
    this._addParticipantContribution,
    this._editParticipantContribution,
    this._egpFormatter,
    this._getPrimaryCurrency,
  ) : super(ParticipantFormState(idempotencyKey: const Uuid().v4()));

  final PeopleRepository _peopleRepository;
  final CreatePerson _createPerson;
  final AddParticipantContribution _addParticipantContribution;
  final EditParticipantContribution _editParticipantContribution;
  final EgpFormatter _egpFormatter;
  final GetPrimaryCurrency _getPrimaryCurrency;

  /// Whether a contribution recorded under [occasionType] should count
  /// toward the person's balance by default: `false` for a condolence,
  /// where the money is not a reciprocal social debt in Egyptian custom,
  /// `true` everywhere else (FR-018).
  static bool defaultCountsTowardBalance(String occasionType) =>
      occasionType != OccasionType.condolence;

  /// Opens the form for a new contribution under [occasionId]. Call once,
  /// right after construction.
  void initialize({required String occasionId, required String occasionType}) {
    emit(
      ParticipantFormState(
        idempotencyKey: state.idempotencyKey,
        occasionId: occasionId,
        occasionType: occasionType,
        countsTowardBalance: defaultCountsTowardBalance(occasionType),
      ),
    );
  }

  /// Switches the form into edit mode, prefilled from [transaction]
  /// (FR-010). The `countsTowardBalance` flag is taken from the row itself
  /// rather than recomputed from [occasionType], because it was captured
  /// when the money was entered and editing must never silently move
  /// somebody's balance (research.md Decision 3).
  void loadForEdit({
    required MoneyTransaction transaction,
    required Person person,
    required String occasionType,
  }) {
    emit(
      ParticipantFormState(
        idempotencyKey: state.idempotencyKey,
        isEditMode: true,
        editingTransactionId: transaction.id,
        occasionId: transaction.occasionId ?? '',
        occasionType: occasionType,
        selectedPerson: person,
        personQuery: person.name,
        amountInput: _egpFormatter.format(transaction.amount),
        currency: transaction.amount.currency,
        direction: transaction.direction,
        date: transaction.date,
        note: transaction.note,
        countsTowardBalance: transaction.countsTowardBalance,
      ),
    );
  }

  /// New contributions default to the primary currency (018 FR-003);
  /// edits keep the row's own currency (set by [loadForEdit]).
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
    emit(state.copyWith(currency: currency, currencyChosenByUser: true));
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
    if (isClosed) return;
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

  /// Attempts to create a new person inline with the currently-typed name,
  /// surfacing 001's possible-duplicate warning instead of inserting when
  /// one is found.
  Future<void> createNewPerson(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final result = await _createPerson(name: trimmed);
    if (isClosed) return;
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
    if (isClosed) return;
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

  /// Overrides the occasion-type default (FR-018) — an explicit user
  /// choice, so it is honored in both directions.
  void countsTowardBalanceChanged(bool value) {
    emit(state.copyWith(countsTowardBalance: value));
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
      // Arabic-Indic and Western digits are equivalent input everywhere an
      // amount is typed (001 FR-023).
      final normalized = NumeralParser.toWesternDigits(state.amountInput);
      final parsed = _egpFormatter.parse(normalized);
      if (!parsed.isPositive) {
        throw const FormatException('Amount must be greater than zero');
      }
      // Every catalog currency has 100 minor units per major (018), so the
      // parsed minor units carry over unchanged.
      amount = Money.fromMinorUnits(parsed.minorUnits, state.currency);
    } on FormatException {
      emit(state.copyWith(amountInvalid: true));
      return;
    }

    emit(
      state.copyWith(
        status: ParticipantFormStatus.submitting,
        clearFailure: true,
      ),
    );

    final note = state.note?.trim();
    final result = state.isEditMode
        ? await _editParticipantContribution(
            transactionId: state.editingTransactionId!,
            amount: amount,
            direction: state.direction,
            date: state.date,
            note: (note?.isEmpty ?? true) ? null : note,
          )
        : await _addParticipantContribution(
            idempotencyKey: state.idempotencyKey,
            occasionId: state.occasionId,
            personId: person.id,
            amount: amount,
            direction: state.direction,
            date: state.date,
            // Always explicit: the toggle the user saw is the value that
            // gets stored, so the repository's own default can never
            // silently disagree with what the form displayed (FR-018).
            countsTowardBalance: state.countsTowardBalance,
            note: (note?.isEmpty ?? true) ? null : note,
          );

    // The form may have been popped while the save was still in flight —
    // the mutation itself already went through exactly once above, but this
    // cubit no longer has a listener to tell, and `emit` after `close()`
    // throws.
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: ParticipantFormStatus.failure, failure: failure),
      ),
      (transaction) => emit(
        state.copyWith(
          // A second contribution from the same open form is a deliberate
          // top-up, not a retry of the one just saved (spec Edge Cases).
          idempotencyKey: const Uuid().v4(),
          status: ParticipantFormStatus.success,
          savedContribution: transaction,
        ),
      ),
    );
  }
}
