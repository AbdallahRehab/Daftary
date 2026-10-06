# Feature Specification: Money Relationships Tracking

**Feature Branch**: `001-money-relationships-tracking`

**Created**: 2026-09-19

**Status**: Draft

**Input**: User description: "Master product brief (docs/project.txt) for an Egyptian personal finance & social money app. This spec covers the first and most foundational pillar called out in that brief: letting a user create people/contacts and record money given to or received from them, see a clear net balance per person, and track full history until debts are settled. Occasions/social-event tracking, paper/OCR-based entry, personal budgeting, savings goals, the AI assistant, and investment education are intentionally deferred to their own future specs."

## Clarifications

### Session 2026-09-19

- Q (added 2026-10-06, feature 022 A1): Can a repayment's direction be edited? → A: No. Editing it made a repayment increase the debt while still labelled a repayment (022 research PF-02). Amount, date and note stay editable; to change direction, delete the repayment and record it again.

- Q: When a person with an outstanding (non-zero) balance is archived, should they still count toward the overview's "total owed to you" / "total you owe" figures (User Story 4)? → A: Yes, always include — archiving only hides a person from the active people list; their balance keeps counting in overview totals until it reaches zero.
- Q: Is this feature a single-device, local-only app (no login, no cross-device sync), or does it need a user account with cloud-backed sync across multiple devices? → A: Single device, local-only — no authentication or account in scope; "another session" in the sync-conflict edge case means concurrent app instances/processes on the same device, not another device.
- Q: When a user edits an existing transaction (FR-015), can they change its kind between a regular exchange and a repayment, or is the kind fixed once the transaction is created? → A: Kind is fixed at creation — to reclassify a transaction, the user deletes it and records a new one of the correct kind.
- Q: What rule should trigger the "possible duplicate" name warning when a user enters a new person's name (FR-003)? → A: Case/whitespace-insensitive prefix-or-contains match (a new name that exactly matches, starts with, or is contained within an existing person's name, ignoring case and extra whitespace) — this also covers exact matches and keeps the "Ahmed" vs. "Ahmed Ali" edge case true as written.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record a Money Transaction With a Person (Priority: P1)

A user wants to make sure they never forget a money exchange with someone they know. When money changes hands — they receive money from someone, or they give money to someone — they open the app, pick (or quickly create) that person, and log the amount and direction in a few seconds.

**Why this priority**: This is the core problem statement of the product ("someone who remembers my money for me"). Without reliable, fast capture of a single transaction, nothing else in the product has value.

**Independent Test**: Can be fully tested by creating a new person and recording one "received" and one "given" transaction against them, then confirming both appear correctly — this alone delivers the core value of "never forget a money exchange."

**Acceptance Scenarios**:

1. **Given** the user has no existing people saved, **When** they choose to record a new transaction and enter a person's name for the first time, **Then** a new person profile is created automatically and the transaction is saved against that person.
2. **Given** an existing person "Ahmed", **When** the user records that Ahmed gave them 2,000 EGP, **Then** the transaction is saved with direction "received from Ahmed", amount 2,000 EGP, and today's date by default.
3. **Given** an existing person "Ahmed", **When** the user records that they gave Ahmed 500 EGP, **Then** the transaction is saved with direction "given to Ahmed" and Ahmed's net balance updates immediately to reflect it.
4. **Given** the user is entering a transaction, **When** they attempt to save an amount of zero or a negative number, **Then** the system rejects the save and explains that a valid positive amount is required.
5. **Given** the user has no internet connection, **When** they record a transaction, **Then** the transaction is saved immediately and durably on the device, without blocking the user (this feature has no network dependency, so there is no separate "synced" state to reach).

---

### User Story 2 - View a Person's Balance and Full History (Priority: P1)

A user wants to open a specific person and instantly understand the state of their money relationship: who owes whom, how much, and the full story of how they got there.

**Why this priority**: Capturing transactions (User Story 1) is worthless if the user cannot later trust and understand the resulting picture. This is the second half of the core value proposition.

**Independent Test**: Can be fully tested by opening a person who has multiple recorded transactions and confirming the displayed net balance matches the sum of their history, with every individual transaction visible and correctly labeled.

**Acceptance Scenarios**:

1. **Given** Ahmed has been given 2,000 EGP and received 500 EGP from the user, **When** the user opens Ahmed's profile, **Then** it shows "Ahmed owes you 1,500 EGP" and lists both transactions in chronological order.
2. **Given** Mohamed was given 3,000 EGP by the user and later returned 1,000 EGP, **When** the user opens Mohamed's profile, **Then** it shows "Mohamed owes you 2,000 EGP" and both transactions are visible.
3. **Given** a person's total given equals their total received, **When** the user opens that person's profile, **Then** the relationship is clearly labeled as "Settled" rather than showing an owing direction.
4. **Given** a person has many transactions (up to the 10,000-combined-transaction ceiling in SC-005), **When** the user scrolls their history, **Then** the list is lazily rendered with no perceptible stutter — target: sustained 60fps with no single frame exceeding 32ms during a scripted scroll — and the app never becomes unresponsive.

