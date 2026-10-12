# Discovery T002: finance entry creation

Read-only notes for T073 (`addSmsSourcedEntry`) and T074 (`confirm`). Read discovery/transactions.md first: the transaction-joining, `_ConfirmAborted` and failure-message findings (F2, F3, F5) apply here unchanged.

## Flags: where the plan or contracts are wrong or imprecise

| # | Plan/contract claim | Reality | What to do |
| --- | --- | --- | --- |
| G1 | "Same validation as addEntry (positive amount, non-empty category, category type == type via `_validateCategoryMatches`, **active category**)" (domain-interfaces.md:264-266; tasks T073 "category active") | `addEntry` and `_validateCategoryMatches` do **not** check that the category is active. `_validateCategoryMatches` (`finance_repository_impl.dart:358-373`) checks only that the category exists (`NotFoundFailure`) and that its type matches (`ValidationFailure`). `FinanceCategories.isArchived` (`app_database.dart:299`) is never read on the write path. | Reuse `_validateCategoryMatches` **unchanged**. Add a separate archived check inside `addSmsSourcedEntry` only (additive: read `_dao.getCategoryById`, reject when `isArchived`). Don't change `addEntry`'s behaviour (briefing rule 4). Record the choice in the T073 decisions file. This matters because a learned merchant mapping can point at a category archived since then. |
| G2 | "the audit insert from v12" (tasks T002) | The audit insert isn't in the v12 migration. v12 only creates the table. The insert is in **`FinanceDao._appendAudit`** (`finance_dao.dart:110-130`), called from `insertEntryIdempotent(companion, audit:)` (`:172-190`). The repository supplies an `EntryAuditDraft` through `_audit(FinanceAuditChange.created)` (`finance_repository_impl.dart:343-353`). | Call `_dao.insertEntryIdempotent(companion, audit: _audit(FinanceAuditChange.created))` exactly as `addEntry` does (`:60-63`). Don't touch the DAO. |
| G3 | Content-free failures | `_validateCategoryMatches` builds a message that includes the **category name** (`:367-370`). The catch-all is `CacheFailure('Failed to record entry: $e')` (`:66`), and an SQLite error string includes the bound parameters, note text among them (see transactions.md F5). | `confirm` maps any inner failure to a fixed-token failure and passes no message through. |
| G4 | "`copyWith` if present" | `FinanceEntry` has **no** `copyWith` (`finance_entry.dart:9-72`). | Add the field, the constructor param and the `props` entry only. |
| G5 | Validation limits (amount <= 12 whole digits, note <= 500, catalog currency) | The repository checks only `amount.isPositive` (`:39-41`) and a non-blank `categoryId` (`:42-44`). The note cap is UI-only (`finance_entry_form_page.dart:260`, `maxLength: 500`). The digit cap lives in `CurrencyFormatter.parse` (`currency_formatter.dart:24,97`). | `ReviewDraft.validate()` enforces these limits, as in transactions.md F4. |
| G6 | `FinanceEntry` has no `source` and gains none (data-model.md:213) | Confirmed. The `FinanceEntries` table (`app_database.dart:316-335`) has no source column. | Add only `import_source`. |

## 1. The entity: `FinanceEntry`

`lib/features/finance/domain/entities/finance_entry.dart`

- `class FinanceEntry extends Equatable` at `:9`. Its const constructor is at `:10-21`: required params first, then the optional ones (`note`, `editedAt`, `deletedAt`).
- Getters at `:54-57` (`isEdited`, `isDeleted`, `isIncome`, `isExpense`).
- `props` at `:59-71`. It lists every field explicitly.
- Additive change (T032/T073): add `this.importSource,` to the constructor, then `final ImportProvenance? importSource;` (with a doc comment), then `importSource` in `props`.
- `FinanceEntryType { income, expense }` is at `lib/features/finance/domain/entities/finance_entry_type.dart:8`. `dbValue` is at `:16`, and `financeEntryTypeFromDb` at `:25`.
- Mapper: `lib/features/finance/data/models/finance_entry_mapper.dart:7-26` (`FinanceEntryMapper.toDomain`). Add the `importSource` mapping there. `dateOnlyMillis(DateTime)` is a **top-level** function in the same file (`:32-33`), shared by the repository.

## 2. Repository interface

`lib/features/finance/domain/repositories/finance_repository.dart`

- `addEntry` at `:24-31`, documented at `:17-23`. Put `addSmsSourcedEntry` after `editEntry`/`addEntry`, with the doc text from `domain-interfaces.md:263-276` ("Called only by SmsImportRepositoryImpl.confirm").
- Test doubles are mocktail (`class MockFinanceRepository extends Mock implements FinanceRepository {}` at `test/features/finance/domain/usecases/add_finance_entry_test.dart:11`). Only `FinanceRepositoryImpl` implements the interface concretely, so a new abstract method breaks nothing.

## 3. The write path to copy: `addEntry`

`lib/features/finance/data/repositories/finance_repository_impl.dart`

