# Feature Specification: Household Budgets

**Feature Branch**: `010-household-budgets`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V1.5 — Household Budgets. Ground this in docs/project.txt section 5 (HOME BUDGET) and build on top of the existing 007-income-expense-tracking module (Category, FinanceEntry). A user wants to plan a monthly budget by allocating planned amounts to expense categories (e.g. Rent 7,000, Food 6,000, Transportation 3,000, Bills 2,500, Entertainment 2,000, Other 4,500 against a monthly income of 30,000 EGP) and see, per category and overall: planned, actual (from real recorded expenses), remaining, percentage used, over-budget warnings, and a spending trend view across months. Budgets must read the existing Category/FinanceEntry data from 007 through its existing repository contracts rather than inventing a second categories table or a second spend-aggregation path, per 007's own data-model.md note that Budgets is expected to do exactly this."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable, documented defaults in Assumptions, following the pattern established in prior specs.*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a Monthly Budget (Priority: P1)

A user wants to plan how much they intend to spend in each expense category this month — rent, food, transportation, bills, entertainment, and whatever else matters to them — so they have a target to spend against instead of finding out at month's end that they overspent.

**Why this priority**: This is the entire reason the feature exists — without a way to set planned amounts per category, there is nothing for "actual vs. planned" to compare against.

**Independent Test**: Can be fully tested by creating a budget for the current month, allocating planned amounts to several existing expense categories, saving, and confirming the budget is retrievable with the correct planned amounts.

**Acceptance Scenarios**:

1. **Given** the user has no budget for the current month yet, **When** they create one and allocate planned amounts to categories such as Rent, Food, and Transportation (picked from their existing expense categories, 007), **Then** the budget is saved and each category's planned amount is shown.
2. **Given** the user is allocating a planned amount to a category, **When** they enter a zero or negative amount, **Then** the system rejects it and explains why.
3. **Given** the user wants a quick reference point, **When** they optionally enter their expected monthly income for the budget, **Then** it is saved and shown alongside the budget for reference, and the system indicates if the sum of planned category amounts exceeds it, without blocking the save.
4. **Given** the user wants to budget for a category the defaults don't cover, **When** they pick any of their existing expense categories (including a custom one they created in 007) or create a new expense category inline, **Then** it becomes available for allocation immediately, exactly as in the existing category-management flow.
5. **Given** the user has already started a new month with no budget defined, **When** they open budgets, **Then** they are offered to create a new one or copy the previous month's budget as a starting point (User Story 4) rather than starting from a blank list every time.

---

### User Story 2 - See Planned vs. Actual, Remaining, and Percentage Used (Priority: P1)

A user wants to open their budget at any point in the month and immediately understand, per category and overall, how much they planned to spend, how much they've actually spent, how much is left, and what share of the plan they've used — without doing any math themselves.

**Why this priority**: Creating a budget (User Story 1) has no value unless the user can later see how reality compares to the plan; this is the core "someone who remembers my money for me" payoff for this feature.

**Independent Test**: Can be fully tested by creating a budget with planned amounts, recording several real expenses (007) against the budgeted categories, and confirming the displayed actual, remaining, and percentage-used figures for each category and overall exactly match the underlying expense entries.

**Acceptance Scenarios**:

1. **Given** a budget category "Food" planned at 6,000 EGP, **When** the user has recorded 3,500 EGP of expenses in the Food category this month, **Then** the budget shows Food's actual as 3,500 EGP, remaining as 2,500 EGP, and 58% used, all computed automatically.
2. **Given** the user opens their budget for the current month, **When** they view it, **Then** they see an overall summary (total planned, total actual, total remaining, overall percentage used) in addition to the per-category breakdown.
3. **Given** the user has recorded an expense in a category that is not part of the current budget, **When** they view the budget, **Then** that spending is shown separately as "unbudgeted" spending rather than silently omitted or incorrectly folded into a budgeted category's actual.
4. **Given** the user edits or deletes an expense entry (007) that affects a budgeted category, **When** they return to the budget, **Then** the actual/remaining/percentage figures reflect the change immediately.
5. **Given** a budgeted category has zero recorded expenses so far this month, **When** the user views the budget, **Then** it shows 0% used and the full planned amount as remaining, not an error or blank state.

---

### User Story 3 - See Over-Budget Warnings (Priority: P2)

A user wants to be clearly warned, without having to compare numbers themselves, when they've spent more than they planned in a category or overall.

**Why this priority**: Turns a passive report (User Story 2) into an active, useful signal — the moment a user actually needs to change behavior — but the feature is still meaningfully useful for after-the-fact review without it.

