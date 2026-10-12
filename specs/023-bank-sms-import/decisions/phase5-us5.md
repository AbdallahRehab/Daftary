# Phase 5 (US5) decisions: duplicate protection (T099, T170, T100–T103)

I owned codegen for this slice. I ran `fvm dart run build_runner build --delete-conflicting-outputs` (it regenerated `injection.config.dart`: `CloseAsDuplicate` registered, `ImportReviewCubit` gets one more argument; a second run was a no-op) and `fvm flutter gen-l10n` (l10n.yaml exists; generated files committed). I did not touch `android/**`, `.github/**`, `tool/**`, `data/platform/**` or `sms_platform_module.dart`, and ran no Android or iOS build.

## Results

See "Verification" at the end for the observed counts.

| Task | Status | Evidence |
|---|---|---|
| T100 `CloseAsDuplicate` + `closeAsDuplicate` | [X] | `data/repositories/close_as_duplicate_test.dart`: 8 tests (tombstone `duplicate` with bank and hashes, blob nulled, identity-shell scrub, no saved record/outbox/counter touched, never resurfaces, not on the Undo list, `ImportAlreadyDecided` on a second close and on an added item, NotFound content-free, store failure rolls back to a fixed token). A mutation that skipped the tombstone insert failed this file. |
| T101 `DuplicateComparisonCard`, `ProbableDuplicateSheet`, `smsImportDuplicate*` | [X] | `presentation/widgets/probable_duplicate_sheet_test.dart`: 17 tests. The transactions `DuplicateWarningSheet` is unchanged (no diff). |
| T102 wiring into `ImportReviewCubit` / `ImportReviewPage` | [X] | Cubit test +13, page test +9 (incl. the RTL/LTR × light/dark matrix over the sheet). The `showAppConfirmDialog` placeholder is gone. |
| T103 sheet + cubit tests, existing suites re-run | [X] | As above. The existing `FindPossibleDuplicate`/`DuplicateWarningSheet` users (`transaction_form_cubit_test`, `transaction_form_dialogs_test`, `find_possible_duplicate_person_test`, `no_op_for_egp_only_user_test`) re-run unchanged: 50 passed. |
| T099 duplicate scenario suite | [X] | `domain/duplicate_scenarios_test.dart`: 33 tests on one real in-memory DB (real parser, frozen normalizer, HMAC, AES-GCM, staging repo, `SmsDuplicateDao`, `CheckDuplicates`, `AddImportedTransaction`, `CloseAsDuplicate`, real finance and transaction repos). |
| T170 cross-path fingerprint | [X] | `domain/cross_path_fingerprint_test.dart`: 36 tests: scan (`RunInboxScan` on a fake gateway) ↔ catch-up ↔ paste ↔ share in both orders, sender/receipt time not inputs, every `_paste/envelopes/` case in both orders (inbox first, paste first), and a rule-version bump of every profile followed by a re-scan for pending, added, closed and purged-row cases. |

New shared test helper: `test/features/sms_import/helpers/pipeline_harness.dart` (the whole pipeline on one in-memory DB; only platform edges and the settings store are fakes).

## Decisions

