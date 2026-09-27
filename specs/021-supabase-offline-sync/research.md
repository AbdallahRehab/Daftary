# Research: Offline-First Cloud Sync (Supabase)

**Feature**: 021-supabase-offline-sync | **Date**: 2026-09-27

Every decision below was checked against the codebase at `fbce88f`. Technical Context has no open "NEEDS CLARIFICATION" items. The product decisions Q1–Q3 are **assumed** answers (spec § Clarifications). Decision 11 lists what would change if they are overridden.

---

## Decision 1: Keep the existing Drift database and extend it with an additive v9 migration

- **Decision**: Keep `AppDatabase` (`lib/core/database/app_database.dart`, file `daftary.sqlite`, `schemaVersion 8`). Raise it to **9** with purely additive changes: new sync tables, plus one id rewrite on `exchange_rates` (Decision 9). No existing column is changed, dropped or renamed.
- **Rationale**:
  - Drift already holds every entity and has a tested migration ladder (`test/core/database/*_migration_test.dart`).
  - It supports watchable queries (`tableUpdates`, `.watch()`) and nestable transactions, which is everything offline-first needs.
  - Replacing it would put existing user data at risk, against FR-007.
- **Alternatives considered**:
  - Isar, Hive, ObjectBox, sqflite: each would need a data copy migration and a rewrite of every DAO, for no gain.
  - PowerSync or ElectricSQL (managed sync layers over SQLite): these add a hosted service and a second schema system, and their conflict models are generic last-write-wins. Our financial conflict rule (FR-035) would need custom work either way.

## Decision 2: Record outbox entries in the DAOs, inside the same Drift transaction

- **Decision**: Every *mutating* DAO method on a synced table runs inside `_db.transaction(...)`. It performs the business write and calls `SyncOutbox.record(...)` with the row's post-write snapshot, so the business write and its queue entry commit together (FR-003). Drift joins nested transactions, so repository-level transactions (for example transaction edit plus audit entry) stay atomic. Writes applied by sync go through a separate `SyncApplier` path that never records outbox entries.
- **Rationale**:
  - DAOs are the narrowest point that every write path goes through, including `deleteRatesFrom`, `setArchived` and `insertAuditEntry`.
  - A guard test lists every public DAO method that writes and asserts that each one records an outbox entry (plan §20).
- **Alternatives considered**:
  - *SQLite triggers that write `json_object(...)` into the outbox*: they cannot be missed, but they need a "suppress while applying remote" flag table, put mapping logic in SQL strings, and are harder to unit test. Rejected on readability and testability grounds (constitution XVI).
  - *Enqueue in `*RepositoryImpl`*: there are more call sites, and it is easier to miss a path.

## Decision 3: Keep sync metadata in side tables, not as columns on business tables

- **Decision**: Add a local table `sync_record_meta(entity_type, entity_id, server_revision, state, last_synced_at)` plus the `sync_outbox`, `sync_conflicts` and `sync_state` tables. Business tables and their generated companions and mappers stay untouched. "Pending" is derived from open outbox entries.
- **Rationale**:
  - Mappers such as `transaction_mapper.dart` and all domain entities stay as they are.
  - The metadata is identical for all 8 synced types.
  - The conflict badge query is one indexed lookup: `(entity_type, entity_id)` where `state = 'conflict'`.
- **Alternatives considered**: Columns on every table: this touches 7 tables, their companions and every insert path. It is also harder to add to future features (FR-006).

## Decision 4: A per-owner server revision counter with in-order commits is the download cursor

- **Decision**:
  - Each owner has one row in `public.sync_owner_state(owner_id, last_revision bigint)`.
  - Every server write (inside the push RPC) runs `UPDATE … SET last_revision = last_revision + 1 … RETURNING`. That row lock serializes one owner's writes, so revisions commit in increasing order.
  - Each synced row stores the `revision` it received.
  - The client keeps one cursor, `last_pulled_revision`, and pulls `WHERE revision > cursor ORDER BY revision`.
