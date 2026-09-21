---

description: "Task list for Fix Archive / Unarchive Stale State"
---

# Tasks: Fix Archive / Unarchive Stale State

**Input**: Design documents from `/Users/abdallahrehab/projects/Daftary/specs/005-archive-state-refresh/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Tests ARE included below. `plan.md`'s Technical Context explicitly names the test files this feature extends/adds (`bloc_test`/`mocktail` on the existing `person_list_cubit_test.dart`/`archived_people_cubit_test.dart`, new `test/widget/people_list_page_test.dart` and `test/widget/archived_people_page_test.dart`, new `integration_test/archive_state_refresh_flow_test.dart`), and constitution Principle XVI (Testability by Design) plus quickstart.md's seven scenarios establish this repo's existing BLoC-test convention as mandatory for state-management changes.

**Organization**: Tasks are grouped by user story (spec.md priorities P1/P2/P1... — see below) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

**Note on task ID order**: IDs reflect assignment order (test-then-implementation pairing across parallel stories), not strict document order — in Phase 4, T010 and T012 (tests, different files) are followed by T011 (implements T010) and T013 (implements T012), so document order is T010, T012, T011, T013 rather than fully ascending.

## Path Conventions

Single Flutter app (`lib/`, `test/`, `integration_test/` at repository root — Option 1 per plan.md's Project Structure). This is a Presentation-layer-only bug fix entirely inside `lib/features/people/presentation/`; no Domain, Data, or schema files change (contracts/people_repository.md).

---

## Phase 1: Setup

**Purpose**: Confirm a clean, green baseline before touching any file, since this is a correctness fix to existing code, not new scaffolding (no new dependency is required — research.md "Technology/version confirmation").

- [X] T001 Run the existing people-feature test suite to confirm a green baseline before any change: `flutter test test/features/people/ test/widget/` (baseline for `test/features/people/presentation/cubit/person_list_cubit_test.dart`, `test/features/people/presentation/cubit/archived_people_cubit_test.dart`)
- [X] T002 [P] Run `flutter analyze` scoped to the files this feature will touch (`lib/features/people/presentation/`) to confirm no pre-existing warnings that would be conflated with this fix's changes

**Checkpoint**: Baseline confirmed green — safe to proceed to Foundational changes.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Lock in the shared reload mechanism every user story depends on, and add the shared state field the cross-cutting FR-006 guard (Polish phase) needs on both list Cubits. research.md Decision 4 establishes that `load()` on both Cubits **already** re-reads `state.nameQuery`/`state.statusFilter` rather than resetting them — no production code change is needed here, only regression-locking tests, before the navigation-reload fixes in Phase 3+ start relying on it.

**⚠️ CRITICAL**: No user story work should begin until T003-T004 confirm the shared reload mechanism behaves as research.md documents.

- [X] T003 [P] Add a `bloc_test` regression-lock case asserting `PersonListCubit.load()` re-reads the *current* `state.nameQuery` and `state.statusFilter` (does not reset them) when invoked a second time, in `test/features/people/presentation/cubit/person_list_cubit_test.dart` (guards research.md Decision 4, which this feature's Phase 3+ fixes depend on for FR-005)
- [X] T004 [P] Add a `bloc_test` regression-lock case asserting `ArchivedPeopleCubit.load()` re-reads the current `state.nameQuery` (does not reset it) when invoked a second time, in `test/features/people/presentation/cubit/archived_people_cubit_test.dart` (symmetric guard per spec Clarifications 2026-09-20)
- [X] T005 [P] Add a `processingPersonId` field (type `String?`) to `PersonListState` in `lib/features/people/presentation/cubit/person_list_state.dart`, with the data-model.md constraint verbatim: "Non-null while an `archive()` call is in flight for that person id; `archive()` is a no-op re-entrancy guard when called again with the same id while it is already set (FR-006). Cleared once the use case call (success or failure) completes and, on success, the subsequent `load()` has emitted." Extend `copyWith()` with an explicit-clear flag (e.g. `clearProcessingPersonId`), mirroring the existing `clearStatusFilter` pattern already used for `statusFilter` (same file), and add the field to `props`.
- [X] T006 [P] Add a `processingPersonId` field (type `String?`) to `ArchivedPeopleState` in `lib/features/people/presentation/cubit/archived_people_state.dart`, per data-model.md's verbatim note: "Same guard as above, applied to `restore()` (FR-006)." Extend `copyWith()` with an explicit-clear flag mirroring the `PersonListState` pattern added in T005, and add the field to `props`.

**Checkpoint**: Shared reload mechanism regression-locked; shared `processingPersonId` state shape exists on both Cubits. User story implementation can now begin.

---

## Phase 3: User Story 1 - Unarchived Person Reappears Immediately in the Active List (Priority: P1) 🎯 MVP

**Goal**: Fix the exact reported bug — restoring a person from the archived list must make them reappear in the active list immediately, without reload/navigation/restart.

**Independent Test**: Archive a person, then unarchive them from the archived list, and verify the person appears in the active people list immediately, without navigating away, reloading, or restarting the app.

### Tests for User Story 1

- [X] T007 [P] [US1] Add a widget test asserting `PeopleListPage` calls `PersonListCubit.load()` again after returning from the AppBar's archived-list `context.push('/people/archived')` (research.md Decision 1's root-cause call site, `lib/features/people/presentation/pages/people_list_page.dart:51`), in new file `test/widget/people_list_page_test.dart`. This test MUST fail before T008.

### Implementation for User Story 1

- [X] T008 [US1] In `lib/features/people/presentation/pages/people_list_page.dart`, replace the AppBar archived-list `IconButton`'s fire-and-forget `onPressed: () => context.push('/people/archived')` (line 51) with the same `await context.push(...); if (context.mounted) { await context.read<PersonListCubit>().load(); }` pattern already used by `_addPerson`/`_recordTransaction` in the same file (lines 184-196), extracted as a private `_openArchivedList(BuildContext context)` method. Add a short code comment cross-referencing feature 005 at this call site (research.md Decision 3: "make the fix hard to omit again").
- [X] T009 [US1] Add integration test Scenario 1 (quickstart.md) to new file `integration_test/archive_state_refresh_flow_test.dart`: archive a person from the active list → open `/people/archived` → tap Restore → navigate back → assert the person appears in the active list immediately and exactly once (FR-001, FR-004, Acceptance Scenarios 1-2, SC-001/SC-003/SC-005).

**Checkpoint**: User Story 1 is fully functional and independently testable — the originally reported bug no longer reproduces.

---

## Phase 4: User Story 2 - Archived List Updates Immediately in Both Directions (Priority: P1)

**Goal**: Ensure both lists update immediately regardless of which screen (list or detail) the archive/unarchive action was triggered from, closing the two remaining stale-Cubit call sites research.md Decision 1 identifies (`PeopleListPage`'s person-tile→detail push, and `ArchivedPeoplePage`'s own push into the detail screen), so FR-002/FR-003/FR-008 hold for every navigation path, not only the archived-list round trip fixed in User Story 1.

**Independent Test**: From the active list, archive a person and verify they disappear from the active list and appear in the archived list immediately; from the archived list, unarchive them and verify the reverse, all without reload.

### Tests for User Story 2

- [X] T010 [US2] Add a widget test case (appended to `test/widget/people_list_page_test.dart`, created in T007) asserting `PeopleListPage` calls `PersonListCubit.load()` again after returning from a person-tile's `onTap: () => context.push('/people/${item.person.id}')` (`lib/features/people/presentation/pages/people_list_page.dart:160`). This test MUST fail before T011.
- [X] T012 [P] [US2] Add a widget test asserting `ArchivedPeoplePage` calls `ArchivedPeopleCubit.load()` again after returning from its own `onTap: () => context.push('/people/${person.id}')` (`lib/features/people/presentation/pages/archived_people_page.dart:82`), in new file `test/widget/archived_people_page_test.dart`. This test MUST fail before T013.

### Implementation for User Story 2

- [X] T011 [US2] In `lib/features/people/presentation/pages/people_list_page.dart`, replace the person-tile's fire-and-forget `onTap: () => context.push('/people/${item.person.id}')` (line 160) with the awaited `push` + `if (context.mounted) { await context.read<PersonListCubit>().load(); }` pattern, extracted as a private `_openPersonDetail(BuildContext context, String personId)` method. Add the Decision-3 cross-reference comment. Depends on T010.
- [X] T013 [US2] In `lib/features/people/presentation/pages/archived_people_page.dart`, replace the list item's fire-and-forget `onTap: () => context.push('/people/${person.id}')` (line 82) with the awaited `push` + `if (context.mounted) { await context.read<ArchivedPeopleCubit>().load(); }` pattern. Add the Decision-3 cross-reference comment. Depends on T012.
- [X] T014 [US2] Add integration test Scenario 2 and the detail-navigation edge case (quickstart.md Scenarios 2 and 6) to `integration_test/archive_state_refresh_flow_test.dart`: archive from active list (already-correct self-reload) → appears in archived list → restore from archived list → reappears in active list on return (FR-002/FR-003/SC-001/SC-002); plus open a person's detail screen from each list and return with no change, asserting no stale flash (FR-008/FR-009). Depends on T009, T011, T013.

**Checkpoint**: User Stories 1 AND 2 both work independently — every navigation path that can trigger or observe an archive/unarchive keeps both lists accurate.

---

## Phase 5: User Story 3 - Search, Sort, and Filter State Remain Correct on Both Lists (Priority: P2)

**Goal**: Confirm search/sort/filter state on both the active and archived lists survives the reload-on-return fixes from User Stories 1-2 exactly as research.md Decision 4 predicts (no production change needed — `load()` already reapplies `nameQuery`/`statusFilter`), and lock this in with tests before release.

**Independent Test**: Apply a search term or filter to the active people list that matches the person being unarchived, unarchive them, and verify they appear immediately without the search/filter being reset or losing its results; repeat with a filter that would exclude them and verify they do not incorrectly appear. Then apply a search term to the archived list, archive a matching person from the active list, and verify they appear immediately in the archived list's filtered results with the search term still applied.

### Tests for User Story 3

- [X] T015 [P] [US3] Add a widget test case (appended to `test/widget/people_list_page_test.dart`) asserting the `AppTextField` search box still shows the previously typed `nameQuery` and the filtered/sorted `items` correctly include a newly-unarchived matching person after `PeopleListPage`'s reload-on-return (T008/T011) fires — confirms FR-005 Acceptance Scenario 1-2 (search preserved, correct sort position, no reset to unfiltered).
- [X] T016 [P] [US3] Add a widget test case (appended to `test/widget/archived_people_page_test.dart`) asserting the archived list's search box still shows the previously typed `nameQuery` and the filtered `people` correctly include a newly-archived matching person after `ArchivedPeoplePage`'s reload-on-return (T013) fires — confirms FR-005 Acceptance Scenario 3 / spec Clarifications 2026-09-20 (symmetric preservation).

### Implementation for User Story 3

- [X] T017 [US3] Add integration test Scenario 3 (quickstart.md) to `integration_test/archive_state_refresh_flow_test.dart`: active-list search preserved across an unarchive; unarchive of a mid-alphabet name lands in correct sorted position; archived-list search preserved across an archive; a relationship-status filter that excludes the restored person correctly hides them while the filter is active. Depends on T014. No production code change expected for this story (research.md Decision 4) — this phase is test-only verification.

**Checkpoint**: All three user stories are independently functional; FR-005 is verified end-to-end on both lists in both directions.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Add the FR-006 no-double-transition guard (shared by both Cubits, not tied to a single priority story), verify FR-007's failure-path behavior, tidy the remaining Decision-3 annotations, and run full regression validation.

- [X] T018 [P] Add a `bloc_test` case asserting `PersonListCubit.archive(id)` is a no-op (the `ArchivePerson` use case is not invoked a second time) when called again with the same `id` while `state.processingPersonId == id`, in `test/features/people/presentation/cubit/person_list_cubit_test.dart`. This test MUST fail before T020.
- [X] T019 [P] Add a `bloc_test` case asserting `ArchivedPeopleCubit.restore(id)` has the same re-entrancy guard, in `test/features/people/presentation/cubit/archived_people_cubit_test.dart`. This test MUST fail before T021.
- [X] T020 Implement the `processingPersonId` re-entrancy guard in `PersonListCubit.archive()` (`lib/features/people/presentation/cubit/person_list_cubit.dart`): set `state.processingPersonId` to `personId` before invoking `_archivePerson`, short-circuit if already set to that `personId`, and clear it (via the `clearProcessingPersonId` flag from T005) on both the success and failure branches so a failed attempt does not permanently lock the control (FR-006, FR-007). Depends on T005, T018.
- [X] T021 Implement the same `processingPersonId` re-entrancy guard in `ArchivedPeopleCubit.restore()` (`lib/features/people/presentation/cubit/archived_people_cubit.dart`). Depends on T006, T019.
- [X] T022 [P] Disable the archive `IconButton` in `PersonListTile` (`lib/features/people/presentation/widgets/person_list_tile.dart`) while `processingPersonId` matches this row's `person.id`, wired via a `BlocSelector<PersonListCubit, PersonListState, String?>` in `people_list_page.dart` selecting `state.processingPersonId` (constitution Principle IV — use `BlocSelector` to avoid unnecessary rebuilds). Depends on T020.
- [X] T023 [P] Disable the restore `TextButton` in `ArchivedPeoplePage`'s list item (`lib/features/people/presentation/pages/archived_people_page.dart`) while `processingPersonId` matches the row's `person.id`, via the equivalent `BlocSelector`. Depends on T021.
- [X] T024 Add integration/widget test Scenario 4 (quickstart.md): rapid double-tap on the same person's archive control, and separately on the same person's restore control, each produces exactly one state transition with no flicker or duplicate row — appended to `integration_test/archive_state_refresh_flow_test.dart`. Depends on T022, T023.
- [X] T025 [P] Add `bloc_test` cases for Scenario 5 (FR-007) in both `test/features/people/presentation/cubit/person_list_cubit_test.dart` and `test/features/people/presentation/cubit/archived_people_cubit_test.dart`: a faked repository returning `Left(CacheFailure(...))` from `archivePerson`/`restorePerson` leaves the person in their original list (no optimistic removal), sets `errorMessage`, and clears `processingPersonId` so the control is tappable again. Depends on T020, T021.
- [X] T026 [P] Add the research.md Decision 3 cross-reference comment ("this call site follows the reload-on-return convention fixed by feature 005-archive-state-refresh — do not omit on new pushes from this screen") to the two already-correct call sites, `_addPerson` and `_recordTransaction`, in `lib/features/people/presentation/pages/people_list_page.dart`, for consistency across all five push call sites now covered by the convention.
- [X] T027 Run the full quickstart.md validation pass (all seven scenarios, including Scenario 7/FR-010 and the empty-state transitions) either manually on a simulator/device or via the command list in `specs/005-archive-state-refresh/quickstart.md` (`flutter test test/features/people/presentation/cubit/person_list_cubit_test.dart`, `.../archived_people_cubit_test.dart`, `test/widget/`, `integration_test/archive_state_refresh_flow_test.dart -d <device>`). Depends on T003-T026, T030-T033.
- [X] T028 Run `flutter analyze` and `dart format` across every file touched by this feature and fix any warnings (constitution Code Quality Gates — no `// ignore`, no suppressed warnings). Depends on T027.
- [X] T029 Run the full existing test suite (`flutter test`) to confirm FR-009 — no regression to existing view/add/edit/search/sort/filter people functionality or to the unrelated `transactions`/`settings` features. Depends on T028.

