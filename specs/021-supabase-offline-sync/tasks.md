---
description: "Task list for 021 Offline-First Cloud Sync (Supabase)"
---

# Tasks: Offline-First Cloud Sync (Supabase)

**Input**: Design documents from `/specs/021-supabase-offline-sync/`: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: REQUIRED. The spec's §17 Testing Strategy and SC-001 to SC-010 make tests part of acceptance. The constitution (XVI) also requires them.

**Organization**: Tasks are grouped by the spec's user stories:

- US1: Offline keeps working, P1
- US2: Offline changes upload, P1
- US3: Existing data backed up, P1
- US4: Remote changes appear, P2
- US5: Financial conflicts, P2
- US6: Sync status, P3

## Format

`- [ ] T### [P?] [US#?] Description with path`

Each task is followed by indented lines:

- **Deps**: the tasks it depends on;
- **Files**: the exact paths it creates or changes;
- **Done when**: the acceptance criteria;
- **Validate**: the check that proves it.

**[P]** means the task touches different files from every other task still open in its group and has no unfinished dependency.

**Code generation rule**: several parallel tasks change `@injectable` or Drift annotations. Parallel tasks must **not** commit a regenerated `lib/core/di/injection.config.dart` or `app_database.g.dart`. Only the group's closing task (T022, T041, T061, T079) runs `dart run build_runner build` and commits the generated files.

**Path conventions**:

- Flutter code lives in `lib/`, tests in `test/`, device tests in `integration_test/`.
- The backend lives in `supabase/`.
- Every existing path cited here was verified in the repository at `fbce88f`. Paths marked **(new)** are created by the task.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Baseline, packages, configuration and platform prerequisites. Maps to plan P0.

- [X] T001 Record the pre-feature baseline in specs/021-supabase-offline-sync/checklists/baseline.md (new)
  - Deps: none
  - Files: `specs/021-supabase-offline-sync/checklists/baseline.md` (new)
  - Done when:
    - The output of `flutter --version` is recorded (it must be 3.47.x).
    - The number of issues from `flutter analyze` is recorded.
    - The pass/fail counts from `flutter test` are recorded.
    - Each of the 11 `integration_test/*_test.dart` flows is recorded as passing or failing.
    - The plan §1 facts are confirmed still true: `AppDatabase.schemaVersion == 8`; the 7 DAOs under `lib/features/*/data/datasources/`; no `INTERNET` permission in `android/app/src/main/AndroidManifest.xml`.
  - Validate: this file is the regression reference for T086.

- [X] T002 Add the three packages to pubspec.yaml and resolve them
  - Deps: T001
  - Files: `pubspec.yaml`, `pubspec.lock`
  - Done when these packages are added under `dependencies:`, each with a one-line comment giving its purpose (research Decision 21):
    - `supabase_flutter: ^2.17.2` (auth and RPC; requires Dart ≥3.9, Flutter ≥3.35)
    - `connectivity_plus: ^7.3.1` (a network hint only)
    - `flutter_secure_storage: ^11.2.0` (session storage, constitution XII)
    - No other package is added: no rxdart, workmanager, dotenv or logger.
  - Validate: `flutter pub get` succeeds and `flutter analyze` shows no new issues.

- [X] T003 [P] Add the committed placeholder config config/supabase.example.json (new) and the git-ignore rules in .gitignore
  - Deps: none
  - Files: `config/supabase.example.json` (new), `.gitignore`
  - Done when:
    - The example file is `{"SUPABASE_URL": "https://nnrmghwqihqnmtnuxzoq.supabase.co", "SUPABASE_PUBLISHABLE_KEY": "<publishable-key-here>"}`.
    - `.gitignore` gains `config/*.json`, `!config/supabase.example.json` and `supabase/.temp/`.
  - Validate: `git check-ignore config/supabase.dev.json` succeeds, and `git check-ignore config/supabase.example.json` fails.

- [X] T004 [P] Create CloudConfig in lib/core/config/cloud_config.dart (new), with a test in test/core/config/cloud_config_test.dart (new)
  - Deps: none
  - Files: the two paths above
  - Done when:
    - It uses `String.fromEnvironment('SUPABASE_URL')` and `String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY')`.
    - `isConfigured` is true only when both are non-empty.
    - The URL and key appear nowhere else in `lib/`.
  - Validate: a plain `flutter test` (no defines) sees `isConfigured == false`.

- [X] T005 [P] Add `<uses-permission android:name="android.permission.INTERNET"/>` to android/app/src/main/AndroidManifest.xml
  - Deps: none
  - Files: `android/app/src/main/AndroidManifest.xml` only. No other Android file changes.
  - Done when: the permission sits next to the existing `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` entries.
  - Validate: the merged manifest of `flutter build apk --debug` contains `INTERNET`, plus `ACCESS_NETWORK_STATE` from `connectivity_plus`.

- [X] T006 [P] Initialize the Supabase CLI project in supabase/ (new)
  - Deps: none. Prerequisites: install the Supabase CLI (`brew install supabase/tap/supabase`) and Docker.
  - Files: `supabase/config.toml` (new)
  - Done when:
    - `supabase init` has run.
    - `[auth] enable_anonymous_sign_ins = true` is set for the local stack, along with `[auth.rate_limit] anonymous_users = 30` (per hour per IP).
    - The email one-time-code template uses `{{ .Token }}`.
  - Validate: `supabase start` boots the local stack.

**Checkpoint**: the packages resolve, the config mechanism exists, and the platform prerequisites are in place.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Local sync schema, the v9 migration, outbox machinery, mappers, failures and logging. Every user story depends on this phase. Maps to plan P1 and the core of P3.

**⚠️ CRITICAL**: No user-story work starts until this phase is complete.

- [X] T007 [P] Add the sync failure types in lib/core/error/failure.dart and their messages in lib/core/l10n/failure_message.dart, lib/core/l10n/app_en.arb and lib/core/l10n/app_ar.arb
  - Deps: none
  - Files: the four paths above, plus the regenerated `lib/core/l10n/app_localizations*.dart`
  - Done when:
    - `NetworkFailure`, `TimeoutFailure`, `ServerFailure`, `UnauthorizedFailure`, `ForbiddenFailure`, `SyncRejectedFailure(reason)` and `SyncConflictFailure` extend `Failure`, and the 4 existing subclasses are unchanged.
    - Each has a localized, user-friendly message in both Arabic and English.
  - Validate: `flutter gen-l10n`, then `flutter analyze`.

- [X] T008 [P] Create SyncEntityType in lib/core/sync/sync_entity_type.dart (new)
  - Deps: none
  - Done when:
    - The enum is `person, moneyTransaction, transactionAudit, financeCategory, financeEntry, exchangeRate, primaryCurrency, conflictResolution`.
    - `.wire` returns `'person'`, `'money_transaction'`, `'transaction_audit'`, `'finance_category'`, `'finance_entry'`, `'exchange_rate'`, `'primary_currency'` and `'conflict_resolution'`.
    - `.rank` is 0 for person and category; 1 for transaction and entry; 2 for audit and conflict resolution; 3 for rate and primary currency (data-model.md `depends_on_rank`).
    - `fromWire` throws on an unknown value.
  - Validate: `test/core/sync/sync_entity_type_test.dart` (new) round-trips every value.

- [X] T009 [P] Create SyncLogger in lib/core/sync/sync_logger.dart (new), with a test in test/core/sync/sync_logger_test.dart (new)
  - Deps: none
  - Done when:
    - The `SyncEvent` enum has one value per event, and the enum names map to the logged names: `SYNC_STARTED`, `SYNC_UPLOAD_STARTED`, `SYNC_UPLOAD_SUCCESS`, `SYNC_UPLOAD_FAILED`, `SYNC_DOWNLOAD_STARTED`, `SYNC_DOWNLOAD_SUCCESS`, `SYNC_CONFLICT`, `SYNC_RETRY`, `SYNC_COMPLETED`, `SYNC_ABORTED`, `SYNC_MIGRATION_ENQUEUED` and `SYNC_CURSOR_ADVANCED`.
    - The allowed field keys are the enum `SyncLogField {entityType, count, durationMs, errorCode, delayMs, revision, opId}` and nothing else.
    - The `DeveloperSyncLogger` implementation writes to `dart:developer` `log`. In release builds it logs only `SYNC_UPLOAD_FAILED`, `SYNC_ABORTED` and `SYNC_CONFLICT`.
    - It is registered as `@LazySingleton(as: SyncLogger)`.
  - Validate: the test shows that the API cannot accept any key outside the enum, and checks the output format.

- [X] T010 Define the Drift sync tables in lib/core/database/sync_tables.dart (new)
  - Deps: none
  - Done when these tables match data-model.md §2 exactly:
    - `SyncOutbox` has `opId` (PK), `entityType`, `entityId`, `opType` (`upsert` or `delete`), `payloadJson`, `baseRevision` (nullable), `dependsOnRank`, `status` (`pending`, `in_flight`, `failed` or `blocked_conflict`), `attemptCount` (default 0), `lastAttemptAt` (nullable), `nextAttemptAt` (nullable), `errorCode` (nullable, a code only) and `createdAt`. Its indexes are `idx_outbox_ready (status, depends_on_rank, created_at)` and `idx_outbox_entity (entity_type, entity_id, status)`.
    - `SyncRecordMeta` has the primary key `(entityType, entityId)`, plus `serverRevision` (nullable), `state` (`synced`, `pending`, `failed` or `conflict`) and `lastSyncedAt` (nullable). Its index is `idx_meta_state (state)`.
    - `SyncConflicts` has `id` (PK), `entityType`, `entityId`, `localPayloadJson`, `serverPayloadJson`, `serverRevision`, `detectedAt` and `resolvedAt` (nullable).
    - `ConflictResolutions` has `id` (PK), `entityType`, `entityId`, `chosenSide` (`local` or `server`), `discardedValuesJson` and `resolvedAt`.
    - `SyncState` is a single row keyed by `'singleton'`, with `enabled` (default **true**), `noticeShown` (default false), `ownerId` (nullable), `deviceId`, `lastPulledRevision` (default 0), `bootstrapEnqueued` (default false), `initialUploadDone` (default false), `lastAttemptAt`, `lastSuccessAt`, `consecutiveFailures` (default 0) and `lastErrorCode`.
  - Validate: this compiles once registered in T011.

