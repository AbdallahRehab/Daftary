# Feature Specification: Fix Archive / Unarchive Stale State

**Feature Branch**: `005-archive-state-refresh`

**Created**: 2026-09-20

**Status**: Draft

**Input**: User description: "R4 — Fix Archive / Unarchive Stale State: on the people/list screen, when a person is archived and then unarchived, the person does not immediately appear in the active list and the user has to reload/reopen the app; archive/unarchive must immediately update the visible people state, preserving sort/search/filter, with no duplicates and consistent failure handling."

## Clarifications

### Session 2026-09-20

- Q: When a person is archived (added to the archived list) or unarchived (removed from it), must the archived list's own search/filter state also be preserved and correctly reapplied, the same way FR-005 requires for the active list? → A: Yes, symmetric — the archived list's search/sort/filter must be preserved and correctly reapplied too, exactly like the active list.
- Q: FR-002 requires archiving to "remove them from the active list immediately and make them appear in the archived list immediately" — does this mean the archived list must update live even if it is already open on a different, currently-visible screen (e.g. another shell tab), or is it enough that it is correct the next time it is opened/viewed? → A: Next-view correctness only — only the screen the user is actively performing the action on (or returning to directly) must update live/immediately; a list screen that is not the currently visible screen (paused beneath the current one in the navigation stack, or in a different shell tab) just needs to be correct the next time it is viewed/reopened. This matches the app's single-visible-screen navigation model and is consistent with the equivalent Clarification in `specs/004-transaction-state-refresh/spec.md`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unarchived Person Reappears Immediately in the Active List (Priority: P1)

A user restores (unarchives) a person from the archived list and expects that person to immediately show up in the active people list, without reloading or reopening the app.

**Why this priority**: This is the exact bug reported and the core value of the fix — without it, the feature delivers nothing.

**Independent Test**: Archive a person, then unarchive them from the archived list, and verify the person appears in the active people list immediately, without navigating away, reloading, or restarting the app.

**Acceptance Scenarios**:

1. **Given** a person is currently archived, **When** the user unarchives them, **Then** that person appears in the active people list immediately.
2. **Given** a person was just unarchived, **When** the user views the active people list, **Then** exactly one entry exists for that person (no duplicates).

---

### User Story 2 - Archived List Updates Immediately in Both Directions (Priority: P1)

A user archives a person from the active list, or unarchives a person from the archived list, and expects both the active list and the archived list to immediately reflect the change — the person leaves one list and appears in the other without delay.

**Why this priority**: Symmetric, immediate correctness in both lists is required for the feature to be trustworthy; a one-directional fix (only unarchive, not archive) would leave the same class of bug half-fixed.

**Independent Test**: From the active list, archive a person and verify they disappear from the active list and appear in the archived list immediately; from the archived list, unarchive them and verify the reverse, all without reload.

**Acceptance Scenarios**:

1. **Given** a person is in the active list, **When** the user archives them, **Then** they immediately disappear from the active list and immediately appear in the archived list.
2. **Given** a person is in the archived list, **When** the user unarchives them, **Then** they immediately disappear from the archived list and immediately appear in the active list (subject to the current active-list filter, per User Story 3).

---

### User Story 3 - Search, Sort, and Filter State Remain Correct on Both Lists (Priority: P2)

A user who has an active search term, sort order, or filter applied to either the active people list or the archived people list expects archive/unarchive actions to update list content immediately while preserving their current search/sort/filter settings on whichever list(s) are affected — and a person should appear immediately in a list if they currently match that list's filter.

**Why this priority**: Important for a polished, non-jarring experience and for the fix to work in real-world usage where users commonly have a filter/search active on either list, but it is secondary to the core immediate-visibility fix (P1 stories).

**Independent Test**: Apply a search term or filter to the active people list that matches the person being unarchived, unarchive them, and verify they appear immediately without the search/filter being reset or losing its results; repeat with a filter that would exclude them and verify they do not incorrectly appear. Then apply a search term to the archived list, archive a matching person from the active list, and verify they appear immediately in the archived list's filtered results with the search term still applied.

**Acceptance Scenarios**:

1. **Given** the active list has a search term applied, **When** a person matching that search term is unarchived, **Then** they appear in the filtered results immediately and the search term remains applied.
2. **Given** the active list has a sort order applied, **When** a person is unarchived, **Then** they are inserted into the list in the correct sorted position without disrupting the existing sort.
3. **Given** the archived list has a search term or filter applied, **When** a person matching it is archived, **Then** they appear in the archived list's filtered results immediately and the search term remains applied.

---

### Edge Cases