---

### User Story 3 - Record a Repayment Against an Existing Balance (Priority: P2)

A user wants to record when a debt is paid back, in full or in part, and see the outstanding amount shrink accordingly rather than having to manually recompute it.

**Why this priority**: Debts are rarely settled in one shot. Without an easy repayment flow, users will misrecord repayments as ordinary transactions and lose track of the real remaining balance.

**Independent Test**: Can be fully tested by creating a person with an outstanding balance, recording a partial repayment, and confirming the remaining balance is reduced by exactly the repaid amount.

**Acceptance Scenarios**:

1. **Given** Ahmed owes the user 1,500 EGP, **When** the user records a 500 EGP repayment from Ahmed, **Then** Ahmed's outstanding balance becomes 1,000 EGP and the repayment appears in his history distinctly from a fresh "received" transaction.
2. **Given** Ahmed owes the user 1,500 EGP, **When** the user records a 1,500 EGP repayment, **Then** Ahmed's status becomes "Settled".
3. **Given** Ahmed owes the user 500 EGP, **When** the user records a repayment of 700 EGP (more than owed), **Then** the system accepts it and now shows that the user owes Ahmed 200 EGP, rather than blocking the entry.

---

### User Story 4 - See an Overview of Everyone I Owe and Everyone Who Owes Me (Priority: P2)

A user wants a single screen that summarizes their overall money exposure across every person, without having to open each profile one by one.

**Why this priority**: As the number of people and transactions grows, per-person browsing does not scale. A consolidated view is what turns individual records into a trustworthy personal ledger.

**Independent Test**: Can be fully tested by creating several people with different balances and confirming the overview correctly totals and groups them into "owes me," "I owe," and "settled."

**Acceptance Scenarios**:

1. **Given** three people owe the user money and two people are owed money by the user, **When** the user opens the overview, **Then** they see a total amount owed to them, a total amount they owe, and both people lists correctly grouped.
2. **Given** the user updates any transaction, **When** they return to the overview, **Then** the totals and groupings reflect the change immediately.
3. **Given** the user has no outstanding balances at all, **When** they open the overview, **Then** it clearly communicates that everything is settled rather than showing an empty or confusing screen.

---

### User Story 5 - Manage People Profiles (Priority: P3)

A user wants to keep their list of people organized: creating a profile ahead of time, editing details, tagging a relationship type, and archiving someone they no longer need to track without losing that person's history.

**Why this priority**: This is supporting/organizational functionality. It improves usability at scale but is not required to deliver the core recording/viewing value.

**Independent Test**: Can be fully tested by creating a person, editing their details, and archiving them, then confirming they disappear from active lists while their transaction history remains intact and retrievable.

**Acceptance Scenarios**:

1. **Given** the user wants to track a new relationship proactively, **When** they create a person profile with just a name, **Then** the person is saved and available to select when recording a transaction.
2. **Given** a person profile exists, **When** the user edits their name, phone number, relationship tag, or notes, **Then** the changes are saved and reflected everywhere that person appears.
3. **Given** a person has existing transactions, **When** the user attempts to permanently delete that person, **Then** the system blocks the permanent delete and offers to archive the person instead, preserving their transaction history.
4. **Given** an archived person, **When** the user looks for them later, **Then** they can still find and view that person's full history through an explicit "archived" view.

---

### User Story 6 - Correct or Remove a Mistaken Transaction (Priority: P3)

A user wants to fix a transaction they entered incorrectly (wrong amount, wrong person, wrong direction, wrong date) without losing trust in the accuracy of their overall ledger.

**Why this priority**: Data-entry mistakes are inevitable. Without a safe correction path, users will lose confidence in the whole product after the first visible error.

**Independent Test**: Can be fully tested by recording a transaction with a deliberately wrong amount, correcting it, and confirming the person's balance recalculates correctly and the change is traceable.

**Acceptance Scenarios**:

1. **Given** a transaction was saved with the wrong amount, **When** the user edits it to the correct amount, **Then** the person's balance recalculates immediately and the transaction record shows it was edited.
2. **Given** a transaction was saved against the wrong person, **When** the user deletes it, **Then** it is removed after an explicit confirmation step and both the affected person's balance and the overview update accordingly.
3. **Given** the user is about to delete a transaction, **When** the confirmation prompt appears, **Then** it clearly states this action cannot be undone before the deletion proceeds.

