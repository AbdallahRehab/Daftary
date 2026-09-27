# Data Model: Offline-First Cloud Sync

**Feature**: 021-supabase-offline-sync | **Date**: 2026-09-27

This document describes three layers of data:

1. The existing business tables. Their business columns are not changed.
2. The new local sync tables, added by the Drift v9 migration.
3. The cloud tables. The DDL contract is in [contracts/supabase-schema.md](contracts/supabase-schema.md).

---

## 1. Entity sync matrix (verified against `app_database.dart`, v8)

| Entity (`entity_type`) | Local table | Id | Relationships | Create | Update | Delete | Archive | Local timestamps | Needs a cloud tombstone? | Conflict policy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `person` | `people` | UUID v4 text | 1→N `money_transactions` | `insertPerson` | `updatePerson` | **Hard** `deletePerson`, allowed only with 0 transactions | `setArchived` | `createdAt`, `updatedAt` | Yes (`deleted_at`) | Last write wins; delete loses to a concurrent edit; delete rejected if the person has transactions |
| `money_transaction` | `money_transactions` | UUID v4 plus unique `idempotencyKey` | N→1 person; 1→N audit | `insertTransactionIdempotent` | `updateTransaction` (+ audit) | **Soft** `softDelete` (+ audit) | — | `createdAt`, `editedAt`, `deletedAt`, `date` | Already soft | **Manual conflict** |
| `transaction_audit` | `transaction_audit_entries` | UUID v4 | N→1 transaction | `insertAuditEntry` | never | never | — | `changedAt` | No (append-only) | None |
| `finance_category` | `finance_categories` | UUID v4 or `seed_<key>` | 1→N entries | `insertCategory` | `updateCategory` | **Hard** `deleteCategory` | `archiveCategory` | `createdAt`, `updatedAt` | Yes | Last write wins; delete becomes archive while entries reference it |
| `finance_entry` | `finance_entries` | UUID v4 plus unique `idempotencyKey` | N→1 category | `insertEntryIdempotent` | `updateEntry` | **Soft** `softDeleteEntry` / `restoreEntry` | — | `createdAt`, `editedAt`, `deletedAt`, `date` | Already soft | **Manual conflict** |
| `exchange_rate` | `exchange_rates` | **`rate_<CUR>_<REL>`** (rewritten in v9) | none | `upsertRate` | `upsertRate` | **Hard** `deleteRatesFrom` (possibly several rows) | — | `lastUpdatedAt` | Yes | Last write wins by pair |
| `primary_currency` | `primary_currency_settings` | `'singleton'`; the cloud primary key is `owner_id` | none | `upsertPrimary` | `upsertPrimary` | never | — | `updatedAt` | No | Last write wins |
| `conflict_resolution` | **new** `conflict_resolutions` | UUID v4 | references entity type + id (no foreign key) | on resolve | never | never | — | `resolvedAt` | No | None |

**Local-only (never synced)**: `app_settings`, `onboarding_status`, `notification_preferences`, `notification_history`.

**Ownership**: local rows have no owner column, because the device has a single owner at a time. The owner is attached on the server from `auth.uid()` and is never sent by the client.

**Never uploaded**: `people.avatarPath` (device file path). A downloaded person keeps the local `avatarPath` if one exists, and otherwise gets `null`.

---

## 2. New local tables (Drift, schema v9)

### `sync_outbox`: pending operations (FR-024)

| Column | Type | Notes |
| --- | --- | --- |
| `op_id` | text PK | UUID v4, generated at enqueue. It is the idempotency key sent to the server. |
| `entity_type` | text | A value from the `entity_type` column in §1. |
| `entity_id` | text | |
| `op_type` | text | `upsert` or `delete`. |
| `payload_json` | text | The full row snapshot in the cloud wire shape (contracts/sync-rpc.md). Updated in place when operations are coalesced. |
| `base_revision` | int nullable | The server revision the local change was made against. `null` means the record has never been synced. |
| `depends_on_rank` | int | 0 = person or category, 1 = transaction or entry, 2 = audit or conflict resolution, 3 = rate or primary currency. |
| `status` | text | `pending`, `in_flight`, `failed`, `blocked_conflict`, `done` (rows are deleted when done). |
| `attempt_count` | int, default 0 | |
| `last_attempt_at` | int nullable | epoch ms |
| `next_attempt_at` | int nullable | epoch ms; null = eligible now |
| `error_code` | text nullable | A code only (for example `network`, `rls_denied`, `person_has_transactions`). Never contains record contents. |
| `created_at` | int | epoch ms, used for FIFO order |

Indexes:

- `idx_outbox_ready (status, depends_on_rank, created_at)`, used by the drain query;
- `idx_outbox_entity (entity_type, entity_id, status)`, used by coalescing and the pending lookup.

### `sync_record_meta`: per-record sync state (FR-008)

