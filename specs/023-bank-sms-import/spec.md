# Feature Specification: Bank SMS Transaction Import

**Feature Branch**: `023-bank-sms-import`

**Created**: 2026-10-06

**Status**: Draft (clarified 2026-10-06; analysis remediation 2026-10-07)

**Input**: User description: "Bank SMS Transaction Import — detect eligible bank SMS (Android automatic, iOS user-initiated), parse, user review/edit, add/ignore, categorize, link person, duplicates; never auto-create."

## Overview

### Feature Overview

Daftary users receive a bank SMS for almost every card purchase, ATM withdrawal, transfer and salary credit. Today they re-type each one into the app, or forget. This feature lets Daftary read those messages **on the device**, turn each eligible one into a **pending import** (a suggestion, not a record), and let the user review, edit, categorize, link to a person where relevant, and then explicitly **Add** or **Ignore** it.

The feature has two platform behaviors that differ by what the operating system allows:

- **ANDROID SMS IMPORT**: with the user's opt-in and the read-SMS permission, Daftary scans the inbox on request, and automatically catches up on new recognized bank messages whenever the app comes to the foreground. There is no background work and no SMS receiver in v1.
- **iOS USER-INITIATED IMPORT**: iOS apps cannot read the SMS inbox. The only iOS path in v1 is Paste: the user copies a message (or several) and pastes it into Daftary.

Android also accepts plain text shared to Daftary from other apps (for example Google Messages, which offers Share on a message). On both platforms the same on-device parsing, review, duplicate detection and save pipeline is used. The paste pipeline is also the fallback on Android when SMS permission is unavailable.

### Problem Statement

1. Manual entry of bank activity is tedious, so the user's income and expense picture drifts from reality.
2. Bank SMS contain exactly the facts needed (amount, direction, date, merchant) but are unstructured, bilingual (Arabic and English), bank-specific, and mixed in with OTPs, promotions and declined-payment notices.
3. A naive "read SMS and auto-save" approach would create wrong financial records, double-count transactions the user already typed, and expose sensitive messages. This is unacceptable for a product whose promise is a trustworthy notebook.

### Goals

- G1. Turn a recognized bank SMS into a pre-filled, reviewable suggestion in one tap (or zero taps on Android after opt-in, through the automatic catch-up).
- G2. Keep the user in control: nothing becomes a transaction without an explicit Add on that specific item.
- G3. Be honest about uncertainty: show per-field and overall confidence, mark inferred values, and never guess silently.
- G4. Avoid duplicates: the same SMS never produces two records, and likely overlaps with entries the user already has are flagged.
- G5. Keep all SMS processing on the device; raw message text never leaves it.
- G6. Work fully offline, in Arabic and English, RTL, light and dark, accessible.
- G7. Reuse the existing money model and write paths; no new transaction types.

### Non-Goals

- NG1. Auto-creating or auto-saving any transaction from an SMS, including "add all" in v1 (batch **ignore** is allowed; batch **add** is not).
- NG2. Reading non-bank SMS, personal conversations, or OTPs; acting as a default SMS app.
- NG3. Open Banking, bank APIs, screen scraping of bank apps, or reading bank-app notifications.
- NG4. Sending SMS content to any server, the BYOK AI assistant, or any LLM in v1. Any future AI-assisted parsing requires a separate spec, explicit opt-in and redaction.
- NG5. iOS automation via Shortcuts or message filters in v1.
- NG6. New transaction types (refund, transfer, adjustment, debt, gift) and automatic currency conversion.
- NG7. Reconciling balances, storing account balances, or tracking bank accounts as entities.
- NG8. Importing occasion contributions, and offering Repayment as a kind in review. In v1 the review offers Given or Received for people-ledger items; a repayment is entered through the existing manual form (see Open Questions, OQ1).
- NG9. Mobile-wallet SMS coverage as a committed v1 deliverable (see Open Questions, OQ4).
- NG10. **Deferred to a later version: live detection.** Background receipt of incoming SMS while the app is closed, any SMS receiver, any notification for imported messages, and the receive-SMS permission. v1 relies on the foreground catch-up scan instead (FR-013).
- NG11. **Deferred to a later version: an iOS share extension.** iOS uses Paste only in v1. (Android keeps its text share target, FR-016.)

### Product Principle

Daftary is "someone who remembers my money for me", not an ERP. The feature must feel like a helpful friend who says "I noticed this message from your bank. Want me to write it down?" and waits for the answer. It must not feel like a bank-statement importer, a reconciliation tool, or surveillance.

### Governance Alignment

- Constitution Principle X ("OCR is an uncertain input requiring confirmation") applies directly: SMS parsing is the same class of uncertain input and follows the same shape: Receive, Parse, Validate, User Review, Confirm, Persist, never auto-create. Constitution v1.1.0 (amended 2026-10-07) names SMS explicitly in Principle X.
- Principles VIII (integer minor units; AI never a source of financial numbers), IX ("AI Integration Is Isolated and Non-Authoritative"; this feature sends nothing to AI in v1, per NG4), XI (offline, idempotent), XII (logs never include financial or personal data), XIII (no hardcoded strings, locale-aware currency), XV (design tokens) and XVI (tests) apply directly. Permissions follow both Principle XII and the Engineering Standards permissions rule: requested contextually with a reason, never at startup.
- The Financial Domain Override applies: imported records are never silently created or modified, and every saved import is traceable to an explicit user confirmation.
- Spec 022 rule: income and expense figures count only FinanceEntries; people, occasion and savings money never count as income or expense. The mapping rules below respect this.

## Clarifications

### Session 2026-10-06

- Q: How should the Android SMS-reading capability ship in v1? → A: The existing sideloaded GitHub-release APK includes SMS reading, and paste/share is in every build; the FR-001 capability switch stays for any future store build. Release gate: verify whether Play Protect enhanced fraud protection covers Egypt and verify the Android 15 restricted-settings flow on real devices; if the Egypt check fails, fall back before release to two APKs (a standard SMS-free one plus a "with bank SMS" one).
- Q: Should Daftary react to new bank SMS while it is closed (live detection) in v1? → A: No. There is no background work and no SMS receiver; when the feature is on and the app comes to the foreground, an automatic catch-up scan runs over recognized senders since the last scan (maximum 90 days), alongside the manual scan and paste/share. Only read-SMS is requested. Live detection with notification (the original US3, now replaced by the catch-up story) is deferred to a later version (NG10).
- Q: How should raw message text and staging data be protected on the device and in backups? → A: Raw text is masked and encrypted at rest (AES-256-GCM) with a random per-install key held in the app's secure storage: on Android wrapped by a non-exportable Android Keystore key, on iOS a Keychain item with this-device-only accessibility, so no device or cloud backup can yield readable raw text; it is purged when the user Adds, Ignores or the item expires; other staging data (parsed fields, hashed tombstones, sender mutes, learned mappings) lives in the main local database like other user data. Backups can never yield readable raw text; undecryptable raw text is treated as purged; Add and its status update commit in one local transaction.
- Q: Is the iOS share extension in v1, or is Paste the only iOS entry? → A: Paste only on iOS, with no share extension in v1 (moved to Non-Goals). Android keeps its "Share to Daftary" text share target.

### Session 2026-10-07 (analysis remediation)

- Q: May a parser or rule update change a message's fingerprint? → A: No. The fingerprint uses a frozen, versioned normalization that is separate from parser matching (FR-023).
- Q: How are authorization reversals handled when the purchase was already added? → A: They become pending items with Ignore suggested, a fixed hint, and the matched saved record shown side by side (FR-024b).
- Q: What happens to a fee stated in the same message as the transaction? → A: It becomes its own pending fee item, never merged into the amount (FR-030a).
- Q: How are moves between the user's own accounts at different banks handled when no own-account keyword is present? → A: A same-amount, opposite-direction pair within one day across banks or channels is flagged as a possible own transfer with Ignore suggested (FR-051d).
- Q: How is pasted or shared text with app-added header lines fingerprinted? → A: Known envelope lines are stripped before splitting and fingerprinting (FR-017a); the formats are verified by a device spike on real messaging apps.
- Q: Which year applies to a year-less pasted message? → A: The current year, or the previous year if that date would be in the future (FR-036).
- Q: Are duplicates compared across currencies? → A: There is no conversion, but a stated original-currency amount is also compared against saved records (FR-059).
- Q: Is the exact reference tier safe for banks that reuse short reference codes? → A: Only for banks whose reference IDs are unique per transaction; otherwise tier 2 also requires a date within one day (FR-059b).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Review and add a bank message as a transaction (Priority: P1)

A user has a pending import produced from a bank SMS. They open it, see the parsed amount, direction, date, merchant and a suggested category, correct anything wrong, and tap Add. Only then does a real transaction exist.

**Why this priority**: This is the core value and the safety gate. Without review-and-confirm, no other part of the feature is acceptable.

**Independent Test**: Seed a pending import from a synthetic SMS (no platform SMS access needed), open review, edit one field, tap Add, and verify exactly one saved record with the edited value, provenance marked as SMS, and the pending item's raw text purged. Verify zero records are created for any item the user did not Add.

**Acceptance Scenarios**:

1. **Given** a pending import for a debit card purchase, **When** the user opens it, **Then** the review screen shows amount, currency, direction, date, merchant, suggested category and an overall confidence label, all editable, and nothing is saved yet.
2. **Given** the review screen with all required fields valid, **When** the user taps Add, **Then** exactly one expense is saved through the standard idempotent write path, the item leaves the pending list, and its raw message text is purged.
3. **Given** a required field (FR-043a: amount, currency, type, date, or category/person) is missing or invalid, **When** the user views the review screen, **Then** Add is disabled and the incomplete required field is identified in text.
4. **Given** the user edits the amount, **When** they tap Add, **Then** the saved amount is the edited value, validated by the same limits as manual entry.
5. **Given** the user taps Add twice quickly, or the app is killed mid-save and the item is re-submitted, **When** the save completes, **Then** exactly one record exists, and the record and the item's added status were committed together.
6. **Given** a pending import the user never opens, **When** any time passes or the app restarts, **Then** no transaction is ever created from it.
7. **Given** the user chooses to view the original message, **When** the item is still pending and its raw text can be decrypted, **Then** the masked original text is shown (FR-045); after Add or Ignore, or when it cannot be decrypted, it is not available.
8. **Given** an item was added, **When** the audit trail of the saved record is inspected, **Then** its `created` audit entry exists and the record carries SMS provenance (`import_source`), together identifying the bank-message import confirmed by the user's Add.
9. **Given** a saved SMS import appears in history, **When** the user views it, **Then** it shows an "Imported from a bank message" label (Arabic "مستورد من رسالة بنكية") that has a screen-reader label.
10. **Given** pending items older than 30 days exist, **When** the user next opens the pending list, **Then** they are gone and a one-line notice reads "N suggestions expired" and says they can be restored (FR-067).

