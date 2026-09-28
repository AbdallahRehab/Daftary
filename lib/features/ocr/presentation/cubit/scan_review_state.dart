import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../people/domain/entities/person.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../domain/entities/candidate_entry.dart';
import '../../domain/entities/ocr_scan.dart';

/// Where the review screen is in its lifecycle.
///
/// [submitting] is deliberately a distinct status rather than a boolean
/// hanging off [ready]: it is what disables the confirm action the instant
/// it is tapped, and a status the UI must switch on is much harder to
/// forget than a flag it may or may not read (FR-021).
enum ScanReviewStatus {
  initial,
  loading,
  ready,
  loadFailure,
  submitting,
  success,
  cancelled,
}

/// Immutable state for `ScanReviewCubit` (constitution Principle IV —
/// updated exclusively via [copyWith], never mutated in place).
///
/// Every list and map held here is replaced wholesale on each change; no
/// caller ever reaches into [entries] and edits an element. In a screen
/// whose entire job is to be the gate before money is written, "the list
/// changed under us" is not a bug class worth keeping open.
class ScanReviewState extends Equatable {
  const ScanReviewState({
    this.scanId = '',
    this.status = ScanReviewStatus.initial,
    this.scan,
    this.entries = const [],
    this.duplicateMatches = const {},
    this.invalidAmountEntryIds = const {},
    this.validationFailureEntryIds = const {},
    this.idempotencyKey,
    this.savedTransactions = const [],
    this.failure,
    this.personLookupFailure,
    this.requiresCancelConfirmation = false,
  });

  final String scanId;
  final ScanReviewStatus status;

  /// The batch itself — its default direction and occasion tag are what
  /// [CandidateEntry.isConfirmEligible] is evaluated against.
  final OcrScan? scan;

  /// Every entry belonging to the scan, discarded ones included, so a
  /// discard is a status change rather than a hole in the list.
  final List<CandidateEntry> entries;

  /// Possible existing people for a candidate's current name, keyed by
  /// entry id (FR-009). Populated by re-running the same duplicate check
  /// manual entry runs whenever a name is edited.
  final Map<String, List<Person>> duplicateMatches;

  /// Entries whose amount field currently holds text that is not a valid
  /// positive EGP amount. A client-side flag rather than a message so the
  /// page renders it through `l10n` (see `ParticipantFormState`).
  final Set<String> invalidAmountEntryIds;

  /// Entries named by the repository's refusal after a confirm attempt
  /// returned `ValidationFailure` — recomputed from freshly reloaded
  /// entries, never guessed from the failure's message (FR-011).
  final Set<String> validationFailureEntryIds;

  /// Regenerated for each confirm attempt; carried into `ConfirmScanBatch`
  /// so a retried attempt is a retry, and a fresh attempt is not swallowed
  /// as one (FR-021).
  final String? idempotencyKey;

  /// What the confirmed batch actually created. Non-empty only in
  /// [ScanReviewStatus.success].
  final List<MoneyTransaction> savedTransactions;
  final Failure? failure;

  /// A failure from the duplicate-person lookup, kept apart from [failure]
  /// so a people-search problem never reads as a failed save.
  final Failure? personLookupFailure;

  /// Set when cancel was requested while corrections existed; the page must
  /// show the "discard your corrections?" prompt before the scan is
  /// actually abandoned (FR-015).
  final bool requiresCancelConfirmation;

  bool get isSubmitting => status == ScanReviewStatus.submitting;
  bool get isSuccess => status == ScanReviewStatus.success;

  /// The entries still in play — what confirm acts on and what the list
  /// renders. Discarded entries are excluded everywhere (FR-010).
  List<CandidateEntry> get activeEntries =>
      entries.where((entry) => !entry.isDiscarded).toList(growable: false);

  /// [activeEntries] with every entry carrying a low-confidence read moved
  /// to the front (FR-013 Acceptance Scenario 1).
  ///
  /// A stable partition, not a sort on confidence: entries that are equally
  /// risky keep the order the parser produced them in, because a list that
  /// reshuffles as the user corrects fields is a list they have to find
  /// their place in again.
  List<CandidateEntry> get orderedEntries {
    final active = activeEntries;
    final risky = <CandidateEntry>[];
    final calm = <CandidateEntry>[];
    for (final entry in active) {
      (entry.hasLowConfidenceField ? risky : calm).add(entry);
    }
    return List.unmodifiable([...risky, ...calm]);
  }

  /// Active entries that are not yet complete enough to become money —
  /// derived, on every rebuild, from the single definition of that rule on
  /// [CandidateEntry] itself (data-model.md validation rules, FR-008).
  Set<String> get ineligibleEntryIds => {
    for (final entry in activeEntries)
      if (!entry.isConfirmEligible(scan?.defaultDirection)) entry.id,
  };

  /// Whether the batch as a whole may be confirmed. False while submitting,
  /// while any active entry is incomplete or has invalid amount text, and
  /// when there is nothing left to confirm.
  bool get canConfirm =>
      !isSubmitting &&
      status != ScanReviewStatus.success &&
      scan != null &&
      activeEntries.isNotEmpty &&
      ineligibleEntryIds.isEmpty &&
      invalidAmountEntryIds.isEmpty;

  /// Whether the user has put work into this batch that cancelling would
  /// throw away (FR-015).
  bool get hasUnsavedCorrections => entries.any((entry) => entry.isEdited);

  ScanReviewState copyWith({
    String? scanId,
    ScanReviewStatus? status,
    OcrScan? scan,
    List<CandidateEntry>? entries,
    Map<String, List<Person>>? duplicateMatches,
    Set<String>? invalidAmountEntryIds,
    Set<String>? validationFailureEntryIds,
    String? idempotencyKey,
    List<MoneyTransaction>? savedTransactions,
    Failure? failure,
    bool clearFailure = false,
    Failure? personLookupFailure,
    bool clearPersonLookupFailure = false,
    bool? requiresCancelConfirmation,
  }) {
    return ScanReviewState(
      scanId: scanId ?? this.scanId,
      status: status ?? this.status,
      scan: scan ?? this.scan,
      entries: entries ?? this.entries,
      duplicateMatches: duplicateMatches ?? this.duplicateMatches,
      invalidAmountEntryIds:
          invalidAmountEntryIds ?? this.invalidAmountEntryIds,
      validationFailureEntryIds:
          validationFailureEntryIds ?? this.validationFailureEntryIds,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      savedTransactions: savedTransactions ?? this.savedTransactions,
      failure: clearFailure ? null : (failure ?? this.failure),
      personLookupFailure: clearPersonLookupFailure
          ? null
          : (personLookupFailure ?? this.personLookupFailure),
      requiresCancelConfirmation:
          requiresCancelConfirmation ?? this.requiresCancelConfirmation,
    );
  }

  @override
  List<Object?> get props => [
    scanId,
    status,
    scan,
    entries,
    duplicateMatches,
    invalidAmountEntryIds,
    validationFailureEntryIds,
    idempotencyKey,
    savedTransactions,
    failure,
    personLookupFailure,
    requiresCancelConfirmation,
  ];
}
