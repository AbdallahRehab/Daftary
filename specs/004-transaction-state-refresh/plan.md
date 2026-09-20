# Implementation Plan: Fix Stale State After Adding Money / Transactions

**Branch**: `004-transaction-state-refresh` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-transaction-state-refresh/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Root cause (see `research.md` for the full trace): `PersonDetailPage`
already implements a correct "push the form, then refresh on return" idiom
for every mutation flow (`_recordTransaction`, `_editTransaction`,
`_recordRepayment`, `_editPerson` — `person_detail_page.dart:177-210`), and
`PersonDetailCubit.refresh()` correctly re-runs the one-shot balance/history
fetch. But `TransactionFormPage` — the screen behind the exact "add
transaction" flow the bug reports — never actually returns control to that
awaited `context.push(...)`: on every successful save it calls
`context.go('/people/${savedTransaction.personId}')`
(`transaction_form_page.dart:100`) instead of popping. go_router's `go()`
replaces the entire route match list and never completes the `Completer`
backing the caller's `push()` `Future` (confirmed against the installed
`go_router` 14.8.1 source, `parser.dart`'s `NavigatingType.go` case) — so the
caller's `if (context.mounted) { await ...refresh(); }` is unreachable dead
code on the success path. Whether the user nonetheless sees correct data
becomes an accident of whether Flutter's `Navigator` happens to mount a
brand-new `PersonDetailPage`/`PersonDetailCubit` for the `go()`-landed-on
route (fresh, page-key mismatch with anything already on the stack) or
reuses an existing, now-stale one already present in the branch's navigation
stack (matching page key) — which is exactly the "sometimes" the bug report
describes, and why "reload/reopen the app" (which always forces a fresh
mount) is the workaround users found. The fix is entirely a Presentation-
layer navigation correction: make the post-save transition a real
`Navigator` pop (mirroring `RepaymentFormPage`'s already-correct
`Navigator.of(context).pop(true)`) so the existing, already-correct
`push()`-then-`refresh()` idiom on `PersonDetailPage` actually fires every
time, deterministically, regardless of prior navigation history — with the
caller (not the form) responsible for any subsequent "jump to the person's
detail page" navigation when the form was opened without a bound `personId`.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.38 stable

