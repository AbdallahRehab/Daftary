# Implementation Plan: Offline-First Cloud Sync (Supabase)

**Branch**: `021-supabase-offline-sync` | **Date**: 2026-09-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/021-supabase-offline-sync/spec.md`

**Companion artifacts**:

- [research.md](research.md), which holds Decisions 1–23;
- [data-model.md](data-model.md);
- [contracts/supabase-schema.md](contracts/supabase-schema.md);
- [contracts/sync-rpc.md](contracts/sync-rpc.md);
- [contracts/dart-interfaces.md](contracts/dart-interfaces.md);
- [quickstart.md](quickstart.md).

> **Assumed decisions.** The spec's Q1–Q3 were not answered before planning. This plan uses the recommended answers:
>
> - anonymous sign-in plus optional email one-time-code linking;
> - sync on by default, with a one-time notice and an off switch;
> - phone and notes are synced, the avatar path is not.
>
> research.md Decision 11 lists exactly which parts change if any of these is overridden. The sync engine and the schema do not change in any case.

## Summary

Daftary already runs offline-first on a local Drift/SQLite database: schema v8, 11 tables, Future-based repositories. It has no network or auth layer. This plan keeps that database as the single source that screens read from and adds a sync layer to the Data side. The layer has five parts:

1. **A transactional outbox.** DAOs write each business row and its outbox entry in one Drift transaction.
2. **A single-flight `SyncEngine`.** Each cycle pushes batches through an idempotent `sync_push` RPC, then pulls incremental pages through `sync_pull`, using a gap-free per-owner revision cursor.
3. **Explicit conflict rules.** Financial records get manual resolution and a synced resolution history. Everything else uses last-write-wins in server order.
4. **Owner-scoped Supabase tables.** Every table has row-level security, append-only rules and analytics views.
5. **Reactive local reads.** They replace the imperative reload-after-mutation used by eight Cubits, which also resolves the 004/005 class of stale-UI bugs.

The only new UI is a Settings sync section, a conflict sheet and badge, and a one-time notice.

## Technical Context

- **Language/Version**: Dart ^3.10.0, Flutter 3.47.0 (stable, 2026-08-11)
- **Primary Dependencies**:
  - Existing: `flutter_bloc` 9, `drift` 2.22, `get_it` / `injectable`, `fpdart`, `uuid`, `go_router`.
  - **New**: `supabase_flutter ^2.17.2`, `connectivity_plus ^7.3.1`, `flutter_secure_storage ^11.2.0`.
- **Storage**: Local Drift/SQLite `daftary.sqlite` (v8 → v9). Remote Supabase Postgres (project `nnrmghwqihqnmtnuxzoq`).
- **Testing**: `flutter_test`, `bloc_test`, `mocktail`, in-memory Drift, `integration_test`, and Supabase CLI with pgTAP (dev-only, not installed yet).
- **Target Platform**: Android (`flutter.minSdkVersion`) and iOS 15.0+ (SPM, no Podfile).
- **Project Type**: Mobile app plus a Supabase backend (schema, functions and policies only; no custom server).
- **Performance Goals**:
  - Local writes and reads are no slower than v8.
  - 1,000 pending operations upload in under 60 s on 4G.
  - Remote changes appear within 10 s of a sync.
  - Watch re-queries are debounced to 50 ms.
- **Constraints**:
  - Fully functional offline.
  - No secrets in the repository.
  - No service-role key.
  - No UI change to existing screens (only additions).
  - Foreground sync only.
- **Scale/Scope**:
  - Per user: about 10k transactions and entries, a few hundred people, 1–3 devices.
  - 8 synced entity types, 8 Cubits moving to watch-based reads, 1 new feature module (`cloud_sync`).

## Constitution Check

*GATE: checked before Phase 0 and re-checked after Phase 1. Both passed.*

| Principle | How the design complies |
| --- | --- |
| I. Clean layering | Supabase types exist only in `lib/core/sync/remote/` and `cloud_sync/data`. The Domain layer sees `CloudSyncRepository` and `watch*` streams of domain entities. Screens never import Supabase. |
| II. Feature-first | The engine lives in `lib/core/sync` because four features share it (the rule for `core/` is two or more). Mappers stay inside each feature's `data/sync/`. The UI goes in a new `features/cloud_sync`. |
| III / IV. BLoC, immutable state | New Cubits with explicit states. Watch subscriptions are cancelled in `close()`. `distinct()` together with Equatable prevents redundant emissions. |
| V. Use cases | The `Watch*` use cases and the sync use cases are the Domain-layer seam. `ResolveSyncConflict` holds real logic. |
| VI. Repository | Repositories still own coordination. The outbox is written in the Data layer (DAO). |
| VII. Typed failures | New `NetworkFailure`, `TimeoutFailure`, `ServerFailure`, `UnauthorizedFailure`, `ForbiddenFailure`, `SyncRejectedFailure` and `SyncConflictFailure`. No empty catch blocks. Sync errors never block a screen. |
| VIII. Deterministic money | Money stays as integers end to end (strings on the wire). Balances are still computed locally by the existing code. |
| XI. Offline and idempotent sync | Covered directly: outbox, operation ledger, idempotency keys, conflict policy, backoff. |
| XII. Secrets | `--dart-define-from-file` with git-ignored config; only the publishable key; sessions in the Keychain or Keystore via `flutter_secure_storage`; logs restricted to an allow-list. |
| XIII. Localization | Every new string goes in both ARB files. The conflict sheet is laid out for RTL. |
| XIV. DI | All new services go through `injectable`. The engine, scheduler, outbox and Supabase client are `@lazySingleton`. |
| XV. Design system | Only `lib/core/design_system` components are used. |
| XVI. Testability | A fake remote, an injected `AppClock` and an injected connectivity stream. The engine takes no `DateTime.now()` directly. |
| Dependency rule ("no unjustified new dependencies") | 3 packages, each justified in research Decision 21. Explicitly not added: rxdart, workmanager, dotenv, a logger, a connectivity checker. |

The one item that needs justification is the new `lib/core/sync` subsystem. It is listed under Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/021-supabase-offline-sync/
├── spec.md  plan.md  research.md  data-model.md  quickstart.md
├── contracts/{supabase-schema.md, sync-rpc.md, dart-interfaces.md}
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks (not created here)
```

