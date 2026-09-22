# Feature Specification: Reports & Data/Privacy Controls

**Feature Branch**: `013-reports-data-privacy`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V1.5.3 — bundle two low-architectural-risk, high-trust-value capabilities into one feature: (A) Reports — spending/income trend visibility over time and a category breakdown, reading feature 007's Income & Expense Tracking data, reusing its existing summary/breakdown aggregation across multiple periods rather than introducing new SQL; (B) Data & Privacy Controls — the privacy controls the product brief explicitly requires: a complete data export the user can share via the OS, and an irreversible 'delete all my data' flow with strong confirmation that resets the app to a fresh-install state. Both depend on feature 007. Neither blocks nor is blocked by any other roadmap item."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable defaults, documented in Assumptions.*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See Spending and Income Trends Over Time (Priority: P1)

A user wants to understand not just this month's numbers but how their spending and income have moved over recent months — which categories dominate, and whether a category is trending up or down — so they can spot patterns without doing the math themselves.

**Why this priority**: This is the direct fulfillment of the product's "someone who remembers my money for me" promise applied to trends, not just point-in-time totals; it's the reason a dedicated Reports screen exists at all, distinct from the Home Dashboard's single-period snapshot.

**Independent Test**: With income/expense entries recorded across several past months and categories, open the Reports screen and verify the category breakdown and the monthly trend both display correct figures matching a manual calculation from the underlying entries.

**Acceptance Scenarios**:

1. **Given** the user has income/expense entries recorded across multiple past months, **When** they open the Reports screen, **Then** they see a monthly trend showing income and expense totals for each of the recent months, and a category breakdown for the currently selected period.
2. **Given** the user is viewing the category breakdown, **When** they look at it, **Then** categories are ordered from largest to smallest amount and each shows its share of the period's total, consistent with how the same breakdown already appears elsewhere in the app.
3. **Given** the user wants to focus on a different time window, **When** they change the selected period for the breakdown, **Then** the breakdown updates to match while the monthly trend continues showing the recent-months overview.
4. **Given** the user has never recorded any income or expense entry, **When** they open the Reports screen, **Then** they see a clear empty state explaining that reports will appear once they start recording income and expenses, with a direct way to add their first entry.
5. **Given** the Reports data fails to load, **When** the screen renders, **Then** the user sees a clear error state with a retry action, never a blank or stuck screen.
6. **Given** the user switches the device language to Arabic or the app theme to dark mode while viewing a chart, **When** the chart re-renders, **Then** its axis direction, legend position, and all labels mirror/theme correctly with no broken or mislabeled chart elements.

---

### User Story 2 - Export a Complete Copy of My Data (Priority: P1)

A user wants a personal backup of everything they've recorded in the app, or wants to move their data somewhere else (a spreadsheet, another device, a personal archive), and expects the app to hand them a complete, readable copy on request.

**Why this priority**: This is a direct, non-negotiable privacy requirement from the product brief ("can users export their data?") and a foundational trust signal for a fully offline app holding someone's complete financial picture — without it, the user has no way to get their own data out if they ever stop using the app.

**Independent Test**: With a mix of people, transactions, income/expense entries, and categories already recorded, request a data export and verify the resulting file contains every one of those records with correct values, and can be shared off the device.

**Acceptance Scenarios**:

1. **Given** the user opens the data export screen, **When** they choose to export their data, **Then** the system generates a single file containing all of their people, person-to-person transactions, income/expense entries, categories, and app settings.
2. **Given** the export is generating, **When** the user is waiting, **Then** they see a clear in-progress indicator, not a frozen or ambiguous screen.
3. **Given** the export completes successfully, **When** the user is shown the result, **Then** they are offered a direct way to share or save the generated file using their device's standard share options.
4. **Given** the export fails for any reason, **When** the failure occurs, **Then** the user sees a clear, friendly error message and a way to try again, and no partially-written file is left in a way that could confuse a later export attempt.
5. **Given** the user has recorded no data of any kind yet, **When** they request an export, **Then** they still receive a valid, correctly-structured file reflecting that there is nothing recorded yet, not an error.

---

### User Story 3 - Permanently Delete All My Data (Priority: P2)

A user wants to stop using the app and have their data completely and irreversibly removed from the device — no residue, no way to accidentally recover it, and the app should return to exactly the state it was in on first install.

**Why this priority**: This is the second explicit, non-negotiable privacy requirement from the product brief ("can users delete their data?"). It is prioritized after export (P1) because export is the safer, non-destructive, higher-frequency need, while deletion is rarer but still mandatory for the app to be trustworthy — and per the constitution's Financial Domain Override, the single most destructive action in the entire app deserves the most deliberate confirmation flow.

