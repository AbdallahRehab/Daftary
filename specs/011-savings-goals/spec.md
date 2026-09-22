# Feature Specification: Savings Goals

**Feature Branch**: `011-savings-goals`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V1.5 — Savings Goals. Ground this in docs/project.txt section 6 (SAVINGS). A user wants named savings goals (e.g. Emergency Fund: target 100,000 EGP, current 35,000 EGP, remaining 65,000 EGP, monthly contribution 5,000 EGP, estimated completion 13 months), support for multiple concurrent goals (new car, wedding, vacation, new phone, home furniture, education, etc.), and deterministic 'what-if' recalculation ('what if I save X more per month', 'how long until I reach my goal', 'how much do I need to save every month'). All projections must be deterministic arithmetic per constitution Principle VIII — no AI/LLM estimation in this V1.5 tier. Decide how goal progress is tracked (a single editable current-amount figure vs. a logged contribution history) and document the decision, staying consistent with how this codebase already treats every other balance/total as derived from a transaction-like history rather than a freely-editable number."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable, documented defaults in Assumptions, following the pattern established in prior specs.*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a Savings Goal (Priority: P1)

A user wants to name something they're saving toward — an emergency fund, a new car, a wedding, a vacation — set a target amount, and optionally set a monthly contribution or a target date, so they have a concrete plan instead of a vague intention to "save more."

**Why this priority**: This is the entire starting point of the feature — without a named goal and a target, there is nothing to track progress against or calculate a plan for.

**Independent Test**: Can be fully tested by creating a goal with a name and target amount, optionally a starting amount already saved and a monthly contribution, and confirming it's saved and retrievable with a correctly computed remaining amount and estimated completion.

**Acceptance Scenarios**:

1. **Given** the user wants to start an emergency fund, **When** they create a goal named "Emergency Fund" with a target of 100,000 EGP and a monthly contribution of 5,000 EGP, **Then** the goal is saved, remaining shows 100,000 EGP, and estimated completion shows 20 months.
2. **Given** the user already has some money set aside before starting to track it in the app, **When** they set a starting amount of 35,000 EGP while creating the goal above, **Then** remaining recalculates to 65,000 EGP and estimated completion recalculates to 13 months.
3. **Given** the user is creating a goal, **When** they enter a target amount of zero or a negative number, **Then** the system rejects it and explains why.
4. **Given** the user knows *when* they want to reach a goal but not how much to save monthly, **When** they set a target date instead of a monthly contribution, **Then** the system computes and shows the required monthly contribution to reach the target by that date.
5. **Given** the user wants to categorize their goal, **When** they pick from common goal types (emergency fund, new car, wedding, vacation, new phone, home furniture, education, other) or leave it as a plain custom name, **Then** the goal is saved with that type, used only for a representative icon/visual — never a behavioral difference in the calculations.
6. **Given** the user is creating a goal, **When** they set neither a monthly contribution nor a target date, **Then** the system still saves the goal (with no estimated completion shown yet) and clearly prompts that setting one of the two is what unlocks a completion estimate.

---

### User Story 2 - Log Contributions and Track Progress (Priority: P1)

A user wants to record money they've actually put toward a goal — and occasionally money they've had to take back out — and see their current saved amount, remaining amount, and updated estimated completion reflect reality, not just the original plan.

**Why this priority**: A goal with only a starting/target figure and no way to log real progress over time quickly goes stale and stops being trustworthy — this is what keeps the feature accurate as the user actually saves.

**Independent Test**: Can be fully tested by creating a goal, logging several contributions (and one withdrawal), and confirming the current amount, remaining amount, and estimated completion all recalculate correctly from that history.

**Acceptance Scenarios**:

1. **Given** a goal with a current amount of 35,000 EGP, **When** the user logs a 5,000 EGP contribution, **Then** the current amount becomes 40,000 EGP, remaining decreases by 5,000 EGP, and the estimated completion recalculates based on the new remaining amount and the goal's monthly contribution.
2. **Given** the user needs to record putting in an amount that doesn't match their usual monthly contribution (e.g. a bonus), **When** they log a one-off contribution of any positive amount, **Then** it is accepted and reflected immediately, distinct from (but shown alongside) their regular monthly contributions in the goal's history.
3. **Given** the user had to dip into a goal for an unrelated expense, **When** they log a withdrawal, **Then** the current amount decreases by that amount and the goal's history clearly shows it as a withdrawal, distinct from a contribution.
4. **Given** a goal's current amount is 10,000 EGP, **When** the user attempts to withdraw 15,000 EGP, **Then** the system rejects it and explains that a withdrawal cannot exceed the currently saved amount.
5. **Given** a goal's current amount reaches or exceeds its target amount, **When** the user views the goal, **Then** it is clearly marked as achieved/completed, with a positive, celebratory visual treatment rather than an over-budget-style warning.
6. **Given** the user views a goal's full contribution history, **When** they open it, **Then** every contribution and withdrawal is listed chronologically with its amount, type, date, and optional note.
7. **Given** the user made a mistake logging a contribution (wrong amount, wrong date), **When** they edit or delete that entry, **Then** the goal's current amount, remaining, and estimated completion all recalculate immediately to reflect the correction.

---

### User Story 3 - Run "What If" Scenarios (Priority: P2)

A user wants to explore, without committing to anything, how changing their monthly contribution would change when they'd reach a goal, or how much they'd need to save monthly to hit a specific target date — so they can make an informed decision about their own budget.

**Why this priority**: This is the feature's signature "help me plan" value beyond simple tracking (User Stories 1-2 already deliver real value on their own), directly answering the product brief's own example questions.

**Independent Test**: Can be fully tested by opening a goal's what-if calculator, entering a hypothetical higher monthly contribution, and confirming the recalculated estimated completion date is correct and mathematically consistent — with nothing saved to the actual goal unless the user explicitly applies it.

**Acceptance Scenarios**:

1. **Given** a goal with remaining amount 65,000 EGP and a monthly contribution of 5,000 EGP (13 months to completion), **When** the user asks "what if I save 1,000 EGP more per month," **Then** the system shows the recalculated monthly contribution (6,000 EGP) and its new estimated completion (11 months), without changing the goal's actual saved plan.
2. **Given** the same goal, **When** the user instead asks "what monthly contribution do I need to finish in 10 months," **Then** the system computes and shows the required monthly contribution (6,500 EGP) for that target.
3. **Given** the user has explored a what-if scenario they like, **When** they choose to apply it, **Then** the goal's actual monthly contribution (and/or target date) is updated to the scenario's values, and this is the only way a what-if exploration ever changes the real goal.
4. **Given** the user asks a what-if question that would require an impossible input (e.g. a monthly contribution of zero or negative, or a target date already in the past), **When** they submit it, **Then** the system rejects it with a clear explanation rather than showing a nonsensical or infinite result.
5. **Given** a goal that has already been achieved, **When** the user opens its what-if calculator, **Then** it clearly explains there's nothing left to plan for and does not offer a misleading recalculation.

---

### User Story 4 - Manage Multiple Concurrent Goals (Priority: P2)

A user saving toward several things at once — an emergency fund, a vacation, a new phone — wants to see all of them together, understand their combined savings picture, and organize goals they're no longer actively pursuing.

**Why this priority**: As soon as a user has more than one goal, a single-goal-at-a-time experience stops scaling; this is what makes the feature usable for how people actually save (several priorities simultaneously), though a single goal is already fully useful without it.

**Independent Test**: Can be fully tested by creating several goals with different targets/progress, opening a goals overview, and confirming it correctly lists and totals them.

**Acceptance Scenarios**:

1. **Given** the user has three active goals with different current/target amounts, **When** they open the goals overview, **Then** they see each goal listed with its progress, and a combined total currently saved across all goals.
2. **Given** the user wants to stop actively tracking a goal without losing its history (e.g. they paused saving for a vacation), **When** they archive it, **Then** it disappears from the active goals list but remains fully viewable, editable, and restorable through an explicit archived-goals view, with its contribution history intact.
3. **Given** the user wants to permanently remove a goal they created by mistake, **When** they attempt to delete a goal with recorded contributions, **Then** the system blocks the permanent delete and offers to archive it instead, preserving its history — consistent with how the app already protects a Person's transaction history (001).
4. **Given** a goal has zero recorded contributions, **When** the user deletes it, **Then** it is permanently removed with no history to preserve.
5. **Given** the user has no savings goals yet, **When** they open the goals section, **Then** a friendly empty state explains the feature and offers a direct way to create the first goal.