| Column | Type | Notes |
| --- | --- | --- |
| `entity_type`, `entity_id` | text, composite PK | |
| `server_revision` | int nullable | The last revision confirmed by the server. |
| `state` | text | `synced`, `pending`, `failed`, `conflict` |
| `last_synced_at` | int nullable | epoch ms |

Index: `idx_meta_state (state)`, which backs the status counts and the conflict badge.

### `sync_conflicts`: open manual conflicts (FR-035)

| Column | Type | Notes |
| --- | --- | --- |
| `id` | text PK | UUID |
| `entity_type`, `entity_id` | text | unique while open |
| `local_payload_json` | text | The local version the user edited. |
| `server_payload_json` | text | The server row returned by `sync_push`. |
| `server_revision` | int | The base revision to use for "keep mine". |
| `detected_at` | int | |
| `resolved_at` | int nullable | |

### `conflict_resolutions`: synced, append-only (Decision 8)

The columns are `id` (PK), `entity_type`, `entity_id`, `chosen_side` (`local` or `server`), `discarded_values_json`, and `resolved_at`.

### `sync_state`: single row with id `'singleton'` (FR-010, FR-060)

| Column | Type | Notes |
| --- | --- | --- |
| `enabled` | bool, default **true** | FR-041 |
| `notice_shown` | bool, default false | The one-time notice (Q2) |
| `owner_id` | text nullable | The `auth.uid()` the cursor belongs to. `null` → **adopt** the first uid with no re-enqueue, because the bootstrap already queued everything. A non-null value that changes → re-own (Decision 11). |
| `device_id` | text | UUID, generated on first run. |
| `last_pulled_revision` | int, default 0 | The single download cursor. |
| `bootstrap_enqueued` | bool, default false | Set to true **in the same transaction** that enqueues existing data. The only guard against a second bootstrap. |
| `initial_upload_done` | bool, default false | |
| `last_attempt_at`, `last_success_at` | int nullable | |
| `consecutive_failures` | int, default 0 | Drives backoff (it persists across triggers). |
| `last_error_code` | text nullable | |

### Business table indexes added in v9 (performance)

Existing indexes cover person history and the finance date and category lookups. v9 adds only:

- `idx_transactions_date (date, deleted_at)`, for overview and the future monthly queries;
- `idx_people_archived (is_archived, normalized_name)`, for the active and archived lists.

---

## 3. The v9 migration (inside `onUpgrade`, `from < 9`)

The steps run in order, inside the migration transaction Drift already uses:

1. `createTable` for `sync_outbox`, `sync_record_meta`, `sync_conflicts`, `conflict_resolutions` and `sync_state`, plus the two indexes above.
2. Rewrite the exchange-rate ids: `UPDATE exchange_rates SET id = 'rate_' || currency_code || '_' || relative_to_currency_code`. This is safe because the unique pair index guarantees there are no collisions and nothing references the id.
3. **Do not enqueue here.** A read that runs during a migration rolls it back (the precedent in `app_database.dart` `beforeOpen`). The flag `sync_state.initial_upload_done = false` is enough.
4. In `beforeOpen`, after the migration has committed and alongside the existing category seed, run `SyncBootstrap.enqueueExistingDataIfNeeded(db)`. It is idempotent:
   - It runs only while `sync_state.bootstrap_enqueued = false`. It must not rely on "no outbox rows exist": after a full upload that crashes before `initial_upload_done` is set, the outbox is empty but the data must not be enqueued again.
   - It inserts one `upsert` outbox row per existing row of every synced type, in dependency rank order, with `base_revision = null`. It skips pristine seed categories (Decision 10).
   - It inserts `sync_record_meta(state = 'pending')` for each of those rows.
   - It sets `bootstrap_enqueued = true`. All of this happens in **one Drift transaction**, so a crash either leaves nothing (and it re-runs on the next open) or leaves everything.
5. On a fresh install, `onCreate` creates all the tables, and the seed runs with no enqueue.

Rollback: if step 1 or 2 throws, Drift's migration transaction rolls back to v8 and the app opens with the v8 data. This matches the existing practice for 007 and 020.

---

## 4. Cloud tables (summary; full DDL is in contracts/supabase-schema.md)

Every synced table shares these columns:

- `owner_id uuid not null default auth.uid() references auth.users on delete cascade`;
- `id text not null`, with **primary key `(owner_id, id)`**;
- `revision bigint not null`;
- `client_created_at timestamptz`, `client_updated_at timestamptz`;
- `server_created_at timestamptz default now()`, `server_updated_at timestamptz default now()`;
- `deleted_at timestamptz`;
- `last_device_id uuid`;
- the index `(owner_id, revision)`.