---

## Phase 7: User Story 4 - Editing and Saving a Person Also Refreshes Correctly (Priority: P2)

**Goal**: Close the cross-feature handoff from `specs/004-transaction-state-refresh/research.md` (lines 157-170): `person_form_page.dart` carries the identical `context.go()`-vs-`context.pop()` navigation defect this feature already fixes for archive/unarchive, in its save-success (line 94) and duplicate-pick (line 79) branches (FR-010).

**Independent Test**: From a person's detail view, edit their name via the Person Form and save; verify the People list and the Person Detail view show the updated name immediately on return, with no reload.

### Tests for User Story 4

- [X] T030 [P] [US4] Add a widget test asserting `PersonFormPage`'s save-success branch performs a `Navigator` pop (not `context.go()`) when the form was reached via a pushed route, so the caller's existing reload-on-return (`PersonDetailPage._editPerson`, `lib/features/people/presentation/pages/person_detail_page.dart:191-196`) fires — in new file `test/widget/person_form_page_test.dart`. This test MUST fail before T031.

### Implementation for User Story 4

- [X] T031 [US4] In `lib/features/people/presentation/pages/person_form_page.dart`, replace the save-success `context.go('/people/${saved.id}')` (line 94) with a `Navigator.pop()`-based approach mirroring the Decision in `specs/004-transaction-state-refresh/research.md` (lines 172-221): when the form was reached via a pushed route (`context.canPop()`), pop with the saved `Person` as the result so the caller's `await context.push(...); if (context.mounted) { load(); }` idiom fires; otherwise fall back to the existing `context.go('/people/${saved.id}')` (no route to pop). Depends on T030.
- [X] T032 [US4] Apply the same fix to the duplicate-warning sheet's "pick existing person" branch (`onPickExisting`, `person_form_page.dart:77-80`): replace `context.go('/people/${person.id}')` with the equivalent pop-based navigation, consistent with T031, so returning from the duplicate person's detail screen also reliably refreshes the originating list. Depends on T031.
- [X] T033 [US4] Add an integration/widget test confirming: edit a person's name from Person Detail → Edit → Save → return to the People list shows the updated name immediately, with no manual reload (FR-010, Acceptance Scenario 1). Depends on T031, T032.