---

### User Story 2 - Android: enable SMS import and scan recent bank messages (Priority: P1)

An Android user enables "Import from bank SMS" in Settings (or from a one-time card), reads the reason, grants the read-SMS permission, picks a window (default 30 days), and sees pending imports for recognized bank messages only.

**Why this priority**: It is the primary acquisition path for the feature on Android and proves the ingestion pipeline end to end.

**Independent Test**: With the capability enabled for the build, grant permission in a test device with synthetic messages from a recognized sender and a non-bank sender; run the scan and verify only the bank message becomes pending, and the non-bank message is not stored.

**Acceptance Scenarios**:

1. **Given** the feature is off, **When** the user opens the Settings entry, **Then** an explanation of what is read, what is not, and that nothing is saved without approval is shown before any system permission prompt.
2. **Given** the user accepts the explanation, **When** the system permission prompt appears and the user grants it, **Then** the user chooses a scan window (default 30 days, maximum 90) and starts the scan.
3. **Given** the inbox contains bank and non-bank messages, **When** the scan runs, **Then** only messages from recognized bank senders become pending imports, and non-bank messages are neither stored nor listed.
4. **Given** the same inbox is scanned again, **When** it completes, **Then** no message produces a second pending item or a second transaction.
5. **Given** the user denies the permission, **When** the prompt closes, **Then** a dedicated explanation state offers the paste and share flow and a path to system settings, and the app does not re-prompt unprompted.
6. **Given** the app is installed outside an app store and the operating system appears to block the permission grant (restricted settings), **When** the user taps Allow and no system dialog appears, **Then** the app infers the block, guides the user step by step to App info, the overflow menu and "Allow restricted settings", retries the grant on return, and still offers paste and share.

---

### User Story 3 - Android: automatic catch-up when the app opens (Priority: P2)

With the feature on, whenever the user opens Daftary, new bank messages that arrived since the last scan are found automatically and appear as pending imports, with no background work and no notification.

**Why this priority**: It delivers most of the value of "live" detection without a background receiver; the manual scan and paste still deliver the core value.

**Independent Test**: With the feature on, deliver synthetic bank messages while the app is closed, open the app, and verify they appear once as pending items and no record is created.

**Acceptance Scenarios**:

1. **Given** the feature is on and permission is granted, **When** the app comes to the foreground, **Then** a catch-up scan runs over recognized senders since the last processed message (at most 90 days) and new items appear as pending.
2. **Given** 2 bank SMS arrived while the app was closed, **When** the user opens the app, **Then** both are pending, with no duplicates, even if the app was force-stopped.
3. **Given** the catch-up finds a non-bank or OTP message, **When** it is checked, **Then** nothing is stored.
4. **Given** the permission was revoked or the feature is off, **When** the app comes to the foreground, **Then** no catch-up runs and no permission prompt appears.

---

### User Story 4 - Paste (iOS and Android) or share (Android) a bank message (Priority: P1)

A user copies a bank message (or several) in their messaging app, opens Daftary's "Paste bank message" screen, taps Paste (or pastes into the text field), and gets pending imports. On Android they can alternatively use Share on a message (for example in Google Messages) and pick Daftary.

**Why this priority**: It is the only iOS path and the cross-platform fallback; it must work without any SMS permission.

**Independent Test**: Provide synthetic text through the paste action and, on Android, through the share entry point, and verify identical pending items; verify the clipboard is never read without the Paste tap.

**Acceptance Scenarios**:

1. **Given** the Paste screen is open, **When** the user taps Paste or pastes into the text field, **Then** the text is parsed on the device and shown as pending item(s) for review.
2. **Given** the Paste screen is open and the user has not tapped Paste, **When** any time passes, **Then** the clipboard is never read.
3. **Given** the pasted text contains several bank messages, **When** parsing completes, **Then** each is split into its own pending item, and a summary states how many were recognized and how many were skipped.
4. **Given** an Android user shares text to Daftary from another app, **When** the share completes, **Then** Daftary opens, honors App Lock, and the recognized item(s) appear in review.
5. **Given** the text is not a recognized bank message, **When** parsing completes, **Then** the user is told it could not be recognized and offered manual entry, with nothing stored.
6. **Given** the system clipboard read returns empty (for example the user denied paste for the app), **When** the user taps Paste, **Then** the "nothing to paste" state explains how to paste into the text field instead.

---

### User Story 5 - Duplicate protection (Priority: P1)

A user who already typed a transaction, or who imports the same message twice, is protected from double counting without being blocked from legitimate similar purchases.

**Why this priority**: A duplicate financial record is a trust failure (consistent with the 022 stance that a second row is P0).

**Independent Test**: Import the same synthetic SMS twice (exact), import a message matching a manually saved entry (probable), and import two same-merchant purchases with different reference numbers (similar); verify collapse, warning, and no warning respectively.

**Acceptance Scenarios**:

1. **Given** a message already imported, added or ignored, **When** it is seen again by any path, **Then** no second pending item and no second transaction is created.
2. **Given** an existing saved transaction with same amount, currency, matching direction and a date within one day, **When** a pending import is opened, or when the user taps Add after edits that newly create such a match, **Then** a side-by-side warning offers "It's the same, don't add" and "It's different, add anyway" before anything is saved.
3. **Given** the user chooses "It's different, add anyway", **When** they save, **Then** it is saved and not blocked.
4. **Given** two messages whose reference numbers are both present and different, or whose dates are more than one day apart, **When** both are pending or saved, **Then** no duplicate warning appears.
5. **Given** a fee SMS that shares the withdrawal's reference ID but has a different amount, **When** both are ingested, **Then** both become separate pending items.

---

### User Story 6 - Ignore, mute and undo (Priority: P2)

A user dismisses messages that are not transactions, mutes a sender that is not a bank, and can undo an ignore (or an expiry) for 30 days.

**Why this priority**: Keeps the pending list clean and the user in control, but the feature is usable without it.

**Independent Test**: Ignore one item, mute a sender, restore one from the ignored list, and verify that ignored items do not resurface, the muted sender produces nothing, and undo returns the item to pending only after a re-scan or re-paste.

**Acceptance Scenarios**:

1. **Given** a pending item, **When** the user chooses Ignore, **Then** it leaves pending, its raw text is purged, and re-scanning never resurfaces it.
2. **Given** several selected items, **When** the user chooses Ignore for the selection, **Then** all are ignored in one action after confirmation.
3. **Given** a sender is marked "Stop suggesting from this sender", **When** future messages arrive from it, **Then** they are not stored or shown.
4. **Given** an ignored or expired item visible in the Undo list (30 days), **When** the user chooses Undo, **Then** its tombstone is removed and the message returns to pending only after a re-scan (Android) or a re-paste or share.

---

### User Story 7 - Transfers, people and categories (Priority: P2)

A user who received a transfer from a person sees a suggested Received entry with a person suggestion; a user who bought groceries sees "groceries" suggested and remembered next time.

**Why this priority**: Improves accuracy and speed, but US1 works with the "other" category and manual choices.

**Independent Test**: Import synthetic transfer and purchase messages; verify suggestions, that no person is created without confirmation, and that a corrected category is suggested for the same merchant afterwards.

**Acceptance Scenarios**:

1. **Given** an incoming transfer naming a person who matches an existing person by name, **When** review opens, **Then** Income is the default with a one-tap suggestion to record it as Received from that person (person pre-selected); with no name match, Income remains the default and no person is created.
2. **Given** a transfer naming someone not in People, **When** review opens, **Then** no person is created until the user confirms or creates one.
3. **Given** the user changes a merchant's category and saves, **When** a later message from the same merchant is parsed, **Then** that category is suggested.
4. **Given** an own-account transfer or savings movement (explicit keywords only, FR-051c), **When** review opens, **Then** Ignore is the suggested action and nothing is counted as income or expense.

---

### User Story 8 - Permission and feature lifecycle (Priority: P2)

A user can turn the feature off, revoke permission in system settings, or delete all data, and the app behaves predictably.

**Why this priority**: Required for trust and platform correctness; follows the permission precedent used by notifications.

**Independent Test**: Revoke the permission while the app is backgrounded, return, and verify the "permission off" state, retained pending items, and working paste/share flow.

**Acceptance Scenarios**:

1. **Given** the feature is on, **When** the user turns it off, **Then** scanning and catch-up stop immediately and the user is asked whether to also delete pending imports.
2. **Given** permission is revoked in system settings, **When** the app resumes, **Then** the "permission off" state is shown and existing pending items remain reviewable.
3. **Given** "Delete all data" is run, **When** it completes, **Then** pending imports, tombstones, sender rules and learned mappings are all gone.
4. **Given** the device was restored from a backup or the app reinstalled, **When** pending items exist whose raw text cannot be decrypted, **Then** they remain reviewable from their parsed fields, "Show original" is unavailable, and old tombstones may no longer match (FR-062).

---

### User Journeys

1. **Android first-time enable and inbox scan.** The user sees a one-time card on Home (or opens Settings, "Bank messages"). They read the explanation, tap Continue, grant the read-SMS permission, choose "Last 30 days", and tap Scan. A progress state shows; results appear as "N bank messages found, M need your review". They open the first item, fix the category, tap Add, and the review advances to the next. They ignore two promotional-looking items and leave the rest for later. Nothing was saved except the one they added.
2. **Android catch-up on open to review to add.** The feature is on. The user pays at a restaurant; the bank SMS arrives while Daftary is closed. Later they open Daftary; the automatic catch-up finds it and the Home card says "1 bank transaction to review". They unlock if App Lock is on, open it, see "restaurants" suggested with high confidence, and tap Add. The item is saved and its raw text purged.
3. **iOS paste.** The user copies a bank message in Messages, opens Daftary, taps the Home quick action "Bank message", which opens "Paste bank message". They tap Paste (accepting the system paste notice if shown) or paste into the text field, and see the parsed item. They review, adjust the date, and tap Add.
4. **Android share from Google Messages.** The user long-presses a bank message in Google Messages, taps Share, and picks Daftary. Daftary opens (behind App Lock) with the item in review; if the text was unrecognized, the not-recognized state offers manual entry.
5. **Duplicate warning.** The user typed "Coffee 85" yesterday. Today they import the matching bank SMS. Review shows a side-by-side card: "You may already have this". They choose "It's the same, don't add"; the pending item is closed as a duplicate without creating a record.
6. **Permission revoked.** The user revokes SMS permission from system settings. On returning to Daftary the import screen explains that automatic import is off, keeps existing pending items, and offers paste and share. Re-enabling restores scanning without losing history.

