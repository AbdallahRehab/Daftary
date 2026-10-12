# Phase 7–8 presentation decisions (T125 presentation half, T128, T129, T132–T135)

There was no partial code from an earlier run for this slice. I checked for an existing trigger, Ignored/Muted pages and `smsImportIgnored*`/`smsImportMute*` keys, and none existed. Everything below is new or an additive edit. I made no edits to domain or data.

## Verification (observed)

| Check | Result |
|---|---|
| `fvm flutter test test/features/sms_import/presentation test/features/dashboard test/widget` | **922 passed, 0 failed** |
| `fvm flutter test test/features/sms_import` (whole feature, including other agents' files) | **1784 passed, 0 failed** |
| `fvm flutter analyze` | **No issues found** (whole repo) |
| build_runner (I own codegen) | Ran. It registered `SmsCatchUpTrigger` (lazySingleton), `IgnoredImportsCubit` and `MutedSendersCubit`, and updated the `BankMessagesCubit`, `BankMessagesHomeCubit` and `ImportReviewCubit` constructors. The only builder warning is the existing `GetConversionContext` one. |
| `tool/check_merged_manifest.sh` | Not run, because it needs a Gradle build of the APK. I made no Android or manifest change, and the trigger only uses a Dart `WidgetsBindingObserver` (no receiver, service, alarm or WorkManager). |
| `flutter gen-l10n` | Ran. 37 new keys in EN and AR. Every plural has the Arabic `=0/=1/=2/few/many/other` set, and `l10n_parity_test` passes. |

## Decisions

| # | Topic | Choice | Why |
|---|---|---|---|
| 1 | Trigger: "isLocked only after a post-frame callback" (L1 in permissions-lifecycle) | `runIfDue` awaits `WidgetsBinding.instance.endOfFrame` (an injectable `FrameWaiter`, `@ignoreParam`) before its first `isLocked` read. It also listens to `LockStatus.changes`: a lock calls `RunCatchUpScan.cancel()`, and an unlock calls `runIfDue()` again. | L1 says a post-frame check is best effort, so the lock listener closes the remaining window. Running again on unlock covers "resumed while locked, then unlocked", where no new resume event comes. |
| 2 | Debounce at the trigger and in the use case | The trigger keeps its own in-memory 60 s debounce (`SmsCatchUpTrigger.debounce = RunCatchUpScan.debounce`) that starts only when an attempt passes the lock check. The use case keeps its persisted `lastCatchUpAt` debounce. | The task asks for a trigger-level debounce test. A locked attempt must not use up the window, or the unlock run would be skipped. |
| 3 | "ExpirePendingImports after unlock at app start" | It runs once per process, on the first `runIfDue` that finds the app unlocked, before the first catch-up, on every platform. Its failure is ignored (best effort). | Pasted and shared items expire on iOS and macOS too. The use case is idempotent. |
| 4 | Start point in `main.dart` | `getIt<SmsCatchUpTrigger>().start()` goes in the `startup.whenReady` block after `SharedTextRouter` (discovery permissions-lifecycle §5). | Cold-launch lock state is settled there. `startup_no_permission_prompt_test` still passes. |
| 5 | Count card visibility (T129) | It is gated by the flag **and** `SmsCapability.available`, like the onboarding card. Count and onboarding are independent variants rendered in the same widget (count first). A failed count read counts as 0. | ui-contract §2: "Hidden when the feature is not available", and "the card's cubit is created only when the flag and capability allow it". Paste-only platforms reach pending items through the quick action, which goes to Paste and then the list. |
| 6 | "All three new Home surfaces below the people summary" | "People summary" means `OverviewSummaryCard` (the people balance summary at the top). The test asserts summary < quick action, summary < count card < onboarding card < Insights, and person rows < count card. The quick-action row was **not** moved. | Moving the shared `QuickActionRow` would rewrite unrelated Home layout (rule 1). The new quick action already sits below the people summary card. The cards also sit below the per-person rows. |
| 7 | Where the T129 test lives | `test/features/dashboard/presentation/bank_messages_home_card_test.dart` (new, as tasks.md names). The existing onboarding test under `sms_import/presentation/widgets/` is kept. | Follows the task path. Nothing was removed. |
| 8 | `ImportReviewCubit` new dependencies | `IgnoreImport` and `MuteSender` are **optional named** constructor parameters. DI always passes them (verified in `injection.config.dart`). The page offers Ignore only when `canIgnore`, and the mute item only when `canMuteSender` (a use case plus a non-blank `senderId`). | Phase 12 files owned by another agent (`leak_suite_test`, `offline_flows_test`) construct `ImportReviewCubit` positionally, and I must not edit them. Optional named parameters keep them compiling. |
| 9 | Single Ignore on review: confirm or not? | No confirmation for a single Ignore. Only the batch confirms (`showAppConfirmDialog(isDestructive: false)`). The item settles as `ignored` and advances like Add (`pushReplacement` to the next item, or back to the hub). | ui-contract §3.3 asks for a confirm only on batch, and the Undo list makes a single Ignore recoverable. |
| 10 | Mute confirmation copy | "Daftary will stop suggesting transactions from {sender}. Its pending items will be removed. Saved transactions are not changed. You can undo this in Muted senders." The sender is LTR-isolated, and the dialog uses `isDestructive: true`. After success, `smsImportMuteDone(count)` gives the number of removed items. | T132 says the confirm must state that the sender's pending items are removed (FR-065). Deleting items with no tombstone and no Undo is destructive. |
| 11 | Hub selection UX | Entry is a long-press or the app-bar "Select" (shown only in `ready`). In selection mode, the app bar shows a close button, "N selected" (a live region) and **Ignore only**. Scan header and expired notice are hidden. Back leaves selection first. Rows get a leading `Checkbox` and `Semantics(selected:, checked:)`. Items decided elsewhere drop out of the selection. A failed batch keeps the selection (all or nothing) and shows the failure. | ui-contract §3.3 and §7.9, FR-046, FR-064. A test asserts no "Add" text is shown in selection mode. |
| 12 | Hub overflow | Added "Ignored items" between Paste and Settings. | ui-contract §2 "Hub overflow: Paste, Ignored, Settings". |
| 13 | Ignored list copy on platforms without scan | The cubit reads `GetSmsCapability`. With it: §3.8 copy that names Scan now. Without it: `smsImportIgnoredComesBackPasteOnly` and `smsImportIgnoredRestoredPasteOnly`. | §3.8: "on iOS the Scan clause is omitted". |
| 14 | "Days left" | `decidedAt + 30 days − now` in whole days (floor), with 0 shown as "Less than a day left". `now` comes from `AppClock` when the list is read. | It matches `purgeDecided` (30 days after the decision). Floor never promises more time than is left. |
| 15 | Undo of an item already gone | `ImportAlreadyDecidedFailure` and `NotFoundFailure` are silent, because the stream drops the row. Other failures show a snackbar and keep the row. | No false error for a row purged or undone elsewhere. |
| 16 | Muted senders loading state | A centered progress indicator, not a skeleton. | The list is tiny (sender ids only). Empty, error with Retry, ready and the per-row submitting state are all covered. |
| 17 | Settings Manage links | Added "Ignored items" (`/bank-messages/ignored`) and "Muted senders" (`/bank-messages/senders`) under Paste, shown with and without the capability. | §3.1, including the capability-unavailable row. "Learned categories" is left to T139. |
| 18 | Test helpers (shared, additive) | `scan_presentation.dart`: `buildBankMessagesCubit` passes `IgnoreImport`, and `buildHomeCubit` takes an optional `repository:`. `review_harness.dart`: adds `settings` (a `FakeSmsImportSettingsRepository(pending: repository)`), passes `ignoreImport`/`muteSender`, and `dispose` closes both. `widget_harness.dart`: adds the `/bank-messages/ignored` and `/bank-messages/senders` stub routes. | Needed by the new tests. All existing call sites still compile and pass. |

## Files

New:
- `lib/features/sms_import/presentation/sms_catch_up_trigger.dart`
- `lib/features/sms_import/presentation/cubit/ignored_imports_cubit.dart`, `muted_senders_cubit.dart`
- `lib/features/sms_import/presentation/pages/ignored_imports_page.dart`, `muted_senders_page.dart`
- `test/features/sms_import/presentation/sms_catch_up_trigger_test.dart` (18 tests)
- `test/features/sms_import/presentation/cubit/ignore_mute_cubits_test.dart` (26 tests)
- `test/features/sms_import/presentation/pages/ignore_mute_pages_test.dart` (40 tests)
- `test/features/dashboard/presentation/bank_messages_home_card_test.dart` (13 tests)

Edited (additive):
- `lib/main.dart`, `lib/core/routing/app_router.dart`
- ARB files plus the generated localizations, `injection.config.dart`
- `bank_messages_home_card.dart`, `home_page.dart` (comment only)
- `bank_messages_home_cubit.dart`
- `bank_messages_cubit.dart` and `bank_messages_state.dart`
- `bank_messages_page.dart`, `pending_import_card.dart`
- `import_review_cubit.dart`, `import_review_state.dart`, `import_review_page.dart`
- `bank_messages_settings_page.dart`
- The three test helpers above

## Follow-ups (not in this slice)

- T139: the Learned categories link and screen.
- T142: Turn off with the delete-pending dialog.
- T143: revocation refresh. Resume handling already exists from 6c.
- Native Arabic review of the new copy (T156).
