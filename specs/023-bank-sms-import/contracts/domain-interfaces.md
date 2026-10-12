# Contract: Domain Interfaces (repositories, services, use cases, failures)

**Feature**: 023 Bank SMS Import · **Research**: Decisions 6-9, 11, 12 · **Requirements**: FR-021..FR-026, FR-045..FR-048, FR-052, FR-055..FR-068, FR-074..FR-078, FR-097..FR-099, FR-102

Conventions (verified against `OcrRepository`, `ConfirmScanBatch`, `FindPossibleDuplicate`): every fallible method returns `Future<Either<Failure, T>>` (fpdart), watchers return `Stream<Either<Failure, T>>`; use cases are `@injectable` classes with a `call(...)`; a repository contract lives in `domain/repositories`, platform and crypto ports in `domain/services`; domain is free of Flutter types; DI is by interface. Dates crossing the domain are `DateTime` (date-only values are normalized to local midnight by the implementation with `dateOnlyMillis`). Failure messages are fixed English tokens and **never** contain message content, amounts, names or digits (FR-097, FR-101). Domain packages under `lib/features/sms_import/domain/` may import `transactions`, `finance` and `people` domain interfaces, exactly as `ocr` does today.

---

## 1. Failures (`lib/features/sms_import/domain/entities/sms_import_failures.dart`)

All extend a feature base, which extends the core `Failure` (`lib/core/error/failure.dart`, `Equatable`, `message` only). Existing `ValidationFailure`, `CacheFailure`, `NotFoundFailure`, `UnknownFailure` are reused where they fit; the new subtypes carry **codes and counts only**.

```dart
abstract class SmsImportFailure extends Failure { const SmsImportFailure(super.message); }

/// Capability off (READ_SMS not declared, or non-Android): readSmsDeclared && Platform.isAndroid is false.
class SmsCapabilityUnavailableFailure extends SmsImportFailure {}

/// Permission not usable. [status] drives the dedicated UI state (FR-069/070/072).
class SmsPermissionFailure extends SmsImportFailure {
  final SmsPermissionStatus status;   // denied | permanentlyDenied | restrictedBlocked | revoked
}

/// The provider query failed (query_failed / invalid_args); retry at next resume.
class SmsInboxQueryFailure extends SmsImportFailure {}

/// Pasted/shared text exceeded the bound (FR-017). Nothing was stored.
class InputTooLargeFailure extends SmsImportFailure {
  final InputLimit limit;             // characters | messages
  final int max;                      // 10000 | 50
}

/// Paste/share text had no recognized bank message (FR-018). Nothing stored.
class NotRecognizedFailure extends SmsImportFailure {}

/// Add attempted on an item that is not pending (double tap, retry after type switch).
class ImportAlreadyDecidedFailure extends SmsImportFailure {
  final SmsImportStatus status;
}

/// Required fields (FR-043a) incomplete or invalid on Add; carries field codes only.
class ImportIncompleteFailure extends SmsImportFailure {
  final Set<ReviewField> fields;      // amount | currency | type | date | category | person
}

/// A probable duplicate exists and the caller did not set duplicateOverride (FR-060).
/// Not an error to log; the UI shows the side-by-side sheet.
class ProbableDuplicateFailure extends SmsImportFailure {
  final DuplicateFinding finding;
}

/// Raw text unreadable (key loss, tag failure); original unavailable (FR-045, FR-074a).
class OriginalUnavailableFailure extends SmsImportFailure {}

/// Scan or catch-up skipped because another run is in flight or a precondition failed.
class ScanNotAllowedFailure extends SmsImportFailure {
  final ScanBlockReason reason;       // disabled | noPermission | alreadyRunning | locked | capabilityOff
}
```

Mapping to the spec error table: permission denied/permanent/restricted/revoked -> `SmsPermissionFailure(status)`; not recognized -> `NotRecognizedFailure`; required field missing -> `ImportIncompleteFailure`; clipboard empty -> not a failure (UI state from `ClipboardReader` returning null); original text unavailable -> `OriginalUnavailableFailure`; save failed -> `CacheFailure` (item stays pending, FR-099); scan interrupted -> `ScanSummary.cancelled` / `processedBeforeInterruption` (state, not failure); DB unavailable -> `CacheFailure`; single-message parser failure -> counted `Unreadable(parserError)`, never a `Failure` (FR-098).

