# Constitution Principle X sign-off — feature 009 (OCR Paper-to-Transaction Entry)

**Task**: T075. **Date**: 2026-09-23. **Branch**: `009-ocr-paper-entry`.

Principle X requires that OCR output can never become a financial record
without explicit human review and confirmation. The claim this document
signs off is stronger than "the UI asks first": it is that **no code path
exists** from recognition output to a `MoneyTransaction` except through
`ConfirmScanBatch`, acting on entries the user explicitly confirmed.

## Method

Every construction site of a `money_transactions` row was enumerated, then
every caller of each one traced back to its entry point.

```
grep -rn "MoneyTransactionsCompanion.insert|into(_db.moneyTransactions)|insertTransactionIdempotent" lib
grep -rn "addOcrSourcedTransaction|addOccasionContribution|addParticipantContribution|addTransaction\(|recordRepayment\(" lib
grep -rn "TransactionsRepository|OccasionsRepository|addOcrSourced|addParticipantContribution" lib/features/ocr/presentation/
```

## Finding 1 — there is one insert path for money in the app

Every `money_transactions` insert in the codebase goes through
`TransactionsDao.insertTransactionIdempotent`, called from exactly four
methods, all in `TransactionsRepositoryImpl`:

| Method | Reached from |
|---|---|
| `addTransaction` | manual entry (`AddTransaction` → `TransactionFormCubit`) |
| `recordRepayment` | manual repayment (`RecordRepayment` → `RepaymentFormCubit`) |
| `addOccasionContribution` | `OccasionsRepositoryImpl.addParticipantContribution` only |
| `addOcrSourcedTransaction` | **`OcrRepositoryImpl.confirmScanBatch` only** |

009 added no fifth path. It added one method to an existing repository and
one caller of it.

## Finding 2 — the OCR feature's only two write calls are inside the gate

`lib/features/ocr/data/repositories/ocr_repository_impl.dart`:

- line 434 — `_occasionsRepository.addParticipantContribution(...)`
- line 444 — `_transactionsRepository.addOcrSourcedTransaction(...)`

`confirmScanBatch` spans lines 348–483; the next method (`cancelScan`)
begins at 485. Both calls are inside the gate, and they are the only two in
the entire feature. `OcrRepositoryImpl` never constructs a
`MoneyTransactionsCompanion` itself — an OCR-sourced row is built by
precisely the code that builds a manual one.

## Finding 3 — the gate is unreachable without a confirmed entry

Inside `confirmScanBatch`, in order:

1. An already-confirmed scan retried under the same key returns the first
   call's transactions; under a different key it is refused. A second batch
   cannot be created from one scan.
2. Every non-discarded entry is checked against
   `CandidateEntry.isConfirmEligible`, and a single failure aborts with
   `ValidationFailure` and **zero** writes.
3. The writes run in one `OcrDao.transaction`, so a mid-batch failure rolls
   the whole thing back.
4. Each entry is marked `confirmed` in that same transaction.

There is no auto-save timer, no background trigger, and no
"high-confidence entries are trusted" shortcut. `RunOcrExtraction` — the
step that turns an image into candidates — takes only an `OcrRepository`
and has no transaction-creating collaborator at all; this is asserted by
name in `run_ocr_extraction_test.dart`, so adding one would fail the suite.

## Finding 4 — Presentation cannot reach a write path

The only reference to a money-writing repository anywhere under
`lib/features/ocr/presentation/` is
`occasion_tag_picker.dart:46`, which calls `getOccasionsList()` — a read,
used to populate the tag picker. No OCR screen holds a
`TransactionsRepository`, and none can create a transaction except by
calling `ConfirmScanBatch`.

## Finding 5 — an edited field stops claiming to be an OCR read

`editCandidateEntry` resets the edited field's `FieldConfidence` to
`inferred`. A value the user typed is never displayed under a
"high-confidence OCR read" badge, which is FR-013's named anti-goal.
A confirmed entry cannot be edited at all — by then the money is the record.

## Automated evidence

| Guarantee | Test |
|---|---|
| One transaction per confirmed entry, `source = ocr`, correct `ocrScanId` | `ocr_repository_impl_test.dart` — gate group (a) |
| Zero transactions for discarded entries | gate group (b) |
| One incomplete entry ⇒ zero writes (all-or-nothing) | gate group (c) |
| No resolvable direction ⇒ refused, never guessed | gate group |
| Retried confirm returns the first batch | gate group (d) |
| Occasion-tagged batch routed through 008 | gate group (e) |
| Already-confirmed scan cannot be re-confirmed | gate group |
| Confirmed entry cannot be edited | gate group |
| Extraction creates nothing, ever | `run_ocr_extraction_test.dart`, repository test |
| Double-tapped confirm calls the use case once | `scan_review_cubit_test.dart` |
| Fresh idempotency key per attempt | `scan_review_cubit_test.dart` |
| Pre-009 rows stay `manual` after migration | `ocr_migration_test.dart` |
| Idempotency index survives the migration | `ocr_migration_test.dart` |

## Sign-off

`ConfirmScanBatch` is the only path from scan data to money; it is
structurally unreachable without a per-entry `confirmed` status set by
explicit user action; and it is all-or-nothing and idempotent. **Principle
X is satisfied.**

One limitation is stated plainly rather than buried: this is a property of
the code as it stands, enforced by the tests above. It is not enforced by
the type system — nothing stops a future change from adding a second caller
of `addOcrSourcedTransaction`. The doc comments on that method and on
`OcrRepository.confirmScanBatch` say so, and the "no transaction-creating
collaborator" tests are the tripwire.
