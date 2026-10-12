# Discovery T001: transactions model and creation path

Read-only notes for T072 (`addSmsSourcedTransaction`), T074 (`SmsImportRepositoryImpl.confirm`), T070 (confirm tests) and T075 (single-review-gate guard). All anchors are at commit `4a5565d` plus the working tree on `023-bank-sms-import`.

## Flags: where the plan or contracts are wrong or imprecise

| # | Plan/contract claim | Reality | What to do |
| --- | --- | --- | --- |
| F1 | "the `_ConfirmAborted` rollback idiom in the OCR confirm path" (plan.md:47, :272, :415; tasks T003/T070/T074) | No `_ConfirmAborted` exists. The OCR idiom is **`_BatchAborted`** (`lib/features/ocr/data/repositories/ocr_repository_impl.dart:694-698`, thrown at `:432` and `:472`, caught at `:496`). The contract mentions this correctly (`domain-interfaces.md:137`). | Write a new private `_ConfirmAborted` in `sms_import_repository_impl.dart` with the same shape as `_BatchAborted`. See state-management.md section 4. |
| F2 | "inner `_db.transaction` calls join it" (domain-interfaces.md:245) | Drift 2.35 (`pubspec.lock`) runs a nested `transaction()` as a **savepoint**, not a join (`drift-2.35.0/lib/src/runtime/api/connection_user.dart:460-486`). If the inner block throws, only the inner savepoint rolls back, and the outer transaction carries on unless the exception reaches it. The inner repositories **catch** every exception and return `Left` (`transactions_repository_impl.dart:578-580`). So outer atomicity relies entirely on `confirm` turning every `Left` into a thrown `_ConfirmAborted`. | Never ignore or `fold` away a `Left` inside the confirm transaction. Throw on every `Left`. T070 must test rollback on an inner `Left` directly. The OCR suite has **no** such test: its all-or-nothing test `(c)` fails before the transaction starts (`test/features/ocr/data/repositories/ocr_repository_impl_test.dart:341`). |
| F3 | Status guard: "re-read the row and require `pending`" inside the transaction | The OCR precedent checks scan status **outside** its transaction (`ocr_repository_impl.dart:368-388`). Copying it literally would break the "two concurrent confirms → one record" requirement. | Do the re-read **inside** `_db.transaction`. Drift serializes top-level transactions on the one `AppDatabase` lazySingleton (`injection.config.dart:893`), so the second confirm sees `added` and returns `ImportAlreadyDecidedFailure`. |
| F4 | "same validation as the manual path", "mirrors manual limits: amount > 0 and <= 12 whole digits, note <= 500" (domain-interfaces.md:334) | The repository validates only `amount.isPositive` and `personId.trim().isNotEmpty` (`_validateAmountAndPerson`, `:670-678`). The 12-digit cap is in `CurrencyFormatter.parse` (`lib/core/money/currency_formatter.dart:24,97-100`). The 500-char note cap is UI-only (`maxLength: 500` at `transaction_form_page.dart:352`). The person's existence is **not** checked, and `PRAGMA foreign_keys` is never turned on (`grep foreign_keys lib` finds only a comment in `data_wipe.dart:19`), so a dangling `personId` would insert. | `ReviewDraft.validate()` must enforce the 12-digit cap, the note cap and the catalog currency itself. Before calling `addSmsSourcedTransaction`, `confirm` (or `AddImportedTransaction`) should verify the person exists and is not deleted. |
| F5 | Failure messages are content-free (FR-097/101, briefing rule 6) | Every `catch (e)` in this repository builds `CacheFailure('...: $e')` (for example `:579`). `SqliteException.toString()` appends `Causing statement: ..., parameters: ...` (`sqlite3-2.9.4/lib/src/exception.dart:59-91`), which includes the **bound note text and amount**. | `confirm` must **not** pass the inner failure's `message` through. Map it to a fixed-token failure (for example a `CacheFailure('sms_confirm_failed')` or a dedicated `SmsImportFailure`), keeping only its runtime type. The same applies to `CurrencyFormatter.parse`, whose `FormatException` messages embed the input (`currency_formatter.dart:86,90,99`). |
| F6 | "`copyWith` if present" (data-model.md:212) | `MoneyTransaction` has **no** `copyWith` (`money_transaction.dart:28-128`). | Add only the field, the constructor param and the `props` entry. Do not invent a `copyWith`. |
| F7 | "a source-grep guard like the OCR one" (domain-interfaces.md:363) | No guard test exists for `addOcrSourcedTransaction`. `grep -rl addOcrSourcedTransaction test` returns nothing. Precedents for source-scanning guards: `test/features/financial_education/architecture_boundary_test.dart`, `test/features/data_privacy/export_no_network_test.dart`, `test/features/ai_assistant/security/api_key_leak_test.dart`. | T075 writes the first guard of this kind and models it on those files. |
| F8 | — | The repository uses `DateTime.now()` for `createdAt` and audit `changedAt` (`:82,:574,:661`), not `AppClock`. | Keep that (don't change existing behaviour). Tests should not assert exact `createdAt`. |

## 1. The entity: `MoneyTransaction`

`lib/features/transactions/domain/entities/money_transaction.dart`

- `enum TransactionSource { manual, ocr }` at `:23`. **Unchanged** (FR-086). SMS rows keep `manual`.
- `class MoneyTransaction extends Equatable` at `:28`. It has a const constructor with named params (`:29-45`): optional params with defaults come after the required ones (`this.source = TransactionSource.manual`, `this.ocrScanId`, ...).
- Getters at `:99-108` (`isEdited`, `isOcrSourced`, `isDeleted`).
- `props` at `:110-127`. It lists every field explicitly, in declaration order.
- No `copyWith` (F6). No `toString` override.

Pattern for T072 (additive only):

```dart
// constructor (after `this.ocrScanId,`)
    this.importSource,
// field (after ocrScanId, with a doc comment)
  /// 023: non-null only for a row the user confirmed from a bank message
  /// (FR-057). Orthogonal to [source], which stays `manual` (FR-086).
  final ImportProvenance? importSource;
// derived getter required by data-model.md:212 (analysis M8):
//   ocr when source == ocr, sms when importSource is sms, else manual.
//   data-model.md names the getter `provenance` but defines no return type
//   for it. ImportProvenance (data-model §2.8) has only sms|unknown, so the
//   getter needs its own small enum. T032 owns that choice; record it in a
//   decisions file.
// props: add `importSource,` (after ocrScanId)
```

Flag F9: data-model.md:212 asks for a derived `MoneyTransaction.provenance` with three values (ocr/sms/manual), but no type is specified for it. `ImportProvenance` is a class with values `sms` and `unknown(raw)` (data-model.md:99-108), not a three-value enum.

Mapper: `lib/features/transactions/data/models/transaction_mapper.dart:9-45` (`MoneyTransactionMapper.toDomain`). Add `importSource: importSource == null ? null : ImportProvenance.fromWire(importSource!)`. `TransactionSourceDb.dbValue` (`:66-71`) is an exhaustive switch and stays as it is.

## 2. Repository interface

`lib/features/transactions/domain/repositories/transactions_repository.dart`

- `addTransaction` at `:19-26`. The "same idempotency contract" doc is at `:13-18`.
- `addOcrSourcedTransaction` at `:192-200`, with its "Called only by `OcrRepositoryImpl.confirmScanBatch`" doc at `:179-191`. **This is the template for `addSmsSourcedTransaction`.** Put the new method right after `:200`, with the doc text from `domain-interfaces.md:248-261`.
- All test doubles are mocktail `extends Mock implements TransactionsRepository` (for example `test/features/transactions/domain/usecases/add_transaction_test.dart:10`). Only `TransactionsRepositoryImpl` implements the interface concretely, so a new abstract method breaks no existing test.

## 3. The write path to copy

`lib/features/transactions/data/repositories/transactions_repository_impl.dart`

| Anchor | What |
| --- | --- |
| `:23` | `@LazySingleton(as: TransactionsRepository)`. The constructor takes `(this._dao, this._db, {GetConversionContext?})` (`:30-34`). |
| `:545-581` | **`addOcrSourcedTransaction`**: validate, build the companion, call `_insertWithCreatedAudit`, return `Right(row.toDomain())`, and catch to `CacheFailure`. |
| `:639-653` | **`_insertWithCreatedAudit`**: a `_db.transaction` that does an idempotency-key lookup, an insert and the `created` audit. |
| `:655-664` | `_writeCreatedAuditEntry`: `TransactionAuditEntriesCompanion.insert(id, transactionId, changeType: AuditChangeType.created.dbValue, changedAt)`, with `previousValuesJson` left absent (null). |
| `:670-678` | **`_validateAmountAndPerson`**: amount > 0, `personId` non-blank. Returns `ValidationFailure?`. |
| `:680-681` | `_dateOnlyMillis` (local midnight). |

Template for `addSmsSourcedTransaction` (a line-for-line copy of `:545-581`; only the marked lines differ):

```dart
  @override
  Future<Either<Failure, MoneyTransaction>> addSmsSourcedTransaction({
    required String idempotencyKey,
    required String personId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
    String? note,
  }) async {
    assert(idempotencyKey.startsWith('sms-import:'));          // NEW (contract §4)
    final validation = _validateAmountAndPerson(amount, personId);
    if (validation != null) return Left(validation);
    try {
      final companion = db.MoneyTransactionsCompanion.insert(
        id: _uuid.v4(),
        idempotencyKey: idempotencyKey,
        personId: personId,
        amountMinorUnits: amount.minorUnits,
        currencyCode: db.Value(amount.currency.code),
        direction: direction.dbValue,
        kind: TransactionKind.initialExchange.dbValue,
        date: _dateOnlyMillis(date),
        note: db.Value(note),
        source: db.Value(TransactionSource.manual.dbValue),    // FR-086, explicit
        importSource: db.Value(ImportProvenance.sms.wire),     // NEW column (v13)
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final row = await _insertWithCreatedAudit(companion);
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to record imported transaction: $e')); // F5: caller must not surface this
    }
  }
```

`source` already defaults to `'manual'` at the column level (`app_database.dart:85`), so passing it explicitly is optional but makes the code self-documenting.

## 4. Idempotency key handling

Idempotency is checked twice, both times by key and both times inside a transaction:

1. `_insertWithCreatedAudit` (`impl:645-648`): `_dao.getByIdempotencyKey(key)`. If a row exists, it is returned and **no audit row is written**.
2. `TransactionsDao.insertTransactionIdempotent` (`lib/features/transactions/data/datasources/transactions_dao.dart:49-65`): the same lookup, then insert, then re-read, then `_outbox.recordUpsert(SyncEntityType.moneyTransaction, id, _transactionMapper.toWire(inserted))`.

Further details:

- The unique index is `MoneyTransactions.idempotencyKey => text().unique()` (`app_database.dart:59`).
- `getByIdempotencyKey` (`dao:67-69`) does **not** filter `deletedAt`. A retry with the key of a since-deleted row returns the deleted row. That is harmless for SMS, because the status guard makes such a retry impossible.
- The key is **per table**. The same `sms-import:<id>` could exist in both `money_transactions` and `finance_entries`. The type-switch retry case (contract §4, T070) is therefore protected only by the `pending` status guard plus full rollback, not by the key. Test it.
- Contrast with OCR: the OCR cubit makes a **fresh UUID per confirm attempt** (`scan_review_cubit.dart:307`) and derives the per-entry key `'$idempotencyKey:${entry.id}'` (`ocr_repository_impl.dart:448`). SMS uses a deterministic `sms-import:<pendingId>`, as the plan intends. Don't copy the OCR fresh-key idiom.

## 5. Where the audit row is written

- `created`: `_writeCreatedAuditEntry` (`impl:655-664`), called only from `_insertWithCreatedAudit` (`:650`), **only when the row is newly inserted**.
- `TransactionsDao.insertAuditEntry` (`dao:208-221`) inserts into `transaction_audit_entries`, re-reads, then calls `_outbox.recordUpsert(SyncEntityType.transactionAudit, ...)`, all in its own `_db.transaction` (nested savepoint when called inside one).
- The audit table (`app_database.dart:247`) has `id, transactionId, changeType, previousValuesJson, changedAt`. It has no source column (confirms data-model.md:396).
- `AuditChangeType { created, edited, deleted }`: `lib/features/transactions/domain/entities/transaction_audit_entry.dart:5`. DB mapping at `transaction_mapper.dart:88-94`.

The audit row the SMS path writes is therefore byte-for-byte identical to the one manual creation writes. That satisfies SC-013: one `created` row plus a non-null `import_source`.

## 6. How confirm joins the caller's transaction

```text
SmsImportRepositoryImpl.confirm
└─ _db.transaction                         (outer, top-level)
   ├─ re-read pending row; status != pending → throw _ConfirmAborted(ImportAlreadyDecidedFailure)
   ├─ TransactionsRepository.addSmsSourcedTransaction
   │   └─ _insertWithCreatedAudit → _db.transaction        (savepoint 1)
   │       ├─ dao.insertTransactionIdempotent → _db.transaction (savepoint 2) + outbox upsert
   │       └─ dao.insertAuditEntry          → _db.transaction (savepoint 2) + outbox upsert
   │   (any exception here is caught → Left(CacheFailure(...$e...)))
   ├─ result.match((f) => throw _ConfirmAborted(f), ...)   ← mandatory (F2)
   ├─ tombstone, status=added, raw_blob=NULL, scrub, learned mapping, addedCount
   └─ commit (or rollback on _ConfirmAborted / any throw)
```

Both repositories and the SMS repository must share the **same** `AppDatabase` instance (the lazySingleton at `injection.config.dart:893`). Drift detects nesting through the zone of that instance. The outbox rows written inside the savepoints roll back with the outer transaction, so a rolled-back confirm queues nothing for sync.

`editTransaction` (`impl:135-190`) builds a partial `MoneyTransactionsCompanion` (`:164-171`) that leaves out new columns. An edit therefore preserves `import_source` automatically, as data-model.md:395 assumes. Confirmed.

## 7. Sync payload (hand-off to T008)

The DAO serializes the row with `MoneyTransactionSyncMapper.toWire(row)` (`lib/features/transactions/data/sync/money_transaction_sync_mapper.dart:21-41`) at insert time (`dao:58-62`). `import_source` must be set in the insert companion, not patched in later, or the queued payload won't carry it. Adding it to `toWire` (only when non-null) is T008's job.