---

## 2. Domain services (ports) in `domain/services/`

| Interface | Methods | Impl (data) | Notes |
|---|---|---|---|
| `SmsInboxGateway`, `SmsPermissionService`, `SharedTextSource` | see [sms-platform-channel.md](sms-platform-channel.md) | `PlatformSmsInboxGateway`, `PlatformSmsPermissionService`, `PlatformSharedTextSource` | |
| `SmsMessageParser` | `parse`, `currentVersions`, `allowedSenders` | `RuleBasedSmsParser` over `SmsParserRegistry` | [parser-contract.md](parser-contract.md) |
| `SmsTextNormalizer` | `NormalizedText normalize(String)` | pure | |
| `SmsMasker` | `String mask(String original, {int threshold = 12})` | pure | FR-031a |
| `SmsMessageSplitter` | `Either<Failure, List<SplitMessage>> split(String)` | pure | FR-017 |
| `RawTextVault` | `Future<Uint8List> seal(String masked, {required String aad})`; `Future<String?> open(Uint8List blob, {required String aad})` (null = unreadable) | `AesGcmRawTextVault` (pointycastle `GCMBlockCipher(AESEngine())`) | AAD = pending id; format `0x01 | nonce(12) | ct | tag(16)` |
| `FingerprintHasher` | `Future<String> fingerprint(String normalizedBody)`; `Future<String> refHash(String bank, String ref)`; `Future<String> refAmountHash({bank, ref, currency, amountMinor, direction})` | `HmacFingerprintHasher` (`crypto` `Hmac(sha256, macKey)`) | outputs hex; inputs per research Decision 6 |
| `SmsKeyStore` | `Future<Uint8List> encKey()`, `macKey()`, `Future<void> purge()` | `SecureStorageSmsKeyStore` | single-flight lazy generation, write then read-back verify; exceptions mean "treat as purged", never logged |
| `ClipboardReader` | `Future<String?> readText()` | `SystemClipboardReader` (`Clipboard.getData(kTextPlain)`) | called only from the Paste button tap (FR-015); null for empty or non-text |
| `ReviewLeaseRegistry` | `Lease acquire(String importId)`; `bool isLeased(String importId)` | in-memory | a re-parse skips leased items (research Decision 7) |
| `AppClock` | existing `core/date/app_clock.dart` | | injected everywhere time matters |
| `LockStatus` | `bool get isLocked`; `Stream<bool> get changes` | adapter over `AppLifecycleObserver.isLocked` | catch-up and shared-text routing wait for unlock |
| `AppLifecycleStateSource` | `bool get isResumed` | adapter over `WidgetsBinding.instance.lifecycleState` | scans stop between pages when not resumed (FR-008a) |
| `ScanCoordinator` | `Future<T?> runExclusive<T>(ScanKind kind, Future<T> Function() body)` | in-memory mutex | one scan at a time across `RunInboxScan` and `RunCatchUpScan` (FR-013): an explicit scan cancels a running catch-up and waits for it; a catch-up while any scan runs is `skipped(alreadyRunning)` |
| `FingerprintNormalizer` | `String normalize(String body)` | pure, frozen v1 | FR-023; never changes with parser rules (parser-contract §3) |

---

## 3. Repository contracts

### 3.1 `SmsImportRepository` (pending, tombstones, decisions)

