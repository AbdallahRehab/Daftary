# Quickstart: Validate Home Dashboard

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Feature 007 (Income & Expense Tracking) implemented first — this feature has a hard dependency on its `GetFinanceSummary`/`GetFinanceHistory` use cases existing and being registered in DI.
- Dependencies installed and code regenerated once the new `dashboard` feature's DI registrations land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # injectable codegen only — no drift schema change
  ```
- An Android emulator/device or iOS simulator/device attached (`fvm flutter devices`).
- An existing install with People/Transactions/Finance data already present is the most representative test case; also test a truly brand-new install (combined empty state, FR-005).

## Run the app

```bash
fvm flutter run
```

No migration runs for this feature — the bottom-nav "Overview" tab simply becomes "Home" and shows the extended screen on next launch.

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests
fvm flutter test integration_test  # end-to-end flow (requires a running device/emulator)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Complete financial picture at a glance (User Story 1)

1. With existing person balances and this-month finance entries recorded, open the Home tab.
   - **Expect**: owed-to-me, owed-by-me, this-month income, this-month expenses, and net all visible together within ~1 second, no extra navigation.
2. Pull to refresh.
   - **Expect**: both figures re-fetch and update together.
3. On a brand-new install with zero people and zero finance entries ever recorded, open Home.
   - **Expect**: one single combined empty state (not two separate ones), explaining the app and offering a way to get started.

### 2. Quick actions (User Story 2)

1. Tap "Add Expense."
   - **Expect**: the existing finance entry form opens, defaulted to expense.
2. Tap "Add Income."
   - **Expect**: the existing finance entry form opens, defaulted to income.
3. Tap "Add Person," then "Add Money Received," then "Add Money Given."
   - **Expect**: each opens its existing, unmodified form.
4. Complete any quick action and return to Home.
   - **Expect**: the financial snapshot reflects the change without a manual refresh.
5. Look at the quick-action row.
   - **Expect**: Add Occasion / Scan Paper are either absent or visibly disabled — never a dead tap target.
6. Rapidly double-tap a quick action.
   - **Expect**: only one navigation occurs.

### 3. Honest placeholders (User Story 3)

1. View the Insights section on a fresh install (no AI Assistant feature exists yet).
   - **Expect**: "insights arrive once the AI Assistant is set up" — never an invented tip.
2. View the Upcoming section (no Budgets/Savings feature exists yet).
   - **Expect**: an honest explanation, distinct in wording from the Financial Snapshot's balance totals (no duplication).

### 4. Partial-failure resilience (User Story 4)

1. Simulate the finance summary failing to load while balance totals succeed (e.g. a faked repository failure in a test harness, or a real device with a corrupted finance query for manual QA).
   - **Expect**: balance totals render normally; the finance card shows an inline error + retry, rest of screen unaffected.
2. Simulate the reverse (balance totals fail, finance summary succeeds).
   - **Expect**: finance summary renders normally; the balance card shows an inline error + retry, rest of screen unaffected.
3. Tap retry on a failed card.
   - **Expect**: only that card's data re-fetches; on success it replaces the error state cleanly.
4. Simulate both failing.
   - **Expect**: one full-screen error state with a single retry that re-attempts both.

### 5. Localization, RTL, and theme

1. Switch the app language to Arabic.
   - **Expect**: full RTL layout on the Home screen — card order, quick-action row, and number/currency formatting all mirror correctly; no hardcoded English strings.
2. Switch between light and dark mode with the snapshot populated.
   - **Expect**: all cards, quick-action icons, and status colors remain legible and correctly themed; income/expense/owed distinctions are never color-only.

### 6. Isolation from underlying calculations (FR-016)

1. Note the balance totals and finance summary shown on Home.
2. Open the existing People/Transactions Overview-equivalent data and the Finance history/summary screens directly.
   - **Expect**: the figures match exactly — Home never computes or displays a different number than the features that own that data.
