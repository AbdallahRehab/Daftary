# Quickstart: Validate Money Relationships Tracking

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.38 stable / Dart 3.10 SDK installed (`flutter --version` to confirm).
- Dependencies installed and code generated once the tasks phase has added them to `pubspec.yaml`:
  ```bash
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs   # drift + injectable codegen
  ```
- An Android emulator/device or iOS simulator/device attached (`flutter devices`).

## Run the app

```bash
flutter run
```

The local SQLite database is created automatically on first launch in the app's document directory — no setup, seed data, or network configuration needed (feature is local-only, per spec Clarifications).

## Automated verification

```bash
flutter analyze                # static analysis gate (constitution: must be clean)
flutter test                   # unit + Cubit + widget tests
flutter test integration_test  # end-to-end flows (requires a running device/emulator)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use them as a scripted smoke test after implementation.

### 1. Record a transaction (User Story 1, spec Acceptance Scenarios 1-5)
1. Open the app with no people saved. Start "Record transaction," type a new name (e.g. "Ahmed"), enter amount `2000`, direction "received." Save.
   - **Expect**: a new Person "Ahmed" is created and the transaction appears against him.
2. Record that you gave Ahmed `500` EGP.
   - **Expect**: Ahmed's balance updates immediately to reflect both transactions.
3. Try to save an amount of `0` or `-100`.
   - **Expect**: save is rejected with an explanation; no transaction is created.
4. Turn on airplane mode, record a transaction.
   - **Expect**: it saves instantly and durably on-device, without blocking the UI — this feature has no network dependency, so there is no separate "synced" state to reach (FR-021).

### 2. View balance and history (User Story 2)
1. Open Ahmed's profile.
   - **Expect**: "Ahmed owes you 1,500 EGP" and both transactions listed chronologically.
2. Record 50+ transactions against one test person, then reconcile by hand.
   - **Expect**: displayed balance exactly matches the manual sum (SC-002) — zero discrepancy.

### 3. Repayment (User Story 3)
1. With Ahmed owing 1,500 EGP, record a 500 EGP repayment.
   - **Expect**: outstanding balance becomes 1,000 EGP; the entry is visibly distinct from a regular "received" transaction.
2. Record a 1,500 EGP repayment on a fresh 1,500-owed person.
   - **Expect**: status becomes "Settled."
3. On a person owed 500 EGP, record a 700 EGP repayment.
   - **Expect**: accepted; balance flips to "you owe them 200 EGP."

### 4. Overview (User Story 4)
1. Create several people with a mix of owing/owed/settled balances, including one person you then archive while they still have a non-zero balance.
   - **Expect**: the overview totals include the archived person's balance (per the spec's Clarifications) until it reaches zero.
2. Edit any transaction, return to the overview.
   - **Expect**: totals update immediately.
3. Settle every balance to zero, reopen the overview.
   - **Expect**: a clear "everything settled" state, not an empty/confusing screen.

### 5. Manage people (User Story 5)
1. Create a person with just a name.
2. Edit their phone/relationship tag/notes.
3. Attempt to permanently delete a person who has transactions.
   - **Expect**: blocked, with an offer to archive instead.
4. Archive them, then find them via the archived-people view and confirm full history is intact.

### 6. Correct/remove a transaction (User Story 6)
1. Edit a transaction's amount.
   - **Expect**: the person's balance recalculates immediately and the transaction shows an "edited" marker.
2. Delete a transaction.
   - **Expect**: an explicit "cannot be undone" confirmation appears before it is removed; the person's balance and the overview update afterward.
3. Rapidly double-tap "Save" on a new transaction, or force-quit and relaunch mid-save and retry.
   - **Expect**: exactly one transaction is created (FR-020/SC-006) — check the person's history for duplicates.

### 7. Localization and numerals (FR-022, FR-023)
1. Switch the device/app language to Arabic.
   - **Expect**: full RTL layout, no mistranslated/hardcoded English strings.
2. Enter an amount using Arabic-Indic digits (e.g. ١٥٠٫٥٠).
   - **Expect**: interpreted identically to `150.50` entered in Western digits.