- **Rationale**:
  - `updated_at > lastSyncedAt` misses rows when clocks skew or transactions overlap, because a row can commit after the reader has already passed its timestamp.
  - A global sequence has the same commit-order gap.
  - A per-owner counter that holds a row lock has no gaps. Its cost is serializing one user's concurrent writes, which is negligible because one person rarely writes from two devices in the same second.
  - Ordering by revision also keeps causal order across tables (a person is always received before their transaction).
- **Alternatives considered**: Timestamp cursor with an overlap window; a global sequence with a "safe watermark"; logical replication or Realtime. All are more complex or leave gaps.

## Decision 5: Two RPCs (`sync_push`, `sync_pull`) instead of per-table PostgREST calls

- **Decision**:
  - `public.sync_push(p_device_id uuid, p_ops jsonb)` applies up to 100 operations in one database transaction and returns one result per operation.
  - `public.sync_pull(p_since bigint, p_limit int)` returns one page of `{entity, row}` rows across all synced tables, ordered by revision.
  - Both are `SECURITY INVOKER` with `search_path = ''`, so row-level security applies to everything they touch.
- **Rationale**:
  - The version check, the idempotency ledger, revision assignment and the rule guards (person-delete, category-delete becoming archive) have to be atomic per operation. Server-side logic is the only place where that holds.
  - One round trip per batch.
  - One cursor for all types.
- **Alternatives considered**: PostgREST `upsert` per table. It cannot do an atomic "compare base revision, then write" plus ledger, so it would need triggers that raise exceptions, and one failing row fails the whole batch.

## Decision 6: Idempotency has three layers

- **Decision**:
  1. **Stable client ids.** The existing UUIDs are kept, and cloud primary keys are `(owner_id, id)`.
  2. **Operation ledger.** `public.sync_operations(owner_id, op_id)` is the primary key. A replayed `op_id` returns the stored result without writing.
  3. **Business keys.** `unique (owner_id, idempotency_key)` on `money_transactions` and `finance_entries`, which already exist locally.
  - An operation that finds its row already present with an identical payload returns `already_applied`.
- **Rationale**: This covers the case where "the response was lost after the commit" (spec edge case) and the case where two different operation ids carry the same business create after a local queue rebuild.
- **Alternatives considered**: An HTTP `Idempotency-Key` header. PostgREST does not support it.

## Decision 7: Conflict policy per entity type

| Entity | Policy | Server behavior when `base_revision ≠ current revision` |
| --- | --- | --- |
| `money_transactions`, `finance_entries` | **Manual** (FR-035) | Returns `conflict` with the server row. Nothing is written. |
| `transaction_audit_entries`, `conflict_resolutions` | Append-only | Never conflict. An insert on an existing id returns `already_applied`. |
| `people`, `finance_categories`, `primary_currency`, `exchange_rates` | **Last-write-wins in server order** (FR-037, FR-038) | Applies the write and returns `applied` with the new revision. Exception: a **delete** with a stale base returns `superseded` with the server row, and the client restores it ("delete loses to concurrent edit"). |
| Person delete while transactions exist on the server | Rule | `rejected` with reason `person_has_transactions`. The client restores the person locally. |
| Category delete while entries reference it | Rule | The server archives instead and returns `applied` with the archived row. |

The rationale is the financial-data override in the constitution: financial records are never merged automatically. Everything else converges without asking the user.

## Decision 8: Record conflict resolutions in a new append-only table, not in audit change types

- **Decision**: New synced table `conflict_resolutions(id, entity_type, entity_id, chosen_side, discarded_values jsonb, resolved_at)`.
- **Rationale**: `transaction_mapper.dart` throws `StateError('Unknown audit changeType')`. A new audit type would crash older app builds when they download it. Finance entries also have no audit table.
- **Alternative considered**: Adding an `AuditChangeType.conflictResolved` value. Rejected because of the version-skew crash.

