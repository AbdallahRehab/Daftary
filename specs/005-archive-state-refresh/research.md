# Phase 0 Research: Fix Archive / Unarchive Stale State

**Feature**: `005-archive-state-refresh` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)

All findings below are traced to code read during planning; no behavior is assumed. This feature has no `NEEDS CLARIFICATION` items in Technical Context (it reuses the existing `people` feature's architecture wholesale, per spec Assumptions), so this document is entirely the root-cause investigation and the design decisions it drives.

## Decision 1: Root cause is a missing reload-on-return, not a data-layer defect

**Decision**: The people-list staleness bug is caused by two `context.push(...)` navigation call sites that do **not** await the pushed route and reload the underlying Cubit afterward — while two sibling call sites in the very same files already do. The Domain/Data layers (use cases, repository, DAO, DB schema) are all correct and require no change.

**Rationale — trace of the actual bug**:

1. Both people lists are one-shot fetches, not reactive streams. `PeopleDao.searchActivePeople`/`searchArchivedPeople` (`lib/features/people/data/datasources/people_dao.dart:46-52`) each run a single Drift `.get()` (not `.watch()`), wrapped by `PeopleRepositoryImpl.searchActivePeople`/`searchArchivedPeople` (`lib/features/people/data/repositories/people_repository_impl.dart:182-217`). This is a deliberate, reasonable choice for a filtered/searched list (a `.watch()` stream would need to be re-built per filter combination anyway) — the bug is not "should have used `.watch()`", it is "the one-shot fetch is not re-triggered on every path that can invalidate it."

2. Each list's own Cubit *does* correctly refresh itself after its own action:
   - `PersonListCubit.archive()` awaits `ArchivePerson`, then calls `load()` on success (`lib/features/people/presentation/cubit/person_list_cubit.dart:69-75`) — archiving from the active list removes the row immediately. Correct.
   - `ArchivedPeopleCubit.restore()` awaits `RestorePerson`, then calls `load()` on success (`lib/features/people/presentation/cubit/archived_people_cubit.dart:45-57`) — restoring from the archived list removes the row immediately. Correct.

3. The two people-list screens are **not** separate `StatefulShellRoute` branches (unlike People/Overview/Settings, which keep independent `Navigator`s under an `IndexedStack` — `lib/core/routing/app_router.dart:36-108`, `lib/core/routing/main_shell.dart`). `/people` (`PeopleListPage`) and `/people/archived` (`ArchivedPeoplePage`) are both plain `GoRoute`s inside the **same** People branch `Navigator` (`_peopleBranchNavigatorKey`). Navigating between them is an ordinary `context.push`, so `PeopleListPage` (the branch root) is **never disposed** while `ArchivedPeoplePage` is pushed on top of it — its `BlocProvider<PersonListCubit>` and the Cubit instance it created in `create: (_) => getIt<PersonListCubit>()..load()` (`lib/features/people/presentation/pages/people_list_page.dart:22-24`) persist for the lifetime of that navigator stack entry, carrying whatever state it last held.

4. `PeopleListPage` already establishes the correct fix pattern for two of its four outgoing pushes — and misses it for the other two:
   - `_addPerson` (`people_list_page.dart:184-189`) and `_recordTransaction` (`people_list_page.dart:191-196`) both `await context.push(...)` and then, `if (context.mounted)`, call `context.read<PersonListCubit>().load()`.
   - The AppBar's archived-list button does **not** follow this pattern: `onPressed: () => context.push('/people/archived')` (`people_list_page.dart:49-52`) — fire-and-forget, no reload on return.
   - The person-tile tap into the detail screen also does not: `onTap: () => context.push('/people/${item.person.id}')` (`people_list_page.dart:160`) — fire-and-forget, no reload on return.
   - `ArchivedPeoplePage`'s only outgoing push (into the detail screen, `archived_people_page.dart:82`) has the same gap.

   This is the exact, reproducible mechanism behind the reported bug: user is on `PeopleListPage` → taps the archived icon → `ArchivedPeoplePage` is pushed fresh (its own `BlocProvider` creates a brand-new `ArchivedPeopleCubit` that loads correctly — this is why the archived screen itself always looks right when you *land* on it) → user restores a person → `ArchivedPeopleCubit.restore()` correctly reloads **that** cubit's own list → user presses back → `PeopleListPage` reappears, but it is the **same, never-disposed** `PersonListCubit` instance from before the trip, holding the pre-restore snapshot — the restored person is invisible until something else (a manual pull-to-refresh, or leaving/re-entering the People tab in a way that recreates the branch root) forces `load()` again. This matches FR-001 and the spec's reported bug exactly.

   The symmetric direction (archiving from the active list, then expecting the archived list to show it) does *not* reproduce today only by accident of ordering: `ArchivedPeoplePage` is pushed fresh **every time** (it is not a shell-branch root, so it is never kept alive across a round trip the way `PeopleListPage` is), so its `BlocProvider`'s `..load()` always sees current data on arrival. This is fragile, not a real fix — see Decision 3.

**Alternatives considered**:
- *Convert the DAO queries to `drift`'s reactive `.watch()` and have both Cubits subscribe to a stream.* Rejected as the primary fix: it is a larger architectural change (Cubits would need to hold/cancel stream subscriptions, `BlocProvider` lifetimes would need rethinking so two lists watching the same table don't both need to be alive at once) than the bug requires, and it does not by itself fix the double-tap (FR-006) or filter-preservation (FR-005) requirements — those need explicit handling either way. It is a legitimate future improvement but is not "the smallest shared architectural fix" the spec's Assumptions ask for. Not adopted.
- *Recreate `PersonListCubit` on every People-branch navigation return (e.g. force the branch's `Navigator` to rebuild the root route).* Rejected — fights `go_router`/`StatefulShellRoute`'s intended stack-preservation behavior (the same mechanism that correctly keeps scroll position/search text when the user is only, say, viewing a detail screen and coming straight back without any mutation) and would also reset `nameQuery`/`statusFilter` in-memory state unless carefully preserved, undermining FR-005 for no benefit over reloading with existing state.
- *Add a `RouteObserver`/`RouteAware` mixin to `PeopleListPage` so it reloads on `didPopNext()` regardless of call site.* Considered and closest in spirit to a "cannot be forgotten again" fix (see Decision 3) — deferred in favor of consistently applying the codebase's own existing, already-half-adopted `await push → conditionally reload` convention, since introducing a new cross-cutting navigation abstraction for a two-screen gap is more machinery than the constitution's Architectural Decision Rule (prefer the simplest adequate option) supports here, and every push call site is a handful of small, easily-reviewed screens.

## Decision 2: Relationship to feature 004 (transaction state-refresh)

**Decision**: Document, per the spec's own Assumptions, that this bug is the **same class** of defect as the transaction-list staleness bug tracked in `specs/004-transaction-state-refresh` — a one-shot repository fetch whose owning Cubit is not reloaded on every navigation path that can invalidate it, because the reload is expressed as an ad-hoc per-call-site convention (`await push(); if (mounted) load();`) that is easy to apply inconsistently. This plan was produced **without reading** `specs/004-transaction-state-refresh`'s own artifacts (per task instructions, to keep the two investigations independent); the match is inferred purely from this feature's own code (Decision 1) plus the general shape of the codebase's list-refresh pattern, which is identical for `people` and `transactions` (`PersonDetailPage` in `lib/features/transactions/presentation/pages/person_detail_page.dart:177-210` uses the exact same `await push(...); if (context.mounted) { await ...refresh(); }` convention for its own transaction history list). Both bugs are therefore very likely fixable with the same *shape* of change (apply the existing reload convention exhaustively, and make it harder to omit going forward) even though this plan fully and independently specifies the people-list-specific fix below so it stands on its own regardless of how 004 is ultimately resolved.

**Rationale**: The spec's Assumptions section explicitly directs documenting this finding rather than silently duplicating a fix strategy that may already exist for 004. No code change is made here to any file under `lib/features/transactions/` or `lib/core/` beyond what this feature's own scope requires (Decision 1's two `people` pages).

**Alternatives considered**: Building a single shared `lib/core/` abstraction (e.g. a `ReloadOnReturn` mixin/widget) used by both features in this same PR. Rejected for this feature's scope — feature 004 is being planned independently and in parallel (per task instructions); introducing a shared `core/` abstraction unilaterally from this feature would risk conflicting with whatever 004 lands on, and Principle II (Feature-First Modularity) only promotes something to `core/` once it is *already* used by two or more features with stable behavior, not preemptively. If 004 converges on the same fix shape, promoting a shared helper afterward is a small, low-risk follow-up.

## Decision 3: Make the fix hard to omit again, not just present today

**Decision**: In addition to fixing the two missing call sites, add a code comment at each of the four `context.push(...)` sites in `PeopleListPage`/`ArchivedPeoplePage` cross-referencing this feature, so a future new navigation added to either screen is visibly expected to follow the same convention. A repo-wide `RouteObserver` is not introduced (Decision 1's alternatives).

**Rationale**: The bug this feature fixes was created by an inconsistently-applied convention, not a missing capability — `PeopleListPage` already proved the convention works for two call sites. The cheapest way to prevent regression without new architecture is making the convention impossible to miss at each call site, which is also directly checkable in code review (constitution's Code Review Mode: "does it duplicate existing code? is there a simpler solution?").

**Alternatives considered**: A lint rule or custom `dart_custom_lint` check enforcing "every push in these two files must be followed by a reload." Rejected as disproportionate tooling investment for a two-file, four-call-site surface.

## Decision 4: Filter/search/sort preservation (FR-005, User Story 3) is already structurally correct — verify, don't rebuild

**Decision**: No new mechanism is needed to preserve `nameQuery`/`statusFilter` (active list) or `nameQuery` (archived list) across an archive/unarchive-triggered reload. `load()` on both Cubits already reads the *current* `state.nameQuery`/`state.statusFilter` and re-runs the repository query with those same values (`person_list_cubit.dart:25-31`, `archived_people_cubit.dart:18-23`); `copyWith()` on both states leaves `nameQuery`/`statusFilter` untouched unless a caller explicitly passes a new value (`person_list_state.dart:39-56`, `archived_people_state.dart:23-35`), and `archive()`/`restore()` never pass those parameters. So simply calling the existing `load()` after a returning navigation (Decision 1's fix) reapplies whatever search/filter was already active — it cannot "reset to unfiltered" by construction, and a newly-unarchived/archived person who does not match the active filter/search correctly will not appear (the same `load()` query that excludes them today already excludes them after the fix, satisfying the spec's edge case).

**Rationale**: This closes the loop the spec's Assumptions and User Story 3 raise — the concern that "reload the whole list from scratch" might mean "loses the applied filter" does not apply here, because "the whole list" reload *is* the filtered/searched query, not an unconditional unfiltered fetch. Sort order (User Story 3, Acceptance Scenario 2) is likewise preserved for free: both DAOs `orderBy([(p) => OrderingTerm(expression: p.name)])` (`people_dao.dart:65`) unconditionally, so a reloaded list is always re-sorted by name — there is no separate "sort state" to lose or reapply.

**Alternatives considered**: Introducing a distinct "reapply filters" step separate from `load()`. Rejected — it would duplicate `load()`'s existing query construction for no behavioral difference; `load()` already *is* the correct "reapply current filters" operation.

## Decision 5: No-duplicate-transition guard for rapid double-tap (FR-006)

**Decision**: Add a `processingPersonId` (or equivalent) field to `PersonListState` and `ArchivedPeopleState` that the `archive()`/`restore()` methods set before calling the use case and clear afterward, short-circuiting a re-entrant call for the same person while one is already in flight; the corresponding archive/restore UI control is disabled for that row while `processingPersonId` matches it.

**Rationale**: Today, `PersonListCubit.archive()` and `ArchivedPeopleCubit.restore()` (`person_list_cubit.dart:69-75`, `archived_people_cubit.dart:45-57`) have no in-flight guard, and `PersonListTile`'s archive `IconButton` (`lib/features/people/presentation/widgets/person_list_tile.dart:40-44`) and `ArchivedPeoplePage`'s restore `TextButton` (`archived_people_page.dart:83-88`) are never disabled. A rapid double-tap today fires the use case twice concurrently. Because `PeopleDao.setArchived` (`people_dao.dart:92-99`) is an idempotent `UPDATE ... SET is_archived = ?`, a double-invocation cannot corrupt the stored `isArchived` value or create a duplicate row (FR-004's "never appears more than once" is protected at the schema level: `id` is the primary key), but it does violate FR-006's "exactly one state transition" requirement (constitution's Duplicate Action Protection standard) — the two concurrent `load()` calls triggered by two overlapping `archive()`/`restore()` calls can interleave and cause a visible flicker or redundant work, and there is no reason to submit the mutation twice. Guarding it is a small, self-contained Cubit-state change, consistent with Principle IV (explicit state fields over ad-hoc booleans scattered in widgets) and Principle III's requirement that a Cubit "avoid duplicate in-flight requests."

**Alternatives considered**: A widget-local `bool _isProcessing` flag inside `PersonListTile`/the archived list item. Rejected — Principle III requires presentation state to live in the Cubit, not scattered local `State` fields, and a Cubit-level guard also protects against a double-tap arriving as two separate `context.read<...>().archive(id)` calls from different code paths, not just two taps on the same rendered button instance.

## Note: User Story 4 / FR-010 (`person_form_page.dart`) decision rationale lives in feature 004

This feature's User Story 4 (spec.md FR-010, tasks.md T030-T033) fixes
`lib/features/people/presentation/pages/person_form_page.dart`'s `context.go()`
navigation defect — the same root-cause bug class this feature's Decisions 1-3 fix for
archive/unarchive. The full investigation and the `Navigator.pop()`-based fix pattern it
mirrors are documented in `specs/004-transaction-state-refresh/research.md`
("Same defect also present in the People feature" and its "Decision" section) rather than
duplicated here, since that feature's research already covers the identical defect for the
sibling `transaction_form_page.dart` case in full.

## Technology/version confirmation

Read directly from `pubspec.yaml` (repo root) — matches feature 002's plan, no version drift since:
- Dart SDK `^3.10.0`; `flutter_bloc: ^9.1.0`; `equatable: ^2.0.5`; `get_it: ^8.0.3`; `injectable: ^2.5.0`; `drift: ^2.22.1` / `drift_dev: ^2.22.1`; `fpdart: ^1.1.1`; `go_router: ^14.6.2`; `bloc_test: ^10.0.0`; `mocktail: ^1.0.4`.

No new dependency is required by this fix.
