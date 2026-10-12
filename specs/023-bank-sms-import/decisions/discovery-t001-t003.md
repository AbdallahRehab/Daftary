# Decisions: discovery T001-T003

This was a read-only slice. No production code was changed, and nothing was formatted, analyzed or tested, because no Dart file was touched.

Places where the docs conflict with the code are listed in full, with anchors, in the flags tables of `discovery/transactions.md` (F1-F9), `discovery/finance.md` (G1-G6) and `discovery/state-management.md` (S1-S5). The recommended resolutions, each taking the most conservative reading, are:

1. **`_ConfirmAborted` does not exist.** The OCR idiom is `_BatchAborted` (`ocr_repository_impl.dart:694`). T074 writes a new private `_ConfirmAborted` with the same shape.
2. **Nested drift transactions are savepoints, not joins.** Atomicity depends on `confirm` throwing on every inner `Left`. T070 must test rollback on an inner `Left` directly, because no existing OCR test covers it.
3. **The status guard goes inside the transaction.** OCR checks status outside its transaction, so it is not the model here.
4. **"Active category" is not part of `addEntry` validation.** Reuse `_validateCategoryMatches` unchanged and add an SMS-only archived check in `addSmsSourcedEntry`. `addEntry` is not changed.
5. **Manual limits (12 digits, note of 500, person exists) are not repository validation.** `ReviewDraft.validate()` and `confirm` enforce them.
6. **Inner repository failures carry `$e`, and SQLite errors embed bound parameters.** `confirm` maps every failure to a content-free token.
7. **Equatable `toString` prints props in debug.** Every SMS-carrying Equatable type overrides `toString`.
8. **Neither `MoneyTransaction` nor `FinanceEntry` has a `copyWith`.** None is added.
9. **The "OCR source-grep guard" the contract refers to does not exist.** T075 is the first such guard.
