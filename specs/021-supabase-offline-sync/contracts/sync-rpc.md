# Contract: Sync RPCs (`sync_push`, `sync_pull`)

**Feature**: 021-supabase-offline-sync

Both functions are `language plpgsql security invoker set search_path = ''`. `execute` is granted to `authenticated` only and revoked from `public` and `anon`. They are called from Dart through `supabase.rpc(...)` with a 20 s timeout.

---

## 1. Wire shape of a record (`payload`)

The field names are the cloud column names in snake_case. The server fills `owner_id`, `revision` and `server_*` itself and ignores them if they are sent.

```jsonc
// money_transaction
{
  "id": "0b0c…", "idempotency_key": "9f1e…", "person_id": "5a2d…",
  "amount_minor": "150000",            // STRING: int64-safe (research Decision 17)
  "currency_code": "EGP", "direction": "given", "kind": "initialExchange",
  "occurred_at": "2026-09-27T09:12:00.000Z", "occurred_on": "2026-09-27", "tz_offset_minutes": 180,
  "note": null, "edited_at": null, "deleted_at": null,
  "client_created_at": "2026-09-27T09:12:03.120Z", "client_updated_at": "2026-09-27T09:12:03.120Z"
}
```

The other types map one to one from data-model.md §4. `people` never includes `avatar_path`.

## 2. `sync_push(p_device_id uuid, p_app_version text, p_platform text, p_ops jsonb) returns jsonb`

### Request

`p_ops` holds at most 100 operations, in client drain order:

```jsonc
[
  { "op_id": "uuid", "entity_type": "person|money_transaction|transaction_audit|finance_category|finance_entry|exchange_rate|primary_currency|conflict_resolution",
    "op_type": "upsert|delete", "entity_id": "text", "base_revision": 42 /* or null */, "payload": { … } }
]
```

### Response

The response has one result per operation, in the same order:

```jsonc
{ "results": [
    { "op_id": "uuid", "result": "applied",         "revision": 57 },
    { "op_id": "uuid", "result": "already_applied", "revision": 57 },
    { "op_id": "uuid", "result": "conflict",        "server_row": { … }, "revision": 55 },
    { "op_id": "uuid", "result": "superseded",      "server_row": { … }, "revision": 56 },
    { "op_id": "uuid", "result": "rejected",        "reason": "person_has_transactions|category_type_mismatch|missing_parent|validation|unknown_entity", "server_row": { … } /* present for person_has_transactions */ }
  ],
  "server_time": "2026-09-27T09:13:00Z" }
```

### Per-operation algorithm

Each operation runs inside its own `begin … exception … end` block, a sub-transaction, so that one bad operation never aborts the batch (FR-029):

```text
1. if exists sync_operations(owner, op_id) → return its stored result as "already_applied" (with revision/server_row).
2. current := select … from <table> where owner_id = uid and id = entity_id for update
3. case
   a. op_type = upsert and current is null:
        for money_transaction/finance_entry: if a row with the same idempotency_key exists → already_applied (return that row's revision)
        insert → applied
   b. op_type = upsert and current not null and base_revision is null:          -- "create" hitting an existing row
        financial: if the business fields equal current → already_applied, else conflict
        append-only types: already_applied
        LWW types: update → applied                                             (seed category / same rate pair from another device)
   c. op_type = upsert and base_revision = current.revision: update → applied
   d. op_type = upsert and base_revision <> current.revision:
        financial: conflict (no write)
        LWW types: update → applied   (server-accepted order wins, FR-037)
   e. op_type = delete (person, finance_category, exchange_rate):
        current is null or already deleted → already_applied
        base_revision <> current.revision → superseded (delete loses to a concurrent edit, FR-037b)
        finance_category with referencing entries → update is_archived = true → applied (server_row returned, FR-037d)
        otherwise update deleted_at = now() → applied (person guard trigger may raise → rejected person_has_transactions)
4. Undeleting: an upsert on an LWW row whose deleted_at is set clears deleted_at (a person or rate re-created with the same id / rate pair).
5. Exceptions: 23514/23502/22P02/P0001 → rejected(reason) ; 23503 (foreign-key violation: parent not uploaded yet) → rejected('missing_parent'), which the client treats as TRANSIENT and retries with backoff ; 42501 → re-raised (it fails the whole call → ForbiddenFailure client-side). A person_has_transactions rejection returns the current person row as server_row. A category delete converted to archive returns the archived row as server_row with result applied.
6. Insert into sync_operations(owner, op_id, entity_type, entity_id, result, revision, reason) — EXCEPT for rejected('missing_parent'), which is transient and must not be recorded; otherwise step 1 would replay the rejection forever.
7. After the loop: upsert devices(owner, p_device_id, p_platform, p_app_version, last_sync_at = now()).
```

