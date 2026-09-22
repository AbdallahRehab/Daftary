# Feature Specification: Occasions / Social Money

**Feature Branch**: `008-occasions-social-money`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V1.5 — Occasions / Social Money. Ground this in docs/project.txt section 2 (OCCASIONS / SOCIAL MONEY) and the existing 001-money-relationships-tracking spec/data-model as the reference for terminology and transaction modeling. The app currently only tracks direct one-to-one money exchanges between the user and a Person. Egyptian users also exchange money around social occasions — weddings, engagements, birthdays, newborn celebrations (سبوع/sebou), condolences, and other family/social gatherings — where the user gives or receives money from multiple people at once, tied to one named event. This feature adds an Occasion concept: a named event with a date, type, notes, attachments/photos, and a list of participants, each an existing or newly-created Person with an amount and a direction. The Occasion shows computed total received, total given, per-participant settlement status, and its own combined transaction history."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable, documented defaults in Assumptions, following the same modeling pattern established in 001-money-relationships-tracking and 007-income-expense-tracking.*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create an Occasion and Record Participants' Contributions (Priority: P1)

A user is at (or just came home from) a wedding, engagement, birthday, newborn celebration ("سبوع"), condolence gathering, or other family/social occasion where several people gave or received money. They want to create one named event and quickly log every person's amount and direction against it, instead of recording scattered, disconnected transactions.

**Why this priority**: This is the entire reason the feature exists — without the ability to group multiple people's contributions under one named social event, a user is forced back to recording occasions as unrelated one-off transactions, losing the event context ("Ahmed's Wedding") entirely.

**Independent Test**: Can be fully tested by creating a new occasion with a name, date, and type, adding three participants (existing or newly-created people) with amounts and directions, and confirming the occasion displays the correct total received, total given, and participant list.

**Acceptance Scenarios**:

1. **Given** the user wants to log "Ahmed's Wedding" on 15 September 2026, **When** they create the occasion with a name, date, and type ("wedding"), **Then** it is saved and appears in their occasions list.
2. **Given** an occasion has been created, **When** the user adds a participant by selecting an existing person (or typing a new name to create one inline, consistent with the existing person-transaction flow), entering an amount, and choosing a direction ("received from them" / "given to them"), **Then** the contribution is saved and immediately reflected in the occasion's totals.
3. **Given** "Ahmed's Wedding" has received 2,000 EGP from Ahmed, 1,000 EGP from Mohamed, 500 EGP from Mahmoud, and 1,500 EGP from Omar, **When** the user opens the occasion, **Then** it shows a total received of 5,000 EGP and lists all four participants with their individual amounts.
4. **Given** the user is adding a participant contribution, **When** they attempt to save a zero or negative amount, **Then** the system rejects the save and explains that a valid positive amount is required.
5. **Given** the user is creating an occasion, **When** they leave the type unset, **Then** the system requires a type to be chosen from the standard set or a custom one before the occasion can be saved.

---

### User Story 2 - See Each Participant's Contribution in Their Own Money History (Priority: P1)

A user wants a contribution recorded at an occasion to show up automatically in that person's overall money relationship — the same profile where their ordinary given/received transactions already live — so the person's balance always reflects the full picture, not just occasion money or only direct transactions.

**Why this priority**: Without this, the app would maintain two disagreeing pictures of "what Ahmed owes me" (one from Person balance, one from Occasions), directly undermining the core trust promise of the product. This must ship alongside User Story 1 for the feature to be safe to release.

**Independent Test**: Can be fully tested by recording a participant contribution inside an occasion, then opening that person's own profile (outside the occasion) and confirming the contribution appears in their transaction history and is included in their net balance, labeled with the occasion it came from.

**Acceptance Scenarios**:

1. **Given** Ahmed is a participant in "Ahmed's Wedding" who gave the user 2,000 EGP, **When** the user opens Ahmed's person profile, **Then** the 2,000 EGP entry appears in Ahmed's transaction history, is clearly labeled as tied to "Ahmed's Wedding," and is included in Ahmed's computed net balance exactly once.
2. **Given** a participant contribution is edited from inside the occasion (amount or direction corrected), **When** the user reopens that person's profile, **Then** the updated values are reflected there too, with no duplicate or stale entry left behind.
3. **Given** a participant contribution is removed from an occasion, **When** the user reopens that person's profile, **Then** the corresponding entry no longer appears in their history or balance.
4. **Given** the user opens a person's profile who has both ordinary transactions and occasion contributions, **When** they view the full history, **Then** both kinds are shown together in chronological order, each visually distinguishable, without the occasion contributions being a separate, disconnected list.

---

### User Story 3 - View Occasion Totals and Settlement Status (Priority: P2)

A user wants to open any past occasion and immediately understand the full financial picture: how much came in, how much went out, and whether the occasion is "settled" (reciprocated) or still has an open social balance.

**Why this priority**: Recording contributions (User Story 1) only has lasting value if the user can later trust a summarized view; this is what turns a list of entries into the "who gave me what at Ahmed's wedding" answer the product promises.

**Independent Test**: Can be fully tested by creating an occasion with a mix of received and given contributions and confirming the displayed total received, total given, net figure, and settlement status all match the underlying participant entries.

**Acceptance Scenarios**:

1. **Given** "Fatma's Wedding" recorded money given to Ahmed (1,000 EGP), Mohamed (500 EGP), and Omar (2,000 EGP), **When** the user opens the occasion, **Then** it shows a total given of 3,500 EGP, a total received of 0 EGP, and lists each participant with their amount.
2. **Given** an occasion has both received and given contributions, **When** the user views it, **Then** total received, total given, and the net difference (received − given) are all shown clearly and separately.
3. **Given** an occasion's total received equals its total given, **When** the user views it, **Then** it is labeled "Settled"; otherwise it is labeled with the outstanding direction and amount (e.g., "5,000 EGP more received than given").
4. **Given** a specific participant within an occasion, **When** the user views that participant's row, **Then** it shows that participant's own overall relationship status (they owe you / you owe them / settled) drawn from their full person balance — not just this one occasion — so the two views never contradict each other.

---

### User Story 4 - Browse, Filter, and Manage Occasions (Priority: P2)

A user wants to find a past occasion quickly (by name, type, or date), see a chronological list of all their occasions, and keep the list relevant by archiving events they no longer need to see front-and-center — without losing the history.

**Why this priority**: As the number of recorded occasions grows across years of weddings, birthdays, and other events, an unorganized flat list stops being useful; this is what keeps the feature usable at scale, but it is not required for the MVP value of logging and viewing a single occasion.

**Independent Test**: Can be fully tested by creating several occasions of different types and dates, then filtering the occasions list by type and confirming only matching occasions appear, and archiving one occasion and confirming it disappears from the default list but remains viewable in an "archived" view.

**Acceptance Scenarios**:

1. **Given** the user has recorded occasions of multiple types across several dates, **When** they open the occasions list, **Then** it is shown in reverse-chronological order (most recent first) by default.
2. **Given** the user wants to find all weddings, **When** they filter by type "wedding," **Then** only occasions of that type are shown.
3. **Given** the user wants to find a specific occasion by name, **When** they search, **Then** matching occasions appear as they type.
4. **Given** an occasion the user no longer needs to see in the active list, **When** they archive it, **Then** it disappears from the default occasions list but remains fully viewable, editable-in-place for corrections, and reachable through an explicit "archived occasions" view, and its participant contributions continue to count in the relevant people's balances.
5. **Given** the user has no occasions recorded yet, **When** they open the occasions section, **Then** a friendly empty state explains the feature and offers a direct way to create the first occasion.

---

### User Story 5 - Attach Photos to an Occasion (Priority: P3)

A user wants to keep a photo of the physical cash envelope list, the invitation, or the event itself attached to the occasion record for their own reference.

**Why this priority**: A nice-to-have memory aid that increases trust and personal value ("someone who remembers my money for me") but is not required for the core recording/reviewing value of the feature.

