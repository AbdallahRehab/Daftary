# Quickstart: Validate Reports & Data/Privacy Controls

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Feature 007 (Income & Expense Tracking) implemented first — this feature has a hard dependency on its `GetSummary`/`GetCategoryBreakdown`/`getHistory` use cases existing and being registered in DI.
- Dependencies installed and code regenerated once `share_plus` and this feature's DI registrations land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # injectable codegen only — no drift schema change
  ```
- An Android emulator/device or iOS simulator/device attached (`fvm flutter devices`) — the OS share sheet only meaningfully exercises on a real device/simulator, not a headless test runner.
- An existing install with People/Transactions/Finance data spanning several months is the most representative test case for Reports and Export; also test a truly brand-new install (empty states) and a populated one specifically for the Delete flow (destructive — use a disposable test install/emulator).

## Run the app

```bash
fvm flutter run
```

No migration runs for this feature — no schema change.

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests, including the real-transaction
                                    # drift atomicity test for DeleteAllUserData
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Spending and income trends (User Story 1)

1. With income/expense entries recorded across several past months and categories, open Reports (from Home/Finance).
   - **Expect**: a monthly trend across recent months and a category breakdown for the current period, both matching a manual sum from the underlying entries.
2. Change the breakdown's selected period.
   - **Expect**: the breakdown updates; the trend keeps showing the recent-months overview unchanged.
3. On a fresh install with zero finance entries, open Reports.
   - **Expect**: a clear empty state with a direct path to add the first entry.
4. Simulate a data-load failure.
   - **Expect**: a clear error state with retry, never a blank/stuck screen.
5. Switch to Arabic/RTL and dark mode while viewing a chart.
   - **Expect**: axis direction, legend position, and all labels mirror/theme correctly.

### 2. Export a complete copy of my data (User Story 2)

1. Open Data Export (from Settings or Reports' shortcut) and generate an export with a mix of people/transactions/entries/categories already recorded.
   - **Expect**: an in-progress indicator, then a completed file offered via the OS share sheet.
2. Open the generated CSV in a text editor.
   - **Expect**: section markers for People, Transactions, Finance Entries, Categories, Settings, each with a header row and correct data rows matching what's in the app (SC-003).
3. Cancel the OS share sheet instead of completing a share.
   - **Expect**: the export screen returns to its ready-to-share state (the file still exists), not an error.
4. Force an export failure (e.g. simulate a repository error).
   - **Expect**: a friendly error message and a retry option; no confusing partial file.
5. On a brand-new install with zero data, request an export.
   - **Expect**: a valid file with empty sections, not an error.

### 3. Permanently delete all my data (User Story 3) — use a disposable test install

1. With a full set of data recorded, open "Delete My Data" in Settings.
   - **Expect**: a clear, unambiguous permanent/irreversible warning.
2. Try to confirm without typing the required phrase.
   - **Expect**: the destructive button stays disabled.
3. Type the exact required phrase, then tap the now-enabled delete button.
   - **Expect**: a short in-progress indicator, then every person/transaction/entry/category/setting is gone and the app shows the onboarding flow, exactly like a fresh install.
4. Force a failure partway through deletion (test harness only — e.g. a faked constraint violation).
   - **Expect**: zero data loss — every table exactly as it was before the attempt.
5. Rapidly double-tap the delete button.
   - **Expect**: only one deletion operation executes.
6. Open the confirmation screen and back out without confirming.
   - **Expect**: no data affected at all.

### 4. Cross-cutting

1. Confirm Reports/Export/Delete all function correctly with the device in airplane mode (FR-022) — only the final OS share-sheet destination choice may require connectivity, never the app's own generation/deletion logic.
2. Confirm no hardcoded English strings anywhere on the Reports/Export/Delete screens when the device language is Arabic.