### Edge Cases

- Message contains an OTP or the words "do not share": MUST NOT be stored or parsed beyond classification as non-transactional.
- Declined, failed, or "pending authorization" notices: non-transactional (FR-024); never suggested as an expense.
- Reversal or cancellation of an authorization (money that never posted): a pending item with Ignore suggested and a hint, because the user may already have added the purchase from the authorization message; a matching saved record is shown side by side (FR-024b).
- Refund or reversal credit that returns posted money: pending item with Ignore suggested and a fixed hint (FR-024a); the saved record is never modified.
- Amount present but direction ambiguous: direction left unset and required before Add.
- Message with no amount: not a pending item; counted as unreadable in a scan, or shown as "could not read, enter manually" for paste/share, and nothing is stored (FR-039a).
- Date missing or unparseable: fall back to the SMS received timestamp, marked inferred, when one exists (scan and catch-up). Paste and share have no received timestamp: Date stays empty and Add stays disabled until the user picks one.
- Date-only model: the SMS time is shown in review but only the calendar date stated in the message is saved; when only the received timestamp exists, the device's local zone at receipt is used (FR-038).
- Currency not in the app's catalog: the user MUST pick a supported currency and re-enter the amount in it; no conversion is performed (FR-053).
- Foreign-currency purchase on an EGP card: the billed account-currency amount is the default; the original amount is shown as read-only context (FR-053).
- Message with multiple amounts (amount, fee, available balance): the transaction amount and fee are distinguished; the balance is never a candidate and is never stored; two remaining candidates show as one-tap choices (FR-030).
- A fee SMS following a withdrawal: treated as a separate expense item; sharing a reference ID with the withdrawal does not merge them (FR-059b).
- Same card and merchant twice within minutes with different reference IDs: both pending, no warning.
- Two distinct messages with byte-identical bodies (no date, time or reference number) collapse as exact duplicates. Accepted limitation; the user can add the second one manually.
- ATM withdrawal: Ignore is suggested by default unless the preference "count cash withdrawals as spending" is on, in which case Expense is suggested; the ATM item shows a one-line link to that preference.
- Credit-card payment, installment debit or conversion notice, or own-card settlement: Ignore is suggested, since the spending was or will be counted elsewhere.
- No active category of the required type exists (all archived or removed): no category is selected and Add stays disabled until the user chooses or creates one.
- The user wants to record a repayment: not offered in review in v1; use the existing manual form (NG8, OQ1).
- Same message imported on two Android devices on the same account: second device's save is caught by the probable-duplicate check against synced transactions.
- Very long, empty, or non-text (MMS-only) messages: skipped safely with a count, never a crash.
- Clipboard or shared text that is non-SMS, empty, or longer than 10,000 characters or 50 messages: rejected or truncated with a clear message stating the limits; nothing is stored beyond recognized items.
- Unsupported bank format: generic fallback parser at confidence no higher than Medium, clearly labeled; with no amount, shown as "could not read, enter manually".
- Sender spoofing or look-alike sender IDs: only allow-listed senders are read (FR-020); a recognized sender whose content does not match any bank signature falls to the generic parser at lower confidence. Paste and share have no sender and use the content signature alone.
- User edits the amount to differ from SMS: allowed; the saved record reflects the user's value.
- App updated with improved parser rules while items are pending: pending items are re-parsed when their raw text is readable; saved items are never altered.
- Pending item older than 30 days: expires and is purged (restorable from the Undo list, FR-067).
- Device restored from backup or app reinstalled: raw text that cannot be decrypted is treated as purged; "Show original" is unavailable (FR-074a).
- Device locale Arabic with Western-digit display: digits remain Western as per the existing display decision; inputs accept Arabic-Indic digits.
- Phone clock or timezone changed between receipt and review: the date uses the SMS's own date, not "today".
- Arabic text with diacritics, tatweel, mixed directionality, or letter-form variants (alef/ya/ta marbuta).
- Android restricted settings blocks the permission for a sideloaded install: guidance shown, with fallback to paste/share.
- Fee stated in the same message as a withdrawal or transfer: a separate pending fee item linked to its parent for display (FR-030a).
- Money moved between the user's own accounts at two banks without own-account keywords: the debit and credit are flagged as a possible own transfer and Ignore is suggested for both (FR-051d).
- Text copied or shared from a messaging app with sender, date or separator lines: those lines are stripped before splitting and fingerprinting (FR-017a).
- A year-less message pasted in early January that refers to late December: the previous year is used (FR-036).
- A purchase the user typed in its original currency (for example USD) before importing the SMS billed in EGP: the probable warning also compares the stated original amount (FR-059).
- The user deletes a record saved from an import: its tombstone remains, so the same message does not resurface for 97 days; the user can re-enter it manually.
- An app update changes parser rules: fingerprints are unchanged, so added, ignored and expired messages do not resurface on re-scan (FR-023).

## Requirements *(mandatory)*

### Functional Requirements

Numbering is stable; requirements retired by the deferral of live detection (FR-008, FR-009, FR-010, FR-013a, FR-071) keep their numbers and are not reused.

#### Distribution and capability gating

- **FR-001**: A build without the Android SMS capability MUST contain NO SMS permission in its merged manifest (including permissions contributed by dependencies) and no SMS receiver, and MUST present only the paste and share flows. The capability MUST be controlled by a single build-time distribution switch that adds or omits the read-SMS manifest declaration; the app MUST derive availability at runtime from that declaration, with no second Dart-side switch that could disagree with the manifest.
- **FR-002**: The system MUST NOT request any SMS-related permission on app start, on install, or from any screen other than the explicit enable flow of this feature.
- **FR-003**: The existing sideloaded, signed release APK distributed through GitHub releases MUST be built with the SMS capability on; paste and share MUST be present in every build. Google Play distribution is not a v1 target; the FR-001 switch remains for any future store build. Release gate: before release, verify (a) whether Play Protect enhanced fraud protection blocks installing or updating an APK that declares SMS permissions in Egypt, and (b) the Android 15 restricted-settings flow on real devices. If check (a) fails, the release MUST fall back to two APKs: the standard SMS-free APK and a separate "with bank SMS" APK.

#### ANDROID SMS IMPORT

- **FR-004**: On Android, the feature MUST be off by default and enabled only through an explicit user action from a Settings entry or a one-time onboarding card, both of which can be dismissed permanently.
- **FR-005**: Before the system permission prompt, the system MUST show a plain-language explanation of what is read (messages from recognized bank senders only), what is never done (no upload, nothing saved without approval), and how to turn it off.
- **FR-006**: The system MUST support a user-initiated inbox scan, run in the foreground, over a user-chosen window of 7, 30 or 90 days, defaulting to 30 and never exceeding 90.
- **FR-007**: The inbox scan MUST show progress, MUST be cancellable, and MUST leave already-created pending items intact if cancelled.
- **FR-008**: *(retired)* Replaced by FR-008a.
- **FR-008a**: The system MUST NOT run any work while the app is not in the foreground, MUST NOT register any receiver for incoming SMS, and MUST NOT request the receive-SMS permission. Live detection is deferred (NG10).
- **FR-009, FR-010**: *(retired with live detection; no notification is shown for imported messages)*
- **FR-011**: On Android, the system MUST also offer the paste screen and MUST accept plain text shared to Daftary from other apps, using the same pipeline.
- **FR-012**: If the SMS permission is denied or revoked, the feature MUST degrade to the paste and share flow, MUST keep existing pending items reviewable, and MUST NOT silently re-prompt.
- **FR-013**: Whenever the feature is on, the permission is granted and the app comes to the foreground, the system MUST run an automatic catch-up scan of recognized senders since the last processed message (at most 90 days), without producing duplicates and without any prompt or notification. A foreground session starts at a transition to the resumed state; the catch-up MUST run at most once per 60 seconds (resumes caused by the permission dialog, App info or the share sheet fall inside that window), MUST NOT run concurrently with an explicit scan, and MUST stop immediately when the feature is turned off or the permission is revoked.
- **FR-013a**: *(retired)*

#### iOS USER-INITIATED IMPORT

- **FR-014**: On iOS, the system MUST NOT attempt to read the SMS inbox or request any SMS-related permission.
- **FR-015**: The system MUST provide a "Paste bank message" screen that reads the clipboard only in response to an explicit user tap on a Paste control, and MUST NOT read the clipboard at app launch, screen open, resume, or in the background. The screen MUST also offer an editable text field where the user can type or paste text; pasting through the system edit menu into that field is the path that avoids the iOS paste prompt. A programmatic clipboard read may show the system "Allow Paste" prompt or return empty when the user has denied paste for the app; an empty result MUST show the "nothing to paste" state with guidance to paste into the text field.
- **FR-016**: On Android, the system MUST provide a text share target that accepts plain text shared from other apps and hands it to the review pipeline. The share target MUST be a dedicated lightweight activity that hands the text to the running app instance, so a share never starts a second app instance; the main activity's launch mode is unchanged. There is no iOS share extension in v1 (NG11).
- **FR-016a**: Text received through the Android share target MUST be processed only by the same pipeline, MUST be shown only in review after App Lock is satisfied, and, if not recognized as a bank message, MUST NOT be stored (FR-018).
- **FR-017**: The paste and share flows MUST accept text containing several messages and split it into separate pending items, reporting how many were recognized and skipped. Input MUST be bounded to 10,000 characters and 50 messages, with a clear message when exceeded.
- **FR-017a**: Before splitting and fingerprinting, the system MUST strip the envelope lines that messaging apps add when copying or sharing (sender name, date or time headers, separators), for the formats verified on the target messaging apps, so a pasted or shared message fingerprints identically to the same message read from the inbox (FR-023).
- **FR-018**: Text received through paste or share that is not recognized as a bank message MUST NOT be stored and MUST result in a clear not-recognized state with a manual-entry option.
- **FR-019**: iOS automation (Shortcuts-based or message-filter-based import) MUST NOT be part of v1.

#### SMS ingestion

