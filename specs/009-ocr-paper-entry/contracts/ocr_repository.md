# Contract: OcrRepository

Local-only Domain/Data boundary (no network — research.md Decision 1). All methods return `Either<Failure, T>`. **This contract is the structural enforcement of constitution Principle X**: `confirmScanBatch` is the only method in this interface (or anywhere else in the app) capable of producing a `MoneyTransaction`/occasion contribution from scan data, and it only acts on entries already marked `confirmed` by explicit prior user action.

```dart
abstract class OcrRepository {
  /// Starts a new scan session from a prepared (cropped/rotated/enhanced)
  /// image already written to local sandboxed storage by
  /// ImagePreparationService (FR-001/FR-002). Status begins as
  /// `processing`.
  Future<Either<Failure, OcrScan>> startScan({
    required String sourceImagePath,
    String? cropBounds,
    required int rotationDegrees,
  });

  /// Runs TextRecognitionService against the scan's image, then
  /// CandidateEntryParser over the result, persisting the produced
  /// CandidateEntry rows and moving the scan to `needsReview` (or `failed`
  /// if zero text/zero candidates were found — FR-003/FR-004). Never
  /// creates a MoneyTransaction.
  Future<Either<Failure, OcrScan>> runExtraction(String scanId);

  /// Sets the batch-level default direction (FR-005). Does not overwrite
  /// any CandidateEntry that already has an explicit per-entry direction
  /// (read or previously user-set).
  Future<Either<Failure, OcrScan>> setBatchDefaultDirection({
    required String scanId,
    required TransactionDirection direction,
  });

  /// Tags the whole batch to a new or existing Occasion (FR-014); every
  /// entry confirmed after this call is saved as an occasion contribution
  /// (008) instead of a plain transaction. Passing null clears the tag.
  Future<Either<Failure, OcrScan>> tagBatchToOccasion({
    required String scanId,
    String? occasionId,
  });

  /// Edits one candidate entry's fields (FR-008). Applies the same
  /// validation as manual transaction entry (positive amount, etc. —
  /// data-model.md CandidateEntry validation rules). Setting
  /// matchedPersonId resolves a possible-duplicate match (FR-009); leaving
  /// it null means "create a new person" at confirm time.
  Future<Either<Failure, CandidateEntry>> editCandidateEntry({
    required String entryId,
    String? personName,
    String? matchedPersonId,
    int? amountMinorUnits,
    TransactionDirection? direction,
    DateTime? date,
    String? notes,
  });

  /// Marks one entry discarded (FR-010); it is excluded from
  /// confirmScanBatch and never becomes a transaction.
  Future<Either<Failure, Unit>> discardCandidateEntry(String entryId);

  /// THE gate (constitution Principle X, FR-007). Marks every currently
  /// non-discarded, currently-valid CandidateEntry as `confirmed`, then —
  /// in one atomic operation — creates one MoneyTransaction per confirmed
  /// entry via TransactionsRepository.addOcrSourcedTransaction (or, when
  /// scan.occasionId is set, OccasionsRepository.addParticipantContribution
  /// with the OCR source metadata passed through), sets the scan's status
  /// to `confirmed`. [idempotencyKey] makes a retried call a no-op
  /// (FR-021, SC-006). Returns ValidationFailure (listing which entries are
  /// incomplete) instead of partially saving if any non-discarded entry is
  /// not confirm-eligible (data-model.md validation rules) — all-or-nothing,
  /// per FR-011.
  Future<Either<Failure, List<MoneyTransaction>>> confirmScanBatch({
    required String idempotencyKey,
    required String scanId,
  });

  /// Cancels an in-progress or needs-review scan with no transactions
  /// created (FR-015). If any entry had already been edited
  /// (CandidateEntry.editedAt != null on at least one row), the caller
  /// must have already shown the "discard your corrections?" confirmation
  /// before calling this.
  Future<Either<Failure, Unit>> cancelScan(String scanId);

  /// Scan history, newest first (FR-018), optionally excluding deleted.
  Future<Either<Failure, List<OcrScan>>> getScanHistory();

  /// Full detail for one scan: the OcrScan, its source image path, and
  /// its CandidateEntry list (FR-018) — for a confirmed scan, entries
  /// remain visible in their confirmed state for reference even though
  /// the real data of record is now in MoneyTransactions.
  Future<Either<Failure, OcrScanDetail>> getScanDetail(String scanId);

  /// Deletes a scan record, its CandidateEntry rows, and its source image
  /// file (FR-023). Does NOT delete any MoneyTransaction the scan already
  /// produced (data-model.md Relationships).
  Future<Either<Failure, Unit>> deleteScan(String scanId);
}
```

**Failure modes**: `ValidationFailure` (incomplete/invalid entry blocking confirm, empty name/type), `NoTextRecognizedFailure`, `NoCandidatesParsedFailure` (both `OcrFailure` subtypes — FR-004), `ImageProcessingFailure` (crop/enhance step failed), `PermissionDeniedFailure` (camera/gallery — FR-016), `NotFoundFailure` (unknown scan/entry id), `CacheFailure`, `UnknownFailure`.

**Idempotency note**: `confirmScanBatch` is the only method here that takes an `idempotencyKey`, for the same reason established in 001/008 — it is the only call a rapid double-tap could duplicate. `startScan`/`runExtraction` are naturally one-shot per scan session (driven by explicit user navigation, not retryable taps in the same sense). All other methods act on an already-identified id and are naturally idempotent.

**Cross-feature note**: `confirmScanBatch` never constructs a `MoneyTransaction` row itself — it always delegates to `TransactionsRepository.addOcrSourcedTransaction` (contracts/transactions_repository_extension.md) or `OccasionsRepository.addParticipantContribution` (008, passed the OCR source metadata), exactly mirroring how 008's `OccasionsRepository` never wrote a `MoneyTransaction` row itself either. This is what keeps "can this code path ever create a transaction without a confirmed review" a question with one obviously-auditable answer.