```dart
abstract class SmsImportRepository {
  // --- ingestion ---------------------------------------------------------

  /// Idempotent insert of one parsed suggestion. Returns [InsertOutcome.inserted]
  /// or [InsertOutcome.alreadyKnown] (fingerprint present in pending rows or
  /// tombstones, or tier-2 exact match). Never creates a MoneyTransaction or
  /// FinanceEntry (FR-022). Seals [rawMasked] with the vault inside the call;
  /// if sealing fails the row is stored with raw_blob = NULL.
  Future<Either<Failure, InsertOutcome>> insertPending(NewPendingImport item);

  /// Batched exact-tier lookup for one page: which of these fingerprints and
  /// (bank, refAmountHash) keys are already known. One query per page.
  Future<Either<Failure, KnownKeys>> findKnown({
    required Set<String> fingerprints,
    required Set<String> refAmountHashes,
  });

  /// Tier-3 helper: tombstone/pending refHashes for a bank, to decide
  /// "both present and different" (FR-059b).
  Future<Either<Failure, Set<String>>> refHashesForBank(String bankId);

  // --- reading -----------------------------------------------------------

  Stream<Either<Failure, List<PendingSmsImport>>> watchPending();   // ordered: low confidence first, then oldest first
  Stream<Either<Failure, int>> watchPendingCount();                 // Home card (FR-050)
  Future<Either<Failure, PendingSmsImport>> getById(String id);
  Stream<Either<Failure, List<PendingSmsImport>>> watchUndoList();  // ignored + expired, decided within 30 days
  Future<Either<Failure, int>> unseenExpiredCount();                // for the "N suggestions expired" notice (FR-025)
  Future<Either<Failure, Unit>> markExpiredNoticeSeen();

  /// Decrypts the masked original. Left(OriginalUnavailableFailure) when the
  /// item is not pending, has no blob, or the blob cannot be opened; on the
  /// first failed open the blob is nulled (FR-074a).
  Future<Either<Failure, String>> openOriginal(String id);

  // --- decisions (each in ONE transaction; raw_blob nulled in each) --------

  /// THE gate (FR-052). In one db.transaction: re-read the row and require
  /// status == pending (else ImportAlreadyDecidedFailure); create the record
  /// through TransactionsRepository.addSmsSourcedTransaction or
  /// FinanceRepository.addSmsSourcedEntry with idempotency key
  /// 'sms-import:<id>'; write the 'added' tombstone (savedRecordId, bank,
  /// refHash, refAmountHash); mark the row added; upsert the learned mapping
  /// when the chosen category differs from the suggestion; increment addedCount.
  /// A Left from an inner repository throws a private _ConfirmAborted so the
  /// whole transaction rolls back (the _BatchAborted idiom of OCR confirm).
  /// Called only by AddImportedTransaction.
  Future<Either<Failure, SavedRecordRef>> confirm({
    required String pendingId,
    required ConfirmedImport confirmed,
  });

  Future<Either<Failure, Unit>> ignore(Set<String> ids);            // single or batch; one transaction
  Future<Either<Failure, Unit>> closeAsDuplicate(String id);        // tombstone 'duplicate'
  Future<Either<Failure, Unit>> undo(String id);                    // ignored/expired only; deletes tombstone + row

  // --- maintenance -------------------------------------------------------

  /// Expires every pending row with expires_at <= now; returns how many.
  Future<Either<Failure, int>> expireDue(DateTime now);

  /// Deletes decided rows older than 30 days and tombstones past purge_after.
  Future<Either<Failure, PurgeResult>> purgeDecided(DateTime now);

  /// Replaces ONLY parsed-field columns and rule_version for one pending row,
  /// in one transaction; fingerprint, hashes, received_at, source, created_at
  /// are immutable (research Decision 7).
  Future<Either<Failure, Unit>> replaceParsedFields(String id, ReparsedFields fields);

  Future<Either<Failure, List<ReparseCandidate>>> pendingNeedingReparse(Map<String, int> currentVersions);

  /// Disable-with-delete (FR-078): removes all pending rows, no tombstones.
  Future<Either<Failure, int>> deleteAllPending();
}

enum InsertOutcome { inserted, alreadyKnown }

/// Sealed so the repository can pick the table without a boolean flag.
sealed class ConfirmedImport {
  String? get note;
  DateTime get date;
  Money get amount;
}
class ConfirmedFinanceEntry extends ConfirmedImport { final String categoryId; final FinanceEntryType type; ... }
class ConfirmedPersonTransaction extends ConfirmedImport { final String personId; final TransactionDirection direction; ... }
```