| Anchor | What |
| --- | --- |
| `:23-28` | `@LazySingleton(as: FinanceRepository)`. The only dependency is `FinanceDao _dao`. The class holds **no `AppDatabase`**, so it runs its transaction through the DAO. |
| `:30-68` | **`addEntry`**: validate, check the category, build the companion, call `insertEntryIdempotent(audit: created)`, catch to `CacheFailure`. |
| `:343-353` | **`_audit(FinanceAuditChange change, {previousValues})`**: returns an `EntryAuditDraft(id: uuid, changeType: change.value, previousValuesJson, changedAt: now)`. |
| `:358-373` | **`_validateCategoryMatches(categoryId, type)`**: returns `Future<Failure?>`. Gives `NotFoundFailure` when the category is missing and `ValidationFailure` on a type mismatch. It does not check whether the category is archived (G1). |

Template for `addSmsSourcedEntry` (a copy of `:30-68`, with the marked lines new):

```dart
  @override
  Future<Either<Failure, FinanceEntry>> addSmsSourcedEntry({
    required String idempotencyKey,
    required String categoryId,
    required FinanceEntryType type,
    required Money amount,
    required DateTime date,
    String? note,
  }) async {
    assert(idempotencyKey.startsWith('sms-import:'));                 // NEW
    if (!amount.isPositive) {
      return const Left(ValidationFailure('Amount must be greater than zero'));
    }
    if (categoryId.trim().isEmpty) {
      return const Left(ValidationFailure('A category must be selected'));
    }
    try {
      final mismatch = await _validateCategoryMatches(categoryId, type); // reused unchanged
      if (mismatch != null) return Left(mismatch);
      final category = await _dao.getCategoryById(categoryId);           // NEW (G1)
      if (category!.isArchived) {
        return const Left(ValidationFailure('Category is archived'));
      }

      final companion = db.FinanceEntriesCompanion.insert(
        id: _uuid.v4(),
        idempotencyKey: idempotencyKey,
        categoryId: categoryId,
        type: type.dbValue,
        amountMinorUnits: amount.minorUnits,
        currencyCode: db.Value(amount.currency.code),
        date: dateOnlyMillis(date),
        note: db.Value(note),
        importSource: db.Value(ImportProvenance.sms.wire),                // NEW column (v13)
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final row = await _dao.insertEntryIdempotent(
        companion,
        audit: _audit(FinanceAuditChange.created),                       // the same created audit
      );
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to record imported entry: $e'));  // confirm must not surface (G3)
    }
  }
```

## 4. Idempotency and the audit, inside the DAO

`lib/features/finance/data/datasources/finance_dao.dart`

| Anchor | What |
| --- | --- |
| `:50-64` | `class EntryAuditDraft { id, changeType, changedAt, previousValuesJson? }`. The DAO fills in the entry id. |
| `:80-94` | `@injectable class FinanceDao(_db, _outbox, _categoryMapper, _entryMapper, _auditMapper)`. |
| `:110-130` | **`_appendAudit(entryId, draft)`**: inserts into `finance_entry_audits`, re-reads, then calls `_outbox.recordUpsert(SyncEntityType.financeEntryAudit, ...)`. It must run inside the change's transaction. |
| `:172-190` | **`insertEntryIdempotent(companion, {required audit})`**: in `_db.transaction`, looks up the idempotency key. If the row exists it is **returned with no audit and no outbox write**. Otherwise it inserts, re-reads, calls `outbox.recordUpsert(financeEntry, toWire(row))` and `_appendAudit`. |
| `:192-194` | `getEntryByIdempotencyKey`: no `deletedAt` filter (same as transactions). |
| `:456-458` | `getCategoryById`: includes archived rows. |

- `FinanceAuditChange { created, edited, deleted, restored }` with `.value` (the stored and wire string) is at `lib/features/finance/domain/entities/finance_entry_audit.dart:5-14`. Note the naming: transactions use `AuditChangeType` with `dbValue`, finance uses `FinanceAuditChange` with `value`.
- The audit table `FinanceEntryAudits` is at `app_database.dart:265`. The unique key is `FinanceEntries.idempotencyKey` (`app_database.dart:318`).
- The idempotency key is **per table**. The type-switch retry is protected only by the `pending` status guard plus rollback (see transactions.md section 4).

## 5. Joining the confirm transaction

`insertEntryIdempotent` opens `_db.transaction` on the same `AppDatabase` lazySingleton. Inside `confirm`'s outer `_db.transaction` it becomes a savepoint (transactions.md F2). `addSmsSourcedEntry` catches everything and returns `Left`, so `confirm` must turn every `Left` into a throw:

```dart
final saved = await _financeRepository.addSmsSourcedEntry(...);
final entry = saved.match((f) => throw _ConfirmAborted(f), (e) => e);
```

`editEntry` (`impl:70-136`) builds a partial `FinanceEntriesCompanion` (`:94-106`), so an edit preserves `import_source`. Confirmed.

## 6. Category validation inputs for the review UI and the draft

- The active-category list for pickers is `FinanceDao.getCategoriesByType` with an `isArchived = false` filter (`finance_dao.dart:443-454`), exposed through `GetCategories` and `WatchCategories`.
- `RemoveCategory` archives a category that is in use and deletes one that isn't. A learned mapping can therefore point at a deleted id (gives `NotFoundFailure` from `_validateCategoryMatches`) or at an archived id (needs the G1 check). Either way, the review screen should clear the suggestion rather than block.
