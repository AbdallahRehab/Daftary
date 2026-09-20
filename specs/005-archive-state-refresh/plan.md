# Implementation Plan: Fix Archive / Unarchive Stale State

**Branch**: `005-archive-state-refresh` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-archive-state-refresh/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

The reported bug — an unarchived person not appearing in the active people list without a manual reload — is caused by a **Presentation-layer navigation gap**, not a data or state-shape defect. `PeopleListPage` (the People tab's shell-branch root) is never disposed while `ArchivedPeoplePage` is pushed on top of it in the same branch `Navigator`, so its `PersonListCubit` instance survives a round trip to the archived list carrying its pre-trip snapshot. Two of `PeopleListPage`'s four outgoing `context.push(...)` calls already follow the correct `await push(...); if (context.mounted) { load(); }` pattern (`_addPerson`, `_recordTransaction`); the other two — the AppBar's archived-list button and the person-tile tap into the detail screen — do not, and neither does `ArchivedPeoplePage`'s own push into the detail screen. The fix applies that same, already-proven pattern to the three missing call sites (research.md Decision 1), which — because `load()` on both Cubits always re-reads and re-applies the current `nameQuery`/`statusFilter` from state rather than resetting it — automatically satisfies FR-005's search/sort/filter preservation for free (research.md Decision 4). Separately, `PersonListCubit.archive()` and `ArchivedPeopleCubit.restore()` gain a `processingPersonId` re-entrancy guard to satisfy FR-006 (no double state transition on a rapid double-tap), since neither currently guards against a concurrent re-invocation. No Domain, Data, or database-schema change is required (contracts/people_repository.md). Per the spec's own Assumptions, research.md documents that this is the same *class* of bug as `specs/004-transaction-state-refresh` (a one-shot fetch whose reload is expressed as an easy-to-omit per-call-site convention) without depending on or duplicating that feature's own investigation. This feature's scope additionally closes the specific cross-feature handoff `specs/004-transaction-state-refresh/research.md` (lines 157-170) left for it: `lib/features/people/presentation/pages/person_form_page.dart`'s save-success (`context.go('/people/${saved.id}')`, line 94) and duplicate-pick (`context.go('/people/${person.id}')`, line 79) branches carry the identical `context.go()`-vs-`context.pop()` defect, fixed here using the same `Navigator.pop()`-based pattern as `specs/004-transaction-state-refresh` applied to the transactions flow (FR-010, User Story 4).

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter (via `flutter_bloc`/`go_router` deps below — no separate Flutter SDK pin found beyond the Dart constraint, matching feature 002's plan)

**Primary Dependencies**: `flutter_bloc: ^9.1.0` (existing `PersonListCubit`/`ArchivedPeopleCubit`, Principle III — no new Cubit, only new state fields and guard logic on the two existing ones); `go_router: ^14.6.2` (the `context.push(...)` call sites being fixed, within the existing People `StatefulShellBranch` — `lib/core/routing/app_router.dart`); `drift: ^2.22.1` (existing one-shot `PeopleDao` queries, unchanged — research.md Decision 1); `get_it: ^8.0.3` + `injectable: ^2.5.0` (existing DI wiring, unchanged); `fpdart: ^1.1.1` (existing `Either<Failure, Success>` flow through `ArchivePerson`/`RestorePerson`, unchanged); `equatable: ^2.0.5` (state value-equality, extended by one new field per state). No new package dependency.

**Storage**: Local SQLite via the existing `drift` `AppDatabase` — no schema change; `People.isArchived` (already present, `lib/core/database/app_database.dart:21`) remains the single source of truth for list membership (data-model.md)

**Testing**: `flutter_test` (unit/widget) extending the existing `test/features/people/presentation/cubit/person_list_cubit_test.dart` and `test/features/people/presentation/cubit/archived_people_cubit_test.dart`; `bloc_test` + `mocktail` for the new `processingPersonId` guard behavior; widget tests for `PeopleListPage`/`ArchivedPeoplePage` covering the newly-added reload-on-return; a new `integration_test/archive_state_refresh_flow_test.dart` exercising quickstart.md's Scenarios 1-3 end-to-end (archive → navigate → restore → return, with a search term applied)

**Target Platform**: Android and iOS mobile apps (existing `android/`/`ios/` platform folders, matching features 001/002) — no new platform surface

**Project Type**: mobile-app (Flutter, feature-first clean architecture) — a correctness fix entirely within the existing `people` feature (`lib/features/people/`), touching two of its `presentation` files plus their state classes; no new feature module

**Performance Goals**: The fixed reload (an extra `load()` call on return from `/people/archived` or `/people/:id`) must not introduce a perceptible delay or loading-spinner flash beyond what the existing `_addPerson`/`_recordTransaction` reload-on-return already exhibits today (same query, same list size) — no new performance goal beyond "as fast as the pattern this feature is extending"

**Constraints**: "Immediately" means within the same interaction/screen-refresh cycle, no manual reload step (spec Assumptions); the fix must reuse the existing state-management architecture rather than introduce a new one (spec Assumptions — ruling out, e.g., a new reactive-stream Cubit design per research.md Decision 1); FR-005/FR-009 require the fix not regress existing correct search/sort/filter/view/add/edit behavior

**Scale/Scope**: 3 presentation files changed (`people_list_page.dart`, `archived_people_page.dart`, `person_form_page.dart` — FR-010/User Story 4, closing the `specs/004-transaction-state-refresh` handoff), 2 Cubits + 2 states changed (`person_list_cubit.dart`/`person_list_state.dart`, `archived_people_cubit.dart`/`archived_people_state.dart`), 1 widget changed to surface the in-flight guard (`person_list_tile.dart`) plus the inline restore button in `archived_people_page.dart`; 0 Domain/Data/schema files changed

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
| --- | --- | --- |
| I. Clean Architecture Layering | Fix is entirely within Presentation (`PeopleListPage`/`ArchivedPeoplePage`/their Cubits); no Domain or Data file changes (contracts/people_repository.md confirms no interface change); Presentation still only calls `PeopleRepository` through the existing `ArchivePerson`/`RestorePerson` use cases, never the DAO/DB directly | PASS |
| II. Feature-First Modularity | All changes stay inside `lib/features/people/`; no new `core/` abstraction is introduced even though the same bug class likely affects `transactions` (research.md Decision 2) — Principle II only promotes to `core/` once genuinely shared and stable, which is not yet true across the two independently-planned fixes | PASS |
| III. BLoC/Cubit Mandate | No new state-management paradigm; `PersonListCubit`/`ArchivedPeopleCubit` remain the sole state holders. The new `processingPersonId` guard is exactly what this principle asks for explicitly ("avoid duplicate in-flight requests") — previously absent, now added | PASS |
| IV. Immutable State | `processingPersonId` is added to both states via the existing `copyWith()` pattern (Equatable value classes); no state is mutated in place; `data-model.md` documents the one non-trivial nuance — nulling out a nullable field via `copyWith` needs the same explicit-clear-flag pattern already used for `statusFilter`'s `clearStatusFilter` (`person_list_state.dart:44,51-53`), applied consistently rather than introduced as a new idiom | PASS |
| V. Domain-Driven Business Logic | `ArchivePerson`/`RestorePerson` use cases are unchanged — they already represent the correct business actions; this fix does not add, remove, or dilute a use case | PASS (N/A change) |
| VI. Repository Pattern | `PeopleRepository`'s interface is unchanged (contracts/people_repository.md); Presentation continues to depend only on the abstraction via DI | PASS |
| VII. Explicit Error Handling | No change to failure handling — `archive()`/`restore()` still route `Left(Failure)` to `errorMessage` in state (FR-007); the new guard clears `processingPersonId` on both the success and failure branches so a failed attempt does not permanently lock the control | PASS |
| VIII. Deterministic Financial Calculations | Not applicable — no financial calculation in this feature (people archive status is not a monetary value) | PASS (N/A) |
| IX. AI Isolation | Not applicable — no AI integration | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Fully local, no network/sync involved. `setArchived` (`people_dao.dart:92-99`) is an idempotent `UPDATE`, so the FR-006 guard is a UX/duplicate-request concern, not a data-corruption risk (research.md Decision 5) — consistent with this principle's duplicate-submission-prevention intent even though it's framed there around sync | PASS |
| XII. Security & Secrets | No secrets, credentials, or sensitive-data handling touched by this fix | PASS (N/A) |
| XIII. Localization & RTL/LTR | No new user-facing strings are introduced (the fix is behavioral, not textual) — if a disabled-state visual affordance is added for the in-flight guard it reuses existing design-system disabled styling, not a new string; existing `l10n.restoreAction`/archive tooltip strings are unchanged | PASS |
| XIV. Dependency Injection | No new dependency to wire; `PersonListCubit`/`ArchivedPeopleCubit` continue to be resolved via `getIt<...>()` in their pages, unchanged | PASS |
| XV. Design System | The archive/restore controls' disabled-while-processing appearance uses the existing `IconButton`/`TextButton` disabled state (no new hardcoded colors/styles) | PASS |
| XVI. Testability by Design | `bloc_test` coverage added for: (a) `load()` after a simulated return preserving `nameQuery`/`statusFilter`, (b) `processingPersonId` guard rejecting a re-entrant `archive()`/`restore()` call, (c) the guard clearing on both success and failure; widget tests added for the reload-on-return at each fixed `context.push` call site; one new `integration_test` end-to-end scenario (Technical Context → Testing) | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): Design confirmed no Domain/Data/schema change was needed (contracts/people_repository.md documents this explicitly rather than fabricating an interface diff) and that FR-005's filter/sort/search preservation requires no new mechanism beyond calling the existing `load()` (data-model.md, research.md Decision 4) — both reduce this feature's footprint below what Technical Context originally allowed for, not beyond it. The one new field (`processingPersonId`) on each state is the minimal shape needed for FR-006 and was sized down during design from an initially-considered `Set<String>` of in-flight ids (unnecessary — the UI can only realistically double-tap one row's control at a time; a single nullable id is sufficient and simpler, per the Architectural Decision Rule). No new dependency, layering, or state-management deviation was introduced beyond what the Constitution Check above already accounted for; all gates remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/005-archive-state-refresh/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── people_repository.md   # No-interface-change note (contracts/people_repository.md)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
└── features/
    └── people/
        └── presentation/
            ├── cubit/
            │   ├── person_list_cubit.dart        # archive(): add processingPersonId re-entrancy guard
            │   ├── person_list_state.dart         # +processingPersonId field (data-model.md)
            │   ├── archived_people_cubit.dart     # restore(): add processingPersonId re-entrancy guard
            │   └── archived_people_state.dart     # +processingPersonId field (data-model.md)
            ├── pages/
            │   ├── people_list_page.dart           # Fix: await+reload on the archived-list push (AppBar
            │   │                                    #   icon) and the person-detail push (tile onTap) —
            │   │                                    #   the two call sites missing the pattern already
            │   │                                    #   used by _addPerson/_recordTransaction
            │   ├── archived_people_page.dart        # Fix: await+reload on the person-detail push;
            │   │                                     #   restore button disabled while processingPersonId
            │   │                                     #   matches the row
            │   └── person_form_page.dart             # Fix (FR-010/US4): save-success (line 94) and
            │                                          #   duplicate-pick (line 79) context.go() branches
            │                                          #   replaced with Navigator.pop()-based navigation,
            │                                          #   closing the specs/004-transaction-state-refresh
            │                                          #   handoff (research.md lines 157-170)
            └── widgets/
                └── person_list_tile.dart            # Archive IconButton disabled while processingPersonId
                                                       #   matches this row's person id

test/
├── features/
│   └── people/
│       └── presentation/
│           └── cubit/
│               ├── person_list_cubit_test.dart      # + processingPersonId guard cases, + load()-preserves-
│               │                                     #   filter-after-external-mutation case
│               └── archived_people_cubit_test.dart  # + processingPersonId guard cases
└── widget/
    ├── people_list_page_test.dart        # NEW — reload-on-return from archived-list push and detail push
    ├── archived_people_page_test.dart    # NEW — reload-on-return from detail push; restore button disables
    └── person_form_page_test.dart        # NEW (FR-010/US4) — save-success and duplicate-pick branches
                                            #   pop (not go()) when reached via a pushed route

integration_test/
└── archive_state_refresh_flow_test.dart  # NEW — end-to-end: archive → navigate to archived list →
                                            #   restore → return → person visible in active list
                                            #   immediately, filter/search preserved (quickstart.md
                                            #   Scenarios 1-3)
```

**Structure Decision**: Same single Flutter app shape as features 001/002 (Option 1) — no new project, no new feature module. Every change lives inside the existing `lib/features/people/presentation/` layer, matching this being a Presentation-only bug fix (Constitution Check, Principle I/II). Tests continue to mirror `lib/` under `test/`, plus one new scenario under `integration_test/` alongside the existing `integration_test/language_switch_flow_test.dart` from feature 002. No `lib/core/` file is touched — the navigation-reload pattern being fixed is applied at each existing call site (research.md Decision 1/3), not extracted into a shared cross-cutting helper, since it is not yet used identically by a second feature (Principle II).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
