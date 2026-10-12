# Phase 4 (US4) decisions: paste everywhere, share on Android (T087–T098)

I owned codegen for this slice: I ran `fvm dart run build_runner build --delete-conflicting-outputs` (it regenerated `injection.config.dart`; the final run also registered the Phase 6a use cases; its only warning is about `GetConversionContext` (currency), outside this slice) and `fvm flutter gen-l10n` (l10n.yaml exists and the generated files are committed).

## Verification (observed)

- `fvm flutter analyze`: **No issues found**.
- Full `fvm flutter test`: **5443 passed, 1 skipped, 0 failed** before the Phase 6a use cases were wired. After the final build_runner run, which registered the 6a use cases: one run reported failures (`data_wipe_test` plus 34 more); `data_wipe_test` alone passed 8/8 right after, and a full re-run gave **5482 passed, 1 skipped, 0 failed**. The skip is the existing opt-in snapshot regenerator. The cause of the first failure was not found; my best guess is a race with the codegen output, so it could be flaky. The parity, hardcoded-string, privacy static-guard, screen-protection and DI tests are green.
- `fvm flutter build apk --debug`: built. The merged debug manifest has no READ_SMS, RECEIVE_SMS, SEND_SMS, RECEIVE_MMS, RECEIVE_WAP_PUSH, WRITE_SMS or READ_PHONE_STATE. `ShareTargetActivity` is present, and `MainActivity` is still `singleTop`.
- `fvm flutter build ios --debug --no-codesign`: built. Nothing under `ios/` changed.
- New tests:
  - `import_pasted_text_test`: 14
  - `import_shared_text_test`: 10
  - `get_sms_capability_test`: 3
  - `paste_cubit_test`: 21
  - `paste_bank_message_page_test`: 19
  - `platform_shared_text_source_test`: 9
  - `shared_text_router_test`: 4
- Additions to existing tests: DI +1, `bank_messages_page_test` +1, `quick_action_row_test` +9 (8 Bank-message tests and 1 layout test).

## Decisions

