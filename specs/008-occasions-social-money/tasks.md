---

description: "Task list for Occasions / Social Money (feature 008)"
---

# Tasks: Occasions / Social Money

**Input**: Design documents from `/specs/008-occasions-social-money/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included, consistent with 001's precedent (constitution Principle XVI). Each user story's tests are written before its implementation tasks (TDD ordering).

**Balance formula (read before Foundational/US1-US3)**: Per data-model.md's "Balance computation (updated)" note, `PersonBalance.netMinorUnits` = `SUM(direction=given) − SUM(direction=received)` over non-deleted rows where `kind != occasionContribution OR counts_toward_balance = TRUE`. This is additive to 001's existing formula — no change to how non-occasion rows are summed.

**Organization**: Tasks are grouped by user story (spec.md priorities P1-P3) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Maps to spec.md user stories (US1-US5)
- File paths follow plan.md's Project Structure exactly

## Path Conventions

Single Flutter app, feature-first per constitution Principle II: `lib/core/`, `lib/features/occasions/{data,domain,presentation}`, plus an additive extension inside the existing `lib/features/transactions/`; `test/` mirrors `lib/`; `integration_test/` for end-to-end flows.

---

## Phase 1: Setup

**Purpose**: Add the one new dependency and directory skeleton this feature needs on top of the existing app.

- [X] T001 Add `image_picker` (or equivalent MIT-licensed capture/gallery-selection package, pinned to the latest stable version compatible with Flutter 3.47.0) to `pubspec.yaml` dependencies; run `fvm flutter pub get` to confirm resolution (research.md Decision 7).
- [X] T002 [P] Create the directory skeleton: `lib/core/media/`, `lib/features/occasions/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/core/media/`, `test/features/occasions/{domain/usecases,data/repositories,presentation/cubit}/`.
- [X] T003 [P] Add `<uses-permission>`/`Info.plist` entries for camera and photo-library access (Android `AndroidManifest.xml`, iOS `Info.plist`), each with a user-facing usage-description string, requested contextually at first use per constitution Engineering Standards (not at app startup).

**Checkpoint**: Dependencies resolve, directories exist, platform permission declarations are in place.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema/entity changes every user story depends on — the `Occasions`/`OccasionAttachments` tables, the `MoneyTransaction` extension, and the shared attachment-picker abstraction.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Extend `lib/features/transactions/domain/entities/money_transaction.dart`: add `occasionContribution` to `TransactionKind`; add `occasionId` (`String?`, FK → `Occasion.id`, non-null only when `kind = occasionContribution` — data-model.md) and `countsTowardBalance` (`bool`, default `true`) fields to `MoneyTransaction`; update `props`/constructor accordingly. This is additive only — existing `initialExchange`/`repayment` behavior from 001 is unchanged.
- [X] T005 [P] Define the `Occasion` entity in `lib/features/occasions/domain/entities/occasion.dart` (`Equatable`): `id`, `idempotencyKey`, `name` (required, non-empty after trim), `date`, `type` (`String`, required non-empty), `notes?`, `isArchived` (default `false`), `createdAt`, `updatedAt`, `deletedAt?`, per data-model.md.
- [X] T006 [P] Define the standard `OccasionType` constant list (`wedding`, `engagement`, `birthday`, `newbornSebou`, `condolence`, `celebration`, `other`) in `lib/features/occasions/domain/entities/occasion_type.dart`, plus a helper distinguishing a standard value from free-text custom input, mirroring `Person.relationshipTag`'s pattern (research.md Decision 6).
- [X] T007 [P] Define the `OccasionAttachment` entity in `lib/features/occasions/domain/entities/occasion_attachment.dart` (`Equatable`): `id`, `occasionId`, `filePath`, `createdAt`, `deletedAt?`.
- [X] T008 [P] Define the `OccasionSummary` value object (`occasionId`, `totalReceivedMinorUnits`, `totalGivenMinorUnits`, `netMinorUnits`, `settlementStatus` enum `settled`/`moreReceived`/`moreGiven`, `participantCount`) and `OccasionParticipantRow` value object (`transactionId`, `personId`, `personName`, `amountMinorUnits`, `direction`, `note?`, `personOverallStatus`) in `lib/features/occasions/domain/entities/occasion_summary.dart` and `occasion_participant_row.dart`, per data-model.md.
- [X] T009 [P] Add `OccasionNotFoundFailure`/`ParticipantNotFoundFailure` to `lib/features/occasions/domain/entities/occasion_failures.dart`, extending the core `Failure`.
- [X] T010 Update `lib/core/database/app_database.dart`: add `Occasions` and `OccasionAttachments` drift tables per data-model.md's Drift Schema Sketch (`UNIQUE INDEX idx_occasions_idempotency_key`, `INDEX idx_occasions_date`, `INDEX idx_occasions_type`, `INDEX idx_occasion_attachments_occasion_id`); add `occasion_id TEXT NULL REFERENCES Occasions(id)` and `counts_toward_balance BOOLEAN NOT NULL DEFAULT TRUE` columns to the existing `MoneyTransactions` table; add `INDEX idx_transactions_occasion_id ON MoneyTransactions(occasion_id, deleted_at)`; bump `schemaVersion` by 1 and add the additive `onUpgrade` migration step (`if (from < N) { ... }`, no existing table/column altered or dropped). Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `app_database.g.dart`.
- [X] T011 [P] Define `lib/core/media/attachment_picker_service.dart`: an abstract `AttachmentPickerService` (`pickFromCamera()`, `pickFromGallery()`, each returning `Either<Failure, String>` — a local file path already copied into the app's private sandboxed storage directory via `path_provider`) so Domain/Presentation never talk to the `image_picker`-class plugin directly (constitution Principle IX-adjacent isolation pattern, applied to media capture).
- [X] T012 [P] Implement `lib/core/media/attachment_picker_service_impl.dart`: wraps the T001 plugin, copies the picked/captured file into a dedicated `attachments/` subdirectory of the app's documents directory, returns the new local path; maps plugin/permission-denial exceptions to a typed `Failure` (never a raw exception to the UI, constitution Principle VII).
- [X] T013 [P] Unit test `AttachmentPickerServiceImpl` against a faked plugin/file-system boundary: successful pick copies the file and returns its new path; permission-denial and cancellation both return a typed `Failure`, never throw — in `test/core/media/attachment_picker_service_impl_test.dart`.
- [X] T014 Define the `TransactionsRepository` extension methods `addOccasionContribution` and `getContributionsForOccasion` in `lib/features/transactions/domain/repositories/transactions_repository.dart`, per `contracts/transactions_repository_extension.md` (signatures only — implemented per-story below).
- [X] T015 Define the `OccasionsRepository` abstract interface in `lib/features/occasions/domain/repositories/occasions_repository.dart` per `contracts/occasions_repository.md` (all method signatures — implemented incrementally across US1-US5).
- [X] T016 [P] Register `lib/core/di/injection.dart` entries for the new DAO/services placeholders (`@injectable` annotations added incrementally per task below; this task just confirms the DI module scans `lib/core/media/` and `lib/features/occasions/`).

**Checkpoint**: Schema, entities, and the attachment abstraction exist. User story implementation can now begin.

---

## Phase 3: User Story 1 - Create an Occasion and Record Participants' Contributions (Priority: P1) 🎯 MVP

**Goal**: A user can create a named occasion and add participant contributions (amount + direction, existing or inline-created people) with correctly computed totals.

**Independent Test**: Create an occasion, add three participants with amounts, confirm totals match.

### Tests for User Story 1 ⚠️

- [X] T017 [P] [US1] Unit test `CreateOccasion`: rejects empty-after-trim `name` or empty `type` (FR-001/FR-002), a retried call with the same `idempotencyKey` returns the existing occasion rather than creating a second one (FR-019) — in `test/features/occasions/domain/usecases/create_occasion_test.dart`.
- [X] T018 [P] [US1] Unit test `AddParticipantContribution`: rejects `amountMinorUnits <= 0` (FR-004), creates a `MoneyTransaction` with `kind = occasionContribution` and the given `occasionId`/`personId`, defaults `countsTowardBalance` to `true` for a non-condolence occasion type and `false` for a condolence-type occasion unless explicitly overridden (FR-018), allows more than one contribution for the same person in the same occasion (FR-006), and a retried call with the same `idempotencyKey` is a no-op returning the existing row (FR-019) — in `test/features/occasions/domain/usecases/add_participant_contribution_test.dart`.
- [X] T019 [P] [US1] Unit test `GetOccasionDetail`'s `OccasionSummary` aggregation: `totalReceivedMinorUnits`/`totalGivenMinorUnits`/`netMinorUnits` computed correctly over a mix of participant rows (FR-007) — in `test/features/occasions/domain/usecases/get_occasion_detail_test.dart`.
- [X] T020 [P] [US1] Repository test against an in-memory `NativeDatabase.memory()`: `OccasionsRepositoryImpl.createOccasion` idempotency-key uniqueness and `addParticipantContribution` delegating to `TransactionsRepository.addOccasionContribution` correctly — in `test/features/occasions/data/repositories/occasions_repository_impl_test.dart`.
- [X] T021 [P] [US1] `bloc_test` for `OccasionFormCubit`: happy-path create, empty-name/empty-type rejection, duplicate-tap producing exactly one saved occasion — in `test/features/occasions/presentation/cubit/occasion_form_cubit_test.dart`.
- [X] T022 [P] [US1] `bloc_test` for `ParticipantFormCubit`: happy-path add, zero/negative-amount rejection, inline person creation reusing 001's duplicate-name flow, duplicate-tap producing exactly one saved contribution — in `test/features/occasions/presentation/cubit/participant_form_cubit_test.dart`.

### Implementation for User Story 1

- [X] T023 [US1] Implement `lib/features/occasions/data/datasources/occasions_dao.dart` (drift DAO): insert an occasion guarded by the `idempotency_key` unique index (on conflict, return the existing row); query occasion by id.
- [X] T024 [US1] Implement `lib/features/transactions/data/datasources/transactions_dao.dart` additions: insert an `occasionContribution` row (same idempotency-guarded insert path as `addTransaction`, extended with `occasion_id`/`counts_toward_balance`); query all non-deleted contribution rows for one `occasion_id`, chronological order (depends on T010).
- [X] T025 [P] [US1] Update `lib/features/occasions/data/models/occasion_mapper.dart`: maps between the drift `Occasion` row and the domain `Occasion` entity.
- [X] T026 [P] [US1] Update `lib/features/transactions/data/models/transaction_mapper.dart`: maps the new `occasion_id`/`counts_toward_balance` columns to/from `MoneyTransaction` (depends on T004). **Critical**: the existing `kind` mapping in both `MoneyTransactionMapper.toDomain()` (line ~18, currently `kind == 'repayment' ? TransactionKind.repayment : TransactionKind.initialExchange`) and `TransactionKindDb.dbValue` (line ~39, currently `this == TransactionKind.repayment ? 'repayment' : 'initialExchange'`) are **binary ternaries, not exhaustive switches** — either one, left as-is, silently mismaps every `occasionContribution` row to/from `initialExchange` instead of throwing or correctly round-tripping. Both MUST be rewritten as exhaustive `switch` expressions covering all three `TransactionKind` values (`initialExchange`, `repayment`, `occasionContribution`) so the analyzer/compiler enforces completeness when a future kind is added. Add a unit-test case asserting `occasionContribution` round-trips correctly through both directions (extend `test/features/transactions/data/models/transaction_mapper_test.dart` if it exists, else add one).
- [X] T027 [US1] Implement `TransactionsRepositoryImpl.addOccasionContribution`/`getContributionsForOccasion` in `lib/features/transactions/data/repositories/transactions_repository_impl.dart` (depends on T014, T024, T026).
- [X] T028 [US1] Implement `OccasionsRepositoryImpl.createOccasion`/`addParticipantContribution` in `lib/features/occasions/data/repositories/occasions_repository_impl.dart`: `addParticipantContribution` validates the occasion exists and is not deleted, resolves the `countsTowardBalance` default from the occasion's `type` (condolence → `false` unless overridden — FR-018), then delegates to `TransactionsRepositoryImpl.addOccasionContribution` (depends on T015, T023, T025, T027).
- [X] T029 [P] [US1] Implement `lib/features/occasions/domain/usecases/create_occasion.dart`, wrapping `OccasionsRepository.createOccasion`.
- [X] T030 [P] [US1] Implement `lib/features/occasions/domain/usecases/add_participant_contribution.dart`, wrapping `OccasionsRepository.addParticipantContribution`.
- [X] T031 [P] [US1] Implement `lib/features/occasions/domain/usecases/get_occasion_detail.dart`: fetches the `Occasion`, its non-deleted contribution rows (via `getContributionsForOccasion`), computes `OccasionSummary` (SUM by direction, settlement label per FR-008) and the `OccasionParticipantRow` list (each row's `personOverallStatus` from `TransactionsRepository.getPersonBalance`, per FR-009 — never a separate occasion-only balance).
- [X] T032 Annotate `OccasionsRepositoryImpl`/`OccasionsDao` and the US1 use cases with `@injectable`/`@LazySingleton(as: ...)`; re-run `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart` (depends on T023-T031).
- [X] T033 [US1] Implement `lib/features/occasions/presentation/cubit/occasion_form_cubit.dart` + `occasion_form_state.dart`: generates a fresh idempotency key on open, validates non-empty name/type before enabling Save, disables Save immediately on tap (FR-019), folds the `Either` result into success/failure state (depends on T029).
- [X] T034 [US1] Implement `lib/features/occasions/presentation/cubit/participant_form_cubit.dart` + `participant_form_state.dart`: reuses 001's person search/inline-create + duplicate-warning pattern (via `PeopleRepository`), validates `amountMinorUnits > 0`, direction toggle, generates a fresh idempotency key, disables Save on tap (depends on T030).
- [X] T035 [P] [US1] Implement `lib/features/occasions/presentation/widgets/occasion_type_chip.dart` and `occasion_type_picker.dart`: renders/selects a standard `OccasionType` (T006) or free-text custom value, styled consistent with `RelationshipTagChip` (001).
- [X] T036 [P] [US1] Implement `lib/features/occasions/presentation/widgets/occasion_totals_card.dart` and `settlement_status_badge.dart`: renders total received/given/net and the settlement label (FR-007/FR-008).
- [X] T037 [US1] Implement `lib/features/occasions/presentation/pages/occasion_form_page.dart`: name field, date picker (defaults to today, accepts future dates — Edge Cases), `OccasionTypePicker` (T035), optional notes field, Save wired to `OccasionFormCubit` (depends on T033, T035).
- [X] T038 [US1] Implement `lib/features/occasions/presentation/pages/participant_form_page.dart`: reuses `PersonPickerField` (001) for select-or-create, amount field accepting Arabic-Indic/Western numerals via `numeral_parser` (001), received/given direction toggle, optional note, Save wired to `ParticipantFormCubit` (depends on T034).
- [X] T039 [US1] Implement `lib/features/occasions/presentation/pages/occasion_detail_page.dart` (initial version — list rendering completed in US3/US4): shows `OccasionTotalsCard`, a participant list built from `GetOccasionDetail`, and an "add participant" action routing to `ParticipantFormPage` (depends on T031, T036, T038).
- [X] T040 [US1] Register `/occasions/new` and `/occasions/:id` (detail) and `/occasions/:id/participants/new` routes in `lib/core/routing/app_router.dart`, and add a reachable entry point from the app's main navigation (depends on T037-T039).

**Checkpoint**: User Story 1 is fully functional and independently testable — create an occasion, add participants, see correct totals.

---

## Phase 4: User Story 2 - See Each Participant's Contribution in Their Own Money History (Priority: P1)

**Goal**: An occasion contribution appears, exactly once, in the participant's own person profile — history and balance — labeled with its occasion, and edits/removals from either entry point stay in sync.

**Independent Test**: Record a contribution inside an occasion; confirm it appears in the person's own profile, included in their balance exactly once; edit and remove it from each entry point and confirm both views agree.

### Tests for User Story 2 ⚠️

- [X] T041 [P] [US2] Unit test `GetPersonBalance`/`GetPersonHistory` (001, extended): confirms the updated SUM predicate excludes `occasionContribution` rows with `countsTowardBalance = false`, includes all others; confirms `getPersonHistory` returns `occasionContribution` rows interleaved chronologically with ordinary transactions — in `test/features/transactions/domain/usecases/get_person_balance_test.dart` (extend existing 001 test file).
- [X] T042 [P] [US2] Unit test `EditParticipantContribution`/`RemoveParticipantContribution`: editing updates the single underlying `MoneyTransaction` row (verifiable via `TransactionsRepository.getPersonHistory` returning the new values), removal soft-deletes it so it disappears from both `getContributionsForOccasion` and `getPersonHistory` — in `test/features/occasions/domain/usecases/edit_remove_participant_contribution_test.dart`.
- [X] T043 [P] [US2] Widget test for `TransactionListTile` (001, extended): renders an `occasionContribution`-kind row with a visible occasion-name label, distinguishable from an ordinary/repayment row — in `test/widget/transaction_list_tile_test.dart` (extend existing 001 test file).
- [X] T044 [P] [US2] `bloc_test` for `PersonDetailCubit` (001, extended): a person's history stream includes occasion-linked contributions and reacts to their edit/removal exactly as it already does for ordinary transactions — in `test/features/transactions/presentation/cubit/person_detail_cubit_test.dart` (extend existing 001 test file).

### Implementation for User Story 2

- [X] T045 [US2] Update the balance/history SQL in `lib/features/transactions/data/datasources/transactions_dao.dart`: add the `AND (kind != 'occasionContribution' OR counts_toward_balance = 1)` predicate to the balance aggregate query; ensure the person-history query already returns all non-deleted kinds (no `kind` filter to remove — 001's query was never kind-scoped) (depends on T010).
- [X] T046 [US2] Implement `OccasionsRepositoryImpl.editParticipantContribution`/`removeParticipantContribution` in `lib/features/occasions/data/repositories/occasions_repository_impl.dart`, both delegating to `TransactionsRepositoryImpl.editTransaction`/`deleteTransaction` (001, unchanged signatures) so there is exactly one write path regardless of entry screen (depends on T028).
- [X] T047 [P] [US2] Implement `lib/features/occasions/domain/usecases/edit_participant_contribution.dart` and `remove_participant_contribution.dart`, wrapping the T046 repository methods.
- [X] T048 Update `lib/features/transactions/presentation/widgets/transaction_list_tile.dart`: when `kind = occasionContribution`, render the linked occasion's name as a label/badge (fetched via the occasion id already present in `MoneyTransaction` — a lightweight `Occasion` name lookup, cached per screen) (depends on T045).
- [X] T049 [US2] Update `lib/features/transactions/presentation/cubit/person_detail_cubit.dart`: no state-shape change required (it already streams `MoneyTransaction` rows per 001); confirm/extend its `buildWhen`/emission logic to react correctly when an occasion-linked row changes (depends on T045).
- [X] T050 [US2] Update `lib/features/occasions/presentation/pages/occasion_detail_page.dart` and `participant_form_page.dart` (edit mode) so a participant row opened for editing routes through `EditParticipantContribution`/`RemoveParticipantContribution` (T047), and confirm the existing `person_detail_page.dart` (001) requires no changes to display an occasion-linked row correctly beyond T048's tile update (depends on T047, T048).

**Checkpoint**: User Stories 1-2 together deliver the safe MVP — occasion contributions are real transactions, visible and consistent everywhere.

---

## Phase 5: User Story 3 - View Occasion Totals and Settlement Status (Priority: P2)

**Goal**: An occasion's totals, net, and settlement label are correct and clearly displayed; each participant row shows their true overall relationship status.

**Independent Test**: Create an occasion with mixed received/given contributions; confirm totals, net, settlement label, and each participant's overall status are all correct.

### Tests for User Story 3 ⚠️

- [X] T051 [P] [US3] Unit test `OccasionSummary.settlementStatus` derivation: `settled` when `netMinorUnits == 0`, `moreReceived`/`moreGiven` with the correct `abs` amount otherwise (FR-008) — extend `test/features/occasions/domain/usecases/get_occasion_detail_test.dart` (T019).
- [X] T052 [P] [US3] Unit test confirming `OccasionParticipantRow.personOverallStatus` reflects the person's full `PersonBalance` (including transactions outside this occasion), not an occasion-scoped figure (FR-009) — extend the same test file.
- [X] T053 [P] [US3] `bloc_test` for `OccasionDetailCubit`: emits correct summary/participant states after add/edit/remove of a contribution, recalculating immediately (FR-007) — in `test/features/occasions/presentation/cubit/occasion_detail_cubit_test.dart`.

### Implementation for User Story 3

- [X] T054 [US3] Implement `lib/features/occasions/presentation/cubit/occasion_detail_cubit.dart` + `occasion_detail_state.dart`: loads `GetOccasionDetail`, exposes `OccasionSummary` + `OccasionParticipantRow` list, refreshes on any participant add/edit/remove (depends on T031, T047).
- [X] T055 [P] [US3] Implement `lib/features/occasions/presentation/widgets/participant_row.dart`: shows a participant's amount/direction/note plus their `personOverallStatus` via `BalanceStatusBadge` (001, reused as-is).
- [X] T056 [US3] Finalize `lib/features/occasions/presentation/pages/occasion_detail_page.dart`: wire to `OccasionDetailCubit` (T054), render `OccasionTotalsCard`/`SettlementStatusBadge` (T036) and the `ParticipantRow` list (T055) with loading/success/empty/error states (constitution: complete UI states) (depends on T054, T055).

**Checkpoint**: Occasion detail view is fully correct and informative — totals, settlement, and per-participant status all match source data.

---

## Phase 6: User Story 4 - Browse, Filter, and Manage Occasions (Priority: P2)

**Goal**: A reverse-chronological, filterable/searchable occasions list; archive/restore; occasion edit; occasion delete with cascade; empty states.

**Independent Test**: Create several occasions, filter by type, archive one, confirm it's hidden but retrievable; delete one and confirm its contributions are removed from affected people.

### Tests for User Story 4 ⚠️

- [X] T057 [P] [US4] Unit test `GetOccasionsList`: reverse-chronological default order, filter by name/type/date range, `includeArchived` toggling (FR-015) — in `test/features/occasions/domain/usecases/get_occasions_list_test.dart`.
- [X] T058 [P] [US4] Unit test `EditOccasion`: updates name/date/type/notes, does **not** retroactively change `countsTowardBalance` on existing contributions when `type` changes to/from condolence (research.md Decision 3) — in `test/features/occasions/domain/usecases/edit_occasion_test.dart`.
- [X] T059 [P] [US4] Unit test `ArchiveOccasion`/`RestoreOccasion`: hides/restores from the default list, leaves contributions and balances untouched (FR-014) — in `test/features/occasions/domain/usecases/archive_restore_occasion_test.dart`.
- [X] T060 [P] [US4] Unit test `DeleteOccasion`: soft-deletes the occasion AND every linked contribution in one DB transaction, appends a `deleted` `TransactionAuditEntry` per contribution, returns the correct affected-participant count for the confirmation dialog, verified with zero leftover/orphaned rows (FR-013, SC-005) — in `test/features/occasions/domain/usecases/delete_occasion_test.dart`.
- [X] T061 [P] [US4] Repository test: deleting a person who has occasion contributions but no other direct transactions is blocked (archived instead), consistent with 001's existing person-deletion rule — extend `test/features/people/data/repositories/people_repository_impl_test.dart`.
- [X] T062 [P] [US4] `bloc_test` for `OccasionsListCubit` (filter/search/reverse-chronological) and `ArchivedOccasionsCubit` — in `test/features/occasions/presentation/cubit/occasions_list_cubit_test.dart` and `archived_occasions_cubit_test.dart`.

### Implementation for User Story 4

- [X] T063 [US4] Implement `OccasionsDao` query methods: list with optional name/type/date-range filter and `includeArchived`, reverse-chronological by `date` (depends on T010, T023).
- [X] T064 [US4] Implement `OccasionsRepositoryImpl.editOccasion`/`archiveOccasion`/`restoreOccasion`/`getOccasionsList` (depends on T028, T063).
- [X] T065 [US4] Implement `OccasionsRepositoryImpl.deleteOccasion`: single DB transaction soft-deleting every `getContributionsForOccasion` row (via `TransactionsRepositoryImpl`'s existing per-row delete + audit-entry mechanism) then the `Occasion` row itself (depends on T027, T028, T064).
- [X] T066 [P] [US4] Implement `lib/features/occasions/domain/usecases/edit_occasion.dart`, `archive_occasion.dart`, `restore_occasion.dart`, `delete_occasion.dart`, `get_occasions_list.dart`, wrapping the T064/T065 repository methods.
- [X] T067 Annotate the new US4 use cases and any new DAO methods with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T066).
- [X] T068 [US4] Implement `lib/features/occasions/presentation/cubit/occasions_list_cubit.dart` + state: loads/filters/searches the active list, reacts to name/type/date-range filter changes (depends on T066).
- [X] T069 [P] [US4] Implement `lib/features/occasions/presentation/cubit/archived_occasions_cubit.dart` + state, mirroring 001's `ArchivedPeopleCubit` pattern (depends on T066).
- [X] T070 [P] [US4] Implement `lib/features/occasions/presentation/widgets/occasion_list_tile.dart`: name, date, type chip, quick total (depends on T035).
- [X] T071 [US4] Implement `lib/features/occasions/presentation/pages/occasions_list_page.dart`: reverse-chronological list (`OccasionListTile`, lazy-rendered per constitution Performance standards), type/name/date-range filter controls, empty state (FR-020), link to archived view (depends on T068, T070).
- [X] T072 [P] [US4] Implement `lib/features/occasions/presentation/pages/archived_occasions_page.dart`, mirroring 001's `ArchivedPeoplePage` (depends on T069, T070).
- [X] T073 [US4] Extend `lib/features/occasions/presentation/pages/occasion_form_page.dart` to support edit mode (pre-filled fields, calls `EditOccasion`) and add an archive/delete action with an explicit confirmation dialog naming the affected participant count from `GetOccasionDetail` before calling `DeleteOccasion` (FR-013) (depends on T031, T066).
- [X] T074 Register `/occasions` (list), `/occasions/archived`, and `/occasions/:id/edit` routes in `lib/core/routing/app_router.dart` (depends on T071-T073).

**Checkpoint**: Occasions are fully browsable, filterable, editable, archivable, and safely deletable with a correct cascade.

---

## Phase 7: User Story 5 - Attach Photos to an Occasion (Priority: P3)

**Goal**: A user can attach and remove photos on an occasion.

**Independent Test**: Attach a photo to an existing occasion; confirm it's viewable; remove it after confirmation.

### Tests for User Story 5 ⚠️

- [X] T075 [P] [US5] Unit test `AddOccasionAttachment`/`RemoveOccasionAttachment`: persists a valid local `filePath`, soft-deletes on removal (FR-017) — in `test/features/occasions/domain/usecases/manage_occasion_attachment_test.dart`.
- [X] T076 [P] [US5] `bloc_test` for `OccasionDetailCubit`'s attachment handling: successful attach updates state, camera/gallery permission denial surfaces a clear, typed, user-facing failure without crashing (FR-017, Edge Cases) — extend `test/features/occasions/presentation/cubit/occasion_detail_cubit_test.dart` (T053).

### Implementation for User Story 5

- [X] T077 [US5] Implement `OccasionAttachmentsDao` methods (insert/soft-delete/list-by-occasion) in `lib/features/occasions/data/datasources/occasions_dao.dart` (depends on T010).
- [X] T078 [US5] Implement `OccasionsRepositoryImpl.addOccasionAttachment`/`removeOccasionAttachment`, calling `AttachmentPickerService` (T011/T012) from the Presentation-triggered flow and persisting the returned local path (depends on T028, T077).
- [X] T079 [P] [US5] Implement `lib/features/occasions/domain/usecases/add_occasion_attachment.dart` and `remove_occasion_attachment.dart`, wrapping T078.
- [X] T080 [P] [US5] Implement `lib/features/occasions/presentation/widgets/occasion_attachment_gallery.dart`: thumbnail grid, tap-to-view, remove-with-confirmation action.
- [X] T081 [US5] Extend `OccasionDetailCubit`/`occasion_detail_page.dart` to surface an "attach photo" action (camera/gallery choice), render `OccasionAttachmentGallery` (T080), and handle the permission-denied failure path with a clear, localized explanation (depends on T054, T079, T080).
- [X] T082 Annotate the US5 use cases/DAO methods with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T077-T081).

**Checkpoint**: All five user stories complete — the full Occasions feature is usable end-to-end.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Localization, theming, performance, and end-to-end validation across the whole feature.

- [X] T083 [P] Add all Occasions-feature strings (occasion form, type names, participant form, settlement labels, empty states, confirmation dialogs, attachment permission explanations) to `lib/core/l10n/app_en.arb` and `app_ar.arb`; regenerate `AppLocalizations` (FR-022).
- [X] T084 [P] RTL/LTR and theme pass: verify occasion list/detail/form screens, type chips, settlement badges, and the attachment gallery render correctly in Arabic RTL and English LTR, and in both light and dark mode (FR-022, SC-007).
- [X] T085 [P] Performance check: seed an occasion with 200 participant contributions and confirm `GetOccasionDetail`'s summary/list render in <1s on a mid-range Android profile target (plan.md Performance Goals).
- [X] T086 Write `integration_test/occasions_flows_test.dart` covering: create occasion + add 3 participants (US1); verify a contribution in the person's own profile, edit it from there, confirm the occasion reflects it (US2); mixed received/given totals + settlement label (US3); filter/search, archive/restore, delete-with-cascade verified against an affected person's balance (US4); attach/remove a photo (US5) — per quickstart.md's manual scenarios.
- [X] T087 Run `fvm flutter analyze` and `fvm flutter format`, fix all warnings (no `// ignore` suppressions without a documented reason, constitution Code Quality Gates).
- [X] T088 Run the full `fvm flutter test` suite and `fvm flutter test integration_test`; confirm all pass.
- [X] T089 Code-review pass against the constitution's Definition of Done checklist for every new/changed file in this feature (layering, immutability, error handling, offline behavior, RTL, accessibility, no hardcoded design values, no duplicated components).

