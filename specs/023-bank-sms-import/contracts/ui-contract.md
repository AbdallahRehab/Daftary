# Contract: UI (routes, screens, states, l10n, accessibility, RTL)

**Feature**: 023 Bank SMS Import · **Research**: Decisions 4, 5, 12, 13 · **Requirements**: FR-004, FR-005, FR-012, FR-015..FR-018, FR-024, FR-040..FR-050, FR-060..FR-068, FR-070, FR-072, FR-078, FR-079, FR-089..FR-096, FR-102; US1-US8; SC-009

Presentation follows the repo conventions verified in `lib/features/ocr/presentation` and `lib/core/design_system`: `flutter_bloc` Cubits with Equatable states updated by `copyWith` (constitution III, IV), no business logic in widgets, every screen has loading, empty, error, ready, submitting and success handling (constitution "UI State Completeness"), design tokens from `tokens.dart`, no hardcoded strings (guard test over `lib/features/sms_import/presentation` for string literals passed to `Text(`). Screens use `AppScaffold` + `AppTopBar` (`core/design_system/glass/`), `AppEmptyView` (`title, message, icon, actionLabel, onAction`), `AppButton`, `AppCard`, `AppTextField`, `AppDateField`, `CurrencyPicker`, `CategoryPickerField`, `PersonPickerField`, `ConfidenceIndicator` (promoted to `core/design_system/`), `AppModalSheet` and `showAppConfirmDialog`. Screen-capture protection and App Lock are app-global and always on (`SecurityPlugin`, `AppLockGate`), so every screen below inherits them (FR-079); no screen opts out and a test asserts no screen disables protection.

## 1. Routes

Declared in `lib/core/routing/app_router.dart` inside the same People-branch `ShellRoute` children as `/ocr/...`, with a `BankMessagesRoutes` constants class in `lib/features/sms_import/presentation/routes.dart` (the `ChatPage.location` precedent). Static paths precede the parameterized one so no literal is captured as an id.

| Constant | Path | Params | Page | Notes |
|---|---|---|---|---|
| `BankMessagesRoutes.hub` | `/bank-messages` | none | `BankMessagesPage` | Pending list + scan entry + state banners. Android with capability available |
| `BankMessagesRoutes.enable` | `/bank-messages/enable` | none | `EnableBankMessagesPage` | Explanation -> permission -> window -> scan (also the target of the Home onboarding card) |
| `BankMessagesRoutes.paste` | `/bank-messages/paste` | none | `PasteBankMessagePage` | **No text in the URL.** The Paste cubit consumes `SharedTextInbox` for shares |
| `BankMessagesRoutes.ignored` | `/bank-messages/ignored` | none | `IgnoredImportsPage` | 30-day Undo list |
| `BankMessagesRoutes.senders` | `/bank-messages/senders` | none | `MutedSendersPage` | View and unmute (FR-065) |
| `BankMessagesRoutes.learned` | `/bank-messages/learned` | none | `LearnedCategoriesPage` | View, remove one, clear all (FR-056) |
| `BankMessagesRoutes.review(id)` | `/bank-messages/review/:importId` | `importId` (UUID path param; not content) | `ImportReviewPage` | Declared last. Never carries amounts, merchants or text |
| `BankMessagesRoutes.settings` | `/settings/bank-messages` | none | `BankMessagesSettingsPage` | Settings entry (FR-050c); next to `/settings/ai-assistant` |

Rules: nothing sensitive in a URL, Intent extra, route `extra` or restoration state (FR-016a, FR-080); review is reached by id and re-reads the row. The Settings page gets a new `ListTile` (key `settings_bank_messages_entry`) in a section after Notifications/Currency, shown on every platform (paste is universal; the SMS-specific rows inside are hidden when `SmsCapability.available` is false).

Feature flag in `lib/core/config/feature_flags.dart`: `kBankMessageImportFeatureEnabled = true` (Home quick action, in the style of `kOcrScanFeatureEnabled`). While it is false Home never offers a live route to these screens. There is no capability const: availability is the runtime `SmsCapability.available` (`readSmsDeclared && Platform.isAndroid`, [research Decision 3](../research.md)); widgets read it only through the use case/cubit.