## Decision 9: Exchange-rate ids derived from the currency pair

- **Decision**:
  - The id becomes `rate_<CUR>_<REL>`, for example `rate_USD_EGP`.
  - The v9 migration rewrites existing ids with one `UPDATE`. Nothing references `exchange_rates.id`, and the unique pair index already guarantees there are no collisions.
  - `CurrencyRepositoryImpl.setExchangeRate` stops using `_uuid.v4()` for new rates.
- **Rationale**: Two devices creating USD→EGP produce the same id, so last-write-wins converges with no rekeying logic.

## Decision 10: Pristine seed categories are never uploaded as changes

- **Decision**:
  - A `seed_*` category whose `name`, `icon` and `isArchived` still equal its seed definition counts as **pristine**.
  - The v9 migration does not enqueue pristine seed rows.
  - `seedDefaultFinanceCategories` writes directly, not through the DAO, so it records no outbox entry.
  - A user edit to a seed row enqueues it normally.
  - Downloaded seed rows overwrite local pristine rows.
- **Rationale**: Without this rule, a freshly installed second device would push its default "Rent" over a category the user renamed on the first device.

## Decision 11: Identity is an anonymous session plus optional email one-time-code linking, stored in secure storage *(assumed Q1)*

- **Decision**:
  - On the first online sync attempt, with sync enabled and no session, call `auth.signInAnonymously()`.
  - Settings then offers "Link email": `auth.updateUser(UserAttributes(email: …))` followed by `verifyOTP(type: OtpType.emailChange)`. This keeps the same `auth.uid()`.
  - On a device that is already anonymous, "Sign in to existing account" runs `signInWithOtp(email)` and then `verifyOTP(type: OtpType.email)`, which switches to that account's uid. The device's local data is then **re-owned**: every synced row is re-enqueued as an upsert and the cursor is reset to 0, which is a merge (FR-050). The old anonymous account is left orphaned.
  - The session is persisted through a `SecureLocalStorage implements LocalStorage` backed by `flutter_secure_storage` (constitution XII).
- **Supabase dashboard prerequisites**:
  - Enable *Anonymous sign-ins*.
  - Enable the email provider with a **one-time-code** template, meaning the `{{ .Token }}` placeholder rather than a magic link. This avoids deep-link setup.
  - Keep the default anonymous sign-in rate limit.
  - Recommended but outside the app: CAPTCHA protection.
- **If Q1 is overridden**:
  - *A (anonymous only)*: remove the email-link use cases and UI.
  - *C (Google/Apple)*: add `sign_in_with_apple` and `google_sign_in`, plus native configuration.
  - *D (required sign-in)*: add a sign-in gate to the startup flow.
  - The sync engine and schema are unchanged in all three cases.
- **Alternatives considered**: A device-generated secret as the owner, without auth. There would be no auth-backed row-level security, so it was rejected.

## Decision 12: Configuration comes from `--dart-define-from-file`

- **Decision**:
  - `lib/core/config/cloud_config.dart` reads `String.fromEnvironment('SUPABASE_URL')` and `String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY')`.
  - Builds pass `--dart-define-from-file=config/supabase.<env>.json`.
  - `config/*.json` is git-ignored. Only `config/supabase.example.json`, holding placeholder values, is committed.
  - If the values are empty, `CloudConfig.isConfigured == false`: sync stays disabled, the app runs exactly as today, and tests and CI need no secrets.
  - Only the publishable (anon) key is ever used. Service-role keys and database passwords never enter the repository.
- **Alternatives considered**:
  - `flutter_dotenv`: an extra package, and it bundles the `.env` as an asset.
  - `envied`: codegen that obfuscates, but the publishable key is public by design.

## Decision 13: Network status is only a hint; a successful request proves reachability