**Independent Test**: Can be fully tested by recording expenses that push a budgeted category's actual spend past its planned amount and confirming a clear, distinct visual warning appears for that category (and overall, when applicable).

**Acceptance Scenarios**:

1. **Given** a budget category "Entertainment" planned at 2,000 EGP, **When** recorded expenses in that category reach 2,000 EGP, **Then** the category is visually marked as fully used (e.g. 100%), and if spending continues past that, it is clearly marked as over budget with the overage amount shown.
2. **Given** a category is approaching but has not yet reached its planned amount (e.g. 90% used), **When** the user views the budget, **Then** it is visually distinguished from both "on track" and "over budget" categories, giving the user advance warning.
3. **Given** the sum of actual spending across all budgeted categories exceeds the sum of planned amounts, **When** the user views the overall budget summary, **Then** the overall total is also clearly marked as over budget, not just the individual categories.

---

### User Story 4 - Carry a Budget Forward to a New Month (Priority: P2)

A user whose spending plan doesn't change much month to month wants to start a new month's budget from their previous month's allocations instead of re-entering every category and amount from scratch.

**Why this priority**: Removes real, recurring friction that would otherwise make the feature feel like a chore every month and cause abandonment — but a user can still get full value from the feature by re-creating a budget manually each month without it.

**Independent Test**: Can be fully tested by creating a budget for one month, then starting a new month and copying the previous month's budget, and confirming the new month's budget starts with the same categories and planned amounts (editable independently afterward).

**Acceptance Scenarios**:

1. **Given** the user has a budget for the previous month, **When** they choose to copy it to a new month, **Then** a new budget is created for the new month with the same categories and planned amounts, which they can then adjust independently.
2. **Given** the user has copied a budget forward, **When** they change a planned amount in the new month, **Then** the previous month's budget and its figures remain completely unaffected.
3. **Given** the user has no previous month's budget to copy (first-ever use), **When** they open budgets for the first time, **Then** they are offered to create one from scratch, with the standard expense categories from 007 available to pick from, and are not blocked or confused by a missing "copy" option.

---

### User Story 5 - View Spending Trends Across Months (Priority: P3)

A user wants to see how their planned and actual spending in a category (or overall) has changed over recent months, to notice patterns like a category that consistently runs over budget.

**Why this priority**: A valuable analytical enhancement once several months of budget history exist, but the core month-to-month planning/tracking value (User Stories 1-3) is fully delivered without it, and it has no meaningful data to show until a user has used the feature for more than one month.

**Independent Test**: Can be fully tested by creating budgets across at least three consecutive months with varying actual spending, opening the trend view, and confirming it correctly shows planned vs. actual for each month per category or overall.

**Acceptance Scenarios**:

1. **Given** the user has budgets and recorded expenses across at least three months, **When** they open the spending trend view for a specific category, **Then** they see that category's planned and actual amounts for each of the recent months, in chronological order.
2. **Given** the user wants an overall view, **When** they open the trend view without selecting a specific category, **Then** they see total planned vs. total actual per month across the same recent months.
3. **Given** the user has fewer than two months of budget history, **When** they open the trend view, **Then** a friendly empty/insufficient-data state explains that trends need at least two months of history rather than showing a broken or misleading single-point chart.

---

### Edge Cases