### Source Code (actual repository layout, extended)

```text
config/
├── supabase.example.json                 # NEW (committed, placeholders)
└── supabase.<env>.json                   # git-ignored
supabase/                                 # NEW (Supabase CLI project)
├── config.toml
├── migrations/<ts>_021_offline_sync.sql
└── tests/{021_rls.test.sql, 021_sync_push.test.sql, 021_sync_pull.test.sql}
lib/
├── core/
│   ├── config/cloud_config.dart                          # NEW
│   ├── database/
│   │   ├── app_database.dart                             # MOD: v9 tables, migration, beforeOpen bootstrap
│   │   ├── sync_tables.dart                              # NEW: Drift table classes for sync_*
│   │   ├── migrations/v9_sync_support.dart               # NEW
│   │   └── watch_tables.dart                             # NEW
│   ├── di/register_module.dart                           # MOD: SupabaseClient, Connectivity, FlutterSecureStorage
│   ├── error/failure.dart                                # MOD: new failure subclasses
│   ├── l10n/{app_en.arb, app_ar.arb, failure_message.dart} # MOD
│   └── sync/                                             # NEW subsystem
│       ├── sync_entity_type.dart   sync_logger.dart   sync_trigger.dart
│       ├── sync_engine.dart        sync_scheduler.dart   backoff_policy.dart
│       ├── connectivity_monitor.dart   sync_bootstrap.dart   sync_mapper_registry.dart
│       ├── local/{sync_outbox.dart, sync_local_store.dart, sync_applier.dart, outbox_coalescer.dart}
│       └── remote/{supabase_initializer.dart, secure_local_storage.dart,
│                   sync_remote_data_source.dart, cloud_auth_data_source.dart, sync_error_mapper.dart}
└── features/
    ├── people/        data/datasources/people_dao.dart (MOD)  data/sync/person_sync_mapper.dart (NEW)
    │                  domain/repositories + usecases/watch_*.dart (MOD/NEW)  presentation/cubit/* (MOD)
    ├── transactions/  transactions_dao.dart (MOD)  data/sync/{money_transaction,transaction_audit}_sync_mapper.dart (NEW) …
    ├── finance/       finance_dao.dart (MOD)  data/sync/{finance_category,finance_entry}_sync_mapper.dart (NEW) …
    ├── currency/      currency_dao.dart, currency_repository_impl.dart (MOD)  data/sync/*_sync_mapper.dart (NEW) …
    ├── settings/      presentation/pages/settings_page.dart (MOD: one section)
    └── cloud_sync/    NEW feature: data/ domain/ presentation/
test/ …  integration_test/offline_sync_flow_test.dart (NEW)
android/app/src/main/AndroidManifest.xml   # MOD: INTERNET permission
.gitignore                                  # MOD: config/*.json, !config/supabase.example.json, supabase/.temp
```

**Structure decision**: keep the existing feature-first layout. There is no global `data/` or `domain/` folder (constitution II). The shared sync machinery goes in `lib/core/sync`, and each feature owns its mapper.

---

## 1. Existing architecture (verified)

| Aspect | Finding | File or evidence |
| --- | --- | --- |
| Flutter / Dart | 3.47.0 / ^3.10.0 | `flutter --version`, `pubspec.yaml` |
| State management | Cubits (`flutter_bloc` 9), one per screen or form, all imperative `load()` | `lib/features/*/presentation/cubit/` |
| Architecture | Feature-first data/domain/presentation layers | `lib/features/{people,transactions,finance,currency,settings,onboarding,insights_notifications,financial_education,startup}` |
| Domain entities | `Person`, `MoneyTransaction`, `TransactionAuditEntry`, `Category`, `FinanceEntry`, `ExchangeRate`, plus settings entities | `domain/entities/` |
| Data models | Drift-generated rows plus mappers (`transaction_mapper.dart` **throws on unknown audit types**) | `data/models/` |
| Repositories | Abstract contracts in domain with `*RepositoryImpl`, all `Future<Either<Failure,T>>` | `domain/repositories/`, `data/repositories/` |
| Use cases | One class per action (`add_transaction.dart`, `archive_person.dart`, …) | `domain/usecases/` |
| Local data sources | Plain `*Dao` classes wrapping `AppDatabase` | `data/datasources/*_dao.dart` |
| Remote data sources | **None** | — |
| Database | Drift v8, 11 tables, migrations v1→v8, seed in `beforeOpen` | `lib/core/database/app_database.dart` |
| DI | `injectable` with a `RegisterModule` for third-party singletons | `lib/core/di/` |
| Connectivity | **None** | — |
| Errors | `Failure` has 4 subclasses, plus feature-specific failures | `lib/core/error/failure.dart` |
| Clock | `AppClock` is injectable | `lib/core/date/app_clock.dart` |
| Startup | `AppStartupCubit.whenReady` runs post-startup services | `lib/main.dart` |
| Tests | Unit, Cubit and repository tests; migration tests built from raw SQLite; 11 integration flows | `test/`, `integration_test/` |
| Platform | The Android main manifest **lacks INTERNET**. iOS 15, SPM. | `android/app/src/main/AndroidManifest.xml`, `ios/Runner.xcodeproj` |

**How the new architecture fits in**:

- **Nothing is replaced.** DAOs gain outbox recording, repositories gain `watch*` methods, and Cubits switch from pull-to-refresh-after-mutation to subscriptions.
- Presentation stays unaware of the cloud, apart from the new `cloud_sync` feature, which depends only on its own domain contract.

## 2. Target architecture