| Cloud table | Business columns | Extra constraints and indexes |
| --- | --- | --- |
| `people` | `name text not null`, `normalized_name text not null`, `phone_number text`, `relationship_tag text`, `notes text`, `is_archived bool not null default false` | `(owner_id, is_archived)` |
| `money_transactions` | `person_id text not null`, `idempotency_key text not null`, `amount_minor bigint not null check (> 0)`, `currency_code char(3) not null`, `direction text check in ('given','received')`, `kind text check in ('initialExchange','repayment')` (the existing local values), `occurred_at timestamptz not null`, `occurred_on date not null`, `tz_offset_minutes smallint not null`, `note text`, `edited_at timestamptz` | FK `(owner_id, person_id) → people`; unique `(owner_id, idempotency_key)`; `(owner_id, person_id)`; `(owner_id, occurred_on)` |
| `transaction_audit_entries` | `transaction_id text not null`, `change_type text not null`, `previous_values jsonb`, `changed_at timestamptz not null` | FK → `money_transactions`; `(owner_id, transaction_id)` |
| `finance_categories` | `name`, `normalized_name`, `type check in ('income','expense')`, `icon_key text`, `is_default bool`, `is_archived bool` | `(owner_id, type)` |
| `finance_entries` | `category_id text not null`, `idempotency_key`, `type`, `amount_minor bigint check (> 0)`, `currency_code char(3)`, `occurred_at`, `occurred_on`, `tz_offset_minutes`, `note`, `edited_at` | FK → categories; unique `(owner_id, idempotency_key)`; `(owner_id, occurred_on)`; `(owner_id, category_id)` |
| `exchange_rates` | `currency_code char(3)`, `relative_to_currency_code char(3)`, `rate_micros bigint check (> 0)` | unique `(owner_id, currency_code, relative_to_currency_code)` |
| `primary_currency` | `currency_code char(3)` | the `id` is always `'singleton'` |
| `conflict_resolutions` | `entity_type`, `entity_id`, `chosen_side`, `discarded_values jsonb`, `resolved_at` | insert-only |

**Server-only tables**:

- `sync_owner_state(owner_id pk, last_revision bigint)`: the per-owner revision counter (Decision 4).
- `sync_operations(owner_id, op_id uuid, result text, revision bigint, applied_at)`: the operation ledger (Decision 6), primary key `(owner_id, op_id)`.
- `devices(owner_id, device_id, platform, app_version, first_seen_at, last_sync_at)`: diagnostics (FR-064), primary key `(owner_id, device_id)`.

---

## 5. State transitions

### Outbox operation

```text
            enqueue / coalesce
                   │
                   ▼
   ┌──────────► pending ──── drain picks it ────► in_flight
   │               ▲                                  │
   │  backoff due  │                                  ├─ applied / already_applied ─► (row deleted; meta = synced, revision stored)
   │               │                                  ├─ transient failure ─► pending (+attempt, next_attempt_at)
   │           failed ◄── "Retry" in Settings ────────├─ permanent failure ─► failed (error_code)
   │                                                  ├─ conflict ─► blocked_conflict (+ sync_conflicts row; meta = conflict)
   │                                                  ├─ superseded ─► (row deleted; the server row is applied locally)
   │                                                  └─ rejected (rule) ─► (row deleted; the local record is restored from the server)
   │
   └── app restarts with rows in in_flight ─► reset to pending (the ledger makes the replay safe)
```

### Record meta

```text
synced ──local write──► pending ──ack──► synced
pending ──permanent fail──► failed ──retry ok──► synced
pending ──conflict──► conflict ──user resolves──► pending ──ack──► synced
```

### Coalescing rules (FR-025), applied when enqueuing onto an entity that already has a `pending` operation (never one that is `in_flight`)

| Existing pending operation | New operation | Result |
| --- | --- | --- |
| upsert | upsert | Replace the payload; keep `op_id` and `base_revision`. |
| upsert with `base_revision = null` (never synced), for a person, category or rate | delete | **Drop both.** The server never saw the record. |
| upsert with `base_revision = null`, for a transaction or entry | soft delete | This is an upsert with `deleted_at` set, so it is coalesced as upsert + upsert. The record still reaches the cloud (FR-025). |
| upsert | delete (a record the server already has) | Replace it with a delete, keeping `base_revision`. |
| any | audit or conflict-resolution insert | Never coalesced. |

---

## 6. Analytics data layers (spec FR-061 to FR-064)

| Layer | Where | Purpose |
| --- | --- | --- |
| **Business data** | the 8 cloud business tables | The source for every financial statistic. |
| **Operational sync metadata** | `revision`, `client_*_at`, `server_*_at`, `last_device_id`, `sync_operations`, `devices` | Diagnosing sync and measuring offline activity (`server_created_at − client_created_at`). |
| **Optional product analytics** | *none collected.* `devices.last_sync_at` and `app_version` are the only usage signals. | There is no behavioral tracking (FR-064). |

The owner-scoped views (`security_invoker = true`) are defined in contracts/supabase-schema.md §Views:

- `v_monthly_person_flows`
- `v_person_balances`
- `v_monthly_finance_by_category`
- `v_daily_activity`