- [X] T011 Register the sync tables and write the v9 migration in lib/core/database/app_database.dart and lib/core/database/migrations/v9_sync_support.dart (new)
  - Deps: T010
  - Files: the two paths above, plus the regenerated `lib/core/database/app_database.g.dart`
  - Done when:
    - The 5 tables are added to `@DriftDatabase(tables: …)` and `schemaVersion` is `9`.
    - `onUpgrade` has an `if (from < 9) await migrateToSyncSupport(this, m);` branch.
    - That function creates the 5 tables and their indexes, and adds the business indexes `idx_transactions_date (date, deleted_at)` and `idx_people_archived (is_archived, normalized_name)`, as `@TableIndex` on `MoneyTransactions` and `People`.
    - It runs `UPDATE exchange_rates SET id = 'rate_' || currency_code || '_' || relative_to_currency_code`.
    - It performs **no reads**, following the `beforeOpen` precedent comment. On a fresh install `onCreate` creates everything.
  - Validate: `dart run build_runner build --delete-conflicting-outputs`, then `flutter analyze`.

- [X] T012 Write the v8→v9 migration test in test/core/database/sync_v9_migration_test.dart (new)
  - Deps: T011
  - Done when:
    - The test builds a raw schema-v8 file with a `sqlite3` handle, following the pattern in `test/core/database/migration_currency_support_test.dart`. The file holds people, transactions (including soft-deleted ones), audits, custom and seeded categories, entries, 2 rates and a primary currency.
    - After opening it as v9, every business column of every row is identical, and only `exchange_rates.id` becomes `rate_<CUR>_<REL>`.
    - The sync tables exist and are empty.
    - A forced failure inside `migrateToSyncSupport` leaves the file at `user_version = 8` with the data intact.
  - Validate: `flutter test test/core/database/sync_v9_migration_test.dart`.

- [X] T013 [P] Create the watch helper in lib/core/database/watch_tables.dart (new), with a test in test/core/database/watch_tables_test.dart (new)
  - Deps: T011
  - Done when:
    - `extension WatchTables on AppDatabase { Stream<void> changesOf(Set<TableInfo> tables) }` emits once immediately, then emits (debounced 50 ms) whenever any listed table is written, using `tableUpdates(TableUpdateQuery.onAllTables(...))`.
    - No rxdart is used.
  - Validate: the test inserts into a watched table and gets 1 event, gets 0 events for an unwatched table, and gets 1 event for 5 writes made within 50 ms.

- [X] T014 [P] Create the outbox coalescer in lib/core/sync/local/outbox_coalescer.dart (new), with a test in test/core/sync/local/outbox_coalescer_test.dart (new)
  - Deps: T008
  - Done when it is a pure function `coalesce(existingPendingOp?, newOp) → CoalesceDecision`, implementing every row of data-model.md §5:
    - upsert + upsert: replace the payload, keeping `op_id` and `base_revision`.
    - upsert with `base_revision = null` + delete, for a person, category or rate: drop both.
    - upsert with `base_revision = null` + soft delete, for a transaction or entry: an upsert with `deleted_at`, still uploaded.
    - upsert + delete for a synced record: becomes a delete, keeping `base_revision`.
    - audit and conflict-resolution inserts are never coalesced.
    - It never merges into an operation that is `in_flight`.
  - Validate: one test per row.

- [X] T015 Create SyncOutbox in lib/core/sync/local/sync_outbox.dart (new), with a test in test/core/sync/local/sync_outbox_test.dart (new)
  - Deps: T011, T014
  - Done when:
    - `recordUpsert(type, id, payload)` and `recordDelete(type, id, lastKnownPayload)` must be called *inside* a caller's `_db.transaction`, and assert that a transaction is active.
    - They look up an open operation for the entity, apply `coalesce`, and insert or update the `sync_outbox` row with `op_id` = UUID v4, `depends_on_rank` from T008, and `created_at` from `AppClock`.
    - They upsert `sync_record_meta.state = 'pending'`.
    - It is registered as `@LazySingleton(as: SyncOutbox)`.
  - Validate:
    - A throw after `recordUpsert` inside a transaction rolls back both the business row and the outbox row.
    - Three upserts produce 1 row.
    - Create then delete of a person produces 0 rows.

- [X] T016 Create the mapper contract and registry in lib/core/sync/sync_mapper_registry.dart (new)
  - Deps: T008
  - Done when:
    - It defines `abstract class SyncMapper<Row>` with `type`, `toWire(Row)` and `fromWire(Map, {Row? existingLocal})` (contracts/dart-interfaces.md §2).
    - `SyncMapperRegistry` resolves a mapper by `SyncEntityType` and throws on an unregistered type.
    - Wire money values are **strings**. Dates are ISO-8601 UTC, and `occurred_on` is `yyyy-MM-dd` in device-local time, together with `tz_offset_minutes`.
  - Validate: compiles, and the registry test in T023 covers it.

- [X] T017 [P] Create the person mapper in lib/features/people/data/sync/person_sync_mapper.dart (new), with a test in test/features/people/data/sync/person_sync_mapper_test.dart (new)
  - Deps: T016
  - Done when:
    - The fields are `id`, `name`, `normalized_name`, `phone_number`, `relationship_tag`, `notes`, `is_archived`, `client_created_at`, `client_updated_at` and `deleted_at`.
    - `avatarPath` is **never** emitted. `fromWire` keeps `existingLocal.avatarPath`, or uses null.
  - Validate: a round trip is lossless apart from `avatarPath`, and a test asserts that the key `avatar_path` is absent.

- [X] T018 [P] Create the transaction and audit mappers in lib/features/transactions/data/sync/money_transaction_sync_mapper.dart (new) and lib/features/transactions/data/sync/transaction_audit_sync_mapper.dart (new), with tests in test/features/transactions/data/sync/ (new)
  - Deps: T016
  - Done when:
    - `amount_minor` is a string; `direction` is in {`given`, `received`}; `kind` is in {`initialExchange`, `repayment`}; `occurred_at`, `occurred_on` and `tz_offset_minutes` are derived from `date`; `edited_at` and `deleted_at` are ISO or null; `idempotency_key` and `currency_code` are carried over.
    - The audit mapper carries `change_type` unchanged, with values in {`created`, `edited`, `deleted`}, and `previous_values` as a JSON object.
  - Validate: round trips, including an amount of 9,007,199,254,740,993 minor units (above 2⁵³), which must be lossless.

- [X] T019 [P] Create the category and entry mappers in lib/features/finance/data/sync/finance_category_sync_mapper.dart (new) and lib/features/finance/data/sync/finance_entry_sync_mapper.dart (new), with tests in test/features/finance/data/sync/ (new)
  - Deps: T016
  - Done when:
    - Categories carry `icon` ↔ `icon_key`, `type` in {`income`, `expense`}, and `is_default`.
    - Entries have the same money and date rules as T018, plus `category_id`.
    - A helper `isPristineSeed(FinanceCategory)` returns true only when the id starts with `seed_` and `name`, `icon` and `isArchived` equal `defaultFinanceCategorySeeds` in `lib/core/database/finance_category_seed.dart`.
  - Validate: round trips, and the pristine-seed cases (renamed, archived, untouched).

- [X] T020 [P] Create the rate and primary-currency mappers in lib/features/currency/data/sync/exchange_rate_sync_mapper.dart (new) and lib/features/currency/data/sync/primary_currency_sync_mapper.dart (new), with tests in test/features/currency/data/sync/ (new)
  - Deps: T016
  - Done when:
    - Rates carry `rate_micros` as a string, and the id is `rate_<CUR>_<REL>`.
    - Primary currency uses the id `'singleton'` and carries `currency_code`.
  - Validate: round trips.

- [X] T021 [P] Create the conflict-resolution mapper in lib/features/cloud_sync/data/sync/conflict_resolution_sync_mapper.dart (new), with a test in test/features/cloud_sync/data/sync/conflict_resolution_sync_mapper_test.dart (new)
  - Deps: T016
  - Done when:
    - `entity_type` is in {`money_transaction`, `finance_entry`}, and `chosen_side` is in {`local`, `server`}.
    - `discarded_values` is a JSON object, and `resolved_at` is ISO.
  - Validate: round trip.

- [X] T022 Register the third-party singletons in lib/core/di/register_module.dart and regenerate lib/core/di/injection.config.dart
  - Deps: T002, T009, T015, T016, T017, T018, T019, T020, T021
  - Done when:
    - `Connectivity` and `FlutterSecureStorage` are registered as `@lazySingleton`.
    - `SupabaseClient` is **not** registered yet (that is T061).
    - The 8 mappers and the registry are registered.
  - Validate: `dart run build_runner build`, then `flutter test test/` shows no DI resolution errors.

- [X] T023 Test that the mapper registry resolves every entity type, in test/core/sync/sync_mapper_registry_test.dart (new)
  - Deps: T017–T022
  - Done when: resolving all 8 `SyncEntityType` values through `getIt` succeeds.
  - Validate: `flutter test test/core/sync/`.

**Checkpoint**:

- The v9 schema is migrated and tested.
- The outbox is atomic and coalesces correctly.
- Every entity has a lossless wire mapper.
- The DI graph is valid.

---

## Phase 3: User Story 1 - Everything keeps working with no connection (Priority: P1) 🎯 MVP

**Goal**: Every write is recorded durably in the queue, and every screen updates from local data with no manual reload. That covers new people, new transactions, archive and unarchive, and balances. Maps to plan P2 and P3.

**Independent Test**:

- With `CloudConfig` unconfigured or in airplane mode, run the 11 existing integration flows. They pass.
- Mutations leave the correct outbox rows, and those rows survive a restart.
- Open screens update without calling `load()`.

### Tests for User Story 1 (write first; they must FAIL before implementation)

- [X] T024 [P] [US1] Write the DAO outbox guard test in test/core/sync/dao_outbox_guard_test.dart (new)
  - Deps: T015
  - Done when, for every mutating public method of the four DAOs listed below, called against an in-memory database, it asserts that exactly one outbox row with the expected `entity_type` and `op_type` exists afterwards. The only exception is the idempotent no-op path, which must record nothing. The methods are:
    - `PeopleDao`: `insertPerson`, `updatePerson`, `setArchived`, `deletePerson`
    - `TransactionsDao`: `insertTransactionIdempotent` (new key, then the same key again), `updateTransaction`, `softDelete`, `insertAuditEntry`
    - `FinanceDao`: `insertCategory`, `updateCategory`, `archiveCategory`, `deleteCategory`, `insertEntryIdempotent`, `updateEntry`, `softDeleteEntry`, `restoreEntry`
    - `CurrencyDao`: `upsertPrimary`, `upsertRate`, `deleteRatesFrom`
  - Validate: the test fails before T025–T028 and passes after them. Until those land it may fail to *compile*, because the DAO constructors change. Keep it out of any full `flutter test` run until T025–T028 are merged, or write it and T025–T028 in the same change.

- [X] T025 [P] [US1] Record outbox entries in lib/features/people/data/datasources/people_dao.dart
  - Deps: T015, T017
  - Done when:
    - Each write method wraps its write in `_db.transaction` and calls `recordUpsert(person, id, mapper.toWire(row))`.
    - `deletePerson` reads the row first, then calls `recordDelete`.
    - `SyncOutbox` and the mapper are injected through the constructor.
  - Validate: the people rows of T024 pass, and `test/features/people/data/repositories/people_repository_impl_test.dart` still passes.

- [X] T026 [P] [US1] Record outbox entries in lib/features/transactions/data/datasources/transactions_dao.dart
  - Deps: T015, T018
  - Done when:
    - `insertTransactionIdempotent` records only when it actually inserted a row.
    - `updateTransaction` and `softDelete` record an upsert of the resulting row.
    - `insertAuditEntry` records a `transactionAudit` upsert.
    - Everything joins the repository's existing transaction for edit or delete together with its audit entry.
  - Validate: T024's transaction rows pass, and `test/features/transactions/data/repositories/transactions_repository_impl_test.dart` passes.

- [X] T027 [P] [US1] Record outbox entries in lib/features/finance/data/datasources/finance_dao.dart
  - Deps: T015, T019
  - Done when: every category and entry write records an outbox entry, with `deleteCategory` recording a delete. `lib/core/database/finance_category_seed.dart` stays untouched: seeding writes directly and records nothing.
  - Validate: T024's finance rows pass, the finance repository tests pass, and a fresh install produces 0 outbox rows.

- [X] T028 [P] [US1] Record outbox entries in lib/features/currency/data/datasources/currency_dao.dart and use deterministic rate ids in lib/features/currency/data/repositories/currency_repository_impl.dart
  - Deps: T015, T020
  - Done when:
    - `upsertRate` receives `newId: 'rate_${currencyCode}_$relativeToCurrencyCode'`, which replaces `_uuid.v4()`.
    - `deleteRatesFrom` selects the matching ids inside the same transaction and records one delete per row.
    - `upsertPrimary` records a `primaryCurrency` upsert.
  - Validate: T024's currency rows pass, and `test/features/currency/data/repositories/currency_repository_impl_test.dart` passes after its id expectations are updated.

### Reactive reads for User Story 1

- [X] T029 [P] [US1] Add watch methods to the people repository and create two use cases
  - Deps: T013
  - Files:
    - `lib/features/people/domain/repositories/people_repository.dart`
    - `lib/features/people/data/repositories/people_repository_impl.dart`
    - `lib/features/people/domain/usecases/watch_active_people.dart` (new)
    - `lib/features/people/domain/usecases/watch_archived_people.dart` (new)
    - `test/features/people/data/repositories/people_repository_watch_test.dart` (new)
  - Done when:
    - `watchActivePeople({nameQuery, statusFilter})` and `watchArchivedPeople({nameQuery})` equal `changesOf({people, moneyTransactions})` mapped through the existing search methods and filtered with `distinct()`.
    - The existing `get` and `search` methods are unchanged.
  - Validate:
    - The first emission equals `searchActivePeople`.
    - After `createPerson` there is a new emission containing the person.
    - After `archivePerson` the person moves from the active stream to the archived stream.

- [X] T030 [P] [US1] Add watch methods to the transactions repository and create four use cases
  - Deps: T013
  - Files:
    - `lib/features/transactions/domain/repositories/transactions_repository.dart`
    - `lib/features/transactions/data/repositories/transactions_repository_impl.dart`
    - `lib/features/transactions/domain/usecases/` (new files): `watch_person_history.dart`, `watch_person_balance.dart`, `watch_person_balances.dart`, `watch_overview.dart`
    - `test/features/transactions/data/repositories/transactions_repository_watch_test.dart` (new)
  - Done when:
    - History watches `{moneyTransactions}`.
    - Balance, balances and overview watch `{moneyTransactions, people, exchangeRates, primaryCurrencySettings}`, reusing `getPersonBalance`, `getPersonBalances` and `getOverview` as they are.
  - Validate:
    - After `addTransaction` the history and balance streams emit the new state.
    - Changing an exchange rate re-emits the converted balance.

- [X] T031 [P] [US1] Add watch methods to the finance and category repositories and create three use cases
  - Deps: T013
  - Files:
    - `lib/features/finance/domain/repositories/finance_repository.dart`
    - `lib/features/finance/domain/repositories/category_repository.dart`
    - `lib/features/finance/data/repositories/finance_repository_impl.dart`
    - `lib/features/finance/data/repositories/category_repository_impl.dart`
    - `lib/features/finance/domain/usecases/` (new files): `watch_finance_history.dart`, `watch_finance_summary.dart`, `watch_categories.dart`
    - `test/features/finance/data/repositories/finance_repository_watch_test.dart` (new)
  - Done when:
    - `watchHistory({filter, required limit})` watches only the loaded window.
    - `watchSummaryTotals(period)` and `watchCategories(...)` take the same parameters as the existing `getCategories`.
  - Validate: the streams emit after entry and category writes, and `watchHistory(limit: 50)` never emits more than 50 rows.

- [X] T032 [US1] Add watch methods to the currency repository and create two use cases
  - Deps: T013, T028 (both edit `currency_repository_impl.dart`, so they run in sequence)
  - Files:
    - `lib/features/currency/domain/repositories/currency_repository.dart`
    - `lib/features/currency/data/repositories/currency_repository_impl.dart`
    - `lib/features/currency/domain/usecases/watch_exchange_rates.dart` (new)
    - `lib/features/currency/domain/usecases/watch_primary_currency.dart` (new)
    - `test/features/currency/data/repositories/currency_repository_watch_test.dart` (new)
  - Done when: `watchExchangeRates()` and `watchPrimaryCurrency()` emit after writes.
  - Validate: the watch tests pass.

- [X] T033 [US1] Move PersonListCubit to subscriptions
  - Deps: T029, T030
  - Files:
    - `lib/features/people/presentation/cubit/person_list_cubit.dart` and `person_list_state.dart`
    - `lib/features/people/presentation/pages/people_list_page.dart`
    - `test/features/people/presentation/cubit/person_list_cubit_test.dart`
  - Done when:
    - The Cubit subscribes to `WatchActivePeople` and `WatchPersonBalances`, and cancels both subscriptions in `close()`.
    - Filter changes resubscribe.
    - `archive` and `undoArchive` no longer call `load()`.
    - The page no longer calls `load()` after `context.push` returns.
    - The retry button calls `resubscribe()`.
  - Validate: a `bloc_test` shows that a person created through the repository appears with no `load()` call, and that archiving removes it.

- [X] T034 [US1] Move ArchivedPeopleCubit to subscriptions
  - Deps: T029
  - Files: `lib/features/people/presentation/cubit/archived_people_cubit.dart`, `lib/features/people/presentation/pages/archived_people_page.dart`, `test/features/people/presentation/cubit/archived_people_cubit_test.dart`
  - Done when: restoring a person updates the list with no reload, and the 005 archive-refresh behavior is kept.
  - Validate: `bloc_test`, plus `integration_test/archive_state_refresh_flow_test.dart` passes.

- [X] T035 [US1] Move PersonDetailCubit to subscriptions
  - Deps: T030
  - Files: `lib/features/transactions/presentation/cubit/person_detail_cubit.dart`, `lib/features/transactions/presentation/pages/person_detail_page.dart`, `test/features/transactions/presentation/cubit/person_detail_cubit_test.dart`
  - Done when:
    - The Cubit subscribes to `WatchPersonHistory(id)` and `WatchPersonBalance(id)`.
    - `refresh()` is removed, and `deleteTransaction` relies on the stream.
    - The page drops its post-navigation reloads.
  - Validate: a `bloc_test` shows that adding, editing or deleting a transaction emits new history and balance with no `refresh()`, and there are no duplicate rows (the 004 acceptance scenarios).

