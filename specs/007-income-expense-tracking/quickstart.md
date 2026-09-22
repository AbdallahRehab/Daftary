# Quickstart: Validate Income & Expense Tracking

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Dependencies installed and code regenerated once the v5 migration/new DI registrations land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # drift + injectable codegen
  ```
- An Android emulator/device or iOS simulator/device attached (`fvm flutter devices`).
- An existing install with People/Transactions data already present is the most representative test case — confirms the v4→v5 migration and default-category seeding both run cleanly against a non-empty database.

## Run the app

```bash
fvm flutter run
```

On first launch after this feature ships, the v5 migration creates `FinanceCategories`/`FinanceEntries` and seeds the default categories automatically — no manual setup, seed script, or network configuration needed (feature is local-only).

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Record an expense (User Story 1)
1. Open the finance section for the first time. Add a new expense: amount `250.50`, category "Groceries," today's date.
   - **Expect**: saved instantly, appears at the top of history, correctly formatted as an expense.
2. Try to save with the amount empty, then with amount `0`.
   - **Expect**: blocked both times with a clear message; nothing entered is lost.
3. Try to save with no category selected.
   - **Expect**: blocked until a category is picked.
4. Leave the date untouched, then change it to a date next week.
   - **Expect**: defaults to today; accepts the future date without error.

### 2. Record income (User Story 2)
1. Add an income entry: amount `15000`, category "Salary."
   - **Expect**: appears in history and totals, visually distinct from expense entries (color/icon/sign).
2. View the combined history with both types present.
   - **Expect**: income and expense are never visually ambiguous at a glance.

### 3. History and totals (User Story 3)
1. With a mix of income/expense entries across several categories and dates, open the summary view for "this month."
   - **Expect**: total income, total expenses, and net are all correct and match a manual sum.
2. View the category breakdown.
   - **Expect**: ordered largest to smallest, each showing its share of the period.
3. Switch to "last month," then a custom range spanning zero entries.
   - **Expect**: totals/history update each time; the zero-entry custom range shows the "no matching results" state, not the true first-use empty state.
4. Filter history by category and by type.
   - **Expect**: only matching entries shown.
5. On a brand-new install with zero entries, open the summary.
   - **Expect**: the true first-use empty state, explaining the feature with a direct "add your first entry" action.

### 4. Manage categories (User Story 4)
1. Open category management on first use.
   - **Expect**: the full default set (16 expense + 6 income categories) already present.
2. Create a custom expense category "Gym," pick an icon.
   - **Expect**: immediately selectable when adding a new expense.
3. Try creating another category named "gym" (different case/spacing) of the same type.
   - **Expect**: blocked, pointed at the existing "Gym" category.
4. Rename "Gym" to "Fitness."
   - **Expect**: every past entry using it now shows "Fitness."
5. Use "Fitness" on at least one entry, then remove it.
   - **Expect**: archived (not deleted) — disappears from the entry-creation picker, but the entry that used it still displays it correctly, and it remains editable on that entry.
6. Create a brand-new category, never use it on any entry, then remove it.
   - **Expect**: deleted outright, no longer visible anywhere.

### 5. Edit/delete with undo (User Story 5)
1. Edit an existing entry's amount and category.
   - **Expect**: totals/breakdown recalculate immediately; entry shows an "edited" marker.
2. Delete an entry.
   - **Expect**: a confirmation prompt appears first; after confirming, an undo affordance is shown for a few seconds.
3. Tap undo within the window.
   - **Expect**: the entry reappears in history/totals exactly as it was.
4. Delete another entry and let the undo window expire without tapping it.
   - **Expect**: it stays removed from history/totals.
5. Rapidly double-tap "Save" on a new entry.
   - **Expect**: exactly one entry is created (FR-021) — check history for duplicates.

### 6. Isolation from existing Transactions (FR-023)
1. Note a person's current balance in the existing People/Transactions feature.
2. Add, edit, and delete several finance entries.
   - **Expect**: that person's balance and the Overview tab's totals are completely unaffected — finance entries never appear in Transactions or vice versa.

### 7. Localization, RTL, and theme (FR-024)
1. Switch the app language to Arabic.
   - **Expect**: full RTL layout on every finance screen; default category names, icons, and number/date formatting all correct; no hardcoded English strings.
2. Enter an amount using Arabic-Indic digits.
   - **Expect**: interpreted identically to the same value in Western digits.
3. Switch between light and dark mode with entries/categories visible.
   - **Expect**: income/expense color-coding and category chips remain legible and correctly themed in both modes.