**Checkpoint**: The cross-feature handoff from `specs/004-transaction-state-refresh` is closed — `person_form_page.dart` no longer carries the navigation defect this feature's other fixes address elsewhere in the People feature.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories (T003/T004 must pass before any Phase 3+ reload fix is trusted to preserve filters; T005/T006 must exist before the Phase 6 guard can be implemented).
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion.
  - User Story 1 (P1) has no dependency on User Story 2 or 3 and delivers the MVP alone.
  - User Story 2 (P1) touches the same file as User Story 1 (`people_list_page.dart`) at a different call site — implement after US1 to avoid merge conflicts, though it does not depend on US1's fix functioning.
  - User Story 3 (P2) is verification-only and is easiest to execute after US1+US2 land, since it tests the reload-on-return fixes they introduce.
- **Polish (Phase 6)**: Depends on Foundational's `processingPersonId` fields (T005/T006) and is otherwise independent of Phases 3-5's navigation fixes; T027-T029 depend on everything above being complete.
- **User Story 4 (Phase 7)**: Depends only on Foundational (Phase 2) completion — touches `person_form_page.dart`, a file no other phase in this feature modifies, so it has no file-conflict dependency on Phases 3-6 and can run in parallel with any of them.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2). No dependency on US2/US3.
- **User Story 2 (P1)**: Can start after Foundational (Phase 2). Shares a file with US1 (`people_list_page.dart`) so is sequenced after it in this plan, but is conceptually independent and independently testable per its own Independent Test.
- **User Story 3 (P2)**: Can start after Foundational (Phase 2); in practice depends on US1/US2's fixes existing to have something to verify against.
- **User Story 4 (P2)**: Can start after Foundational (Phase 2). No dependency on US1/US2/US3 — different files (`person_form_page.dart`), different bug (FR-010, not the archive/unarchive fix).