---

### Edge Cases

- What happens when the user tries to create a person whose name closely matches an existing person (e.g., "Ahmed" vs. "Ahmed Ali")? The system should surface a possible-duplicate warning and let the user pick the existing person instead of creating a new one, without ever silently merging two people on its own.
- What happens when the same physical/logical action (e.g., tapping "Save" twice quickly, or a retried sync after reconnecting) could create a transaction more than once? The system must guarantee exactly one transaction is ever created per user-initiated save.
- How does the system handle a repayment or transaction entered with a decimal amount (e.g., 150.50 EGP)? It must be accepted and calculated precisely, with no rounding drift in balances over time.
- How does the system handle an extremely large amount (e.g., 5,000,000 EGP)? It must be accepted, stored, and displayed accurately without overflow or truncation.
- What happens if the user tries to record a transaction against themselves (no separate person selected)? The system should prevent this, since every transaction requires a distinct counterparparty.
- What happens when a person's balance passes through exactly zero as a result of an edit or deletion? Their status must immediately reflect "Settled."
- What happens when the user deletes the only remaining transaction for a person? The person remains in the system with a zero balance and an empty history, rather than being removed.
- How does the system behave if a transaction is recorded while offline and, once back online, conflicts with another edit to the same transaction from another session (e.g., the app was force-closed and reopened, or two concurrent app processes on the same device — this feature is single-device/local-only, so this is not a cross-device conflict)? The more recent confirmed edit wins, and the user is never shown two conflicting versions of the same transaction as if both were current.
- What happens when numerals are entered using Arabic-Indic digits versus Western digits? Both must be accepted and interpreted as the same numeric value.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create a person profile with, at minimum, a name; phone number, avatar, relationship tag (e.g. family, friend, colleague, customer, supplier, other/custom), and free-text notes are optional.
- **FR-002**: Users MUST be able to create a new person inline, at the moment of recording a transaction, without leaving that flow.
- **FR-003**: The system MUST warn the user when a newly entered person name closely matches an existing person's name — specifically, when the new name exactly matches, starts with, or is contained within an existing person's name, ignoring case and extra whitespace — and let the user choose the existing person instead of creating a duplicate.
- **FR-004**: Users MUST be able to record a money transaction against a specific person, capturing: amount, direction (money given to the person / money received from the person), date (defaulting to today, editable), and an optional note.
- **FR-005**: The system MUST reject transactions with a zero or negative amount and explain why.
- **FR-006**: The system MUST support decimal amounts (at minimum to the smallest standard currency subunit) with no rounding drift across repeated calculations.
- **FR-007**: The system MUST default to Egyptian Pounds (EGP) as the transaction currency for this feature.
- **FR-008**: The system MUST automatically compute and display each person's current net balance as the sum of all money given to them minus all money received from them — a positive result means they owe the user, a negative result means the user owes them, zero means settled — without requiring the user to do any manual math.
- **FR-009**: The system MUST classify and clearly label each person's relationship status as one of: "They owe you," "You owe them," or "Settled," based solely on their current computed net balance.
- **FR-010**: Users MUST be able to view a person's complete transaction history in chronological order, with each entry showing its type, amount, direction, date, and note.
- **FR-011**: Users MUST be able to record a repayment transaction that reduces an existing outstanding balance, including a repayment smaller than the full outstanding amount (partial repayment).
- **FR-012**: The system MUST accept a repayment larger than the current outstanding balance and reflect the resulting reversed-direction balance rather than blocking the entry.
- **FR-013**: Users MUST be able to view a consolidated overview showing the total amount owed to them, the total amount they owe, and the list of people contributing to each total.
- **FR-014**: The overview and every affected person's balance MUST update immediately whenever a transaction is added, edited, or deleted.
- **FR-015**: Users MUST be able to edit an existing transaction's amount, direction, date, or note, with the edit reflected in recalculated balances and visibly marked as an edited record (not a silent overwrite). A transaction's kind (initial exchange vs. repayment) MUST NOT be changeable via edit once the transaction is created; reclassifying requires deleting the transaction and recording a new one of the correct kind. The **direction of a repayment** is likewise fixed at creation (it is inferred from the balance) and MUST NOT be changeable via edit (amended 2026-10-06 by 022 A1).
- **FR-016**: Users MUST be able to delete a transaction after an explicit confirmation step that states the action cannot be undone.
- **FR-017**: The system MUST prevent permanently deleting a person who has any recorded transactions, offering to archive that person instead so their history remains fully retrievable.
- **FR-018**: Users MUST be able to view, search, and restore archived people separately from their active people list.
- **FR-019**: Users MUST be able to search and filter their people list by name and by relationship status (they owe you / you owe them / settled).
- **FR-020**: The system MUST ensure that a single user-initiated save action (including a rapid repeated tap or a retried background sync) never results in more than one recorded transaction.
- **FR-021**: This feature has no network dependency at all (see Assumptions: single-device, local-only). Users MUST be able to record and view money transactions and balances regardless of device connectivity; every entry MUST be durably saved to the local device the instant it is recorded, and no connectivity state, app restart, or retried save MUST ever cause a transaction to be recorded more than once (see FR-020).
- **FR-022**: The system MUST display all people, transactions, amounts, and dates correctly in both Arabic (right-to-left) and English (left-to-right), according to the user's selected language.
- **FR-023**: The system MUST accept numeric input in both Arabic-Indic and Western numeral forms as equivalent values.
- **FR-024**: Archived people with a non-zero balance MUST continue to be included in the overview's totals and groupings (User Story 4) until their balance reaches zero; archiving a person MUST NOT remove their outstanding balance from the user's overall money-exposure picture.

