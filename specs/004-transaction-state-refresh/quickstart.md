# Quickstart: Validating the Transaction State Refresh Fix

**Feature**: `004-transaction-state-refresh` | **Date**: 2026-09-20

This validates the three user stories from `spec.md` against the root cause
and fix described in `research.md` (`TransactionFormPage`'s post-save
`context.go()` → real `Navigator` pop, so `PersonDetailCubit.refresh()`
reliably runs). Run manually against a debug build, and encode the same
scenarios as automated tests per the coverage plan at the bottom.

## Manual validation

### US1 — New transaction appears immediately (P1)

1. Open an existing person's Person Details page (reached via the People
   list, so a real navigation stack exists underneath).
2. Tap the record-transaction FAB, fill in a "money received" transaction,
   Save.
3. **Expect**: back on Person Details immediately (no spinner-then-restart
   flash), the new transaction visible in the list, in chronological
   position, with no manual reload.
4. Repeat for "money given."
5. **Regression for the specific bug reported**: repeat steps 2-4 a *second*
   time in the same app session, from the *same* now-fresh Person Details
   screen (this is the exact scenario research.md identifies as previously
   failing due to Page-key reuse after a `go()` landing) — confirm the second
   transaction also appears immediately, not just the first.
6. Confirm exactly one row exists for each added transaction (no duplicates)
   in the list.

### US2 — Totals and balance update immediately (P1)

1. On a person's Person Details page, note the current headline
   (they-owe-you / you-owe-them amount) and badge status.
2. Add a transaction of a known amount (e.g. EGP 100 received).
3. **Expect**: the headline amount and badge update immediately to the new
   correct net balance — no reload, no stale figure even briefly shown as
   final.
4. Add a second transaction that flips the balance direction (e.g. a large
   "given" transaction on a settled person) and confirm the status badge
   (they-owe-you / you-owe-them / settled) updates immediately, not just the
   number.
5. Record a repayment (existing, already-working flow) and confirm it still
   updates immediately — this is the no-regression check for the pattern the
   fix is modeled on (`RepaymentFormPage`'s existing `Navigator.pop(true)`).

### US3 — Failed save does not corrupt state (P2)

1. Note the current transaction list and totals on a person's Person Details
   page.
2. Trigger a rejected save (e.g. leave amount at 0/blank, or another
   validation the form rejects) and confirm the form shows an inline error
   and does not navigate away.
3. If reachable, trigger a save that fails at the repository layer (e.g. by
   temporarily forcing a `CacheFailure` in a test double) and confirm the
   error snackbar appears and the user remains on the form.
4. Navigate back to Person Details (back button) and confirm the list and
   totals are byte-for-byte identical to step 1 — no phantom row, no partial
   total change.
5. Retry with valid input, save successfully, and confirm exactly one
   transaction now exists (the earlier failed attempt left nothing behind).

### Edge cases (spec "Edge Cases" section)

- Add a transaction, then immediately navigate away (People list) and back
  to Person Details — confirm the up-to-date state still shows (not a stale
  snapshot from before the add). This exercises the *non-live* correctness
  guarantee (FR-007) independent of the live-update fix.
- On a person with zero transactions, add the first one and confirm the
  screen transitions from the empty state directly to a one-row list with no
  intermediate flash of the old empty state.
- Add a transaction from a person's Detail page, and — per the spec's
  Clarification — confirm the Overview tab (if it was already open in the
  background before the add) is **not** required to update live; switching
  to it afterward and confirming its totals are correct is sufficient
  (out of scope to make it live in this feature).

## Automated coverage plan

Existing cubit-level tests (`test/features/transactions/presentation/cubit/person_detail_cubit_test.dart`,
`transaction_form_cubit_test.dart`) already exercise `PersonDetailCubit`/
`TransactionFormCubit` in isolation with faked use cases — they pass today
and will continue to pass, because **the defect is not inside either cubit**;
it is in the navigation glue connecting them (`research.md`). These unit
tests cannot catch this class of bug on their own, so coverage must be added
at the widget/navigation level:

1. **Widget test** exercising the real `GoRouter` (or a minimal router
   fixture reproducing the `/people/:id` → `/transactions/new` → pop
   sequence) to assert that after a simulated successful save, the
   `PersonDetailCubit`'s `refresh()`/`load()` is actually invoked (e.g. via a
   spy/mocked use case call count) and the same `PersonDetailCubit` instance
   is reused rather than silently orphaned. This directly regression-tests
   the fixed `await context.push(...)` completer chain.
2. **Widget test** for the double-add sequence in US1 step 5 above (add,
   then add again from the resulting screen) to guard against the specific
   "sometimes" intermittency described in `research.md` (Page-key reuse only
   manifesting on a second visit).
3. Extend or add a widget test for the failure path (US3) confirming
   `PersonDetailState` is unchanged after a failed save + back-navigation.
4. Consider one `integration_test/` scenario (this repo already has
   `integration_test/language_switch_flow_test.dart` as a precedent) covering
   US1+US2 end-to-end on a real device/emulator, since this bug is
   specifically a navigation-timing defect that is easiest to miss in a pure
   widget-test harness.