### Within Each User Story

- Tests MUST be written and FAIL before the corresponding implementation task.
- Widget-test-then-fix pairs before the story's integration test.
- Story complete (checkpoint) before moving to the next priority.

### Parallel Opportunities

- T001 and T002 (Setup) can run in parallel.
- T003, T004, T005, T006 (Foundational) touch four different files and can all run in parallel.
- T007 (US1 test) has no same-file conflict with T012 (US2 test, different new file) — both can start as soon as Foundational is done.
- T015 and T016 (US3 tests) touch different files and can run in parallel.
- T018 and T019 (Polish guard tests) touch different files and can run in parallel; T022 and T023 (disable-control UI) touch different files and can run in parallel once their respective guards (T020/T021) land; T025 and T026 can run in parallel with each other and with T022/T023.

---

## Parallel Execution Examples

### Foundational (Phase 2)

```bash
Task: "Add bloc_test regression-lock for PersonListCubit.load() preserving nameQuery/statusFilter in test/features/people/presentation/cubit/person_list_cubit_test.dart"
Task: "Add bloc_test regression-lock for ArchivedPeopleCubit.load() preserving nameQuery in test/features/people/presentation/cubit/archived_people_cubit_test.dart"
Task: "Add processingPersonId field to PersonListState in lib/features/people/presentation/cubit/person_list_state.dart"
Task: "Add processingPersonId field to ArchivedPeopleState in lib/features/people/presentation/cubit/archived_people_state.dart"
```