- **FR-020**: Only messages whose sender is on the recognized bank sender list (and not muted) MAY be read. On Android the sender filter MUST be applied in the inbox query selection, before any message body is read. Paste and share input has no sender: recognition MUST use the content signature alone, and overall confidence MUST be capped at Medium. Sender IDs are matched case-insensitively on their normalized form; the recognized lists ship with the app.
- **FR-021**: Every ingested message from any path (scan, catch-up, paste, share) MUST pass through the same pipeline: recognition, parsing, normalization, validation, classification, duplicate check, then creation of a pending import.
- **FR-022**: The system MUST NOT create a saved transaction at any point in ingestion; the only record ingestion may create is a pending import.
- **FR-023**: Each pending import MUST have a unique identity and a message fingerprint computed from the normalized message body ONLY. Sender and received time MUST NOT be inputs, so the fingerprint is identical across scan, catch-up, paste and share. The fingerprint MUST use a frozen, versioned normalization (removal of bidi and zero-width characters, whitespace collapse and digit normalization only) that is independent of the parser's matching normalization, so parser or rule updates never change a message's fingerprint; changing the fingerprint normalization requires a migration that matches both old and new fingerprints. Ingestion MUST be idempotent: processing the same message any number of times by any path yields one pending import.
- **FR-024**: Non-transactional messages (OTP, balance inquiry, promotion, declined or failed authorization, and pending authorization) MUST NOT become pending imports; they MUST be counted in a scan summary and SHOULD be listed in a "skipped" view without raw text.
- **FR-024a**: A credit that returns posted money (refund or reversal credit) MUST become a pending import with Ignore suggested and the fixed hint "If this refunds an expense you already added, edit or delete that expense instead." The system MUST NOT modify or delete any saved record because of an import.
- **FR-024b**: A reversal or cancellation of an authorization (money that never posted) MUST become a pending import with Ignore suggested and the fixed hint "If you already added this purchase, delete it. The bank says the charge was cancelled." When a saved record matches (same reference hash, or the same amount and currency with a date within one day of an own-money expense or Given record), review MUST show it side by side with an action to open it. The system MUST NOT modify or delete that record. Whether a bank's purchase message is a posted purchase or a pending authorization MUST be calibrated per bank on its corpus.
- **FR-025**: Pending imports MUST expire 30 days after creation if not added or ignored. Expiry MUST purge raw text and leave a tombstone (FR-066); parsed fields needed to display the item in the Undo list MAY be retained only for the 30-day Undo window and are then purged. On the next open of the pending list the user MUST see a one-line "N suggestions expired" notice that says they can be restored.
- **FR-026**: When parser rules are updated, pending (unsaved) imports whose raw text is readable MUST be re-parsed with the new rules; pending imports whose raw text cannot be decrypted keep their parsed fields unchanged; saved transactions MUST NOT be altered.

#### SMS parsing

- **FR-027**: Parsing MUST be performed entirely on the device, deterministically and rule-based. No message text MAY be sent to any server, AI assistant or model in v1.
- **FR-028**: The system MUST select a parser through a registry keyed on sender and content signature, apply bank-specific Arabic and English rule sets, and fall back to a generic parser when no bank rule set matches. Precedence: (1) a bank rule set matching sender and content signature; (2) paste and share only: a bank rule set matching the content signature; (3) the generic parser. A recognized sender with a non-matching signature falls to the generic parser. If several bank rule sets match, the one with the highest overall confidence wins, then a fixed registry order. Parsers MUST NOT be merged field by field. Corpus tests MUST show that supported banks never match each other's samples.
- **FR-029**: The v1 bank coverage target is NBE, Banque Misr, CIB, QNB Alahli, Banque du Caire, AAIB and InstaPay notifications, with the generic fallback for others. Support for each bank MUST be accepted only when it meets the corpus accuracy gate (SC-001) for that bank. The final list is confirmed in OQ3.
- **FR-030**: The parser MUST attempt to extract: amount, currency, debit or credit direction, transaction kind (card purchase, ATM withdrawal, transfer in or out, InstaPay, salary or deposit, bill payment, refund or reversal, fee), date, time, bank, merchant or counterparty, masked account or card last four digits, reference ID, available balance, and sender ID. The transaction amount is the amount adjacent to a debit, credit or purchase verb in the bank rule set; fees are parsed as separate amounts; the balance is never a candidate. If two non-fee candidates remain, amount confidence is Low and review shows both as one-tap choices.
- **FR-030a**: A fee stated in the same message as a transaction (for example an InstaPay or ATM fee) MUST become its own pending item (kind fee, Expense suggested), shown as linked to its parent and carrying its own fingerprint derived from the parent's, so the user can Add or Ignore it independently. A fee MUST NOT be added to or merged into the transaction amount.
- **FR-031**: The system MUST persist only the last four digits of any card or account number, MUST NOT persist the available balance, and MUST NOT persist any OTP or full account number.
- **FR-031a**: Before raw text is persisted, every digit run of 12+ digits (ASCII, Arabic-Indic or Eastern Arabic-Indic, single spaces or hyphens joining groups) and every Egyptian mobile number MUST be masked except its last four (threshold per bank rule set, default 12, never higher). Fingerprints and reference hashes MUST be computed once from the unmasked normalized text before masking and never recomputed; re-parse cannot recover masked references. This satisfies FR-031 and FR-077.
- **FR-032**: Parser rule sets MUST be versioned, and each pending import MUST record the rule-set version that produced it, together with parser id, per-field confidence and classification, on the pending record only. Tombstones and saved records store none of these.
- **FR-033**: A message that yields an amount but no determinable debit or credit nature MUST NOT be presented as ready to add; the type MUST be shown as incomplete (FR-043a).

#### Normalization

- **FR-034**: The system MUST normalize Arabic-Indic and Eastern Arabic-Indic digits to Western digits before parsing, handle thousands separators (comma, Arabic thousands separator) and decimal separators (period, Arabic decimal separator), and convert amounts to integer minor units of the stated currency.
- **FR-035**: The system MUST recognize common currency expressions including EGP, LE, L.E., ج.م, جنيه, USD, $, and others in the app's currency catalog, and MUST map them to ISO currency codes; an unrecognized currency MUST require the user to choose one.
- **FR-036**: The system MUST parse dates in common bank formats (for example dd/mm/yy, dd/mm/yyyy, dd-MMM, Arabic month names) and 12-hour and 24-hour times, and MUST interpret ambiguous two-digit years and day-month order using the bank rule set's convention; the generic parser assumes day-month order (Egyptian convention). A date without a year takes the year of the received timestamp, or the previous year if that would be in the future relative to it; for paste and share the current year applies, or the previous year if that date would be in the future relative to today; the field is marked inferred.
- **FR-037**: The system MUST normalize Arabic text variants (diacritics, tatweel, alef and ya forms, ta marbuta) before matching keywords, merchants and sender signatures.
- **FR-038**: The saved day MUST be the calendar date stated in the message. When the message states no date, the system MUST use the received timestamp when one exists (scan and catch-up), interpreted in the device's local time zone at receipt, and mark the date as inferred. Paste and share items with no stated date MUST leave Date empty; it is required and Add stays disabled until the user picks one.

#### Confidence scoring

- **FR-039**: The system MUST compute a per-field confidence and an overall confidence for each pending import, reusing the existing confidence model: each field is either *read* (with level Low, Medium or High) or *inferred* (no level, distinct styling). Overall confidence is the lowest level among the required read fields; any inferred required field caps it at Medium. The generic parser and paste/share input cap it at Medium. If any required field is absent, overall confidence is Low.
- **FR-039a**: A bank message with no amount MUST NOT become a pending item: it is counted as unreadable in a scan summary, or shown as "could not read, enter manually" for paste and share, and nothing is stored.
- **FR-040**: Confidence MUST be displayed as Low, Medium or High with an icon and a text label, never by color alone and never as a percentage, consistent with the existing scan review convention; inferred fields MUST carry a distinct visual treatment.
- **FR-041**: Overall confidence MUST be capped as stated in FR-039, and any item produced by the generic fallback parser MUST NOT be rated High.
- **FR-042**: Confidence MUST affect presentation and ordering only (low-confidence items are surfaced for attention first); it MUST NOT cause any item to be added automatically at any level, and Low or Medium confidence MUST NOT disable Add by itself; only incomplete or invalid required fields do (FR-046).

#### Review and edit flow

- **FR-043**: The system MUST provide a pending-imports list and a review screen where each item shows type (expense, income, given, received), amount, currency, date, category or person, note, bank and masked account, confidence, and any warnings. No separate import history exists: saved imports appear in normal history with the "Imported from a bank message" label, ignored and expired items appear in the 30-day Undo list, and the content-free counts of FR-102 are the only summary.
- **FR-043a**: "Required fields" means: amount, currency, type, date, and category (for income or expense) or person (for given or received). Add MUST be enabled only when all are present and valid.
- **FR-044**: Review MUST be a dedicated pending-import review screen with inline editable fields (type, amount, currency, date, category or person, note), following the scan review pattern. It MUST NOT open or modify the manual transaction forms. Every user-facing field MUST be editable, and edits MUST follow the same limits as the manual forms (amount greater than zero within the existing ceiling of at most 12 whole digits, category type must match entry type, note at most 500 characters, valid date). It MUST reuse the existing category picker, person picker with similar-name choice, and confidence indicator, and MUST create records only through the SMS confirm entry points (Architecture Impact: Single review gate), with no duplicated validation logic.
- **FR-045**: The review screen MUST offer a read-only "Show original message" while the item is pending and its raw text can be decrypted, rendered in the message's own direction and showing the masked text of FR-031a. It MUST NOT retain it after Add or Ignore, and MUST show it as unavailable when the text cannot be decrypted.
- **FR-046**: Add MUST be disabled while any required field (FR-043a) is incomplete or invalid, and MUST apply to exactly one item at a time; there MUST be no "add all" action in v1. The pending list supports multi-select for Ignore only. After Add the review advances to the next pending item.
- **FR-047**: Leaving review with unsaved edits MUST ask for confirmation; leaving without edits MUST leave the item pending unchanged.
- **FR-048**: The review MUST let the user switch an item between expense or income (own money) and given or received (people ledger), switching required fields accordingly. Repayment MUST NOT be offered in review in v1 (NG8, OQ1); a repayment is entered through the existing manual form. Occasion contribution MUST NOT be offered in v1.
- **FR-049**: The Note on a saved transaction MUST NOT be auto-filled with the raw message; the user MAY choose to copy the merchant name into the note.
- **FR-050**: Entry points: (a) a Home quick action "Bank message", gated by a compile-time feature flag in the style of the existing OCR flag, which opens the Bank messages screen on Android when the SMS capability is available and Paste otherwise (iOS, and Android builds without the capability); (b) a Home card showing only a count, and only while pending items exist (plus the FR-004 onboarding card); (c) Settings, "Bank messages", for permission state, the scan, muted senders, learned categories, the cash-withdrawal preference and the ignored list. There are no tab badges, and no raw message content is shown on Home.

