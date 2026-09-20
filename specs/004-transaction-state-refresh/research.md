# Research: Fix Stale State After Adding Money / Transactions

**Feature**: `004-transaction-state-refresh` | **Date**: 2026-09-20

This document records the root-cause investigation for the reported bug ("a
new transaction sometimes does not appear immediately on Person Details until
the app is reloaded") and the decisions that follow from it. Every claim below
traces to a specific file/line in this repository, or to the installed
`go_router` package source (`go_router: ^14.6.2`, resolved `14.8.1`, at
`~/.pub-cache/hosted/pub.dev/go_router-14.8.1/lib/src`).

## Root Cause

### Summary

`PersonDetailPage` already has a correct-looking refresh mechanism for every
mutation flow it triggers:

```dart
// lib/features/transactions/presentation/pages/person_detail_page.dart:177-182
Future<void> _recordTransaction(BuildContext context) async {
  await context.push('/transactions/new?personId=$personId');
  if (context.mounted) {
    await context.read<PersonDetailCubit>().refresh();
  }
}
```

`PersonDetailCubit.refresh()` (`person_detail_cubit.dart:71-75`) simply
re-runs `load()`, which re-fetches balance + history from
`TransactionsRepository` (a one-shot `Future`-based read, not a reactive
stream — see "No reactive data layer" below). This pattern is proven to work:
`_editTransaction`, `_editPerson`, and `_recordRepayment` on the same page use
the identical `await context.push(...); if (context.mounted) refresh();`
idiom, and `RepaymentFormPage` closes correctly with a genuine pop:

```dart
// lib/features/transactions/presentation/pages/repayment_form_page.dart:40-44
if (state.status == RepaymentFormStatus.success) {
  ...
  Navigator.of(context).pop(true);
```

**The bug is that `TransactionFormPage` — the page reached by the "record
transaction" FAB, i.e. the exact flow in the bug report — does not pop.** On
successful save it instead calls `context.go(...)`:

```dart
// lib/features/transactions/presentation/pages/transaction_form_page.dart:94-103
if (state.status == TransactionFormStatus.success) {
  ...
  final savedTransaction = state.savedTransaction;
  if (savedTransaction != null) {
    context.go('/people/${savedTransaction.personId}');   // <-- always taken on success
  } else {
    Navigator.of(context).pop();
  }
}
```

`_addTransaction`/`_editTransaction` in `TransactionFormCubit.submit()`
(`transaction_form_cubit.dart:217-230`) always emits `savedTransaction` on the
success branch, so the `else Navigator.of(context).pop()` line is dead code —
**every successful save takes the `context.go(...)` branch**, for both create
and edit mode (edit mode goes through the same `TransactionFormCubit`/
`TransactionFormPage`, so `PersonDetailPage._editTransaction` has the
identical defect).

### Why `context.go()` breaks the caller's `await context.push(...)`

`context.push()` in go_router returns a `Future` backed by a `Completer` that
is only ever completed in one place: `ImperativeRouteMatch.complete(value)`
(`go_router-14.8.1/lib/src/match.dart:454-457`), which fires when that pushed
route is popped in the normal way.

`context.go()` follows a completely different code path. In
`GoRouteInformationParser._updateRouteMatchList`
(`go_router-14.8.1/lib/src/parser.dart:170-215`):

```dart
switch (type) {
  case NavigatingType.push:
    return baseRouteMatchList!.push(
      ImperativeRouteMatch(pageKey: _getUniqueValueKey(), completer: completer!, matches: newMatchList),
    );
  ...
  case NavigatingType.go:
    return newMatchList;   // <-- whole match list replaced; nothing here ever
                            //     calls .complete() on any pending push completer
```

`NavigatingType.go` unconditionally replaces the *entire* route match list
with `newMatchList` and never iterates the discarded matches to complete their
completers. So when `TransactionFormPage` calls
`context.go('/people/${savedTransaction.personId}')`, the `Completer` created
by `PersonDetailPage`'s earlier `context.push('/transactions/new?personId=...')`
call is silently abandoned — **the `await context.push(...)` in
`_recordTransaction` never resolves**. Everything after it, including
`if (context.mounted) { await context.read<PersonDetailCubit>().refresh(); }`,
is unreachable on the success path. This is confirmed by contrast: on the
*failure* path the user backs out via the platform back button, which is a
real `Navigator.pop()` and does complete the future — which is exactly why
FR-005 ("failed save leaves Person Details untouched") already holds today
without any fix, while FR-001/FR-002 (successful save must show up
immediately) do not.

### Why the bug is *intermittent* rather than 100% reproducible

Because the explicit `refresh()` call never runs, whether the user sees fresh
data at all depends entirely on an unrelated side effect of `context.go()`:
whether Flutter's `Navigator` treats the `/people/:id` page landed on as the
*same* `Page` (by `key`) as one already present deeper in the branch's stack,
or as a brand-new one.

- `context.push()` matches always get a **fresh random `ValueKey`** per call
  (`_getUniqueValueKey()`, `parser.dart:217-220`), so the *first* time a
  person is opened (`PeopleListPage`/`OverviewPage` → `context.push('/people/$id')`)
  and the FAB is used, the subsequent `context.go('/people/$id')` produces a
  declaratively-matched page with a different key scheme than the pushed one
  it's replacing — Flutter treats it as new, mounts a fresh
  `PersonDetailPage`, and `BlocProvider`'s `create: (_) => getIt<PersonDetailCubit>()..load(personId)`
  runs again. In this specific case the screen *happens* to end up correct,
  purely by accident of page-key mismatch, not because any refresh logic
  executed.
- On a **second** transaction added from that same now-`go()`-reached
  `PersonDetailPage` (or any path that revisits `/people/:id` after already
  having arrived there via `go()` once), the branch's Navigator stack and key
  derivation can line back up with the page already mounted underneath,
  causing Flutter to **reuse the existing `PersonDetailPage` element**
  (and therefore the existing, now-stale `PersonDetailCubit` — `BlocProvider.create`
  does not re-run for a reused element) instead of creating a new one. This is
  the "sometimes" the bug report describes, and matches FR-007's explicit
  requirement that correctness must hold "regardless of navigation path
  taken."

### No reactive data layer to fall back on

This is not a case where a Drift `.watch()` stream exists elsewhere and was
simply forgotten here. Every read in the transactions data layer is a one-shot
`Future`:

- `TransactionsDao.getHistoryForPerson`/`netBalanceMinorUnits` use
  `.get()`, never `.watch()` (`lib/features/transactions/data/datasources/transactions_dao.dart:44-49,75-79`).
- `TransactionsRepositoryImpl.getPersonHistory`/`getPersonBalance` return
  plain `Future<Either<Failure, T>>` (`transactions_repository_impl.dart:168-192`).
- `PersonDetailCubit.load`/`refresh` are explicit imperative fetch calls
  (`person_detail_cubit.dart:29-75`), not stream subscriptions.
- `OverviewCubit`/`PersonListCubit` (checked for contrast) use the exact same
  one-shot `load()`-on-`initState`/manual-`refresh()` idiom — there is no
  more sophisticated "correct" reactive pattern already in the codebase that
  Person Details is failing to use. The entire app's state-management
  convention for this feature area is "fetch once, refetch explicitly on a
  known trigger."

This matters for the fix approach chosen below.

### Same defect also present in the People feature (informational only)

`lib/features/people/presentation/pages/person_form_page.dart` mixes the same
two patterns — `context.go('/people/${person.id}')` (lines 79, 94) alongside
`context.pop()` (lines 96, 101) and `context.go('/people')` (line 103) on
different save-success branches. `PersonDetailPage._editPerson`
(`person_detail_page.dart:191-196`) uses the same
`await context.push('/people/$personId/edit'); if (context.mounted) refresh();`
idiom as `_recordTransaction`, so an edit-person save that lands on a `go()`
branch is subject to the identical broken-completer defect. This is exactly
the shared root cause the `005-archive-state-refresh` spec's Assumptions
section anticipates. **No file under `specs/005-...` or `lib/features/people/`
is modified by this feature** — this is noted here only as corroborating
evidence and a pointer for whoever plans 005.

## Decision

**Decision**: Fix the navigation glue, not the data layer. Change
`TransactionFormPage`'s (and, for consistency/FR-008 "no regression," any
other transaction-flow page found to share the pattern) post-save navigation
so that returning to an already-open Person Details screen goes through a
real `Navigator` pop — exactly like `RepaymentFormPage` already does
successfully — instead of `context.go(...)`. Concretely:

- When `TransactionFormPage` was reached with a bound `personId` (the FAB
  flow from `PersonDetailPage`, and edit mode reached from a transaction's own
  row) — i.e. whenever there is a pushed route to return to — pop with the
  saved transaction as the result (`Navigator.of(context).pop(savedTransaction)`),
  letting the *existing* `await context.push(...); if (context.mounted) { await ...refresh(); }`
  callers do what they already correctly attempt to do today.
- When `TransactionFormPage` was reached from the global FAB with no
  `personId` bound (`PeopleListPage._recordTransaction`, person picked inside
  the form), preserve the current "jump straight to that person's Detail
  page" UX, but implement it as an explicit `context.push('/people/$id')`
  performed by the *caller* after its own `pop` resolves (inspecting the
  popped `MoneyTransaction?`), not as a `go()` inside the form itself. A
  freshly-`push()`-ed `PersonDetailPage` always gets a new random page key
  (per `_getUniqueValueKey()` above), so it is guaranteed to mount a fresh
  `PersonDetailCubit` and call `load()` — no key-reuse ambiguity.

This keeps every read one-shot/imperative (matching the rest of the app),
fixes the actual defect (a broken `Future` chain from misusing declarative
`go()` where an imperative `pop()` was needed), and makes the outcome
deterministic instead of dependent on incidental Page-key reuse — directly
satisfying:
- **FR-001/FR-002**: the caller's own `refresh()` now reliably runs after
  every successful save, so the list and totals update in the same
  interaction.