**Independent Test**: With a full set of people, transactions, income/expense entries, and categories recorded, trigger the delete-all-data flow, complete its confirmation, and verify every record is gone and the app behaves exactly like a fresh install afterward.

**Acceptance Scenarios**:

1. **Given** the user opens the delete-my-data option in Settings, **When** they view it, **Then** they see a clear, unambiguous warning that this action is permanent, cannot be undone, and will remove everything they have recorded.
2. **Given** the user wants to proceed, **When** they attempt to confirm the deletion, **Then** the system requires an explicit, deliberate confirmation step (not a single accidental tap) before anything is deleted.
3. **Given** the user completes the confirmation, **When** the deletion runs, **Then** every person, transaction, income/expense entry, category, and app setting is removed, and the app returns to its first-launch (onboarding) state.
4. **Given** the deletion is in progress, **When** the user is waiting, **Then** they see a clear indication that deletion is happening, and it completes in a short, bounded time.
5. **Given** the deletion fails partway through for any reason, **When** the failure occurs, **Then** none of the user's data has been removed — the operation either fully succeeds or leaves everything exactly as it was, never a partial deletion.
6. **Given** the user opens the confirmation step, **When** they change their mind, **Then** they can cancel with no data affected at all.

---

### Edge Cases

- What happens when the user requests an export immediately after having just deleted an entry (or a category, or a person) using its own feature's undo window? The export reflects the data as currently persisted at the moment of export, not any in-flight, not-yet-finalized undo state.
- What happens when the user's device runs low on storage during export generation? The export fails cleanly with a clear message rather than producing a corrupted or truncated file.
- What happens when the user cancels the OS share sheet after a successful export instead of completing a share/save action? The generated file remains available and the export screen returns to its ready-to-share state, not an error state.
- What happens when the device language/direction changes (Arabic/RTL vs. English/LTR) while a chart or the export/delete screens are open? Layout, chart mirroring, and all labels must remain correct with no broken layout.
- What happens if the user attempts to trigger the delete flow twice in rapid succession (e.g., a fast double-tap)? Only one deletion operation ever executes.
- What happens when the device has zero network connectivity while exporting or deleting? Both operations complete normally — neither depends on network access; only the final "share" step hands off to the OS's own share mechanism, which itself may or may not need network access depending on where the user chooses to send the file, but the app's own export/delete logic never requires connectivity.
- What happens if the app is closed or backgrounded mid-deletion? The deletion either has already fully committed or not been applied at all when the app resumes — never left in a partial state (constitution: transactional, all-or-nothing).

## Requirements *(mandatory)*

### Functional Requirements

**Reports**

- **FR-001**: The system MUST let the user view a monthly trend of income and expense totals across a range of recent months.
- **FR-002**: The system MUST let the user view a per-category breakdown of income or expense totals for a selectable period, ordered from largest to smallest amount, consistent with the category breakdown already available elsewhere in the app.
- **FR-003**: The system MUST NOT introduce a second, separately-maintained calculation path for any total or breakdown figure already computed elsewhere in the app — every reported figure MUST come from the app's single existing source of truth for that figure.
- **FR-004**: The system MUST show a distinct empty state on the Reports screen when the user has never recorded any income or expense entry, explaining what the screen will show once they do, with a direct path to add their first entry.
- **FR-005**: The system MUST show a clear error state with a retry action if report data fails to load, and MUST NOT leave the user on a blank or indefinitely loading screen.
- **FR-006**: The system MUST render all chart elements (trend lines/bars, axes, legends, labels) correctly mirrored for right-to-left (Arabic) layout and correctly themed in both light and dark mode.

**Data Export**

- **FR-007**: The system MUST let the user generate a single export file containing all of their recorded people, person-to-person transactions, income/expense entries, categories, and app settings.
- **FR-008**: The system MUST produce a correctly structured export file even when the user has no data of any kind recorded yet (an empty-but-valid export, not an error).
- **FR-009**: The system MUST show a clear in-progress state while the export file is being generated.
- **FR-010**: Upon successful export generation, the system MUST offer the user a direct way to share or save the file using their device's standard sharing mechanism.
- **FR-011**: The system MUST show a clear, friendly error message and a retry option if export generation fails, and MUST NOT leave a partially-written file in a state that could be mistaken for a complete export.
- **FR-012**: The system MUST generate the export using only data already persisted on the device, and MUST NOT transmit any of the user's data anywhere as part of generating the export — the export only leaves the device if and when the user explicitly chooses a destination through the device's own share mechanism.

**Delete My Data**