### 3.2 `SmsImportSettingsRepository` (settings, mutes, learned mappings, counters)

```dart
abstract class SmsImportSettingsRepository {
  Stream<Either<Failure, SmsImportSettings>> watchSettings();
  Future<Either<Failure, SmsImportSettings>> getSettings();             // creates the singleton lazily

  Future<Either<Failure, Unit>> setEnabled(bool enabled);
  Future<Either<Failure, Unit>> dismissOnboarding();
  Future<Either<Failure, Unit>> setScanWindow(ScanWindow window);
  Future<Either<Failure, Unit>> setCountCashWithdrawals(bool value);
  Future<Either<Failure, Unit>> markPermissionRequested();
  Future<Either<Failure, Unit>> advanceCursor({required DateTime date, required int id});
  Future<Either<Failure, Unit>> recordScan({required DateTime at, required bool catchUp});
  Future<Either<Failure, Unit>> addCounts({int scanned = 0, int recognized = 0, int added = 0, int ignored = 0});
  Future<Either<Failure, Unit>> setRulesSeen(Map<String, int> versions);

  Stream<Either<Failure, Set<String>>> watchMutedSenders();
  /// One transaction: inserts the mute (canonical upper-case) and deletes that
  /// sender's pending rows (no tombstones, as in FR-078). Returns the deleted count.
  Future<Either<Failure, int>> muteSender(String senderId);
  Future<Either<Failure, Unit>> unmuteSender(String senderId);

  Stream<Either<Failure, List<MerchantCategoryMapping>>> watchMappings();
  Future<Either<Failure, Map<(String, String), String>>> getMappingMap();
  Future<Either<Failure, Unit>> removeMapping(String merchantKey, String entryType);
  Future<Either<Failure, Unit>> clearMappings();                        // "Clear learned categories" (FR-056)
}
```

### 3.3 `SmsDuplicateLookup` (read-only, spans both aggregates; FR-060)

```dart
abstract class SmsDuplicateLookup {
  /// Probable tier 1 for one pending item with CURRENT edited values.
  /// Same currency and amount, date within one day (calendar arithmetic
  /// DateTime(y, m, d-1/d+1), never Duration math), direction group
  /// (expense=given, income=received), deleted_at IS NULL, any source.
  /// Returns refs only (id, kind, direction/type, date, importSource).
  Future<Either<Failure, List<DuplicateRecordRef>>> findSavedMatches({
    required Money amount,
    required DateTime date,
    required SuggestedRecordType type,   // expense | income | given | received
  });

  /// One query for a whole ingestion page: all rows of both tables in
  /// [minDate-1d, maxDate+1d], indexed in memory as (currency, amount).
  Future<Either<Failure, SavedRecordWindow>> loadWindow(DateTime minDate, DateTime maxDate);

  /// Tier 1 branch (2): another pending item with same card last four,
  /// merchant key and amount within 10 minutes, no reference ID, parsed time
  /// on both. Uses idx_sms_pending_amount_pair.
  Future<Either<Failure, PendingSmsImport?>> findPendingPair(PendingSmsImport item);

  /// SMS-sourced match refinement (FR-059a): the tombstone refHash of an
  /// existing record, by saved_record_id.
  Future<Either<Failure, String?>> refHashForSavedRecord(String savedRecordId);
}
```

The existing person-scoped `FindPossibleDuplicate` is **not changed** (FR-060). Implementation: `SmsDuplicateDao` over the two tables.

---

## 4. Extensions to existing repositories (single review gate)

Both follow `addOcrSourcedTransaction` (`transactions_repository.dart:192`): documented "only the SMS repository calls this", same validation as the manual path, idempotent insert plus `created` audit in one local transaction, enqueued to the sync outbox by the existing DAO path. Because `SmsImportRepositoryImpl.confirm` runs in an outer `_db.transaction`, the inner `_db.transaction` calls join it (Drift nesting), which is what gives FR-075a's atomicity.