#### Transaction mapping

The mapping below defines **suggested** defaults only; the user decides in review.

| SMS kind | Daftary record | Type / direction | Default suggestion |
|---|---|---|---|
| Card purchase, POS | Own expense (FinanceEntry) | Expense | Category from merchant rules or past choices, else "other" |
| ATM withdrawal | None by default | Ignore suggested | Ignore; when the preference "count cash withdrawals as spending" is on, Expense with "other" |
| Credit-card payment, installment debit or conversion notice, own-card or loan settlement | None | Ignore suggested | Ignore (spending counted elsewhere); the original purchase message is a card purchase; "N of M" text is not stored |
| Bill payment (electricity, water, phone, internet) | Own expense | Expense | Matching seeded category by keyword, else "other" |
| Bank fee or charge | Own expense | Expense | "other"; no new category is created; the user may pick any category and the learned mapping (FR-056) applies |
| Salary credit | Own income | Income | "salary" category |
| Other deposit or credit (including cash deposit) | None until chosen | No default type | User must choose Income or Ignore |
| Transfer or InstaPay out to a named counterparty | Own expense | Expense | Category "family" or "other"; Given suggested (one tap, person pre-selected) only when the name matches an existing person |
| Transfer or InstaPay in from a named counterparty | Own income | Income | Category "other_income"; Received suggested (one tap, person pre-selected) only when the name matches an existing person |
| Refund or reversal credit | None | Ignore suggested | Fixed hint (FR-024a); Income only if the user explicitly switches |
| Authorization reversal or cancellation (money that never posted) | None | Ignore suggested | Fixed hint (FR-024b); a matching saved record is shown with "Open it" |
| Fee stated inside another message | Own expense (separate item) | Expense | Its own pending item linked to the parent (FR-030a) |
| Own-account transfer, savings movement | None | Not income or expense | Ignore suggested (respects 022) |
| Non-transactional (OTP, promo, balance inquiry, declined) | None | n/a | Not imported |

- **FR-051**: The system MUST apply the mapping table as suggestions only and MUST NOT create any new transaction type, refund type, transfer type or debt type.
- **FR-051a**: ATM, refund or reversal, and own-account movements MUST default to Ignore suggested. A non-salary deposit MUST have no default type (the user chooses Income or Ignore). A named transfer MUST default to Expense or Income, with a one-tap Given or Received only on a person-name match. An ATM withdrawal becomes an Expense suggestion only when the FR-051b preference is on.
- **FR-051b**: The system MUST provide a user preference "count cash withdrawals as spending", off by default, located in Bank messages settings; when on, ATM withdrawals MUST be suggested as Expense instead of Ignore. An ATM item MUST show a one-line link to this preference.
- **FR-051c**: Own-account transfers MUST be suggested only from explicit message keywords (for example own account, between your accounts, card payment, savings); otherwise the transfer is a named transfer. There is no name-based self detection in v1.
- **FR-051d**: When a transfer-out and a transfer-in or deposit of the same amount and currency occur within one day of each other from different banks or channels (two pending items, or a pending item and an SMS-sourced saved record of the opposite direction group), the system MUST flag both as a possible move between the user's own accounts, suggest Ignore with a one-line hint, and never block either item.
- **FR-052**: Saving an import MUST be possible only through an explicit Add on one reviewed item, MUST be idempotent, and MUST produce the same audit and sync behavior as manual creation.
- **FR-053**: When a message states both an original-currency amount and a billed amount in the account currency, the billed amount is the default and the original amount is shown as read-only context in review (not stored); if undeterminable, the item is Low and the user picks. If only an original-currency amount is stated, it is saved in that currency when in the app's catalog (EGP, USD, EUR, SAR, AED, GBP), with no conversion or exchange rate. When the currency is outside the catalog, the amount also becomes incomplete: the user MUST choose a catalog currency and re-enter the amount, and the parsed number is never reinterpreted. When no currency is stated, a bank rule set supplies its account default (EGP for Egyptian banks), marked inferred; with the generic parser or paste/share, the currency stays empty and is required.
- **FR-054**: Person suggestions MUST use the existing name-based matching only; Given or Received MUST be suggested only when the counterparty name matches an existing person (one tap, person pre-selected, switching always available). The system MUST NOT create a person without explicit user confirmation, and MUST show the existing similar-name choice when more than one person could match.
- **FR-055**: Category suggestions MUST come from (a) the user's previous category choice for the same normalized merchant, then (b) built-in merchant keyword rules, then (c) "other". A normalized merchant is the merchant text after FR-037 normalization, lowercased, with digits and punctuation removed and whitespace collapsed; matching is exact. Seeded categories MUST be resolved by their stable key, an archived category MUST NEVER be suggested, the suggestion MUST be of the same type as the entry, and if no active category of the required type exists, no category MUST be selected and Add MUST stay disabled until the user chooses.
- **FR-056**: When the user saves an item with a category different from the suggestion, the system MUST remember the merchant-to-category mapping on the device and use it for later suggestions; the user MUST be able to view and clear learned mappings. Learned mappings are kept when the feature is disabled and removed by "Clear learned categories" or Delete all data.
- **FR-057**: Saved transactions that came from an SMS MUST be identifiable as such (for an "Imported from a bank message" label and for duplicate reasoning), and this provenance MUST be durable for the life of the saved record, independent of staging retention. The saved record MUST contain only user-confirmed fields.
- **FR-058**: The SMS time of day MAY be shown in review but only the local calendar day MUST be saved; the review MUST state this when time is displayed.

#### Duplicate detection

All tiers run on the device, offline.

| Tier | Condition | Behavior |
|---|---|---|
| Exact duplicate | Same message fingerprint (normalized body only, identical across scan, catch-up, paste and share), or same bank plus same reference ID plus same amount plus same direction | Silently collapsed: never a second pending item and never a second transaction |
| Probable duplicate | (1) An existing saved transaction of any source (manual, OCR, SMS; own money or people ledger) with same amount in integer minor units, same ISO currency, matching direction (expense equals given, income equals received) and date within one day, unless the existing record is SMS-sourced and both reference hashes are present and differ (FR-059a); or (2) another pending import with the same card last four, merchant and amount within 10 minutes, no reference ID, and a parsed time on both messages | Side-by-side warning; user chooses "It's the same, don't add" or "It's different, add anyway"; never blocks |
| Legitimately similar | Reference IDs both present and different (regardless of date), or same merchant and amount on dates more than one day apart | No warning |

There is no amount tolerance and no conversion between currencies. When a message states both a billed amount and an original-currency amount, the probable rule also compares the original amount and currency against saved records (a purchase the user typed in its original currency).

- **FR-059**: The system MUST implement the three tiers above, and the exact tier MUST ensure that re-processing a message never yields a second pending item or saved transaction, in addition to the existing idempotency guarantee at save.
- **FR-059a**: An added item's tombstone MUST keep the saved record ID, the bank identifier, a keyed hash of its reference ID, and a keyed hash of its reference ID with amount, currency and direction (both content-free), so that tier 2 and "same bank" can be evaluated. When the existing record is SMS-sourced and both reference hashes are present and differ, the system MUST show NO probable-duplicate warning. "Clearly different days" means dates more than one day apart.
- **FR-059b**: Duplicate evaluation MUST run in this order: (1) fingerprint match is exact; (2) same bank, same reference ID, same amount and same direction is exact, for banks whose reference IDs are unique per transaction (a bank rule-set property); for other banks it additionally requires a date within one day; (3) both reference hashes present and different is legitimately similar, and evaluation stops; (4) the probable rules. A reference ID alone MUST NOT collapse messages. When a reference ID is missing on either side, only the fingerprint and the probable rules apply.
- **FR-060**: The probable-duplicate check MUST run when review opens AND again on Add, using the current edited values; a match that first appears on Add MUST show the side-by-side choice before saving. It MUST compare against saved own-money and people-ledger records of any source, same currency only, and show the best-matching existing record (ranked by merchant or note similarity, then closest date) side by side with the pending item. It MUST be a new SMS-specific check spanning both record types, MUST NOT change the existing person-scoped check, and applies only to SMS import review in v1; manual and OCR forms are unchanged.
- **FR-061**: The "It's the same, don't add" choice MUST close the pending item as a duplicate (retaining only a fingerprint tombstone) and MUST NOT create or modify any transaction.
- **FR-062**: Message fingerprints and reference IDs MUST be stored only as keyed hashes (HMAC) using a single per-install secret held in secure storage, in local-only records, and MUST NOT be reversible to message content. If the key is lost (for example on reinstall or after a device restore, where the key is not restored), old tombstones stop matching; this is accepted.
- **FR-063**: The user MUST be able to override a probable-duplicate warning; the override MUST NOT be recorded as a failure.

#### Ignore and reject

Decision vocabulary: **Ignore** means "not a transaction I want recorded"; it keeps a tombstone and is undoable for 30 days. **"It's the same, don't add"** is a duplicate decision; it keeps a tombstone and is not in the Undo list. **"Stop suggesting from this sender"** is a mute rule, reversible from Settings. Delete is not a pending-import action.

- **FR-064**: The user MUST be able to Ignore a single pending item and to ignore a selection of items in one action after confirmation.
- **FR-065**: The user MUST be able to mark a sender "Stop suggesting from this sender"; such senders MUST produce no pending items and no stored content.
- **FR-066**: Tombstones for added, ignored, "same, don't add" and expired items MUST contain no raw text and MUST be kept at least 97 days (90-day maximum scan window plus 7), so that items do not resurface on re-scan.
- **FR-067**: The user MUST be able to view items ignored or expired in the last 30 days and undo the decision. The 30-day period applies only to the visibility of the Undo list, not to tombstone retention.
- **FR-068**: Undoing an ignore or an expiry MUST remove its tombstone; the message MUST return to pending only after a re-scan (Android) or a re-paste or share, since raw text was purged, and the UI MUST say so.

#### Permissions

- **FR-069**: The feature MUST request read-SMS only, and only after the explanation in FR-005; receive-SMS is never requested. Denial, permanent denial and revocation MUST be handled as distinct states.
- **FR-070**: A denied or revoked permission MUST yield a dedicated state with a path to system settings, following the existing permission precedent, and the app MUST detect revocation on resume.
- **FR-071**: *(retired; this feature requests no notification permission)*
- **FR-072**: On Android installs from outside an app store, where the operating system blocks the SMS permission grant until the user allows restricted settings, no public API reports the block. The enable flow MUST infer it (the request is denied with no system dialog shown, on a version that applies the restriction, for a non-store install), guide the user step by step, retry the grant, and still offer paste and share.
- **FR-073**: The only permission this feature may request is read-SMS (Android). It MUST NOT request receive-SMS, contacts, storage, notifications, battery-exemption, notification-listener or accessibility permissions.

