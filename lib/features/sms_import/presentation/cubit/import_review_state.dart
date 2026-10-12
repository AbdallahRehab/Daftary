import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/category.dart';
import '../../../people/domain/entities/person.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_value_types.dart';

/// The review screen's phases (ui-contract §3.4).
enum ImportReviewStatus {
  initial,
  loading,
  ready,

  /// Not found, or no longer pending (added, ignored, expired elsewhere).
  alreadyHandled,
  loadFailure,
  submitting,
  success,

  /// "It's the same, don't add" closed the item (FR-061); nothing added.
  closedAsDuplicate,

  /// Ignore closed the item (FR-064, T132); nothing added.
  ignored,

  /// "Stop suggesting from this sender" removed the item with the
  /// sender's other pending items (FR-065, T132); nothing added.
  senderMuted,
}

/// The "Show original message" section (FR-045).
enum OriginalSection { collapsed, loading, shown, unavailable }

/// Immutable state of `ImportReviewCubit` (T078). The draft is a value
/// object; nothing here is ever persisted (FR-047).
class ImportReviewState extends Equatable {
  ImportReviewState({
    this.status = ImportReviewStatus.initial,
    this.pendingId = '',
    this.item,
    this.draft,
    this.initialDraft,
    this.amountInput = '',
    List<Category> categories = const [],
    this.categoriesLoading = false,
    this.personQuery = '',
    List<Person> personResults = const [],
    this.selectedPerson,
    List<Person> personDuplicateMatches = const [],
    this.pendingPersonName,
    this.finding,
    this.duplicateRequest,
    this.duplicatePending,
    this.parent,
    this.originalSection = OriginalSection.collapsed,
    this.original,
    this.requiresDiscardConfirmation = false,
    this.leaveApproved = false,
    this.failure,
    this.nextImportId,
    this.mutedRemovedCount = 0,
    List<Person> similarPeople = const [],
    this.countCashWithdrawals,
  }) : categories = List.unmodifiable(categories),
       personResults = List.unmodifiable(personResults),
       personDuplicateMatches = List.unmodifiable(personDuplicateMatches),
       similarPeople = List.unmodifiable(similarPeople);

  final ImportReviewStatus status;
  final String pendingId;

  /// The pending item as loaded; read-only context for the header.
  final PendingSmsImport? item;

  /// The user's current edits.
  final ReviewDraft? draft;

  /// The draft as first built from the item, to detect unsaved edits.
  final ReviewDraft? initialDraft;

  /// The amount field's text, as typed (Arabic-Indic digits allowed).
  final String amountInput;

  /// Active categories of the draft's type (FR-055).
  final List<Category> categories;
  final bool categoriesLoading;

  final String personQuery;
  final List<Person> personResults;
  final Person? selectedPerson;

  /// The existing similar-name choice (FR-054): set when creating a person
  /// whose name looks like an existing one.
  final List<Person> personDuplicateMatches;
  final String? pendingPersonName;

  /// The latest `CheckDuplicates` result on the draft's current values.
  final DuplicateFinding? finding;

  /// One-shot: Add found a probable duplicate; the page shows the choice
  /// and calls `consumeDuplicateRequest`.
  final DuplicateFinding? duplicateRequest;

  /// The other pending item of a probable pending-pair finding, for the
  /// side-by-side card (FR-059 tier 4, pending pair).
  final PendingSmsImport? duplicatePending;

  /// The parent message of a split fee item, while it is still pending
  /// (FR-030a).
  final PendingSmsImport? parent;

  final OriginalSection originalSection;

  /// The masked original, only while shown; dropped on collapse or leave.
  final OriginalMessage? original;

  /// One-shot: leaving with edits needs the discard prompt (FR-047).
  final bool requiresDiscardConfirmation;

  /// One-shot: the user confirmed leaving; the page pops.
  final bool leaveApproved;

  /// The last Add failure (the item is still pending, FR-099).
  final Failure? failure;

  /// After a successful Add: the next pending item to review, if any
  /// (FR-046).
  final String? nextImportId;

  /// After "Stop suggesting from this sender": how many pending items of
  /// that sender were removed (this one included).
  final int mutedRemovedCount;

  /// A named transfer that more than one existing person could match
  /// (FR-054): the people of the similar-name choice. Empty otherwise.
  final List<Person> similarPeople;

  /// The current "count cash withdrawals as spending" preference
  /// (FR-051b), or `null` when unknown.
  final bool? countCashWithdrawals;

  /// The suggestion shown for the item: an ATM withdrawal follows the
  /// current cash preference; anything else keeps its parsed suggestion.
  SuggestedRecordType? get suggestedType {
    final item = this.item;
    return item == null ? null : suggestionFor(item, countCashWithdrawals);
  }

  /// The suggestion for [item]: an ATM withdrawal follows the cash
  /// preference [countCash] (Expense when on, Ignore when off, FR-051a/b);
  /// with an unknown preference, and for every other item, the parsed
  /// suggestion stays.
  static SuggestedRecordType suggestionFor(
    PendingSmsImport item,
    bool? countCash,
  ) {
    if (item.kind != SmsKind.atmWithdrawal || countCash == null) {
      return item.suggestedType;
    }
    return countCash ? SuggestedRecordType.expense : SuggestedRecordType.ignore;
  }

