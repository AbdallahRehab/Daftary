# Feature Specification: Home Dashboard

**Feature Branch**: `012-home-dashboard`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V1.5.2 — turn the existing OverviewPage into the app's real 'financial snapshot + quick actions' home screen, per ROADMAP-PLAN.md §V1.5.2 and docs/project.txt §12 'Dashboard'. Extend (not replace) the existing /overview route: Financial Snapshot (existing owed-to-me/owed-by-me totals + this-month income/expense/net from feature 007), Quick Actions (Add Expense, Add Income, Add Person, Add Money Received, Add Money Given — all existing forms; Add Occasion/Scan Paper wired but hidden behind a feature flag until those features ship), Insights (honest empty state until AI Assistant exists — never fake), Upcoming (honest empty state until Budgets/Savings exist). No new entities/tables. Depends on feature 007 for GetFinanceSummary."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable defaults, documented in Assumptions.*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See My Complete Financial Picture at a Glance (Priority: P1)

A user opens the app and wants to immediately understand where they stand: who owes them money, who they owe, and how their personal income/spending looked this month — without navigating to multiple separate screens.

**Why this priority**: This is the core reason a "home" screen exists at all — a single glance that answers "how am I doing financially right now." Everything else on this screen is secondary to this snapshot.

**Independent Test**: With existing people balances and finance entries already recorded, open the home screen and verify the owed-to-me/owed-by-me totals and the this-month income/expense/net figures are all visible together and match what the People and Finance sections show individually.

**Acceptance Scenarios**:

1. **Given** the user has outstanding balances with other people and recorded income/expense entries this month, **When** they open the home screen, **Then** they see total owed to them, total they owe, this month's total income, this month's total expenses, and this month's net — all on one screen without further navigation.
2. **Given** both the balance totals and the finance summary load successfully, **When** the screen finishes loading, **Then** both figures are presented side by side as one cohesive "financial snapshot," not as two visually disconnected sections.
3. **Given** the user has no outstanding balances with anyone and no finance entries yet, **When** they open the home screen, **Then** they see a single combined first-run empty state explaining what the app does and how to get started, not two separate confusing empty states stacked on top of each other.
4. **Given** the user pulls to refresh the home screen, **When** the refresh completes, **Then** both the balance totals and the finance summary are re-fetched and updated together.

---

### User Story 2 - Start a Common Action Without Hunting for It (Priority: P1)

A user wants to log something that just happened — an expense, income, a new person, money received or given — right from the home screen, without first navigating to the section that owns that action.

**Why this priority**: Quick capture is the single highest-frequency need for a "someone who remembers my money for me" app; making the user dig through tabs to log a five-second transaction directly undermines the product's core promise.

**Independent Test**: From the home screen, tap each quick action and verify it opens the correct existing entry form pre-configured for that action (e.g., Add Expense opens the finance entry form defaulted to expense).

**Acceptance Scenarios**:

1. **Given** the user is on the home screen, **When** they tap "Add Expense," **Then** the existing expense entry form opens, defaulted to the expense type.
2. **Given** the user is on the home screen, **When** they tap "Add Income," **Then** the existing income entry form opens, defaulted to the income type.
3. **Given** the user is on the home screen, **When** they tap "Add Person," **Then** the existing add-person form opens.
4. **Given** the user is on the home screen, **When** they tap "Add Money Received" or "Add Money Given," **Then** the existing person-to-person transaction form opens, pre-set to the corresponding direction.
5. **Given** the user completes any quick action and returns to the home screen, **When** the screen is shown again, **Then** the financial snapshot reflects the just-recorded change without requiring a manual refresh.
6. **Given** a quick action for a feature that does not exist yet in the app (e.g., Add Occasion, Scan Paper), **When** the user views the quick actions row, **Then** that action is either not shown or clearly shown as not yet available, and never leads to a broken or dead-end screen.

---

### User Story 3 - Know What's Coming Without Being Told a Lie (Priority: P2)

A user wants to see forward-looking information — spending insights and upcoming obligations — but only if the app actually has something real to say; a fabricated tip or a made-up "upcoming bill" would break trust immediately.

**Why this priority**: Directly implements the product's non-negotiable trust principle (never a fake AI insight) and the "progressive disclosure" instruction — these sections exist as placeholders for real future capability, not as decoration today.

**Independent Test**: On a fresh install with none of the AI Assistant, Budgets, or Savings features present, open the home screen and verify the Insights and Upcoming sections each show an honest, clearly-worded empty state rather than any invented content.

**Acceptance Scenarios**:

1. **Given** the AI Assistant feature does not yet exist in the installed app, **When** the user views the Insights section, **Then** they see an explanation that insights become available once the AI Assistant is set up, and no invented or static "fake" insight is ever shown.
2. **Given** neither Budgets nor Savings exist yet in the installed app, **When** the user views the Upcoming section, **Then** they see an explanation that this section will show upcoming bills, savings goals, and unsettled balances once those features exist, and no fabricated content is shown.
3. **Given** the user has unsettled person-to-person balances, **When** the Upcoming section's empty state is shown, **Then** it does not duplicate or restate the balance totals already shown in the Financial Snapshot (the two sections must add distinct value, not repeat each other).

---

### User Story 4 - Recover Gracefully When Part of the Data Fails to Load (Priority: P2)

A user opens the home screen on a device where, for some reason, one part of the data (e.g., the finance summary) fails to load while the rest of the app's data is fine — they should still be able to use everything that did load, and clearly retry only the part that failed.

**Why this priority**: A financial home screen that goes fully blank or unusable because of one failed query would be a severe usability regression on the app's single most-visited screen; partial failure must degrade gracefully.

**Independent Test**: Simulate one aggregate (balance totals or finance summary) failing to load while the other succeeds, and verify the screen still renders the successful part fully, with a clear, localized retry affordance on just the failed part.

**Acceptance Scenarios**:

1. **Given** the balance totals load successfully but the finance summary fails, **When** the home screen renders, **Then** the balance totals display normally, and the finance-summary card shows an inline error state with a retry action, without blocking or hiding the rest of the screen.
2. **Given** the finance summary loads successfully but the balance totals fail, **When** the home screen renders, **Then** the finance summary displays normally, and the balance-totals card shows an inline error state with a retry action, without blocking or hiding the rest of the screen.
3. **Given** a card is showing an inline error state, **When** the user taps its retry action, **Then** only that card's data is re-fetched, and on success it replaces the error state with the correct figures without disturbing the rest of the screen.
4. **Given** both aggregates fail to load, **When** the home screen renders, **Then** the user sees a clear full-screen error state with a single retry action that re-attempts both.

---

### Edge Cases

- What happens when the user has people balances but has never recorded a single income/expense entry (or vice versa)? Each card independently shows its own correct state — one populated, the other showing its own zero/empty figures — never a shared or ambiguous empty state that implies both are missing.
- What happens when the device language/direction changes (Arabic/RTL vs. English/LTR) while the home screen is open? Layout, card order, quick-action icons, and number formatting must mirror correctly with no broken layout, matching the app's existing RTL precedent.
- What happens when the user switches theme (light/dark) while viewing the home screen? All cards, quick-action icons, and status colors remain legible and correctly themed in both modes, and income/expense/owed distinctions are never conveyed by color alone.
- What happens if the user taps a quick action while the previous quick-action navigation is still in flight (rapid double-tap)? Only one navigation occurs — no duplicate screens are pushed.
- What happens when a hidden/disabled quick action slot (Add Occasion, Scan Paper) is present in the layout but its feature is not yet available? It never triggers a broken deep link, a crash, or a blank screen; at most it is visibly present-but-disabled or entirely absent from the row, and this state is validated by this feature's own tests before it is ever depended on by a future feature's toggle.
- What happens if the user has zero people but has recorded finance entries, or the reverse? The single combined empty state referenced in User Story 1 only applies when *both* are truly empty; if either has real data, that data is shown and only the genuinely empty side reflects its own empty content.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST present, on a single home screen, the existing person-to-person balance totals (total owed to the user, total the user owes) alongside the current month's total income, total expenses, and net (income minus expenses), without requiring navigation to a separate screen.
- **FR-002**: The system MUST load the balance totals and the monthly finance summary together, and MUST show a loading state until both have resolved (successfully or with an error) for the first time.
- **FR-003**: The system MUST treat a failure in one of the two aggregates (balance totals, finance summary) independently from the other: the successful aggregate MUST render normally, and the failed aggregate MUST show its own inline error state with a retry action that re-fetches only that aggregate.
- **FR-004**: The system MUST show a single, full-screen error state with one combined retry action only when both aggregates fail to load.
- **FR-005**: The system MUST show one combined first-run empty state, explaining the app's purpose and offering a direct path to get started, only when the user has zero people, zero person-to-person balance activity, and zero finance entries; if either side has any data, that side MUST display its real state instead of an empty placeholder.
- **FR-006**: The system MUST provide quick actions for: Add Expense, Add Income, Add Person, Add Money Received, and Add Money Given, each opening the corresponding existing entry form pre-configured for that action (e.g., Add Expense opens the expense entry form already defaulted to the expense type).
- **FR-007**: The system MUST NOT introduce any new entry form, field, or validation rule for the actions in FR-006 — each quick action MUST reuse the existing, already-implemented form and flow for that action unchanged.
- **FR-008**: The system MUST reserve quick-action slots for Add Occasion and Scan Paper that are either hidden or visibly disabled until their underlying features exist in the app, and MUST NOT allow tapping a not-yet-available slot to produce a broken screen, dead link, or crash.
- **FR-009**: The system MUST show an Insights section that displays an honest explanatory empty state (insights arrive once the AI Assistant is set up) and MUST NOT display any invented, static, or hardcoded "insight" text presented as if it were derived from the user's real data.
- **FR-010**: The system MUST show an Upcoming section that displays an honest explanatory empty state (upcoming bills, savings goals, and unsettled balances arrive once Budgets/Savings exist) and MUST NOT display any fabricated upcoming item.
- **FR-011**: The system MUST refresh the financial snapshot when the user returns to the home screen after completing a quick action or otherwise changing underlying data, so the figures shown are never stale from a prior visit.
- **FR-012**: The system MUST support a manual pull-to-refresh (or equivalent) gesture on the home screen that re-fetches both aggregates together.
- **FR-013**: The system MUST prevent a rapid repeated tap on the same quick action from triggering more than one navigation.
- **FR-014**: The system MUST present the home screen, all of its card labels, quick-action labels, and empty/error states fully localized in both Arabic and English, with correct RTL/LTR layout, number formatting, and currency formatting, and correctly themed in both light and dark mode.
- **FR-015**: The system MUST remain fully usable with no internet connection, consistent with the app's existing offline-only operation — nothing on this screen depends on network access.
- **FR-016**: The system MUST NOT alter the underlying calculation logic, data, or storage of the existing person-to-person balance totals or the finance summary — this feature only presents and coordinates already-correct data from those two existing sources.

