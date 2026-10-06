# Feature Specification: Financial Trust Audit

**Feature Branch**: `022-financial-trust-audit`

**Created**: 2026-10-05

**Status**: Draft

**Input**: User description: "Comprehensive Product, Accounting, Business Logic & QA Audit of the existing Daftary app. Audit-only phase (no code changes): inspect the current implementation against existing requirements/specs, accounting principles, financial/business logic (person balances, given/received, repayments partial/full, settlements, occasions, income/expense, budgets, savings), data model, user flows, QA (stale state, cache invalidation), terminology for Egyptian users/accountants, reporting & auditability, security/privacy, offline/sync. Deliverable: a structured audit (sections 1–20, prioritized backlog, test scenarios with expected inputs/outputs, accountant and chief-accountant requirements) ending with 'DECISIONS REQUIRED FROM ME'. Constraints: don't invent functionality, don't replace architecture without evidence, deterministic calculations, AI never source of truth, keep the product simple (not an ERP)."

## Overview

Daftary already ships people-and-money tracking (001), income/expense (007), occasions (008), OCR entry (009), budgets (010), savings goals (011), a home dashboard (012), reports and data export (013), an AI assistant (014), app lock (015), multi-currency (018) and optional cloud sync (021). Each module was specified and tested on its own. Nobody has yet checked, across all modules, whether the numbers shown to the user are correct, consistent, explainable and named in words an Egyptian user understands.

This feature produces that check: an evidence-based audit document plus a prioritized remediation backlog. The audit stories (US1–US5) change no application behavior. The remediation stories (US6–US9) change only the behavior listed in [contracts/behavior-changes.md](contracts/behavior-changes.md). Items that depend on open owner decisions (Q1–Q3) are left out until they are decided.

An initial pass over the code already surfaced real risks (see [preliminary-findings.md](preliminary-findings.md)). They are seeds the audit must verify, not conclusions.

## Clarifications

### Session 2026-10-05

These were decided from the existing specs, the constitution and the current code. No owner input was needed. They set the "expected behavior" the audit measures against.

