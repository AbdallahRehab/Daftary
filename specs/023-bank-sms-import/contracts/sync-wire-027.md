# Contract: Sync Wire and Server Migration 027 (`import_source`)

**Feature**: 023 Bank SMS Import · **Research**: Decision 10 · **Requirements**: FR-057, FR-083, FR-085, FR-086, FR-087, FR-088, SC-012; Data Model Impact "Provenance"; Sync architecture impact

Staging data never syncs (FR-085). The **only** sync change is one optional provenance field on the two synced aggregates that an SMS Add can create: `money_transactions` (people ledger) and `finance_entries` (own income/expense). It is **not** a new value of `source`, `kind` or `direction`: `money_transaction_sync_mapper.dart` reads `source` with `SyncWire.oneOf(json, 'source', sources)`, which throws on an unknown value, so every v1.0.1 device would fail its pull (a 022-class P0). A new nullable key is ignored by v1.0.1 mappers, which read named keys only.

## 1. The wire field

| Property | Value |
|---|---|
| Key | `import_source` |
| Entities | `money_transaction`, `finance_entry` (no other entity type; audits are unchanged) |
| JSON type | `string` or absent |
| Allowed values (server check) | `'sms'` |
| Absent / `null` | Not imported (FR-057). Every existing row |
| Direction | push (client -> server) and pull (server -> client) |
| Content | A fixed token. No SMS-derived text, no fingerprint, no bank, no reference (FR-088) |

Push example (1.2 client, SMS-sourced own expense; unchanged keys elided):

```json
{ "id": "...", "idempotency_key": "sms-import:7f3c...", "category_id": "...",
  "type": "expense", "amount_minor": 12550, "currency_code": "EGP",
  "occurred_on": "2026-03-04", "note": null, "import_source": "sms", "...": "..." }
```

A people-ledger SMS import carries `"source": "manual"` and `"import_source": "sms"` (FR-086).

## 2. Server migration 027

File: `supabase/migrations/20261006100000_027_import_source.sql` (additive; after `20261005100000_026_finance_entry_audits.sql`; applied migrations are never edited).

1. **Columns**:
   - `alter table public.money_transactions add column import_source text check (import_source in ('sms'));`
   - `alter table public.finance_entries add column import_source text check (import_source in ('sms'));`
   - Nullable, no default, no backfill, no index. Grants in 021 are table-level, so the new columns are covered (`021_offline_sync.sql:832-846`). RLS policies are row-scoped and unchanged.
2. **`sync_push`**: `create or replace function public.sync_push(...)` = **026's body verbatim** with `'import_source'` appended to the `v_business` arrays of the `money_transaction` and `finance_entry` branches (026 lines ~185-196). Nothing else changes: no policy, ledger, conflict or version-gating logic (the `app_version_at_least` gating from 025 is untouched). Because `v_cols` is "writable columns present in the payload" (026 `:283-286`) and unknown keys are silently ignored, a payload with or without the key is valid in every combination.
3. **`sync_pull` / `sync_pull_v2`**: **no change.** They return `to_jsonb(t)` per table (026 `:497,512,623,638`), so the new column is emitted automatically as `null` or `'sms'`.
4. A comment on `sync_push` naming 027 and a `comment on column` for both columns ("provenance of the row; 'sms' = created from an on-device bank message import; no message content").
5. **Rollback**: re-apply 026's `sync_push` body in a new migration (027 never drops the columns; a rollback leaves harmless nullable columns).

Future provenance values (for example `'wallet'`) require a **new migration extending the check** before any app version that writes them ships.

## 3. Client changes (1.2.0)