**Primary Dependencies**: `flutter_bloc: ^9.1.0` (existing `PersonDetailCubit`/
`TransactionFormCubit`/`RepaymentFormCubit` — no new Cubit, no new state-
management paradigm); `go_router: ^14.6.2` (resolved `14.8.1`) — the fix
changes *which* `go_router` navigation primitive is called
(`Navigator.pop`/`context.pop` vs `context.go`) on an existing
`StatefulShellRoute.indexedStack` "People" branch, it does not restructure
routes; `drift: ^2.22.1` (existing one-shot `TransactionsDao` queries,
confirmed unchanged — see `research.md` "No reactive data layer to fall
back on"); `get_it: ^8.0.3` + `injectable: ^2.5.0` (existing DI, unchanged);
`fpdart: ^1.1.1` (existing `Either<Failure, Success>` flow, unchanged)

**Storage**: Local SQLite via the existing `drift` `AppDatabase` /
`money_transactions` table — no schema change, no migration

**Testing**: `flutter_test` (widget tests — new coverage needed at the
navigation-glue level, since the existing `bloc_test`-based
`PersonDetailCubit`/`TransactionFormCubit` unit tests already pass today and
cannot, by construction, catch a bug that lives in the navigation code
connecting two independently-correct cubits); `bloc_test` + `mocktail` for
any cubit-level assertions added incidentally; `integration_test` (optional,
following the `language_switch_flow_test.dart` precedent) for an end-to-end
add-transaction-see-it-immediately regression check

**Target Platform**: Android and iOS mobile apps (existing `android/`/`ios/`
platform folders; unchanged)

**Project Type**: mobile-app (Flutter, feature-first clean architecture) —
bug fix confined to the existing `transactions` feature's Presentation layer
(and, transitively, its route wiring in `core/routing/`); no new feature
module

**Performance Goals**: No new performance goal beyond SC-001/SC-002 — the
fix must not introduce a visible delay/flash between save and the updated
Person Details screen (a real `pop()` is strictly cheaper than the current
`go()`, which rebuilds the whole branch's match list, so no regression risk)

**Constraints**: Must not change `TransactionsRepository`'s public contract,
`PersonDetailState`/`TransactionFormState` shape, or any Domain/Data code
(root cause and fix are both Presentation-layer navigation only — see
`research.md`/`contracts/README.md`); must preserve the existing "jump
straight to the newly-created person's Detail page" behavior for the
global (`PeopleListPage`) add-transaction FAB, which has no `personId`
pre-bound and today relies on the same (broken) `context.go(...)` call; must
not regress `_editTransaction`/`_editPerson` (FR-008), which share the
identical defect today (see `research.md`) and must be fixed alongside the
reported add-transaction case rather than left as latent bugs

**Scale/Scope**: A navigation-glue fix touching a small, fully-enumerated set
of existing files — no new files/folders. In scope: `transaction_form_page.dart`
(post-save navigation), `person_detail_page.dart` (caller-side navigation for
the personId-less case, if the person-picker path is retained there instead
of purely in the form), `people_list_page.dart` (`_recordTransaction`'s
caller-side follow-up navigation to the newly created person). Out of scope:
`person_form_page.dart`'s analogous defect (noted in `research.md` as shared
root cause relevant to `005-archive-state-refresh`, explicitly not touched
here) and any live-refresh of Overview/People List while already open
(spec Clarification: next-view correctness only for those screens)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
| --- | --- | --- |
| I. Clean Architecture Layering | Fix is entirely within Presentation (page-level navigation calls); no Domain/Data code touched; `PersonDetailCubit`/`TransactionFormCubit` continue to depend only on their existing use cases | PASS |
| II. Feature-First Modularity | All changed files already live under `lib/features/transactions/presentation/pages/` (and `lib/features/people/presentation/pages/people_list_page.dart`, same feature area as the trigger site); no new catch-all folder, no code moved into `core/` | PASS |
| III. BLoC/Cubit Mandate | No new state-management paradigm — the fix makes the *existing* `PersonDetailCubit.refresh()` call (already written, already correct) actually execute reliably by fixing the navigation completer chain that was silently swallowing it; this is precisely "avoid/resolve race conditions," the exact gap this principle calls out | PASS |
| IV. Immutable State | No state shape changes; `PersonDetailState`/`TransactionFormState` `copyWith()`-based immutability is untouched | PASS |
| V. Domain-Driven Business Logic | No use case changes; `AddTransaction`/`EditTransaction`/`RecordRepayment` already represent real business actions and are confirmed correct in `research.md` | PASS |
| VI. Repository Pattern | No `TransactionsRepository`/`TransactionsRepositoryImpl` change — confirmed unnecessary in `contracts/README.md` | PASS |
| VII. Explicit Error Handling | No change to `Either<Failure, T>` flow; the failure path (`TransactionFormStatus.failure`) already pops correctly today via a real `Navigator.pop()` on back-navigation and is unaffected by this fix | PASS |
| VIII. Deterministic Financial Calculations | Not applicable — `PersonBalance.net` computation (`SUM` over non-deleted rows) is unchanged; the bug was never in the calculation, only in when it was re-triggered | PASS (N/A) |
| IX. AI Isolation | Not applicable — no AI integration in this feature | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Not applicable to the fix itself (fully local, no network); the *existing* idempotency-key handling (`TransactionsDao.insertTransactionIdempotent`, FR-003/FR-004) is confirmed already correct and untouched by this fix | PASS (N/A) |
| XII. Security & Secrets | Not applicable — no secrets/credentials/sensitive-data handling in navigation code | PASS (N/A) |
| XIII. Localization & RTL/LTR | Not applicable — no new user-facing strings, no layout change; existing localized snackbars/labels on the touched pages are untouched | PASS (N/A) |
| XIV. Dependency Injection | Not applicable — no new dependency introduced; existing `getIt<PersonDetailCubit>()`/`getIt<TransactionFormCubit>()` wiring is unchanged | PASS (N/A) |
| XV. Design System | Not applicable — no visual/design-token change; this is a navigation-timing fix with no new widget | PASS (N/A) |
| XVI. Testability by Design | The bug's existence despite passing cubit unit tests is itself evidence that navigation-glue behavior needs its own test coverage; `quickstart.md`'s Automated Coverage Plan calls for new widget-level tests asserting the real `push()`→pop()→`refresh()` chain fires, plus a double-add regression test for the specific intermittency `research.md` identifies, before this fix is considered done | PASS (tests to be added — no violation, but flagged as required follow-through, not optional) |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`):
`data-model.md` confirms no entity/state-shape change was needed once the
actual defect (navigation, not data) was isolated; `contracts/README.md`
confirms `TransactionsRepository`'s interface needs no change. Nothing
discovered during Phase 1 design widened the fix's surface area beyond what
the Constitution Check above already accounted for — specifically, the
Phase 1 pass did *not* surface a need to touch `person_form_page.dart`
(the People feature's analogous defect, `research.md` "Same defect also
present in the People feature") to satisfy this feature's FRs, so it remains
correctly out of scope here and is left as a pointer for `005-archive-state-refresh`
planning rather than pulled in unscoped. All gates remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/004-transaction-state-refresh/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command) — root-cause trace
├── data-model.md         # Phase 1 output — confirms no entity/state-shape change needed
├── quickstart.md         # Phase 1 output — manual + automated validation of US1-US3
├── contracts/            # Phase 1 output — confirms no repository-interface change needed
│   └── README.md
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
└── features/
    ├── transactions/
    │   └── presentation/
    │       ├── pages/
    │       │   ├── transaction_form_page.dart   # FIX: post-save navigation — real pop()
    │       │   │                                  (carrying `savedTransaction`) instead of
    │       │   │                                  context.go(...), so the caller's existing
    │       │   │                                  `await push(); refresh();` idiom resolves.
    │       │   │                                  Applies to both create and edit mode (same
    │       │   │                                  widget/cubit), fixing `_editTransaction`
    │       │   │                                  (FR-008 no-regression) alongside the
    │       │   │                                  reported add-transaction bug.
    │       │   └── person_detail_page.dart       # No behavioral change expected to
    │       │                                       `_recordTransaction`/`_editTransaction`
    │       │                                       themselves (their push+refresh idiom was
    │       │                                       already correct) — touched only if the
    │       │                                       popped `MoneyTransaction?` result needs to
    │       │                                       be read here (e.g. to confirm which
    │       │                                       transaction was saved for a snackbar/assert
    │       │                                       in tests); no new fields, no new widgets.
    │       └── (cubit/, domain/, data/ unchanged — see data-model.md and contracts/README.md)
    │
    └── people/
        └── presentation/
            └── pages/
                └── people_list_page.dart          # FIX: `_recordTransaction`'s post-`push()`
                                                      follow-up — after the form (opened with no
                                                      personId) pops with the saved transaction,
                                                      explicitly `context.push('/people/$id')` to
                                                      the new transaction's person, preserving
                                                      today's "jump to that person" UX without
                                                      routing it through the form's own go().

test/
├── features/
│   └── transactions/
│       └── presentation/
│           └── cubit/                             # Existing person_detail_cubit_test.dart /
│                                                     transaction_form_cubit_test.dart already
│                                                     pass and need no change (bug is not in
│                                                     either cubit — see research.md); left as-is.
└── widget/                                         # NEW test(s) here — this app's existing
                                                       convention for page/navigation-level tests
                                                       (mirrors main_shell_test.dart /
                                                       settings_page_test.dart) — asserting the
                                                       push()→pop()→refresh() chain fires and the
                                                       double-add intermittency from research.md
                                                       does not reproduce.

integration_test/
└── (optional) transaction_add_refresh_flow_test.dart   # Following the existing
                                                           language_switch_flow_test.dart
                                                           precedent — end-to-end US1/US2 check.
```

No new `lib/` feature folders, no new Domain entities/use cases/repository
methods, and no database migration are introduced by this fix — see
`data-model.md` and `contracts/README.md` for the explicit confirmation that
Phase 1 design did not surface a need for any of those.

**Structure Decision**: Same single Flutter app shape as features 001/002
(Option 1) — no structural change. This feature adds no new feature module
and no new top-level folder; every touched file already exists under
`lib/features/transactions/presentation/pages/` or
`lib/features/people/presentation/pages/`, consistent with Principle II
(fix lives where the bug lives, not hoisted into `core/`). Tests continue to
mirror `lib/` under `test/`, with new page/navigation-level coverage added
under `test/widget/` alongside this app's existing precedent for that kind of
test (`main_shell_test.dart`, `settings_page_test.dart`), plus an optional
`integration_test/` addition mirroring `language_switch_flow_test.dart`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