- **Decision**:
  - Use `connectivity_plus` `onConnectivityChanged`. `none` pauses sync. Any other value triggers a cycle.
  - Reachability is proven only by a successful RPC call.
  - Failures feed backoff: 5 s × 2ⁿ with ±20 % jitter, capped at 15 min, and persisted in `sync_state` so that a connection going on and off repeatedly does not reset it.
- **Alternative considered**: `internet_connection_checker_plus`. It pings a third-party host, which is still not proof that Supabase is up, and adds another package.

## Decision 14: Reactive reads re-run existing queries when relevant tables change

- **Decision**:
  - New `lib/core/database/watch_tables.dart` exposes `Stream<void> changesOf(Set<TableInfo>)`, built on `db.tableUpdates(TableUpdateQuery.onAllTables(...))`. It starts with one initial event and debounces to 50 ms.
  - Repositories add `watch*` methods that `asyncMap` the **existing** `get*` query and apply `distinct()` over the `Either` result.
  - Cubits subscribe once and cancel the subscription in `close()`.
- **Rationale**:
  - Balance, overview and summary logic, including currency conversion, is reused exactly as it is, so business logic does not change.
  - Writes from sync go through the same `AppDatabase` instance, so they emit update events too.
  - No `rxdart` is needed.
- **Alternatives considered**:
  - Rewriting every query as a Drift `.watch()`: large churn.
  - An app-level event bus: this does not see writes made by sync.

## Decision 15: No Supabase Realtime

The reasoning is in spec §20. Triggers on launch, return to foreground, reconnect, local write (debounced) and a 5-minute foreground timer are enough for a single owner. `SyncScheduler.request()` is the hook Realtime could call later.

## Decision 16: No sync in the background

iOS `BGTaskScheduler` gives no timing guarantees, and Android WorkManager needs `workmanager` plus a headless isolate that opens the same SQLite file. Both add risk: two processes writing to the database, and the session being refreshed while the app is closed. Sync runs only in the foreground (FR-023). This can be revisited later.

## Decision 17: Mapping money and dates to the server

- **Money**:
  - `amount_minor bigint check (> 0)` and `currency_code char(3)`, checked against `^[A-Z]{3}$`.
  - `rate_micros bigint check (> 0)`.
  - The Dart `int` (64-bit) maps losslessly to `bigint`, and JSON numbers stay within 2⁵³ for any realistic amount. As a guard, the push payload sends money as **strings**.
- **Dates**: the local `date` is epoch milliseconds. It is sent as:
  - `occurred_at timestamptz` (exact, so it round-trips losslessly);
  - `occurred_on date`, the calendar date in the device's local time, computed on the client when the operation is enqueued;
  - `tz_offset_minutes smallint`.
  Monthly and yearly analytics group by `occurred_on`, so grouping never depends on server time zones.
- **Client vs server time**: `client_updated_at` holds the device's `updatedAt`, `editedAt` or `deletedAt`. `server_updated_at` is set by a trigger. Their difference measures offline activity (FR-062).

## Decision 18: Logging goes through a small interface over `dart:developer`

`SyncLogger` has `event(SyncEvent, {Map<String, Object> fields})`. The allowed field keys are an enum: `entityType`, `count`, `durationMs`, `errorCode`, `delayMs`, `revision`, `opId`. Amounts, names, notes, phone numbers and tokens therefore cannot be logged by construction. Output goes to `developer.log` in debug builds. Release builds log `warning` and `error` only. No logging package is added, because the codebase uses `dart:developer` and `debugPrint` already.

## Decision 19: Batch sizes and timing defaults

| Parameter | Default |
| --- | --- |
| Push batch | 100 operations per RPC |
| Pull page | 500 rows |
| Request timeout | 20 s |
| Write debounce | 3 s |
| Foreground periodic timer | 5 min |
| Backoff | 5 s base, capped at 15 min |

The initial upload of 5,000 transactions is about 50 push calls.

## Decision 20: Mapping errors to failures