## 2. Entry points

| Entry | Where | Behavior |
|---|---|---|
| Home quick action "Bank message" | `QuickActionRow` (new `showBankMessage = kBankMessageImportFeatureEnabled` param; new `bankMessageLocation` constant) | Android with `SmsCapability.available` -> `/bank-messages`; every other case (iOS, macOS, Android without capability) -> `/bank-messages/paste`. `onReturn` refreshes Home like the other actions |
| Home count card | New `BankMessagesHomeCard` (dashboard widgets), placed **below the people summary** (PRODUCT principles 2 and 73; a dashboard ordering test asserts it) | Rendered only while `watchPendingCount > 0`; shows a count only ("1 bank transaction to review", plural), **no merchant, amount or text**; tap -> `/bank-messages`; no tab badges (FR-050). Hidden when the feature is not available |
| Home onboarding card | same widget, second variant | Android + capability available + `isEnabled = false` + `onboardingDismissed = false`; text explains the feature in one line; actions "Set up" -> `/bank-messages/enable` and "Dismiss" (permanent, `UpdateSmsImportPreferences(OnboardingDismissed)`) (FR-004) |
| Settings -> Bank messages | `SettingsPage` | `/settings/bank-messages` |
| Android share target | `SharedTextRouter` | After unlock, `router.go('/bank-messages/paste')`; see section 6 |
| Hub overflow | `BankMessagesPage` | Paste, Ignored, Settings |

Home must not load pending data eagerly for unavailable builds: the card's cubit is created only when the flag and capability allow it.

## 3. Screens and states

State enums are per screen (`initial/loading/ready/empty/error/submitting/success`); a state object holds explicit fields rather than subclasses (constitution IV). Cubits: `BankMessagesCubit` (hub + list), `EnableFlowCubit`, `ImportReviewCubit(importId)`, `PasteCubit`, `IgnoredImportsCubit`, `MutedSendersCubit`, `LearnedCategoriesCubit`, `BankMessagesSettingsCubit`. Each coordinates use cases only ([domain-interfaces.md](domain-interfaces.md)).

### 3.1 Settings -> Bank messages (`BankMessagesSettingsPage`)

Sections: **Status** (permission state chip: Off / On / Permission off / Blocked by Android; a "Turn on" or "Turn off" button), **Scan** (window radio 7/30/90, "Scan now" button, last scan time, content-free counts scanned/recognized/added/ignored), **Preferences** ("Count cash withdrawals as spending" switch, FR-051b), **Manage** (links to Muted senders, Learned categories, Ignored items, Paste a bank message), **Privacy** (static text: read on this device only; nothing saved without Add).

| State | Rendering |
|---|---|
| loading | Skeleton rows from `AppCard`; no spinner-only screen |
| ready (feature off) | Status "Off" with "Turn on" -> `/bank-messages/enable`; scan section hidden; paste link shown |
| ready (on, granted) | All sections |
| ready (permission off: revoked/denied) | Banner (section 3.7), existing pending items stay reachable, paste link prominent (FR-070, FR-012) |
| ready (capability unavailable: iOS, macOS, SMS-free build) | Only Paste, Ignored, Muted senders, Learned categories and Preferences; no scan or permission rows; no mention of SMS permission |
| error | `AppEmptyView` with Retry (settings read failed) |
| submitting | The toggled control disabled with a progress indicator; double taps ignored |
| success | The control reflects the new value; for Turn off: `showAppConfirmDialog` first ("Also delete pending imports?" with two outcomes: keep, delete) -> `DisableSmsImport(deletePending)` (FR-078) |

### 3.2 Enable and permission flow (`EnableBankMessagesPage`)

Linear steps in one page (a `PageView`-free state machine in `EnableFlowCubit`): **Explain** -> **Permission** -> **Window** -> **Scanning** -> **Done**. No system prompt before Explain is acknowledged (FR-005, US2-1); never from app start (FR-002).