### User Story 1

```bash
Task: "Widget test: PeopleListPage reloads on return from the archived-list push, in test/widget/people_list_page_test.dart"
```
(Single-call-site story — the implementation task T008 and integration test T009 follow sequentially in the same file/flow.)

### User Story 2

```bash
Task: "Widget test: ArchivedPeoplePage reloads on return from its detail push, in test/widget/archived_people_page_test.dart"
```
(Runs in parallel with US1's T007/T010 work since it is a different file; the People-tile fix (T010/T011) is sequenced after US1 only to avoid two engineers editing `people_list_page.dart` at once.)

### User Story 3

```bash
Task: "Widget test: active-list search term preserved after reload-on-return, appended to test/widget/people_list_page_test.dart"
Task: "Widget test: archived-list search term preserved after reload-on-return, appended to test/widget/archived_people_page_test.dart"
```

### Polish

```bash
Task: "bloc_test: PersonListCubit.archive() re-entrancy guard, in test/features/people/presentation/cubit/person_list_cubit_test.dart"
Task: "bloc_test: ArchivedPeopleCubit.restore() re-entrancy guard, in test/features/people/presentation/cubit/archived_people_cubit_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (regression-locks the reload mechanism; adds the shared state field used later).
3. Complete Phase 3: User Story 1 (T007-T009).
4. **STOP and VALIDATE**: Run quickstart.md Scenario 1 manually — archive → open archived list → restore → back → person reappears once, immediately. This alone fixes the exact reported bug (SC-005).
5. Ship this increment if desired; it is independently correct and testable even before US2/US3 land.

### Incremental Delivery

1. Setup + Foundational → shared foundation confirmed correct.
2. Add User Story 1 → validate independently → the reported bug is fixed (MVP).
3. Add User Story 2 → validate independently → both lists, both directions, all navigation paths are now accurate (FR-002/FR-003/FR-008 fully covered).
4. Add User Story 3 → validate independently → FR-005 search/sort/filter preservation is proven on both lists (test-only phase, no new production risk).
5. Polish → FR-006 (no double-transition) and FR-007 (failure leaves state untouched) are added and verified; full quickstart.md and full regression suite close out FR-009.
6. Add User Story 4 → validate independently → FR-010 is fixed, closing the `specs/004-transaction-state-refresh` cross-feature handoff (can be done in parallel with any of steps 2-5 since it touches a different file).

### Notes

- This is a small, well-scoped Presentation-layer fix (2 Cubits + 2 states + 3 pages + 1 widget, per plan.md's Scale/Scope) — every phase above stays inside `lib/features/people/`; no `lib/core/` abstraction is introduced (constitution Principle II; research.md Decision 2/3). Phase 7 (`person_form_page.dart`) is additive, closing a specific cross-feature handoff (FR-010) rather than expanding the core archive/unarchive scope.
- Commit after each task or logical group; stop at any checkpoint to validate a story independently before continuing.
- Avoid combining User Story 1 and User Story 2's fixes into a single commit/task even though they share a file — keeping them separable preserves the ability to ship the MVP (US1) alone if needed.