---

### Edge Cases

- What happens when a goal's target amount is edited after contributions have already been logged? Remaining, percentage progress, and estimated completion all recalculate immediately from the new target and the existing contribution history — nothing about the logged history itself changes.
- What happens when a user sets both a monthly contribution and a target date that don't mathematically agree (e.g. the monthly contribution is too low to reach the target by that date)? The system shows both figures honestly alongside a clear shortfall indication (e.g. "at this rate, you'll reach this 4 months after your target date") rather than silently picking one over the other or hiding the mismatch.
- What happens when a user sets a target date that has already passed? The system rejects it at entry time with a clear explanation, since a plan cannot be computed for a date already in the past.
- What happens when a goal's monthly contribution is left unset and no target date is set either (Acceptance Scenario 6, User Story 1)? The goal is still fully usable for logging contributions and tracking current/remaining/percentage progress; only the estimated-completion figure is unavailable until one of the two is set.
- What happens when the user logs a contribution with a decimal amount, or an extremely large amount? Handled with the same precision and validation ceiling already established for money throughout the app (001/007).
- What happens when two goals happen to have the same name (e.g. two different "Vacation" goals in different years)? This is allowed — goal names are not required to be unique, unlike Person names, since there's no duplicate-identity risk the way there is with people.
- What happens when a goal is fully achieved and the user keeps logging contributions toward it anyway (e.g. still auto-saving into the same account)? Additional contributions are accepted and simply increase the current amount past the target — the goal's achieved status doesn't block further logging, and the user can separately choose to raise the target (a "stretch goal") if they want new planning figures.
- What happens when the estimated-completion calculation would produce an extremely long timeline (e.g. a 1 EGP monthly contribution against a 1,000,000 EGP target)? The system still computes and displays it accurately (e.g. in years, not an absurd number of months) rather than erroring or truncating, though the "at this rate" framing itself is expected to prompt the user to reconsider their inputs.
- What happens when the app's language or theme changes while an achieved-goal celebratory state or a what-if calculator is open? Both must remain correctly laid out, legible, and fully localized in RTL/LTR and both themes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create a savings goal with, at minimum, a name and a positive target amount; a goal type (from a standard set — emergency fund, new car, wedding, vacation, new phone, home furniture, education, other — or a plain custom name with no type), a starting amount already saved, a monthly contribution, and a target date are all optional at creation.
- **FR-002**: The system MUST reject a target amount that is zero or negative, and MUST reject a monthly contribution or a starting amount that is negative (zero is acceptable for a starting amount).
- **FR-003**: The system MUST reject a target date that is on or before the current date, with a clear explanation.
- **FR-004**: The system MUST track a goal's current saved amount as the sum of its logged contributions minus its logged withdrawals — never as an independently, freely-editable single figure — so it can never silently drift out of sync with the goal's own history, consistent with how every other balance/total in this app (person balances, occasion totals, budget actuals) is derived rather than directly settable.
- **FR-005**: Users MUST be able to log a contribution (a positive amount added toward a goal) with an amount, date (defaulting to today), and optional note.
- **FR-006**: Users MUST be able to log a withdrawal (a positive amount removed from a goal's progress) with the same fields as a contribution; the system MUST reject a withdrawal whose amount exceeds the goal's current saved amount at the time it's logged, explaining why.
- **FR-007**: The system MUST reject a zero or negative amount for any contribution or withdrawal, and MUST enforce the same decimal-precision and maximum-amount rules already established for money throughout the app (001/007).
- **FR-008**: Users MUST be able to view a goal's full contribution/withdrawal history in chronological order, each entry clearly labeled by type (contribution vs. withdrawal), with its amount, date, and note.
- **FR-009**: Users MUST be able to edit or delete a previously logged contribution/withdrawal, with the goal's current amount, remaining amount, percentage progress, and estimated completion all recalculating immediately to reflect the change.
- **FR-010**: The system MUST automatically compute and display, for every goal that has a monthly contribution set: the estimated number of months (and a corresponding estimated completion date) needed to reach the target from the current amount, using simple deterministic division (remaining amount ÷ monthly contribution, rounded up to the next whole month) — never an AI/LLM-estimated figure.
- **FR-011**: The system MUST automatically compute and display, for every goal that has a target date set but no monthly contribution, the required monthly contribution to reach the target by that date, using simple deterministic division (remaining amount ÷ number of whole months remaining until the target date).
- **FR-012**: When a goal has both a monthly contribution and a target date set and they mathematically disagree (the contribution-derived completion estimate falls after the target date), the system MUST clearly show both figures together with an honest shortfall indication, never silently favoring one over the other or hiding the mismatch.
- **FR-013**: Users MUST be able to run a "what if I save a different amount per month" calculation for any active, unachieved goal, seeing the recalculated estimated completion for a hypothetical monthly contribution, without altering the goal's actual saved monthly contribution unless they explicitly apply it.
- **FR-014**: Users MUST be able to run a "what monthly contribution do I need to finish by a given date" calculation for any active, unachieved goal, seeing the recalculated required monthly contribution for a hypothetical target date, without altering the goal's actual saved target date unless they explicitly apply it.
- **FR-015**: The system MUST let the user explicitly apply a what-if scenario's values to the goal's actual monthly contribution and/or target date; this MUST be the only mechanism by which exploring a what-if scenario changes the goal's real plan.
- **FR-016**: The system MUST reject a what-if input that is itself invalid (zero/negative hypothetical contribution, a past hypothetical target date) with the same clarity as FR-002/FR-003, and MUST clearly explain — rather than offer a misleading recalculation — when the user opens the what-if calculator for a goal that has already been achieved.
- **FR-017**: The system MUST automatically mark a goal as "achieved" the moment its current amount (FR-004) reaches or exceeds its target amount, and MUST display this with a distinct, positive visual treatment rather than the vocabulary used for over-budget or warning states elsewhere in the app.
- **FR-018**: The system MUST continue to accept further contributions/withdrawals against an already-achieved goal (Edge Cases) without blocking the log action or removing its achieved status, unless a later edit/withdrawal brings the current amount back below the target, in which case the achieved status is removed automatically until it is reached again.
- **FR-019**: Users MUST be able to view a consolidated overview of all active goals showing each goal's progress and a combined total currently saved across all of them.
- **FR-020**: Users MUST be able to archive a goal, hiding it from the active goals list while preserving it, its full contribution history, and its computed figures, retrievable through an explicit archived-goals view; an archived goal MUST continue to accept edits to its history (e.g. correcting a past entry) even while archived.
- **FR-021**: The system MUST prevent permanently deleting a goal that has any logged contribution or withdrawal, offering to archive it instead; a goal with zero logged entries MAY be permanently deleted.
- **FR-022**: The system MUST prevent a single user-initiated save action (including a rapid repeated tap) from creating more than one goal or more than one contribution/withdrawal entry.
- **FR-023**: The system MUST show a friendly empty state when the user has no savings goals yet, explaining the feature and offering a direct way to create the first one.
- **FR-024**: The system MUST keep all goal creation, contribution logging, what-if calculation, and viewing fully functional with no network connection, consistent with the app's existing offline-only operation.
- **FR-025**: The system MUST present all savings-goal screens fully localized in both Arabic and English, with correct RTL/LTR layout, number formatting, currency formatting, and date formatting per the active language, and correctly themed in both light and dark mode.
- **FR-026**: The system MUST NOT alter, migrate, or merge any existing `MoneyTransaction`/`Person` (001), `FinanceEntry`/`Category` (007), `Occasion` (008), or `Budget` (010) data, records, or calculations as part of this feature; savings goals are an entirely independent ledger.

### Key Entities *(include if feature involves data)*

- **Savings Goal**: A named target the user is saving toward. Attributes: name, optional goal type (a representative icon/label only — never a behavioral difference in calculation), target amount, optional monthly contribution, optional target date, archived/active state, achieved state (derived, not independently settable — FR-017), and its own contribution/withdrawal history. Current amount, remaining amount, percentage progress, and estimated completion are all derived from the goal's target/monthly-contribution/target-date fields plus its Savings Contribution history — never independently stored as mutable figures (FR-004).
- **Savings Contribution**: A single logged deposit or withdrawal against one Savings Goal. Attributes: amount (always positive), type (contribution or withdrawal), date, optional note, creation/edit timestamps. Mirrors the same "atomic, traceable, edits are explicit" pattern already established for `MoneyTransaction` (001) and `FinanceEntry` (007) — never a value the user edits by simply overwriting the goal's current-amount figure directly.
- **What-If Scenario** *(ephemeral, not persisted)*: A hypothetical monthly-contribution or target-date input the user explores against an existing goal's current state, producing a recalculated estimated-completion or required-monthly-contribution figure. Has no effect on the real Savings Goal unless explicitly applied (FR-015), and is never itself saved as a record — it exists only for the duration of the calculation/interaction.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a new savings goal with a target and a monthly contribution, and see a correct estimated completion, in under 45 seconds.
- **SC-002**: For any goal, the displayed current amount always exactly matches the sum of its contribution history minus its withdrawal history, with zero discrepancies across test scenarios involving at least 50 logged entries on a single goal.
- **SC-003**: For any goal with a monthly contribution set, the displayed estimated-completion figure always exactly matches the deterministic formula in FR-010, verified across at least 20 varied target/current/contribution combinations with zero discrepancies.
- **SC-004**: A user can run a what-if scenario and see a recalculated result in under 5 seconds of interaction, with the underlying goal provably unchanged (re-fetching the goal shows identical values) unless the user explicitly applied the scenario.
- **SC-005**: A user managing 5 concurrent goals can determine their combined total currently saved within 2 seconds of opening the goals overview, with no manual calculation.
- **SC-006**: 100% of contributions and withdrawals a user logs remain individually visible in that goal's history; none are ever silently merged, overwritten, or lost.
- **SC-007**: Switching the app language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, or truncation defects on any savings-goal screen, including the achieved-goal celebratory state and the what-if calculator.

## Assumptions

- **Progress is a derived ledger, not an editable number (key decision)**: Consistent with how this codebase already treats every other running total — Person balances (001), Occasion totals (008), Budget actuals (010) — a goal's current amount is always computed from its Savings Contribution history, never a field the user directly overwrites. This was chosen specifically so a goal's progress can never silently drift from an auditable record of how it got there, matching the constitution's Financial Domain Override and this codebase's own established precedent (FR-004).
- **No automatic link to Budgets or the general Transactions ledger**: Consistent with 010's own Assumptions (which already declined to auto-link Budgets and Savings Goals), Savings Contributions are an entirely independent ledger from `MoneyTransaction` (001) and `FinanceEntry` (007). A user may separately choose to record a "Savings" budget category or expense entry for their own household-budgeting purposes, but this feature does not read from or write to either — avoiding a premature bidirectional dependency between three already-independent features, exactly the same reasoning 010 used for its own relationship to this feature.
- **Deterministic arithmetic only**: All estimated-completion and required-monthly-contribution figures (FR-010/FR-011/what-if calculations) are computed by simple, documented, deterministic division/date arithmetic — this V1.5 roadmap tier has no AI/LLM integration at all (constitution Principle VIII/IX), and the product's own roadmap places any AI-assisted financial insight in a later tier.
- **Rounding convention**: Estimated months are always rounded **up** to the next whole month (e.g. 12.1 months displays as 13 months) rather than truncated or rounded to nearest, because a plan that under-promises completion time is safer and more honest than one that over-promises — the user reaches their goal on or before the estimate, never after.
- **Goal type is cosmetic only**: The standard goal-type set (emergency fund, new car, wedding, vacation, new phone, home furniture, education, other) drives only a representative icon/label, exactly like `Person.relationshipTag` and `Occasion.type` in prior specs — it has no effect on any calculation, validation rule, or default behavior.
- **Currency**: Single currency (EGP), consistent with the app's existing scope; multi-currency is out of scope.
- **Amount ceiling and precision**: Reuses the same maximum-amount validation ceiling and decimal/no-rounding-drift handling already enforced for `MoneyTransaction`/`FinanceEntry` amounts, for consistency rather than inventing new limits.
- **No goal-name uniqueness constraint**: Unlike `Person` (where near-duplicate names risk creating a confusing split identity for a real person), two goals may share the same name with no warning — there is no equivalent identity risk for a goal.
- **Navigation placement**: Savings Goals needs a reachable entry point from the app's main navigation. The exact placement is a navigation/IA decision made at planning time, not a behavioral requirement of this spec.
