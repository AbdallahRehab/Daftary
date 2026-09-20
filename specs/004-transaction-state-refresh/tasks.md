---

description: "Task list for Fix Stale State After Adding Money / Transactions"
---

# Tasks: Fix Stale State After Adding Money / Transactions

**Input**: Design documents from `/specs/004-transaction-state-refresh/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/README.md`, `quickstart.md`

**Tests**: Included. This repository has an established `bloc_test`/widget-test convention (`test/features/transactions/presentation/cubit/`, `test/widget/main_shell_test.dart`, `test/widget/person_detail_page_test.dart`, `test/widget/settings_page_test.dart`), and `plan.md`/`quickstart.md` explicitly call for new navigation-glue widget tests because the existing cubit unit tests provably cannot catch this class of bug (the defect is in navigation code connecting two independently-correct cubits, not inside either cubit).

**Organization**: Tasks are grouped by user story (P1/P1/P2, per `spec.md`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1, US2, US3) — omitted for Setup/Foundational/Polish
- Every task includes an exact file path

## Path Conventions

Single Flutter app (Option 1, per `plan.md`): `lib/features/<feature>/{data,domain,presentation}`, tests mirrored under `test/`, with page/navigation-level tests under `test/widget/` and optional end-to-end coverage under `integration_test/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the pre-fix baseline before touching any navigation code. No new project scaffolding, dependencies, or folders are needed — `plan.md` confirms this fix introduces no new package, no new feature module, and no database migration.

- [ ] T001 [P] Run `flutter test test/features/transactions/presentation/cubit/person_detail_cubit_test.dart test/features/transactions/presentation/cubit/transaction_form_cubit_test.dart` and confirm both pass unmodified, establishing the pre-fix baseline from `quickstart.md`'s Automated Coverage Plan (`research.md` confirms the defect is not inside either cubit, so these must keep passing with zero changes).
- [ ] T002 [P] Run `flutter test test/widget/person_detail_page_test.dart` and confirm it passes unmodified — this existing test only exercises rendering (no `GoRouter`), so per `research.md` it cannot catch the navigation defect, but it must not regress from this fix.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The single root-cause navigation fix that every user story's behavior and tests depend on.

**⚠️ CRITICAL**: No user-story test can meaningfully pass until this phase is complete.

- [ ] T003 Fix the root-cause defect in `lib/features/transactions/presentation/pages/transaction_form_page.dart`: in the `BlocConsumer` listener's `TransactionFormStatus.success` branch (currently `context.go('/people/${savedTransaction.personId}')`, line 100), replace the `go()` call with `Navigator.of(context).pop(savedTransaction)` so the caller's already-correct `await context.push(...); if (context.mounted) { await context.read<PersonDetailCubit>().refresh(); }` idiom in `lib/features/transactions/presentation/pages/person_detail_page.dart` (`_recordTransaction` lines 177-182, `_editTransaction` lines 198-210) actually completes, per `research.md`'s Decision (a real `Navigator` pop, mirroring `RepaymentFormPage`'s existing `Navigator.of(context).pop(true)` at `repayment_form_page.dart:40-44`). This applies uniformly to create and edit mode since `TransactionEditPage` (`lib/features/transactions/presentation/pages/transaction_edit_page.dart`) wraps the same `TransactionFormPage`/`TransactionFormCubit` — fixing `_editTransaction` (FR-008 no-regression) alongside the reported add-transaction bug in the same change.
- [ ] T004 Update `_recordTransaction` in `lib/features/people/presentation/pages/people_list_page.dart` (currently `await context.push('/transactions/new')` with no bound `personId`, line ~192) to read the `MoneyTransaction?` now returned by T003's pop and, when non-null, explicitly call `context.push('/people/${transaction.personId}')` — preserving today's "jump straight to that person's Detail page" UX for the personId-less global-FAB flow without routing it through the form's own `go()` (`research.md` Decision, personId-less case). Depends on T003 (relies on the pop now carrying a result).
- [ ] T005 [P] In `lib/features/transactions/presentation/pages/person_detail_page.dart`, capture the `MoneyTransaction?` result now returned by the popping `context.push('/transactions/new?personId=$personId')` calls in `_recordTransaction`/`_editTransaction`, for use in later test assertions (`plan.md` Project Structure: "no new fields, no new widgets" — `data-model.md` confirms `PersonDetailState` needs no change). Depends on T003; independent of T004 (different file).

**Checkpoint**: The pop()-based navigation contract is now in place and deterministic (no longer dependent on incidental Page-key reuse). All user stories below build on this.

---

## Phase 3: User Story 1 - New Transaction Appears Immediately After Saving (Priority: P1) 🎯 MVP

**Goal**: After a successful "money received" or "money given" save from Person Details, the new transaction appears in the visible list immediately, with no reload and no duplicate entries.

**Independent Test**: Open an existing person's details page, add a "money received" transaction, and verify it appears in the transaction list immediately after the save confirmation, with no reload, navigation away, or app restart.

### Tests for User Story 1

- [ ] T006 [US1] Create `test/widget/transaction_form_navigation_test.dart` with a minimal real `GoRouter` fixture reproducing the `/people/:id` → `/transactions/new` → pop sequence (mirroring `test/widget/main_shell_test.dart`'s router-fixture pattern and `test/widget/person_detail_page_test.dart`'s mocked-repository DI setup via `getIt`), and add the first test case: after simulating a successful "money received" save, assert `PersonDetailCubit.refresh()`/`load()` is invoked (via a spy/mocked use-case call count) and the same `PersonDetailCubit` instance is reused rather than orphaned (`quickstart.md` Automated Coverage Plan item 1; spec Acceptance Scenario 1).
- [ ] T007 [US1] In `test/widget/transaction_form_navigation_test.dart`, add a test case for a "money given" transaction confirming the same immediate-appearance behavior (spec Acceptance Scenario 2). Depends on T006 (same file).
- [ ] T008 [US1] In `test/widget/transaction_form_navigation_test.dart`, add the double-add regression test: add a transaction, land back on Person Details, then add a second transaction from that same now-fresh screen, and assert both transactions appear immediately with exactly one list entry each — this is the specific Page-key-reuse intermittency `research.md` identifies as previously failing only on a *second* visit (`quickstart.md` US1 steps 5-6; spec Acceptance Scenario 3; Edge Case "rapid submits"/duplicate list entries). Depends on T007 (same file).
- [ ] T009 [US1] In `test/widget/transaction_form_navigation_test.dart`, add a test case for the personId-less global-FAB flow (`PeopleListPage._recordTransaction`): confirm that after save, the newly created transaction's person is opened and the transaction is visible immediately, verifying T004's caller-side `context.push('/people/$id')` fix. Depends on T004 and T008 (same file).

### Implementation for User Story 1

Implementation for this story is already complete via the Foundational fixes (T003, T004, T005) — Phase 3 is test/validation-only, consistent with `plan.md`'s framing of this as a navigation-glue-only fix confined to already-enumerated files.

- [ ] T010 [US1] Manually execute `quickstart.md`'s "US1 — New transaction appears immediately" steps 1-6 against a debug build (both directions, plus the same-session repeat-add regression check), confirming no spinner-then-restart flash and no manual reload needed.

**Checkpoint**: User Story 1 is fully functional and independently testable/verifiable — this is the MVP.

---

## Phase 4: User Story 2 - Totals and Balance Update Immediately (Priority: P1)

**Goal**: After a successful transaction save, the person's net balance amount and relationship-status indicator update immediately alongside the new transaction row.

**Independent Test**: Note a person's current net balance and relationship status, add a new transaction of a known amount, and verify the displayed net balance updates by exactly that amount immediately after save, with no reload.

### Tests for User Story 2

- [ ] T011 [US2] In `test/widget/transaction_form_navigation_test.dart`, add a test case stubbing `TransactionsRepository.getPersonBalance` to return an updated `PersonBalance.net` after save, and assert the Person Details headline reflects the new correct value immediately with no reload — `data-model.md`: `PersonBalance` is `{ personId, net }`, "computed fresh on every `TransactionsRepository.getPersonBalance` call... already always correct *at the moment it is computed*; the bug was never in this computation, only in *when* `PersonDetailCubit` was told to recompute it" (spec Acceptance Scenario 1, US2). Depends on T009 (same file).
- [ ] T012 [US2] In the same file, add a test case that flips the balance direction (e.g. a large "given" transaction on a settled/they-owe-you person) and asserts `BalanceStatusBadge` (`lib/features/transactions/presentation/widgets/balance_status_badge.dart`) updates its displayed `RelationshipStatus` immediately, not just the numeric amount (`quickstart.md` US2 step 4; spec Acceptance Scenario 2, US2). Depends on T011.

### Implementation for User Story 2

No additional production code change is required beyond the Foundational fix (T003) — `data-model.md` confirms `PersonBalance.net`/`PersonDetailState.history` derivation is unchanged, so totals become correct automatically the moment `refresh()` reliably runs.

- [ ] T013 [US2] Manually execute `quickstart.md`'s "US2 — Totals and balance update immediately" steps 1-5, including the no-regression check that `RepaymentFormPage`'s existing `Navigator.of(context).pop(true)` flow (`repayment_form_page.dart:40-44`) still updates totals immediately post-fix.

**Checkpoint**: User Stories 1 and 2 both independently functional.

---

## Phase 5: User Story 3 - Failed Transaction Creation Does Not Corrupt State (Priority: P2)

**Goal**: A failed transaction save leaves the Person Details list and totals byte-for-byte unchanged, with a clear failure indication and no phantom or duplicate record.

**Independent Test**: Trigger a failed transaction save (e.g. via an invalid state the system rejects), and verify the transaction list and totals on the person's details page are unchanged and no partial/duplicate entry was created.

### Tests for User Story 3

- [ ] T014 [US3] In `test/widget/transaction_form_navigation_test.dart`, add a test case that stubs the add-transaction use case to fail (e.g. return a `Left(ValidationFailure(...))`/`Left(CacheFailure(...))`), triggers a save, and asserts `PersonDetailState`'s history and balance are unchanged after returning to Person Details via back-navigation — confirming the pre-existing `TransactionFormStatus.failure` listener branch in `transaction_form_page.dart` (untouched by T003, since it never called `go()`/`pop()` on failure) continues to only show a snackbar and never navigate (spec Acceptance Scenario 1, US3; `quickstart.md` US3 items 1-4; FR-005/FR-006). Depends on T012 (same file).
- [ ] T015 [US3] In the same file, add a regression test confirming a rapid double-tap of Save still creates exactly one persisted transaction post-fix, exercising `TransactionFormCubit.submit()`'s existing `if (state.isSubmitting) return;` guard together with `TransactionsDao.insertTransactionIdempotent`'s existing idempotency-key handling (FR-003/FR-004; spec Acceptance Scenario 2, US3; Edge Case "rapid double-tap"). Depends on T014.

### Implementation for User Story 3

No production code change is required — `research.md` confirms the failure path "already pops normally today and was never broken." Phase 5 is regression-test-only, guarding this correct behavior against the T003 navigation change.

- [ ] T016 [US3] Manually execute `quickstart.md`'s "US3 — Failed save does not corrupt state" steps 1-5 against a debug build, including the retry-after-failure step confirming exactly one transaction ends up persisted.

**Checkpoint**: All three user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Repository-wide verification that the fix is complete, non-regressive, and correctly scoped.

- [ ] T017 [P] Run `flutter analyze` and `dart format --set-exit-if-changed .` (constitution "Code Quality Gates") against every file touched in Phase 2 (`transaction_form_page.dart`, `people_list_page.dart`, `person_detail_page.dart`) and the new `test/widget/transaction_form_navigation_test.dart`.
- [ ] T018 Run the full `flutter test` suite to confirm zero regressions across `test/features/transactions/presentation/cubit/`, `test/widget/` (including the new `transaction_form_navigation_test.dart` alongside `person_detail_page_test.dart`, `main_shell_test.dart`, `settings_page_test.dart`), and every other existing suite.
- [ ] T019 [P] Manually execute `quickstart.md`'s "Edge cases" section: (a) add a transaction, navigate away to the People list and back to Person Details, and confirm up-to-date (not stale) state per FR-007; (b) on a person with zero transactions, confirm the screen transitions directly from empty state to a one-row list with no intermediate flash; (c) confirm the Overview tab, if it was already open in the background before the add, is correctly *not* required to update live, and is correct once revisited (spec Clarification — explicitly out of scope for live update in this feature).
- [ ] T020 [P] Optional: add `integration_test/transaction_add_refresh_flow_test.dart`, mirroring the existing `integration_test/language_switch_flow_test.dart` precedent, covering US1+US2 end-to-end on a real device/emulator (`plan.md` Testing section; `quickstart.md` Automated Coverage Plan item 4).
- [ ] T021 [P] Confirm `lib/features/people/presentation/pages/person_form_page.dart`'s analogous `context.go()`/`context.pop()` mixing defect (`research.md` "Same defect also present in the People feature", lines 79/94/96/101/103) remains untouched, per `plan.md`'s explicit out-of-scope Constraint — leave it as a pointer for `specs/005-archive-state-refresh` planning rather than fixing it here.
- [ ] T022 [P] Add a widget test in `test/widget/transaction_form_navigation_test.dart` covering the Edge Case "navigated away from Person Details before the save operation completes": start a transaction save, navigate away (e.g. back to the People list) before the save's `Future` resolves, then return to Person Details and confirm the result is reflected correctly with no loss or duplication (FR-007, spec.md Edge Cases).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — T001/T002 can start immediately and run in parallel.
- **Foundational (Phase 2)**: Depends on Setup completion. T003 has no dependency within the phase; T004 and T005 both depend on T003 (they rely on the pop now carrying a `MoneyTransaction?` result) but are independent of each other (different files) — **BLOCKS all user stories**.
- **User Stories (Phase 3-5)**: All depend on Foundational (Phase 2) completion. Because all three stories add tests into the *same* new file (`test/widget/transaction_form_navigation_test.dart`), the test-writing tasks (T006-T009, T011-T012, T014-T015) are a single, strictly sequential chain by file-conflict, even though they are logically organized by story and priority (P1 → P1 → P2).
- **Polish (Phase 6)**: Depends on all of Phase 3-5 being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2). No dependency on US2/US3.
- **User Story 2 (P1)**: Can start after Foundational (Phase 2); its tests build on the same navigation fixture US1 establishes (T006), so its test tasks are sequenced after US1's in the shared file, but the *behavior* it verifies has no code dependency on US1's specific scenarios.
- **User Story 3 (P2)**: Can start after Foundational (Phase 2); same shared-file test sequencing as US2, but verifies pre-existing (unfixed) behavior, so it has no functional dependency on US1/US2 passing first.

### Within Each User Story

- Tests are written against the Phase 2 fix; there is no separate "models before services" ordering here since this is a navigation-only bug fix with no new entities/services.
- Manual `quickstart.md` validation tasks (T010, T013, T016) can be run any time after their story's automated tests pass.

### Parallel Opportunities

- T001 and T002 (Setup) in parallel.
- T004 and T005 (Foundational) in parallel, once T003 is done.
- T017, T019, T020, T021, T022 (Polish) in parallel, once T018's full-suite gate is scheduled (T018 itself should run after code is final, but does not conflict with any of the [P] Polish tasks' files).
- Because Phase 3-5's test tasks share one file, there is **no** cross-story parallelism available within `test/widget/transaction_form_navigation_test.dart` — plan for sequential authorship there regardless of team size.

---

## Parallel Example: Setup

```bash
# Launch both baseline checks together:
Task: "Run flutter test test/features/transactions/presentation/cubit/person_detail_cubit_test.dart test/features/transactions/presentation/cubit/transaction_form_cubit_test.dart"
Task: "Run flutter test test/widget/person_detail_page_test.dart"
```

## Parallel Example: Foundational

```bash
# After T003 lands, these two touch different files and can proceed together:
Task: "Update PeopleListPage._recordTransaction in lib/features/people/presentation/pages/people_list_page.dart"
Task: "Capture popped MoneyTransaction? result in lib/features/transactions/presentation/pages/person_detail_page.dart"
```

## Parallel Example: Polish

```bash
# Once the full test suite (T018) is green, these four are independent:
Task: "flutter analyze / dart format changed files"
Task: "Manual quickstart.md Edge Cases validation"
Task: "Add integration_test/transaction_add_refresh_flow_test.dart"
Task: "Confirm person_form_page.dart defect is untouched/out of scope"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (baseline confirmation).
2. Complete Phase 2: Foundational (T003 is the actual bug fix; T004/T005 round out the enumerated scope).
3. Complete Phase 3: User Story 1 tests + manual validation.
4. **STOP and VALIDATE**: The original reported bug ("transaction not appearing without reload") no longer reproduces, including on a second add from the same screen (T008).
5. This alone resolves the single most important behavior per spec's "Why this priority" for US1.

