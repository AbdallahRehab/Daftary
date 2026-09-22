# Quickstart: Validate Household Budgets

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Dependencies installed and code regenerated once the migration/new DI registrations and the new `fl_chart` dependency land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # drift + injectable codegen
  ```
- An Android emulator/device or iOS simulator/device attached (`fvm flutter devices`).
- An existing install with 007 (Income & Expense) data already present, including at least a few expense categories with recorded entries across 2-3 different months — the most representative test case, since this feature is entirely read-driven off that data.

## Run the app

```bash
fvm flutter run
```

On first launch after this feature ships, the migration creates `Budgets`/`BudgetCategoryAllocations` automatically — no manual setup, seed data, or network configuration needed (feature is local-only and adds zero changes to any existing table).

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Create a budget (User Story 1)
1. Open budgets for the current month with none yet; create one, allocate Rent 7,000, Food 6,000, Transportation 3,000 (from existing 007 categories), set expected income to 30,000.
   - **Expect**: saved; each category shows its planned amount.
2. Try to allocate a negative amount.
   - **Expect**: blocked with a clear message.
3. Allocate enough categories that the total exceeds the expected income.
   - **Expect**: an "exceeds income" indication shown, save still succeeds.
4. Create a new expense category inline from the allocation picker.
   - **Expect**: immediately usable, consistent with 007's category flow.

### 2. Planned vs. actual (User Story 2)
1. With the budget from scenario 1 saved, record (007) a 3,500 EGP Food expense this month.
   - **Expect**: Food shows actual 3,500, remaining 2,500, 58% used; overall summary reflects it too.
2. Record an expense in a category not part of the budget.
   - **Expect**: shown separately as unbudgeted spending, not folded into any budgeted category.
3. Edit the 3,500 EGP expense to 4,000 EGP, then delete a different budgeted expense.
   - **Expect**: figures update immediately both times.
4. Check a budgeted category with zero recorded expenses.
   - **Expect**: 0% used, full planned amount remaining, no error.

### 3. Over-budget warnings (User Story 3)
1. Push Entertainment's actual spend to exactly its planned amount, then past it.
   - **Expect**: 100%-used state at the boundary, then a clear over-budget state with the overage amount shown past it.
2. Push a category to ~90% used without exceeding it.
   - **Expect**: a distinct "near full" state, different from both on-track and over-budget.
3. Push total actual spend across all categories past total planned.
   - **Expect**: the overall summary is also marked over budget.

### 4. Copy forward (User Story 4)
1. From next month (no budget yet), copy the previous month's budget.
   - **Expect**: new budget created with identical categories/amounts in under a few taps; completes quickly.
2. Edit a planned amount in the new month.
   - **Expect**: the source month's budget and figures are completely unaffected.
3. On a fresh install with zero budget history, open budgets for the first time.
   - **Expect**: offered to create from scratch (no broken "copy" affordance since nothing exists to copy).

### 5. Spending trends (User Story 5)
1. With budgets and expenses recorded across at least 3 months, open the trend view for a specific category.
   - **Expect**: correct planned/actual per month, chronological order.
2. Open the overall trend view (no category selected).
   - **Expect**: total planned vs. total actual per month.
3. On an install with only 1 month of budget history, open the trend view.
   - **Expect**: a friendly "not enough history yet" state, not a broken/misleading single-point chart.

### 6. Localization and theming (FR-020)
1. Switch the app language to Arabic and reopen a budget with over-budget/near-full states and the trend chart.
   - **Expect**: correct RTL layout including the chart's axis/labels, correct numeral/month formatting, warning states conveyed by more than color alone.
2. Switch between light and dark mode.
   - **Expect**: progress rows, warning badges, and the trend chart remain legible and correctly themed.
