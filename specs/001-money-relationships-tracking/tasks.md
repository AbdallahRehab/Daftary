---

description: "Task list for Money Relationships Tracking (feature 001)"
---

# Tasks: Money Relationships Tracking

**Input**: Design documents from `/specs/001-money-relationships-tracking/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included. Not explicitly requested in spec.md, but plan.md's Testing section and constitution Principle XVI ("Testability by Design") mandate unit tests for use cases/repositories/money math, `bloc_test` for Cubits, widget tests for key screens, and an `integration_test` suite — plan.md's Project Structure even names the test files. Each user story's tests are written before its implementation tasks (TDD ordering) so they can be run red-then-green.

**Balance-sign formula (read before Foundational/US1/US3/US4)**: Per `data-model.md`'s `PersonBalance.netMinorUnits` (fixed by `/speckit-analyze` to match spec.md's own worked examples — see spec.md FR-008 and data-model.md's PersonBalance table), every task below that computes a balance uses `netMinorUnits = SUM(direction=given) − SUM(direction=received)` over non-deleted rows; positive ⇒ they owe you, negative ⇒ you owe them, zero ⇒ settled. This is consistent with FR-008, FR-009, and every worked example in User Stories 2 and 3.

**Organization**: Tasks are grouped by user story (spec.md priorities P1–P3) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Maps to spec.md user stories (US1–US6)
- File paths follow plan.md's Project Structure exactly (`lib/features/<feature>/{data,domain,presentation}`, `lib/core/`, `test/`, `integration_test/`)

## Path Conventions

Single Flutter app (Option 1 shape), feature-first per constitution Principle II:
`lib/core/`, `lib/features/{people,transactions}/{data,domain,presentation}`, `test/` mirrors `lib/`, `integration_test/` for end-to-end flows.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Turn the bare `flutter create` scaffold (currently only `lib/main.dart`) into a project ready for feature-first, clean-architecture development.

- [ ] T001 Add feature dependencies to `pubspec.yaml`: `flutter_bloc`, `equatable`, `get_it`, `injectable`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `fpdart`, `uuid`, `intl`, `flutter_localizations` (sdk), `go_router`; dev dependencies: `build_runner`, `drift_dev`, `injectable_generator`, `bloc_test`, `mocktail`. Run `flutter pub get` to confirm resolution.
- [ ] T002 [P] Enable Flutter's `gen_l10n`: add `generate: true` under the `flutter:` section of `pubspec.yaml` and create `lib/l10n.yaml` with `arb-dir: lib/core/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart` (constitution Principle XIII).
- [ ] T003 [P] Create `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_ar.arb` with an initial `appTitle` key ("Daftary" / "دفتري") so `gen_l10n` has a valid template to generate `AppLocalizations` from (FR-022).
- [ ] T004 [P] Create the feature-first directory skeleton per plan.md's Project Structure: `lib/core/{database,design_system,di,error,money,routing}/`, `lib/features/{people,transactions}/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/core/`, `test/features/{people,transactions}/{domain/usecases,data/repositories,presentation/cubit}/`, `test/widget/`, and `integration_test/`.
- [ ] T005 [P] Review `analysis_options.yaml` and add any missing strict-mode analyzer options (`strict-casts`, `strict-inference`, `strict-raw-types`) so `flutter analyze` enforces the constitution's static-analysis gate from the start.

**Checkpoint**: Project builds, dependencies resolve, directory layout matches plan.md.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that every user story depends on — local database, money arithmetic, error types, DI, routing, design system, app bootstrap.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T006 Define `lib/core/error/failure.dart`: an abstract `Failure` base plus `ValidationFailure`, `CacheFailure`, `NotFoundFailure`, `UnknownFailure` (constitution Principle VII). Feature-specific failures (`PossibleDuplicateFailure`, `PersonHasTransactionsFailure`) are added later, in US1/US5, where the `Person` entity they carry becomes available.
- [ ] T007 [P] Define `lib/core/money/money.dart`: a `Money` value type wrapping a signed 64-bit integer count of EGP piastres (1 EGP = 100 piastres), exposing only integer-safe `add`/`subtract`/`negate`/compare operations — no floating point anywhere (research.md Decision 4, constitution Principle VIII).
- [ ] T008 [P] Define `lib/core/money/egp_formatter.dart`: converts `Money` ⇄ decimal EGP display strings (e.g. `150.50`) using `intl`'s `NumberFormat.currency`, exactly at the UI boundary — decimal-to-minor-units conversion (e.g. `150.50` → `15050`) must be exact, with no rounding drift (FR-006).
- [ ] T009 [P] Define `lib/core/money/numeral_parser.dart`: normalizes Arabic-Indic digits (٠-٩) to Western digits (0-9) before any amount is parsed, so both numeral systems are accepted as equivalent (FR-023).
- [ ] T010 [P] Unit test `Money` arithmetic and decimal conversion (add/subtract/negate/compare; `150.50` EGP → `15050` piastres exactly; large amounts up to 5,000,000 EGP with no overflow/truncation) in `test/core/money/money_test.dart`.
- [ ] T011 [P] Unit test `numeral_parser` (Arabic-Indic ↔ Western digit equivalence, e.g. `١٥٠٫٥٠` parses identically to `150.50`) in `test/core/money/numeral_parser_test.dart`.
- [ ] T012 Define `lib/core/database/app_database.dart`: a `drift` `AppDatabase` with `People`, `MoneyTransactions`, `TransactionAuditEntries` tables per data-model.md's Drift Schema Sketch — columns, types, `UNIQUE INDEX idx_transactions_idempotency_key` on `MoneyTransactions.idempotency_key`, `INDEX idx_people_normalized_name`, `INDEX idx_transactions_person_id ON MoneyTransactions(person_id, deleted_at)`, `INDEX idx_audit_transaction_id`. Run `dart run build_runner build --delete-conflicting-outputs` to generate `app_database.g.dart`.
- [ ] T013 [P] Configure `lib/core/di/injection.dart` with `get_it` + `injectable`: an `@InjectableInit` bootstrap function, and register `AppDatabase` as a lazy singleton opened against a file in the app's sandboxed documents directory (via `path_provider`) — constitution Principle XIV and Principle XII's data-protection requirement, per research.md Decision 11 (OS-level storage protection, no app-level DB encryption for v1).
- [ ] T014 [P] Configure `lib/core/routing/app_router.dart`: a `go_router` skeleton with a placeholder home route, exported as a `GoRouter` instance each later phase extends with its own routes.
- [ ] T015 [P] Build `lib/core/design_system/tokens.dart`: color, typography, spacing, and radius tokens (constitution Principle XV — no hardcoded values in feature widgets).
- [ ] T016 [P] Build the shared design-system widgets in `lib/core/design_system/`: `app_button.dart`, `app_text_field.dart`, `app_card.dart`, `app_empty_view.dart`, `app_confirm_dialog.dart`, each built from T015's tokens.
- [ ] T017 Wire `lib/main.dart`: call the injectable bootstrap from T013, construct `MaterialApp.router` with `AppRouter`'s config, register `AppLocalizations.delegate` + the standard Flutter/Material/Cupertino localization delegates, and set `supportedLocales: [Locale('en'), Locale('ar')]` (FR-022).

**Checkpoint**: Foundation ready — app launches to a placeholder home screen with a working local DB, DI, router, design tokens, and localization scaffold. User story implementation can now begin.

---

## Phase 3: User Story 1 - Record a Money Transaction With a Person (Priority: P1) 🎯 MVP

**Goal**: A user can pick or inline-create a person and record a money transaction (given/received) against them in a few seconds, with duplicate-name protection and a guaranteed single save even on a rapid double-tap.

**Independent Test**: Create a new person and record one "received" and one "given" transaction against them; confirm both are saved correctly and the person's balance reflects them.

### Tests for User Story 1 ⚠️ (write first, confirm they fail, then implement)

- [ ] T018 [P] [US1] Unit test `FindPossibleDuplicatePerson`: bidirectional, case/whitespace-insensitive exact/prefix/contains match against existing (active or archived) person names — e.g. "Ahmed" vs. "Ahmed Ali" matches in either direction (FR-003, data-model.md Validation rules) — in `test/features/people/domain/usecases/find_possible_duplicate_person_test.dart`.
- [ ] T019 [P] [US1] Unit test `CreatePerson`: rejects an empty-after-trim name, returns `PossibleDuplicateFailure` instead of inserting when a duplicate name is found, succeeds otherwise (FR-001, FR-003) — in `test/features/people/domain/usecases/create_person_test.dart`.
- [ ] T020 [P] [US1] Unit test `AddTransaction`: rejects `amountMinorUnits <= 0` with an explanatory `ValidationFailure` (FR-005), rejects a `personId` equal to the app's own user/no distinct counterparty (Edge Cases), and a retried call with the same `idempotencyKey` returns the already-persisted transaction rather than creating a second one (FR-020, SC-006) — in `test/features/transactions/domain/usecases/add_transaction_test.dart`.
- [ ] T021 [P] [US1] Unit test `GetPersonBalance`: `netMinorUnits = SUM(given) − SUM(received)` over non-deleted rows only (see the sign-correction note above), status derived from its sign (FR-008, FR-009) — in `test/features/transactions/domain/usecases/get_person_balance_test.dart`.
- [ ] T022 [P] [US1] Repository test against an in-memory `NativeDatabase.memory()`: `PeopleRepositoryImpl.createPerson`/`confirmCreateDespiteDuplicate`/`searchActivePeople`/`getPersonById` — in `test/features/people/data/repositories/people_repository_impl_test.dart`.
- [ ] T023 [P] [US1] Repository test against an in-memory `NativeDatabase.memory()`: `TransactionsRepositoryImpl.addTransaction` — the `idempotency_key` unique index makes a retried insert a no-op that returns the existing row (FR-020/SC-006) — and `getPersonBalance` aggregate correctness — in `test/features/transactions/data/repositories/transactions_repository_impl_test.dart`.
- [ ] T024 [P] [US1] `bloc_test` for `TransactionFormCubit`: happy-path save, duplicate-name warning branch (pick existing vs. confirm new), zero/negative-amount rejection, and a simulated double-tap producing exactly one saved transaction — in `test/features/transactions/presentation/cubit/transaction_form_cubit_test.dart`.

### Implementation for User Story 1

- [ ] T025 [P] [US1] Define the `Person` entity in `lib/features/people/domain/entities/person.dart` (`Equatable`): `id` (UUID), `name` (required, non-empty after trim — FR-001), `phoneNumber`/`avatarPath`/`relationshipTag`/`notes` (all optional), `isArchived` (default `false`), `createdAt`, `updatedAt`, per data-model.md.
- [ ] T026 [P] [US1] Define the `RelationshipStatus` enum (`theyOweYou` / `youOweThem` / `settled`) and the `PersonBalance` value object in `lib/features/transactions/domain/entities/person_balance.dart`: `personId`, `netMinorUnits`, `status` derived solely from `netMinorUnits`'s sign using the **corrected** formula (given − received) from the note above.
- [ ] T027 [P] [US1] Define `TransactionDirection` (`given`/`received`), `TransactionKind` (`initialExchange`/`repayment`, immutable after creation per Clarifications), and the `MoneyTransaction` entity in `lib/features/transactions/domain/entities/money_transaction.dart`: `id`, `idempotencyKey`, `personId`, `amountMinorUnits` (`> 0`), `direction`, `kind`, `date`, `note?`, `createdAt`, `editedAt?`, `deletedAt?`, per data-model.md.
- [ ] T028 [P] [US1] Add `PossibleDuplicateFailure` (carries the matching `List<Person>`) to `lib/features/people/domain/entities/people_failures.dart`, extending the core `Failure` from T006.
- [ ] T029 [US1] Define the `PeopleRepository` abstract interface in `lib/features/people/domain/repositories/people_repository.dart` per `contracts/people_repository.md` (all 8 methods — `createPerson`/`confirmCreateDespiteDuplicate`/`searchActivePeople`/`getPersonById` implemented in this phase; `editPerson`/`archivePerson`/`restorePerson`/`deletePerson`/`searchArchivedPeople` implemented later in US5).
- [ ] T030 [US1] Define the `TransactionsRepository` abstract interface in `lib/features/transactions/domain/repositories/transactions_repository.dart` per `contracts/transactions_repository.md` (`addTransaction`/`getPersonBalance` implemented in this phase; `recordRepayment`/`editTransaction`/`deleteTransaction`/`getPersonHistory`/`getOverview` implemented later in US2/US3/US4/US6).
- [ ] T031 [US1] Implement `lib/features/people/data/datasources/people_dao.dart` (drift DAO): insert a person computing `normalized_name` (lowercased, whitespace-collapsed) at write time; a duplicate-name lookup implementing the bidirectional exact/prefix/contains match against `normalized_name` (FR-003); search active people by optional name/status.
- [ ] T032 [US1] Implement `lib/features/people/data/models/person_mapper.dart`: maps between the drift `Person` row and the domain `Person` entity (T025).
- [ ] T033 [US1] Implement `lib/features/people/data/repositories/people_repository_impl.dart`: `createPerson` (runs the FR-003 duplicate check, returns `PossibleDuplicateFailure` instead of inserting on a match), `confirmCreateDespiteDuplicate` (bypasses the check), `searchActivePeople`, `getPersonById`; maps DB exceptions to `CacheFailure`/`UnknownFailure` (depends on T029, T031, T032).
- [ ] T034 [US1] Implement `lib/features/transactions/data/datasources/transactions_dao.dart` (drift DAO): insert a transaction guarded by the `idempotency_key` unique index — on a unique-constraint violation, fetch and return the existing row instead of erroring (FR-020/SC-006); an aggregate query for a person's net balance (`SUM(amount WHERE direction='given') − SUM(amount WHERE direction='received')` over `deleted_at IS NULL` rows — corrected sign, see note above).
- [ ] T035 [US1] Implement `lib/features/transactions/data/models/transaction_mapper.dart`: maps between drift `MoneyTransaction`/`TransactionAuditEntry` rows and the domain entities (T026, T027).
- [ ] T036 [US1] Implement `lib/features/transactions/data/repositories/transactions_repository_impl.dart`: `addTransaction` (validates `amountMinorUnits > 0` per FR-005, rejects a self-referential `personId` per Edge Cases, writes a `created` `TransactionAuditEntry` in the same DB transaction) and `getPersonBalance` (depends on T030, T034, T035).
- [ ] T037 [P] [US1] Implement `lib/features/people/domain/usecases/find_possible_duplicate_person.dart`: pure domain function over the normalized-name index (research.md Decision 8).
- [ ] T038 [P] [US1] Implement `lib/features/people/domain/usecases/create_person.dart`, wrapping `PeopleRepository.createPerson`.
- [ ] T039 [P] [US1] Implement `lib/features/transactions/domain/usecases/add_transaction.dart`, wrapping `TransactionsRepository.addTransaction` (the `idempotencyKey` is caller-supplied per the contract, not generated here).
- [ ] T040 [P] [US1] Implement `lib/features/transactions/domain/usecases/get_person_balance.dart`, wrapping `TransactionsRepository.getPersonBalance`.
- [ ] T041 Annotate `PeopleRepositoryImpl`/`PeopleDao`, `TransactionsRepositoryImpl`/`TransactionsDao`, and the four US1 use cases (T037-T040) with `@injectable`/`@LazySingleton(as: ...)`, then re-run `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart` (depends on T031-T040).
- [ ] T042 [US1] Implement `lib/features/transactions/presentation/cubit/transaction_form_cubit.dart` + `transaction_form_state.dart` (`Equatable`, `copyWith`): generates a fresh idempotency key when the form opens, live-searches people via `PeopleRepository.searchActivePeople` as the user types a name, surfaces `PossibleDuplicateFailure` matches as a pickable list, disables Save immediately on tap (a loading state) so a rapid double-tap cannot re-invoke the use case (FR-020), validates `amountMinorUnits > 0` client-side before calling `AddTransaction`, and folds the `Either` result into success/failure state (depends on T037-T040).
- [ ] T043 [P] [US1] Implement `lib/features/transactions/presentation/widgets/duplicate_warning_sheet.dart`: shown when the cubit surfaces a duplicate-name match; lets the user pick the existing person or explicitly confirm creating a new one — never a silent auto-merge (FR-003, Edge Cases).
- [ ] T044 [P] [US1] Implement `lib/features/transactions/presentation/widgets/person_picker_field.dart`: a text field with live search-as-you-type against active people plus an inline "create new person" affordance (FR-002).
- [ ] T045 [US1] Implement `lib/features/transactions/presentation/pages/transaction_form_page.dart`: amount field accepting Arabic-Indic and Western numerals via `numeral_parser` (FR-023), given/received direction toggle, date picker defaulting to today (FR-004), optional note field, the `PersonPickerField` (T044), a Save button wired to `TransactionFormCubit`, inline validation error display for zero/negative amounts (FR-005), and a brief on-save confirmation that the transaction is durably saved regardless of connectivity (FR-021 — this feature is local-only with no sync/reconciliation step, so no "pending" state is shown) (depends on T042-T044).
- [ ] T046 [US1] Register the `/transactions/new` route for `TransactionFormPage` in `lib/core/routing/app_router.dart`, and add a reachable entry point (e.g. a floating action button on the Foundational placeholder home screen from T014) so the flow is testable end-to-end.

**Checkpoint**: User Story 1 is fully functional and independently testable — record a transaction against a new or existing person, with duplicate protection and guaranteed-once saves.

---

## Phase 4: User Story 2 - View a Person's Balance and Full History (Priority: P1)

**Goal**: Opening a person shows their current net balance/status and their complete chronological transaction history.

**Independent Test**: Open a person with multiple recorded transactions; confirm the displayed net balance matches the sum of their history and every transaction is visible and correctly labeled.

### Tests for User Story 2 ⚠️

- [ ] T047 [P] [US2] Unit test `GetPersonHistory`: returns non-deleted rows only, in chronological order, each carrying its `kind`/`direction`/edited metadata (FR-010) — in `test/features/transactions/domain/usecases/get_person_history_test.dart`.
- [ ] T048 [P] [US2] `bloc_test` for `PersonDetailCubit`: loads a person's balance + history together, resolves to "Settled" when net is zero, and to `theyOweYou`/`youOweThem` for the corresponding signs (FR-009) — in `test/features/transactions/presentation/cubit/person_detail_cubit_test.dart`.
- [ ] T049 [P] [US2] Widget test for `PersonDetailPage`: renders the balance headline ("X owes you" / "you owe X" / "Settled") and lists transactions in chronological order — in `test/widget/person_detail_page_test.dart`.

### Implementation for User Story 2

- [ ] T050 [US2] Extend `transactions_dao.dart`/`transactions_repository_impl.dart` (T034/T036) with `getPersonHistory`: query non-deleted rows for a person ordered by `date` ascending (FR-010).
- [ ] T051 [P] [US2] Implement `lib/features/transactions/domain/usecases/get_person_history.dart`, wrapping `TransactionsRepository.getPersonHistory`.
- [ ] T052 [US2] Implement `lib/features/transactions/presentation/cubit/person_detail_cubit.dart` + `person_detail_state.dart`: loads a person's `PersonBalance` and history together, exposing the `RelationshipStatus` label (FR-009) (depends on T040, T051).
- [ ] T053 [P] [US2] Implement `lib/features/transactions/presentation/widgets/balance_status_badge.dart`: renders "They owe you" / "You owe them" / "Settled" from `RelationshipStatus` (FR-009).
- [ ] T054 [P] [US2] Implement `lib/features/transactions/presentation/widgets/transaction_list_tile.dart`: shows type, amount, direction, date, note, and an "edited" marker when `editedAt != null` (FR-010, FR-015).
- [ ] T055 [US2] Implement `lib/features/transactions/presentation/pages/person_detail_page.dart`: balance headline + `BalanceStatusBadge`, a `ListView.builder`-backed chronological transaction list using `TransactionListTile` (so scrolling stays smooth with many transactions per Acceptance Scenario 4), and an entry point to record a new transaction against this person (depends on T052-T054).
- [ ] T056 [US2] Register the `/people/:id` route for `PersonDetailPage` in `lib/core/routing/app_router.dart`, and navigate to it after a transaction is saved from `TransactionFormPage` (closing the loop opened by T045/T046).

**Checkpoint**: User Stories 1 and 2 together deliver the product's core value ("never forget a money exchange, always understand where it stands").

---

## Phase 5: User Story 3 - Record a Repayment Against an Existing Balance (Priority: P2)

**Goal**: A repayment reduces (or, if it overshoots, flips) a person's outstanding balance, and is visibly distinct from a regular transaction.

**Independent Test**: Create a person with an outstanding balance, record a partial repayment, confirm the remaining balance is reduced by exactly the repaid amount.

### Tests for User Story 3 ⚠️

- [ ] T057 [P] [US3] Unit test `RecordRepayment`: partial repayment reduces net by exactly the repaid amount (AC1: 1,500 → 1,000 after 500), a repayment equal to the outstanding amount settles it (AC2: 1,500 → 0), and an overshoot repayment flips the sign (AC3: owed 500 + repayment 700 → user owes 200) — `direction` is always inferred by the use case (`received` when the current net > 0, `given` otherwise), never accepted from the caller — in `test/features/transactions/domain/usecases/record_repayment_test.dart`.
- [ ] T058 [P] [US3] Extend the repository test from T023 with `TransactionsRepositoryImpl.recordRepayment` against an in-memory DB, verifying the resulting balance for all 3 scenarios above — in `test/features/transactions/data/repositories/transactions_repository_impl_test.dart`.

### Implementation for User Story 3

- [ ] T059 [US3] Extend `transactions_dao.dart`/`transactions_repository_impl.dart` (T034/T036) with `recordRepayment`: reads the current balance (given − received, per the sign-correction note), infers `direction` (`received` if current net > 0, else `given`), inserts with `kind = repayment`, reuses the same idempotency-key handling as `addTransaction`, and writes a `created` `TransactionAuditEntry` — the repository's `recordRepayment` signature never accepts a `direction` parameter, matching `contracts/transactions_repository.md`.
- [ ] T060 [P] [US3] Implement `lib/features/transactions/domain/usecases/record_repayment.dart`, wrapping `TransactionsRepository.recordRepayment`.
- [ ] T061 [US3] Implement `lib/features/transactions/presentation/cubit/repayment_form_cubit.dart` + `repayment_form_state.dart`: pre-bound to a known `personId` (opened from `PersonDetailPage`), generates its own idempotency key, validates `amountMinorUnits > 0`, calls `RecordRepayment`, exposes loading/success/failure states (depends on T060).
- [ ] T062 [P] [US3] Implement `lib/features/transactions/presentation/pages/repayment_form_page.dart`: amount field (numeral-parser-aware), date, optional note, Save button wired to `RepaymentFormCubit`.
- [ ] T063 [US3] Register the `/people/:id/repayment` route in `lib/core/routing/app_router.dart`; add a "Record repayment" entry point on `PersonDetailPage` (T055) that navigates to it and refreshes `PersonDetailCubit` on return (depends on T052/T055, T062).
- [ ] T064 [P] [US3] Extend `transaction_list_tile.dart` (T054) to visually distinguish `kind == repayment` rows from `kind == initialExchange` rows (AC1: "distinctly from a fresh received transaction").

**Checkpoint**: User Stories 1-3 all work independently.

---

## Phase 6: User Story 4 - See an Overview of Everyone I Owe and Everyone Who Owes Me (Priority: P2)

**Goal**: A single screen totals and groups every person into "owes me," "I owe," and "settled," including archived people with a non-zero balance.

**Independent Test**: Create several people with different balances and confirm the overview correctly totals and groups them.

### Tests for User Story 4 ⚠️

- [ ] T065 [P] [US4] Unit test `GetOverview`: totals/groupings include archived people while their balance is non-zero (FR-024, Clarifications), exclude a person once their balance reaches zero, and `settledCount` counts people with `netMinorUnits == 0` — in `test/features/transactions/domain/usecases/get_overview_test.dart`.
- [ ] T066 [P] [US4] Extend the repository test from T023/T058 with `TransactionsRepositoryImpl.getOverview` against a mix of active/archived/settled people, verifying `totalOwedToUserMinorUnits`, `totalUserOwesMinorUnits`, and both grouped lists — in `test/features/transactions/data/repositories/transactions_repository_impl_test.dart`.
- [ ] T067 [P] [US4] `bloc_test` for `OverviewCubit`: totals refresh immediately after a transaction changes elsewhere (FR-014, AC2), and an explicit "everything settled" state is exposed when no outstanding balances exist (AC3) — in `test/features/transactions/presentation/cubit/overview_cubit_test.dart`.

### Implementation for User Story 4

- [ ] T068 [US4] Define `PersonSummary` and `OverviewSummary` value objects in `lib/features/transactions/domain/entities/overview_summary.dart` per data-model.md: `totalOwedToUserMinorUnits`, `totalUserOwesMinorUnits`, `peopleTheyOweYou`, `peopleYouOweThem`, `settledCount`.
- [ ] T069 [US4] Extend `transactions_dao.dart`/`transactions_repository_impl.dart` (T034/T036/T059) with `getOverview`: aggregates each person's net balance (including archived people, per FR-024) using the corrected given−received sign convention, grouped into owed-to-user/user-owes/settled buckets, most-recent-activity-first within each list (depends on T068).
- [ ] T070 [P] [US4] Implement `lib/features/transactions/domain/usecases/get_overview.dart`, wrapping `TransactionsRepository.getOverview`.
- [ ] T071 [US4] Implement `lib/features/transactions/presentation/cubit/overview_cubit.dart` + `overview_state.dart`: loads the `OverviewSummary`, exposing an explicit "all settled" flag distinct from loading/empty (AC3) (depends on T070).
- [ ] T072 [P] [US4] Implement `lib/features/transactions/presentation/widgets/overview_summary_card.dart`: renders the total-owed-to-you / total-you-owe headline figures.
- [ ] T073 [US4] Implement `lib/features/transactions/presentation/pages/overview_page.dart`: `OverviewSummaryCard` + two grouped lists ("They owe you" / "You owe them"), each row navigating to `PersonDetailPage`, and an explicit "Everything is settled" empty state (AC3) (depends on T071, T072).
- [ ] T074 [US4] Register the `/overview` route in `lib/core/routing/app_router.dart` and add navigation to it from the app's main entry surface (depends on T073).

**Checkpoint**: User Stories 1-4 all work independently.

---

## Phase 7: User Story 5 - Manage People Profiles (Priority: P3)

**Goal**: Create people ahead of time, edit their details, and archive/restore them without losing history.

**Independent Test**: Create a person, edit their details, archive them, then confirm they disappear from the active list while their history remains retrievable.

### Tests for User Story 5 ⚠️

- [ ] T075 [P] [US5] Unit test `EditPerson`: updates `name`/`phoneNumber`/`relationshipTag`/`notes` and bumps `updatedAt` — in `test/features/people/domain/usecases/edit_person_test.dart`.
- [ ] T076 [P] [US5] Unit test `ArchivePerson`/`RestorePerson`: archiving always succeeds regardless of outstanding balance or transaction count — in `test/features/people/domain/usecases/archive_restore_person_test.dart`.
- [ ] T077 [P] [US5] Unit test `DeletePerson`: blocked with `PersonHasTransactionsFailure` when the person has any transaction, including soft-deleted ones (data-model.md: "including soft-deleted ones, to keep audit history attributable"); succeeds when the person has zero transactions (FR-017) — in `test/features/people/domain/usecases/delete_person_test.dart`.
- [ ] T078 [P] [US5] `bloc_test` for `PersonListCubit`: filters active people by name and by `RelationshipStatus` (FR-019) — in `test/features/people/presentation/cubit/person_list_cubit_test.dart`.
- [ ] T079 [P] [US5] `bloc_test` for `ArchivedPeopleCubit`: lists/searches archived people; restoring one moves it back into the active list — in `test/features/people/presentation/cubit/archived_people_cubit_test.dart`.

### Implementation for User Story 5

- [ ] T080 [US5] Add `PersonHasTransactionsFailure` to `lib/features/people/domain/entities/people_failures.dart` (extends the file created in T028).
- [ ] T081 [US5] Extend `people_dao.dart`/`people_repository_impl.dart` (T031/T033) with `editPerson`, `archivePerson`, `restorePerson`, `deletePerson` (checks `MoneyTransactions` — including soft-deleted rows — before allowing a delete), and `searchArchivedPeople`.
- [ ] T082 [P] [US5] Implement `lib/features/people/domain/usecases/edit_person.dart`.
- [ ] T083 [P] [US5] Implement `lib/features/people/domain/usecases/archive_person.dart` and `restore_person.dart`.
- [ ] T084 [P] [US5] Implement `lib/features/people/domain/usecases/delete_person.dart`.
- [ ] T085 [US5] Implement `lib/features/people/presentation/cubit/person_list_cubit.dart` + `person_list_state.dart`: loads active people, applies name + `RelationshipStatus` filters (FR-019), using `GetPersonBalance` (T040) per person to determine status (depends on T040, T081-T084).
- [ ] T086 [P] [US5] Implement `lib/features/people/presentation/cubit/person_form_cubit.dart` + `person_form_state.dart`: create mode (delegates to `CreatePerson`/`confirmCreateDespiteDuplicate`, reusing the duplicate-warning flow from US1) and edit mode (delegates to `EditPerson`), covering the full field set including `relationshipTag` (depends on T038, T082).
- [ ] T087 [P] [US5] Implement `lib/features/people/presentation/cubit/archived_people_cubit.dart` + `archived_people_state.dart`: search and restore (depends on T083).
- [ ] T088 [P] [US5] Implement `lib/features/people/presentation/widgets/person_list_tile.dart`: name, relationship tag, `BalanceStatusBadge` (T053), archive action.
- [ ] T089 [P] [US5] Implement `lib/features/people/presentation/widgets/relationship_tag_chip.dart`.
- [ ] T090 [US5] Implement `lib/features/people/presentation/pages/people_list_page.dart`: searchable/filterable active-people list (FR-019) using `PersonListTile`, entry points into `PersonFormPage` (create) and `PersonDetailPage`, and an archive action (depends on T085, T088, T089).
- [ ] T091 [US5] Implement `lib/features/people/presentation/pages/person_form_page.dart`: full create/edit form (name, phone, relationship tag, notes), reusing `DuplicateWarningSheet` (T043) in create mode, and a delete action that shows an "archive instead?" dialog when `DeletePerson` returns `PersonHasTransactionsFailure` (FR-017) (depends on T086).
- [ ] T092 [US5] Implement `lib/features/people/presentation/pages/archived_people_page.dart`: searchable archived list with a "Restore" action per person, linking into `PersonDetailPage` for full history (FR-018, AC4) (depends on T087).
- [ ] T093 [US5] Register `/people`, `/people/new`, `/people/:id/edit`, `/people/archived` routes in `lib/core/routing/app_router.dart`, and make `PeopleListPage` the app's home/landing route, replacing the Foundational placeholder (T014/T046) (depends on T090-T092).

**Checkpoint**: User Stories 1-5 all work independently.

---

## Phase 8: User Story 6 - Correct or Remove a Mistaken Transaction (Priority: P3)

**Goal**: Edit or delete a transaction safely, with the balance recalculating immediately and the change remaining traceable.

**Independent Test**: Record a transaction with a wrong amount, correct it, confirm the person's balance recalculates and the change is traceable.

### Tests for User Story 6 ⚠️

- [ ] T094 [P] [US6] Unit test `EditTransaction`: updates `amount`/`direction`/`date`/`note`, sets `editedAt`, never changes `kind`/`id`/`idempotencyKey`/`personId`/`createdAt` (FR-015, data-model.md State transitions), and appends an `edited` `TransactionAuditEntry` with the pre-edit snapshot — in `test/features/transactions/domain/usecases/edit_transaction_test.dart`.
- [ ] T095 [P] [US6] Unit test `DeleteTransaction`: sets `deletedAt` (soft delete, never mutating `amount`/`direction`/`date`/`note` in place), appends a `deleted` `TransactionAuditEntry`, and excludes the row from subsequent balance/history/overview reads — in `test/features/transactions/domain/usecases/delete_transaction_test.dart`.
- [ ] T096 [P] [US6] Extend the `PersonDetailCubit` `bloc_test` (T048) with edit/delete flows: balance recalculates immediately after either action (AC1/AC2) — in `test/features/transactions/presentation/cubit/person_detail_cubit_test.dart`.

### Implementation for User Story 6

- [ ] T097 [US6] Extend `transactions_dao.dart`/`transactions_repository_impl.dart` (T034/T036/T059/T069) with `editTransaction` (the method signature never accepts a `kind` parameter, matching `contracts/transactions_repository.md`; writes the pre-edit snapshot to `previousValuesJson` and sets `editedAt`) and `deleteTransaction` (sets `deletedAt`, writes a `deleted` audit entry) — each in a single DB transaction.
- [ ] T098 [P] [US6] Implement `lib/features/transactions/domain/usecases/edit_transaction.dart`.
- [ ] T099 [P] [US6] Implement `lib/features/transactions/domain/usecases/delete_transaction.dart`.
- [ ] T100 [US6] Extend `transaction_form_cubit.dart`/`transaction_form_page.dart` (T042/T045) with an edit mode: prefilled from an existing `MoneyTransaction`, `amount`/`direction`/`date`/`note` editable, `kind` shown read-only, calls `EditTransaction` instead of `AddTransaction`, and refreshes `PersonDetailCubit`/`OverviewCubit` on success (depends on T098).
- [ ] T101 [P] [US6] Implement `lib/features/transactions/presentation/widgets/delete_transaction_confirm_dialog.dart`: an explicit confirmation stating the action cannot be undone (FR-016, AC3) before `DeleteTransaction` is called.
- [ ] T102 [US6] Wire an edit action and a delete action (via T101) onto each row in `transaction_list_tile.dart`/`person_detail_page.dart`, refreshing balance/history/overview after either completes (FR-014) (depends on T099, T100, T101).
- [ ] T103 [US6] Register the `/transactions/:id/edit` route in `lib/core/routing/app_router.dart` (depends on T100).

**Checkpoint**: All 6 user stories are independently functional.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Localization completeness, RTL verification, end-to-end validation, performance, and static-analysis cleanliness across every story above.

- [ ] T104 [P] Populate `lib/core/l10n/app_en.arb` and `app_ar.arb` with the full string set used across all screens built in Phases 3-8 (labels, validation messages, confirmation dialogs, empty states), then regenerate `AppLocalizations` (FR-022).
- [ ] T105 [P] Full Arabic RTL pass: verify `PeopleListPage`, `PersonDetailPage`, `TransactionFormPage`, `OverviewPage`, `ArchivedPeoplePage` render correctly under `Locale('ar')` with RTL `Directionality`, with no hardcoded English strings remaining (FR-022, quickstart.md §7).
- [ ] T106 [P] Write `integration_test/money_relationships_flows_test.dart` covering quickstart.md's end-to-end flows: record a transaction (new + existing person), view balance/history, repayment (partial/full/overshoot), overview totals + archived-balance inclusion, archive/restore, edit/delete traceability, and double-tap idempotency (US1-US6; SC-001, SC-002, SC-003, SC-006, SC-007).
- [ ] T107 Performance validation: seed 500 people / 10,000 transactions in a test harness and confirm `GetOverview`/`OverviewCubit` renders correct totals in under 2 seconds (SC-005), and that `PersonDetailPage` scrolling for a person with many transactions sustains ~60fps with no single frame exceeding 32ms during a scripted scroll (User Story 2, Acceptance Scenario 4's measurable threshold), using Flutter's frame-timing APIs (`SchedulerBinding.addTimingsCallback` or `integration_test`'s `traceAction`/timeline summary) to capture the measurement.
- [ ] T108 [P] Run `flutter analyze` and resolve all findings (constitution's static-analysis gate must be clean); run `dart format lib test integration_test`.
- [ ] T109 Re-verify the Constitution Check's Post-Design gates against the finished implementation (Clean Architecture layering, no direct DB/API access from widgets, `Either`-based error handling everywhere, integer-minor-unit money throughout, the corrected balance-sign formula applied consistently) and fix any drift found.
- [ ] T110 Execute quickstart.md's full manual validation script end-to-end on a device/emulator (all 7 scripted scenarios) as the final Definition of Done check.
- [ ] T111 [P] Concurrent same-device edit test (spec.md Edge Cases: "the more recent confirmed edit wins"): in `test/features/transactions/data/repositories/transactions_repository_impl_test.dart`, simulate two overlapping `editTransaction` calls against the same `MoneyTransaction` row (e.g. two in-flight `Future`s completing out of submission order) against the in-memory DB, and assert the persisted row and its latest `TransactionAuditEntry` reflect the edit with the later `changedAt`, never a merged or ambiguous state — verifying research.md Decision 7's "handled by SQLite's own transactional isolation" claim with an actual test rather than leaving it asserted-only.
- [ ] T112 [P] Plan and run a small moderated usability-test session (5-8 participants) against SC-008: show each participant a `PersonDetailPage` for a person they haven't seen before (one "they owe you", one "you owe them", one "Settled") with no prior explanation, and record whether they correctly state the balance status; target ≥90% correct without help. Document the script and results in `specs/001-money-relationships-tracking/usability-test-results.md`. This is a research/UX task, not a code task — schedule it separately from the engineering checkpoints if no participants are available yet, but it MUST be completed before SC-008 is considered met.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories.
- **User Stories (Phase 3-8)**: All depend on Foundational completion.
  - US1 and US2 are both P1 and should be done first, in order (US2 reuses US1's `TransactionFormPage` navigation target).
  - US3 (repayment) and US4 (overview) are P2, each depending on US1's transaction-writing infrastructure and US2's `PersonDetailPage` as an entry point (US3) or reading US1/US3's data (US4).
  - US5 (manage people) and US6 (correct/remove transaction) are P3; US6 extends US1's `TransactionFormCubit`/`TransactionFormPage`.
- **Polish (Phase 9)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on other stories beyond Foundational.
- **US2 (P1)**: Reuses US1's `TransactionFormPage`/routing as its "record a transaction" entry point, but its own balance/history display is independently testable.
- **US3 (P2)**: Needs `PersonDetailPage` (US2) as its entry point; reuses US1's idempotency/DAO patterns.
- **US4 (P2)**: Reads data US1/US3 write; independently testable once US1 exists.
- **US5 (P3)**: Extends the `PeopleRepository`/`Person` foundation from US1; reuses US1's `DuplicateWarningSheet`.
- **US6 (P3)**: Extends US1's `TransactionFormCubit`/`TransactionFormPage` and US2's `PersonDetailPage`/`TransactionListTile`.

### Within Each User Story

- Tests MUST be written and FAIL before implementation.
- Entities/value objects → repository interfaces → DAOs → repository implementations → use cases → DI registration → Cubits → widgets → pages → routes.
- Story complete (checkpoint) before moving to the next priority.

### Parallel Opportunities

- All Setup tasks marked `[P]` can run in parallel.
- All Foundational tasks marked `[P]` can run in parallel once T006 (Failure base) exists.
- Within a story, all test tasks marked `[P]` can run in parallel (different files).
- Within a story, entity/value-object definition tasks marked `[P]` can run in parallel; DAO/repository-impl tasks are sequential (same files, shared DB schema); use-case tasks marked `[P]` can run in parallel once their repository method exists.
- US5 and US6 can be built in parallel by different developers once US1-US4 are complete, since US5 touches `features/people/` and US6 mostly touches `features/transactions/`.

---

## Parallel Example: User Story 1

```bash
# Launch all US1 tests together:
Task: "Unit test FindPossibleDuplicatePerson in test/features/people/domain/usecases/find_possible_duplicate_person_test.dart"
Task: "Unit test CreatePerson in test/features/people/domain/usecases/create_person_test.dart"
Task: "Unit test AddTransaction in test/features/transactions/domain/usecases/add_transaction_test.dart"
Task: "Unit test GetPersonBalance in test/features/transactions/domain/usecases/get_person_balance_test.dart"

