# Phase 7–10 domain + data slice (T125–T127, T130–T131, T136–T137, T139/T141/T142 use cases, T144)

An earlier run was interrupted. Most of the code was already in place. This pass reviewed that code against tasks.md, domain-interfaces §3 and §5, parser-contract §8, data-model §6 and the spec FRs, then completed or fixed it. Working code was left as it was.

## Status per task

| Task | Status | Notes |
|---|---|---|
| T125 | [ ] partial | The domain test `domain/usecases/run_catch_up_scan_test.dart` is complete: every skip reason with no inbox read, the debounce, single flight, the coordinator, the 24 h overlap, the 90-day cap, stops between pages (disable, revoke, paused, lock), maintenance at the end, and "never throws". **Left for the presentation agent**: `test/features/sms_import/presentation/sms_catch_up_trigger_test.dart` (post-frame `isLocked` check, single flight, 60 s debounce at the trigger). |
| T126 | [X] | `RunCatchUpScan` was reviewed against §5.2. It is now `@lazySingleton` (see decision 2). |
| T127 | [X] | `ReparsePending` and `SmsImportRepositoryImpl.replaceParsedFields` were reviewed. Tests: `reparse_pending_test.dart` (fakes, the real database and the real pipeline). |
| T130 | [X] | `data/repositories/ignore_undo_mute_test.dart`: ignore (single, batch, all or nothing), undo, the Undo list, mute (invariant 8, no tombstones), and the muted sender left out of the allow-list. |
| T131 | [X] | Repository methods plus `IgnoreImport`, `UndoIgnore` (`needsRescan: true`), `WatchUndoList`, `MuteSender`, `UnmuteSender` and `WatchMutedSenders`. They are exercised over the real repositories in the T130 file. |
| T136 | [X] | `data/parsing/suggest_for_test.dart` was rewritten for the transfer and people cases. The new file `domain/usecases/learned_mapping_test.dart` checks that a mapping wins over a keyword, and that a mapping to an archived or deleted category is skipped and left in place. |
| T137 | [X] | This was already wired: `LoadParserOptions` reads `PeopleRepository.searchActivePeople()` (read only) and `SmsIngestionService`/`ReparsePending` use it. The new tests prove that the people repository is only searched, never written (mocktail `verifyNoMoreInteractions`). |
| T139 | [ ] partial | **Done**: the use cases `WatchLearnedMappings`, `RemoveLearnedMapping(MerchantCategoryMapping)` and `ClearLearnedMappings`, tested in `learned_mapping_test.dart`. **Left**: `LearnedCategoriesCubit`/`Page`, the `smsImportMappings*` keys and the `/bank-messages/learned` route. |
| T141 | [ ] partial | **Done**: `disable_sms_import_test.dart`, `privacy/delete_all_test.dart` (the five tables, both keys, a purge failure that stops before any wipe) and the key-loss test (in `delete_all_test.dart`). **Left**: the revocation-on-resume Cubit test (presentation). |
| T142 | [ ] partial | **Done**: the `DisableSmsImport` and `ClearSmsImportData` use cases. **Left**: the disable action with the "also delete pending imports?" dialog on `BankMessagesSettingsPage`. |
| T144 | [X] | `PurgeSmsImportKeys` is injected into `DeleteAllUserData` right after `PurgeAIAssistantCredentials`. The `delete_all_user_data_test.dart` group "023 T144" passes, and so does the existing suite. |

## Decisions

| # | Conflict or ambiguity | Choice | Why |
|---|---|---|---|
| 1 | parser-contract §8 says a named transfer with a person match becomes `given`/`received`. Spec FR-051a, US7-1 and T136 say Expense/Income stays the **default**, with a *one-tap* Given/Received and the person pre-selected. | The spec wins. `suggestFor` now returns `expense` (learned, else `other`) or `income` (learned, else `other_income`) for `transferOut`/`transferIn`, and sets `personId` only on exactly one existing-name match. The type never changes. The review page already offers `acceptSuggestedPerson()` whenever `suggestedPersonId != null` and the type is not a person type, so it needed no change. One assertion in `rule_based_sms_parser_test.dart` was updated to the spec behaviour. | The spec is the higher authority. It is also the more conservative reading: a debt record is never pre-chosen, and the user switches with one tap. |
| 2 | §5.2 calls for single flight through a shared `_inFlight`. The class was a factory `@injectable`, so each resolution would get its own `_inFlight`, and `cancel()` would not reach a run started by another holder. | `RunCatchUpScan` is now `@lazySingleton`. **The orchestrator must run codegen** (the generated config still registers a factory). Until then nothing breaks, and `ScanCoordinator` (already a lazy singleton) still keeps runs exclusive. | Single flight and cancel must be shared app-wide (the trigger and the hub). |
| 3 | Signature of `RemoveLearnedMapping` | `call(MerchantCategoryMapping mapping)`. It passes `entryType.dbValue` to the repository. | The screen holds the mapping object, so the stored entry-type string never leaks into presentation. |
| 4 | `WatchLearnedMappings` and "category removed" | A thin pass-through. Mappings to archived or missing categories are still listed. The Cubit resolves category names and shows "category removed". | data-model §3.4: such a mapping is "left in place" and the view shows it as removed. Joining categories is a display concern. |
| 5 | Is T137 already done? | Yes, through `LoadParserOptions` (phase2d #14). No new people code was written. Tests were added only to prove that people are read and never created. | Avoids duplicating wiring that already works. |

## New `@injectable` classes (need codegen by the orchestrator)

- `WatchLearnedMappings`, `RemoveLearnedMapping`, `ClearLearnedMappings` (factories, `domain/usecases/`).
- An annotation change: `RunCatchUpScan` `@injectable` → `@lazySingleton`.

All the other use cases in this slice were already in `injection.config.dart`.

## Results

- `fvm flutter analyze`: no issues.
- `fvm flutter test test/features/sms_import/domain test/features/sms_import/data test/features/sms_import/privacy test/features/data_privacy`: 1442 passed, 0 failed.
- Also run: `test/features/sms_import/presentation` and `di`: 240 passed, 0 failed.
