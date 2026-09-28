import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../entities/candidate_entry.dart';
import '../entities/ocr_scan.dart';
import '../entities/ocr_scan_detail.dart';

/// Domain/Data boundary for scans and their candidate entries
/// (constitution Principle VI). Local-only: no method here touches the
/// network, and there is no implementation that could (009 FR-019).
///
/// **This interface is where constitution Principle X is enforced
/// structurally rather than merely behaviourally.** [confirmScanBatch] is
/// the only method that can turn scan data into money, it only acts on
/// entries the user has explicitly confirmed, and no other method anywhere
/// in the app writes a `MoneyTransaction` from a [CandidateEntry]. That is
/// a property of the shape of this interface, not a rule someone has to
/// remember while editing the UI.
abstract class OcrRepository {
  /// Starts a scan session from an already-prepared image sitting in the
  /// app's sandboxed storage (FR-001/FR-002). The scan begins as
  /// [ScanStatus.processing].
  Future<Either<Failure, OcrScan>> startScan({
    required String sourceImagePath,
    String? cropBounds,
    required int rotationDegrees,
  });

  /// Runs recognition over the scan's image, then the parser over the
  /// result, persisting the candidate entries and moving the scan to
  /// [ScanStatus.needsReview].
  ///
  /// Moves the scan to [ScanStatus.failed] and returns
  /// `NoTextRecognizedFailure`/`NoCandidatesParsedFailure` when nothing
  /// usable came out (FR-003/FR-004). Creates no `MoneyTransaction` under
  /// any outcome.
  Future<Either<Failure, OcrScan>> runExtraction(String scanId);

  /// Sets the batch-level default direction (FR-005). Never overwrites an
  /// entry that already carries its own direction, read or user-set —
  /// changing a default must not quietly undo a correction.
  Future<Either<Failure, OcrScan>> setBatchDefaultDirection({
    required String scanId,
    required TransactionDirection direction,
  });

  /// Tags the whole batch to an occasion (FR-014); everything confirmed
  /// afterwards is saved as that occasion's contribution (008) instead of a
  /// plain transaction. Passing `null` clears the tag.
  Future<Either<Failure, OcrScan>> tagBatchToOccasion({
    required String scanId,
    String? occasionId,
  });

  /// Loads the scan's entries in review order (FR-008).
  Future<Either<Failure, List<CandidateEntry>>> getCandidateEntries(
    String scanId,
  );

  Future<Either<Failure, OcrScan>> getScan(String scanId);

  /// Applies one field edit, with the same validation manual entry uses —
  /// a non-positive amount is rejected here exactly as it is there
  /// (FR-008). Setting [matchedPersonId] resolves the entry to an existing
  /// person (FR-009); leaving it null means "create a new person at
  /// confirm time", as manual entry behaves.
  Future<Either<Failure, CandidateEntry>> editCandidateEntry({
    required String entryId,
    String? personName,
    String? matchedPersonId,
    bool clearMatchedPersonId = false,
    int? amountMinorUnits,
    TransactionDirection? direction,
    DateTime? date,
    String? notes,
  });

  /// Marks one entry discarded (FR-010). It is excluded from
  /// [confirmScanBatch] and never becomes a transaction. Siblings and the
  /// scan's own status are untouched.
  Future<Either<Failure, Unit>> discardCandidateEntry(String entryId);

  /// **The gate** (constitution Principle X, FR-007).
  ///
  /// Marks every non-discarded, confirm-eligible entry as confirmed and —
  /// in one database transaction — creates exactly one `MoneyTransaction`
  /// per confirmed entry, delegating to
  /// `TransactionsRepository.addOcrSourcedTransaction` or, when the scan is
  /// occasion-tagged, `OccasionsRepository.addParticipantContribution`.
  /// It never builds a transaction row itself.
  ///
  /// All-or-nothing: if any non-discarded entry is not confirm-eligible,
  /// returns `ValidationFailure` naming them and creates **zero**
  /// transactions (FR-011). A retried call with the same [idempotencyKey]
  /// returns what the first call created rather than a second batch
  /// (FR-021, SC-006).
  Future<Either<Failure, List<MoneyTransaction>>> confirmScanBatch({
    required String idempotencyKey,
    required String scanId,
  });

  /// Abandons a scan with nothing created (FR-015). When any entry was
  /// already edited, the caller must have shown the "discard your
  /// corrections?" prompt first — a scan the user put work into is kept as
  /// [ScanStatus.discarded] rather than hard-deleted, so the effort is not
  /// silently thrown away.
  Future<Either<Failure, Unit>> cancelScan(String scanId);

  /// Scan history, newest first, excluding deleted scans (FR-018).
  Future<Either<Failure, List<OcrScan>>> getScanHistory();

  /// One scan with its entries and the transactions it produced (FR-018).
  Future<Either<Failure, OcrScanDetail>> getScanDetail(String scanId);

  /// Deletes the scan record, its entries, and its source image file
  /// (FR-023). Never deletes a `MoneyTransaction` the scan already
  /// produced — by then those are real financial records of their own
  /// (data-model.md Relationships).
  Future<Either<Failure, Unit>> deleteScan(String scanId);
}