- [X] T036 [US1] Move OverviewCubit to subscriptions
  - Deps: T030
  - Files: `lib/features/transactions/presentation/cubit/overview_cubit.dart`, `lib/features/transactions/presentation/pages/overview_page.dart`, `test/features/transactions/presentation/cubit/overview_cubit_test.dart`
  - Done when: the Cubit subscribes to `WatchOverview`, and the "reload from other screens" calls are removed.
  - Validate: a `bloc_test` shows the totals change after a transaction is added elsewhere.

- [X] T037 [US1] Move FinanceHistoryCubit to subscriptions
  - Deps: T031
  - Files: `lib/features/finance/presentation/cubit/finance_history_cubit.dart`, `lib/features/finance/presentation/pages/finance_history_page.dart`, `test/features/finance/presentation/cubit/finance_history_cubit_test.dart`
  - Done when:
    - The Cubit subscribes to `WatchFinanceHistory(limit: loadedCount)`.
    - "Load more" increases the limit and resubscribes without losing scroll position.
    - Pull-to-refresh stays as a resubscribe.
  - Validate: `bloc_test` for add, delete and restore.

- [X] T038 [US1] Move FinanceMonthSummaryCubit to subscriptions
  - Deps: T031
  - Files: `lib/features/finance/presentation/cubit/finance_month_summary_cubit.dart`, `lib/features/finance/presentation/widgets/finance_month_summary_card.dart`, `test/features/finance/presentation/cubit/finance_month_summary_cubit_test.dart` (new)
  - Done when: the Cubit subscribes to `WatchFinanceSummary(period)`.
  - Validate: `bloc_test`.

- [X] T039 [US1] Move CategoryManagementCubit to subscriptions
  - Deps: T031
  - Files: `lib/features/finance/presentation/cubit/category_management_cubit.dart`, `lib/features/finance/presentation/pages/category_management_page.dart`, `test/features/finance/presentation/cubit/category_management_cubit_test.dart`
  - Done when: the Cubit subscribes to `WatchCategories`, and the reload after the form closes is removed.
  - Validate: `bloc_test`.

- [X] T040 [US1] Move ExchangeRateListCubit and PrimaryCurrencyCubit to subscriptions
  - Deps: T032
  - Files:
    - `lib/features/currency/presentation/cubit/exchange_rate_list_cubit.dart` and `primary_currency_cubit.dart`
    - `lib/features/currency/presentation/pages/exchange_rate_list_page.dart`, `currency_settings_page.dart` and `exchange_rate_form_page.dart`
    - `test/features/currency/presentation/cubit/exchange_rate_list_cubit_test.dart` and `primary_currency_cubit_test.dart`
  - Done when: both Cubits subscribe to their watch streams, and the post-navigation `load()` calls are removed.
  - Validate: `bloc_test`, plus `integration_test/currency_flows_test.dart`.

- [X] T041 [US1] Register the new watch use cases for DI and regenerate lib/core/di/injection.config.dart
  - Deps: T029–T040
  - Done when: all 11 `Watch*` use cases are `@injectable` and the Cubit constructors resolve.
  - Validate: `dart run build_runner build`, `flutter analyze`, then `flutter test`.

- [X] T042 [US1] Test that the outbox survives a restart, in test/core/sync/local/outbox_persistence_test.dart (new)
  - Deps: T025–T028
  - Done when:
    - Against a file-backed temporary database, the test makes mutations, closes the database, reopens it, and finds identical outbox rows with `status = 'pending'`.
    - Rows left `in_flight` stay `in_flight` until T056's `resetInFlight`.
  - Validate: the test passes.

- [ ] T043 [US1] Run the offline regression over all 11 existing integration flows
  - Deps: T041, T042
  - Files: none (verification only). The flows are in `integration_test/`: `money_relationships_flows_test.dart`, `finance_flows_test.dart`, `currency_flows_test.dart`, `archive_state_refresh_flow_test.dart` and the other 7.
  - Done when: every flow passes on a device in airplane mode, and the results match the T001 baseline.
  - Validate: `flutter test integration_test/`.

**Checkpoint**: US1 is shippable on its own. The app behaves exactly as before, screens are reactive, and every change is durably queued, although nothing uploads yet.

---

## Phase 4: User Story 2 - Offline changes reach the cloud automatically (Priority: P1)

**Goal**: The backend schema with row-level security, the push RPC, an anonymous session, the remote layer, the push half of the engine, connectivity triggers and the single-flight scheduler. Maps to plan P4–P7.

**Independent Test**: Make N mixed offline mutations, then go online. Within 10 s the cloud holds exactly N effects. Repeating with the connection cut, or the app killed mid-upload, also yields exactly N. Quickstart #3, #4 and #7.

### Backend for User Story 2

- [X] T044 [US2] Write the backend foundation in supabase/migrations/<timestamp>_021_offline_sync.sql (new), part 1
  - Deps: T006
  - Done when, as specified in contracts/supabase-schema.md §0, §1 and §6:
    - The `anon` role is revoked from all tables.
    - `sync_owner_state` exists with row-level security and an owner policy.
    - `next_revision()` and `sync_stamp()` exist, both `security invoker` with `set search_path = ''`.
    - `sync_operations` has its `result` check (`'applied','already_applied','conflict','superseded','rejected'`).
    - `devices` has its `platform` check (`'android','ios'`).
  - Validate: `supabase db reset` applies cleanly.

- [X] T045 [US2] Add the 8 business tables to the same migration file
  - Deps: T044
  - Done when, following contracts/supabase-schema.md §2, §3 and §5 verbatim:
    - Every table has the common column block with `primary key (owner_id, id)`, `char_length(id) between 1 and 64`, the `(owner_id, revision)` index, the `sync_stamp` trigger, row-level security enabled, and select, insert and update policies using `(select auth.uid())`. There is **no delete policy**.
    - `people`: `char_length(name) between 1 and 200`; `phone_number <= 40`; `relationship_tag <= 60`; `notes <= 2000`.
    - `money_transactions`: `amount_minor > 0`; `currency_code ~ '^[A-Z]{3}$'`; `direction in ('given','received')`; `kind in ('initialExchange','repayment')`; `tz_offset_minutes between -840 and 840`; `unique (owner_id, idempotency_key)`; a foreign key to `people`.
    - `transaction_audit_entries`: insert and select policies only, and a foreign key to `money_transactions`.
    - `finance_categories`: `type in ('income','expense')` and `name` 1–100 characters.
    - `finance_entries`: the same money checks as transactions, a unique idempotency key, and a foreign key to categories.
    - `exchange_rates`: `rate_micros > 0` and `check (id = 'rate_' || currency_code || '_' || relative_to_currency_code)`.
    - `primary_currency`: `check (id = 'singleton')`.
    - `conflict_resolutions`: `entity_type in ('money_transaction','finance_entry')`, `chosen_side in ('local','server')`, and insert and select policies only.
    - Every foreign-key column has an index.
  - Validate: `supabase db reset`, then the Supabase security advisor (`supabase db lint`) shows no errors.

- [X] T046 [US2] Add the rule-guard triggers to the same migration file
  - Deps: T045
  - Done when:
    - `people_guard_delete` raises `P0001 'person_has_transactions'` when `deleted_at` goes from null to set while any transaction exists, including soft-deleted ones.
    - `finance_entry_type_matches_category` raises `23514 'category_type_mismatch'`.
  - Validate: covered by T049.

- [X] T047 [US2] Add the `sync_push(p_device_id uuid, p_app_version text, p_platform text, p_ops jsonb) returns jsonb` function to the same migration file
  - Deps: T046
  - Done when:
    - It implements contracts/sync-rpc.md §2 in full: the ledger lookup; `for update`; branches 3a–3e including the conflict, superseded, category-archive and undelete paths; a per-operation exception sub-block mapping `23514`/`23502`/`22P02`/`P0001` to `rejected(reason)` and `23503` to `rejected('missing_parent')`; `server_row` returned for `person_has_transactions` and for a category archived in place of a delete; a re-raise on `42501`; the ledger insert; and the `devices` upsert.
    - It rejects more than 100 operations.
    - It is `security invoker`, with `grant execute` to `authenticated` only.
  - Validate: covered by T049.

- [X] T048 [P] [US2] Write the row-level security isolation tests in supabase/tests/021_rls.test.sql (new)
  - Deps: T045
  - Done when all 7 guarantees in contracts/supabase-schema.md §8 are asserted for 2 users, across every table (the views are added in T082).
  - Validate: `supabase test db`.

- [X] T049 [P] [US2] Write the `sync_push` outcome tests in supabase/tests/021_sync_push.test.sql (new)
  - Deps: T047
  - Done when these cases are asserted:
    - Insert returns `applied`. The same `op_id` returns `already_applied` with 1 row. A new `op_id` with the same `idempotency_key` returns `already_applied`.
    - Stale-base financial update returns `conflict` with no write. Stale-base update on a last-write-wins type returns `applied`. Stale-base delete returns `superseded`.
    - A person delete with transactions returns `rejected person_has_transactions`.
    - A category delete with entries archives the category.
    - A type mismatch returns `rejected`.
    - A transaction whose person does not exist returns `rejected missing_parent`, and that is not recorded as final in the ledger (the retry must be able to apply).
    - A batch of 3 where the middle operation is invalid applies the other 2.
    - 101 operations are rejected.
    - Revisions increase monotonically per owner.
  - Validate: `supabase test db`.

