# Feature Specification: Fix Stale State After Adding Money / Transactions

**Feature Branch**: `004-transaction-state-refresh`

**Created**: 2026-09-20

**Status**: Draft

**Input**: User description: "R3 — Fix Stale State After Adding Money / Transactions: on a person's details page, after adding a new money transaction (received or given), the newly created transaction sometimes does not appear immediately and the user has to reload/reopen the app; after successful creation, Person Details must immediately reflect the new transaction and all affected totals, without duplication or state corruption on failure."

## Clarifications

### Session 2026-09-20

- Q: Should the fix also make an already-open Overview/summary screen update its balances live when a transaction is added elsewhere, or is it enough that it's correct the next time that screen is opened/viewed? → A: Next-view correctness only — only Person Details must update live/immediately; other already-open screens (e.g. Overview) just need to be correct the next time they are viewed/reopened.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - New Transaction Appears Immediately After Saving (Priority: P1)

A user viewing a person's details page adds a new "money received" or "money given" transaction. As soon as the save completes successfully, they expect to see the new transaction in the list on that same screen without any extra action.

**Why this priority**: This is the exact bug reported — it is the single most important behavior to fix, and the feature has no value without it.

**Independent Test**: Open an existing person's details page, add a "money received" transaction, and verify it appears in the transaction list immediately after the save confirmation, with no reload, navigation away, or app restart.

**Acceptance Scenarios**:

1. **Given** a person's details page is open, **When** the user successfully adds a "money received" transaction, **Then** the new transaction appears in the visible transaction list immediately.
2. **Given** a person's details page is open, **When** the user successfully adds a "money given" transaction, **Then** the new transaction appears in the visible transaction list immediately.
3. **Given** a transaction was just added, **When** the user looks at the transaction list, **Then** exactly one entry exists for that transaction (no duplicates).

---

### User Story 2 - Balance Updates Immediately (Priority: P1)

A user who just added a transaction expects the person's net balance amount and relationship-status indicator (the "they owe you" / "you owe them" / "settled" label and its `BalanceStatusBadge`) on the same screen to reflect the new transaction immediately, so they can trust what they see without double-checking by reloading.

**Why this priority**: A stale balance is as harmful as a missing transaction row for a money-tracking app — an out-of-date balance is a trust-breaking correctness issue, not a cosmetic one.

**Independent Test**: Note a person's current net balance and relationship status, add a new transaction of a known amount, and verify the displayed net balance and status update to the correct new value immediately after save, with no reload.

**Acceptance Scenarios**:

1. **Given** a person's current net balance is B, **When** the user successfully adds any transaction affecting balance, **Then** the displayed net balance immediately reflects the new correct value.
2. **Given** a transaction changes which side of zero the net balance falls on, **When** the save completes, **Then** the relationship-status label and `BalanceStatusBadge` immediately reflect the new status ("they owe you" / "you owe them" / "settled").

---

### User Story 3 - Failed Transaction Creation Does Not Corrupt State (Priority: P2)

A user attempts to add a transaction and the save fails (e.g. validation or storage error). They expect to see a clear failure indication and expect the person's details page to remain exactly as it was before the attempt — no phantom transaction, no incorrect totals.

**Why this priority**: Important for data integrity and trust, but it is a secondary/edge path relative to the primary "successful add" bug being fixed — hence P2.

**Independent Test**: Trigger a failed transaction save (e.g. via an invalid state the system rejects), and verify the transaction list and totals on the person's details page are unchanged and no partial/duplicate entry was created.

**Acceptance Scenarios**:

1. **Given** a person's details page is open, **When** a transaction save fails, **Then** no new transaction appears in the list and totals remain unchanged.
2. **Given** a transaction save failed, **When** the user retries and it succeeds, **Then** exactly one transaction is created (the earlier failed attempt did not leave a partial record).

---

### Edge Cases

- What happens if the user adds a transaction, then immediately navigates away from and back to the person's details page? The correct, up-to-date state must still be shown (not a stale cached snapshot from before the add).
- What happens if the user adds a transaction while another screen showing related data (e.g. an overview/summary screen) is also open or navigated to afterward? That screen's relevant totals must also be correct the next time it is viewed, consistent with the person's details page.
- What happens if the user rapidly submits the same transaction twice (e.g. double-tap on save)? Exactly one transaction must be created, not two.
- What happens if the transaction list is empty before this add (first transaction for a person)? The list must transition correctly from its empty state to showing the one new transaction.
- What happens if the app is navigated away from the person's details page before the save operation completes? The result must still be reflected correctly the next time that page is shown, without loss or duplication.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After a transaction is successfully created, the system MUST display the new transaction in the Person Details transaction list immediately, without requiring the user to reload, navigate away and back, or restart the app.
- **FR-002**: After a transaction is successfully created, the system MUST update the Person Details net balance amount and the relationship-status indicator (the "they owe you" / "you owe them" / "settled" label and its `BalanceStatusBadge`) immediately to reflect the new transaction.
- **FR-003**: The system MUST create exactly one persisted transaction per successful save, with no duplicate entries appearing on screen or in storage.
- **FR-004**: The system MUST prevent a transaction from being submitted more than once from a single user save action (e.g. rapid double-tap).
- **FR-005**: If transaction creation fails, the system MUST leave the Person Details transaction list and totals exactly as they were before the attempt — no phantom transaction and no partial total update.
- **FR-006**: If transaction creation fails, the system MUST clearly communicate the failure to the user in a way consistent with the app's existing error handling.
- **FR-007**: The system MUST show accurate, up-to-date transaction and total data on the Person Details page whenever it is (re)viewed, regardless of navigation path taken to reach it.
- **FR-008**: The fix MUST NOT change or regress existing correct behavior for viewing, editing, or removing transactions, or any other Person Details functionality.

### Key Entities *(include if feature involves data)*

- **Transaction**: A single money-received or money-given record tied to a person, with an amount, direction, and timestamp; the entity whose creation must be immediately visible.
- **Person Balance Summary**: The derived net balance amount and relationship-status indicator shown on Person Details (`PersonBalance.net` and its derived `status`), computed from that person's transactions and required to stay in sync with them.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of successfully created transactions appear on the Person Details screen within the same interaction, with zero reloads/restarts needed, across manual and automated regression testing.
- **SC-002**: 100% of successful transaction creations result in a correct, immediately visible net balance amount and relationship-status indicator, with zero stale-balance occurrences in regression testing.
- **SC-003**: Zero duplicate transactions are produced across repeated/rapid submission attempts in regression testing.
- **SC-004**: Zero phantom transactions or incorrect totals result from a failed transaction creation in regression testing.
- **SC-005**: The original reported bug (transaction not appearing without reload) does not reproduce in any of the regression test scenarios defined for this feature.

## Assumptions

- This is a correctness bug fix within the existing money-tracking feature, not a new feature; existing transaction creation, storage, and display behavior otherwise remains unchanged.
- The fix reuses and corrects the existing state-management architecture already in place for people and transactions, rather than introducing a new or parallel state-management approach.
- "Immediately" means within the same user interaction/screen refresh cycle triggered by the save action, with no manual reload step, network permitting.
- Confirmed via clarification: any other screens that display the same or derived data — namely the Overview screen (`OverviewPage`) and the People list (`PeopleListPage`), both of which show per-person or aggregate balance summaries — only need to be correct the next time they are viewed after the fix; live refresh of an already-open, in-background screen is explicitly out of scope for this feature unless it shares the same root cause as this bug.