| Step / state | Content |
|---|---|
| Explain (ready) | What is read (messages from recognized bank senders only), what is never done (no upload, nothing saved without your approval), how to turn it off; a "Continue" button and "Not now"; "Paste instead" link |
| Permission (submitting) | While the system dialog is up: progress, buttons disabled. `RequestSmsPermission` in `runExternalActivity` |
| Denied | Dedicated explanation: why it is needed, that nothing is lost; "Try again" (once, never silently) and "Paste or share instead"; does not re-prompt unprompted (FR-012, US2-5) |
| Permanently denied | Explanation + "Open App info" (`OpenSmsAppInfo`) + steps text + "Paste or share instead" |
| Restricted-settings blocked (`restrictedBlocked`) | Step-by-step guidance (numbered, large text safe): 1. Open App info, 2. open the overflow menu (three dots), 3. choose "Allow restricted settings", 4. come back and tap "Try again". "Open App info" button; **on app resume** the cubit re-checks `getStatus` and, if now granted, advances automatically ("retries the grant on return", FR-072, US2-6); paste/share fallback always visible. Copy never claims certainty: "Android may be blocking this permission" |
| Window (ready) | 7 / 30 / 90 days radio, default 30; "Scan" button |
| Scanning (loading) | Determinate when total is known else indeterminate; live-region progress text "Processed N"; **Cancel** button; cancel leaves created pending items intact (FR-007) |
| Done (success) | Summary with plural strings: "N bank messages found", "M need your review", plus skipped (non-transactional) and unreadable counts (content-free, FR-097); primary "Review now" -> first pending review, secondary "Close". Announced |
| error (query failed, DB failure) | Message per failure table with Retry; partial results kept; "N processed before the interruption" |

### 3.3 Pending list (`BankMessagesPage`, route `/bank-messages`)

Header region: state banner (section 3.7), "Scan now" (Android, enabled+granted) and "Paste a message" actions, expired notice (one line "N suggestions expired. You can restore them from Ignored items.", dismissible, calls `AcknowledgeExpiredNotice`), summary counts. Summary after a scan or paste: "N found: R ready, V need review, S skipped" (plural), with a "Skipped" link to a content-free list (bank, received date, reason such as "Not a transaction" or "Could not read"; never text; FR-024, FR-097), held in memory only. List ordered low confidence first then oldest first (FR-042); each row is a card: type chip (suggested type or "Choose type"), amount + currency (or "Amount needs checking"), date (with "inferred" marker), merchant or counterparty, masked card ("•••• 1234"), `ConfidenceIndicator` (overall), bank name, warning chips (Ignore suggested, possible duplicate). No raw text.

Multi-select: long-press or a "Select" action enters selection mode (checkbox leading, `Semantics(selected:)`), toolbar shows "N selected" (plural) and **Ignore** only; a batch Ignore asks `showAppConfirmDialog(isDestructive: false)` first (FR-064, US6-2). There is **no** "Add all" or batch Add anywhere (FR-046); a widget test asserts its absence.

| State | Rendering |
|---|---|
| loading | Skeleton cards |
| empty | `AppEmptyView`: "No bank messages to review" with a hint matching the platform (Android: "Scan now" action; iOS/paste-only: "Paste a bank message" action); not an error |
| ready | The list; tap a row -> `/bank-messages/review/<id>`; on return the list refreshes from the stream |
| error | `AppEmptyView` with Retry |
| submitting (batch Ignore) | Selected rows disabled; progress; success announces "N ignored" |
| scanning (Android) | Inline progress bar + Cancel at the top while `RunInboxScan` runs; list stays interactive |
| success | Snackbar after Ignore with **Undo** is not offered (Undo lives in the Ignored list because the raw text is purged) |

### 3.4 Review (`ImportReviewPage`, route `/bank-messages/review/:importId`)

Dedicated review screen; it **never** opens or modifies the manual transaction forms (FR-044). Layout (single scrolling column, `ListView` with `AppCard` sections):