**Independent Test**: Can be fully tested by attaching a photo to an existing occasion and confirming it is viewable from the occasion's details afterward.

**Acceptance Scenarios**:

1. **Given** an existing occasion, **When** the user attaches a photo from their camera or gallery, **Then** it is saved and shown in the occasion's details.
2. **Given** an occasion has one or more attachments, **When** the user removes one, **Then** it is deleted from the occasion after a confirmation step and no longer appears.
3. **Given** the user is attaching a photo, **When** the device denies camera/gallery permission, **Then** the system explains why the permission is needed and how to proceed without crashing or silently failing.

---

### Edge Cases

- What happens when the same person is added as a participant more than once in the same occasion (e.g., two separate contributions from Ahmed at the same wedding)? The system MUST allow multiple distinct participant entries for the same person within one occasion (e.g., an initial contribution plus a later top-up), each recorded and displayed as its own entry, rather than forcing them into a single combined row.
- What happens when a participant is removed from an occasion after their contribution has already been individually edited from inside their person profile? Editing a contribution from either the occasion view or the person's profile view must update the same single underlying record — there is only ever one copy of the truth, never two entries that could drift apart.
- What happens when the user deletes an occasion entirely? All of its participant contributions must be removed as well (after an explicit confirmation that names the number of affected participants and their people), and every affected person's balance and history must update accordingly — an occasion is never left as a dangling reference inside a person's history.
- What happens when the user tries to delete a person who has occasion contributions but no other direct transactions? The same protection as the existing person-management rule applies: a person with any recorded history (including occasion contributions) cannot be permanently deleted, only archived.
- What happens if the occasion date is set in the future (e.g., an upcoming wedding the user is pre-planning contributions for)? It is accepted and shown as an upcoming occasion; contributions can still be recorded against it before the date arrives.
- What happens when a condolence-type occasion is recorded? Condolence contributions are not socially expected to be reciprocated the way wedding/celebration gifts are, so they default to not affecting the participant's overall person balance (see Assumptions); the user can still override this per occasion if they do want it tracked as a balance-affecting exchange.
- What happens when the same physical action (e.g., double-tapping "Save participant") could add a contribution twice? Exactly one contribution is ever created per save action, consistent with the duplicate-action protection already required for ordinary transactions.
- What happens when an occasion has zero participants (just created, none added yet)? It is saved and shown with totals of zero and an explicit "no participants yet" prompt, rather than being blocked from creation.
- What happens when numerals are entered using Arabic-Indic digits versus Western digits for a contribution amount? Both are accepted and interpreted as the same numeric value, consistent with the existing transaction entry behavior.
- What happens when the user archives a person who has occasion contributions? The person is hidden from active people lists/pickers as usual, but their name and amounts remain visible inside the occasions they participated in, and their balance keeps counting toward that occasion's and the overview's totals until settled.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create an Occasion with, at minimum, a name and a date; type, notes, and attachments are optional at creation time but a type MUST be chosen before the occasion can be considered complete (FR-002).
- **FR-002**: Users MUST choose an Occasion type from a standard set — wedding, engagement, birthday, newborn celebration ("سبوع"/sebou), condolence, celebration, other — or define a custom type, consistent with how relationship tags are customizable for people.
- **FR-003**: Users MUST be able to add a participant to an Occasion by selecting an existing Person or creating a new one inline, without leaving the occasion flow, consistent with the existing inline-person-creation pattern for transactions.
- **FR-004**: Each Occasion participant entry MUST capture an amount, a direction (received from this person at the occasion / given to this person at the occasion), and an optional note; the system MUST reject a zero or negative amount and explain why.
- **FR-005**: An Occasion participant entry MUST be recorded as a Money Transaction linked to both the participant's Person record and the Occasion (a distinct transaction kind/source: "occasion contribution"), so it is a single source of truth that appears in the person's regular transaction history and is included in their overall net balance computation — never a separate, parallel record that could disagree with the person's balance.
- **FR-006**: The system MUST allow more than one participant entry for the same Person within the same Occasion (e.g., an initial gift plus a later top-up), each tracked and displayed as its own entry.
- **FR-007**: The system MUST automatically compute and display, for every Occasion: total amount received, total amount given, and the net difference (received − given), recalculated immediately whenever a participant entry is added, edited, or removed.
- **FR-008**: The system MUST label an Occasion "Settled" when its total received exactly equals its total given, and otherwise MUST clearly show the outstanding direction and amount.
- **FR-009**: The system MUST show, for each participant listed within an Occasion, that person's own current overall relationship status (they owe you / you owe them / settled), computed from their full transaction history exactly as in the existing Person balance feature — never a separate, occasion-only balance that could contradict it.
- **FR-010**: Users MUST be able to edit a participant entry's amount, direction, or note from either the Occasion view or that person's own profile view, with the change applying to the single underlying record and immediately reflected in both places.
- **FR-011**: Users MUST be able to remove a participant entry from an Occasion after an explicit confirmation step; removal MUST delete the corresponding transaction so it no longer appears in the person's history or balance.
- **FR-012**: Users MUST be able to edit an Occasion's name, date, type, and notes after creation.
- **FR-013**: Users MUST be able to delete an entire Occasion after an explicit confirmation step that names how many participant contributions will be removed; deleting an Occasion MUST remove all of its participant contributions and update every affected person's balance and history accordingly.
- **FR-014**: Users MUST be able to archive an Occasion, removing it from the default occasions list while keeping it fully viewable, editable, and restorable through an explicit archived-occasions view; archiving an Occasion MUST NOT remove or alter its participants' contributions or balances.
- **FR-015**: Users MUST be able to view a list of all Occasions in reverse-chronological order by default, and filter/search it by name, type, and date range.
- **FR-016**: Users MUST be able to view an Occasion's complete combined transaction history (all of its participant contributions together, in chronological order), each entry showing the participant's name, amount, direction, and note.
- **FR-017**: Users MUST be able to attach one or more photos to an Occasion (e.g., a photo of the physical cash-envelope list or the event) and remove an attachment after confirmation.
- **FR-018**: By default, participant contributions from condolence-type Occasions MUST NOT be included in the participant's overall person-balance computation (they are treated as a one-time courtesy, not an expected reciprocal exchange), while contributions from all other Occasion types (wedding, engagement, birthday, newborn/sebou, celebration, other, custom) MUST be included by default; the user MUST be able to override this default on a per-occasion basis.
- **FR-019**: The system MUST prevent a single user-initiated save action (including a rapid repeated tap) from creating more than one participant entry or more than one Occasion.
- **FR-020**: The system MUST show a friendly empty state when the user has no Occasions recorded yet, and a distinct "no participants yet" state for a newly created Occasion with none added.
- **FR-021**: The system MUST keep all Occasion creation, editing, participant management, and viewing fully functional with no network connection, consistent with the app's existing offline-only operation.
- **FR-022**: The system MUST present all Occasion screens, standard occasion types, and settlement labels fully localized in both Arabic and English, with correct RTL/LTR layout, number formatting, and date formatting per the active language, and correctly themed in both light and dark mode.
- **FR-023**: The system MUST NOT alter, migrate, or merge existing 001 Person or Money Transaction records as part of this feature beyond adding the new occasion-contribution kind and its Occasion link; ordinary person-to-person transactions recorded outside an occasion remain entirely unaffected.