```text
 UI (existing pages + cloud_sync pages)
   │  BlocBuilder / BlocSelector
 Cubits ──────────── subscribe ───────────┐
   │ call                                  │ Stream<Either<Failure,T>>
 Use cases (Add*/Edit*/…  +  Watch*)       │
   │                                       │
 Repository contracts (domain) ─ impl ─────┘
   │
 Feature DAOs ──(same Drift txn)──► SyncOutbox.record()
   │                                       │
 ┌─▼───────────── AppDatabase (SQLite, source of truth) ─────────────┐
 │ business tables │ sync_outbox │ sync_record_meta │ sync_conflicts │ sync_state │
 └─▲───────────────────────────────────────────▲────────────────────┘
   │ tableUpdates → watch streams               │ SyncLocalStore / SyncApplier
   │                                   SyncEngine (single-flight)
   │                                            │ SyncRemoteDataSource / CloudAuthDataSource
   │                          SyncScheduler ◄── triggers: launch, resume, connectivity, outbox change (3 s), 5 min timer, "Sync now"
   │                                            ▼
   │                           Supabase: sync_push / sync_pull RPC → RLS-protected tables
```

## 3. Local database implementation

- The existing `AppDatabase` is reused (research Decision 1). The migration is required only to add the sync tables. **No reset, no data copy.**
- The table definitions are in [data-model.md §2](data-model.md): `sync_outbox`, `sync_record_meta`, `sync_conflicts`, `conflict_resolutions`, `sync_state`.
- New indexes: 2 on the sync tables and 2 on business tables.
- `schemaVersion: 8 → 9`, with the `from < 9` branch as described in data-model.md §3:
  - create the tables and indexes;
  - rewrite the exchange-rate ids;
  - enqueue existing rows in `beforeOpen` with `SyncBootstrap`, which is idempotent and runs in one transaction.
- **Preserving existing data**: no business column is touched except `exchange_rates.id`, which has no references and is guaranteed unique by the existing pair index. The migration test asserts that business fields are byte-identical before and after.
- Local foreign keys: Drift has not enabled `PRAGMA foreign_keys` so far, and that stays unchanged. Referential order on download is guaranteed by revision order (contracts/sync-rpc.md §3).

## 4. Supabase integration

- **Initialization**: `SupabaseInitializer.ensureInitialized()` in `core/sync/remote/`.
  - It is called lazily by `SyncScheduler.start()`, never before `runApp`, so the splash timing stays as it is (019).
  - It runs `Supabase.initialize(url: CloudConfig.url, anonKey: CloudConfig.publishableKey, authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage(), autoRefreshToken: true), realtimeClientOptions: …)`.
  - Realtime is never subscribed.
  - If `CloudConfig.isConfigured` is false, the scheduler reports `disabled` and returns.
- **Configuration**: `--dart-define-from-file` (research Decision 12). `config/supabase.example.json` is committed. Launch configurations (`.vscode/launch.json`, if present) reference the dev file.
- **Where it starts**: `main.dart` calls `getIt<SyncScheduler>().start()` inside the existing `startup.whenReady.then(...)` block, next to `NotificationRecomputeTrigger`.
- **Auth**: `CloudAuthDataSource` (research Decision 11). `ensureSession()` runs at the start of each cycle.
- **Error handling**: `SyncErrorMapper` maps exceptions to failures (research Decision 20).
- **Connection handling**: every call has a 20 s timeout. The client's own token refresh runs only while the app is in the foreground.
- **When sync is off (FR-041)**: if `sync_state.enabled` is false at startup, Supabase is **not initialized at all**. When the switch is turned off at runtime, `supabase.auth.stopAutoRefresh()` is called, and `startAutoRefresh()` when it is turned back on. No request of any kind (including token refresh) leaves the device while sync is off.
- **iOS reinstall**: Keychain entries survive an app uninstall, so a reinstalled app can find the previous anonymous session while its local database is empty. `sync_state.owner_id` is `null`, so the first uid is adopted and the pull from cursor 0 **restores** the user's data. This is intended; it is documented and tested in T069.

## 5. Supabase schema

The full contract is in [contracts/supabase-schema.md](contracts/supabase-schema.md):

- 8 owner-scoped business tables with the common sync columns;
- `sync_owner_state`, `sync_operations` and `devices`;
- the stamp, guard and type-match triggers;
- owner-only row-level security with no delete policy anywhere;
- 4 views with `security_invoker` enabled.

It ships as one migration, `supabase/migrations/<ts>_021_offline_sync.sql`, and is deployed with `supabase db push`. RPC semantics are in [contracts/sync-rpc.md](contracts/sync-rpc.md).

## 6. Repository and data-source strategy

- **Reads**: Cubit → `Watch*` use case → `Repository.watch*` → `db.changesOf({tables})` → the existing `get*` query. Supabase is never read to render a screen.
- **Writes**: Cubit → use case → `Repository.add/edit/...` → DAO method.
  - The DAO opens `_db.transaction`, performs the business write, calls `SyncOutbox.recordUpsert/Delete`, and commits. The result returns to the UI at once.
  - The `tableUpdates` event on `sync_outbox` fires `SyncScheduler.request(localWrite)`, debounced by 3 s.
- **Remote**: only the `SyncEngine` talks to `SyncRemoteDataSource`. Repositories never call it. That keeps the "a local write never waits for the network" rule structurally guaranteed (FR-002).

## 7. Offline-first behavior per operation (DAO-level changes)

| DAO method | Outbox entry recorded |
| --- | --- |
| `PeopleDao.insertPerson` / `updatePerson` / `setArchived` | `person` upsert |
| `PeopleDao.deletePerson` | `person` delete, or the pending create is dropped by coalescing |
| `TransactionsDao.insertTransactionIdempotent` | `money_transaction` upsert. Nothing is recorded if it returned an existing row by idempotency key. |
| `TransactionsDao.updateTransaction` / `softDelete` | `money_transaction` upsert (a soft delete is an upsert with `deleted_at` set) |
| `TransactionsDao.insertAuditEntry` | `transaction_audit` upsert (never coalesced) |
| `FinanceDao.insertCategory` / `updateCategory` / `archiveCategory` | `finance_category` upsert |
| `FinanceDao.deleteCategory` | `finance_category` delete |
| `FinanceDao.insertEntryIdempotent` / `updateEntry` / `softDeleteEntry` / `restoreEntry` | `finance_entry` upsert |
| `CurrencyDao.upsertPrimary` | `primary_currency` upsert |
| `CurrencyDao.upsertRate` | `exchange_rate` upsert (id = the pair) |
| `CurrencyDao.deleteRatesFrom` | one `exchange_rate` delete per deleted row. The DAO reads the ids first, in the same transaction. |