1. **Header**: bank name, masked card/account ("•••• 1234"), source label ("From SMS", "Pasted", "Shared"), overall `ConfidenceIndicator`, warnings (Ignore-suggested hint with its fixed text for refund, one-line link to the cash-withdrawal preference for ATM, generic-parser notice; for an authorization reversal the FR-024b hint plus, when `CheckDuplicates` found one, a read-only card of the matching saved record with "Open it"; for a split fee the line "Fee from the <bank> message of <date>" linking to its parent when still pending; for `possibleOwnTransfer` the line "This looks like money moved between your own accounts. Ignore both if so." with Ignore preselected as the suggestion, FR-051d).
2. **Type** selector (segmented): Expense, Income, Given, Received. A suggested type is preselected; `unset` shows none selected with text "Choose a type" (FR-033). Repayment and occasion are not offered (FR-048). Switching type swaps the required fields (category vs person) and re-runs `CheckDuplicates`. For named transfers a one-tap chip "Record as Received from <name>" appears only when `suggestedPersonId` is set (FR-054).
3. **Amount**: `AppTextField` (numeric, Arabic-Indic digits accepted via the existing numeral parser) + `CurrencyPicker`. Two-candidate case: two chips with the candidate amounts above the field ("Which amount?"). Out-of-catalog currency: inline message "Choose a currency and enter the amount in it" with the picker highlighted (FR-053). Foreign amount shown as read-only context line ("Original: USD 25.00", not saved).
4. **Date**: `AppDateField`; read-only line "Message time 10:15. Only the date is saved." when `timeMinutes` is set (FR-058); inferred marker and `ConfidenceIndicator`; empty with required marker for paste/share without a date.
5. **Category** (`CategoryPickerField(categories, type, selectedCategoryId, onCategorySelected, onManageCategories, errorText, isLoading)`) for expense/income or **Person** (`PersonPickerField(query, results, selectedPerson, onQueryChanged, onPersonSelected, onCreateNew, errorText)`) for given/received with the existing similar-name choice; creating a person happens only on the user's tap through the existing `CreatePerson` (FR-054). No active category of the required type: no selection and the picker's "Manage categories" path; Add stays disabled (FR-055).
6. **Note** (`AppTextField`, 500 max, counter) plus a "Use merchant name as note" text button; never prefilled with the message (FR-049).
7. **Original message**: collapsed `ExpansionTile` "Show original message" visible only while `hasRawText`; on expand calls `ShowOriginalMessage`; renders the masked text with `Text(masked, textDirection: detected)` (direction from the first strong character, independent of app locale, FR-091); unavailable -> inline "The original can't be shown. You can continue from the fields above." (FR-045). Collapsing or leaving drops the text from cubit state.
8. **Duplicate banner**: when `CheckDuplicates` returns `probable` a persistent banner "You may already have this" with "Compare" (opens the sheet, 3.6); recomputed on every relevant edit (debounced 300 ms).
9. **Actions** (sticky bottom, large targets): primary **Add** (disabled until all required fields are valid; a text line above lists what is missing, e.g. "Missing: date, category", FR-043a/US1-3), secondary **Ignore**, overflow: "Stop suggesting from this sender" (only with a `senderId`), "It's the same, don't add" (only when a probable duplicate exists).

Behavior: the cubit holds a `ReviewDraft`; leaving with edits asks `showAppConfirmDialog` ("Discard your changes?"), without edits leaves the item pending untouched (FR-047). Add calls `AddImportedTransaction`; on `ProbableDuplicateFailure` it opens the sheet instead of failing; on success the review advances with `pushReplacement` to the next pending item (low confidence first) or pops to the list when none remain (FR-046). Double-tap is absorbed (`submitting` state ignores taps). Re-parse never replaces a draft: the cubit holds a `ReviewLease` while open.

| State | Rendering |
|---|---|
| loading | Skeleton |
| ready | As above; Add enabled or not per validation |
| not found / already decided | `AppEmptyView` "This item was already handled" with a back action (e.g. after a re-parse or expiry elsewhere) |
| error (load) | `AppEmptyView` with Retry |
| submitting | Add shows progress; every control disabled; announced "Saving" |
| success | Brief confirmation (snackbar "Added") then advance; announced |
| failure on Add | Inline message "It wasn't saved. The item is still pending." + Retry (idempotent key makes retry safe, FR-099) |