#### Privacy and security

- **FR-074**: Raw SMS text MUST NOT appear in logs, sync payloads, backups (readable), CSV exports, analytics or diagnostics, AI requests, crash output or clipboard writes by the app.
- **FR-074a**: Raw SMS text MUST be encrypted at rest (AES-256-GCM) with a random per-install key held in the app's secure storage: on Android wrapped by a non-exportable Android Keystore key, on iOS a Keychain item with this-device-only accessibility, so no device or cloud backup can yield readable raw text. Raw text that cannot be decrypted (for example after a restore or reinstall) MUST be treated as purged, and "Show original" is then unavailable. Other staging data is ordinary local user data (FR-075).
- **FR-075**: Raw message text MUST be masked (FR-031a), retained only while the item is pending, and purged when the item is added, ignored, closed as a duplicate ("It's the same, don't add") or expired. Other staging data (parsed fields, hashed tombstones, sender mutes, learned merchant mappings) lives in the main local database like other user data and contains no raw text.
- **FR-075a**: Add MUST save the record and mark the pending item added (with its tombstone) in one local transaction, so a kill before commit leaves the item pending and a kill after it leaves it added. The idempotency key MUST derive from the pending import id, so a retry (including after a type switch) can never save a second record in the other table.
- **FR-076**: Pending imports, tombstones, sender rules and learned merchant mappings MUST be stored on the device only, MUST be included in "Delete all data", and MUST be excluded from CSV export.
- **FR-077**: The system MUST NOT store full card or account numbers, balances or OTPs, and MUST NOT display any of them beyond the last four digits.
- **FR-078**: Disabling the feature MUST stop scanning and catch-up immediately and MUST offer an option to delete all pending imports at the same time.
- **FR-079**: Screens showing pending imports or original messages MUST be covered by the existing screen-capture protection and App Lock behavior.
- **FR-080**: A share target or deep link MUST NOT expose message content to other apps.
- **FR-081**: The system MUST NOT send any SMS-derived data to the AI assistant in v1.

#### Offline behavior

- **FR-082**: Every capability in this feature (scan, catch-up, paste, share, parsing, review, duplicate checks, Add, Ignore) MUST work with no network connection.
- **FR-083**: Saving an import MUST use the existing local-first write path; syncing the saved record afterward MUST follow existing outbox behavior when connectivity and cloud sync are available.
- **FR-084**: Loss of connectivity during any step MUST NOT lose pending items or produce a partial save.

#### Sync behavior

- **FR-085**: Pending imports, tombstones, sender rules, learned merchant mappings and fingerprints MUST NOT sync to the cloud; only saved transactions sync, as they do today.
- **FR-086**: Provenance of saved imports MUST be synced in a new nullable optional field on both synced record types (MoneyTransaction and FinanceEntry; absent means not SMS), added by an additive server migration deployed after the pending 025 and 026 server migrations and before the app that writes it. It MUST NOT be a new value of any existing enumerated wire field. App versions v1.0.1 and later MUST keep pulling and pushing without error in any deployment order, and provenance MUST be durable for the life of the record (FR-057).
- **FR-087**: Because staging is device-local, the same message imported on two devices MUST be caught by the probable-duplicate check against synced transactions, and the product MUST NOT promise cross-device exact-duplicate prevention.
- **FR-088**: Synced SMS-provenance records MUST NOT carry any SMS-derived content beyond the user-confirmed fields.

#### Localization

- **FR-089**: All user-visible strings, including confidence labels, error messages and warnings, MUST be localized in Arabic and English with parity and MUST NOT be hardcoded.
- **FR-090**: Amounts and dates MUST be formatted per the active locale rules of the app (including Western digits displayed in Arabic, per the existing decision), and currency symbols MUST follow existing currency formatting.
- **FR-091**: Parsing MUST accept both Arabic and English templates for each supported bank regardless of the app language; the template language is matched per message, independent of the app locale, and a bank rule set may match an Arabic, English or mixed body. The message's original text MUST be displayed in its own direction (RTL or LTR) with correct bidirectional handling.
- **FR-092**: All new screens MUST render correctly in RTL and LTR, in light and dark themes, using existing design tokens.

#### Accessibility

- **FR-093**: Every interactive control and every confidence, warning and duplicate indicator MUST have a screen-reader label stating its meaning, and meaning MUST NOT be conveyed by color alone.
- **FR-094**: All touch targets MUST be at least 48dp and text MUST meet WCAG AA contrast in both themes.
- **FR-095**: Review MUST be fully operable with a screen reader and with large text scaling without clipping or overlapping.
- **FR-096**: Progress, completion, duplicate and error states MUST be announced to assistive technology.

#### Error handling

| Failure | User message intent | Recovery |
|---|---|---|
| Permission denied | Explain why it is needed and that nothing is lost | Paste/share fallback; open system settings |
| Permission permanently denied or blocked by the OS | Explain the OS restriction in plain words | Step-by-step guidance; paste/share fallback |
| Permission revoked while on | Say automatic import is off | Keep pending items; re-enable or paste/share |
| Message not recognized | Say it does not look like a supported bank message | Manual entry |
| Required field missing | Name the field that is missing | Edit field in review |
| Multiple amounts or ambiguous amount | Say which value needs checking | Review shows candidates; user picks |
| Unsupported currency | Ask which currency applies | Choose from catalog and re-enter amount |
| Clipboard empty or non-text | Say there is nothing to paste | Copy a message and retry, or paste into the text field |
| Original text unavailable | Say the original cannot be shown | Continue from the parsed fields |
| Save failed | Say it was not saved and the item is still pending | Retry; item remains pending; no duplicates |
| Scan interrupted | Say how many were processed | Resume or re-scan without duplicates |
| Database unavailable | Say the app could not store the item | Retry; no partial state |
| Parser failure on a single message | Say one message could not be read | Skip it, continue with others |

- **FR-097**: Failures MUST be handled as typed errors with user-facing messages that follow the table, and MUST NOT include message content, amounts or personal data in any log. A scan summary MUST show content-free counts (found, ready, needs review, skipped as non-transactional, unreadable); unreadable items are listed without raw text, and an unrecognized pasted message shows the not-recognized state with manual entry. There is no "report format" feature in v1.
- **FR-098**: One malformed or hostile message MUST NOT stop the processing of other messages and MUST NOT crash the app.
- **FR-099**: A failed Add MUST leave the pending item intact and MUST NOT leave a partially created record.

#### Analytics and diagnostics

- **FR-100**: No telemetry or crash reporting exists for this feature and none MUST be added. Server-side owner-scoped analytics views already exist over synced records; synced SMS-sourced records MUST add nothing to them beyond user-confirmed values and provenance.
- **FR-101**: Any local diagnostics MUST use only allow-listed, content-free fields (counts, rule-set versions, bank identifier, coarse failure category) and MUST NOT include raw text, amounts, merchants, names or account digits.
- **FR-102**: The system SHOULD provide on-device, user-visible, content-free counts (messages scanned, recognized, added, ignored) for the user's understanding and for QA.
- **FR-103**: If analytics is introduced in the future, it MUST be a separate opt-in decision and MUST follow FR-101.

### Key Entities

- **Pending SMS Import**: A staging suggestion derived from one message. Holds parsed fields, per-field and overall confidence (with read versus inferred markers), proposed type and category or person, warnings, duplicate findings, parser id and rule-set version, status (pending, added, ignored, duplicate, expired), creation time, and, only while pending, the masked, encrypted raw message text. Local-only. Never a transaction.
- **Bank Profile / Parser Rule Set**: The versioned recognition and parsing knowledge for one bank or channel (sender identifiers, content signatures, Arabic and English templates, kind classification, merchant keyword rules). Ships with the app; not user data.
- **Sender Rule (Mute)**: The user's decision to "Stop suggesting from this sender". Local-only.
- **Import Fingerprint / Tombstone**: A keyed hash (single per-install secret) of the normalized message body, plus the bank identifier, the reference-ID hash, the reference-plus-amount hash and, for added items, the saved record ID, kept after a decision or expiry so the same message never resurfaces. Contains no message content. Local-only, kept at least 97 days; the Undo list is visible for 30 days.
- **Merchant to Category Learned Mapping**: The user's remembered category for a normalized merchant name. Local-only, viewable and clearable.
- **MoneyTransaction (people ledger)**: Existing aggregate. Gains an optional provenance field (see Data Model Impact).
- **FinanceEntry (own income and expense)**: Existing aggregate. Gains an optional provenance field (see Data Model Impact).

## Data Model Impact

This section names existing domain concepts because the feature owner explicitly asked for data and architecture impact. It states what must change and the constraints, not class or schema designs.

- **New local-only staging records**: Pending SMS Imports, Import Fingerprints/Tombstones, Sender Rules and Merchant-to-Category Mappings MUST be added as local-only tables in the main local database and listed in the local-only classification. The existing guard test that forces every new table to be classified as synced or local-only MUST pass.
- **Delete-all-data**: The all-tables wipe MUST include every new table; its table-enumeration test MUST be extended accordingly. Export (CSV) MUST NOT include the new tables.
- **Provenance (both aggregates)**: Provenance MUST NOT be a new value of any existing enumerated wire field (`source`, `kind`, `direction`): the client sync mapper rejects unknown enumerated values, so v1.0.1 to 1.1.x devices would fail to pull in any deploy order, which 022 classes as P0. Provenance travels in a new nullable optional field on both synced tables that older clients ignore. The additive server migration replaces the push function based on the latest definition (026), adds the field to the money-transaction and finance-entry column lists, and deploys after 025/026 and before the app that writes it. MoneyTransaction's existing `source` keeps an existing value (`manual`) for SMS imports. Tests MUST prove that a v1.0.1 mapper pulls an SMS-sourced row without error, and that a v1.0.1 edit-and-push leaves the field intact.
- **FinanceEntry**: It has no source or provenance field today. The new provenance field MUST default to absent (not SMS) for all existing rows, be added by an additive local migration, and be synced per FR-086; it is durable for the life of the record.
- **Backups**: Raw text is encrypted with a this-device-only key that is not backed up (FR-074a); other staging data is ordinary user data in the main database and carries no raw text.
- **Idempotency**: Saving an import MUST use a client idempotency key derived from the pending import id, and the record save and the status update MUST commit in one local transaction (FR-075a).
- **Audit**: Saved imports MUST write the same audit rows as manual creation and MUST identify the source as SMS.
- **No change to money semantics**: Amounts remain integer minor units with ISO currency; dates remain date-only; no stored exchange rate; no new category or transaction types.
- **Retention rules**: Raw text exists only on pending items, masked and encrypted, purged on Add, Ignore, "It's the same, don't add" or 30-day expiry; tombstones keep hashes, the bank identifier and, for added items, the saved record ID, for at least 97 days.
- **Schema versioning**: Local schema changes MUST be additive migrations that preserve existing data.