- **FR-003/FR-004**: unchanged — already correctly enforced by
  `TransactionFormCubit.submit()`'s `if (state.isSubmitting) return;` guard
  and the DAO's idempotency-key unique-constraint handling
  (`transactions_dao.dart:21-33`); no fix needed there.
- **FR-005/FR-006**: unchanged — the failure path already pops normally
  today and was never broken.
- **FR-007**: correctness no longer depends on which navigation path was
  taken to reach Person Details, because a real pop always completes the
  same way regardless of prior history.
- **Constitution Principle III** (BLoC/Cubit Mandate — avoid/resolve race
  conditions): removes the race between "does Flutter reuse this Page's
  Element" and "did the explicit refresh fire," replacing it with a single
  deterministic trigger.
- **Constitution Principle IV** (Immutable State): no change — `PersonDetailState`/
  `TransactionFormState` already model this correctly; the bug was never in
  the state shape, only in what triggered a re-emission.

### Alternatives considered

1. **Convert `PersonDetailCubit`'s history/balance reads to Drift `.watch()`
   streams**, so the UI updates itself the instant a row changes, independent
   of navigation. Rejected as the primary fix: it would be the *first*
   reactive-stream cubit in the app (every sibling cubit — `OverviewCubit`,
   `PersonListCubit`, `ArchivedPeopleCubit` — uses one-shot fetch + explicit
   refresh), which conflicts with the spec's Assumptions ("reuses and
   corrects the existing state-management architecture... rather than
   introducing a new or parallel state-management approach") and would be a
   materially larger change (new stream-subscription lifecycle management in
   the Cubit, `StreamSubscription` cancellation on `close()`, merging two
   streams — history and balance — into one state) than the actual defect
   warrants. It is also insufficient on its own: it does not fix the root
   navigation defect, since the reported bug already has a designed refresh
   path that a stream would sit *alongside*, not replace — the broken
   `context.go()`/`push()` completer mismatch would remain a latent bug for
   every other flow that relies on the same idiom (edit, delete confirmation
   round-trips, person edit). Noted as a good candidate for a future,
   separate hardening pass, not for this bug fix.
2. **A cross-page event bus / global notifier** ("transaction created" event
   that any open screen listens for) so Person Details refreshes even if the
   navigation glue is never fixed. Rejected: introduces a second
   state-propagation mechanism alongside BLoC/Cubit, which Principle III
   explicitly prohibits without documented justification, and over-solves a
   problem that a correct `pop()` already solves for the one screen the
   spec's Clarification requires to update live (Person Details).
3. **Keep `context.go()` but also call `refresh()` from a `didPopNext`/route-
   aware observer on `PersonDetailPage` instead of relying on the `push()`
   future.** Rejected: still leaves the underlying architectural inconsistency
   (mixing imperative push/pop with declarative go for what is, from the
   user's perspective, a "go back" action) in place for every other page that
   uses the same `await push(); refresh();` idiom (edit transaction, edit
   person, repayment), so it would fix only this one call site and leave the
   identical defect for `_editTransaction`/`_editPerson`, failing FR-008
   ("MUST NOT regress... any other Person Details functionality" — those
   flows are currently *accidentally* working only via the same page-key
   coincidence described above, not because they are actually correct).

## Other Investigation Notes

- `AddTransaction`/`RecordRepayment`/`EditTransaction` use cases
  (`lib/features/transactions/domain/usecases/`) are thin, already-correct
  passthroughs to `TransactionsRepository`; no change needed (Principle V —
  each still represents a meaningful, named business action, not a bare
  wrapper, since the repository owns idempotency/audit-entry coordination).
- `TransactionsRepositoryImpl.addTransaction`/`recordRepayment`
  (`transactions_repository_impl.dart:27-90`) already writes the transaction
  row and its audit entry, and `TransactionsDao.insertTransactionIdempotent`
  (`transactions_dao.dart:21-33`) already handles a retried idempotency key
  by returning the existing row instead of erroring — this feature's own
  FR-003/FR-004 are already satisfied by the data layer as-is, which is the
  same underlying idempotency mechanism `001-money-relationships-tracking`
  formally specified as its FR-020 (no separate FR-020 exists in this
  feature's own spec.md — cited here only as the originating requirement).
- `pubspec.yaml`: Dart SDK `^3.10.0`; `flutter_bloc: ^9.1.0`; `go_router: ^14.6.2`
  (resolved `14.8.1`); `drift: ^2.22.1`; `get_it: ^8.0.3` / `injectable: ^2.5.0`;
  `fpdart: ^1.1.1`.
