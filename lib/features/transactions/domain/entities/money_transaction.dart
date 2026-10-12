import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import '../../../../core/provenance/import_provenance.dart';
import '../../../../core/provenance/record_provenance.dart';

/// Which way the money moved.
enum TransactionDirection { given, received }

/// Whether a transaction is a regular exchange, a repayment against an
/// existing balance, or one participant's contribution recorded under an
/// `Occasion` (008). Fixed at creation — never changeable via edit
/// (Clarifications): reclassifying means delete + re-create.
enum TransactionKind { initialExchange, repayment, occasionContribution }

/// How this row came to exist: typed in by the user, or confirmed from an
/// OCR scan of a paper list (009). Defaults to [manual] for every row that
/// existed before 009 and for every row created by any non-OCR path, so the
/// field is additive in the strictest sense — nothing about 001/008
/// behaviour changes.
///
/// A [TransactionSource.ocr] row is never created directly from recognition
/// output: it exists only because the user explicitly confirmed a
/// `CandidateEntry` on the OCR review screen (constitution Principle X).
enum TransactionSource { manual, ocr }

/// A single recorded money event between the user and one [Person]. The
/// atomic, immutable-by-default unit of financial truth — edits and
/// deletions are explicit, confirmed, and traceable rather than silent.
class MoneyTransaction extends Equatable {
  const MoneyTransaction({
    required this.id,
    required this.idempotencyKey,
    required this.personId,
    required this.amount,
    required this.direction,
    required this.kind,
    required this.date,
    required this.createdAt,
    this.note,
    this.occasionId,
    this.countsTowardBalance = true,
    this.source = TransactionSource.manual,
    this.ocrScanId,
    this.editedAt,
    this.deletedAt,
    this.importSource,
  });

  final String id;

  /// Client-generated once per user-initiated save action; a retried insert
  /// with the same key is a no-op that returns the existing row (FR-020).
  final String idempotencyKey;
  final String personId;

  /// Always strictly positive (FR-005).
  final Money amount;
  final TransactionDirection direction;
  final TransactionKind kind;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  /// The `Occasion` this row was recorded under (008). Non-null exactly
  /// when [kind] is [TransactionKind.occasionContribution]; `null` for every
  /// ordinary transaction, which is the vast majority and unchanged from 001.
  final String? occasionId;

  /// Whether this row feeds the person's [PersonBalance]. Always effectively
  /// `true` except for occasion contributions, which may be recorded as
  /// non-counting — the condolence default (008 FR-018), where the money is
  /// not a reciprocal social debt. Stored per row rather than derived from
  /// the occasion's current type, so later editing that type never silently
  /// moves someone's balance (008 research.md Decision 3).
  final bool countsTowardBalance;

  /// Whether the user typed this row in or confirmed it from a paper scan
  /// (009 FR-012). Recorded so an OCR-sourced row is honestly labelled as
  /// such everywhere it is shown, and so a whole scan's output can be
  /// traced after the fact.
  final TransactionSource source;

  /// The `OcrScan` this row was confirmed from (009). Non-null exactly when
  /// [source] is [TransactionSource.ocr]; `null` for every manually entered
  /// row. Orthogonal to [occasionId] — an OCR-confirmed, occasion-tagged
  /// entry carries both.
  ///
  /// The referenced scan may since have been deleted (009 FR-023 deletes a
  /// scan without touching the real transactions it produced), in which case
  /// the row still correctly reports its OCR origin and only the "view
  /// original scan" affordance goes away.
  final String? ocrScanId;

  /// `null` means never edited. Presence drives the "edited" UI marker
  /// (FR-015).
  final DateTime? editedAt;

  /// Soft-delete tombstone; `null` means active.
  final DateTime? deletedAt;

  /// 023: non-null only for a row the user confirmed from a bank message
  /// (FR-057). Orthogonal to [source], which stays
  /// [TransactionSource.manual] for such a row (FR-086). `null` means "not
  /// imported".
  final ImportProvenance? importSource;

  /// How this row arrived, as one value (023 data-model §3.6, analysis M8):
  /// [RecordProvenance.ocr] when [source] is [TransactionSource.ocr],
  /// [RecordProvenance.sms] when [importSource] is SMS, else
  /// [RecordProvenance.manual].
  ///
  /// Code that needs "how did this record arrive" must read this getter and
  /// must not test `source == TransactionSource.manual` alone: an
  /// SMS-confirmed row also has `source == manual`.
  RecordProvenance get provenance {
    if (source == TransactionSource.ocr) return RecordProvenance.ocr;
    if (importSource?.isSms ?? false) return RecordProvenance.sms;
    return RecordProvenance.manual;
  }

  bool get isEdited => editedAt != null;

  /// Whether this row belongs to an `Occasion` (008) — the single condition
  /// under which [occasionId] is readable as non-null.
  bool get isOccasionContribution =>
      kind == TransactionKind.occasionContribution;

  /// Whether this row came from a confirmed paper scan (009).
  bool get isOcrSourced => source == TransactionSource.ocr;
  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
    id,
    idempotencyKey,
    personId,
    amount,
    direction,
    kind,
    date,
    note,
    occasionId,
    countsTowardBalance,
    source,
    ocrScanId,
    createdAt,
    editedAt,
    deletedAt,
    importSource,
  ];
}
