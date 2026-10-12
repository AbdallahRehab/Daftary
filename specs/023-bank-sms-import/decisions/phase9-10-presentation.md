# Phase 9–10 presentation decisions (T138–T143, T145)

This slice resumes a run that was stopped partway through. The earlier run had already written most of the code and tests: the T138 cubit/state/page changes, `LearnedCategoriesCubit` and `LearnedCategoriesPage`, the `smsImportSuggest*`, `smsImportMappings*` and `smsImportSettingsTurnOff*` keys (EN and AR), the `/bank-messages/learned` route, the Manage link, Turn off in the Settings cubit and page, and five test files. It left no decisions file. I audited each piece against tasks.md, ui-contract §3.1/§3.4/§3.9/§9, FR-012, FR-051a/b/c, FR-054, FR-056, FR-062, FR-070, FR-072 and FR-078. Correct code was kept. I fixed the gaps below. I made no domain or data edits.

## Verification (observed)

| Check | Result |
|---|---|
| `fvm flutter test test/features/sms_import test/features/dashboard test/widget` | **2387 passed, 0 failed** |
| `fvm flutter test test/features/settings test/features/data_privacy` | 174 passed |
| Slice files only (transfer cubit, transfer page, learned, turn off, revocation) | 64 passed |
| `fvm flutter analyze` (whole repo) | **No issues found** |
| `fvm dart format` (presentation, its tests, router) | 0 changed |
| `flutter gen-l10n` | Ran. All new plurals in AR have `=0/=1/=2/few/many/other`. `l10n_parity_test` passes. |
| build_runner (I own codegen) | Ran. `LearnedCategoriesCubit`, `BankMessagesSettingsCubit(…, DisableSmsImport)` and `ImportReviewCubit(watchSettings:)` are registered. |

## Fixes made in this pass

1. `learned_categories_cubit.dart`: added braces to two `if … return` statements (the two analyzer infos at lines 187 and 190).
2. `learned_categories_page.dart`: the Remove button was wrapped in `Semantics(button: true, excludeSemantics: true)`. That removed the button's own tap action from the semantics tree, so screen-reader users could not activate it. Now the merchant-naming label sits *inside* the `TextButton`, so the button keeps its tap action. A test asserts both the label and `SemanticsAction.tap`.
3. `import_review_page.dart`: the "Record as Received from / Given to {name}" chip now wraps the counterparty in `BidiIsolate.auto` (FR-091, ui-contract §8). The test expectation changed to match.

## Decisions

