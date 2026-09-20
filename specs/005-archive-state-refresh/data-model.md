# Phase 1 Data Model: Fix Archive / Unarchive Stale State

**Feature**: `005-archive-state-refresh` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)

This is a correctness fix to existing presentation-layer state, not a new domain model. Nothing in the Domain or Data layers changes (research.md Decision 1) — the two entities below are the spec's Key Entities, documented to the extent this feature touches them.

## Entity: Person (unchanged)

Defined in `lib/features/people/domain/entities/person.dart:4-63`; persisted via the `People` Drift table (`lib/core/database/app_database.dart:13-27`). No fields, validation, or schema version change in this feature.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Primary key (UUID v4) |
| `name` | `String` | Non-empty after trim |
| `isArchived` | `bool` | The field this feature's list-visibility bug centers on. `false` → visible in the active list; `true` → visible in the archived list. Mutually exclusive by construction — a person row has exactly one `isArchived` value at any instant, so "appears in both lists" (FR-004) cannot happen at the data layer; it could previously appear to happen in the UI only because of the stale-Cubit bug this feature fixes (research.md Decision 1). |
| `updatedAt` | `DateTime` (stored as epoch ms `int`) | Set to "now" by both `PeopleRepositoryImpl.archivePerson` and `.restorePerson` (`people_repository_impl.dart:136-161`) whenever `isArchived` changes. Unchanged by this feature. |
| *(other fields)* | — | `phoneNumber`, `avatarPath`, `relationshipTag`, `notes`, `createdAt` — untouched by archive/restore, unchanged by this feature. |

**State transition** (unchanged business rule, now correctly reflected in the UI by this feature):

```
active (isArchived=false) --archive()--> archived (isArchived=true)
archived (isArchived=true) --restore()--> active (isArchived=false)
```

Both transitions are unconditional (no precondition on balance/transaction count — `archive_person.dart:7-8`, `restore_person.dart:7`).

## Entity: People List View State (this feature's actual change)

The spec's "People List View State" entity — the search term, sort order, and filter currently applied to each list — already exists as two separate immutable Cubit states, one per list, per constitution Principle IV. This feature adds one field to each to satisfy FR-006 (no double-transition); no other field changes.

### `PersonListState` (active list) — `lib/features/people/presentation/cubit/person_list_state.dart`

| Field | Type | Status | Notes |
| --- | --- | --- | --- |
| `status` | `PersonListStatus` (`loading`/`success`/`failure`) | unchanged | |
| `items` | `List<PersonListItem>` (`Person` + `PersonBalance`) | unchanged | Result of the current filtered/sorted query |
| `nameQuery` | `String` | unchanged | The active search term; preserved across reload by construction (research.md Decision 4) — `load()` reads it, never resets it |
| `statusFilter` | `RelationshipStatus?` | unchanged | The active relationship-status filter (FR-019 from feature 001); same preservation guarantee |
| `errorMessage` | `String?` | unchanged | |
| **`processingPersonId`** | **`String?`** | **NEW** | Non-null while an `archive()` call is in flight for that person id; `archive()` is a no-op re-entrancy guard when called again with the same id while it is already set (FR-006). Cleared once the use case call (success or failure) completes and, on success, the subsequent `load()` has emitted. |

Sort order is implicit (always name-ascending via `ORDER BY name` in `PeopleDao._searchByArchiveState`, `people_dao.dart:65`) — there is no separate sort field to model or preserve.

### `ArchivedPeopleState` (archived list) — `lib/features/people/presentation/cubit/archived_people_state.dart`

| Field | Type | Status | Notes |
| --- | --- | --- | --- |
| `status` | `ArchivedPeopleStatus` (`loading`/`success`/`failure`) | unchanged | |
| `people` | `List<Person>` | unchanged | Result of the current filtered/sorted query |
| `nameQuery` | `String` | unchanged | The archived list's own search term (spec Clarifications session 2026-09-20: symmetric preservation with the active list); preserved across reload the same way |
| `errorMessage` | `String?` | unchanged | |
| **`processingPersonId`** | **`String?`** | **NEW** | Same guard as above, applied to `restore()` (FR-006) |

Both `copyWith()` implementations keep their existing "field unset ⇒ keep prior value" semantics (Principle IV); `processingPersonId` follows the same convention (`String?` param, `null` default meaning "no explicit change" is not expressible for a nullable field the normal way — see plan.md's Constitution Check table, Principle IV row, for how this is resolved, mirroring the existing `clearStatusFilter` boolean-flag pattern already used for `statusFilter`).

## Validation rules

Unchanged from feature 001 — this feature adds no new validation. The only new invariant is behavioral, not a field-validation rule: **while `processingPersonId == id` for a given person, that person's archive/restore control MUST be disabled** (FR-006), enforced in `PersonListTile`/`ArchivedPeoplePage`'s list item by disabling the control's `onPressed` when `processingPersonId` (via `BlocSelector`) matches the row's person id.

## Relationships

No new relationships. `Person.id` remains the sole join key used by `PersonListItem` (pairs a `Person` with its `PersonBalance`, computed by `GetPersonBalance` from `MoneyTransactions`, unchanged) and by the archived list's plain `Person` rows.