### 3.5 Paste screen (`PasteBankMessagePage`)

Controls: a multi-line editable `TextField` (system edit menu paste, no iOS paste prompt) and a **Paste** button (`ReadClipboardText` only inside `onPressed`); a "Process" button; character counter; limits help text ("Up to 10,000 characters and 50 messages"). **No clipboard read in `initState`, route push, `didChangeAppLifecycleState` or a focus listener**; a widget test asserts the mocked `flutter/platform` channel receives no `Clipboard.getData` before the tap (FR-015, US4-2). For a share launch, the cubit consumes `SharedTextInbox` and parses immediately (after unlock) while showing the result states below; the field is empty.

| State | Rendering |
|---|---|
| initial/ready | Empty field, Paste and Process (Process disabled while empty) |
| clipboard empty or non-text | "Nothing to paste" state with guidance to paste into the field (not an error, US4-6) |
| processing (loading) | Progress; controls disabled |
| result: recognized | Summary "N recognized, M skipped" (plural); one item -> navigate to its review; several -> go to the pending list with the new items; announced |
| result: not recognized (`NotRecognizedFailure`) | "This doesn't look like a supported bank message" + actions "Enter manually" (-> `/finance/entries/new` expense) and "Try again"; nothing stored (FR-018) |
| result: too large (`InputTooLargeFailure`) | Message stating the limit that was exceeded (characters or messages); nothing stored |
| result: unreadable only | "Could not read, enter manually" |
| error | Message + Retry |
| iOS | Identical screen; no SMS mention |

### 3.6 Probable duplicate sheet (`ProbableDuplicateSheet`, via `AppModalSheet`)

Named `ProbableDuplicateSheet` because `DuplicateWarningSheet` already exists in `lib/features/transactions/presentation/widgets/` (person-scoped, unchanged). Opened from the review banner or when `ProbableDuplicateFailure` comes back from Add (FR-060, US5-2). Title "You may already have this". Two cards side by side (stacked vertically at text scale >= 1.3 or width < 360 dp): **Already in Daftary** (type label, amount and currency, date, category or person, note first line, the "Imported from a bank message" label when the existing record has provenance) and **This message** (the draft values). Differences highlighted by text, not color alone ("Same amount", "1 day apart"). Two full-width actions: **It's the same, don't add** (`CloseAsDuplicate`, closes the item, leaves no record, FR-061) and **It's different, add anyway** (`AddImportedTransaction(duplicateOverride: true)`, never blocks, not recorded as a failure, FR-063). Dismissing (back, scrim) returns to review with the item pending. On open, a polite live-region announcement "Possible duplicate found" (FR-096). The legitimately-similar tier (reference IDs both present and different, or dates > 1 day apart) shows **no** warning.

### 3.7 Permission and capability state banner (shared widget `SmsPermissionBanner`)

Used on the hub, settings and the enable flow, driven by `SmsPermissionStatus` + `isEnabled`:

| Status | Banner | Actions |
|---|---|---|
| `granted`, enabled | none | |
| `denied` (not yet asked or can ask once) | "Bank message import needs permission to read messages from your bank." | "Allow", "Paste or share instead" |
| `permanentlyDenied` | "Permission is turned off for Daftary." | "Open App info", "Paste or share instead" |
| `restrictedBlocked` | "Android may be blocking this permission for apps installed outside a store." | "Show me how" (opens the 3.2 guidance), "Paste or share instead" |
| `revoked` (detected on resume, FR-070) | "Automatic import is off because the permission was turned off. Your pending items are still here." | "Turn on again", "Open App info", "Paste or share instead" |
| `unavailable` | none (the SMS rows are not rendered at all) | |

No automatic re-prompt anywhere; the `Allow` and `Try again` buttons are the only triggers (FR-012).