### Key Entities *(include if feature involves data)*

- This feature introduces no new persisted entity, field, or database table. It reads two already-existing aggregates — the person-to-person balance summary (existing) and the monthly finance summary (introduced by feature 007, Income & Expense Tracking) — and presents them together on one screen. No new data is stored as a result of viewing this screen.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can see their complete financial snapshot (balance totals + this month's income/expense/net) within 1 second of opening the app on a warm start, with no further navigation required.
- **SC-002**: A user can begin any of the five quick actions (Add Expense, Add Income, Add Person, Add Money Received, Add Money Given) in a single tap from the home screen.
- **SC-003**: When one of the two data sources fails to load, 100% of the time the other data source still renders correctly and the failed one offers a working retry, verified across at least 50 simulated single-source-failure test runs.
- **SC-004**: Zero fabricated or invented content ever appears in the Insights or Upcoming sections before their underlying features (AI Assistant, Budgets, Savings) exist — verified by a dedicated test asserting only the two approved empty-state messages can ever render in those sections pre-launch of those features.
- **SC-005**: Switching the app language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, or truncation defects on the home screen.
- **SC-006**: A brand-new install with zero people and zero finance entries shows exactly one combined empty state, never two separate or contradictory empty states on the same screen.

## Assumptions

- **Navigation placement**: The existing Overview tab/route is relabeled "Home" and extended in place; the People tab remains the app's first/default tab and default landing route, unchanged. A full bottom-navigation reshuffle (e.g., promoting Home to tab 1) is an open, low-risk product decision explicitly deferred in the roadmap until the Occasions feature is real — not decided by this feature.
- **Scope boundary**: This feature is presentation/coordination only. It does not compute any new balance, income, or expense figure — both aggregates it displays are owned, computed, and correctly maintained entirely by the existing People/Transactions feature and by feature 007 (Income & Expense Tracking). This feature has a hard dependency on feature 007's finance summary capability being available.
- **Quick action scope**: All five active quick actions (Add Expense, Add Income, Add Person, Add Money Received, Add Money Given) open forms that already exist elsewhere in the app; this feature builds no new form. The two future-feature quick-action slots (Add Occasion, Scan Paper) are placeholders only, reserved so the screen's layout does not need to be redesigned when those features ship later.
- **Insights and Upcoming timing**: Both sections are intentionally non-functional placeholders for this feature's initial release. Insights becomes real once the AI Assistant feature ships; Upcoming becomes real once Budgets and/or Savings ship. Neither is a regression or an oversight — both are the explicit, honest "nothing here yet" state the product brief requires instead of a fake preview.
- **Refresh behavior**: "Refreshes when the user returns to the screen" means the two aggregates are re-fetched on the screen regaining focus/visibility (e.g., returning from a quick action's form) — this feature does not require a persistent background sync or push-based update mechanism, consistent with the app's fully offline, single-device scope.
- **Partial-failure granularity**: The two data sources (balance totals, finance summary) are the only two independently-retryable units this feature defines; a failure within one source's own internal computation is surfaced as that whole source failing, not decomposed further.
