import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';
import '../../../people/domain/entities/person.dart';
import '../../domain/entities/money_transaction.dart';

enum TransactionFormStatus { editing, submitting, success, failure }

/// Immutable state for [TransactionFormCubit] (constitution Principle IV —
/// updated exclusively via [copyWith]).
class TransactionFormState extends Equatable {
  TransactionFormState({
    required this.idempotencyKey,
    this.status = TransactionFormStatus.editing,
    this.isEditMode = false,
    this.editingTransactionId,
    this.selectedPerson,
    this.personQuery = '',
    this.personSearchResults = const [],
    this.duplicateMatches = const [],
    this.pendingPersonName,
    this.direction = TransactionDirection.given,
    this.kind = TransactionKind.initialExchange,
    DateTime? date,
    this.amountInput = '',
    this.currency = Currency.egp,
    this.currencyChosenByUser = false,
    this.note,
    this.amountErrorMessage,
    this.amountInvalid = false,
    this.personErrorMessage,
    this.personSelectionRequired = false,
    this.errorMessage,
    this.savedTransaction,
  }) : date = date ?? DateTime.now();

  final String idempotencyKey;
  final TransactionFormStatus status;
  final bool isEditMode;
  final String? editingTransactionId;
  final Person? selectedPerson;
  final String personQuery;
  final List<Person> personSearchResults;

  /// Possible-duplicate matches surfaced after attempting to create a new
  /// person inline (FR-003) — shown via `DuplicateWarningSheet`.
  final List<Person> duplicateMatches;

  /// The name typed for a not-yet-created person, held while the duplicate
  /// warning sheet is awaiting the user's decision.
  final String? pendingPersonName;
  final TransactionDirection direction;

  /// Fixed at creation and shown read-only in edit mode — there is no code
  /// path that lets an edit change it (Clarifications, T100).
  final TransactionKind kind;
  final DateTime date;
  final String amountInput;

  /// The currency the amount is entered and stored in (018 FR-001). Starts
  /// as a placeholder and is replaced by the primary currency once
  /// `TransactionFormCubit.loadDefaultCurrency` resolves (FR-003); in edit
  /// mode it is the record's own currency.
  final Currency currency;

  /// True once the user picked a currency themselves, so a late-arriving
  /// primary-currency default never overwrites their choice.
  final bool currencyChosenByUser;
  final String? note;

  /// Set by a repository call (e.g. a search failure); already carries the
  /// repository's own message text.
  final String? amountErrorMessage;

  /// Set by this cubit's own client-side "amount must be > 0" check
  /// (FR-005) — a flag rather than a message so the page can render it via
  /// `l10n.amountInvalidError` regardless of locale (T105).
  final bool amountInvalid;
  final String? personErrorMessage;

  /// Set by this cubit's own client-side "a person must be selected" check
  /// — same localization rationale as [amountInvalid].
  final bool personSelectionRequired;
  final String? errorMessage;
  final MoneyTransaction? savedTransaction;

  bool get isSubmitting => status == TransactionFormStatus.submitting;
  bool get isSuccess => status == TransactionFormStatus.success;

  TransactionFormState copyWith({
    TransactionFormStatus? status,
    Person? selectedPerson,
    bool clearSelectedPerson = false,
    String? personQuery,
    List<Person>? personSearchResults,
    List<Person>? duplicateMatches,
    String? pendingPersonName,
    bool clearPendingPersonName = false,
    TransactionDirection? direction,
    DateTime? date,
    String? amountInput,
    Currency? currency,
    bool? currencyChosenByUser,
    String? note,
    String? amountErrorMessage,
    bool? amountInvalid,
    bool clearAmountError = false,
    String? personErrorMessage,
    bool? personSelectionRequired,
    bool clearPersonError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    MoneyTransaction? savedTransaction,
  }) {
    return TransactionFormState(
      idempotencyKey: idempotencyKey,
      status: status ?? this.status,
      isEditMode: isEditMode,
      editingTransactionId: editingTransactionId,
      selectedPerson: clearSelectedPerson
          ? null
          : (selectedPerson ?? this.selectedPerson),
      personQuery: personQuery ?? this.personQuery,
      personSearchResults: personSearchResults ?? this.personSearchResults,
      duplicateMatches: duplicateMatches ?? this.duplicateMatches,
      pendingPersonName: clearPendingPersonName
          ? null
          : (pendingPersonName ?? this.pendingPersonName),
      direction: direction ?? this.direction,
      kind: kind,
      date: date ?? this.date,
      amountInput: amountInput ?? this.amountInput,
      currency: currency ?? this.currency,
      currencyChosenByUser: currencyChosenByUser ?? this.currencyChosenByUser,
      note: note ?? this.note,
      amountErrorMessage: clearAmountError
          ? null
          : (amountErrorMessage ?? this.amountErrorMessage),
      amountInvalid: clearAmountError
          ? false
          : (amountInvalid ?? this.amountInvalid),
      personErrorMessage: clearPersonError
          ? null
          : (personErrorMessage ?? this.personErrorMessage),
      personSelectionRequired: clearPersonError
          ? false
          : (personSelectionRequired ?? this.personSelectionRequired),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      savedTransaction: savedTransaction ?? this.savedTransaction,
    );
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    status,
    isEditMode,
    editingTransactionId,
    selectedPerson,
    personQuery,
    personSearchResults,
    duplicateMatches,
    pendingPersonName,
    direction,
    kind,
    date,
    amountInput,
    currency,
    currencyChosenByUser,
    note,
    amountErrorMessage,
    amountInvalid,
    personErrorMessage,
    personSelectionRequired,
    errorMessage,
    savedTransaction,
  ];
}