| Source | Detection | Failure | Retry? |
| --- | --- | --- | --- |
| `SocketException`, `ClientException`, handshake errors | exception type | `NetworkFailure` | Transient |
| `TimeoutException` | the 20 s timeout | `TimeoutFailure` | Transient |
| `PostgrestException` 5xx, `PGRST0xx` connection errors, HTTP 429 or 503 | code or status | `ServerFailure` | Transient |
| `AuthException`, `PGRST301` (JWT expired), HTTP 401 | code | `UnauthorizedFailure` | Refresh the session once, then pause |
| `42501` (insufficient privilege, RLS) | code | `ForbiddenFailure` | Permanent for the operation |
| `23514`, `23502`, `22P02` (check, not-null, invalid input) | code | `SyncRejectedFailure(reason)` | Permanent for the operation |
| `23503` (foreign key, parent missing), returned as `rejected missing_parent` | RPC result | — | **Transient**: retried with backoff |
| Per-operation `rejected`, `conflict`, `superseded` | RPC result | handled per operation, not as a failure | — |
| Drift or SQLite exception | exception type | `CacheFailure` (existing) | — |

## Decision 21: Packages (compatibility checked against Flutter 3.47.0 and the Dart constraint ^3.10.0)

| Package | Version | Supports | Why it is needed |
| --- | --- | --- | --- |
| `supabase_flutter` | `^2.17.2` | Dart ≥3.9, Flutter ≥3.35 ✅ | Requested. Provides auth, RPC and session refresh. |
| `connectivity_plus` | `^7.3.1` | Dart ≥3.2 ✅ | Connectivity hint (Decision 13). Nothing in the project does this today. |
| `flutter_secure_storage` | `^11.2.0` | Dart ≥3.8, Flutter ≥3.19 ✅ | Session tokens (constitution XII). `supabase_flutter` defaults to `shared_preferences`, which is not secure. |

- **Not added**:
  - `rxdart` (Decision 14);
  - `workmanager` (Decision 16);
  - `flutter_dotenv` / `envied` (Decision 12);
  - a logging package (Decision 18);
  - `internet_connection_checker` (Decision 13).
- **Transitive dependencies from `supabase_flutter`**: `app_links`, `url_launcher`, `shared_preferences`. These are acceptable. With the one-time-code flow no deep-link intent filter or URL scheme is configured.

## Decision 22: Platform configuration

- **Android**: `android/app/src/main/AndroidManifest.xml` has **no `INTERNET` permission** today; only debug and profile get it, through the Flutter templates. Add `<uses-permission android:name="android.permission.INTERNET"/>`. `ACCESS_NETWORK_STATE` is merged in by `connectivity_plus`. `minSdk` stays at `flutter.minSdkVersion`, which is compatible. No other change is needed.
- **iOS**:
  - The deployment target is 15.0, which all three packages support.
  - There is no `Podfile` (the project uses Swift Package Manager). The plan verifies that each new plugin resolves under SPM with `flutter build ios --no-codesign`. If one does not, Flutter falls back to CocoaPods and generates a Podfile. That is acceptable, but the change must be reviewed.
  - `flutter_secure_storage` uses the Keychain and needs no entitlements for the default access group.
  - No `Info.plist` change is needed: there are no URL schemes, and ATS already allows HTTPS.

## Decision 23: Testing tools

- **Dart**: in-memory `AppDatabase.forTesting(NativeDatabase.memory())` (existing pattern), `mocktail`, `bloc_test`, and a `FakeSyncRemote` implementing the `SyncRemoteDataSource` contract in memory. The fake reproduces the RPC semantics from `contracts/sync-rpc.md` so engine tests are deterministic.
- **Database**: Supabase CLI (`supabase start`, `supabase test db`) with pgTAP tests under `supabase/tests/`. These cover row-level security isolation, constraints, `sync_push` outcomes and the gap-free order of `sync_pull`. The CLI is **not installed** locally yet; it is a dev-only prerequisite listed in quickstart.
- **Device**: extend `integration_test/` with an offline-then-online flow that runs against a local Supabase stack.