- Decided: **The person balance model stays one running net per person.** It is the sum of given minus the sum of received, over active rows. Linking a repayment to a specific debt (FIFO or per-debt allocation) is classified as an *Optional future feature*, not a gap.
- Decided: **A repayment's direction is set by the system and MUST NOT be editable.** It follows from the balance at the time of recording, the same way a transaction's kind can't be changed (001 Clarifications). If the edit form lets it be flipped, that is a *Bug*, P0 (PF-02).
- Decided: **Income, expense and budget figures count only income/expense entries.** Money given to or received from a person, occasion contributions, and savings contributions or withdrawals never count as income or expense. Any mixing is a *Bug*.
- Decided: **There are two kinds of duplicate.** A *technical duplicate* is the same save repeated (a retry, a double tap, or a sync replay); it MUST never create a second row, and if it does that is P0. A *possible user duplicate* is the same person, amount, direction and date; the expectation is a warning, never a block. A missing warning is an *Improvement*, P2.
- Decided: **Rounding.** Every money figure is in integer minor units. Percentages are for display only. Savings "required per month" rounds up (011). Any floating-point arithmetic in a path that produces money is a P1 finding.
- Decided: **Archived people.** People archived with a non-zero balance stay in the overview totals (001 Clarifications). The expectation is that the user can see which archived people make up part of a total. If they can't, it is a *Missing requirement*, P2.
- Decided: **Change history.** The app already stores the previous values on every edit and delete. The expectation is that the user can see a transaction's change history from that transaction. Because it isn't shown, this is a *Missing requirement*, P2. Income and expense entries keep **no** change history at all. That breaks the constitution's Financial Domain Override ("every financial mutation MUST be traceable via … audit metadata"), so it is **P1**.
- Decided: **Offline.** Daftary is local-first, so every financial entry, edit, delete and calculation is expected to work fully offline. Only cloud sync, email linking and the AI assistant may need a network. A financial action blocked while offline is P1.
- Decided: **Sync conflicts.** A conflicting edit to a financial record MUST NOT be resolved silently in a way that changes a balance without the user seeing it. A silent last-write-wins on money fields is P0. A visible resolution path is the expected behavior (021).
- Decided: **Exchange rates and the primary currency are settings, not ledger records.** Last-write-wins sync is accepted for them, because each rate shows when it was last updated and every converted total is labelled as converted at the current rate. No money row is changed when a rate changes. The silent-last-write-wins P0 rule above applies to records that hold money amounts (transactions, income/expense entries, savings contributions). The owner can reverse this decision. If so, it becomes a manual-conflict item like A3.
- Decided: **Sync changes must not break installed older apps.** Any change to what the server sends or answers must keep v1.0.1 and later apps syncing. Deployment order is part of the expected behavior. A change that leaves an older app with a stuck sync, or with a conflict it can't see, is P0.
- Decided: **Severity tie-break.** If a wrong money figure can appear through normal use, it is P0. If it needs an unusual but possible sequence of actions, it is P1. If the figure is correct but unclear or misleading, it is P2.
- Decided: **Terminology.** The consumer UI uses everyday Egyptian Arabic. Formal accounting terms (receivable, payable, settlement) stay in the internal model and in the accountant-facing sections of the audit only. The audit proposes wording; it changes nothing.
- Decided: **How the audit is run.** Flows are run on an Android emulator in Arabic and English, in light and dark themes. Sync is checked by tracing the code and running the existing automated tests, plus a live run against a development backend only if one is configured. Otherwise the flow is marked "traced, not executed" (SC-002).
- Clarification ended early when the owner moved on to `/speckit-plan`. Three owner questions are still open and are carried into [plan.md](plan.md) § "Owner decisions still open": Q1 (social money in the loan balance), Q2 (exchange-rate valuation) and Q3 (repayment larger than what's owed). Work that depends on them is kept separate, not assumed.
- Q: Should 022 stay audit-only, or also deliver the remediation? (S1) → A: The owner asked for implementation tasks covering the remediation (`/speckit-tasks`, 2026-10-05). FR-002 now permits the remediation waves in plan.md whose expected behavior is already settled (Waves 0–4). Plan items C1, C2 and the "block over-repayment" variant of A2 still wait on Q1–Q3 and get no tasks until decided.
- Decided: **Validation bar.** All amount-entry forms are checked for the *same* rules: amount above zero, decimal places allowed by the currency, Arabic-Indic and Western digits, thousands separators, and a very large maximum. Any difference between forms is a *Bug*, P2. Technical error text shown to the user is a *Bug*, P2 (constitution Principle VII).

## User Scenarios & Testing *(mandatory)*

The "users" of this feature are the people who act on the audit: the product owner, developers, QA, and an accountant or chief accountant reviewing the product. Each story is one slice of the audit document that is useful on its own.

### User Story 1 - Verified financial-correctness findings (Priority: P1)

The product owner wants to know, with evidence, whether any number Daftary shows can be wrong. Examples are a person's balance, the overview totals, occasion totals, budget remaining and savings progress. The audit traces every user-visible financial figure back to the rule that produces it. It runs concrete scenarios through each rule (including partial repayment, over-repayment, edit, delete, a currency change, an offline edit followed by sync, and duplicate submission) and reports every place where the result is wrong, ambiguous or depends on something it shouldn't.

**Why this priority**: Wrong or unexplainable money figures destroy user trust in a finance app, and they are the only P0 class of problem. Everything else in the audit is secondary.

**Independent Test**: Give the "Financial Logic Assessment", "Critical Bugs" and "Test Scenarios" sections to a developer with no other context. For every finding they can reproduce the defect, or confirm the rule, using only the steps, inputs and expected outputs written in the audit.

**Acceptance Scenarios**:

1. **Given** the list of user-visible financial figures, **When** the audit is complete, **Then** every figure has an entry stating its definition in plain language, what increases it, what decreases it, how edit, delete, archive and currency change affect it, and whether it can be traced back to the transactions behind it.
2. **Given** a finding classified P0 or P1, **When** a reviewer reads it, **Then** it includes reproduction steps, the expected result, the actual result (verified by running the scenario or by tracing the code), the business impact and a recommended fix direction.
3. **Given** a preliminary finding from [preliminary-findings.md](preliminary-findings.md), **When** the audit is complete, **Then** it is marked Confirmed, Refuted or Partially confirmed, with evidence. None is carried over unverified.

---

### User Story 2 - Test scenarios with exact expected numbers (Priority: P1)

QA wants a scenario catalogue for every critical calculation: exact inputs, exact expected outputs and the expected wording or status shown. QA can then prove the numbers right today and keep them right after the fixes.

**Why this priority**: Without exact expected outputs, "correct" cannot be tested. This catalogue is also the regression safety net for every later fix.

**Independent Test**: A QA engineer runs the catalogue against the current app and records pass/fail per scenario without asking anyone what the expected value should be.

**Acceptance Scenarios**:

1. **Given** each critical calculation (person net balance, overview totals, repayment direction, occasion totals and status, finance income/expense/net, budget remaining/percentage/status, savings current/remaining/required monthly/estimated date), **When** the catalogue is complete, **Then** each one has happy-path, boundary (zero, one minor unit, very large, decimal, Arabic-Indic digits), negative and regression scenarios, each with an exact numeric expected output.
2. **Given** the cross-cutting flows (offline edit and later sync, the same record edited on two devices, a retried save, archive and restore, AR/EN switch, RTL, dark mode), **When** the catalogue is complete, **Then** each flow has at least one scenario with the expected state after every step.
3. **Given** existing automated tests, **When** the audit is complete, **Then** it lists which catalogue scenarios are already covered and which are testing gaps.

---

### User Story 3 - Accountant and chief-accountant traceability review (Priority: P2)

A محاسب or رئيس حسابات looks at any balance in the app ("why is this person's balance 5,000 EGP?") and wants to rebuild it from the transactions behind it. They also want to see what changed, when and why. The audit states what such a reviewer would expect, what is missing, and the *minimum* additions that would earn their trust without turning Daftary into accounting software.

**Why this priority**: Being able to trace numbers is what separates "the app says so" from "I can verify it". It ranks after correctness, which has to come first.

**Independent Test**: An accountant reads only sections 3, 12, 18 and 19. They can say which balances they could reconcile today, which they couldn't, and why.

**Acceptance Scenarios**:

1. **Given** each aggregate figure, **When** the traceability review is complete, **Then** the audit states whether a user can see the list of transactions that make it up, filtered to the same scope (person, occasion, category, month, currency).
2. **Given** edits and deletions, **When** the review is complete, **Then** the audit states whether the history of changes is stored, whether the user can see it, and whether that is enough to explain a changed balance.
3. **Given** any recommended accounting concept (for example "opening balance", "write-off" or "rate locked at transaction date"), **When** it is proposed, **Then** it is classified as user-visible or internal-only and justified by a concrete correctness or trust problem. Concepts with no such justification are left out.

---

### User Story 4 - Terminology and Arabic/RTL review (Priority: P2)

The product owner wants every money-related term in both languages checked against one question: would a normal Egyptian user (parent, spouse, employee, small shop owner) understand it, and would an accountant consider it correct?

**Why this priority**: Unclear words for direction ("given/received", "settled") make users enter money the wrong way round. That is a correctness problem that starts in the UI.

**Independent Test**: Hand the terminology table to a native Egyptian Arabic speaker who has not used the app. They confirm whether each recommended term is clearer than the current one.

**Acceptance Scenarios**:

1. **Given** every user-facing financial term in Arabic and English, **When** the review is complete, **Then** each problematic term has a row with: current term, recommended Arabic, recommended English, why, who must understand it, and change / keep.
2. **Given** places where the same word means different things (for example "تمت التسوية" for a person's balance and for an occasion's totals), **When** the review is complete, **Then** each clash is listed with a recommended way to tell them apart.
3. **Given** Arabic RTL screens, **When** the review is complete, **Then** issues with number direction, mixed-script amounts, currency placement, Arabic-Indic digit input, chart direction and icon mirroring are listed per screen.

---

### User Story 5 - Prioritized backlog and owner decisions (Priority: P3)

The product owner wants one prioritized backlog to plan the fix features from. They also want a short list of the decisions only they can make.

**Why this priority**: This turns the findings into action. It depends on stories 1–4 being done.

**Independent Test**: Planning can schedule the next three remediation features from the backlog alone.

**Acceptance Scenarios**:

1. **Given** all findings, **When** the backlog is complete, **Then** every item has: ID, title, type (Bug / Missing requirement / Improvement / Optional future feature), severity (P0–P3), current behavior, expected behavior, business reason, technical reason, acceptance criteria, dependencies and recommended priority.
2. **Given** the "DECISIONS REQUIRED FROM ME" section, **When** the owner reads it, **Then** it contains only product or policy choices that the code, the specs and the constitution cannot settle. Each one gives options, a recommendation and what changes depending on the answer.

---

### User Story 6 - Ledger correctness fixes (Priority: P1)

A user's person balances can't be distorted by editing a repayment, by paying back more than they meant to, or by a rare currency edge case (plan A1, A2, B2).

**Why this priority**: These are the confirmed ways a balance can become wrong or misleading through normal use.

**Independent Test**: Checklist CHK026, CHK028 and CHK091 pass, and the calculation catalogue stays green.

**Acceptance Scenarios**:

1. **Given** Ahmed owes 1,000 EGP and a 400 EGP repayment has been recorded, **When** the user edits that repayment, **Then** the direction can't be changed and the balance stays 600 EGP.
2. **Given** Ahmed owes 1,000 EGP, **When** the user enters a 1,500 EGP repayment, **Then** a confirmation says "You will owe Ahmed 500 EGP" before anything is saved.

---

### User Story 7 - Sync and date integrity (Priority: P1)

Money records stay correct across two devices: a conflicting savings contribution is never silently overwritten, and dates never move across time zones (plan A3, B1).

**Why this priority**: These defects cause silent loss or misplacement of money records.

**Independent Test**: Checklist CHK110 and CHK111 pass using the fake-remote sync tests.

**Acceptance Scenarios**:

1. **Given** the same savings contribution was edited offline on two devices, **When** both sync, **Then** a conflict is listed and the version that isn't kept is preserved.
2. **Given** a transaction dated 2026-10-01 on a UTC+3 device, **When** a UTC+2 device pulls it, **Then** it shows 2026-10-01 and counts in October.

---

### User Story 8 - Traceability and complete export (Priority: P2)

A user or accountant can see how a record changed, and can export everything the app holds (plan C3, D2, D1).

**Why this priority**: This is what makes numbers explainable and reconcilable outside the app.

**Independent Test**: Checklist CHK079, CHK087, CHK088 and CHK094 pass.

**Acceptance Scenarios**:

1. **Given** an edited transaction, **When** the user taps its "Edited" marker, **Then** they see every earlier version with its timestamp.
2. **Given** occasions, budgets and savings exist, **When** the user exports, **Then** the CSV has a section for each.

---

### User Story 9 - Plain wording and safe input (Priority: P2)

Labels use everyday Egyptian Arabic; a currency change on edit is confirmed; the Arabic thousands separator is accepted; and a likely duplicate is flagged (plan E1, E3, E5, C4).

**Why this priority**: Unclear words and silent reinterpretation of amounts lead users to enter money wrong.

**Independent Test**: Checklist CHK035, CHK092, CHK103 and CHK117 pass, and the RTL screenshot comparisons change only on reworded screens.

**Acceptance Scenarios**:

1. **Given** the user types "١٬٥٠٠", **When** they save, **Then** 1,500.00 is recorded.
2. **Given** an EGP transaction is being edited, **When** the user picks USD, **Then** a no-conversion warning appears before saving.

---

### Edge Cases

The audit MUST explicitly evaluate at least these situations. Each one comes from a real rule in the current product:

- A repayment recorded when the person's balance is already zero, or is larger than what is owed (the direction flips).
- Editing a repayment's direction so it matches the original debt, which makes the debt bigger while the row is still labelled a repayment.
- Editing or deleting a transaction that a later repayment was meant to settle.
- An occasion contribution that counts toward the person's balance (a wedding gift, or نقطة) mixed with loans in the same "they owe you / you owe them" figure.
- Changing an exchange rate after transactions in that currency already exist, and what happens to old balances and totals.
- Changing the primary currency.
- One person with balances in two currencies pointing in opposite directions, with no exchange rate set.
- An archived person who still has a non-zero balance: are they in the overview totals, and are they visible?
- Deleting a person, an occasion, a category or a savings goal that has money attached.
- Dates near midnight, across a daylight-saving change, or synced between devices in different time zones.
- The same record edited offline on two devices, then synced (conflict handling and what the user sees).
- A save retried after a timeout (idempotency), and a double tap on Save.
- An older installed app (v1.0.1) syncing the same account as a newer app, after the server has been updated: it downloads a record type it doesn't know, or gets a conflict it has no screen for.
- Records already downloaded with a shifted date, before the date fix existed.
- An OCR-confirmed transaction whose scan is later deleted.
- Very large amounts, one minor unit, Arabic-Indic digits, a pasted amount with thousands separators, and a negative or zero amount.
- Budgets in months with no entries, spending against a category that has no allocation, and a budget copied to a new month.
- A savings withdrawal bigger than the current savings, a target date in the past, and contributions in a different currency from the goal.

## Requirements *(mandatory)*

### Functional Requirements

**Scope and method**

- **FR-001**: The audit MUST be based on inspecting the current product: running the app and tracing the implementation and the specs 001–021. Each finding MUST cite where the evidence came from (screen, flow or code location). Findings MUST NOT describe functionality that does not exist.
- **FR-002**: The audit itself (US1–US5) MUST NOT change application behavior, data or schema. Remediation (US6–US9) MAY change behavior, but only as described in [contracts/behavior-changes.md](contracts/behavior-changes.md) and only for plan items whose expected behavior is settled. Policy-dependent items (C1, C2, the A2 blocking variant) are excluded until the owner decides Q1–Q3.
- **FR-003**: The audit MUST compare the product against its own sources of truth (the specs, `PRODUCT.md` and the constitution) and report where these sources contradict the shipped product or each other. For example, `PRODUCT.md` says there is no sync or account, but cloud sync (021) is shipped.

**Coverage**

- **FR-004**: The audit MUST cover every financial concept the product actually uses: given, received, repayment (partial, full, over-repayment), occasion contribution (counting and non-counting), settlement, net balance, owed-to-me and I-owe totals, income, expense, category, budget allocation, unbudgeted spending, savings contribution, savings withdrawal, exchange rate and primary currency. For each concept it MUST state: meaning, where it is used, effect on each balance, reversibility, partial settlement, and behavior on edit, delete, duplicate, offline and after sync.
- **FR-005**: The audit MUST also assess concepts the product does *not* have but a consumer money app may need: refund, adjustment or correction, transfer, gift as distinct from a loan, opening balance, forgiving a debt (write-off), and linking a repayment to a specific debt. It MUST classify each as needed now, optional later, or not needed, with a reason.
- **FR-006**: The audit MUST execute or trace every user flow listed in the Input (the 29 flows: create person through sync after going online). For each flow it MUST record expected behavior, actual behavior, any defect, severity, business impact and a recommended solution.
- **FR-007**: The audit MUST check for stale-state problems by tracing the real refresh path for each list and total: new transactions appearing, totals refreshing, archive and restore updating lists, duplicate entries, more than one state holder for the same screen, mutable state, and cache invalidation. It MUST NOT assume a root cause without tracing it.
- **FR-008**: The audit MUST assess the data model: whether the stored entities and relationships can represent every concept in FR-004, and whether any fields are missing (rate at transaction time, repayment-to-debt link, reason for change, sync metadata). Structural changes MAY only be recommended when they fix a demonstrated correctness or traceability problem.
- **FR-009**: The audit MUST assess security and privacy: local data protection, app lock, what is synced and to where, what the AI assistant receives, export contents, data wipe completeness, and whether logs contain sensitive data.
- **FR-010**: The audit MUST assess offline and sync behavior: duplicate prevention, conflict detection, how conflicts are shown to and resolved by the user, partial sync, and whether any financial mutation can be applied twice or lost.
- **FR-011**: The audit MUST assess reporting and auditability. Can each total be traced to its source transactions? Are filters available (date range, person, occasion, category, currency)? Is settlement history visible? Is the change history visible? Does the export allow reconciliation outside the app?
- **FR-012**: The audit MUST assess UX for a non-technical Egyptian user: ambiguous transaction direction, unclear balances, confusing actions, missing feedback, empty states, validation, and the number of steps for common tasks. Arabic MUST be reviewed as a native RTL experience, not as translated English.
- **FR-013**: The audit MUST confirm that every financial figure is produced by deterministic rules, and that AI output is never used as, or presented as, the source of a financial number.

**Output**

- **FR-014**: The audit document MUST contain, in this order: 1 Executive Summary; 2 Current Product Assessment; 3 Accounting Assessment; 4 Financial Logic Assessment; 5 Business Logic Assessment; 6 Data Model Assessment; 7 UX/UI Assessment; 8 Arabic/RTL Assessment; 9 QA Assessment; 10 Security & Privacy Assessment; 11 Offline/Sync Assessment; 12 Reporting Assessment; 13 Missing Features; 14 Incorrect Features; 15 Recommended Improvements; 16 Critical Bugs; 17 Test Scenarios; 18 Accountant Requirements; 19 Chief Accountant Requirements; 20 Prioritized Backlog; and a closing "DECISIONS REQUIRED FROM ME" section.
- **FR-015**: Every finding MUST be classified by type (Bug / Missing requirement / Improvement / Optional future feature) and severity: P0 (financial correctness, data corruption or security), P1 (major business function broken), P2 (important UX or function issue), P3 (cosmetic or minor).
- **FR-016**: Each backlog item MUST include every field listed in User Story 5, scenario 1.
- **FR-017**: The terminology review MUST use the row format in User Story 4, scenario 1, and MUST favor plain everyday Arabic over accounting jargon in the consumer UI. Accurate accounting terms are kept for internal concepts.
- **FR-018**: The Test Scenarios section MUST give exact inputs and exact expected outputs (amounts in a stated currency, the expected status label in both languages) for every critical calculation named in User Story 2, scenario 1.
- **FR-019**: Recommendations MUST respect the existing architecture and design system, MUST NOT introduce a second state-management approach, and MUST keep the product simple. Any recommendation that adds user-visible accounting concepts MUST name the trust or correctness problem it solves.
- **FR-020**: The "DECISIONS REQUIRED FROM ME" section MUST contain only decisions that the evidence cannot settle. The audit MUST at least resolve or escalate these open policy questions:
  - Whether reciprocal social money (wedding or occasion gifts) belongs in the same balance as loans.
  - Whether a foreign-currency amount keeps the exchange rate from its transaction date or is revalued at today's rate.
  - What a "repayment" may do when it is larger than what is owed.
- **FR-021**: The audit MUST be readable by each audience on its own terms. The executive summary and backlog are for the product owner. Reproduction steps are for developers and QA. Sections 3, 18 and 19 are written for accountants without needing code knowledge.

### Key Entities

- **Audit Finding**: one verified observation. It has an ID, area (accounting, logic, data, UX, RTL, QA, security, sync, reporting), type, severity, evidence location, expected vs. actual behavior, business impact and recommendation.
- **Financial Figure**: a number shown to the user (for example "person net balance" or "budget remaining"). It has a plain-language definition, the rule that computes it, its inputs, how it can be traced back to transactions, and which findings affect it.
- **Test Scenario**: an ID, the calculation or flow it covers, preconditions, steps, exact inputs, exact expected outputs (numbers and labels in AR/EN), category (happy, boundary, negative, regression, consistency, offline, sync, localization, RTL, accessibility, performance) and whether it is already covered by automation.
- **Terminology Entry**: current term (AR/EN), recommended term (AR/EN), reason, audience, decision (change/keep).
- **Backlog Item**: derived from one or more findings, with the fields in User Story 5 scenario 1 and links to its findings and test scenarios.
- **Owner Decision**: the question, the options, the recommended option, and the impact of each option on scope.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of user-visible financial figures in the app appear in the audit with a definition, a computing rule and a traceability verdict.
- **SC-002**: 100% of the 29 listed user flows have a recorded expected/actual result. Flows that cannot be run (for example sync without a configured backend) are marked "traced, not executed" with the reason.
- **SC-003**: 100% of P0 and P1 findings include reproduction steps that a developer unfamiliar with the code can follow to reproduce the result in under 15 minutes.
- **SC-004**: Every critical calculation has at least 5 scenarios with exact expected outputs, covering at least zero, one minor unit, very large values, edit and delete.
- **SC-005**: 100% of the preliminary findings are marked Confirmed, Refuted or Partially confirmed with evidence.
- **SC-006**: The "DECISIONS REQUIRED FROM ME" section has no more than 7 items, and each item has a recommended option.
- **SC-007**: An accountant reviewer can reconcile at least one person balance, one occasion total and one monthly budget figure using only the audit and the app's own screens, or the audit explains exactly which gap stops them.
- **SC-008**: The audit stories (US1–US5) change no application source, schema or data file. The remediation stories (US6–US9) change only the behavior listed in `contracts/behavior-changes.md`, and every figure outside that list is unchanged, as proven by the calculation catalogue and the upgrade snapshot.

## Assumptions

- The audit covers the product as it is on `main` at v1.0.1 (2026-10-05), including modules shipped after `PRODUCT.md` was last updated (occasions, OCR, budgets, savings, dashboard, AI assistant, app lock, cloud sync).
- The existing per-feature specs (001–021) and their clarifications describe intended behavior. Where code and spec disagree, the audit reports the disagreement instead of picking a winner silently.
- The constitution's financial rules (integer money, deterministic calculation, AI non-authoritative, OCR confirmation, idempotent sync, Financial Domain Override) are the bar the product is measured against.
- Cloud sync can be assessed by tracing and automated tests even if no live backend session is available during the audit. Where this limits a finding, the finding says so.
- The target user is a non-accountant Egyptian individual, Arabic first. Accountant and chief-accountant perspectives are used to test whether the numbers are trustworthy, not to turn Daftary into a business ledger.
- The audit deliverable is written in English with Arabic terms inline where wording matters. A full Arabic translation of the audit is out of scope.
- Fixes whose expected behavior is settled are delivered here as US6–US9. Items that depend on the owner (C1, C2, the A2 blocking variant) and items marked "Later" or H become later features.
- The wording changes (plan E1) need the owner's sign-off on the audit's §8 terminology table before they ship.