| # | Ambiguity | Choice | Why |
|---|---|---|---|
| 1 | `closeAsDuplicate` write path: `transitionRow` (2d #17) writes no tombstone and no scrub | Its own single transaction, mirroring `confirm`: re-read inside the transaction, `canTransition` guard → `ImportAlreadyDecidedFailure(current)`, tombstone `duplicate` (bank, `refHash`, `refAmountHash`, no saved record), then `_identityShell` + status `duplicate` + `decided_at`. Any throw → `CacheFailure('sms_import_store_failed')`. No counter moves. | data-model §6 row "It's the same, don't add". The data-model counters are added/ignored/scanned/recognized only; there is no duplicate counter. |
| 2 | The "not yet implemented" repository test listed `closeAsDuplicate` | Removed `closeAsDuplicate` from that list (ignore/undo stay). Its behaviour is covered by the new file. | The method is now implemented by design. The test's intent ("unimplemented decisions refuse") is unchanged for the methods that are still stubs. Not a weakening. |
| 3 | Where the check runs | Unchanged from Phase 3: on open (after category/person reconciliation) and debounced after every edit; `AddImportedTransaction` re-checks on the current draft. A `ProbableDuplicateFailure` at Add opens the sheet instead of failing. | FR-060, ui-contract §3.4 items 8 and Behavior. |
| 4 | "It's the same, don't add" entry points | The sheet only (reached from Add, or from the banner's new **Compare** button). No separate overflow item on the review page. | The user always sees the side-by-side comparison before closing. Fewer write paths. ui-contract lists an overflow item; the banner action covers the same need, and the sheet is the place the contract defines the action. |
| 5 | Outcome state after closing | New `ImportReviewStatus.closedAsDuplicate` (plus `ImportReviewState.isSettled`, used by the page's `PopScope` and `requestLeave`). Same navigation as Add: `pushReplacement` to the next pending item, else back to the list; snackbar and announcement "Not added. It's already in Daftary." | A distinct confirmation; "Added" would be false. |
| 6 | Pending-pair findings carry no `matchedRecord` | The cubit loads the other pending item (`duplicatePending`) through `GetPendingImport` whenever a probable finding has `matchedPendingId`, and clears it when the finding goes away. The sheet's start card is then titled "Another bank message" with its type, amount, date and source. | The other side of a pending pair is not "in Daftary" yet; the title says so. |
| 7 | Side contents vs the contract ("category or person") | Type label, amount, date, the note's first line, and the "Imported from a bank message" label for the saved side; type, amount, date and source label ("From SMS"/"Pasted"/"Shared") for the message side. No category/person name. | T101's acceptance names type, amount, date and source label. `DuplicateRecordRef` carries no category/person name, and loading one would need a new cross-feature lookup. Follow-up if wanted. |
| 8 | Text-only differences | `duplicateComparisonPhrases`: "Same amount", or "Same as the original amount in the message" when the saved record equals the stated original amount (FR-059); plus "Same day / 1 day apart / N days apart" in calendar days (shared `calendarDaysApart`). | ui-contract §3.6: differences by text, not colour. |
| 9 | Stacking rule | Stacked at text scale ≥ 1.3 or sheet width < 360 dp, else side by side with `IntrinsicHeight`. "Already in Daftary" is first (start edge) in both directions; tested in all four locale/theme combinations. | ui-contract §3.6, §7.5. |
| 10 | Announcement | The sheet announces "Possible duplicate found" assertively once, on its first frame (ui-contract §5 lists it as assertive; §3.6 says polite; I took §5, the stricter list). The page no longer announces it separately, so it is said once on both entry paths. | One announcement per open. |
| 11 | ARB keys | Added 16 `smsImportDuplicate*` keys (en + ar, MSA). One plural (`smsImportDuplicateDaysApart`): EN `=0/=1/other`, AR all six forms. Removed the 4 placeholder keys `smsImportReviewDuplicate{Title,Message,AddAnyway,GoBack}`; their only user was the placeholder dialog and banner this phase replaces. | Avoids two copies of the same action string; parity test green. |
| 12 | FR-059 stated original amount in the scenario suite | No shipped template (bank or generic) captures the `foreignAmount`/`foreignCurrency` groups, so no real message yields `PendingSmsImport.foreignAmount` today. The FR-059 scenarios stage the item directly through `insertPending` with the value the parser contract defines, then run the real `CheckDuplicates`/`AddImportedTransaction` against a real USD record. **Follow-up for the bank-profile owner**: add the groups to the templates of banks that state an original amount (needs real samples, OQ2), with a version bump. | Not my slice (profiles), and it needs real phrasing. The duplicate side of FR-059 is proven. |
| 13 | "Catch-up" in T170 | Phase 7 (`RunCatchUpScan`, T126) does not exist yet, so the catch-up path is the call it will make: `SmsIngestionService.ingest(source: catchUpScan, advanceCursor: true)` with sender, receipt time and provider id. | The fingerprint and staging behaviour under test live there. |
| 14 | Envelope bodies are generic phrasing from an unrecognized sender | They are ingested as inbox reads with sender `BANKX` (the allow-list would drop them in `RunInboxScan`). The NBE message goes through the real `RunInboxScan`. | The cross-path property is about fingerprints, not the allow-list. |
| 15 | Version-bump test | A registry built from the shipped profiles with every `version + 1` (same rules), sharing the database and the MAC key with the first harness. Also checks that the row is gone after `purgeDecided` while the tombstone keeps the message out. | FR-023: a rule update never resurfaces a message. |

## Findings (no code bug found)

No scenario exposed a bug in ingestion, staging or `CheckDuplicates`. Observed behaviour worth knowing:

- A non-unique-reference bank's message is **not** collapsed against a *decided* item with the same reference/amount within a day (a tombstone keeps no date, 2d #4). The second item is still caught as **probable** against the saved record, so the user is asked, never silently blocked (`duplicate_scenarios_test` "a non-unique bank reference is not collapsed against a decided item").
- An `added`/`duplicate` identity shell keeps its fingerprint, so a re-ingest is collapsed by the pending-row lookup as well as by the tombstone. After the 30-day row purge, the tombstone alone keeps it out (tested).

## Files

- New lib: `domain/usecases/close_as_duplicate.dart`; `presentation/widgets/duplicate_comparison_card.dart`; `presentation/widgets/probable_duplicate_sheet.dart`.
- Edited lib: `data/repositories/sms_import_repository_impl.dart` (`closeAsDuplicate` + doc); `presentation/cubit/import_review_cubit.dart` (`CloseAsDuplicate` dependency, `compareDuplicate`, `closeAsDuplicate`, pending-pair load); `presentation/cubit/import_review_state.dart` (`closedAsDuplicate`, `duplicatePending`, `isSettled`); `presentation/pages/import_review_page.dart` (sheet instead of dialog, Compare on the banner, closed outcome); `lib/core/l10n/app_{en,ar}.arb` and regenerated `app_localizations*.dart`; regenerated `lib/core/di/injection.config.dart`.
- New tests: `data/repositories/close_as_duplicate_test.dart`, `domain/duplicate_scenarios_test.dart`, `domain/cross_path_fingerprint_test.dart`, `presentation/widgets/probable_duplicate_sheet_test.dart`, `helpers/pipeline_harness.dart`.
- Edited tests: `helpers/review_harness.dart` (passes `CloseAsDuplicate`), `presentation/cubit/import_review_cubit_test.dart` (+13), `presentation/pages/import_review_page_test.dart` (+9), `data/repositories/sms_import_repository_impl_test.dart` (decision 2).

## Verification (observed)

- `fvm dart format lib/features/sms_import test/features/sms_import`: 0 changed.
- `fvm flutter analyze`: **No issues found**.
- Full `fvm flutter test`: **5651 passed, 1 skipped, 0 failed** (the skip is the existing opt-in snapshot regenerator). The native-assets `lipo` error did not appear.
- New/extended tests in this slice: 8 + 33 + 36 + 17 + 13 + 9 = 116.