- What happens if archiving or unarchiving fails (e.g. a storage error)? The person must remain in their original list (active or archived) with no partial state change, and the failure must be communicated to the user consistent with existing error handling.
- What happens if the user rapidly taps archive/unarchive twice on the same person? Exactly one state transition must occur, not a flicker or duplicate/conflicting state.
- What happens if the user navigates directly to a person's detail view and archives/unarchives from there, then returns to the people list? The list must reflect the change immediately upon return, consistent with the list-based flows.
- What happens if the active list is empty before an unarchive brings back the only visible person, or the archived list becomes empty after the last archived person is restored? Both lists must transition correctly to/from their empty states.
- What happens if a person is unarchived while a filter is active that would exclude them (e.g. filtering by a criterion they don't currently match)? They must correctly NOT appear in the active list view under that filter, while still being genuinely active (visible once the filter is cleared or changed).

### User Story 4 - Editing and Saving a Person Also Refreshes Correctly (Priority: P2)

A user opens an existing person's detail view, edits their details via the Person Form, and saves. They expect the People list and the Person Detail view to reflect the change immediately on return, without a manual reload.

**Why this priority**: Not the originally reported bug, but the identical `context.go()`-vs-`context.pop()` navigation defect this feature already fixes for archive/unarchive is also present in `person_form_page.dart`'s save-success path (documented as a cross-feature handoff in `specs/004-transaction-state-refresh/research.md`, "pointer for whoever plans 005"). Leaving it unfixed here would mean this feature's own bug class survives in the same feature area. P2 because it is a related-but-distinct defect, not the core archive/unarchive fix.

**Independent Test**: From a person's detail view, edit their name via the Person Form and save; verify the People list (whichever list — active or archived — the person belongs to) and the Person Detail view show the updated name immediately on return, with no reload.

**Acceptance Scenarios**:

1. **Given** a person's detail view is open, **When** the user edits and saves their details via the Person Form, **Then** the People list and the Person Detail view reflect the updated details immediately on return, without reload.
2. **Given** the Person Form's duplicate-warning sheet is shown and the user picks an existing person instead of creating a new one, **When** they are navigated to that existing person's detail view and later return to the People list, **Then** the list reflects accurate state immediately, without reload.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When a person is unarchived, the system MUST make them appear in the active people list immediately, without requiring a reload, navigation away and back, or app restart.
- **FR-002**: When a person is archived, the system MUST remove them from the active people list immediately and make them appear in the archived list immediately.
- **FR-003**: When a person is unarchived, the system MUST remove them from the archived people list immediately.
- **FR-004**: The system MUST ensure a person never appears in both the active and archived lists at the same time, and never appears more than once in either list.
- **FR-005**: The system MUST preserve the currently applied search term, sort order, and filter on both the active people list and the archived people list across an archive or unarchive action, applying them correctly to each updated list.
- **FR-006**: The system MUST prevent a single archive or unarchive action from producing more than one state transition (e.g. rapid double-tap must not toggle the state twice or create inconsistent state).
- **FR-007**: If an archive or unarchive action fails, the system MUST leave the person in their original list with no partial or inconsistent state, and MUST clearly communicate the failure to the user.
- **FR-008**: The system MUST show accurate, up-to-date active and archived people lists whenever those screens are (re)viewed, regardless of navigation path taken to reach them.
- **FR-009**: The fix MUST NOT change or regress existing correct behavior for viewing, adding, editing, searching, sorting, or filtering people, or any other people-management functionality.
- **FR-010**: When a person's details are edited and saved from the Person Form, the system MUST reliably refresh the People list (active or archived, whichever is the return destination) and the Person Detail view on return, using the same real-navigation-pop-based reload as this feature's other fixes — closing the identical `context.go()`-vs-`context.pop()` navigation defect already fixed for the transactions flow (`specs/004-transaction-state-refresh`) but left unaddressed in `person_form_page.dart`'s save-success and duplicate-pick paths.

### Key Entities *(include if feature involves data)*

- **Person**: An individual tracked in the app, with an archived/active status that determines which list they appear in.
- **People List View State**: The current search term, sort order, and filter applied independently to the active people list and to the archived people list, each of which must be preserved and correctly reapplied to its own list across archive/unarchive actions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of unarchive actions result in the person appearing in the active list within the same interaction, with zero reloads/restarts needed, across manual and automated regression testing.
- **SC-002**: 100% of archive actions result in the person disappearing from the active list and appearing in the archived list within the same interaction.
- **SC-003**: Zero instances of a person appearing in both lists, or appearing more than once in a single list, across regression testing.
- **SC-004**: Search, sort, and filter state is preserved correctly across 100% of archive/unarchive actions in regression testing.
- **SC-005**: The original reported bug (unarchived person not appearing without reload) does not reproduce in Scenario 1 of `quickstart.md` ("Unarchived person reappears immediately") or its corresponding automated regression test.

## Assumptions

- This is a correctness bug fix within the existing people-management feature, not a new feature; existing archive/unarchive business rules (who can be archived, what archiving means) otherwise remain unchanged.
- The fix reuses and corrects the existing state-management architecture already in place for the people feature, rather than introducing a new or parallel state-management approach.
- Investigation during planning confirmed this bug shares the same root cause (a fire-and-forget `context.push`/`context.go` navigation call not followed by an explicit reload) as the transaction state-refresh bug (`specs/004-transaction-state-refresh`); the smallest shared architectural fix (reload-on-return via `Navigator.pop()`-based navigation) is applied consistently, not a new mechanism. `specs/004-transaction-state-refresh/research.md` additionally identified that `person_form_page.dart` carries the identical defect and left it as an explicit pointer for this feature's planning — FR-010/User Story 4 above close that handoff as part of this feature's scope, rather than leaving it as a dangling cross-feature reference.
- "Immediately" means within the same user interaction/screen refresh cycle triggered by the archive/unarchive action, with no manual reload step.
