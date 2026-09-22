# Feature Specification: Income & Expense Tracking

**Feature Branch**: `007-income-expense-tracking`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V1.5 — Personal Finance core. The app currently tracks only money exchanged between the user and other people (People + Transactions). It has no way to record the user's own income (salary, freelance, business, bonus, gift, other) or personal expenses (rent, electricity, water, internet, phone, groceries, transportation, fuel, medical, education, entertainment, shopping, restaurants, subscriptions, family, other), organized by customizable categories. This is a hard prerequisite for Budgets and for any AI spending insight planned later in the roadmap, since both need a real source of income/expense data to work from."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable defaults, documented in Assumptions.*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record an Expense (Priority: P1)

A user just paid for something — groceries, a phone bill, a taxi ride — and wants to log it in under a few seconds so their spending history stays accurate.

**Why this priority**: Expense logging is the single most frequent action in this feature and the entire reason it exists; without it, nothing else here has value.

**Independent Test**: From the finance section, add a new expense with an amount and a category, save it, and verify it appears at the top of the history with the correct amount, category, and date.

**Acceptance Scenarios**:

1. **Given** the user is adding a new expense, **When** they enter a positive amount, pick a category, and save, **Then** the expense is recorded and immediately visible in the history and in the relevant category/period totals.
2. **Given** the user is adding a new expense, **When** they leave the amount empty or enter zero, **Then** the system blocks saving and shows a clear validation message without discarding what was already entered.
3. **Given** the user is adding a new expense, **When** they don't pick a category, **Then** the system blocks saving until a category is chosen (no uncategorized entries).
4. **Given** the user is adding a new expense, **When** they don't change the date, **Then** today's date is used automatically; **When** they do change it, **Then** any past date is accepted and future dates are accepted as planned/scheduled entries.
5. **Given** the user is adding a new expense, **When** they add an optional note, **Then** the note is saved and shown on the entry's details.

---

### User Story 2 - Record Income (Priority: P1)

A user just got paid — salary, a freelance payment, a bonus, a gift — and wants to log it so their income history and totals stay accurate.

**Why this priority**: Income is the counterpart to expenses and equally essential to any meaningful personal-finance picture (remaining budget, savings capacity); without it the feature only tells half the story.

**Independent Test**: From the finance section, add a new income entry with an amount and a category, save it, and verify it appears in the history and totals separately from expenses.

**Acceptance Scenarios**:

1. **Given** the user is adding a new income entry, **When** they enter a positive amount, pick an income category, and save, **Then** the entry is recorded and immediately visible in the history and in the relevant totals.
2. **Given** the user is viewing their history, **When** it contains both income and expense entries, **Then** each is clearly and visually distinguished from the other (not just by category name).
3. **Given** the user is adding a new income entry, **When** they apply the same validation rules as expenses (amount, category required), **Then** the same blocking/feedback behavior applies.

---

### User Story 3 - Review History and Totals (Priority: P2)

A user wants to understand where their money is going and coming from — total spent this month, total earned, and a breakdown by category — without doing any math themselves.

**Why this priority**: Recording data has no value on its own; users need to see it summarized to get the "someone who remembers my money for me" experience the product is built around.

**Independent Test**: With a mix of income and expense entries across categories and dates already recorded, open the history/summary view and verify totals, per-category breakdown, and period filtering are all correct.

**Acceptance Scenarios**:

1. **Given** the user has recorded income and expense entries, **When** they open the summary view, **Then** they see total income, total expenses, and the net (income minus expenses) for the currently selected period.
2. **Given** the user has entries across multiple categories, **When** they view the breakdown, **Then** each category shows its total and share of the period's spending (or income), ordered from largest to smallest.
3. **Given** the user wants a different time range, **When** they switch the period (e.g., this month, last month, custom range), **Then** all totals, breakdowns, and the history list update to match.
4. **Given** the user wants to find a specific entry, **When** they search or filter by category, type (income/expense), or date range, **Then** only matching entries are shown.
5. **Given** the user has no entries at all yet, **When** they open the summary or history, **Then** they see a friendly empty state that explains what this feature does and offers a direct way to add their first entry.
6. **Given** the user has entries in the selected period but a filter matches none of them, **When** the filter is applied, **Then** a distinct "no matching results" state is shown (not the same as the true first-time empty state).

---

### User Story 4 - Manage Categories (Priority: P2)

A user wants the category list to actually match their life — rename "Shopping" to something more specific, add a category the defaults don't cover, or retire one they never use — without losing any history already recorded against it.

**Why this priority**: Categories are core to every other story here; without the ability to customize them the feature stops matching real spending patterns, which the product brief explicitly calls out as a requirement.

**Independent Test**: Create a custom category, use it on a new entry, then rename and archive a different category, and verify existing entries referencing archived categories still display correctly in history.

**Acceptance Scenarios**:

1. **Given** the user opens category management, **When** the feature is used for the first time, **Then** a standard starter set of income and expense categories already exists (so the user isn't forced to set up categories before logging their first entry).
2. **Given** the user wants a category the defaults don't cover, **When** they create a new one with a name, an icon, and whether it's for income or expenses, **Then** it immediately becomes available when adding entries.
3. **Given** the user renames or re-icons an existing category, **When** they save the change, **Then** all past entries using that category reflect the updated name/icon (no re-entry needed).
4. **Given** a category has entries recorded against it, **When** the user tries to remove it, **Then** the system archives it (hides it from new-entry pickers) rather than deleting it, and existing entries keep showing it correctly.
5. **Given** a category has never been used by any entry, **When** the user removes it, **Then** it is deleted outright with no orphaned data left behind.
6. **Given** the user is picking a category while adding an entry, **When** the list is shown, **Then** archived categories are excluded from the picker but a category already used on an entry being edited remains visible for that entry.

---

### User Story 5 - Edit or Delete an Entry (Priority: P3)

A user made a mistake — wrong amount, wrong category, wrong date — or the entry no longer applies, and needs to correct or remove it.

**Why this priority**: Important for data accuracy, but lower priority than the ability to create and review data in the first place; the app is only trustworthy long-term if mistakes are fixable.

**Independent Test**: Edit an existing entry's amount and category, verify totals recalculate correctly, then delete a different entry and verify it disappears from history and totals while its change is auditable, consistent with how the existing Transactions feature already handles edits and deletes.

**Acceptance Scenarios**:

1. **Given** an existing entry, **When** the user edits its amount, category, date, or note and saves, **Then** the change is applied, the entry is marked as edited, and all affected totals update immediately.
2. **Given** an existing entry, **When** the user chooses to delete it, **Then** the system asks for confirmation before removing it, and afterward it no longer appears in history or totals.
3. **Given** the user just deleted an entry, **When** they immediately want to reverse that action, **Then** an undo option is available for a short window before the deletion becomes final.

---

### Edge Cases

- What happens when the user enters a decimal amount (e.g., 45.75 EGP)? It must be accepted and stored exactly, with no floating-point rounding drift, consistent with how existing person-to-person transactions already handle amounts.
- What happens when the user enters an extremely large amount? It must be accepted up to the same practical ceiling already enforced for person-to-person transactions, with the same validation message if exceeded.
- What happens if the user tries to create a category name that already exists (case-insensitive, trimmed) for the same type (income or expense)? The system blocks it and points the user to the existing category instead of creating a near-duplicate.
- What happens when the device language/direction changes (Arabic/RTL vs English/LTR) while category and entry lists are open? Layout, icons, amount alignment, and number formatting must mirror correctly with no broken layouts.
- What happens when a user has recorded entries and then switches theme (light/dark)? All charts, category colors, and income/expense visual distinctions must remain legible and correctly themed.
- What happens when the user filters to a period with zero entries after previously seeing data? The distinct "no matching results" empty state appears, not the true first-time empty state.
- What happens if the same physical entry is accidentally saved twice in a row (e.g., a fast double-tap on save)? Only one entry must be recorded.
- What happens when an entry's date is set in the future? It is accepted and shown in history/totals for the period it falls in, clearly marked as not yet due if the UI distinguishes past vs. upcoming.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow the user to record a new expense entry with a required positive amount, a required category, a date (defaulting to today), and an optional note.
- **FR-002**: The system MUST allow the user to record a new income entry with the same required/optional fields as FR-001, using an income-type category.
- **FR-003**: The system MUST reject saving any entry with a zero, negative, or missing amount, and MUST reject saving any entry with no category selected, showing a clear validation message in both cases without discarding the rest of the entered data.
- **FR-004**: The system MUST store every amount as an exact value with no floating-point rounding error, consistent with the existing money-handling approach used for person-to-person transactions.
- **FR-005**: The system MUST visually distinguish income entries from expense entries everywhere they can appear together (history list, totals, breakdowns).
- **FR-006**: The system MUST provide a starter set of default categories (both income and expense) available immediately on first use, without requiring the user to create any category before logging their first entry.
- **FR-007**: The system MUST allow the user to create a custom category with a name, an icon, and a type (income or expense).
- **FR-008**: The system MUST prevent creating a new category whose name duplicates (case-insensitive, trimmed) an existing active category of the same type.
- **FR-009**: The system MUST allow the user to rename or change the icon of an existing category (default or custom), and MUST reflect that change on every past entry that uses it.
- **FR-010**: The system MUST allow the user to remove a category: if it has never been used by any entry, delete it outright; if it has been used by at least one entry, archive it (removed from selection for new entries, preserved and correctly displayed on existing entries) instead of deleting it.
- **FR-011**: The system MUST exclude archived categories from the category picker when creating a new entry, while still allowing an entry that already uses an archived category to display and keep that category when edited.
- **FR-012**: The system MUST let the user view a history of income and expense entries, each showing amount, category, direction (income/expense), date, and note if present.
- **FR-013**: The system MUST let the user filter/search the history by entry type (income/expense), category, and date range.
- **FR-014**: The system MUST let the user view, for a selected period, the total income, total expenses, and net (income minus expenses).
- **FR-015**: The system MUST let the user view a per-category breakdown of totals for the selected period, ordered from largest to smallest amount.
- **FR-016**: The system MUST let the user switch the selected period (at minimum: this month, last month, and a custom date range) and MUST recalculate history, totals, and breakdowns to match.
- **FR-017**: The system MUST show a distinct empty state when the user has no income/expense entries at all, explaining the feature's purpose and offering a direct path to add the first entry.
- **FR-018**: The system MUST show a distinct "no matching results" state — different from the true first-use empty state — when a filter or period selection matches zero entries but entries exist elsewhere.
- **FR-019**: The system MUST allow the user to edit an existing entry's amount, category, date, and note, mark it as edited, and immediately reflect the change in all totals and breakdowns.
- **FR-020**: The system MUST require explicit confirmation before deleting an entry, and MUST offer a short-window undo after deletion completes.
- **FR-021**: The system MUST prevent duplicate entries being recorded from a single accidental repeated save action (e.g., a rapid double-submit).
- **FR-022**: The system MUST keep every income/expense entry, category, and total available and fully functional with no network connection, consistent with the app's existing offline-only operation.
- **FR-023**: The system MUST NOT alter, migrate, or merge the existing person-to-person Transactions data model, records, or balances as part of this feature; income/expense entries are a separate, additive concept the user records in addition to (not instead of) person-to-person money exchanges.
- **FR-024**: The system MUST present all income/expense screens, categories, and default category names fully localized in both Arabic and English, with correct RTL/LTR layout, number formatting, and date formatting per the active language, and correctly themed in both light and dark mode.

### Key Entities *(include if feature involves data)*

- **Finance Entry**: A single recorded income or expense event belonging to the user (not to another person). Attributes: type (income or expense), amount, category, date, optional note, created/edited/deleted timestamps for audit and undo, matching the trustworthiness pattern already established by the existing Transactions feature. This is a distinct concept from the existing person-to-person `MoneyTransaction` (which always involves another `Person` and has no category) — the two are recorded and reported separately, and this feature does not read, write, or duplicate `MoneyTransaction` data.
- **Category**: A user-facing label for grouping finance entries. Attributes: name, icon, type (income or expense — a category serves one or the other, never both), whether it is a default (starter) or custom category, and whether it is archived. Categories are the shared vocabulary future features (e.g., Budgets) will also use, so this feature is the single source of truth for it going forward.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can record a new expense or income entry, from opening the entry form to seeing it in their history, in under 15 seconds.
- **SC-002**: A user can find their total spending for the current month and their single biggest spending category within 2 taps/steps from the app's main screen.
- **SC-003**: 100% of amounts recorded and displayed match exactly what the user entered, with zero rounding discrepancies, across at least 1,000 recorded entries in testing.
- **SC-004**: A user with no prior finance-tracking experience can create a custom category and use it on a new entry without external help, on their first attempt.
- **SC-005**: Switching the app language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, or truncation defects on any screen in this feature.
- **SC-006**: A user can fully record, review, and manage their income and expenses with no internet connection at any point.

## Assumptions

- **Scope boundary**: This feature covers personal income/expense recording and reporting only. It does not include Budgets (spending limits/alerts) or Savings goals — those are separate, later roadmap items that will read from the Category/Finance Entry data this feature establishes.
- **Relationship to existing Transactions**: Person-to-person money exchanges (the existing People/Transactions feature) and personal income/expenses (this feature) are intentionally kept as two separate concepts, because they answer two different questions ("who owes whom" vs. "where does my money go"). Per the product's data-integrity principle, this feature is being built now specifically so that later features needing spending/income data (Budgets, AI insights) have exactly one source of truth to read from, rather than each inventing its own.
- **Default categories**: The starter category set follows the examples given in the product brief — Expenses: Rent, Electricity, Water, Internet, Phone, Groceries, Transportation, Fuel, Medical, Education, Entertainment, Shopping, Restaurants, Subscriptions, Family, Other. Income: Salary, Freelance, Business, Bonus, Gift, Other Income.
- **Currency**: Single currency (EGP), consistent with the app's existing scope — multi-currency is out of scope for this feature.
- **Amount ceiling**: Reuses whatever maximum-amount validation ceiling the existing Transactions feature already enforces, for consistency rather than inventing a new limit.
- **Undo window**: A short, standard undo window (a few seconds) after deletion is sufficient; the exact duration is a presentation-layer/UX detail decided at planning time, not a product decision requiring user input.
- **Navigation placement**: This feature needs a reachable entry point from the app's main navigation. The exact placement (a new tab vs. folded into the existing Overview area) is a navigation/IA decision made at planning time, not a behavioral requirement of this spec.
- **Attachments**: Photo/receipt attachments on entries are out of scope for this feature (OCR-based paper scanning is a separate, later roadmap item that will produce entries for review here, not the other way around).
