# Phase 6c decisions: US2 presentation (T118–T123)

This slice resumes an interrupted run. Most of the code already existed: the cubits, pages, widgets, ARB keys, routes, the Settings tile and the Home card. I audited each file against tasks.md, ui-contract §1–§3.7 and §9, and FR-002, FR-004, FR-005, FR-012, FR-024, FR-070, FR-072 and FR-097. I fixed the hang, filled the gaps below and wrote the missing tests. I did not edit anything in domain or data.

## Verification (observed)

| Check | Result |
|---|---|
| `fvm flutter test test/features/sms_import/presentation test/features/dashboard test/features/settings` | **418 passed, 0 failed** |
| `fvm flutter test test/features/sms_import` (whole feature) | **1689 passed, 0 failed** |
| `fvm flutter test test/widget/home_page_test.dart test/widget/settings_page_test.dart test/widget/quick_action_row_test.dart` | 52 passed |
| `fvm flutter analyze` | 0 issues in my files. The only remaining issues are 2 `avoid_print` infos in `test/features/sms_import/zz_tmp/explore_test.dart`. That is not my file: another agent created it during this run. |
| build_runner (I own codegen) | Ran. `injection.config.dart` picked up the concurrent agent's in-progress `ClearLearnedMappings`, `RemoveLearnedMapping` and `WatchLearnedMappings`, and `RunCatchUpScan` changed from factory to lazySingleton. None of these are mine. The only builder warning is the existing `GetConversionContext` one, which has nothing to do with SMS. |

## Root cause of the 10 timeouts (bank_messages_settings_cubit_test)

`BankMessagesSettingsCubit.close()` and `BankMessagesHomeCubit.close()` ran `await _subscription?.cancel()`. The settings stream they follow is an `async*` generator suspended in `await for` (the test fake `_watch`). Its cancel future only completes when the generator resumes, and that happens on the next change event, which never comes. So `close()` hung, and every tearDown timed out. The fix is in the cubits, not the tests. Cancellation is fire-and-forget through `unawaited(...)` in a `_cancelSubscription()` helper. `BankMessagesCubit` already used this pattern. `open()` and `retry()` use it too, so re-opening can't hang either. No test was changed.

## Decisions

| # | Topic | Choice | Why |
|---|---|---|---|
| 1 | FR-072 "retries the grant once" vs ui-contract §3.2 | On resume after "Open App info", the flow re-checks the status without prompting. If the permission is now granted, it enables and advances by itself. If not, it stays on the step, and the user taps "Try again" (step 4 of the guidance) to make the explicit request. It never prompts automatically on resume. | The contract row spells out the more conservative reading. An automatic prompt on resume would break FR-012 ("MUST NOT silently re-prompt"). The existing cubit tests encode this behaviour. |
| 2 | Hub and Settings resume handling (FR-070, ui-contract §9) | **Added.** `AppLifecycleListener(onResume:)` on `BankMessagesPage` calls `refreshScanContext()`, and on `BankMessagesSettingsPage` calls `refreshPermission()`. Both are prompt-free. | It was missing. Revocation must be detected on resume. Only the enable page had a listener. |
| 3 | Hub scan-failure card | Added the line "N processed before the interruption" (`smsImportScanInterrupted`). | ui-contract §3.2 error row. The enable page already showed it, but the hub didn't. |
| 4 | Settings status row at 200% text | `Row(Expanded(label), Chip)` became a `Wrap`. | The new 200% Arabic test found a real 40 px overflow. |
| 5 | Scan summary format | Each count is a separate, whole plural sentence (found, ready, need review, already listed, skipped, unreadable). Lines with a zero count are left out, except "found". | ui-contract §8.6 says not to concatenate fragments. Per-line plurals stay grammatical in Arabic for 11–99. FR-097 lists the same counts. |
| 6 | The Settings tile, "tile visibility by capability" | The tile is shown on every platform (binding orchestrator decision CHK013/CHK036). Capability decides what is inside the page: Status, Scan and the banner are hidden without it, while Preferences, Manage → Paste and Privacy stay. | Paste works everywhere. The tests cover both sides: the tile is present and comes after Notifications, and the SMS rows are absent without the capability with no mention of a permission. |
| 7 | Settings "Turn off" and the Manage links (Muted senders, Learned categories, Ignored) | Not added. | They belong to T142 (DisableSmsImport) and T133/T134/T139. The page's Manage section holds Paste only for now. |
| 8 | Home onboarding gate (FR-004, "Android") | The gate is `kBankMessageImportFeatureEnabled` plus `GetSmsCapability.available`. Capability means `readSmsDeclared && Android`, so "Android" is implied, and presentation never checks `Platform.isX` (rule 11). The cubit is only created after both gates pass. If either type is unregistered in DI, the card hides. | ui-contract §2. The existing `home_page_test` keeps passing with no SMS registration. |
| 9 | Startup test (FR-002) | `startup_no_permission_prompt_test.dart` is a static guard over the code lines of `lib/` (comments excluded). `.request(previouslyRequested` appears only in `RequestSmsPermission`, `'requestPermission'` only in `SmsChannelClient`, `RequestSmsPermission` is used only by `EnableSmsImport`, and `EnableSmsImport` only by `EnableFlowCubit`. `main.dart`, `features/startup/**`, the lifecycle observer and the shared-text router/inbox name no permission or enable-flow type. A behavioural half opens the home, hub, settings and enable cubits plus resume/refresh against one fake and asserts 0 requests, with `permissionRequested` still false. | A full `main()` boot needs the platform channels and the database. The static guard pins the only path to the prompt, which is what FR-002 needs. |
| 10 | Test-harness routes | `test/features/sms_import/helpers/widget_harness.dart` now also knows `/bank-messages/enable` and `/settings/bank-messages`, so tests can observe navigation. Additive only. | It's needed to assert "Set up", "Turn on" and "Turn on again" go to the enable flow and never to a prompt. |
| 11 | Home ordering test location | The ordering assertion (person rows < onboarding card < Insights) lives in `test/features/sms_import/presentation/widgets/bank_messages_home_card_test.dart`. It pumps `HomeView` with `GetSmsCapability` and `BankMessagesHomeCubit` registered in `getIt`, unregisters them after, and verifies the dashboard cubit is never asked to load or refresh. | I stayed inside my test folder rather than editing `test/widget/home_page_test.dart`. |