Create, update, archive and unarchive all persist immediately, reach the UI through watch streams, get marked `pending` in `sync_record_meta`, and upload later. The existing delete semantics are kept: soft for financial records, hard locally with a cloud tombstone for the rest.

## 8. Sync engine

| Concern | Design |
| --- | --- |
| Components | `SyncScheduler` (triggers and single-flight) → `SyncEngine.runCycle()` → `SyncLocalStore`, `SyncApplier`, `SyncRemoteDataSource`, `CloudAuthDataSource`, `SyncLogger` |
| Operation model | `OutboxOp` (data-model.md `sync_outbox`) and `PushResult` (contracts/sync-rpc.md §2) |
| State | `SyncRuntimeStatus` values: idle, syncing, offline, backingOff, authRequired, disabled. Persisted state lives in `sync_state`. |
| Cycle | 1. If not enabled, not configured or no network, set the status and return. 2. `ensureSession()`; if the uid differs from `sync_state.owner_id`, **re-own**: re-enqueue everything and reset the cursor to 0. 3. Push loop: `nextBatch(100)` → mark in flight → `push` → `applyPushResults`, repeated until the batch is empty or contains only blocked operations. 4. Pull loop: `pull(since: cursor)` → `applyPage`, repeated until `has_more` is false. 5. Update `last_success_at` and reset the failure count. |
| Ordering | `depends_on_rank`, then `created_at`. An operation is skipped while a lower-ranked operation for its parent (for example the person of a transaction) is `failed` or `blocked_conflict`. That blocks dependents only. |
| Batch size | Push 100 operations, pull 500 rows |
| Partial failure | Handled per operation (contracts/sync-rpc.md §5). Operations A (applied), B (failed) and C (pending) are each stored correctly; the queue is never marked done as a whole. |
| Retry | Transient failures of a whole call: backoff of `5 s · 2^n ± 20 %`, capped at 15 min, with `n = sync_state.consecutive_failures`. Permanent failures of one operation: `failed` until "Retry" in Settings or a relevant change (for example re-authentication). |
| Resume and restart | `resetInFlight()` runs on `start()`. The cursor is persisted per page. The ledger makes replayed pushes safe. |
| Triggers | Launch (after startup is ready); `AppLifecycleState.resumed`; connectivity changing to available; outbox table change (3 s debounce); a 5 min periodic timer while resumed; "Sync now"; the enabled switch turning on |
| Single-flight | A `_running` future plus a `_rerunRequested` flag. A request that arrives mid-cycle schedules exactly one follow-up. |
| Manual sync | `SyncNow` use case. The button is disabled while `syncing`. |

## 9. Idempotency

There are three layers (research Decision 6):

1. **Stable client ids.** Cloud primary keys are `(owner_id, id)`.
2. **The `sync_operations` ledger**, keyed by `op_id`.
3. **`unique (owner_id, idempotency_key)`** on transactions and entries, plus an equal-fields check for a create that hits an existing row.

Example: transaction `ABC123` with `op_id` `X`.

| Attempt | What happens |
| --- | --- |
| First | The row is inserted and the ledger stores `applied`. |
| Retry after the response was lost | The ledger hit returns `already_applied`, and the device marks it synced. |
| Re-enqueued after a re-own under a new `op_id` Y | The same id and fields return `already_applied`. |

There is still exactly 1 row. The pgTAP test covers it, and so does the engine test with `FakeSyncRemote`.

## 10. Conflict resolution

This is the chosen strategy (research Decision 7; contracts/sync-rpc.md §2 steps 3b, 3d and 3e):

| Case | Financial (transaction, entry) | People, categories, primary currency, rates |
| --- | --- | --- |
| Local update vs remote update | **Conflict**: preserved, flagged and badged. The user chooses. | Server order wins, meaning the later push. |
| Local delete vs remote update | Conflict (a soft delete is an update of `deleted_at`) | `superseded`: the delete loses and the record is restored locally. |
| Remote delete vs local update | Conflict | The local update is applied by last-write-wins and restores the row, clearing `deleted_at`. |
| Same record edited on two devices | The second device to push gets the conflict. | The second push wins. |
| Person delete while the server has transactions | — | `rejected`; the person is restored and archive is suggested. |
| Category delete while entries reference it | — | The server archives instead. |

Resolution (contracts/sync-rpc.md §6) always writes a `conflict_resolutions` record holding the discarded version. **No financial version is ever discarded without a record of it.**

## 11. Incremental sync

- The cursor is `sync_state.last_pulled_revision`, a gap-free per-owner revision (research Decision 4). It is **not** `updated_at`: device clocks and commit-order races make timestamps unsafe.
- Each pull asks for `revision > cursor`, in pages of 500. Tombstones are included.
- The full dataset downloads only when the cursor is 0: on first restore, or after a re-own.

## 12. Connectivity

- `ConnectivityMonitor` wraps `connectivity_plus`.
  - When no network is reported, the engine makes no requests and shows the `offline` status.
  - When the network comes back, it calls `request(connectivityRestored)`.
- A network being present is **never** treated as proof the cloud is reachable. Failures go to backoff, and backoff state persists across on/off switching (FR-053).
- Single-flight is described in §8.

## 13. Reactive local data

`watch_tables.dart` together with the repository `watch*` methods (contracts/dart-interfaces.md §3). These Cubits are migrated:

| Cubit | Before | After |
| --- | --- | --- |
| `PersonListCubit` | `load()` after create, archive or undo | Subscribes to `watchActivePeople` + `watchPersonBalances` |
| `ArchivedPeopleCubit` | `load()` after restore | `watchArchivedPeople` |
| `PersonDetailCubit` | `load(id)` / `refresh()` after add, edit or delete (the 004 fix) | `watchPersonHistory` + `watchPersonBalance` + `watchHasConflict` |
| `OverviewCubit` | Reloaded from other screens | `watchOverview` (removes the "next-view only" limit agreed in 004) |
| `FinanceHistoryCubit` | `load()` | `watchHistory(limit: loadedCount)`; paging raises the limit |
| `FinanceMonthSummaryCubit` | `load()` | `watchSummaryTotals(period)` |
| `CategoryManagementCubit` | `load()` | `watchCategories` |
| `ExchangeRateListCubit`, `PrimaryCurrencyCubit` | `load()` | `watchExchangeRates`, `watchPrimaryCurrency` |

The page-level `await cubit.load()` calls made after `context.push(...)` returns are removed in `people_list_page`, `archived_people_page`, `person_detail_page`, `overview_page`, `finance_history_page`, `finance_month_summary_card`, `category_management_page`, `exchange_rate_list_page` and `currency_settings_page`. Retry buttons keep calling a `resubscribe()` method. This fixes:

- a new person not appearing;
- a new transaction not appearing;
- archive and unarchive needing a reload;
- balances not updating;

and it does so for both local and sync-applied changes, without a separate workaround.

## 14. Analytics-ready data

Everything in [data-model.md §6](data-model.md) and [contracts/supabase-schema.md §7](contracts/supabase-schema.md). Every question in spec FR-061 maps to one view or one base-table query:

| Question | Source |
| --- | --- |
| Total given, total received, net | `v_person_balances` summed per currency |
| Outstanding balances | `v_person_balances where net_given_minor <> 0` |
| Counts by month or year | `v_monthly_person_flows` |
| Average amount | `avg_minor` |
| Distribution by kind and direction | the `kind` and `direction` columns |
| People total, active and archived | `people` |
| Most active relationships | `tx_count` in `v_person_balances` |
| Daily activity and offline lag | `v_daily_activity` |

**No analytics UI is built.**

## 15. Security

- Row-level security is on for every table, with `(select auth.uid())` policies, no delete policies, and append-only tables.
- The `anon` role is revoked from everything.
- RPCs are `SECURITY INVOKER`, so row-level security applies inside them.
- Ownership: `owner_id` is set by a trigger from `auth.uid()`, and a client-sent `owner_id` is ignored.
- Only the publishable key is in the app, supplied at build time through a git-ignored file. The service-role key and the database password never enter the repository; the database password is typed only at the Supabase CLI prompt.
- Sessions are stored in `flutter_secure_storage`.
- Logs use an allow-listed set of field keys (research Decision 18). The email is masked in the UI and never logged.
- **Table-by-table review** is the pgTAP isolation suite (contracts/supabase-schema.md §8). It is a merge gate.
- Account deletion is out of scope; `on delete cascade` from `auth.users` is ready for it.
- Abuse of anonymous sign-ins is limited by the Supabase rate limit (30 per hour per IP, set in T006 and T050). CAPTCHA was rejected for this feature because it needs a client widget package.

## 16. Migration of existing data

```text
v8 app with data
  → Drift onUpgrade(from 8): create sync tables, rewrite rate ids          [atomic; rollback = v8 intact]
  → beforeOpen: SyncBootstrap.enqueueExistingDataIfNeeded                 [one txn; idempotent; skips pristine seeds]
  → first online cycle: ensureSession (anonymous) → push rank-ordered batches of 100
       (idempotent: ledger + idempotency_key + equal-fields check)       [interruptible and resumable at any batch]
  → pull from 0 (merges any cloud data that already exists)
  → verify: once the outbox is empty, set initial_upload_done = true; log counts per entity type
```

- **IDs**: every existing row already has a stable id, so no ids are generated. Rates get deterministic ids.
- **Duplicates**: prevented by the three idempotency layers. People are never merged by name (spec 001 rule).
- **Balances**: not affected, because they are computed locally from unchanged rows. The migration test checks this by comparing `getOverview()` before and after.
- **Partial failure**: failed operations stay `failed` and visible, while other operations continue. A crash mid-bootstrap or mid-upload resumes on the next launch.

## 17. Package changes

| Package | Version | Purpose | Used in |
| --- | --- | --- | --- |
| `supabase_flutter` | `^2.17.2` | Auth (anonymous and one-time code), RPC, token refresh | `core/sync/remote/*` only |
| `connectivity_plus` | `^7.3.1` | Network change hint | `core/sync/connectivity_monitor.dart` |
| `flutter_secure_storage` | `^11.2.0` | Session persistence (constitution XII) | `core/sync/remote/secure_local_storage.dart` |

All three were checked against Flutter 3.47 and Dart ^3.10 (research Decision 21). Everything else is reused: `drift`, `uuid`, `fpdart`, `injectable`, `flutter_bloc`, and `AppClock`.

## 18. File-level implementation plan

**Create**