## Architecture Impact

- **Layering**: SMS access (inbox query, share target) is a platform-boundary concern behind an interface; parsing, normalization, classification, confidence and duplicate logic are pure domain logic with no platform dependency, following the repository pattern (Principle VI) and typed Failure with Either results (Principle VII). No empty catch blocks. Review reuses the existing validators, pickers and confidence indicator rather than duplicating validation (FR-044).
- **State management**: Presentation state for the pending list, review and the paste screen uses the existing Cubit and Equatable state convention (Principle III). Dependency injection follows the existing convention.
- **Single review gate**: Following the OCR convention, a dedicated repository entry point creating SMS-sourced records MUST be callable only from the confirm use case, so the review gate exists in one place (supports FR-052).
- **Duplicate check**: A new SMS-specific duplicate use case queries both aggregates by amount, currency, direction group and date window (FR-060).
- **Entry points**: The only external entry today is notification-tap routing. This feature adds an Android text share target (a dedicated trampoline activity carrying the new intent filter; the main activity's launch mode is unchanged) and Home and Settings routes. There is no background receiver, no iOS extension, no app group and no new notification surface in v1.
- **Foreground-only work**: The scan and catch-up run in the foreground only, using the same ingestion pipeline (FR-008a, FR-013).
- **Feature flag**: The single build-time distribution switch of FR-001 gates the Android SMS capability, including its manifest permission.
- **Navigation**: A pending-imports area reachable from Settings and Home, via the existing router; the share route is added next to the existing routes.
- **Localization and design system**: New strings in both ARB files with feature-prefixed keys; design tokens and the existing confidence indicator style reused.
- **Sync**: Outbox, revision and conflict handling for saved records are unchanged. Provenance is added only as a new optional field (never a new value of an existing enumerated field), ignored by older clients (FR-086). Any server change MUST be additive and deployed before the app that depends on it, and a v1.0.1 mapper pull test is required.
- **Logging**: Only the existing allow-listed logging approach may be used; new log keys MUST be content-free (Principle XII).
- **Constitution**: Principle X names SMS as an uncertain input subject to the same confirm-before-persist rule (constitution v1.1.0, amended 2026-10-07). Principle XII (permissions) and the Financial Domain Override are cited by FR-002, FR-052, FR-069.
- **Platform policy impact**: See Risks; the build-time capability gate (FR-001) and the release gate (FR-003) are the architectural response.

## Testing Strategy

Following Principle XVI and the existing OCR parser tests as the template:

- **Golden SMS corpus**: A repository corpus of **anonymized, synthetic** messages (invented amounts, names, dates, card last-fours, reference IDs; no real customer message may be committed) covering each supported bank in Arabic and English, each transaction kind, and noise (OTP, promotions, declines). Each entry has an expected parse (fields, kind, classification, confidence band). Field-level accuracy on this corpus is a release gate (SC-001), and supported banks must never match each other's samples (FR-028).
- **Parsing per bank**: unit tests per bank and language for amount, currency, direction, kind, date, merchant, reference, last four.
- **Normalization**: Arabic-Indic digits, separators, currency words, dates (including Arabic month names, 2-digit years and year-less dates), 12/24-hour time, Arabic letter variants.
- **Malformed, unsupported and partial**: empty, truncated, mixed-language, huge, missing amount, missing date, ambiguous direction, multiple amounts, unknown currency, spoofed sender, unsupported bank.
- **Confidence calibration**: tests proving the fallback parser and paste/share never yield High, lowest-read-field capping, inferred-field cap at Medium, and that read versus inferred markers are set correctly.
- **Duplicates by tier**: exact (re-scan, re-paste, re-share, same reference; identical fingerprint across all paths; byte-identical bodies; fee SMS sharing a reference ID is not collapsed), probable (manual, OCR, SMS sources; own money and people ledger; edge of the one-day window; check re-run on Add with edited values), and legitimately similar (differing reference hashes with SMS-sourced existing record show no warning; dates more than one day apart).
- **Review actions**: edit, validate, add, double-tap add, kill-and-retry add (one record, atomic status), type switch on retry, ignore, batch ignore, undo ignore and undo expiry, mute sender, expiry after 30 days, no "add all" exists, review advances to the next item.
- **Mapping and preferences**: cash-withdrawal preference off and on, credit-card payment, installments, deposits, refunds (hint, no modification of saved records), named transfers with and without a person match, Repayment not offered, archived or missing categories (Add stays disabled).
- **Capability gating**: a build without the SMS capability has no SMS permission in its merged manifest and no SMS receiver; no build contains a receive-SMS permission or receiver.
- **Backups and encryption**: raw text is absent from device and cloud backup contents; after a simulated restore the raw text is undecryptable, treated as purged, and "Show original" is unavailable.
- **Android share target**: shows no parsed or raw content outside the app; the item appears only in the app behind App Lock.
- **Catch-up and restricted settings**: foreground catch-up after the app was closed or force-stopped yields no duplicates; no catch-up when off or revoked; restricted-settings inference and guidance flow.
- **Tombstones**: a 90-day re-scan after any add, ignore, duplicate decision or expiry resurfaces 0 items.
- **Never auto-create**: a test that exercises ingestion on every path and asserts zero saved transactions without a confirm action.
- **Analysis remediation (2026-10-07)**: golden fingerprints stay fixed across parser-rule changes; one message fingerprints identically through scan, catch-up, paste and share, including captured copy envelopes; an authorization reversal after an added purchase shows the hint and the matched record; an in-message fee yields a separate pending fee item; a cross-bank own-transfer pair is flagged; a purchase typed in its original currency triggers the probable warning; a year-less paste in early January resolves to the previous year; dates around DST transitions and time-zone changes stay on the stated day; dashboard income, expense and people totals are correct after adding each kind.
- **Permissions**: denial, permanent denial, revocation while the app is backgrounded, restricted-settings guidance, no prompt at startup, only read-SMS requested.
- **Android**: inbox scan with sender filtering in the query, duplicate delivery, catch-up on foreground, share target routing with App Lock.
- **iOS fallback**: paste only on tap (never on open or resume), empty clipboard state, text-field paste, multi-message split, not-recognized state.
- **Offline**: all flows with no network; save then sync later.
- **Sync**: saved SMS-sourced records sync; a v1.0.1 mapper pulls an SMS-sourced row without error; a v1.0.1 edit-and-push keeps the provenance field; staging records never in sync payloads; two-device probable-duplicate catch.
- **Localization and RTL**: ARB parity, RTL theme tests per new screen.
- **Dark mode and accessibility**: contrast, semantics labels, 48dp targets, large text, screen-reader flow of review.
- **Privacy leak tests**: assert that raw message text and parsed financial fields are absent from logs, sync payloads, CSV export, diagnostics and the saved record's note; assert purge on add, ignore, duplicate decision and expiry; assert masking of long digit runs; assert delete-all clears every new table.
- **Regression**: existing manual transaction form, finance entry form, OCR scan flow, duplicate-person check, export and delete-all remain unchanged in behavior.
- **Cubit, repository, mapper and use-case tests** per convention; widget tests for review, paste and permission states; integration tests for the critical flows in the journeys.
- **Performance**: scan of 500 messages measured on a mid-range device (SC-005).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the golden corpus, for each supported bank, at least 95% of extracted fields (amount, currency, direction, date) are correct, and 100% of non-transactional messages (OTP, promotions, declines) are not offered as normal transactions.
- **SC-002**: Across all automated and manual test runs, 0 transactions are saved without an explicit Add on that specific item.
- **SC-003**: Across all privacy tests, 0 bytes of readable raw message text appear in logs, sync payloads, CSV exports, diagnostics, backups or saved notes.
- **SC-004**: For a high-confidence pending item, the median time from opening review to a saved transaction is 10 seconds or less in Arabic-first usability testing with at least 8 participants.
- **SC-005**: A scan of 500 messages from recognized and unrecognized senders completes in 5 seconds or less on a reference device (4 GB RAM or less, released 2022 or later).
- **SC-006**: Importing the same message any number of times, by any mix of scan, catch-up, paste and share, creates 0 additional pending items and 0 additional transactions.
- **SC-007**: In seeded tests, 100% of messages matching an existing saved transaction on amount, currency, direction and a date within one day produce the probable-duplicate warning, except pairs whose reference IDs are both present and different, which produce 0% warnings regardless of date.
- **SC-008**: Every capability in FR-082 works with no network connection.
- **SC-009**: 100% of new screens pass contrast, 48dp target, screen-reader label and RTL checks in both themes and both languages.
- **SC-010**: At least 90% of participants (at least 8, Arabic-first) correctly describe, after first use, that nothing is saved until they tap Add.
- **SC-011**: Pending items older than 30 days are 100% purged, and "Delete all data" removes 100% of feature data.
- **SC-012**: Existing manual-entry, OCR, export and delete-all regression suites pass with no behavior changes.
- **SC-013**: 100% of SMS-sourced records have exactly one `created` audit entry and a non-null `import_source`.
- **SC-014**: A 90-day re-scan after any add, ignore, duplicate decision or expiry resurfaces 0 items.
- **SC-015**: At least 80% of usability participants (at least 8) on Android 15 complete the enable flow, including the restricted-settings step, within 2 minutes.

## Risks and Limitations

- **Play policy**: READ_SMS is a runtime "dangerous" permission. Google Play restricts it to default SMS handlers and a narrow list of approved exceptions (which includes an SMS-based money-management use case, but requires a permissions declaration, a demo and core-functionality approval). Approval is not assured. Daftary is distributed as a sideloaded signed APK; Play is not a v1 target. Mitigation: build-time capability gate, FR-003 and the paste/share fallback.
- **Sideload friction (re-verify on target versions)**: Android 15 enhanced confirmation blocks SMS permissions for apps installed from untrusted sources (such as a browser-downloaded GitHub release) until the user goes to App info, then the overflow menu, then "Allow restricted settings". Under sideloading this is the default path, not an edge case, and no public API reports the block, so the app infers it (FR-072).
- **Play Protect (release gate, FR-003)**: Google Play Protect enhanced fraud protection, in its pilot countries, blocks installing internet-sideloaded APKs that declare SMS permissions. If Egypt is covered, adding SMS to the only APK would block installs and updates for all users; the fallback is two APKs.
- **Developer verification (verify during planning)**: Google's Android developer verification for sideloaded apps on certified devices (2026-27) requires registering the signing identity.
- **RCS/RBM (verify during planning)**: Bank messages sent over RCS or RBM are not readable through SMS permissions.
- **Backups and key loss**: Android Auto Backup and iOS backups include the app's data, but the this-device-only key is not restored, so raw text (and the tombstone hashing key) is lost after a restore or reinstall. Raw text is then treated as purged and old tombstones may stop matching; this is accepted (FR-062, FR-074a).
- **iOS limits**: No inbox access is possible; the experience depends on the user pasting. A programmatic clipboard read can show the system paste prompt or return empty; pasting into the text field avoids the prompt. Messages offers Copy, Reply and Forward on a bubble but no Share sheet, and copies one bubble at a time, so multi-message paste is mostly an Android and Notes case. Re-verify on target iOS versions during planning.
- **No live detection**: New messages are found only when the app is opened or a scan or paste is run; the user sees them later than with a live feature (NG10).
- **Bank format drift**: Banks change SMS templates without notice; accuracy will decay. Mitigation: versioned rules, fallback parser, in-app "could not read" path, and ability to ship rule updates.
- **Arabic variance**: Dialect, spelling, transliterated merchants, and mixed scripts reduce parse and category accuracy.
- **Date-only model**: The time of day is lost on save.
- **Unencrypted database**: The local database is not encrypted and relies on the OS sandbox; parsed fields in it are no more sensitive than saved transactions, and raw message text is encrypted separately (FR-074a).
- **Multi-device double import**: Staging is not synced, so exact-duplicate prevention does not span devices; only the probable-duplicate check helps. Byte-identical bodies also collapse as exact duplicates (accepted limitation).
- **Over-trust**: Users may habituate to tapping Add without reading; mitigated by the per-item confirm, confidence cues and no "add all".
- **Spoofed senders**: an alphanumeric sender ID can be spoofed, so a fake message that matches a bank signature can produce a High-confidence pending item. It is never saved without review; accepted.
- **Share injection**: any app can share text to Daftary; such text is capped at Medium confidence and gated by review; accepted.
- **Duplicate warning fatigue**: common round amounts match often; mitigated by ranking the best match and by measuring the false-positive rate on a synthetic ledger.
- **Own-transfer detection is heuristic**: the cross-bank pair rule (FR-051d) catches same-amount moves within one day only; other own transfers rely on keywords or the user's choice.
- **Merchant categorization**: Keyword rules and learned mappings will be wrong sometimes; the category is always editable.

## Assumptions

- Android users who value this feature accept the sideload distribution (FR-003); paste and share cover builds and users without SMS access.
- "Never auto-create, no bulk add in v1" is chosen because a single wrong financial record erodes trust more than extra taps; batch ignore is safe because it creates nothing.
- Defaults (30-day scan window, 90-day maximum, 30-day pending expiry, 30-day Undo list visibility, 97-day tombstone retention) balance usefulness and minimal retention and may be tuned later.
- The date-only model is retained; adding time-of-day is out of scope.
- Parser rules are delivered with the app release; remote rule updates are out of scope for v1 and would need their own privacy review.
- Occasion contributions are excluded from v1 because they depend on occasion context an SMS cannot supply, and kind cannot be changed after saving. Repayment is not offered in review by default (OQ1).
- Mobile-wallet SMS (for example Vodafone Cash) is out of v1 by default (OQ4).
- The existing name-only person matching is sufficient for suggestions; phone-based matching is out of scope.
- The existing screen-capture protection and App Lock apply unchanged; no notification, notification permission or quiet-hours behavior is involved in v1.
- Existing OCR confidence presentation is reused for visual consistency.
- Decisions taken by default in the clarification pass:
  - Review is a dedicated screen, not the manual forms (FR-044); there is no separate import history (FR-043).
  - Bank fee SMS default to "other" with no new category; learned mappings apply (mapping table).
  - Refund or reversal credits get Ignore plus a fixed hint, with no matching query or record changes (FR-024a).
  - Parser precedence is bank match, then content-only match, then generic, with fixed registry order on ties and no field merging (FR-028).
  - Confidence uses read (Low, Medium, High) or inferred (no level); overall is the lowest read level, capped at Medium for inferred fields, the generic parser and paste/share; Low and Medium never block Add; no amount means no pending item (FR-039, FR-039a, FR-042).
  - Duplicate rules: exact amounts only, same currency only, evaluated in a fixed order, and a reference ID alone never collapses messages (FR-059b); the 10-minute pending-pair rule needs a parsed time on both.
  - Entry points are a Home quick action, a Home count card and a Settings entry, with no tab badges (FR-050).
  - Items are added one at a time and review advances to the next; multi-select is for Ignore only (FR-046).
  - Expired items are restorable for 30 days like ignored ones (FR-067).
  - Foreign-currency messages default to the billed account-currency amount, with no conversion; an out-of-catalog currency requires re-entry; no stated currency is supplied by the bank rule set, else required (FR-053).
  - Own-account transfers are detected only from explicit keywords (FR-051c).
  - Dates: year-less dates follow the received year (or the previous year if in the future); day-month order is assumed by the generic parser; paste and share without a date leave Date empty (FR-036, FR-038).
  - Template language is matched per message, not by app locale (FR-091); a normalized merchant is lowercased, digit- and punctuation-free text, matched exactly (FR-055).
  - Raw text is masked for digit runs of 12 or more before persistence (FR-031a); tombstones keep the bank identifier (FR-059a).
  - Ambiguous movements follow the mapping table: ATM, refund and own-account are Ignore; non-salary deposits have no default type; named transfers are Expense or Income with an optional one-tap Given or Received; ATM becomes Expense only with the preference (FR-051a, FR-051b).
  - Learned mappings are kept when the feature is disabled (FR-056); there is no "report unsupported format" feature in v1 (FR-097); paste and share are in every build (FR-001, FR-011).
  - Scan window options (7, 30, 90), pending expiry (30 days) and Undo window (30 days) are settled by the current requirements; no notification is shown for imports.
  - The Principle X amendment naming SMS was applied on 2026-10-07 (constitution v1.1.0).

## Open Questions

Each item below is implemented by its recommended default; answering differently changes only the stated impact.

### OQ1. Offer Repayment in review?

- **Question**: Should the review let the user switch an item to Repayment, or only to Given or Received?
- **Why it matters**: Repayment adds a balance-dependent state to review for a label-only gain, since a person's net balance is the same either way.
- **Recommended default**: Given or Received only in v1; a repayment is entered through the existing manual form (FR-048, NG8, FR-043a, mapping table).
- **Alternatives**: Offer Repayment when the selected person has a balance in the matching direction, with the direction derived by the existing repayment rules.
- **Impact**: FR-043, FR-043a, FR-048, NG8, the edge cases and the mapping and review tests would need to add Repayment back.

### OQ2. Real anonymized sample SMS and sender IDs per bank (user-held prerequisite)

- **Question**: Who supplies real-format sample messages and the sender IDs for each v1 bank, anonymized for the corpus?
- **Why it matters**: The golden corpus (SC-001) and the recognized sender list (FR-020, FR-029) cannot be completed without them; the plan cannot finish and no bank can pass the accuracy gate.
- **Recommended default**: The product owner provides anonymized samples and sender IDs per bank before planning completes; no real message is committed to the repository.
- **Alternatives**: Ship only the banks for which samples exist, with the generic parser for the rest.
- **Impact**: The v1 bank list (OQ3), SC-001 and the parser work schedule.

### OQ3. Confirm the initial bank list

- **Question**: Is the v1 set NBE, Banque Misr, CIB, QNB Alahli, Banque du Caire, AAIB and InstaPay right?
- **Why it matters**: It sets the corpus size and the rule sets to build.
- **Recommended default**: This set, with each bank accepted only when it meets the corpus gate (FR-029).
- **Alternatives**: A smaller launch set (for example the three banks the owner uses), or additional banks.
- **Impact**: FR-029, the corpus and per-bank tests.

### OQ4. Mobile-wallet SMS (Vodafone Cash, Orange Cash, Etisalat Cash, telecom wallets)

- **Question**: Are wallet SMS in or out of v1?
- **Why it matters**: Wallet messages use different templates and senders and may involve balances and fees not modeled in v1.
- **Recommended default**: Out of v1 (NG9); the generic parser may still read them at lower confidence when pasted.
- **Alternatives**: Include one or more wallets as supported senders in v1.
- **Impact**: FR-029, the sender list, the corpus and the mapping table.

### OQ5. Does Play Protect enhanced fraud protection cover Egypt? (release gate)

- **Question**: Does Play Protect block installing or updating an internet-sideloaded APK that declares SMS permissions on devices in Egypt?
- **Why it matters**: If it does, adding SMS to the only release APK would block installs and updates for all users.
- **Recommended default**: Assume it may; verify on real devices before release (FR-003).
- **Alternatives**: If the check fails, ship two APKs (a standard SMS-free one and a "with bank SMS" one); or drop Android SMS reading in v1 and keep paste and share only.
- **Impact**: FR-003, the release pipeline and the Android test matrix.

### OQ6. Android 15 restricted-settings flow on real devices (release gate)

- **Question**: Does the inferred restricted-settings guidance work on target Android 13 to 16 devices for a GitHub-release install?
- **Why it matters**: Under sideloading it is the default path and gates SC-015.
- **Recommended default**: Ship the inference and step-by-step guidance (FR-072) and verify on real devices before release.
- **Alternatives**: Provide only static written instructions without an in-app check.
- **Impact**: FR-072, US2 scenario 6 and SC-015.

### OQ7. Probable-duplicate windows

- **Question**: Are plus or minus one day (saved records) and 10 minutes (pending pairs by card and merchant) the right windows for banks that post next-day?
- **Why it matters**: Too narrow misses real duplicates; too wide warns on legitimate purchases.
- **Recommended default**: One day and 10 minutes (the duplicate table).
- **Alternatives**: Two days for known next-day-posting banks; a longer pending-pair window.
- **Impact**: The duplicate table, SC-007 and the duplicate tests.