- **FR-013**: The system MUST provide a way, reachable from the app's settings, for the user to permanently delete all of their recorded data.
- **FR-014**: The system MUST display an explicit, unambiguous warning that the deletion is permanent and irreversible before any deletion occurs.
- **FR-015**: The system MUST require a deliberate, explicit confirmation step — not a single ordinary tap — before executing the deletion, consistent with how the app already requires confirmation for its most sensitive actions.
- **FR-016**: The system MUST delete every person, person-to-person transaction, income/expense entry, category, and app setting when the deletion is confirmed, with no data left behind.
- **FR-017**: The system MUST return the app to its original first-launch (onboarding) state immediately after a successful deletion.
- **FR-018**: The system MUST perform the deletion as a single all-or-nothing operation: if any part of the deletion fails, the system MUST leave all of the user's data completely unaffected — a partial deletion MUST NEVER occur.
- **FR-019**: The system MUST show a clear in-progress indication while deletion is running and MUST complete it in a short, bounded time.
- **FR-020**: The system MUST let the user cancel the deletion confirmation at any point before the final confirmation with no data affected.
- **FR-021**: The system MUST prevent a rapid repeated confirmation tap from triggering more than one deletion operation.

**Cross-cutting**

- **FR-022**: The system MUST keep both Reports and the Export/Delete flows fully usable with no internet connection, except for the final, user-initiated hand-off to the device's own share mechanism after an export completes, which is outside the app's own control.
- **FR-023**: The system MUST present all Reports, Export, and Delete screens, labels, warnings, and confirmation copy fully localized in both Arabic and English, with correct RTL/LTR layout, and correctly themed in both light and dark mode.

### Key Entities *(include if feature involves data)*

- This feature introduces no new entity that the user creates or edits, and no new persisted database table. It reads across the app's existing recorded data (people, person-to-person transactions, income/expense entries, categories, app settings) to produce two output artifacts: an on-screen trend/breakdown view (Reports, ephemeral, recomputed on demand) and a generated export file (a point-in-time, shareable snapshot of that same data, not a live or synced copy). The delete operation removes existing data; it does not introduce any of its own.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user with existing income/expense history can see their monthly income/expense trend and current-period category breakdown within 2 seconds of opening the Reports screen.
- **SC-002**: A user can generate and reach the share/save step for a complete data export in 3 taps or fewer from the Reports/Settings area.
- **SC-003**: 100% of a user's recorded people, transactions, income/expense entries, and categories are present and correctly valued in a generated export file, verified across at least 3 distinct test datasets of varying size.
- **SC-004**: A user cannot complete the delete-all-data flow with fewer than 2 distinct deliberate confirmation actions, verified by review of the confirmation flow.
- **SC-005**: 100% of simulated delete-failure scenarios in testing result in zero data loss (either full success or a fully-intact prior state), with zero partial-deletion outcomes observed.
- **SC-006**: Switching the app language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, mirroring, or truncation defects on the Reports, Export, or Delete screens.
- **SC-007**: A user with no recorded data can still successfully complete an export (receiving a valid empty file) and can still see the correct Reports empty state, with no error shown in either case.

## Assumptions

- **Scope boundary**: Reports in this feature covers trend and category-breakdown visibility only, sourced entirely from feature 007's existing Income/Expense data. It does not include Budgets or Savings reporting (those features do not exist yet) and does not include any person-to-person balance trend (the existing Overview/Home screens already cover point-in-time balance totals; a historical trend of balances is out of scope here).
- **Export format**: The export is a single downloadable/shareable file in a common, widely-readable, non-proprietary format (e.g. a structured text/spreadsheet-compatible format) so the user can open it without needing this app — chosen because it directly serves the "give the user their data back in a usable form" intent of the privacy requirement, not because of any particular technical preference.
- **Export scope is always "everything"**: this feature's export always includes all recorded data categories (people, transactions, income/expense entries, categories, settings) in one file rather than offering a partial/selective export — a full export is the simplest, most trustworthy default for a privacy feature, and partial export is a reasonable future enhancement rather than a requirement here.
- **Delete is account-wide, not selective**: "Delete My Data" removes everything, matching the product brief's framing of this as the account-deletion-equivalent action for a backend-less, fully local app. Deleting a single person/transaction/entry already exists as a separate capability in each owning feature and is unaffected by and unrelated to this feature.
- **No backup-before-delete requirement**: the delete flow does not automatically trigger an export first. A user who wants a safety copy can use the Export feature (User Story 2) beforehand; this is a UX suggestion the confirmation screen can surface, not a hard technical requirement of the delete flow itself.
- **Reports period defaults**: "recent months" for the monthly trend defaults to a reasonable rolling window (e.g. the last several months) matching typical personal-finance review habits; the exact number of months and the category-breakdown period's default selection are presentation-layer details decided at planning time, not product requirements this spec fixes.
- **Single user per device**: consistent with the rest of the app's scope, there is exactly one user's data on the device — export and delete both operate on "all data on this device," with no multi-account or multi-profile concept to consider.