### 3.8 Ignored items (`IgnoredImportsPage`)

Lists `ignored` and `expired` items of the last 30 days (amount, currency, date, merchant, status label "Ignored" or "Expired", days left). Each row has **Undo**; after Undo a message states clearly: "It will come back when you tap Scan now, or paste or share this message again." (FR-068; automatic catch-up does not re-read older messages, so the copy names Scan explicitly; on iOS the Scan clause is omitted). Items closed as duplicate or added are not here. States: loading skeleton; empty "Nothing ignored recently"; ready; error with Retry; submitting per row; success announced ("Restored. Tap Scan now, or paste it again, to see it.").

### 3.9 Muted senders and learned categories

`MutedSendersPage`: list of sender IDs with Unmute (LTR-isolated identifiers). `LearnedCategoriesPage`: rows "<merchant> -> <category>" with remove and a **Clear learned categories** action behind `showAppConfirmDialog(isDestructive: true)`. Archived/missing category shown as "Category removed". Both have loading, empty, ready, error, submitting, success states as above.

## 4. Reuse map (no new variants unless listed)

| Need | Reused component | Change |
|---|---|---|
| Page chrome | `AppScaffold`, `AppTopBar` | none |
| Empty/error/not-found | `AppEmptyView` | none |
| Confirm dialogs | `showAppConfirmDialog(context, title, message, confirmLabel, cancelLabel, isDestructive)` | none |
| Category selection | `CategoryPickerField` | none |
| Person selection | `PersonPickerField` | none |
| Currency | `CurrencyPicker(value, onChanged)` | none |
| Date | `AppDateField(label, date, onDateChanged, ...)` | must allow a null (empty) date for paste/share with required marker; verify at task time and extend minimally if it does not |
| Confidence | `ConfidenceIndicator(confidence: FieldConfidence)` | promoted from `features/ocr/presentation/widgets` to `core/design_system`; strings keep the `ocrConfidence*` keys (Low/Medium/High/Inferred), so no parallel `smsImportConfidence*` family; add a variant for the overall `OverallConfidence` that maps to `FieldConfidence.read(level)` |
| Sheets | `AppModalSheet` | none |
| New shared (feature-local) widgets | `PendingImportCard`, `ImportTypeSelector`, `SmsPermissionBanner`, `DuplicateComparisonCard`, `BidiText` (LRI/PDI isolate helper for identifiers) | live in `lib/features/sms_import/presentation/widgets/`; not promoted to core until a second feature needs them |
| Provenance label | New `ImportedFromSmsLabel` widget (copy "Imported from a bank message") | rendered in transaction and finance history rows and detail where `importSource == ImportProvenance.sms`; has a screen-reader label; lives in `core/design_system/` because two features render it |

## 5. Localization