| Path | Purpose |
| --- | --- |
| `config/supabase.example.json` | Placeholder config |
| `supabase/config.toml`, `supabase/migrations/<ts>_021_offline_sync.sql`, `supabase/tests/021_{rls,sync_push,sync_pull}.test.sql` | Backend schema and tests |
| `lib/core/config/cloud_config.dart` | Build-time config |
| `lib/core/database/sync_tables.dart`, `migrations/v9_sync_support.dart`, `watch_tables.dart` | Local schema and watch |
| `lib/core/sync/{sync_entity_type, sync_logger, sync_trigger, sync_engine, sync_scheduler, backoff_policy, connectivity_monitor, sync_bootstrap, sync_mapper_registry}.dart` | Engine |
| `lib/core/sync/local/{sync_outbox, sync_local_store, sync_applier, outbox_coalescer}.dart` | Local sync store |
| `lib/core/sync/remote/{supabase_initializer, secure_local_storage, sync_remote_data_source, cloud_auth_data_source, sync_error_mapper}.dart` | Remote |
| `lib/features/people/data/sync/person_sync_mapper.dart` | Mapper |
| `lib/features/transactions/data/sync/{money_transaction,transaction_audit}_sync_mapper.dart` | Mappers |
| `lib/features/finance/data/sync/{finance_category,finance_entry}_sync_mapper.dart` | Mappers |
| `lib/features/currency/data/sync/{exchange_rate,primary_currency}_sync_mapper.dart` | Mappers |
| `lib/features/*/domain/usecases/watch_*.dart` (about 11) | Watch use cases |
| `lib/features/cloud_sync/data/{repositories/cloud_sync_repository_impl.dart, sync/conflict_resolution_sync_mapper.dart}` | Feature data |
| `lib/features/cloud_sync/domain/{entities/sync_status.dart, entities/sync_conflict_item.dart, repositories/cloud_sync_repository.dart, usecases/*.dart (9)}` | Feature domain |
| `lib/features/cloud_sync/presentation/{cubit/(sync_settings, sync_conflicts, email_link, sync_notice)_cubit+state.dart, pages/sync_settings_page.dart, widgets/(conflict_resolution_sheet, conflict_badge, sync_notice_sheet, sync_status_line).dart}` | Feature UI |
| Tests | Listed in §20 |

**Modify**

| Path | Change |
| --- | --- |
| `pubspec.yaml` | Add the 3 packages |
| `.gitignore` | `config/*.json`, `!config/supabase.example.json`, `supabase/.temp/` |
| `android/app/src/main/AndroidManifest.xml` | Add `INTERNET` |
| `lib/main.dart` | Start `SyncScheduler` in the `whenReady` block, and show the notice host |
| `lib/core/database/app_database.dart` | Add tables, v9, `beforeOpen` bootstrap |
| `lib/core/di/register_module.dart` | `SupabaseClient` (lazy, only if configured), `Connectivity`, `FlutterSecureStorage` |
| `lib/core/error/failure.dart`, `lib/core/l10n/failure_message.dart`, ARB files | New failures and strings |
| `lib/core/routing/app_router.dart` | `/settings/sync` route |
| `lib/features/{people,transactions,finance,currency}/data/datasources/*_dao.dart` | Transactions plus outbox recording |
| `lib/features/{people,transactions,finance,currency}/domain/repositories/*.dart` and `data/repositories/*_impl.dart` | `watch*` methods; currency uses deterministic rate ids |
| The 9 Cubits and pages listed in §13 | Subscriptions replace reloads |
| `lib/features/transactions/presentation/widgets/<transaction row>` and `lib/features/finance/presentation/widgets/<entry row>` | Conflict badge |
| `lib/features/settings/presentation/pages/settings_page.dart` | One new section tile |
| `test/features/**/cubit/*_test.dart` for the migrated Cubits | Update to stream-based setups |

**Delete**: nothing.

## 19. Dependency injection

| Registration | Scope | Notes |
| --- | --- | --- |
| `AppDatabase` | existing `@lazySingleton` | Unchanged. It is the one instance that all DAOs, the outbox and the applier share. |
| `SupabaseClient` | `@lazySingleton` in `RegisterModule`, resolved **after** `SupabaseInitializer.ensureInitialized()` | Never resolved when not configured |
| `Connectivity`, `FlutterSecureStorage` | `@lazySingleton` (module) | |
| `SyncOutbox`, `SyncLocalStore`, `SyncApplier`, `SyncMapperRegistry` | `@LazySingleton(as: …)` | |
| `SyncRemoteDataSource`, `CloudAuthDataSource`, `ConnectivityMonitor`, `SyncLogger` | `@LazySingleton(as: …)` | Abstractions, so tests can inject fakes |
| `SyncEngine`, `SyncScheduler` | `@lazySingleton` | Exactly one of each (single-flight depends on this) |
| `CloudSyncRepository` | `@LazySingleton(as: …)` | |
| Watch and sync use cases | `@injectable` | |
| New Cubits | `@injectable` (factory) | Same pattern as the existing Cubits |

After the change, `dart run build_runner build` regenerates `injection.config.dart`.

## 20. Testing plan

**Minimum gate**: every row below exists and passes.

| Area | Test file(s) | Cases |
| --- | --- | --- |
| Migration | `test/core/database/sync_v9_migration_test.dart`, built from a raw v8 file (the pattern of the existing migration tests) | Business fields unchanged; rate ids rewritten; bootstrap enqueues N rows and skips pristine seeds; bootstrap twice gives N, not 2N; a failure mid-migration leaves v8; `getOverview()` is identical before and after |
| DAO and outbox | `test/core/sync/local/sync_outbox_test.dart`, `test/features/*/data/datasources/*_dao_sync_test.dart` | Insert, update, delete, archive, restore for each type → exactly 1 coalesced operation; atomicity (a thrown error rolls back both); **a guard test that fails if any public DAO write method does not record an outbox entry** |
| Coalescing | `outbox_coalescer_test.dart` | Every row of data-model.md §5 |
| Repository and watch | `test/features/*/data/repositories/*_watch_test.dart` | The first emission equals `get*`; a write emits an update; a sync-applied write emits; `distinct` suppresses duplicates |
| Engine | `test/core/sync/sync_engine_test.dart` with `FakeSyncRemote` | Create, update and delete sync; pulled insert, update and tombstone; partial failure (A ok, B fail, C pending); a lost response is replayed as already applied; duplicate prevention; conflict creates a `sync_conflicts` row and a blocked operation; superseded restores; rejection of a person delete; dependent blocked only by a failed parent; re-own on a uid change; cursor advances only per full page |
| Retry and backoff | `backoff_policy_test.dart`, `sync_scheduler_test.dart` (fake clock) | Exponential with jitter bounds and cap; persisted across triggers; permanent vs transient classification |
| Connectivity | `sync_scheduler_test.dart` | offline→online triggers once; online→offline mid-cycle aborts cleanly with operations back to pending; flapping x10 gives 1 cycle; network present but remote throwing is transient |
| Error mapping | `sync_error_mapper_test.dart` | Every row of research Decision 20 |
| Conflict resolution | `resolve_sync_conflict_test.dart` | Keep mine and keep theirs → correct operations plus a `conflict_resolution` record, in one transaction |
| Cubits | `bloc_test` for the 9 migrated Cubits and 4 new ones | New person, new transaction, archive/unarchive and balance changes all emit with no `load()` call |
| Widget | `sync_settings_page_test.dart`, `conflict_badge_test.dart` | All status states in `ar` and `en`; the badge shows only when in conflict |
| Database | `supabase/tests/*.test.sql` | Row-level security isolation (7 guarantees); constraints; `sync_push` outcome matrix; `sync_pull` ordering and no gaps |
| Integration | `integration_test/offline_sync_flow_test.dart` (local Supabase) plus all 11 existing flows, which must run unchanged offline | Offline CRUD → restart → online → cloud equals local; interrupted upload resumes without duplicates |