- [ ] T050 [US2] Deploy the backend to the remote project and configure its auth (manual)
  - Deps: T048, T049
  - Files: none in the repository.
  - Done when:
    - `supabase link --project-ref nnrmghwqihqnmtnuxzoq` and `supabase db push` have run. The database password is typed at the prompt and never saved.
    - In the dashboard: *Anonymous sign-ins* is enabled, the anonymous sign-in rate limit is kept at 30 per hour per IP or lower, and the email one-time-code template uses `{{ .Token }}`. CAPTCHA is deliberately not enabled: it would need a client widget package, which is out of scope. A pg_cron cleanup of orphaned anonymous users is left for a later feature.
    - `config/supabase.dev.json` has been created locally (git-ignored) with the publishable key only.
  - Validate: the dashboard shows the tables with row-level security enabled, and `rpc('sync_push')` with a publishable-key anonymous session answers.

### Remote layer for User Story 2

- [X] T051 [P] [US2] Create the Supabase initializer and the secure session storage
  - Deps: T002, T004
  - Files: `lib/core/sync/remote/secure_local_storage.dart` (new), `lib/core/sync/remote/supabase_initializer.dart` (new), `test/core/sync/remote/secure_local_storage_test.dart` (new)
  - Done when:
    - `SecureLocalStorage implements LocalStorage` and is backed by `FlutterSecureStorage`.
    - `ensureInitialized()` is idempotent, does nothing when `!CloudConfig.isConfigured`, passes `FlutterAuthClientOptions(localStorage: SecureLocalStorage(), autoRefreshToken: true)`, and never subscribes to Realtime.
  - Validate: a unit test with a mocked `FlutterSecureStorage`.

- [X] T052 [P] [US2] Create the sync error mapper in lib/core/sync/remote/sync_error_mapper.dart (new), with a test in test/core/sync/remote/sync_error_mapper_test.dart (new)
  - Deps: T007
  - Done when it maps every row of research Decision 20 to a failure together with a `transient` or `permanent` classification:
    - Socket, client and handshake errors → `NetworkFailure`
    - `TimeoutException` → `TimeoutFailure`
    - 5xx, 429 or 503, and `PGRST` connection errors → `ServerFailure`
    - `AuthException` or `PGRST301` → `UnauthorizedFailure`
    - `42501` → `ForbiddenFailure`
    - `23514`, `23502`, `22P02` → `SyncRejectedFailure`
    - a `rejected missing_parent` result (from `23503`) → transient
  - Validate: one test per row.

- [X] T053 [US2] Create the anonymous-session part of the auth data source in lib/core/sync/remote/cloud_auth_data_source.dart (new)
  - Deps: T051
  - Done when: `currentUserId`, `isAnonymous` and `ensureSession()` (which calls `signInAnonymously()` when there is no session) exist. The email methods are declared but left for T078.
  - Validate: a unit test with a mocked `GoTrueClient`.

- [X] T054 [US2] Create the push call in lib/core/sync/remote/sync_remote_data_source.dart (new)
  - Deps: T052, T053
  - Done when:
    - `push(ops, device)` calls `rpc('sync_push', params: …)` with a 20 s `.timeout`.
    - It parses the per-operation results (contracts/sync-rpc.md §2) into `PushResult`.
    - It turns exceptions into `SyncRemoteException(failure, transient)` using T052.
    - `pull` is declared for T067.
  - Validate: a unit test with a mocked `SupabaseClient.rpc` covering the parsing of all 5 result kinds and the error paths.

- [X] T055 [P] [US2] Create a fake remote for tests in test/core/sync/fakes/fake_sync_remote.dart (new)
  - Deps: T054 (the interface)
  - Done when:
    - It is an in-memory `SyncRemoteDataSource` that reproduces contracts/sync-rpc.md §2 and §3: the ledger, revisions, the conflict, superseded and rejected branches, and pull pages.
    - Tests can script failures: `failNextCalls(n, failure)`, `dropResponseAfterCommit()`, and `seedServerRow(...)`.
  - Validate: it has its own small test file, `test/core/sync/fakes/fake_sync_remote_test.dart` (new).

### Engine and scheduler for User Story 2