```dart
// TransactionsRepository (+ TransactionsRepositoryImpl.addSmsSourcedTransaction)
/// Called only by SmsImportRepositoryImpl.confirm. [kind] is always
/// initialExchange (NG8: no repayment, no occasion). Writes
/// source = manual (FR-086, never a new enum value) and import_source = 'sms'.
/// Validation = _validateAmountAndPerson (same as addTransaction).
/// Idempotent on [idempotencyKey] ('sms-import:<pendingId>').
Future<Either<Failure, MoneyTransaction>> addSmsSourcedTransaction({
  required String idempotencyKey,
  required String personId,
  required Money amount,
  required TransactionDirection direction,
  required DateTime date,
  String? note,
});

// FinanceRepository (+ FinanceRepositoryImpl.addSmsSourcedEntry)
/// Called only by SmsImportRepositoryImpl.confirm. Same validation as
/// addEntry (positive amount, non-empty category, category type == type via
/// _validateCategoryMatches, active category). Writes import_source = 'sms'.
/// Idempotent on [idempotencyKey]; writes the FinanceAuditChange.created row.
Future<Either<Failure, FinanceEntry>> addSmsSourcedEntry({
  required String idempotencyKey,
  required String categoryId,
  required FinanceEntryType type,
  required Money amount,
  required DateTime date,
  String? note,
});
```

Domain model changes: `MoneyTransaction.importSource` and `FinanceEntry.importSource` (`ImportProvenance?`, [data-model.md](../data-model.md) 3.6). `editTransaction` / `editEntry` must not alter it; `watchHistory` and detail reads expose it for the "Imported from a bank message" label (FR-057).

Each method asserts `idempotencyKey.startsWith('sms-import:')` in debug builds and a repository test proves the type-switch retry case: attempt Add as `expense`, fail after insert (simulated), retry as `given` -> `ImportAlreadyDecidedFailure`/a single record in total (the status guard inside the same transaction covers it).

---

## 5. Use cases (`lib/features/sms_import/domain/usecases/`)

All `@injectable`, returning `Either<Failure, T>` unless stated. "Gate" notes name the FR each exists to satisfy.

### 5.1 Capability, permission, enablement

| Use case | `call(...)` | Returns | Behavior |
|---|---|---|---|
| `GetSmsCapability` | `()` | `SmsCapability` | Never fails; no prompt |
| `GetSmsPermissionStatus` | `()` | `SmsPermissionStatus` | Prompt-free refresh (`SmsPermissionService.getStatus`); used on resume (FR-070), mirrors `request_notification_permission.dart`'s `refresh()` |
| `RequestSmsPermission` | `()` | `SmsPermissionStatus` | Reads, then persists `permissionRequested` and passes the value read as `previouslyRequested` (phase6b), wraps `SmsPermissionService.request()` in `runExternalActivity` (through an injected `ExternalActivityRunner` port so domain stays Flutter-free); refuses when capability unavailable (`SmsCapabilityUnavailableFailure`). Only caller of `request()` (FR-002) |
| `OpenSmsAppInfo` | `()` | `Unit` | `SmsPermissionService.openAppInfo()` |
| `EnableSmsImport` | `({required ScanWindow window})` | `EnableResult {status, enabled}` | Precondition: the UI already showed the explanation (the cubit state machine enforces it; the use case takes `explanationAcknowledged: true` and returns `ValidationFailure` otherwise). Calls `RequestSmsPermission`; on `granted` sets `isEnabled = true` and `scanWindow`; on `denied|permanentlyDenied|restrictedBlocked` leaves it off and returns the status for the guidance UI. Does **not** start the scan |
| `DisableSmsImport` | `({required bool deletePending})` | `int` (deleted count) | Sets `isEnabled = false` first (so a running scan stops between pages), then `deleteAllPending()` if asked; keeps mutes, mappings, tombstones (FR-056, FR-078) |
| `UpdateSmsImportPreferences` | `(SmsPreferenceChange)` sealed: `ScanWindowChanged`, `CountCashChanged`, `OnboardingDismissed` | `Unit` | Thin but centralizes the settings writes the UI can make |

### 5.2 Ingestion