- What happens when a category used in a budget is later archived in category management (007, FR-010)? The budget keeps showing that category's name/icon and its actual spend correctly (archived categories remain resolvable, 007's own rule), but the archived category is excluded from the picker when allocating a *new* budgeted category, consistent with 007's existing archived-category picker exclusion (FR-011).
- What happens when the user sets a planned amount of exactly zero for a category they still want listed (e.g. to explicitly track "I don't plan to spend anything here")? It is accepted (only a negative amount is rejected) and immediately shows as over budget at the first EGP of actual spending in that category, which is the correct, expected behavior for a zero-planned category.
- What happens when the sum of planned category amounts exceeds the entered monthly income? The system shows this clearly (e.g. "budget exceeds income by X") but does not block saving — this is a real, valid situation some users intentionally plan around (e.g. drawing from savings), not an error.
- What happens when the user records an expense with a date in a different month than the currently open budget? It correctly affects that expense's own month's budget (matched by date), not the month the user happened to be viewing when they recorded it.
- What happens when the user deletes a budget entirely? It is removed after explicit confirmation; the underlying expense entries (007) are completely unaffected, since a budget is only a plan overlaid on real spending data, never a store of the spending data itself.
- What happens when the user removes a single category from an existing budget (rather than deleting the whole budget)? That category's planned amount is removed from the budget; its actual spending (if any) then shows as "unbudgeted" for that month rather than disappearing.
- What happens when two categories in the same budget happen to have the same name (e.g. after one was renamed to match another)? Category name uniqueness is already enforced per type at creation in 007 (FR-008), so this cannot occur through normal use; a budget always references categories by their stable ID, never by name.
- What happens when the user views a budget for a future month that hasn't started yet? It is allowed (pre-planning next month is a valid use case) and simply shows 0 actual spending so far, exactly like Edge Case "zero recorded expenses" in User Story 2.
- What happens when the app's language or theme changes while a budget with over-budget categories is open? Over-budget/warning indicators must never rely on color alone (constitution Accessibility standard) and must remain correctly laid out and legible in RTL/LTR and both themes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create a budget scoped to a single calendar month, allocating a planned amount to one or more existing or newly-created expense categories (reusing 007's Category entity and category-management flow — this feature MUST NOT introduce a second categories concept).
- **FR-002**: The system MUST reject a negative planned amount and explain why; a planned amount of exactly zero MUST be accepted.
- **FR-003**: Users MUST be able to optionally record an expected monthly income figure on a budget, shown for reference alongside the budget, without it constraining or altering how planned/actual/remaining are computed per category.
- **FR-004**: The system MUST indicate, without blocking the save, when the sum of a budget's planned category amounts exceeds its recorded expected income (when an income figure is present).
- **FR-005**: The system MUST automatically compute and display, for every budgeted category: actual spend (the sum of that category's non-deleted expense entries from 007 whose date falls within the budget's month), remaining (planned minus actual), and percentage used (actual divided by planned, expressed as a percentage) — recalculated immediately whenever a relevant expense entry is added, edited, or deleted, and never stored as an independently editable figure.
- **FR-006**: The system MUST automatically compute and display an overall summary for the budget: total planned, total actual, total remaining, and overall percentage used, aggregated across all of that budget's categories.
- **FR-007**: The system MUST identify and separately display "unbudgeted" spending — expense entries (007) in the budget's month whose category is not part of the current budget — distinctly from budgeted-category actuals, rather than omitting it or misattributing it.
- **FR-008**: The system MUST visually distinguish three states for each budgeted category based on its percentage used: on track (below a near-full threshold), near full (at or above the threshold but not yet over), and over budget (actual exceeds planned) — using more than color alone to convey the distinction (e.g. also an icon or label).
- **FR-009**: The system MUST visually mark the overall budget summary as over budget whenever total actual exceeds total planned, independent of individual category states.
- **FR-010**: Users MUST be able to edit an existing budget: change a category's planned amount, add a new categorized allocation, or remove a category from the budget, with all totals recalculating immediately.
- **FR-011**: Users MUST be able to delete an entire budget after explicit confirmation; deleting a budget MUST NOT alter, delete, or otherwise affect any underlying expense/income entries (007).
- **FR-012**: Users MUST be able to create a new month's budget by copying an existing (typically the most recent) month's budget as a starting point, producing an independently editable new budget with the same categories and planned amounts, with no ongoing link back to the source budget.
- **FR-013**: Users MUST be able to navigate between months to view any past, current, or future month's budget (if one exists for that month) or be offered to create one if none exists.
- **FR-014**: Users MUST be able to view a spending trend across at least the most recent 6 months (or however many months of budget history exist, whichever is fewer), either for a single selected category or as an overall planned-vs-actual comparison, with a clear "not enough history yet" state when fewer than 2 months of budget history exist.
- **FR-015**: The system MUST compute every planned/actual/remaining/percentage/trend figure using the existing deterministic, integer-minor-unit money arithmetic already established in 007/001 — never floating point, never an AI-estimated figure.
- **FR-016**: The system MUST read category and expense data exclusively through 007's existing `Category`/`FinanceEntry` repository contracts — this feature MUST NOT introduce a second category table, a second expense-entry table, or a second spend-aggregation code path.
- **FR-017**: The system MUST prevent a single user-initiated save action (including a rapid repeated tap) from creating more than one budget for the same month or duplicating a category allocation within a budget.
- **FR-018**: The system MUST show a friendly empty state when the user has no budget for the currently viewed month, offering to create one or copy the previous month's (FR-012).
- **FR-019**: The system MUST keep all budget creation, editing, viewing, and trend features fully functional with no network connection, consistent with the app's existing offline-only operation.
- **FR-020**: The system MUST present all budget screens fully localized in both Arabic and English, with correct RTL/LTR layout, number formatting, currency formatting, and date/month formatting per the active language, and correctly themed in both light and dark mode, with warning states conveyed by more than color alone.
- **FR-021**: The system MUST allow a budgeted category whose underlying `Category` has since been archived (007) to continue displaying correctly (name, icon, actual spend) within its existing budget, while excluding archived categories from the picker used to add a *new* allocation to a budget.
- **FR-022**: The system MUST NOT alter, migrate, or merge any existing `MoneyTransaction`/`Person` (001) or `FinanceEntry`/`Category` (007) data, records, or balance/summary calculations as part of this feature; budgets are a read-and-plan-only overlay on top of existing expense data.