### Key Entities

- **Person**: An individual the user has a money relationship with. Holds identifying details (name, optional phone number, avatar, relationship tag, notes), an archived/active state, and a computed net balance and status derived from their transactions. A person is never truly deleted once they have transaction history — only archived.
- **Money Transaction**: A single recorded event of money moving between the user and one Person. Holds an amount, direction (given to / received from), transaction kind (initial exchange or repayment), date, optional note, creation/edit timestamps, and edit history. Every transaction belongs to exactly one Person and is the atomic, immutable-by-default unit of financial truth — edits and deletions are explicit, confirmed, and traceable rather than silent.
- **Person Balance** *(derived, not independently editable)*: The net financial position between the user and a Person at any point in time, computed entirely from that Person's Money Transactions (sum of given minus received, adjusted by repayments — see FR-008 for the authoritative formula and sign convention). Always recalculated from source transactions rather than stored as an independently editable value, so it can never silently drift out of sync with the underlying history.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time user can create a person and record their first money transaction in under 60 seconds without external help.
- **SC-002**: For any person with recorded transactions, the displayed net balance always exactly matches the mathematical result of their full transaction history — verified with zero discrepancies across test scenarios involving at least 50 transactions per person.
- **SC-003**: 100% of transactions a user records remain individually visible in that person's history; none are ever silently merged, overwritten, or lost.
- **SC-004**: A user can determine whether a given person owes them, they owe that person, or the relationship is settled within 2 seconds of opening that person's profile, with no manual calculation.
- **SC-005**: The overview screen correctly reflects the true totals across at least 500 people and 10,000 combined transactions, with results appearing in under 2 seconds.
- **SC-006**: Zero duplicate transactions are ever produced from a single save action, including rapid repeated taps and offline entries that later sync.
- **SC-007**: Every edit or deletion of a transaction remains traceable (what changed, when) with zero silent, untraceable modifications to financial history across all tested scenarios.
- **SC-008**: In usability testing, at least 90% of participants correctly describe a person's balance status ("they owe me," "I owe them," or "settled") after viewing that person's profile for the first time, without prior explanation.

## Assumptions

- This spec covers only direct, one-to-one money relationships between the app's user and the people they add. Group/event-based money collection (weddings, engagements, and other social occasions) is a related but distinct concept and is deferred to a separate future specification, as the product brief itself flags this as an open design question.
- Paper/photo-based (OCR) transaction entry, the AI financial assistant, household budgeting, savings goals, and investment education are all out of scope for this spec and will be specified separately; this feature only concerns manually entered person-to-person transactions.
- All transactions are between the app's single user and a Person; recording a transaction between two other third parties (not involving the app's user) is out of scope for v1.
- Egyptian Pounds (EGP) is the only currency supported by this feature in v1; multi-currency support is deferred.
- The app has exactly one user per installation for this feature; shared/family ledgers where multiple app users see the same people and transactions are a future capability, not part of this spec. This feature is single-device and local-only: no login/authentication or cross-device cloud sync is in scope; all data lives on the one device, and "offline" simply means that device currently has no network connectivity.
- "Settled" status is derived automatically and continuously from the net balance reaching zero; there is no separate manual "mark as settled" action distinct from the transactions themselves in this spec (a deliberate debt write-off, if needed, is simply recorded as an adjustment-style transaction).
- Attachments (e.g., a photo of a handwritten note) may be optionally linked to a transaction as supporting context, but scanning/extracting data automatically from such an image is the separate OCR feature, not part of this spec.
