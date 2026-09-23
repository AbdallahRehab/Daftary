import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/money_transaction.dart';
import 'field_confidence.dart';

/// Where one proposed entry stands in the review (009 data-model.md).
///
/// There is no automatic transition out of [pendingReview], at any
/// confidence level however high: only an explicit user action on the
/// review screen moves an entry (constitution Principle X, FR-007).
enum CandidateEntryStatus { pendingReview, confirmed, discarded }

/// One proposed transaction parsed out of a scan, before the user has
/// agreed to it.
///
/// Deliberately *not* a `MoneyTransaction`: it is a suggestion, carrying
/// per-field provenance ([FieldConfidence]) and the raw text it came from
/// so the reviewer can check it against the page. It only becomes real
/// money by passing through `ConfirmScanBatch`.
class CandidateEntry extends Equatable {
  const CandidateEntry({
    required this.id,
    required this.scanId,
    required this.status,
    required this.personName,
    required this.personNameConfidence,
    required this.amountConfidence,
    required this.directionConfidence,
    required this.dateConfidence,
    required this.rawOcrText,
    required this.createdAt,
    this.matchedPersonId,
    this.amountMinorUnits,
    this.direction,
    this.date,
    this.notes,
    this.editedAt,
  });

  final String id;
  final String scanId;
  final CandidateEntryStatus status;

  /// The parser's best read of the name, editable throughout review. May be
  /// empty when nothing name-shaped was recognized on the line, in which
  /// case the entry simply cannot be confirmed until the user fills it in
  /// (FR-008).
  final String personName;
  final FieldConfidence personNameConfidence;

  /// Set once the user resolves this entry to an existing person, directly
  /// or through the duplicate-check flow (FR-009). `null` means "create a
  /// new person at confirm time", exactly as manual entry behaves.
  final String? matchedPersonId;

  /// `null` or non-positive blocks confirmation (FR-008, same rule as 001
  /// FR-005).
  final int? amountMinorUnits;
  final FieldConfidence amountConfidence;

  /// `null` falls back to the scan's batch default for display and for the
  /// effective value resolved at confirm time (FR-005).
  final TransactionDirection? direction;
  final FieldConfidence directionConfidence;

  /// `null` falls back to the scan's own date.
  final DateTime? date;
  final FieldConfidence dateConfidence;
  final String? notes;

  /// The original, unedited recognized line this entry was parsed from —
  /// kept so review can compare against the page, and so a past scan stays
  /// explainable.
  final String rawOcrText;
  final DateTime createdAt;

  /// Set on any review-screen edit. Non-null on at least one entry is what
  /// makes cancelling the scan prompt before throwing work away (FR-015).
  final DateTime? editedAt;

  bool get isEdited => editedAt != null;
  bool get isDiscarded => status == CandidateEntryStatus.discarded;
  bool get isConfirmed => status == CandidateEntryStatus.confirmed;

  /// The direction actually used if this entry were confirmed now, given
  /// the batch default. `null` means neither is set, which blocks confirm.
  TransactionDirection? effectiveDirection(
    TransactionDirection? batchDefault,
  ) => direction ?? batchDefault;

  /// The date actually used if this entry were confirmed now, falling back
  /// to the scan's own date — always resolvable, so it never blocks
  /// confirm on its own.
  DateTime effectiveDate(DateTime scanDate) => date ?? scanDate;

  /// Whether this entry is complete enough to become a real transaction
  /// (data-model.md validation rules, FR-008).
  ///
  /// Defined once, here, and used by both `ScanReviewCubit` (to enable the
  /// confirm button) and `OcrRepositoryImpl.confirmScanBatch` (to refuse
  /// the write). Two copies of this rule could disagree, and the direction
  /// they would disagree in is "the UI let it through" — so there is one.
  bool isConfirmEligible(TransactionDirection? batchDefault) {
    if (personName.trim().isEmpty) return false;
    final amount = amountMinorUnits;
    if (amount == null || amount <= 0) return false;
    if (effectiveDirection(batchDefault) == null) return false;
    return true;
  }

  /// Whether any field on this entry is a low-confidence read — the signal
  /// the review screen sorts on so the riskiest rows are seen first
  /// (FR-013).
  bool get hasLowConfidenceField =>
      personNameConfidence.isLowConfidenceRead ||
      amountConfidence.isLowConfidenceRead ||
      directionConfidence.isLowConfidenceRead ||
      dateConfidence.isLowConfidenceRead;

  CandidateEntry copyWith({
    CandidateEntryStatus? status,
    String? personName,
    FieldConfidence? personNameConfidence,
    String? matchedPersonId,
    bool clearMatchedPersonId = false,
    int? amountMinorUnits,
    FieldConfidence? amountConfidence,
    TransactionDirection? direction,
    FieldConfidence? directionConfidence,
    DateTime? date,
    FieldConfidence? dateConfidence,
    String? notes,
    DateTime? editedAt,
  }) {
    return CandidateEntry(
      id: id,
      scanId: scanId,
      status: status ?? this.status,
      personName: personName ?? this.personName,
      personNameConfidence: personNameConfidence ?? this.personNameConfidence,
      matchedPersonId: clearMatchedPersonId
          ? null
          : (matchedPersonId ?? this.matchedPersonId),
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      amountConfidence: amountConfidence ?? this.amountConfidence,
      direction: direction ?? this.direction,
      directionConfidence: directionConfidence ?? this.directionConfidence,
      date: date ?? this.date,
      dateConfidence: dateConfidence ?? this.dateConfidence,
      notes: notes ?? this.notes,
      rawOcrText: rawOcrText,
      createdAt: createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    scanId,
    status,
    personName,
    personNameConfidence,
    matchedPersonId,
    amountMinorUnits,
    amountConfidence,
    direction,
    directionConfidence,
    date,
    dateConfidence,
    notes,
    rawOcrText,
    createdAt,
    editedAt,
  ];
}