| # | Ambiguity | Choice | Why |
|---|---|---|---|
| 1 | `ImportPastedText` must return `newIds`, but `SmsIngestionService.ingest` returns only a `ScanSummary` | Added an optional `onCreated(List<String> ids)` callback to `ingest` (additive; existing callers are unchanged). | This avoids changing `ScanSummary` equality, which existing tests depend on. Only ids pass through it, never content. |
| 2 | Meaning of "Not recognized" | `Left(NotRecognizedFailure)` when `recognized == 0 && unreadable == 0`, and also for empty or blank split output. A bank message that is unreadable only returns `Right` with no new ids, and the UI shows "Couldn't read this message" with manual entry (ui-contract §3.5). | Ingestion stores only recognized transactions, so nothing is stored in any of these cases (tested against the real pipeline and an in-memory DB). The content-free FR-102 counters (`addCounts`) are still incremented for a not-recognized paste. They are counts, not an item. |
| 3 | `ImportPastedText` called with an inbox source | It is coerced to `SmsSource.paste`. | This is the most restrictive source: no sender, no receipt time, capped at Medium. |
| 4 | `ImportSharedText` shape. domain-interfaces says it is stream-driving, but ui-contract says the cubit parses after it consumes the inbox | It has two members. `unlockedShares()` takes the cold-start share once plus warm shares, and releases each only while unlocked; the router uses it. `call(SharedText)` waits for unlock **again**, maps `truncated` to `InputTooLargeFailure(characters)`, and then runs `ImportPastedText(source: share)`; the cubit uses it. | This satisfies both docs. The second unlock wait covers the late-lock race (discovery L1), so parsing never runs behind the lock screen. |
| 5 | `SharedTextInbox` capacity | Holds one text; a newer share replaces an unconsumed one. `take()` clears it, and `arrivals` (with no content) lets an open Paste screen consume a warm share. A share that arrives during processing is consumed right after. | Memory only. It is never a route, URL, `extra` or restoration state. |
| 6 | Paste button behaviour | It reads the clipboard (the only read) and fills the field. **Process** stages the text. | This follows ui-contract §3.5 (separate Paste and Process). |
| 7 | Navigation after a result | One new item: `pushReplacement(review(id))`. Several: snackbar summary, then `go(hub)`. Recognized but all already known: stays on the page with the summary and an "Open bank messages" action. | Back from review returns to whatever opened Paste. `go(hub)` also works for a share-launched Paste, which has nothing to pop. |
| 8 | Privacy flags on the field | Added `privateInput` (default false) to `AppTextField`. It turns off autocorrect, suggestions and IME personalized learning. | Additive design-system change; the existing 39 call sites are unchanged. |
| 9 | Field length | No `maxLength`. A counter shows "N of 10,000 characters" and turns red when exceeded, and the splitter rejects the input with a message. | `maxLength` would silently truncate a paste and stage a partial message. |
| 10 | Secure-flag protection | No per-page opt-in. Protection is app-wide (discovery L3). | The page imports no `ScreenshotProtectionService`. |
| 11 | `GetSmsCapability` is listed under T109 (US2), but T098 needs it | Created `domain/usecases/get_sms_capability.dart` (a one-line call to `SmsInboxGateway.getCapability`). **T109 should reuse it and not recreate it.** | T098 must read availability only through `GetSmsCapability` (briefing rule 11). |
| 12 | Home quick action | `QuickActionRow` gets `showBankMessage` (default `kBankMessageImportFeatureEnabled`) and `smsCapabilityAvailable` (a resolver). The resolver runs **on tap only**, so Home's build and the existing dashboard tests never touch DI. Location: hub when the capability is available, otherwise Paste. `onReturn` is kept. | The existing "both flags off renders five" test now passes `showBankMessage: false` through its helper, in keeping with its "all flags off" intent. Its assertions are unchanged. |
| 13 | Hub empty state | `AppEmptyView` gains one Paste action (`smsImportPasteTitle`). The scan action arrives with US2. | This item was deferred by the Phase 3 decision. |
| 14 | `SmsPlugin` methods outside the share scope | `getPermissionState`, `requestPermission` and `queryInbox` answer the typed `unavailable` code until T106 implements them. `getCapabilities.isStoreInstall` is `null`. | The contract allows this (§3: `unavailable` = READ_SMS not declared). It is also the correct answer for this build. |
| 15 | Delivering a share exactly once | Kotlin `SharedTextHolder` keeps one pending payload, pushes it to the stream listener once one exists, and drains it on `getInitialSharedText`. Every payload carries a monotonic `seq`, and `PlatformSharedTextSource` drops a repeated `seq` across both paths. A restored `ShareTargetActivity` (with `savedInstanceState`) does not replay the share. | Contract invariant 4. |
| 16 | `ShareTargetActivity` details | Plain `Activity` with `Theme.Translucent.NoTitleBar`. It sets no content view and never renders the text, because its window is not FLAG_SECURE. It reads `EXTRA_TEXT` only for `ACTION_SEND` with type `text/plain`, and drops a malformed extra silently. It starts `MainActivity` even when there is no text, so the user lands in the app. | Contract §2.5 and discovery §6. No logging. |
| 17 | Spike S1 (one instance, task affinity) | Not run: it needs a device. The contract baseline (trampoline with `NEW_TASK|CLEAR_TOP|SINGLE_TOP`) is used. | Briefing rule on device spikes. |

## Notes for other slices

- **T106 (US2)** extends `SmsPlugin.kt`. It replaces the three `unavailable` arms and uses the stored `activityBinding` for the permission listener.
- **T107** replaces only the inbox and permission branches of `SmsPlatformModule`. The shared-text branch now takes `SmsChannelClient`.
- **T128 (`main.dart`)**: the `SharedTextRouter` line sits after the `SyncScheduler` line in the `whenReady` block.
- I ran `fvm dart format` on `lib/features/sms_import` as a whole. That may have reformatted files of the parallel Phase 6a slice (profiles and use cases). Formatting changes only whitespace.