| Place | Change |
|---|---|
| Drift | `import_source` text null on both tables (data-model.md 4.6) |
| `MoneyTransactionSyncMapper.toWire` / `FinanceEntrySyncMapper.toWire` | Add `'import_source': row.importSource` **only when non-null** (spread `if (row.importSource != null)`), so the existing exact-shape tests stay valid and a null never travels over a set value |
| `fromWire` (both) | `importSource: Value((json['import_source'] as String?) ?? existingLocal?.importSource)`: a non-null local value is never downgraded to null, whether the key is absent (server predating 027) or present but null (a pre-027 row pulled after 027, or `keepTheirs`). Provenance is never legitimately cleared. `sync_applier.dart:154` already passes `existingLocal`. Unknown strings are stored as-is (domain `ImportProvenance.unknown`) |
| `SyncWire` | A tiny `SyncWire.stringOrNull` reuse; no new helper |
| `sync_entity_type.dart` | **No change**: no new entity type (a new type would make v1.0.1's `fromWire` throw) |
| Edits | `editTransaction` / `editEntry` do not touch the column, and an edit's push re-sends the existing non-null value (harmless, same value) |

## 4. Backward compatibility guarantees (v1.0.1 and later)

| Scenario | Guarantee | Why |
|---|---|---|
| v1.0.1 pulls a row with `import_source: 'sms'` | No throw; business values identical | v1.0.1 mappers read named keys only (`money_transaction_sync_mapper.dart:50-85`, `finance_entry_sync_mapper.dart:36-60`); the extra key is never read |
| v1.0.1 pushes an edit of an SMS-sourced row (payload has no `import_source`) | Server column left intact | `sync_push` updates only payload-present writable columns |
| v1.0.1 pushes a new row | Column stays `null` | no key |
| 1.2 pushes to a server **without** 027 | Push succeeds; `import_source` is silently dropped; the record syncs without provenance | unknown payload keys ignored by the whitelist |
| 1.2 pulls from a server without 027 | Row has no key; local provenance preserved | `fromWire` keeps `existingLocal.importSource` |
| 027 applied, app not yet shipped | No effect | optional column |
| Deploy order | 027 adds no ordering constraint beyond 026's; 1.1+ clients require 026 (`sync_pull_v2`) | no enum value added, no new entity, no required column |
| Mixed fleet, same account | The "Imported from a bank message" label appears only on 1.2+ devices; the underlying record is identical everywhere | v1.0.1 ignores the key |
| Another cloud client or analytics view | Sees one extra nullable column | FR-100: owner-scoped views gain nothing beyond user-confirmed values and provenance |

**Cosmetic consequence if the order is violated** (app before 027): rows saved in that window lack provenance on other devices (no label there; the duplicate warning loses only the "same bank, different reference" nuance for them). No data is lost. An optional repair (re-enqueue rows with non-null `import_source` once after 027, using the `sync_state` flag pattern of `b1_repull_done`) is **not built in v1**.

## 5. Deploy order (binding)

**025 -> 026 -> (1.1.0, 022) -> 027 -> app that writes provenance (1.2.0)**.

- 027 depends on nothing in 025/026 beyond the text of the `sync_push` function it replaces, so all three go in one `supabase db push` (run by the user) and the app ships afterwards.
- If 025/026 are not yet pushed when 027 is, `create or replace function` in 027 must be based on 026's body (the file in the repo), never on the older live definition; the migration is generated from `20261005100000_026_finance_entry_audits.sql`.
- Add 027 to `quickstart.md` ("Deploy") and the release checklist; update the Supabase deploy-state note after the user confirms the push.
- Before tagging 1.2.0, verify against the target project: `select column_name from information_schema.columns where table_name in ('money_transactions','finance_entries') and column_name = 'import_source'` returns two rows.

## 6. Tests (the compatibility test and its companions)

**Server (pgTAP)** `supabase/tests/027_import_source.test.sql` (pattern of `021_rls.test.sql`):

1. Upsert with `import_source: 'sms'` persists on both tables.
2. A **v1.0.1-shaped** update payload (no `import_source` key) leaves the column intact on both tables.
3. Pre-existing rows read `null`.
4. The check rejects `'x'` (error surfaced as a validation rejection, not a crash).
5. `sync_pull` and `sync_pull_v2` output contains the key with `'sms'` / `null`.
6. RLS: another owner cannot read or write the row (unchanged; asserted for the new column).
7. **Create retry spanning the deploy** (analysis L6): a row created before 027 (key dropped, column `null`) and then retried after 027 with the same op and `import_source: 'sms'` and no base revision. Expected and documented outcome: the "same create" comparison differs only on `import_source`, so the server answers `conflict`. This is narrow (it needs a lost acknowledgement across the deploy) and harmless (the user resolves it with no data loss). The binding deploy order (027 before v1.2.0) prevents it in practice; the test pins the behavior so a future change is deliberate.

**Client compatibility test (the gate)**:

- `test/core/sync/legacy/v101_mappers.dart`: a **frozen verbatim copy** of the two v1.0.1 `fromWire` bodies (from commit `c86e2df`) **together with the `SyncWire` helpers they call** (v1.0.1 uses `SyncWire.parseInstant(json['occurred_at'])`, current code `parseLocalDay`), never edited, so the test does not silently run current semantics.
- `test/core/sync/legacy/v101_pull_compat_test.dart`: feeds a post-027 `to_jsonb`-shaped JSON for each aggregate with `import_source: 'sms'` and an invented future key (`future_field: 1`) and asserts no throw and identical business values (id, amount, currency, date, note, ...).
- `test/core/sync/import_source_mapper_test.dart`: `toWire` omits the key when null and includes it when `'sms'`; `fromWire` with the key present sets it, with the key absent keeps `existingLocal.importSource`, with the key present and null keeps a local `'sms'` (also through `ConflictResolver.keepTheirs`); unknown strings round-trip.
- Two-device test on the existing `SyncHarness` / `FakeSyncRemote` (pattern of `sync_log_scrub_test.dart`): device A saves an SMS-sourced row, device B pulls it and exposes provenance; a legacy-shaped edit-and-push leaves the field intact on the fake server.
- Scrub test: the real `SyncOutbox` payload after an SMS Add contains only user-confirmed fields plus `import_source`; `note` is null unless the user typed one; no fingerprint, merchant text copied into note, sender or bank (FR-088); the sentinel strings of the privacy leak test never appear.
- `ci.yml` re-runs the new legacy test directory under the UTC sync run (existing `ci.yml:43` pattern).

## 7. Out of scope (explicit)

No server table for staging, tombstones, mutes or mappings; no sync of settings; no change to `sync_pull_v2` types; no audit-source column (the `created` audit row plus `import_source` identify the source, data-model.md section 9); no `source` enum change; no backfill of existing rows.