Shared domain service `SmsIngestionService` (not user-facing; used by the use cases below):

```dart
Future<Either<Failure, ScanSummary>> ingest({
  required List<RawIncoming> messages,        // {text, sender?, receivedAt?, providerId?}
  required SmsSource source,
  required ScanCancellationToken token,
  void Function(ScanProgress)? onProgress,
});
```

Per call: normalize -> `SmsMessageParser.parse` -> for each `ParsedTransaction` compute `fingerprint`, `refHash`, `refAmountHash` (from the **unmasked** values) -> `findKnown` (exact tiers 1 and 2, one query per page) -> mask the original -> seal -> `insertPending` -> counts. `NonTransactional` and `Unreadable` store nothing. One hostile message never stops the others (FR-098). The fingerprint input comes from the frozen `FingerprintNormalizer`, never from `SmsTextNormalizer` (FR-023). An in-message `fee` stages a second pending fee item linked by `parentImportId`, with fingerprint `fp1|fee|...` and no reference hashes (FR-030a). Pages are persisted in a transaction together with the cursor advance (scan/catch-up); cancellation stops between messages and leaves created items intact (FR-007). Raw bodies are not retained after the page.

| Use case | `call(...)` | Returns | Behavior / FRs |
|---|---|---|---|
| `ParseMessages` | `({required List<RawIncoming> messages, required SmsSource source})` | `List<ParseOutcome>` (parse + classify only, no persistence) | Pure orchestration used by `SmsIngestionService` and by tests; also the "dry parse" for the debug inject tile |
| `RunInboxScan` | `({required ScanWindow window, required ScanCancellationToken token, void Function(ScanProgress)? onProgress})` | `ScanSummary` | Preconditions: enabled, `granted`, capability. Allow-list = `parser.allowedSenders - mutes`. Pages `queryInbox` from `now - window` (cursor reset for an explicit scan) until a short page; defensive sender re-check; stops between pages when the lifecycle state is not `resumed` (an explicit scan then returns `cancelled = true` and keeps its cursor, FR-008a); `ScanSummary` has found / created / alreadyKnown / non-transactional / unreadable / cancelled. Bypasses the 60 s debounce; runs inside `ScanCoordinator.runExclusive` (cancels a running catch-up first); sets `lastScanAt`. FR-006, FR-007, FR-020 |
| `RunCatchUpScan` | `()` | `CatchUpOutcome` = `skipped(ScanBlockReason)` \| `ran(ScanSummary)` | Same pipeline from `cursor - 24h` capped at 90 days; skip (not failure) when disabled, not granted, locked, already running or `lastCatchUpAt` < 60 s old; single-flight (`Future<bool>? _inFlight` joined by concurrent callers, the idiom of `notification_recompute_trigger.dart:69`) and inside `ScanCoordinator.runExclusive`, skipped when an explicit scan holds it; checks `enabled` and permission between pages so disable/revocation stops it immediately, and stops between pages whenever the lifecycle state is not `resumed` (FR-008a; waits for a post-frame callback before checking `isLocked` and re-checks it between pages, so it cannot race App Lock's asynchronous lock); at the end runs `ExpirePendingImports` and `ReparsePending`. Never throws; failures counted content-free and retried at the next resume. FR-013 |
| `ImportPastedText` | `({required String text, required SmsSource source /* paste | share */})` | `PasteImportResult {summary: ScanSummary, newIds: List<String>, notRecognized: bool}` | `SmsMessageSplitter.split` (bounds) -> ingest with `sender = null`, `receivedAt = null`; if no item recognized -> `Left(NotRecognizedFailure)` and nothing stored; summary states recognized and skipped (FR-017, FR-018). Confidence capped at Medium by the pipeline |
| `ImportSharedText` | `()` | `Stream<Either<Failure, PasteImportResult>>`-driving use case | Thin: reads `SharedTextSource.takeInitial()` and `.stream`, waits for `LockStatus.isLocked == false`, then calls the same code path as `ImportPastedText(source: share)`. The text exists only in an in-memory `SharedTextInbox` until consumed (FR-016a, FR-079). The routing side is in ui-contract.md |
| `ReadClipboardText` | `()` | `String?` | Only from the Paste button tap (FR-015); a widget test asserts no `Clipboard.getData` before the tap |

### 5.3 Reading, review and decisions

| Use case | `call(...)` | Returns | Behavior / FRs |
|---|---|---|---|
| `GetPendingImports` | `()` | `List<PendingSmsImport>` | Sorted low confidence first, then oldest first (FR-042 ordering only) |
| `WatchPendingImports` | `()` | `Stream<Either<Failure, List<PendingSmsImport>>>` | Drives the list and Home card count (`WatchPendingImportCount`) |
| `GetExpiredNotice` / `AcknowledgeExpiredNotice` | `()` | `int` / `Unit` | "N suggestions expired" notice on next list open (FR-025, US1-10) |
| `GetPendingImport` | `(String id)` | `PendingSmsImport` | `NotFoundFailure` when absent |
| `ShowOriginalMessage` | `(String id)` | `OriginalMessage {text, direction}` | `repository.openOriginal` plus direction from first strong character (`Bidi.detectRtlDirectionality`); `OriginalUnavailableFailure` otherwise (FR-045) |
| `CheckDuplicates` | `({required PendingSmsImport item, required ReviewDraft draft})` | `DuplicateFinding` | Order fixed by FR-059b: (1) fingerprint exact (already done at ingestion; re-checked), (2) same bank + ref + amount + direction exact via `refAmountHash`, (3) both `refHash` present and different -> `legitimatelySimilar`, stop, (4) probable: saved-record match of any source and aggregate, same currency, +/-1 day, direction group; skipped when the existing record is SMS-sourced and both reference hashes are present and differ; and the pending-pair rule. Uses the **draft's current values** (FR-060); never blocks (FR-063). Tier 2 applies only when the profile's `refIsUnique` is true, else it also needs a date within one day (FR-059b). The probable rule also compares the stated `foreignAmount` against saved records in that currency (FR-059). Candidates are ranked by merchant/note similarity, then closest date, and only the best one is returned. Adds `possibleOwnTransfer` when an opposite-direction item of the same amount and currency from a different bank or channel exists within one day among pending items or SMS-sourced saved records (FR-051d). For an `authorizationReversal` item it returns the matching saved expense or Given record (same `refHash`, or same amount and currency within one day) for the side-by-side card (FR-024b) |
| `AddImportedTransaction` | `({required String pendingId, required ReviewDraft draft, bool duplicateOverride = false})` | `SavedRecordRef` | **The only place an import becomes money** (Principle X by analogy, FR-052). Steps: load item (`pending` or `ImportAlreadyDecidedFailure`); `draft.validate()` (pure domain, mirrors manual limits: amount > 0 and <= 12 whole digits, catalog currency, note <= 500, category type == entry type, valid date) -> `ImportIncompleteFailure`; unless `duplicateOverride`, `CheckDuplicates` -> `Left(ProbableDuplicateFailure)` when `probable`; then `SmsImportRepository.confirm` with a `ConfirmedFinanceEntry` or `ConfirmedPersonTransaction`. No timer, background path or batch variant calls it (no "add all", FR-046). A person for given/received is created beforehand by the review cubit through the existing `CreatePerson` only after the user's explicit tap (FR-054) |
| `IgnoreImport` | `({required Set<String> ids})` | `Unit` | Single or batch; the UI confirms a batch first (FR-064). `repository.ignore` |
| `CloseAsDuplicate` | `(String id)` | `Unit` | "It's the same, don't add" (FR-061) |
| `UndoIgnore` | `(String id)` | `UndoResult {needsRescan: true}` | Ignored or expired only; removes the tombstone; the UI says the message returns after re-scan, re-paste or share (FR-067, FR-068) |
| `WatchUndoList` | `()` | stream | 30-day Undo list |
| `MuteSender` / `UnmuteSender` | `(String senderId)` | `int` (deleted pending rows) / `Unit` | Canonical upper-case. `MuteSender` deletes that sender's pending rows (no tombstones, as in FR-078) in the same transaction as the mute, so no pending items and no stored content remain (FR-065); repository test. Future messages are skipped. "Stop suggesting from this sender" is offered only for items with a `senderId` |
| `WatchMutedSenders`, `WatchLearnedMappings`, `RemoveLearnedMapping`, `ClearLearnedMappings` | | | Settings screens (FR-056) |
| `GetScanCounts` | `()` | `SmsImportCounts` | FR-102 content-free counters |

### 5.4 Maintenance and deletion

| Use case | `call(...)` | Returns | Behavior / FRs |
|---|---|---|---|
| `ExpirePendingImports` | `({DateTime? now})` | `int` | `expireDue` then `purgeDecided`; run on opening the pending list, at the end of every scan/catch-up, and after unlock at app start. Idempotent (FR-025, FR-066, SC-011) |
| `ReparsePending` | `()` | `int` re-parsed | Runs when `parser.currentVersions` differs from stored `rulesSeen` (list open, post-update). For each pending item that is **not leased** by an open review: `openOriginal` (masked text) -> parse with the stored `source`/`senderId`/`receivedAt` -> `replaceParsedFields` (hashes immutable). Items whose blob cannot be opened keep their fields (FR-026). Saved records are never touched. Updates `rulesSeen` |
| `ClearSmsImportData` | `(ClearScope scope)` | `Unit` | `scope`: `pending` (disable flow), `learnedMappings`, `mutedSenders`. Does not clear tombstones (they are what stops resurfacing); full wipe is Delete-all |
| `PurgeSmsImportKeys` | `()` | `Unit` | Deletes `sms_import.enc_key.v1` and `sms_import.mac_key.v1`; called by `DeleteAllUserData` beside `PurgeAIAssistantCredentials` |

`DeleteAllUserData` (existing) gains `PurgeSmsImportKeys` as a dependency; the five tables are wiped by `AppDatabase.deleteAllUserData`.

---

## 6. Shared value types (summary; full field lists in data-model.md)

`RawIncoming{text, sender?, receivedAt?, providerId?}`, `NewPendingImport` (all persisted fields + `rawMasked` + hashes), `ReparsedFields`, `ReparseCandidate{id, source, senderId, receivedAt, ruleVersion}`, `SavedRecordRef{id, type: moneyTransaction|financeEntry}`, `KnownKeys{fingerprints, refAmountHashes}`, `PurgeResult{rows, tombstones}`, `ScanProgress{processed, total?}`, `ScanCancellationToken{bool isCancelled; void cancel()}`, `ReviewDraft{type, amount, currency, date, categoryId?, personId?, note?}` with pure `validate() -> Set<ReviewField> missing`, `PasteImportResult`, `SmsImportCounts{scanned, recognized, added, ignored}`.

## 7. Invariants (tested)

1. `ingest` never calls `TransactionsRepository` or `FinanceRepository` (a mock-strict test; SC-002, FR-022).
2. `addSmsSourcedTransaction` / `addSmsSourcedEntry` have exactly one non-test caller, `SmsImportRepositoryImpl.confirm` (a source-grep guard like the OCR one).
3. `confirm` on a non-pending row returns `ImportAlreadyDecidedFailure` and writes nothing; two concurrent `confirm` calls yield one record.
4. After every terminal transition `raw_blob IS NULL`; after expiry the same.
5. No failure `message` contains digits from a message, an amount, a merchant or a name.
6. `RunCatchUpScan` makes no `queryInbox` call when disabled, not granted, locked, or inside the debounce.
7. `ExportUserData` has no dependency on any interface in this document.
8. `MuteSender` leaves no pending row and no tombstone for that sender (FR-065).
9. `RunInboxScan`/`RunCatchUpScan` make no `queryInbox` call after the lifecycle state leaves `resumed` (fake-lifecycle test).
10. `RunInboxScan` and `RunCatchUpScan` never run at the same time (`ScanCoordinator` test).
11. A parser-rule version change never changes the fingerprint of a staged or tombstoned message (golden test, FR-023).