All strings are ARB keys in `lib/core/l10n/app_en.arb` (template, per `l10n.yaml`) and `app_ar.arb`, prefix **`smsImport`**, each with an `@key` carrying a `description` (and typed `placeholders`), as in `syncStatusPending`. Both languages ship together; a parity test `test/features/sms_import/presentation/l10n_parity_test.dart` (cloned from `ai_assistant/presentation/l10n_parity_test.dart`) checks: both languages non-empty, no AR-only keys, matching placeholder names, and that every `plural` in English has the Arabic category set `=0`/`=1`/`=2`/`few`/`many`/`other` present (the repo's existing `syncStatusPending`, `app_ar.arb:368`, omits `many`; it is left alone as a separate follow-up, and the parity test enforces the full set for `smsImport*` keys only; new keys write all forms so counts 11-99 are grammatical).

Key families (each family is a prefix; individual keys are enumerated in tasks):

| Family | Covers |
|---|---|
| `smsImportHome*` | quick action label, count card, onboarding card, dismiss |
| `smsImportSettings*` | section titles, status labels, window labels, cash-withdrawal switch and help, counts |
| `smsImportEnable*` | explanation copy, step titles, continue/not now, done summary labels |
| `smsImportPermission*` | denied, permanently denied, revoked, unavailable banners and actions |
| `smsImportRestricted*` | the step-by-step guidance and the "may be blocking" caveat |
| `smsImportScan*` | progress, cancel, summary lines, interrupted, errors |
| `smsImportPending*` | list title, empty states per platform, row labels, selection, batch ignore dialog, expired notice |
| `smsImportReview*` | field labels, required-missing line, type labels, candidate chips, foreign-context line, time note, note helper, discard dialog, add/ignore, saving/saved/failed, already-handled |
| `smsImportKind*` | `SmsKind` display names (ICU `select`) |
| `smsImportSuggest*` | suggestion hints (ICU `select` on suggested type), fixed refund hint (FR-024a), ATM preference link text, generic-parser notice |
| `smsImportWarning*` | one string per `SmsWarning` |
| `smsImportDuplicate*` | banner, sheet title, "already in Daftary" / "this message", comparison phrases, two actions |
| `smsImportPaste*` | screen title, field hint, paste button, process, limits text, nothing-to-paste, not-recognized, too-large, recognized/skipped summary, enter manually |
| `smsImportShare*` | share-launch result strings (unlock deferral needs none; reuses paste results) |
| `smsImportIgnored*` | Undo list title, status labels, days left, undo, "comes back after re-scan" |
| `smsImportMute*` | "Stop suggesting from this sender", confirmation (states that this sender's pending items are removed), muted-senders screen |
| `smsImportMappings*` | learned categories screen, clear confirmation, "category removed" |
| `smsImportError*` | one per failure row of the spec error table, without content |
| `smsImportSemantics*` | screen-reader labels (section 7) |
| `smsImportProvenance*` | "Imported from a bank message" label (Arabic "مستورد من رسالة بنكية") and its semantics label; covers scan, paste and share-sourced saves |

Plural keys (ICU `plural`; English `=0`/`=1`/`other`; Arabic `=0`/`=1`/`=2`/`few`/`many`/`other`): `smsImportScanFound` ("N bank messages found"), `smsImportScanNeedReview` ("M need your review"), `smsImportScanSkipped`, `smsImportScanUnreadable`, `smsImportScanProgress`, `smsImportPendingExpiredNotice` ("N suggestions expired"), `smsImportPendingSelectedCount`, `smsImportPendingIgnoreConfirmTitle`, `smsImportHomeCardCount` ("N bank transactions to review"), `smsImportPasteRecognized`, `smsImportPasteSkipped`, `smsImportIgnoredDaysLeft`, `smsImportMappingsCount`. Select keys: `smsImportKindLabel` (`{kind, select, cardPurchase{...} atmWithdrawal{...} ... other{...}}`), `smsImportSuggestHint` (on suggested type). Existing precedent for select: `repaymentFlipConfirmMessage` (`app_en.arb:2687`).

Formatting: amounts through `CurrencyFormatter(currency, locale)` and dates through `AppDateFormatter(locale)`, both Western digits in Arabic via `numeralLocaleFor` (FR-090); the message time of day via `DateFormat.jm(numeralLocaleFor(locale))` post-processed with `NumeralParser.toWesternDigits`. No new formatter.

**Decision**: paste/share-sourced saves also carry `import_source = 'sms'` (one wire value in 027; a value per channel would add a 027 check value and change nothing the user sees), so the copy is channel-neutral: "Imported from a bank message" (Arabic "مستورد من رسالة بنكية"), matching spec US1-9 and FR-057.

## 6. Share and App Lock flow

`SharedTextRouter` (precedent `NotificationTapRouter.start(router)`, started in the `startup.whenReady` block of `main.dart`): subscribes to `SharedTextSource.stream` and calls `takeInitial()` once; keeps the text in the in-memory `SharedTextInbox` (never a route argument); waits until `LockStatus.isLocked == false`; then `router.go('/bank-messages/paste')`. `AppLockGate` keeps the routed child mounted but offstage while locked, so nothing renders before unlock, and parsing is deferred until unlock so the text lives only in memory until then (FR-016a, FR-079). After consumption the inbox clears. A not-recognized share stores nothing (FR-018). The Android entry is the `ShareTargetActivity` trampoline (sms-platform-channel §2.5), so no second engine exists; spike S1 only verifies the instance count is 1 and does not change this Dart contract.

## 7. Accessibility (FR-093..FR-096, SC-009)

1. Every interactive control has a localized `Semantics` label stating meaning; icon-only buttons have `tooltip`/label. Rows announce as one node: "Expense, 125.50 EGP, 4 March, Example Cafe, high confidence, Ignore suggested".
2. Confidence and warning indicators have **icon + text label**, never color alone; inferred fields carry the distinct "Inferred, not read" badge (reuse of `ConfidenceIndicator`'s semantics).
3. Required-field errors are text (`errorText` + the "Missing: ..." line), associated with the field; the first invalid field is announced and focus moves to it when Add is attempted.
4. Touch targets >= 48 x 48 dp (chips, segmented control, checkboxes, list actions); `tokens.dart` spacing only.
5. Live regions and announcements (`SemanticsService.announce`, polite unless noted): scan progress (at 25% steps and on completion), scan summary, paste result, "Possible duplicate found" (assertive), "Added", "Ignored N", "Restored", errors.
6. Text scaling to 200% without clipping or overlap: columns not rows for primary content, `Wrap` for chips, sheet cards stack, the sticky action bar scrolls with content when it would exceed 40% of the viewport.
7. Contrast: tokens meeting WCAG AA in both themes; no raw `Color(...)` literals (constitution XV, a grep guard like the existing design-token test).
8. Screen-reader flow of review: header -> type -> amount -> date -> category/person -> note -> original -> actions; Add is announced with its disabled reason.
9. Selection mode exposes `Semantics(selected:, checked:)` and the "N selected" count.
10. Reduced motion respected (no required animations).

Tests: per-screen widget tests with `SemanticsController` assertions, `textScaleFactor 2.0` golden-free overflow checks, 48 dp target assertions, theme x locale matrix.

## 8. RTL and bidirectional rules (FR-091, FR-092)

1. Layout uses `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `start`/`end`; no `left`/`right` literals in the feature (grep guard).
2. Directional icons (back, chevrons, progress arrows) use mirroring-aware icons or `matchTextDirection: true`; non-directional icons (shield, check) do not flip.
3. The original message is rendered in **its own** direction (`Bidi.detectRtlDirectionality` on first strong character) regardless of app locale, left-aligned or right-aligned accordingly via `textAlign: TextAlign.start` inside a `Directionality`.
4. Embedded LTR tokens inside RTL strings (sender IDs, masked card "•••• 1234", amounts with currency code, reference-free identifiers) are isolated with LRI/PDI marks through `BidiText`, so digits and punctuation do not reorder; amounts display Western digits per FR-090.
5. Segmented controls, steppers and the side-by-side duplicate cards mirror: "Already in Daftary" sits at the start edge in both locales; the stacked narrow layout preserves reading order.
6. The 3-step restricted-settings guidance is a numbered list; numbers are Western digits in both languages; the sentence order is authored per language (not concatenated from fragments), including plural and select forms.
7. Every new screen has an RTL x LTR x light x dark widget test (pattern `test/features/ocr/presentation/widgets/ocr_rtl_theme_test.dart`).

## 9. Navigation and lifecycle notes

- Review advances with `pushReplacement` so back from the last item returns to the list, not to an already-decided item.
- On app resume the hub/settings cubits call `GetSmsPermissionStatus` (prompt-free) to reflect revocation (FR-070); the catch-up itself is run by `SmsCatchUpTrigger`, not by screens.
- Opening the list triggers `ExpirePendingImports` then `ReparsePending` (both idempotent), then shows the expired notice.
- No screen logs; no screen reads the clipboard except the Paste button; no screen shows pending content on Home (FR-050).
- Debug builds only: a "Inject synthetic message" tile in the existing debug settings (pattern of `debug_seed_tile.dart`) feeds `ParseMessages`/ingestion without the OS (research Decision 14); excluded from release builds by `kDebugMode`.
