# Contract Extension: TransactionsRepository (001/008, extended by this feature)

Adds one method to the existing `TransactionsRepository` interface, following the exact same additive pattern 008 already used for `addOccasionContribution`. All existing 001/008 methods and signatures are unchanged.

```dart
abstract class TransactionsRepository {
  // ...existing 001 methods unchanged (addTransaction, recordRepayment,
  // editTransaction, deleteTransaction, getPersonHistory, getPersonBalance,
  // getOverview)...
  // ...existing 008 additions unchanged (addOccasionContribution,
  // getContributionsForOccasion)...

  /// Creates a MoneyTransaction with source = ocr and the given
  /// [ocrScanId] (FR-012). Used internally by OcrRepositoryImpl's
  /// confirmScanBatch — Presentation never calls this directly. [kind]
  /// defaults to initialExchange for a plain (non-occasion-tagged) scan
  /// entry; when the scan is occasion-tagged, confirmScanBatch calls
  /// OccasionsRepository.addParticipantContribution instead (which itself
  /// is extended, see below) so the occasionId/countsTowardBalance rules
  /// from 008 are applied exactly once, in one place.
  Future<Either<Failure, MoneyTransaction>> addOcrSourcedTransaction({
    required String idempotencyKey,
    required String personId,
    required String ocrScanId,
    required int amountMinorUnits,
    required TransactionDirection direction,
    required DateTime date,
    String? note,
  });
}
```

## Contract Extension: OccasionsRepository (008, extended by this feature)

```dart
abstract class OccasionsRepository {
  // ...existing 008 methods unchanged, EXCEPT addParticipantContribution
  // gains two optional parameters so an OCR-confirmed, occasion-tagged
  // entry is traceable exactly like an OCR-confirmed plain transaction:

  Future<Either<Failure, MoneyTransaction>> addParticipantContribution({
    required String idempotencyKey,
    required String occasionId,
    required String personId,
    required int amountMinorUnits,
    required TransactionDirection direction,
    bool? countsTowardBalance,
    String? note,
    String? ocrScanId,          // NEW, optional — null for manual entry (unchanged behavior)
  });
}
```

**Behavioral note**: Passing `ocrScanId` sets `source = ocr` on the created row in addition to the existing `kind = occasionContribution`/`occasionId` fields (008) — the two source-tracking extensions (008's occasion link, 009's OCR link) are independent, orthogonal columns that compose on the same row without conflict, per data-model.md's `MoneyTransaction (EXTENDED)` validation rules.
