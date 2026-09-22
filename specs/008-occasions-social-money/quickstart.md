# Quickstart: Validate Occasions / Social Money

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Dependencies installed and code regenerated once the migration/new DI registrations and the new `image_picker`-class dependency land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # drift + injectable codegen
  ```
- An Android emulator/device or iOS simulator/device attached (`fvm flutter devices`), with camera/gallery access available for the attachment scenario.
- An existing install with People/Transactions data already present is the most representative test case — confirms the additive migration (new tables + new `MoneyTransactions` columns) runs cleanly against a non-empty database and existing balances are unaffected.

## Run the app

```bash
fvm flutter run
```

On first launch after this feature ships, the migration creates `Occasions`/`OccasionAttachments` and adds the two new columns to `MoneyTransactions` automatically — no manual setup, seed script, or network configuration needed (feature is local-only).

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Create an occasion and record participants (User Story 1)
1. Create occasion "Ahmed's Wedding," date 15 Sep 2026, type "Wedding."
   - **Expect**: saved, appears in the occasions list.
2. Add four participants received: Ahmed 2,000 EGP, Mohamed 1,000 EGP, Mahmoud 500 EGP, Omar 1,500 EGP (creating any new people inline).
   - **Expect**: each contribution saves immediately; occasion total received updates to 5,000 EGP after the last one.
3. Try to save a participant contribution with amount `0`.
   - **Expect**: blocked with a clear message.
4. Try to save the occasion with no type chosen.
   - **Expect**: blocked until a type is selected or a custom one entered.

### 2. Contribution appears in the person's own history (User Story 2)
1. From "Ahmed's Wedding," open Ahmed's contribution, then navigate to Ahmed's own person profile.
   - **Expect**: the 2,000 EGP entry appears in Ahmed's transaction history, labeled "Ahmed's Wedding," and is included in his net balance exactly once.
2. Edit the amount to 2,200 EGP from Ahmed's profile screen directly (not from the occasion).
   - **Expect**: reopening the occasion shows 2,200 EGP for Ahmed and the occasion's total received recalculates to 5,200 EGP — same underlying row, both views agree.
3. Remove Ahmed's contribution from the occasion.
   - **Expect**: it disappears from both the occasion and Ahmed's profile; Ahmed's balance recalculates accordingly.

### 3. Occasion totals and settlement (User Story 3)
1. Create "Fatma's Wedding" with money given to Ahmed (1,000), Mohamed (500), Omar (2,000); no received entries.
   - **Expect**: total given 3,500 EGP, total received 0 EGP, labeled with the outstanding "given" direction (not "Settled").
2. Add a received contribution of 3,500 EGP from a fifth person.
   - **Expect**: occasion becomes "Settled."
3. Open a participant row inside any occasion for a person who also has unrelated direct transactions with a different net balance.
   - **Expect**: their row shows their true overall status (they owe you / you owe them / settled), not an occasion-only figure.

### 4. Browse, filter, archive (User Story 4)
1. Create occasions of several types across different dates; open the occasions list.
   - **Expect**: shown most-recent-first.
2. Filter by type "wedding."
   - **Expect**: only weddings shown.
3. Archive one occasion.
   - **Expect**: disappears from the default list, still viewable and editable under "archived occasions," participant balances unaffected.
4. With zero occasions ever created (fresh install), open the occasions section.
   - **Expect**: friendly empty state with a direct "create your first occasion" action.

### 5. Attachments (User Story 5)
1. From an existing occasion, attach a photo from the gallery.
   - **Expect**: saved and shown in the occasion's details.
2. Remove the attachment.
   - **Expect**: deleted after a confirmation step.
3. Deny camera/gallery permission when prompted.
   - **Expect**: a clear explanation is shown; the app does not crash and the occasion remains usable without the photo.

### 6. Deletion cascade (Edge Cases, FR-013)
1. Create an occasion with 5 participant contributions, then delete the occasion.
   - **Expect**: confirmation names "5 participants" before deleting; after confirming, the occasion is gone and all 5 corresponding entries are gone from the affected people's histories/balances — verify at least one affected person's profile directly.

### 7. Condolence balance default (Edge Cases, FR-018)
1. Create a condolence-type occasion and add a received contribution from a person with no other transactions.
   - **Expect**: the occasion shows the contribution and its total correctly, but that person's overall balance/status remains "Settled" (the contribution does not count toward it) unless the user explicitly overrode the toggle at entry time.

### 8. Localization and theming (FR-022)
1. Switch the app language to Arabic, then reopen an occasion with mixed Arabic/English participant names and amounts.
   - **Expect**: RTL layout, correct numeral/date formatting, no truncation.
2. Switch between light and dark mode on the occasion detail and list screens.
   - **Expect**: settlement badges, type chips, and totals remain legible and correctly themed.