### Key Entities *(include if feature involves data)*

- **Occasion**: A named social event the user wants to track money around. Attributes: name, date, type (standard set or custom), optional notes, archived/active state, zero or more attachments/photos, and a computed total received, total given, net difference, and settlement status derived entirely from its linked participant contributions. Never stores totals as independently editable fields — always recomputed from source contributions, mirroring how Person balances are never independently editable in 001.
- **Occasion Participant Contribution**: A single Money Transaction (using the existing 001 transaction model, extended with a new "occasion contribution" kind/source and a link to exactly one Occasion) that also belongs to exactly one Person. Attributes: amount, direction (received from / given to, same semantics as an ordinary transaction), optional note, a per-occasion flag for whether it counts toward the participant's overall person balance (default derived from Occasion type per FR-018), plus the standard creation/edit/delete audit trail already required for every Money Transaction. This is the single record that appears both inside the Occasion's participant list and inside the Person's own transaction history — never duplicated into two separate rows.
- **Occasion Attachment**: An optional photo or image linked to an Occasion (not to an individual participant contribution), for the user's own reference. Attributes: file reference, upload timestamp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a new occasion and record contributions for at least three participants in under 90 seconds.
- **SC-002**: For any occasion, the displayed total received, total given, and settlement status always exactly match the sum of its underlying participant contributions, with zero discrepancies across test scenarios involving at least 30 participants in a single occasion.
- **SC-003**: 100% of occasion participant contributions appear correctly, exactly once, in both the occasion's participant list and the corresponding person's own transaction history and balance — never duplicated, never missing from either view.
- **SC-004**: A user can determine whether a specific occasion is fully settled or still has an outstanding balance within 2 seconds of opening it, with no manual calculation.
- **SC-005**: Deleting an occasion with 20 participant contributions correctly removes all 20 corresponding entries from the affected people's histories and balances, verified with zero leftover or orphaned records.
- **SC-006**: A user with no prior use of the feature can find the occasions section, understand its purpose from the empty state, and create their first occasion without external help, on their first attempt.
- **SC-007**: Switching the app language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, or truncation defects on any occasion screen.