# Launch all US1 entity/value-object definitions together:
Task: "Define Person entity in lib/features/people/domain/entities/person.dart"
Task: "Define RelationshipStatus + PersonBalance in lib/features/transactions/domain/entities/person_balance.dart"
Task: "Define TransactionDirection/TransactionKind + MoneyTransaction in lib/features/transactions/domain/entities/money_transaction.dart"
Task: "Add PossibleDuplicateFailure in lib/features/people/domain/entities/people_failures.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories).
3. Complete Phase 3: User Story 1 (record a transaction).
4. Complete Phase 4: User Story 2 (view balance/history) — together these two P1 stories deliver the product's core value proposition.
5. **STOP and VALIDATE**: run quickstart.md scenarios 1-2 manually; demo if ready.

### Incremental Delivery

1. Setup + Foundational → Foundation ready.
2. US1 + US2 → Test independently → Deploy/Demo (MVP).
3. US3 (repayment) → Test independently → Deploy/Demo.
4. US4 (overview) → Test independently → Deploy/Demo.
5. US5 (manage people) → Test independently → Deploy/Demo.
6. US6 (correct/remove) → Test independently → Deploy/Demo.
7. Polish (Phase 9) → Full localization, RTL, integration tests, performance validation, final constitution/quickstart sign-off.

### Parallel Team Strategy

With multiple developers, after Setup + Foundational:
- Developer A: US1 → US2 (sequential, P1 first).
- Developer B: joins after US1's `PeopleRepository`/`TransactionsRepository` interfaces exist (T029/T030) to start US5's people-management work.
- Once US1-US4 are done, Developer A/B split US5/US6 in parallel (different feature subfolders).

---

## Notes

- `[P]` tasks touch different files with no unmet dependencies at the time they're started.
- `[Story]` labels map tasks to spec.md's US1-US6 for traceability.
- **Balance-sign formula applies throughout**: every task computing or aggregating a balance (T021, T026, T034, T036, T057-T059, T065-T069) uses `given − received`, matching data-model.md and spec.md FR-008 — see the callout at the top of this file.
- `kind` (initial exchange vs. repayment) is fixed at creation everywhere (T027, T036, T059, T097) — there is no code path that lets an edit change it (Clarifications).
- T111 and T112 close out `/speckit-analyze` findings F1 (concurrent-edit resolution has no dedicated test) and E1 (SC-008 usability criterion has no dedicated task) — both are part of Definition of Done for Phase 9, not optional polish.
- Verify each story's tests fail before implementing it; commit after each task or logical group; stop at any checkpoint to validate a story independently.