- [X] T056 [US2] Create the local sync store in lib/core/sync/local/sync_local_store.dart (new), with a test in test/core/sync/local/sync_local_store_test.dart (new)
  - Deps: T015
  - Done when:
    - `nextBatch(limit, now)` returns operations ordered by rank, then `created_at`, with `status = 'pending'` and `next_attempt_at <= now`. It skips operations whose parent entity (a transaction's person, an entry's category, an audit's transaction) has an operation in `failed` or `blocked_conflict`.
    - `markInFlight` and `resetInFlight` exist.
    - `applyPushResults` runs in one transaction. `applied` and `already_applied` delete the outbox rows and set meta to `synced` with the revision. `rejected` sets meta to `failed` with the reason, except `missing_parent`, which is rescheduled as transient.
    - Until T071 lands, `conflict` and `superseded` results are stored as `failed` with `error_code = 'unhandled_conflict'` and are **never dropped**, so no version is lost even if US2 ships before US5.
    - `rescheduleBatch`, `readState` and `writeState` (with the `deviceId` generated on first read) exist.
    - `watchCounts()` returns the pending, failed and conflict counts from `sync_record_meta`.
  - Validate: ordering, parent blocking, a restart after `in_flight`, and the counts.

- [X] T057 [P] [US2] Create the backoff policy in lib/core/sync/backoff_policy.dart (new), with a test in test/core/sync/backoff_policy_test.dart (new)
  - Deps: none
  - Done when: `delayFor(n) = min(5 s · 2^n, 15 min) ± 20 %` jitter, with an injectable `Random`.
  - Validate: the bounds hold for n from 0 to 12, and the cap holds.

- [X] T058 [US2] Create the push phase of the engine in lib/core/sync/sync_engine.dart (new), with a test in test/core/sync/sync_engine_push_test.dart (new)
  - Deps: T054, T055, T056, T057, T009
  - Done when `runCycle()` does the following:
    - It returns `disabled` or `offline` early.
    - It calls `ensureSession()`.
    - It loops `nextBatch(100)` → `markInFlight` → `push` → `applyPushResults` until the batch is empty.
    - A failure of the whole call puts the batch back to `pending` with the backoff delay and increments `consecutive_failures`.
    - Auth failures and `42501` pause the cycle with status `authRequired`.
    - It logs `SYNC_STARTED`, `SYNC_UPLOAD_*`, `SYNC_RETRY` and `SYNC_COMPLETED`/`SYNC_ABORTED` with the allowed fields only.
  - Validate, using `FakeSyncRemote`:
    - Create, update and delete sync.
    - Partial failure: A applied, B rejected and marked failed, C still pending.
    - A dropped response after commit is replayed and results in 1 server row.
    - The same operation executed 3 times results in 1 server row.
    - A dependent transaction stays unsent while its person operation is failed.
    - Network failure triggers backoff.

- [X] T059 [P] [US2] Create the connectivity monitor in lib/core/sync/connectivity_monitor.dart (new)
  - Deps: T022
  - Done when: `hasNetwork` maps `connectivity_plus` results (`[none]` → false, anything else → true) and applies `distinct()`. It is documented as a hint only.
  - Validate: a unit test with a mocked `Connectivity`.

- [X] T060 [US2] Create the scheduler in lib/core/sync/sync_scheduler.dart (new) and lib/core/sync/sync_trigger.dart (new), with a test in test/core/sync/sync_scheduler_test.dart (new)
  - Deps: T058, T059
  - Done when:
    - `start()` calls `resetInFlight`, then sets up the triggers: launch; `AppLifecycleListener` resumed; connectivity becoming available; a `changesOf({syncOutbox})` debounce of 3 s; a 5 min `Timer.periodic` while resumed; and `request(manual)`.
    - Single-flight: a `_running` future plus a `_rerunRequested` flag, so exactly one follow-up runs.
    - It respects `next_attempt_at`.
    - `status` is a stream of `SyncRuntimeStatus` values.
    - It returns `disabled` when `!CloudConfig.isConfigured` or `sync_state.enabled == false`, and makes no requests in that case. It does not initialize Supabase while disabled, and it calls `auth.stopAutoRefresh()` / `startAutoRefresh()` when the switch changes (plan §4).
  - Validate, using fake connectivity, a fake clock and `FakeSyncRemote`:
    - offline → online gives 1 cycle.
    - online → offline mid-cycle leaves operations back in `pending`.
    - 10 on/off flaps give 1 cycle.
    - A network that is present while the remote throws is treated as transient backoff.
    - 5 rapid `request()` calls give at most 2 cycles.

- [X] T061 [US2] Wire the scheduler and SupabaseClient into startup
  - Deps: T060, T051
  - Files: `lib/main.dart`, `lib/core/di/register_module.dart`, `lib/core/di/injection.config.dart`
  - Done when:
    - `SupabaseClient` is registered as `@lazySingleton` and resolved only after `SupabaseInitializer.ensureInitialized()`.
    - `SyncEngine` and `SyncScheduler` are `@lazySingleton`.
    - `main.dart` calls `unawaited(getIt<SyncScheduler>().start())` inside the existing `startup.whenReady.then` block, next to `NotificationRecomputeTrigger`.
    - Nothing runs before `runApp`, so the 019 splash timing is unchanged.
  - Validate: `integration_test/splash_startup_flow_test.dart` passes, and an app run without defines shows no network activity.

- [ ] T062 [US2] Write the device integration test for offline upload in integration_test/offline_sync_flow_test.dart (new)
  - Deps: T061, T050 (or a local `supabase start`)
  - Done when these scenarios pass against the local Supabase stack, with connectivity toggled through an injected fake `ConnectivityMonitor`:
    - Offline create: a person and a transaction → app restart → data present → online → sync → the cloud has exactly 1 person and 1 transaction.
    - Offline update: edit a transaction and a person → sync → the cloud shows the new values and the audit row.
    - Offline delete and archive: soft-delete a transaction, archive a person → sync → the cloud shows `deleted_at` and `is_archived`.
    - Failed sync: the remote is forced down → operations stay pending → the backend is restored → retry → synced.
    - Duplicate prevention: the upload is interrupted and repeated → a query grouping by `idempotency_key` with `count > 1` returns 0 rows.
  - Validate: `flutter test integration_test/offline_sync_flow_test.dart --dart-define-from-file=config/supabase.local.json`.

**Checkpoint**: US1 and US2 together form the backup MVP. Local changes reliably reach the cloud with no duplicates.

---

## Phase 5: User Story 3 - Existing data is backed up on upgrade (Priority: P1)

**Goal**: Rows that existed before the upgrade are queued once and uploaded once, safely and resumably. Maps to plan §16.

**Independent Test**: A v8 database with data → upgrade → bootstrap → upload. Running it twice, or interrupting it at 40 %, still gives cloud counts equal to local counts, and balances are identical.

- [X] T063 [US3] Create the bootstrap step in lib/core/sync/sync_bootstrap.dart (new) and call it from beforeOpen in lib/core/database/app_database.dart
  - Deps: T015–T020, T011
  - Done when:
    - `enqueueExistingDataIfNeeded(db)` returns immediately when `sync_state.bootstrap_enqueued` is true. It must never infer this from an empty outbox (data-model.md §3).
    - Otherwise, in **one** Drift transaction, it streams every synced type in chunks of 500 and in rank order, inserting outbox upserts with `base_revision = null` and meta `pending`.
    - It skips pristine seed categories (T019 `isPristineSeed`), sets `bootstrap_enqueued = true` in the same transaction, and logs `SYNC_MIGRATION_ENQUEUED` with the count per type.
    - It is called in `beforeOpen` after `seedDefaultFinanceCategories`. It does not call `SyncOutbox`, which would recurse into the DAOs.
  - Validate: T064.

- [X] T064 [US3] Test the bootstrap in test/core/sync/sync_bootstrap_test.dart (new), and extend test/core/database/sync_v9_migration_test.dart
  - Deps: T063, T012
  - Done when:
    - A v8 fixture with N synced rows (including 3 pristine seeds and 1 renamed seed) gives N−3 outbox rows.
    - Opening a second time does not add rows.
    - The outbox fully drained with `initial_upload_done` still false, followed by a reopen, re-enqueues nothing (guards against a second bootstrap).
    - A crash simulated mid-transaction leaves 0 rows, and they appear in full on the next open.
    - `getOverview()` and `getPersonBalances()` are identical before and after.
    - A fresh install gives 0 rows.
  - Validate: `flutter test test/core/sync/sync_bootstrap_test.dart test/core/database/`.

- [X] T065 [US3] Mark the initial upload complete and test an interrupted upload
  - Deps: T058, T063
  - Files: `lib/core/sync/sync_engine.dart`, `test/core/sync/sync_engine_initial_upload_test.dart` (new)
  - Done when: after a cycle drains the outbox, the engine sets `sync_state.initial_upload_done = true` and logs the count per entity type.
  - Validate, using `FakeSyncRemote`, a bootstrap of 5,000 transactions, and a failure at batch 20:
    - The next cycle resumes.
    - The final server row count equals the local count.
    - 0 duplicates.
    - `initial_upload_done` is true only at the end.

**Checkpoint**: upgrading users are fully backed up.

---

## Phase 6: User Story 4 - Remote changes appear without reloading (Priority: P2)

**Goal**: The pull RPC, the applier, cursor advancement, and re-owning local data on an identity change. Maps to plan P4 (pull) and P6.

**Independent Test**: A cloud row inserted for the owner appears on the open Person Detail page after one sync. A cloud archive moves the person to the archived list. Quickstart #5.

- [ ] T066 [US4] Add `sync_pull(p_since bigint, p_limit int default 500) returns jsonb` in a NEW migration file supabase/migrations/<timestamp>_021b_sync_pull.sql (new), then test it in supabase/tests/021_sync_pull.test.sql (new) and deploy it
  - Deps: T047, T050. It must not edit the already-deployed `_021_offline_sync.sql`.
  - Done when:
    - It is the `UNION ALL` of the 8 tables where `revision > p_since`, ordered by revision, `limit` capped at 1000, returning `changes`, `max_revision` and `has_more`, with tombstones included (contracts/sync-rpc.md §3).
    - It is `security invoker`.
  - Also: grant execute to `authenticated` and revoke it from `anon` and `public` inside this file. After the tests pass, run `supabase db push`.
  - Validate with pgTAP:
    - The order follows revision.
    - A person arrives before its transaction.
    - Tombstones are present.
    - User B sees none of A's rows.
    - Two concurrent pushes, one pull afterwards: nothing is skipped.

- [X] T067 [US4] Implement pull in lib/core/sync/remote/sync_remote_data_source.dart
  - Deps: T054, T066
  - Done when: `pull({since, limit})` returns a `PullPage`, with a 20 s timeout and the error mapping from T052.
  - Validate: a unit test on the parsing.

- [X] T068 [US4] Create the applier in lib/core/sync/local/sync_applier.dart (new), with a test in test/core/sync/local/sync_applier_test.dart (new)
  - Deps: T056, T023
  - Done when:
    - It implements every row of contracts/sync-rpc.md §4 in one transaction per page: insert; overwrite when there is no open operation; skip when there is one; tombstones hard-delete people, categories and rates but soft-delete transactions and entries; pristine seeds are overwritten.
    - It sets meta to `synced` with the revision, and advances `last_pulled_revision` to `max_revision` at the end of that transaction.
    - It never calls `SyncOutbox`.
  - Validate:
    - Each row of the table.
    - A person's `avatarPath` is kept.
    - A failure mid-page leaves the cursor unchanged.
    - A watch stream (T029) emits after `applyPage`.

- [X] T069 [US4] Add the pull phase and re-owning to lib/core/sync/sync_engine.dart, with a test in test/core/sync/sync_engine_pull_test.dart (new)
  - Deps: T067, T068, T065 (T065 also edits `sync_engine.dart`)
  - Done when:
    - After the push phase, the engine loops `pull(since: cursor)` → `applyPage` until `!has_more`, logging `SYNC_DOWNLOAD_*` and `SYNC_CURSOR_ADVANCED`.
    - If `ensureSession()`'s uid differs from `sync_state.owner_id`, it runs one transaction that re-enqueues every synced row as an upsert with `base_revision = null` (the bootstrap routine with `force: true`), resets the cursor to 0 and stores the new `owner_id`. Local data is never deleted.
  - Validate, using `FakeSyncRemote`:
    - Pulls of 3 pages.
    - A tombstone is applied.
    - The cursor persists across a restart.
    - A uid change re-uploads everything and then pulls from 0, with 0 duplicates.
    - `owner_id` null (fresh DB, e.g. an iOS reinstall with the Keychain session still present) adopts the uid **without** re-enqueueing, then restores the data from cursor 0.

- [X] T070 [US4] Test that remote changes reach an open screen, in test/features/transactions/presentation/person_detail_remote_update_test.dart (new)
  - Deps: T069, T035
  - Done when: a widget test pumps `PersonDetailPage` with the real repository and an in-memory database, runs `SyncEngine.runCycle()` against a `FakeSyncRemote` seeded with a new transaction for that person, and the new row and updated balance render with no navigation.
  - Validate: `flutter test` on that file. Quickstart #5 is the manual device check.

**Checkpoint**: restore and a second device work.

---

## Phase 7: User Story 5 - Conflicts on financial records are never silently resolved (Priority: P2)

**Goal**: Detect, keep and resolve financial conflicts, with a synced resolution history and a badge on the row. Maps to plan P8.

**Independent Test**: Diverge one transaction locally and on the server, then sync. The row shows a badge. "Keep mine" and "Keep theirs" each resolve the conflict and write a `conflict_resolutions` row. Quickstart #6.

- [X] T071 [US5] Handle conflict and superseded results in lib/core/sync/local/sync_local_store.dart and lib/core/sync/local/sync_applier.dart, with a test in test/core/sync/local/sync_local_store_conflict_test.dart (new)
  - Deps: T056, T068
  - Done when:
    - `conflict`: the operation becomes `blocked_conflict`, meta becomes `conflict`, and a `sync_conflicts` row is inserted holding the local payload, the server payload and the server revision. `SYNC_CONFLICT` is logged with the entity type only.
    - `superseded`: the operation is deleted and the `server_row` is applied through `SyncApplier` (the record is restored).
    - `rejected person_has_transactions`: the operation is deleted and the person is re-inserted from `server_row`, which the result must carry.
    - `applied` carrying a `server_row` (a category archived instead of deleted): the row is applied locally.
    - Replaces T056's interim `unhandled_conflict` handling, and migrates any such stored rows into `sync_conflicts`.
    - Extends `SyncApplier` (T068): when a pulled row targets an entity whose operation is `blocked_conflict`, it refreshes `sync_conflicts.server_payload_json` and `server_revision` (contracts/sync-rpc.md §4).
  - Validate: each branch; a blocked transaction stops its audit entries from being sent; after a second remote edit is pulled, keep-theirs applies the **latest** server version.

- [X] T072 [US5] Create the conflict resolver in lib/core/sync/local/conflict_resolver.dart (new), with a test in test/core/sync/local/conflict_resolver_test.dart (new)
  - Deps: T071, T021
  - Done when, in one transaction each:
    - `keepMine(entity)` enqueues an upsert with `base_revision = conflict.server_revision` and the local payload, plus a `conflictResolution` insert with `chosen_side = 'local'` and `discarded_values` set to the server row. The blocked operation is closed and `resolved_at` is set.
    - `keepTheirs(entity)` applies the server row locally, enqueues a `conflictResolution` with `chosen_side = 'server'` and `discarded_values` set to the local payload, and closes the operation.
  - Validate: both paths produce exactly 1 resolution record and never lose a version. After keep-theirs, the audit entries of the discarded edit are still queued unchanged (spec FR-035), and nothing is deleted from `transaction_audit_entries`.

- [X] T073 [US5] Create the cloud_sync domain contract and its conflict part
  - Deps: T072
  - Files:
    - `lib/features/cloud_sync/domain/entities/sync_conflict_item.dart` (new)
    - `lib/features/cloud_sync/domain/entities/sync_status.dart` (new)
    - `lib/features/cloud_sync/domain/entities/sync_runtime_status.dart` (new): the Domain layer's own enum. It never imports `lib/core/sync`.
    - `lib/features/cloud_sync/domain/repositories/cloud_sync_repository.dart` (new): the full contract from contracts/dart-interfaces.md §4
    - `lib/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart` (new): implements `watchConflicts`, `resolveConflict` and `watchHasConflict` now. The other methods return `Left(UnknownFailure('not yet implemented'))` until T076.
    - `lib/features/cloud_sync/domain/usecases/watch_sync_conflicts.dart` (new) and `resolve_sync_conflict.dart` (new)
    - `test/features/cloud_sync/data/cloud_sync_repository_conflict_test.dart` (new)
  - Done when: `SyncConflictItem` summaries show amount, date, direction and note, formatted in the Presentation layer, never in the Domain layer.
  - Validate: the repository test passes.

- [X] T074 [US5] Add the conflict badge and resolution sheet
  - Deps: T073, T035, T037
  - Files:
    - `lib/features/cloud_sync/presentation/widgets/conflict_badge.dart` (new)
    - `lib/features/cloud_sync/presentation/widgets/conflict_resolution_sheet.dart` (new)
    - `lib/features/cloud_sync/presentation/cubit/sync_conflicts_cubit.dart` (new) and `sync_conflicts_state.dart` (new)
    - `lib/features/transactions/presentation/widgets/transaction_list_tile.dart`
    - `lib/features/finance/presentation/widgets/finance_entry_list_tile.dart`
    - `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_ar.arb`
    - `test/features/cloud_sync/presentation/conflict_badge_test.dart` (new)
  - Done when:
    - The badge renders only when `watchHasConflict` is true, and otherwise leaves each tile's layout unchanged.
    - The sheet uses only `lib/core/design_system` components, shows the two versions side by side in RTL and LTR, and offers "Keep mine" and "Keep theirs".
  - Validate: widget tests in `ar` and `en`, and the existing tile tests still pass.

- [X] T075 [US5] Simulate two devices editing the same records, in test/core/sync/sync_engine_conflict_test.dart (new)
  - Deps: T072, T069
  - Done when: two `SyncEngine` instances, backed by 2 in-memory databases and one shared `FakeSyncRemote` with the same owner, cover these cases:
    - Both edit the same transaction: the second gets a conflict, and after resolution both converge.
    - One deletes while the other edits a transaction: a conflict.
    - Both edit the same person: last write wins, and they converge with no conflict.
    - Device A deletes a person while device B edits it: the person is restored.
    - Both create the USD→EGP rate: 1 row.
    - Both keep pristine seeds while one renames "Rent": the rename survives.
  - Validate: no version of a financial record is lost in any case (checked through `conflict_resolutions`).

**Checkpoint**: financial data is never silently overwritten.

---

## Phase 8: User Story 6 - Sync status is visible but unobtrusive (Priority: P3)

**Goal**: The Settings sync page, status, sync now, the on/off switch, retrying failed items, email linking, and the one-time notice. Maps to plan P9.

**Independent Test**: Each of the states up to date, pending, syncing, offline, failed, conflict and auth-required renders correctly in `ar` and `en`, and "Sync now" never starts a second cycle.

- [X] T076 [US6] Finish the remaining CloudSyncRepository methods in lib/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart, with a test in test/features/cloud_sync/data/cloud_sync_repository_impl_test.dart (new)
  - Deps: T073, T060
  - Done when:
    - `watchStatus` combines `SyncScheduler.status` (mapping the core `SchedulerState` to the domain `SyncRuntimeStatus`), `SyncLocalStore.watchCounts` and `sync_state`.
    - `syncNow` calls `request(manual)`.
    - `setEnabled` writes `sync_state.enabled` and then calls `request` or pauses.
    - `markNoticeShown` exists.
    - `retryFailed` sets `failed` back to `pending`, clears `next_attempt_at`, and calls `request`.
    - The email methods delegate to T078.
    - Errors come back as `Either`.
  - Validate: the unit tests pass.

- [X] T077 [P] [US6] Create seven use cases in lib/features/cloud_sync/domain/usecases/ (new)
  - Deps: T073
  - Files: `watch_sync_status.dart`, `sync_now.dart`, `set_sync_enabled.dart`, `acknowledge_sync_notice.dart`, `retry_failed_sync.dart`, `request_email_code.dart`, `confirm_email_code.dart`
  - Done when: each is `@injectable` and delegates to `CloudSyncRepository`.
  - Validate: `flutter analyze`.

- [X] T078 [US6] Add email linking and sign-in to lib/core/sync/remote/cloud_auth_data_source.dart
  - Deps: T053
  - Done when:
    - `requestEmailLinkCode(email)` calls `updateUser(UserAttributes(email:))`, and `confirmEmailLink` calls `verifyOTP(type: OtpType.emailChange)`, keeping the same uid.
    - `requestSignInCode` calls `signInWithOtp(email)`, and `confirmSignIn` calls `verifyOTP(type: OtpType.email)` and returns the new uid, which makes T069 re-own the data on the next cycle.
    - The raw email is never logged.
  - Validate: unit tests with a mocked `GoTrueClient` cover code sent, invalid code, and uid retained or changed.

- [X] T079 [US6] Create three Cubits in lib/features/cloud_sync/presentation/cubit/
  - Deps: T076, T077, T078
  - Files: `sync_settings_cubit.dart` and state, `email_link_cubit.dart` and state, `sync_notice_cubit.dart` and state (all new), with tests in `test/features/cloud_sync/presentation/cubit/` (new)
  - Done when:
    - The state models are immutable and use `copyWith`.
    - `EmailLinkCubit` has the states initial, codeSent, verifying, success and failure, plus a duplicate-submit guard.
    - `SyncSettingsCubit` disables "Sync now" while the status is `syncing`.
  - Validate: `bloc_test` for every transition.

- [X] T080 [US6] Create the sync settings page and link it from Settings
  - Deps: T079
  - Files:
    - `lib/features/cloud_sync/presentation/pages/sync_settings_page.dart` (new)
    - `lib/features/cloud_sync/presentation/widgets/sync_status_line.dart` (new)
    - `lib/core/routing/app_router.dart`: the `/settings/sync` route, next to the existing settings routes
    - `lib/features/settings/presentation/pages/settings_page.dart`: one new `_SettingsSection` with a `ListTile` titled "Cloud backup & sync"
    - `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_ar.arb`
  - Done when the page shows:
    - the status line and the last sync time;
    - the pending, failed and conflict counts;
    - "Sync now" and the enabled switch;
    - "Link email" (while anonymous), or "Sign in to existing account", or the masked email;
    - the list of failed items with Retry;
    - the list of conflicts, which opens T074's sheet.
    - No other Settings section changes.
  - Validate: `test/features/cloud_sync/presentation/sync_settings_page_test.dart` (new) renders each status in `ar` and `en`.

- [X] T081 [US6] Create the one-time sync notice
  - Deps: T079
  - Files: `lib/features/cloud_sync/presentation/widgets/sync_notice_sheet.dart` (new), `lib/main.dart` (or `lib/core/routing/main_shell.dart` for the host), and the ARB files
  - Done when: after startup is ready and only when `CloudConfig.isConfigured && !noticeShown`, a dismissible sheet explains backup and links to `/settings/sync`. Dismissing it calls `AcknowledgeSyncNotice`.
  - Validate: a widget test shows it once, then never again.

**Checkpoint**: every user story is independently functional.

---

## Phase 9: Polish & Cross-Cutting Concerns (plan P10)

- [ ] T082 [P] Add the analytics views in a NEW migration file supabase/migrations/<timestamp>_021c_analytics_views.sql (new), test them in supabase/tests/021_views.test.sql (new), and deploy them
  - Deps: T050, T066 (a later timestamp). It never edits an earlier 021 migration. After the tests pass, run `supabase db push`, and revoke `anon` access inside the file.
  - Done when:
    - `v_monthly_person_flows`, `v_person_balances`, `v_monthly_finance_by_category` and `v_daily_activity` are defined per contracts/supabase-schema.md §7, all `with (security_invoker = true)`.
    - They filter `deleted_at is null` and never convert currencies.
    - `grant select` goes to `authenticated`.
  - Validate with pgTAP:
    - User isolation.
    - Every FR-061 question is answered by a single query: total given, total received, net, outstanding, count, monthly, yearly, average, people count, active relationships.
    - No view is visible to `anon`.

- [X] T083 [P] Review observability and add a log-scrub test in test/core/sync/sync_log_scrub_test.dart (new)
  - Deps: T069, T075
  - Done when: a full engine run against `FakeSyncRemote`, with a spy `SyncLogger`, emits every required event and no field values containing amounts, names, notes, emails or tokens.
  - Validate: the test passes.

- [X] T084 [P] Update the roadmap in specs/ROADMAP-PLAN.md
  - Deps: none
  - Done when: the 2026-09-22 "no backend; V3.5 dropped" decision is marked superseded by 021, with a link to this spec.
  - Validate: review.

- [X] T085 [P] Add a sync performance check in test/performance/sync_upload_perf_test.dart (new)
  - Deps: T065
  - Done when:
    - Bootstrapping 5,000 transactions takes under 5 s in memory.
    - 1,000 operations drain through `FakeSyncRemote` with a simulated 150 ms latency per call in under 60 s (SC-004).
    - Watch re-queries during bulk apply are debounced, meaning at most 1 emission per 50 ms.
  - Validate: the test passes.

- [ ] T086 Run the static and unit quality gate
  - Deps: all implementation tasks
  - Done when:
    - `dart format --output=none --set-exit-if-changed lib test` passes.
    - `flutter analyze` shows 0 new issues compared with T001.
    - `flutter test` is fully green.
    - `supabase test db` is green.
  - Validate: the output is attached to `checklists/baseline.md`.

- [ ] T087 Validate on Android
  - Deps: T086
  - Done when:
    - `flutter build apk --debug` and `flutter build apk --release --dart-define-from-file=config/supabase.prod.json` both succeed.
    - The release manifest contains `INTERNET`.
    - On a device, quickstart scenarios 1–10 pass, including 10, the upgrade from the previous release APK.
  - Validate: results are recorded in `checklists/baseline.md`.

- [ ] T088 Validate on iOS
  - Deps: T086
  - Done when:
    - `flutter build ios --release --no-codesign --dart-define-from-file=config/supabase.prod.json` succeeds.
    - Swift Package Manager resolution is confirmed for `supabase_flutter` (with `app_links`, `url_launcher` and `shared_preferences`), `connectivity_plus` and `flutter_secure_storage`. If a Podfile was generated, the diff is reviewed and justified.
    - No `Info.plist` or entitlement change was made.
    - Quickstart scenarios 1–10 pass on a device or simulator.
  - Validate: results are recorded.

- [ ] T089 Run the security review
  - Deps: T086
  - Done when:
    - `git grep -nE "service_role|sb_secret_|eyJhbGci"` finds nothing.
    - `config/*.json` other than the example file is untracked.
    - The Supabase dashboard *Security Advisor* shows no errors.
    - The row-level security review checklist confirms: every table has row-level security, no table has a delete policy, append-only tables have no update policy, and the functions are `security invoker` with `search_path = ''` and are not executable by `anon`.
    - `/security-review` has been run on the branch.
  - Validate: findings are fixed or documented.

- [ ] T090 Review the dependencies
  - Deps: T086
  - Done when: `flutter pub deps --style=compact` shows only the 3 intended direct additions, and `flutter pub outdated` has no incompatible constraints.
  - Validate: a note in `checklists/baseline.md`.

- [X] T092 [P] Add a guard test that every table is classified as synced or local-only, in test/core/sync/table_classification_guard_test.dart (new)
  - Deps: T011, T016
  - Done when:
    - The test lists `AppDatabase.allTables` and asserts that each one is in exactly one of two lists: synced (it has a `SyncMapper` registered) or `localOnlyTables`, declared in `lib/core/sync/sync_entity_type.dart`. The local-only list is `app_settings`, `onboarding_status`, `notification_preferences`, `notification_history` and the 5 sync tables.
    - A table added by a future feature fails the test until it is classified. This enforces spec FR-006.
  - Validate: the test passes now, and fails when a dummy table is added.

- [ ] T091 Sign off the Definition of Done in specs/021-supabase-offline-sync/checklists/definition-of-done.md (new)
  - Deps: T082–T090, T092
  - Done when: each row of plan.md §26 is checked, with a link to the evidence (the test name or quickstart scenario).
  - Validate: all rows are checked.

---

## Dependencies & Execution Order

### Phase dependencies

```text
Phase 1 Setup (T001–T006)
   └─► Phase 2 Foundational (T007–T023)  ── BLOCKS all stories
          ├─► US1 (T024–T043)  P1  MVP
          │     └─► US2 (T044–T062) P1   [backend T044–T050 can start right after T006, in parallel with Phase 2 and US1]
          │            ├─► US3 (T063–T065) P1
          │            └─► US4 (T066–T070) P2
          │                   └─► US5 (T071–T075) P2
          │                          └─► US6 (T076–T081) P3
          └──────────────────────────────────► Polish (T082–T091)
```

### Task dependency graph (condensed)

```text
T001 ─► T002 ─► T022 ─► T059
T006 ─► T044 ─► T045 ─► T046 ─► T047 ─┬─► T049 ─┐
                  │                    ├─► T066   ├─► T050
                  ├─► T048 ────────────┘          │
                  (T050 ─► T066 ─► T082: new migration files only)│
T010 ─► T011 ─┬─► T012 ─► T064
              ├─► T013 ─► {T029,T030,T031,T032} ─► {T033…T040} ─► T041 ─► T043
              └─► T015 ◄─ T014 ◄─ T008
                   ├─► {T025,T026,T027,T028} ◄─ {T017,T018,T019,T020} ◄─ T016
                   │         └─► T024(guard), T042
                   └─► T056 ─┬─► T058 ◄─ {T054 ◄─ T052,T053 ◄─ T051} , T055, T057
                             │     └─► T060 ─► T061 ─► T062
                             ├─► T068 ─► T069 ◄─ T067 ◄─ T066
                             └─► T071 ─► T072 ─► T073 ─► T074 ; T075
T063 ─► T064, T065 ;  T073 ─► T076/T077 ─► T079 ─► T080, T081 ;  T053 ─► T078
```

### Parallel execution groups

| Group | Tasks | Why they are safe to run together |
|---|---|---|
| G1 Setup | T003, T004, T005, T006 | Separate files |
| G2 Foundation primitives | T007, T008, T009, T010 | Separate files |
| G3 Mappers | T017, T018, T019, T020, T021 | One feature folder each |
| G4 DAO wiring | T025, T026, T027, T028 (plus T024, written alongside) | One DAO each |
| G5 Watch repositories | T029, T030, T031 (T032 runs after T028, same file) | One feature each |
| G6 Cubit migrations | T033/T034 (people), T035/T036 (transactions), T037–T039 (finance), T040 (currency) | Different features. Run sequentially within a feature. |
| G7 Backend | T044→T047 run as a chain on one file, **in parallel with** Phase 2 and US1. T048 and T049 run in parallel. | Different stack |
| G8 Remote layer | T051, T052, T055, T057, T059 | Separate files |
| G9 Polish | T082, T083, T084, T085, T092 | Separate files. T082 uses its own new migration file. |

### Critical path

T001 → T002 → T010 → T011 → T014/T015 → T025–T028 → T056 → T058 → T060 → T061 → T062 → T063 → T065 → T068 → T069 → T071 → T072 → T073 → T076 → T079 → T080 → T086 → T087 / T088 → T091

The backend chain T006 → T044–T050 must finish before T062, and runs off the critical path when it is started early.

## Parallel Example: User Story 1

```bash
# Start together once Phase 2 is done:
Task: "T025 Record outbox entries in lib/features/people/data/datasources/people_dao.dart"
Task: "T026 Record outbox entries in lib/features/transactions/data/datasources/transactions_dao.dart"
Task: "T027 Record outbox entries in lib/features/finance/data/datasources/finance_dao.dart"
Task: "T028 Record outbox entries in lib/features/currency/data/datasources/currency_dao.dart"
Task: "T029 Watch methods for the people repository"   # the repository file differs from the DAO file
Task: "T030 Watch methods for the transactions repository"
```

## Task groups by concern

| Group | Tasks |
|---|---|
| **Database (local)** | T010, T011, T012, T013, T063, T064 |
| **Supabase (backend)** | T006, T044, T045, T046, T047, T048, T049, T050, T066, T082 |
| **Offline and sync** | T014, T015, T024–T028, T042, T051–T061, T067–T069, T071–T072 |
| **Migration of existing data** | T011, T012, T063, T064, T065, T069 (re-own) |
| **Reactive UI** | T029–T041, T070, T074 |
| **Auth and security** | T003, T004, T051, T053, T078, T048, T089 |
| **Error handling** | T007, T052, T058 (classification), T071 (rejections), T080 (display) |
| **Observability** | T009, T058, T069, T083 |
| **Testing** | Every task with a test file, plus T043, T062, T070, T075, T085 |
| **Android and iOS validation** | T005, T087, T088 |

## Implementation Strategy

1. **MVP (US1)**: Phase 1 → Phase 2 → US1. This ships a behavior-identical app with reactive screens (it fixes the 004/005 class of bugs) and a durable queue, with no network needed.
2. **Backup MVP (+US2 +US3)**: build the backend in parallel from T006. Then add the remote layer, engine and scheduler, then the bootstrap. Existing and new data now reaches the cloud.
3. **Restore and multi-device (+US4 +US5)**: pull, apply and re-own, then conflicts.
4. **Visibility (+US6)**: the Settings page, email linking and the notice.
5. **Polish**: views, performance, security and platform validation, then the Definition of Done.

Stop at any checkpoint to validate that story on its own.

## Final Definition of Done

Every row of plan.md §26 is satisfied, recorded by T091:

- The app works offline (T043).
- Data persists locally (T042, T064).
- Offline changes are queued (T024).
- Reconnecting triggers sync (T060).
- Supabase receives the changes (T062).
- Remote changes reach the local database (T069).
- The UI updates automatically (T033–T041, T070).
- There are no duplicate financial records (T049, T058, T062).
- Conflicts are handled safely (T075).
- Existing data is preserved (T012, T064).
- Row-level security protects user data (T048, T082, T089).
- Android works (T087).
- iOS works (T088).
- All tests pass (T086).