## Tests added

- `cubit/bank_messages_cubit_test.dart`: a new group with 10 hub scan-state tests. They cover no capability, Scan now with the saved window, progress, the ignored double tap, Cancel, a failure keeping the processed count, a permission failure showing the banner, revocation on refresh, Turn on vs the blocked banner, App info, close cancelling the scan, and a redacted `toString`.
- `pages/bank_messages_page_scan_test.dart` (15 tests): the paste-only page without the capability; the summary and the Skipped sheet (bank, date or "Date unknown", reason, never text); dismissing the summary; progress, Cancel and the list staying interactive; failure, interrupted count and Retry; the revoked banner with pending items and paste; Turn on again and the Turn on card going to enable; the resume re-check; `startScan` gating; and the RTL/LTR × light/dark matrix with 48 dp checks.
- `pages/enable_bank_messages_page_test.dart` (16 tests): the explanation and no prompt on open or resume; Not now; Paste instead; Continue asking once and leading to the 7/30/90 window; denied with Try again once and no re-prompt on resume; permanently denied, with a grant in App info advancing on return without a prompt; restricted with the numbered steps, the re-check and no prompt on return, then an explicit Try again; window, scan, summary and Review now; Cancel; a scan failure with the interrupted count and Retry; unavailable; the locale × theme matrix; and 200% Arabic.
- `pages/bank_messages_settings_page_test.dart` (15 tests): capability on/off rows; Off with Turn on; on with the window, Scan now, last scan and the 4 counters; the window and cash switch writing; the save-failure snackbar; revoked and restricted banners; the resume re-check; the matrix; 200%; and the main Settings tile (present, after Notifications, opens `/settings/bank-messages`).
- `widgets/bank_messages_home_card_test.dart` (12 tests): flag off reads nothing; no capability means no cubit; it shows when off and not dismissed; it hides when on; Set up goes to enable; Dismiss is permanent across a new card; a failed dismiss keeps the card; the matrix; and the Home ordering.
- `startup_no_permission_prompt_test.dart` (6 tests): see decision 9.
- `widgets/sms_permission_banner_test.dart` already existed (one test per state, the restricted guidance, the matrix) and passes.

## Not done / follow-ups (outside this slice)

- T129 (count variant of the Home card) is untouched, as instructed.
- The Turn-off dialog (T142) and the Manage links (T133, T134, T139) are listed in decision 7.
- Device-only: the real restricted-settings round-trip on Android 15 (S4/SC-015).
