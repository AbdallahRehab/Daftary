# Decisions: Phase 2a — core promotion and pure domain (T016-T034)

Slice: T016, T017, T018 (core), T019-T034 (domain, provenance, entity fields, purity guard, fakes). No Drift, DI or build_runner work. Nothing in this slice needs generated code.

## Core (T016-T018)

1. **T016 test move.** As discovery/importers.md §1 found, there is no `field_confidence_test.dart`, so nothing moves into `test/core/confidence/`. The only moved test is `test/widget/confidence_indicator_test.dart` → `test/core/design_system/confidence_indicator_test.dart`. No new test was created in T016, so its diff holds only the three `git mv`s and import lines (7 lib files, 9 test files, plus the moved files' own imports). The `app_database.dart:219` doc-comment mention of `FieldConfidence` was left alone.
2. **T017.** `toWesternDigits` now maps U+06F0-U+06F9 as well. The existing separator mapping (`٫` → `.`, `٬` → `,`) is unchanged, and Western input is returned unchanged. The class doc comment was updated to name both digit ranges.
3. **T018.** `kBankMessageImportFeatureEnabled = true`. Its doc comment says it gates only the Home entry points and is not the inbox capability (orchestrator CHK013). No capability const was added.

## Domain (T019-T031)

4. **`SmsSource` Dart names.** T019 lists the stored values (`scan|catchup|paste|share`). data-model §2.1 names the Dart values `inboxScan`/`catchUpScan`/`paste`/`share` with those DB values, and I used that.
5. **Safe defaults for unknown stored strings (T019).** Each was chosen so an unknown value can never enable Add or invent a claim:
   - `SmsImportStatus` → `duplicateClosed`: terminal, so Add is impossible; not in the Undo list; purged like any decided row. Mapping to `pending` could re-add a decided row.
   - `TombstoneOutcome` → `duplicate`: still blocks resurfacing and claims no saved record.
   - `SmsSource` → `paste`: no sender, no receipt time, confidence capped at Medium.
   - `SmsKind`/`SmsDirection` → `unknown`; `SuggestedRecordType` → `unset`; `OverallConfidence` → `low`; `ScanWindow` → 30 days.
   - `SavedRecordType` and `SmsWarning` → `null`, so an unknown warning is dropped, never reinterpreted.
   DB strings: `SmsKind` uses snake_case, as data-model §2.3 says. data-model gives no format for `SmsWarning`, so it uses snake_case for consistency (the T036/T041 mappers must use `dbValue`). `SavedRecordType` uses `moneyTransaction|financeEntry`, as data-model §3.1 writes it.
6. **`ParseResult` has four variants (T021).** tasks.md lists `Parsed | NotRecognized | NonTransactional | Unreadable`, but parser-contract §4 lists only three. I added `NotRecognized`: "not a bank message at all", which drives FR-018 for paste/share. "Parsed" in the task is shorthand for parser-contract's `ParsedTransaction`, which is the class name used. `NonTransactionalReason` and `UnreadableReason` live in `parse_result.dart`, and `SmsField` lives in `parse_confidence.dart`.
7. **`PendingSmsImport` invariants (T022).** The constraints are checked by `invariantViolations` (a `Set<PendingImportInvariant>` of codes, never values), which the constructor `assert`s. They are not thrown in release: a row read back from the DB must never crash the list, so the repository should check `invariantViolations` before it writes. Two extra data-model rules are included: `timeMinutes` in 0..1439 (§4.1), and `savedRecordId`/`savedRecordType` set together and only when `added` (§3.1). `expiresAt` must equal `createdAt.add(Duration(days: 30))` (`PendingSmsImport.expiryFor`). The fields are **exactly** data-model §3.1. **Flag for T061/CheckDuplicates:** data-model §4.1 persists `foreignAmountMinor`/`foreignCurrency` in `warnings_json` for FR-059, but §3.1 lists no `foreignAmount` field, so the entity has none. If CheckDuplicates needs it on the entity, add a nullable `Money? foreignAmount` additively.
8. **No `copyWith` on `PendingSmsImport`.** It isn't in data-model, and the repository rebuilds rows from DB data. The fakes use a test-local `pendingWithDecision` helper. `SmsImportSettings` and `ReviewDraft` do get a `copyWith` (with `clearX` flags, the state-management.md style), because the settings fake and the review cubit need them.
9. **`SmsPermissionStatus` includes `unavailable`** (data-model §2.9 and sms-platform-channel §6), even though T024 lists five values. `SmsPermissionResult` (the five facts of channel §2.3) and `SmsInstallSource` live in `sms_permission_status.dart`.
10. **`revoked` in the classifier (T029).** Research Decision 2 says the classifier yields `revoked`, but its signature `(result, previouslyRequested)` has no input that could produce it. I added an optional `previouslyGranted = false`. Order: granted → revoked (when previously granted; a prior grant rules out restricted settings) → restrictedBlocked → permanentlyDenied → denied. The request path passes `false`. The test table covers all 16 `{granted, dialogShown, shouldShowRationale, previouslyRequested}` combinations × sdk 33-36 × the 3 install sources (192 cases), plus the revoked cases. An `unknown` install source on API 35+ counts as "not a store", following the contract's `installSource != store` literally.
11. **`overallConfidence` signature (T028).** I used tasks.md's `overallConfidence(fields, {required bool capMedium})`, plus a helper `confidenceCapsAtMedium({isGeneric, source})` that covers parser-contract §6's `{isGeneric, source}` form. When every required field is inferred, the result is Medium (start at High, apply the inferred cap). Optional fields never affect the result.
12. **`ReviewDraft` shape (T026).** The fields are `amountMinorUnits: int?` and `currencyCode: String?` rather than a `Money amount`, because a draft can hold an amount with no currency (paste). `money` gives a `Money` only for a catalog currency. `ReviewField` gained a **`note`** code, because domain-interfaces §1 lists none and T026 requires note <= 500. The note is measured in Unicode code points (`runes`). The manual form's `maxLength: 500` counts grapheme clusters, and the `characters` package is not a direct dependency (I changed no pubspec). So a 500-grapheme note with combining marks could exceed 500 runes and be flagged. That is strictly safer than lenient. The review page (T082) should show the `note` code. Category/person are required by type; a blank string counts as missing. "Valid date" means present. The manual forms accept future dates, so no other date rule exists to mirror.
13. **Value types (T027).**
    - `NewPendingImport` wraps a `PendingSmsImport` plus `rawMasked`, rather than duplicating ~35 fields. Its `hasRawText` is ignored on insert.
    - `ReparsedFields` excludes `bankId`, because the hashes depend on the bank and are immutable.
    - `ScanBlockReason` gained `debounced` and `notResumed`, because `RunCatchUpScan` skips for those (contract §5.2) and the contract list lacked them.
    - `SkippedEntry.reason` is a new `SkipReason` enum (the unreadable reasons plus `notRecognized`).
    - `OriginalMessage.direction` is a domain enum `TextDirectionHint`, so the domain needs no Flutter `TextDirection`.
    - `DuplicateFinding` gained `possibleOwnTransfer` (FR-051d), because `CheckDuplicates` must report it and returns only a finding. `DuplicateRecordRef.type` reuses `SuggestedRecordType` (expense|income|given|received).
    - `SavedRecordWindow` (needed by `SmsDuplicateLookup.loadWindow`, not in the §6 list) indexes refs by `Money`.
    - `ClearScope` lives here too.
    - `ConfirmedImport` and `InsertOutcome` live in `sms_import_repository.dart`, as in the contract.
14. **Ports (T030).**
    - `ScanCoordinator.runExclusive(kind, token, body)` takes the caller's `ScanCancellationToken`. The contract's `(kind, body)` gives the coordinator no way to cancel a running catch-up, which FR-013 requires. A `bool get isRunning` was added.
    - `SmsMessageParser.parse(input, {ParserOptions options = const ParserOptions()})`: the contract shows `parse(input)` but also says options come from `ParserOptions`, which change per scan (learned mappings), so they are a parameter with a default.
    - `ParserOptions.activeCategoryKeysByType: Set<String>` cannot "resolve seed keys -> ids". It is `activeCategoryIdsBySeedKey: Map<String, String>` instead. `learnedCategoryIds` is keyed `(merchantKey, entryType dbValue)`, matching `getMappingMap`.
    - The ports use `dart:typed_data`, which is pure and allowed. `ExternalActivityRunner.run<T>(body)` and `ReviewLease` (with `importId` and `release()`) are defined here.
15. **Repository contracts (T031)** follow domain-interfaces §3.1-3.3 signatures verbatim. The `ConfirmedImport` subclasses are Equatable with a redacted `toString`.
16. **Redaction.** Every Equatable type that can carry SMS-derived content overrides `toString`: `ParsedTransaction`, `PendingSmsImport`, `ReviewDraft`, `RawIncoming`, `NewPendingImport`, `ReparsedFields`, `OriginalMessage`, `DuplicateRecordRef`, `DuplicateFinding`, `InboxSmsMessage`, `SharedText`, `SmsParseInput`, `SplitMessage`, `NormalizedText`, `PersonNameRef`, `ParserOptions`, `MerchantCategoryMapping`, `SmsImportTombstone` and `ConfirmedImport`. `SmsImportFailure.toString` prints the type, the fixed token and its enum codes only. A test asserts that no failure's `message` or `toString` contains any digit.

## Entities (T032)

17. Per the orchestrator decision, `RecordProvenance { manual, ocr, sms }` is in `lib/core/provenance/record_provenance.dart`. `MoneyTransaction.provenance` returns it: `ocr` first (when `source == ocr`), then `sms` (when `importSource?.isSms`), else `manual`. An `unknown` future provenance reads as `manual`.
    - `ImportProvenance` is a class with an `ImportProvenanceKind` enum, a `static const sms`, and a `static fromWire(String?)` that keeps the original string for unknown values. Equality compares the wire string, as data-model §2.8 says.
    - Neither entity gained a `copyWith`. Only the constructor param (default null, last) and the `props` entry were added, so all existing constructors compile unchanged.
    - No entity tests existed before, so new ones were created: `test/features/transactions/domain/entities/money_transaction_test.dart` and `test/features/finance/domain/entities/finance_entry_test.dart`.
    - Mapping the column in `transaction_mapper.dart`/`finance_entry_mapper.dart` waits for the v13 column (T036 and later). It is not in this slice.

## Tests (T033, T034)

18. **T033.** The purity guard rejects `package:flutter*`, `package:drift*`, `dart:io`, `dart:ui` and `*services.dart` under `sms_import/domain`. It checks both directions between `sms_import` and `ai_assistant` (package and relative URIs, with a positive control).
19. **T034.** The fakes cover every T030 port and every T031 repository, plus `FixedClock` and `InMemorySecureStorage` (a `Fake implements FlutterSecureStorage` with a throw switch). `FakeSmsImportRepository` implements the data-model §6 state machine in memory. Its `confirm` writes no real record; T070 uses a real database. `test/features/sms_import/helpers/builders.dart` adds `buildPendingImport`, and `helpers/fakes_test.dart` smoke-tests the fakes' contract behaviour.
