# Quickstart: Validate the Archive/Unarchive Stale-State Fix

**Feature**: `005-archive-state-refresh` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)

This is a validation guide, not an implementation guide — it proves the three user stories and the edge cases work end-to-end. See `data-model.md` for the state fields referenced and `research.md` for why each scenario is expected to behave this way.

## Prerequisites

- A working checkout with `flutter pub get` already run.
- At least 3 test people created in the active list, one with a relationship-status filter match (e.g. one "they owe you", one "settled") and distinct names for search testing.
- Run on a simulator/device: `flutter run`, or drive the scenarios below as `flutter test` (unit/widget/bloc) plus one `integration_test` run:
  ```
  flutter test test/features/people/presentation/cubit/person_list_cubit_test.dart
  flutter test test/features/people/presentation/cubit/archived_people_cubit_test.dart
  flutter test test/widget/
  flutter test integration_test/archive_state_refresh_flow_test.dart -d <device>
  ```

## Scenario 1 — Unarchived person reappears immediately (User Story 1, P1)

1. From the People tab (`/`), archive a person (tap the archive icon on their row).
2. Tap the archived-list icon in the AppBar → `/people/archived`.
3. Tap **Restore** on that person.
4. Tap back (do **not** pull-to-refresh, restart the app, or switch tabs and back).

**Expected**: The person appears in the active list immediately upon returning — no manual reload step. Confirms FR-001 and closes the exact reported bug (SC-005).

**Expected (no duplicates)**: The person appears exactly once. Confirms Acceptance Scenario 2 / FR-004.

## Scenario 2 — Both directions, both lists, immediate (User Story 2, P1)

1. From the active list, archive a person. **Expected**: they disappear from the active list immediately (no navigation needed — this direction already worked pre-fix, per research.md Decision 1, and must keep working).
2. Navigate to `/people/archived`. **Expected**: the person appears there immediately (fresh screen, always worked).
3. Restore them from the archived list. **Expected**: they disappear from the archived list immediately (self-list refresh, already worked).
4. Return to the active list (back navigation). **Expected**: they reappear in the active list immediately — this is the fixed direction (Scenario 1 repeated as the "both directions" check).

Confirms FR-002, FR-003, SC-001, SC-002, SC-003.

## Scenario 3 — Search/sort/filter preserved on both lists, both directions (User Story 3, P2)

**Active list search preserved across an unarchive:**
1. On the active list, type a search term that matches an archived person's name (e.g. their first name) — the list correctly shows no match (they're archived).
2. Navigate to `/people/archived`, restore that person, return to the active list.
3. **Expected**: the search box still shows the same typed term, and the restored person now appears in the (still-filtered) results, matching the term. The list was not reset to unfiltered. Confirms Acceptance Scenario 1 / FR-005.

**Active list sort preserved across an unarchive:**
1. Restore a person whose name sorts in the middle of the current active-list names.
2. **Expected**: they appear in correct alphabetical position, not appended at the end. Confirms Acceptance Scenario 2.

**Archived list search preserved across an archive (symmetric — Clarifications 2026-09-20):**
1. On `/people/archived`, type a search term that would match a person still in the active list once archived.
2. Without clearing that search term, go back to the active list, archive that matching person, return to `/people/archived`.
3. **Expected**: the archived list's search box still shows the same term, and the newly archived person appears in the filtered results. Confirms Acceptance Scenario 3.

**Filter correctly excludes a non-matching restore:**
1. Apply a relationship-status filter on the active list (e.g. "Settled") that the person being restored does not currently match.
2. Restore that person from the archived list, return to the active list.
3. **Expected**: the person does **not** appear while that filter is active (they are genuinely active underneath — clear/change the filter and they appear). Confirms the spec's edge case on filtered exclusion.

## Scenario 4 — No duplicate transition on rapid double-tap (FR-006)

1. On the active list, rapidly double-tap the archive icon on the same person (as fast as the UI allows, e.g. two taps within one frame using a widget/integration test's `tester.tap()` twice without a `pump()` in between).
2. **Expected**: exactly one archive transition occurs — the person ends up archived (not toggled back to active), no error, no duplicate row, no UI flicker between two intermediate states. Repeat for rapid double-tap **Restore** on the archived list.

Confirms FR-006; verify at the Cubit level too — `PersonListCubit`/`ArchivedPeopleCubit`'s `processingPersonId` guard (data-model.md) should cause the second concurrent call to no-op rather than invoke the use case twice.

## Scenario 5 — Archive/unarchive-triggered failure leaves state untouched (FR-007)

1. Simulate a storage failure on `archivePerson`/`restorePerson` (e.g. a faked repository returning `Left(CacheFailure(...))` in a widget/bloc test, since there is no in-app way to force a real Drift I/O error).
2. **Expected**: the person remains in their original list (no optimistic removal), `errorMessage` is set and surfaced to the user (existing error-presentation pattern — snackbar/`AppEmptyView`), and `processingPersonId` is cleared so the control is tappable again.

## Scenario 6 — Consistent behavior regardless of navigation path (FR-008, edge case)

1. From the active list, open a person's detail screen (`/people/:id`), then return without changing anything.
2. **Expected**: the active list still reflects its correct current state (no stale flash, no unnecessary flicker — this exercises the newly-added reload-on-return at the detail-navigation call site from research.md Decision 1, confirming it doesn't regress the common "just viewed, nothing changed" case per FR-009).
3. Repeat from the archived list's detail navigation.

## Scenario 7 — Editing and saving a person also refreshes correctly (FR-010, User Story 4)

1. From the active list, open a person's detail screen, then Edit, change their name, and Save.
2. **Expected**: the app returns to Person Detail (not a `context.go()`-driven reload) showing the updated name, and the People list reflects the updated name immediately on return with no manual reload — confirms `person_form_page.dart`'s save-success branch now pops instead of using `context.go()` (research.md cross-reference to `specs/004-transaction-state-refresh/research.md`'s Decision).
3. Repeat by picking an existing person from the duplicate-warning sheet (`onPickExisting`) and confirm it also returns via the same pop-based navigation.

## Empty-state transitions (spec edge case)

1. With exactly one active person, archive them. **Expected**: the active list shows its empty state (FR per feature 001's existing empty-state contract) immediately, no reload needed.
2. With exactly one archived person, restore them. **Expected**: the archived list shows its empty state immediately, and (per Scenario 1) the active list shows that person immediately on return.

## Pass criteria

All seven scenarios above behave as described with no manual reload, app restart, or tab-switch-and-back required at any step — matching SC-001 through SC-005 and FR-010.