### Key Entities *(include if feature involves data)*

- **Budget**: A user's spending plan for one calendar month. Attributes: the month/year it applies to, an optional expected-income figure for reference, and a set of Budget Category Allocations. Never stores planned totals or income-vs-plan comparisons as independently editable figures — the overall summary is always computed from its allocations.
- **Budget Category Allocation**: One category's planned amount within a Budget. Attributes: a reference to an existing `Category` (007, must be of type expense), a planned amount, and computed (not stored) actual/remaining/percentage-used figures derived on demand from 007's `FinanceEntry` records matching that category and the Budget's month.
- **Category / FinanceEntry (from 007, unchanged)**: Read, not written to, by this feature (beyond the existing category-management flow this feature reuses for inline creation). This feature adds no new fields to either.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a complete monthly budget with 5 categories in under 90 seconds.
- **SC-002**: For any budgeted category, the displayed actual/remaining/percentage-used figures always exactly match the sum of that category's real expense entries for the budget's month, with zero discrepancies across test scenarios involving at least 100 expense entries spread across 10 categories.
- **SC-003**: A user can tell, at a glance and within 2 seconds of opening a budget, which categories are on track, near full, and over budget, with no manual comparison of numbers.
- **SC-004**: Copying a previous month's budget to a new month takes under 10 seconds and produces an exact match of categories/planned amounts, independently editable with zero effect on the source month.
- **SC-005**: 100% of expense spending in a budgeted month is accounted for in the budget view, either as a budgeted category's actual or as clearly labeled unbudgeted spending — none is ever silently missing.
- **SC-006**: A user with at least 3 months of budget history can identify, from the trend view, which category has most consistently gone over budget, without needing to open each month's budget individually.
- **SC-007**: Switching the app language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, or truncation defects on any budget screen, including the over-budget warning states.

## Assumptions

- **Scope boundary and relationship to Savings Goals**: Budgets and the separate Savings Goals feature (a later roadmap item) are related but intentionally not automatically linked in v1.5. A user may budget for a category they personally call "Savings" (an ordinary custom expense category from 007, representing money they intend to set aside that month) exactly as shown in the product brief's own worked example, but this feature does not read from or write to Savings Goals' own target/progress tracking. A future integration (e.g. suggesting a budget category per active goal) is a reasonable later enhancement, not required here — avoiding it now keeps both features independently simple and avoids a premature bidirectional dependency.
- **Budget scope is expense categories only**: Income categories (007) are not budgeted against in this feature (there is nothing to "plan to spend" for income); the optional expected-income figure (FR-003) is a simple reference number, not a linked aggregation of income `FinanceEntry` rows, keeping the feature's calculation surface small and unambiguous for v1.5. A future enhancement could offer to pre-fill it from actual recorded income, but this spec does not require it.
- **One budget per calendar month**: A user has at most one active budget per month; "carrying forward" (FR-012) always creates an independent new budget for a different month, never a recurring/templated budget that auto-applies every month without an explicit copy action — this keeps each month's plan an intentional, reviewable decision rather than a silently auto-repeating one.
- **No push notifications**: Over-budget warnings (User Story 3) are in-app visual states shown when the user opens the budget, not push/background notifications — consistent with the product brief's "do not overload the dashboard" / progressive-disclosure guidance and avoiding a notification-permission dependency this v1.5 tier does not otherwise need. A future notifications feature could add this.
- **Trend view scope**: Limited to a rolling window of the most recent 6 months of budget history (FR-014) for v1.5, a scope chosen to keep the trend view fast and simple to compute and display on mid-range devices; a longer/custom range is a reasonable future enhancement.
- **Currency**: Single currency (EGP), consistent with 001/007's existing scope; multi-currency is out of scope.
- **Amount ceiling**: Reuses the same maximum-amount validation ceiling already enforced for `MoneyTransaction`/`FinanceEntry` amounts, for consistency rather than inventing a new limit.
- **Near-full threshold**: The "near full" warning state (FR-008) uses a reasonable default threshold (90% of planned) — a presentation-layer/UX detail decided at planning time, not a product decision requiring user input, and not user-configurable in v1.5.