**Idempotency proof**: replaying the same `op_id` hits step 1. Replaying the same business create under a *new* `op_id` hits 3a (idempotency key) or 3b (equal fields). Either way, the number of rows does not change.

## 3. `sync_pull(p_since bigint, p_limit int default 500) returns jsonb`

```jsonc
{ "changes": [
    { "entity_type": "person", "revision": 43, "row": { …full row incl. deleted_at… } },
    { "entity_type": "money_transaction", "revision": 44, "row": { … } }
  ],
  "max_revision": 44,     // the highest revision in this page (== p_since when empty)
  "has_more": true }
```

- The response is the `UNION ALL` of the 8 synced tables `where owner_id = auth.uid() and revision > p_since`, `order by revision limit p_limit`. It is backed by the `(owner_id, revision)` index on every table.
- Tombstones (`deleted_at` not null) are included.
- Causal order is kept, because a person's revision is always lower than the revision of any transaction created after it.

## 4. Client application of a pulled page (`SyncApplier`)

The whole page is applied in **one Drift transaction**. `sync_state.last_pulled_revision` is advanced to `max_revision` only at the end of that transaction (FR-021, FR-057). For each change:

| Local situation | Action |
| --- | --- |
| No local row | Insert it, and set meta to `synced` with the revision. |
| Local row, no open outbox operation | Overwrite the business fields (keep the local `avatarPath` for people) and set meta to `synced`. |
| Local row with an open outbox operation | **Skip** the business row: our pending operation carries its own `base_revision`, and the conflict is decided at push time. **Exception**: if that operation is `blocked_conflict`, update `sync_conflicts.server_payload_json` and `server_revision` to this newer row, so "keep theirs" never applies a stale version and "keep mine" uses the latest base. |
| Tombstone for a person, category or rate | Delete the local row, unless an outbox operation is open. |
| Tombstone for a transaction or entry | Set the local `deletedAt` (a soft delete, as the app already does). |
| A `seed_*` category, pristine locally | Overwrite it (research Decision 10). |

Rows applied here never create outbox entries. The `SyncApplier` writes through its own DAO methods, not the feature DAOs that record outbox entries.

## 5. Handling results on the client (`SyncEngine`)

| Result | Outbox | Meta | Other |
| --- | --- | --- | --- |
| `applied` / `already_applied` | Delete the row. | `synced`, and `server_revision = revision` | If `server_row` is present (a category archived instead of deleted), apply it locally through `SyncApplier` (the category is re-inserted as archived). |
| `conflict` | `blocked_conflict` | `conflict` | Insert a `sync_conflicts` row with both payloads. Log `SYNC_CONFLICT`. |
| `superseded` | Delete the row. | `synced` | Apply `server_row` locally (the record is restored). |
| `rejected` `person_has_transactions` | Delete the row. | `synced` | Re-insert the person from `server_row`. This is **required**, not "next pull": the cursor may already be past that revision. The Settings status shows "Couldn't delete; archive instead". |
| `rejected` `missing_parent` | Back to `pending` with backoff | unchanged | Transient: the parent is uploaded in an earlier rank or a later batch. |
| `rejected` (other) | `failed` with `error_code = reason` | `failed` | Shown in Settings with a Retry action. |
| Whole call fails (network, timeout, 5xx) | Every operation in the batch goes back to `pending` with backoff. | unchanged | `SYNC_RETRY` |
| Whole call fails with auth or 42501 | The batch goes back to `pending`, and the engine pauses until the session is valid. | unchanged | status `authRequired` |

## 6. Resolving a conflict (client, `ResolveSyncConflict` use case)

- **Keep mine**: enqueue an `upsert` with `base_revision = sync_conflicts.server_revision` and the local payload, plus a `conflict_resolution` insert with `chosen_side = 'local'` and `discarded_values` = the server row. The `blocked_conflict` operation is closed.
- **Keep theirs**: apply the server row locally, and enqueue a `conflict_resolution` with `chosen_side = 'server'` and `discarded_values` = the local payload. Close the blocked operation.

Both run in one Drift transaction, and `sync_conflicts.resolved_at` is set.