## Assumptions

- **Single source of truth for money (key decision)**: Occasion participant contributions are modeled as ordinary Money Transactions (the same entity introduced in 001-money-relationships-tracking) carrying a new "occasion contribution" kind/source and a link to an Occasion, rather than as a separate, parallel record type. This was chosen specifically so that a person's balance (computed once, per 001's FR-008) and an occasion's totals can never disagree — there is exactly one row of financial truth per contribution, read from two different views (the Person profile and the Occasion detail).
- **Reciprocity and balance semantics**: Egyptian social-occasion money (نقطة/gifts at weddings, engagements, birthdays, newborn celebrations) generally carries a cultural expectation of future reciprocation, so by default it is treated exactly like an ordinary given/received transaction for balance purposes — receiving money at your own occasion nudges the ledger toward "you owe them" (a future gift), and giving money at someone else's occasion nudges it toward "they owe you," matching real social expectation. Condolence money is a documented exception (FR-018) because it carries no such reciprocity expectation in Egyptian custom; the user may override the default per occasion for any type.
- **Scope boundary**: This feature covers manual creation and management of occasions and their participant contributions only. OCR/paper-based entry into an occasion (photographing a physical guest list and auto-extracting participants) is a separate, later roadmap feature that will produce occasion participant entries for review here, not the other way around. Budgets, savings goals, and the AI assistant are out of scope.
- **Currency**: Single currency (EGP), consistent with the app's existing scope; multi-currency is out of scope for this feature.
- **Amount ceiling and precision**: Reuses the same maximum-amount validation ceiling and decimal/no-rounding-drift handling already enforced for person-to-person transactions, for consistency rather than inventing new limits.
- **Attachments**: Attachments belong to the Occasion as a whole (e.g., a photo of the full guest/cash list), not to individual participant contributions, since that matches how users actually take these photos in practice (one photo covering several names). Attachment storage/retention follows the same local-device approach as other attachments in the app; cloud backup of attachments is a future concern outside this spec.
- **Navigation placement**: Occasions need a reachable entry point from the app's main navigation (e.g., alongside People/Transactions). The exact placement is a navigation/IA decision made at planning time, not a behavioral requirement of this spec.
- **No settlement action beyond the transaction model**: Consistent with 001, "settling" an occasion or a participant's contribution is not a separate manual status flag — it is simply the natural result of the underlying balance reaching zero (optionally helped along by the user recording an ordinary repayment transaction against that person, exactly as in 001 User Story 3). There is no independent "mark occasion as settled" action.