| # | Topic | Choice | Why |
|---|---|---|---|
| 1 | Named transfer default (FR-051a vs parser-contract §8) | The type stays Expense/Income. A one-tap chip "Record as Received from / Given to <name>" appears only when `suggestedPersonId` is set (exactly one existing-name match, from the domain). | Spec wins (phase7-10-domain-data #1). A debt record is never pre-chosen. |
| 2 | "Existing similar-name choice when more than one person matches" (FR-054) | When there's no single match, the cubit reads `searchActivePeople()` (read-only) and applies the existing `FindPossibleDuplicatePerson` rule. If more than one person matches, it shows one line ("N people could be <name>", plural) and a "Choose who sent / received it" chip. The chip switches to Received/Given and opens the existing `DuplicateWarningSheet` (pick existing, or create anyway). | Reuses the app's existing similar-name UI and rule. Nothing new is invented and nothing is created by reading. |
| 3 | Creating a person | Only through `PersonPickerField.onCreateNew` → the existing `CreatePerson`. A `PossibleDuplicateFailure` opens the same similar-name sheet, and "create anyway" goes through `confirmCreateDespiteDuplicate`. With no match, a muted line says "<name> isn't in your people. A person is created only if you tap Create new person." | FR-054 / US7-2: explicit tap only. |
| 4 | Own-account hint (FR-051c) | No type is pre-selected. The hint "Suggested: Ignore. Nothing is counted as income or spending." shows under the type selector, plus the existing `possibleOwnTransfer` warning line in the header. The same hint is used for refund, reversal and ATM-off. With `unset`, the "choose a type" variant shows. | ui-contract §3.4 item 1, FR-033. |
| 5 | Cash-withdrawal default from settings (FR-051b) | Review reads the **current** preference (`WatchSmsImportSettings.current()`, optional named ctor param). An ATM item becomes Expense when it's on and Ignore when it's off, even if the item was parsed under the other value. With no reader, or an unreadable preference, the parsed suggestion stays. | The preference can change after parsing. The ctor param is optional so `leak_suite_test`/`offline_flows_test` still compile. |
| 6 | ATM one-line link | A `TextButton` in the header states the current setting ("Cash withdrawals (aren't) counted as spending. Change in settings") and pushes `/settings/bank-messages`. On return, `refreshCashPreference()` applies the new default **only while the draft is untouched**. Edits are never replaced. The `atmIgnoredByDefault` warning line is hidden because the link states the same thing. | FR-051b plus FR-047 (never overwrite the user's edits). |
| 7 | Learned categories, "category removed" | The cubit resolves each mapping against **active** categories (`GetCategories`, archived excluded) of the matching type. Archived, deleted or wrong-type shows "Category removed" (text plus icon, not color alone). Rows are sorted by merchant, then type. | data-model §3.4. It matches suggestion-time skipping, so the screen agrees with what the parser does. |
| 8 | Clear learned categories | Behind `showAppConfirmDialog(isDestructive: true)`. Remove one has no confirmation (one row, low cost). Remove and Clear are single-flight. Failures go to a snackbar and the list stays. | ui-contract §3.9. |
| 9 | Turn off dialog outcomes | "Also delete pending imports?" with **Keep them** (cancel slot) and **Delete them** (destructive confirm). Dismissing the dialog counts as Keep, so the feature still turns off and nothing is deleted. Only `DisableSmsImport(deletePending:)` is called. `ClearSmsImportData(pending)` isn't needed because `DisableSmsImport` already does disable-then-delete in the right order. | ui-contract §3.1 names exactly two outcomes, keep and delete. `showAppConfirmDialog` can't tell dismiss from cancel, and the non-destructive outcome is the safe default. Turning off is reversible and deletes nothing in that path. |
| 10 | Turn off visibility | Shown only with the capability and while enabled. Without the capability there is no Status section (CHK013/CHK036). Mutes, mappings, tombstones and saved records are kept (the use case guarantees this, and the cubit test checks mutes). | FR-056, FR-078. |
| 11 | T143 resume refresh | Already present from 6c: `AppLifecycleListener.onResume` → `BankMessagesCubit.refreshScanContext()` and `BankMessagesSettingsCubit.refreshPermission()`, both prompt-free. The new `revocation_on_resume_test.dart` covers it at cubit level: the revoked banner, both pending items kept and still pending, Scan not run, 0 permission requests across repeated resumes, `permissionRequested` untouched, `isEnabled` left on (revocation is not Turn off), and a grant in App info clearing the banner without a prompt. The page-level resume tests from 6c still pass. | FR-012, FR-070, US8-2. |
| 12 | T145 restore / key loss | Review renders from parsed fields only. "Show original" stays visible but **disabled**, with the localized reason (`smsImportErrorOriginalUnavailable`) when `hasRawText` is false or the first open fails. Add still works. Widget tests cover EN (the open fails, as after a restore) and AR. "Old tombstones stop matching" needs no code: it is accepted (FR-062). It is pinned by the existing `hmac_fingerprint_hasher_test` ("a different key gives a different fingerprint") and the data-level key-loss test in `privacy/delete_all_test.dart`. | No fix was needed. The behaviour matched the spec. |

## Files

Edited in this pass:
- `lib/features/sms_import/presentation/cubit/learned_categories_cubit.dart` (braces)
- `lib/features/sms_import/presentation/pages/learned_categories_page.dart` (Remove semantics)
- `lib/features/sms_import/presentation/pages/import_review_page.dart` (bidi isolate on the chip)
- `test/features/sms_import/presentation/learned_categories_test.dart` (semantics assertion)
- `test/features/sms_import/presentation/pages/import_review_transfer_page_test.dart` (isolated name)

Kept from the stopped run (audited, all inside the slice): `import_review_cubit.dart`/`_state.dart`/`_page.dart` (T138); `learned_categories_cubit.dart`/`_page.dart` (T139); `bank_messages_settings_cubit.dart`/`_state.dart`/`_page.dart` (T142, Manage link); `app_router.dart` (learned route); ARB plus generated l10n; `injection.config.dart` (regenerated); the tests `cubit/transfer_people_review_test.dart`, `pages/import_review_transfer_page_test.dart`, `learned_categories_test.dart`, `pages/bank_messages_settings_turn_off_test.dart` and `cubit/revocation_on_resume_test.dart`; and the `/bank-messages/learned` stub in `helpers/widget_harness.dart`.

No files outside the slice were edited.

## Follow-ups (not this slice)
- Native Arabic review of the new copy (T156).