## 21. Android and iOS

- **Android**:
  - Add `INTERNET` to the **main** manifest. Today it exists only in the debug and profile variants, so release builds would silently fail every request.
  - `ACCESS_NETWORK_STATE` is merged in by `connectivity_plus`.
  - No `minSdk` change; keep `flutter.minSdkVersion` and check it against `flutter_secure_storage` 11 during the build.
  - No intent filters, because the one-time code avoids deep links.
- **iOS**:
  - Deployment target 15.0 is fine.
  - Confirm Swift Package Manager resolution for `supabase_flutter`'s transitive plugins (`app_links`, `url_launcher`, `shared_preferences`), `connectivity_plus` and `flutter_secure_storage`, using `flutter build ios --no-codesign`.
  - No Info.plist change and no entitlements, because Keychain uses the default group.
- No unrelated platform files are touched.

## 22. Performance safeguards

- Reads are local only. Watch queries are debounced (50 ms) and filtered with `distinct`.
- Local indexes: the existing ones, plus the 2 new business indexes and the 3 on the sync tables.
- Cloud indexes: `(owner_id, revision)` on every table, plus a foreign-key index on every foreign key and date indexes for analytics.
- Push batches of 100 and pull pages of 500. The initial upload runs in batches and never blocks the UI (the engine runs on the main isolate, but in short async steps with Drift's background isolate).
- No full downloads, except when the cursor is 0.
- No requests while offline or while sync is disabled. Single-flight, a 3 s write debounce and persisted backoff prevent request storms.
- History paging is kept, because `watchHistory` watches the loaded window only. Nothing loads the whole database into memory. The bootstrap enqueue streams rows in chunks of 500.

## 23. Error handling by layer

| Layer | Error | Mapping and behavior |
| --- | --- | --- |
| Local database | `SqliteException`, `DriftWrappedException` | `CacheFailure` (existing). For a sync write, the whole local transaction is rolled back. |
| Network | socket, handshake or client errors | `NetworkFailure`, transient |
| Supabase | 5xx, 429, `PGRST` connection errors | `ServerFailure`, transient |
| Timeout | the 20 s limit | `TimeoutFailure`, transient |
| Auth | `AuthException`, JWT expiry (`PGRST301`) | `UnauthorizedFailure`: refresh the session once, then status `authRequired` |
| Row-level security | `42501` | `ForbiddenFailure`: the batch pauses and a diagnostic is logged |
| Validation | the `rejected` result or `23514`/`23502`/`22P02` | `SyncRejectedFailure(reason)`: the operation is `failed` and a Retry is offered |
| Conflict | the `conflict` result | This is state, not a failure: the conflict flow starts. `SyncConflictFailure` is used only when a resolve action is invalid. |
| Migration | an exception during v9 | Drift rolls back to v8. The app opens with v8 data, sync stays disabled, and `SYNC_ABORTED errorCode=migration` is logged. |

Sync failures reach the user only through `SyncStatus` in the Settings sync page, using localized messages from `failure_message.dart`. They never surface on an existing screen.

## 24. Observability

`SyncLogger` event names:

- `SYNC_STARTED`, `SYNC_UPLOAD_STARTED`, `SYNC_UPLOAD_SUCCESS`, `SYNC_UPLOAD_FAILED`;
- `SYNC_DOWNLOAD_STARTED`, `SYNC_DOWNLOAD_SUCCESS`;
- `SYNC_CONFLICT`, `SYNC_RETRY`, `SYNC_COMPLETED`, `SYNC_ABORTED`;
- `SYNC_MIGRATION_ENQUEUED`, `SYNC_CURSOR_ADVANCED`.

The fields are limited to `entityType`, `count`, `durationMs`, `errorCode`, `delayMs`, `revision` and `opId`, and the enum keys make any other field impossible to log. Release builds log warnings and errors only. The cloud side has `sync_operations` (result and reason per operation) and `devices.last_sync_at` for diagnosis. The status view also shows a `last_error_code`.

## 25. Implementation order

> **Release constraint**: US2 (upload) MUST NOT ship without US3 (bootstrap). On an upgraded install, new transactions would reference people who were never uploaded, and they would be rejected as `missing_parent` indefinitely. The two ship together.


Adjusted from the requested sequence: reactive reads come early because they are independent and remove the 004/005 risk before any cloud work starts.

| Phase | Steps | Gate |
| --- | --- | --- |
| **P0 Setup** | Packages; `.gitignore`; `config/supabase.example.json`; `CloudConfig`; Android `INTERNET`; `supabase init` | `flutter analyze`; builds succeed |
| **P1 Local foundation** | `sync_tables.dart`; v9 migration and rate-id rewrite; `SyncOutbox` and coalescer; `SyncBootstrap`; new failures | Migration and outbox tests are green |
| **P2 Reactive reads** (can run alongside P1) | `watch_tables.dart`; repository `watch*`; `Watch*` use cases; migrate the 9 Cubits and pages; Cubit tests | All existing tests plus the watch tests are green; offline integration flows unchanged |
| **P3 DAO outbox wiring** | Record outbox entries in every mutating DAO method; the guard test | Every DAO write enqueues exactly once |
| **P4 Backend** | The schema migration; triggers; row-level security; `sync_push` / `sync_pull`; views; pgTAP | `supabase test db` is green; `db push` to the project |
| **P5 Remote layer** | `SupabaseInitializer`, `SecureLocalStorage`, `CloudAuthDataSource`, `SyncRemoteDataSource`, `SyncErrorMapper`, feature mappers and registry | Mapper round-trip tests; error-mapper tests |
| **P6 Engine** | `SyncLocalStore`, `SyncApplier`, `SyncEngine`, `BackoffPolicy`, `FakeSyncRemote`, engine tests | Engine suite is green |
| **P7 Triggers** | `ConnectivityMonitor`, `SyncScheduler` (lifecycle, timer, outbox listener, single-flight), wired into `main.dart` | Scheduler and connectivity tests are green |
| **P8 Conflicts** | `sync_conflicts` flow, `ResolveSyncConflict`, badge and sheet | Conflict tests are green |
| **P9 cloud_sync UI** | Repository, use cases, Cubits, `SyncSettingsPage`, Settings tile, route, notice, email link, ARB strings | Widget tests in ar and en |
| **P10 Verification** | `integration_test/offline_sync_flow_test.dart`; `flutter analyze`; `flutter test`; Android release build; iOS build; quickstart scenarios 1–10; secret scan; `specs/ROADMAP-PLAN.md` updated | Definition of Done |

## 26. Definition of Done (verification of each item)

| Requirement | Verified by |
| --- | --- |
| The app works offline | All 11 existing integration flows pass in airplane mode; quickstart #1 |
| Data persists locally | Quickstart #2; migration test |
| Offline mutations are queued | DAO guard test; outbox tests; pending count in #1 |
| Connectivity returning triggers sync | Scheduler test; quickstart #3 (≤10 s) |
| Supabase receives the changes | Engine test; quickstart #3 table check |
| Remote changes reach the local database | Applier and engine pull tests; quickstart #5 |
| The UI updates automatically | Watch and Cubit tests; quickstart #5 |
| No duplicate financial records | Idempotency tests (engine and pgTAP); quickstart #4 duplicate query returns 0 rows |
| Conflicts are handled safely | Conflict tests; quickstart #6 |
| Existing data is preserved | v9 migration test; quickstart #10 |
| Row-level security protects user data | pgTAP isolation suite |
| Android works | `flutter build apk --release` plus a device run |
| iOS works | `flutter build ios --no-codesign` plus a device run |
| Tests pass | `flutter analyze` clean; `flutter test` and `supabase test db` green |

---

## Closing summary

1. **Architecture**: The Drift database stays the source of truth. DAOs write an outbox entry in the same transaction as each business write. A single-flight engine pushes through an idempotent RPC and pulls through a gap-free revision cursor. The UI reads through watch streams. Supabase is a remote protected by row-level security that only the engine talks to.
2. **Database changes**: Drift v9 adds 5 sync tables and 4 indexes, rewrites exchange-rate ids to their currency pair, and bootstraps the existing data into the outbox in `beforeOpen`. Business fields are unchanged.
3. **Supabase changes**:
   - 8 owner-scoped business tables;
   - `sync_owner_state`, `sync_operations` and `devices`;
   - the stamp, guard and type-match triggers;
   - `sync_push` and `sync_pull`;
   - owner-only row-level security with no deletes;
   - 4 analytics views.
4. **Sync architecture**: Scheduler (triggers and single-flight) → Engine (session → push batches → pull pages) → per-operation results → per-entity conflict policy → resolution history.
5. **File-by-file**: §18.
6. **Packages**: `supabase_flutter ^2.17.2`, `connectivity_plus ^7.3.1`, `flutter_secure_storage ^11.2.0`.
7. **Migration**: §16. It is atomic, idempotent and resumable, and it never rewrites business data.
8. **Testing**: §20. The migration, outbox guard, engine, conflict, scheduler, Cubit and pgTAP row-level security suites are merge gates.
9. **Risks**:
   - Q1–Q3 are assumed, and overriding them changes only the auth UI and scope.
   - Migrating the Cubits to watch streams carries regression risk against 004/005 (mitigated by P2 running first, with tests).
   - SPM support in the new iOS plugins (checked in P0 or P10).
   - The anonymous-account orphan left behind on re-own.
   - The Supabase free tier pausing (tolerated by the offline-first design).
   - The roadmap contradiction (update `ROADMAP-PLAN.md`).
10. **Dependency graph**:

    ```text
    P0 ─► P1 ─► P3 ─┐
     └──► P2 ───────┤
    P0 ─► P4 ─► P5 ─┴► P6 ─► P7 ─► P8 ─► P9 ─► P10
    ```

11. **Recommended order**: P0 → (P1 ∥ P2 ∥ P4) → P3 → P5 → P6 → P7 → P8 → P9 → P10.
12. **Definition of Done**: §26.

## Complexity Tracking

| Addition | Why needed | Simpler alternative rejected because |
| --- | --- | --- |
| New `lib/core/sync` subsystem (about 20 files) | Four features share one outbox, engine and applier, which puts it in `core/` under the constitution II rule for code shared by two or more features. | A separate copy per feature would duplicate the engine four times and could not guarantee dependency order across features. |
| Server RPCs rather than plain PostgREST upserts | Atomic "check base revision, then write" plus the ledger, handled per operation (research Decision 5) | Per-table upserts cannot give per-operation results or a check-and-set as one atomic step. |
| Per-owner revision counter | A gap-free cursor (research Decision 4) | An `updated_at` cursor loses rows under clock skew or overlapping commits. |
