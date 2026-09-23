import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../people/domain/entities/person.dart';
import '../../../transactions/domain/entities/money_transaction.dart';

enum ParticipantFormStatus { editing, submitting, success, failure }

/// Immutable state for [ParticipantFormCubit] (constitution Principle IV —
/// updated exclusively via [copyWith]).
class ParticipantFormState extends Equatable {
  ParticipantFormState({
    required this.idempotencyKey,
    this.status = ParticipantFormStatus.editing,
    this.isEditMode = false,
    this.editingTransactionId,
    this.occasionId = '',
    this.occasionType = '',
    this.selectedPerson,
    this.personQuery = '',
    this.personSearchResults = const [],
    this.duplicateMatches = const [],
    this.pendingPersonName,
    this.amountInput = '',
    this.direction = TransactionDirection.received,
    DateTime? date,
    this.note,
    this.countsTowardBalance = true,
    this.amountInvalid = false,
    this.personSelectionRequired = false,
    this.personFailure,
    this.failure,
    this.savedContribution,
  }) : date = date ?? DateTime.now();

  /// Generated once when the form opens and regenerated after a successful
  /// save, so a retried save resolves to the same contribution (FR-019)
  /// while a deliberate second entry for the same person — an initial gift
  /// plus a later top-up (spec Edge Cases) — is never swallowed as a retry.
  final String idempotencyKey;
  final ParticipantFormStatus status;
  final bool isEditMode;
  final String? editingTransactionId;

  /// The parent occasion this contribution belongs to (FR-005).
  final String occasionId;

  /// The parent occasion's type, held because it decides
  /// [countsTowardBalance]'s default (FR-018).
  final String occasionType;
  final Person? selectedPerson;
  final String personQuery;
  final List<Person> personSearchResults;

  /// Possible-duplicate matches surfaced after attempting to create a new
  /// person inline — the very same 001 flow, reused rather than reinvented
  /// (FR-003 of 001).
  final List<Person> duplicateMatches;

  /// The name typed for a not-yet-created person, held while the duplicate
  /// warning is awaiting the user's decision.
  final String? pendingPersonName;
  final String amountInput;
  final TransactionDirection direction;
  final DateTime date;
  final String? note;

  /// Whether this contribution feeds the person's overall balance.
  /// Pre-set to `false` under a condolence occasion, `true` everywhere
  /// else, and freely overridable by the user either way (FR-018).
  final bool countsTowardBalance;

  /// Set by this cubit's own client-side "amount must be > 0" check — a
  /// flag rather than a message so the page renders it through `l10n`
  /// regardless of locale.
  final bool amountInvalid;

  /// Set by this cubit's own client-side "a person must be selected" check
  /// — same localization rationale as [amountInvalid].
  final bool personSelectionRequired;

  /// A typed failure from the person search / inline-create path, kept
  /// separate from [failure] so a people problem never reads as a failed
  /// save.
  final Failure? personFailure;
  final Failure? failure;
  final MoneyTransaction? savedContribution;

  bool get isSubmitting => status == ParticipantFormStatus.submitting;
  bool get isSuccess => status == ParticipantFormStatus.success;

  ParticipantFormState copyWith({
    String? idempotencyKey,
    ParticipantFormStatus? status,
    Person? selectedPerson,
    bool clearSelectedPerson = false,
    String? personQuery,
    List<Person>? personSearchResults,
    List<Person>? duplicateMatches,
    String? pendingPersonName,
    bool clearPendingPersonName = false,
    String? amountInput,
    TransactionDirection? direction,
    DateTime? date,
    String? note,
    bool? countsTowardBalance,
    bool? amountInvalid,
    bool clearAmountError = false,
    bool? personSelectionRequired,
    Failure? personFailure,
    bool clearPersonError = false,
    Failure? failure,
    bool clearFailure = false,
    MoneyTransaction? savedContribution,
  }) {
    return ParticipantFormState(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      isEditMode: isEditMode,
      editingTransactionId: editingTransactionId,
      occasionId: occasionId,
      occasionType: occasionType,
      selectedPerson: clearSelectedPerson
          ? null
          : (selectedPerson ?? this.selectedPerson),
      personQuery: personQuery ?? this.personQuery,
      personSearchResults: personSearchResults ?? this.personSearchResults,
      duplicateMatches: duplicateMatches ?? this.duplicateMatches,
      pendingPersonName: clearPendingPersonName
          ? null
          : (pendingPersonName ?? this.pendingPersonName),
      amountInput: amountInput ?? this.amountInput,
      direction: direction ?? this.direction,
      date: date ?? this.date,
      note: note ?? this.note,
      countsTowardBalance: countsTowardBalance ?? this.countsTowardBalance,
      amountInvalid: clearAmountError
          ? false
          : (amountInvalid ?? this.amountInvalid),
      personSelectionRequired: clearPersonError
          ? false
          : (personSelectionRequired ?? this.personSelectionRequired),
      personFailure: clearPersonError
          ? null
          : (personFailure ?? this.personFailure),
      failure: clearFailure ? null : (failure ?? this.failure),
      savedContribution: savedContribution ?? this.savedContribution,
    );
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    status,
    isEditMode,
    editingTransactionId,
    occasionId,
    occasionType,
    selectedPerson,
    personQuery,
    personSearchResults,
    duplicateMatches,
    pendingPersonName,
    amountInput,
    direction,
    date,
    note,
    countsTowardBalance,
    amountInvalid,
    personSelectionRequired,
    personFailure,
    failure,
    savedContribution,
  ];
}