### Incremental Delivery

1. Setup + Foundational → the navigation defect is fixed for every flow that depends on it (add, edit, both entry points).
2. Add User Story 1 tests → validate independently → the reported bug is confirmed fixed (MVP).
3. Add User Story 2 tests → validate independently → totals/balance correctness is confirmed as a consequence of the same fix.
4. Add User Story 3 tests → validate independently → confirm the already-correct failure path was not regressed by the navigation change.
5. Polish → analyzer/format/full-suite gate, edge cases, optional integration test, and an explicit scope confirmation that the People feature's analogous defect was intentionally left untouched.

### Solo/Small-Team Strategy

Because Phase 2's fix (T003) is a single small, well-isolated change and all story-specific verification lands in one shared test file, this feature is best executed by one engineer sequentially through Phases 1 → 2 → 3 → 4 → 5 → 6 rather than split across parallel owners — the "parallel team" pattern from other features' task lists does not apply well here given the single shared test file and single root-cause file.

---

## Notes

- [P] tasks = different files, no dependency on an incomplete task.
- [Story] label maps a task to its user story for traceability; Setup/Foundational/Polish carry no story label.
- The actual code fix is Phase 2 (T003-T005); Phases 3-5 are test/validation phases that prove US1/US2/US3's acceptance scenarios hold against that fix — this reflects `plan.md`'s framing of the feature as "a navigation-glue fix touching a small, fully-enumerated set of existing files," not new feature construction.
- Constitution Principle XVI (Testability by Design) and the plan's Constitution Check both flag test coverage as "required follow-through, not optional" for this feature — do not skip Phases 3-5's test tasks even though the underlying fix is small.
- Avoid: touching `lib/features/people/presentation/pages/person_form_page.dart` (T021 explicitly confirms it stays out of scope), introducing a Drift `.watch()` stream or a cross-page event bus (both rejected alternatives in `research.md`), or changing any Domain/Data code (`TransactionsRepository`, use cases, `TransactionsDao` are all confirmed unchanged in `contracts/README.md` and `data-model.md`).