  bool get isSubmitting => status == ImportReviewStatus.submitting;

  /// The item was decided on this screen or elsewhere; nothing to edit.
  bool get isSettled =>
      status == ImportReviewStatus.success ||
      status == ImportReviewStatus.closedAsDuplicate ||
      status == ImportReviewStatus.ignored ||
      status == ImportReviewStatus.senderMuted ||
      status == ImportReviewStatus.alreadyHandled ||
      status == ImportReviewStatus.loadFailure;

  /// Every required field that blocks Add (FR-043a), from the domain rule.
  Set<ReviewField> get missing => draft?.validate() ?? const {};

  /// Add is enabled only when nothing is missing (FR-046).
  bool get canAdd =>
      status == ImportReviewStatus.ready && draft != null && missing.isEmpty;

  /// Whether the user changed anything since the item was opened.
  bool get isDirty => draft != null && draft != initialDraft;

  ImportReviewState copyWith({
    ImportReviewStatus? status,
    String? pendingId,
    PendingSmsImport? item,
    ReviewDraft? draft,
    ReviewDraft? initialDraft,
    String? amountInput,
    List<Category>? categories,
    bool? categoriesLoading,
    String? personQuery,
    List<Person>? personResults,
    Person? selectedPerson,
    bool clearSelectedPerson = false,
    List<Person>? personDuplicateMatches,
    String? pendingPersonName,
    bool clearPendingPersonName = false,
    DuplicateFinding? finding,
    bool clearFinding = false,
    DuplicateFinding? duplicateRequest,
    bool clearDuplicateRequest = false,
    PendingSmsImport? duplicatePending,
    bool clearDuplicatePending = false,
    PendingSmsImport? parent,
    OriginalSection? originalSection,
    OriginalMessage? original,
    bool clearOriginal = false,
    bool? requiresDiscardConfirmation,
    bool? leaveApproved,
    Failure? failure,
    bool clearFailure = false,
    String? nextImportId,
    int? mutedRemovedCount,
    List<Person>? similarPeople,
    bool? countCashWithdrawals,
    bool clearCountCash = false,
  }) {
    return ImportReviewState(
      status: status ?? this.status,
      pendingId: pendingId ?? this.pendingId,
      item: item ?? this.item,
      draft: draft ?? this.draft,
      initialDraft: initialDraft ?? this.initialDraft,
      amountInput: amountInput ?? this.amountInput,
      categories: categories ?? this.categories,
      categoriesLoading: categoriesLoading ?? this.categoriesLoading,
      personQuery: personQuery ?? this.personQuery,
      personResults: personResults ?? this.personResults,
      selectedPerson: clearSelectedPerson
          ? null
          : (selectedPerson ?? this.selectedPerson),
      personDuplicateMatches:
          personDuplicateMatches ?? this.personDuplicateMatches,
      pendingPersonName: clearPendingPersonName
          ? null
          : (pendingPersonName ?? this.pendingPersonName),
      finding: clearFinding ? null : (finding ?? this.finding),
      duplicateRequest: clearDuplicateRequest
          ? null
          : (duplicateRequest ?? this.duplicateRequest),
      duplicatePending: clearDuplicatePending
          ? null
          : (duplicatePending ?? this.duplicatePending),
      parent: parent ?? this.parent,
      originalSection: originalSection ?? this.originalSection,
      original: clearOriginal ? null : (original ?? this.original),
      requiresDiscardConfirmation:
          requiresDiscardConfirmation ?? this.requiresDiscardConfirmation,
      leaveApproved: leaveApproved ?? this.leaveApproved,
      failure: clearFailure ? null : (failure ?? this.failure),
      nextImportId: nextImportId ?? this.nextImportId,
      mutedRemovedCount: mutedRemovedCount ?? this.mutedRemovedCount,
      similarPeople: similarPeople ?? this.similarPeople,
      countCashWithdrawals: clearCountCash
          ? null
          : (countCashWithdrawals ?? this.countCashWithdrawals),
    );
  }

  @override
  List<Object?> get props => [
    status,
    pendingId,
    item,
    draft,
    initialDraft,
    amountInput,
    categories,
    categoriesLoading,
    personQuery,
    personResults,
    selectedPerson,
    personDuplicateMatches,
    pendingPersonName,
    finding,
    duplicateRequest,
    duplicatePending,
    parent,
    originalSection,
    original,
    requiresDiscardConfirmation,
    leaveApproved,
    failure,
    nextImportId,
    mutedRemovedCount,
    similarPeople,
    countCashWithdrawals,
  ];

  /// Redacted: never prints an amount, a name, the note, the original text
  /// or an id (FR-097, FR-101).
  @override
  String toString() =>
      'ImportReviewState(status: ${status.name}, '
      'type: ${draft?.type?.name}, '
      'missing: ${missing.map((f) => f.name).join(',')}, '
      'dirty: $isDirty, original: ${originalSection.name}, '
      'duplicate: ${finding?.tier.name}, '
      'failure: ${failure.runtimeType})';
}