---

## Dependencies & Execution Order

- **Setup (Phase 1)** → **Foundational (Phase 2)**: strictly sequential; Foundational blocks every user story.
- **US1 (Phase 3)** is the MVP; depends only on Foundational.
- **US2 (Phase 4)** depends on US1 (needs contributions to exist) but is the other required half of a safe release (spec: "must ship alongside User Story 1").
- **US3 (Phase 5)** depends on US1 (occasion detail scaffold) and benefits from US2's history/balance correctness being in place first, though its own tests can be written in parallel.
- **US4 (Phase 6)** depends on US1 (occasions exist) and US2 (deletion cascade must correctly affect person history/balance, already extended there).
- **US5 (Phase 7)** depends on US1 (occasion detail page exists) and Foundational's `AttachmentPickerService` (T011/T012); independent of US2-US4 otherwise.
- **Polish (Phase 8)** depends on all prior phases.

## Parallel Execution Examples

- Within Foundational: T005-T009 (entities/value objects/failures) can run in parallel with each other once T004 lands; T011-T013 (media abstraction) are independent of T005-T010 and can run in parallel.
- Within US1: T017-T022 (all test-writing tasks) can run in parallel before any implementation task starts; T029-T031 (use cases) can run in parallel once their shared repository methods (T028) land.
- Within US4: T057-T062 (tests) can run in parallel; T066 (use cases) can run in parallel once T064/T065 land.

## Implementation Strategy

**MVP first**: Phases 1-4 (Setup, Foundational, US1, US2) deliver the minimum safe, independently valuable release — occasions can be created with participants, and every contribution is correctly, consistently reflected in the existing person-balance system. Ship this before continuing.

**Incremental delivery**: US3 (totals/settlement clarity) and US4 (browse/filter/archive/delete-cascade) are the next-highest-value increments and can be delivered in either order. US5 (photo attachments) is the lowest-priority, safely deferrable increment.
