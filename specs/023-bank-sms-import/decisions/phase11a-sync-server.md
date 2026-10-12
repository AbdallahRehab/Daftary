# Decisions: Phase 11a — sync server and legacy compatibility (T147, T148, T149, T151)

Slice owner: Phase 11a subagent. Files created (nothing existing was edited except checkboxes in tasks.md):

- `supabase/migrations/20261006100000_027_import_source.sql` (T147)
- `supabase/tests/027_import_source.test.sql` (T148)
- `test/core/sync/legacy/v101_mappers.dart`, `test/core/sync/legacy/v101_pull_compat_test.dart` (T149)

No `supabase db push` was run and no remote database was contacted. Migrations 021–026 are untouched (`git status` shows only the new files).

## Results

| Task | Status | Evidence |
|---|---|---|
| T147 | [X] | Generated mechanically from 026 lines 79–462 with two line-targeted substitutions; diff below shows only the two array additions plus the comment. Never executed against any Postgres (see T148). |
| T148 | **[ ] — written, NOT EXECUTED** | Docker is not running (`docker ps`: colima socket missing) and no local Postgres binaries exist, so `supabase test db` could not run. The test has never run; it must be run with a local stack (`supabase start && supabase test db`) before it counts. |
| T149 | [X] | `fvm flutter test test/core/sync/legacy`: 9/9 passed (local TZ, `TZ=UTC`, and `TZ=Pacific/Kiritimati`). `fvm dart format`: 0 changed. `fvm flutter analyze test/core/sync/legacy`: no issues. |
| T151 | [X] — no change | `.github/workflows/ci.yml:40-43` ("Test sync in UTC", `TZ: UTC`) already runs `flutter test … test/core/sync …`; `test/core/sync/legacy/` is a subdirectory, so the new tests already run in the UTC pass (and in the main `flutter test` step). Editing ci.yml would be redundant and ci.yml is a serialization hotspot (T105). |

Full `fvm flutter analyze` at the time of writing: 3 issues, all `unused_import` warnings in `lib/features/sms_import/domain/entities/sms_value_types.dart` (the other agent's in-progress file). None in this slice's files.

## Decisions

| # | Doc conflict or ambiguity | Choice | Why |
|---|---|---|---|
| 1 | Migration filename timestamp | Kept `20261006100000_027_import_source.sql`: it sorts after the latest existing migration `20261005100000_026_finance_entry_audits.sql`. No change needed. | Contract and task name this file. |
| 2 | Which grants to restate | Restated only the two `sync_push` lines, byte-identical to 026 `:731-732`. Did not restate `sync_pull`/`sync_pull_v2` grants or the audit-table grants. | 027 replaces only `sync_push`; the pull functions are not touched (contract §2.3), so their ACLs are unchanged. `create or replace` keeps ACLs anyway; the restatement follows the repo convention for the replaced function. |
| 3 | Column grants | None added. | 021 `:840-845` grants `select, insert, update` at table level on both tables, which covers new columns; `anon` was revoked on all tables at 021 `:824`. |
| 4 | "Comment naming 027" | Extended 026's `comment on function public.sync_push` text with "; 027 adds import_source to money_transaction and finance_entry." and added `comment on column` for both columns. Also a section banner and a header block in the file. | Contract §2.4. The function comment is part of the diff below; the function body itself differs only in the two arrays. |
| 5 | Sync-wire-027 §6 case 7 says the create retry "with the same op" returns `conflict` | **The doc is imprecise.** A retry with the SAME `op_id` is answered from the `sync_operations` ledger before any comparison (026 file lines `:240-263`), so it returns `already_applied` and the column stays null. Only the same create carried by a NEW `op_id` with no base revision reaches the "same create" comparison, which now includes `import_source` and returns `conflict`. The pgTAP test pins both (f1 same op → `already_applied`; f2 new op → `conflict` with `server_row.import_source = null`) plus a control (new op without the key → `already_applied`). | Test what the server actually does. The local outbox reuses `opId` on retry (`sync_outbox.dart:79`) and makes a new one only when it inserts a new op (`:96`), e.g. after an edit made while the create was in flight. Either way no data is lost; the binding deploy order (027 before 1.2.0) prevents both cases. |
| 6 | Check rejection shape | `import_source: 'x'` → `rejected` / `validation` via the existing `23%` branch of the exception handler; the batch continues. A direct `update … set import_source = 'wallet'` raises `23514` (`throws_ok`). | Contract §6.4 ("a validation rejection, not a crash"). |
| 7 | How v1.0.1 was frozen (T149) | Two plain classes `V101MoneyTransactionSyncMapper` / `V101FinanceEntrySyncMapper` holding the class constants and the `fromWire` bodies, plus a private `_V101Wire` with the 8 helpers + `_bad`. Edits to the copied text: `SyncWire.` → `_V101Wire.`, classes no longer extend `SyncMapper` (so no `@override`), and `dart format` re-wrapped the `parseMoney` line (longer identifier). Verified with a diff (below). | Discovery sync.md §2. Following the `egp_formatter_regression_test.dart` precedent (header naming the commit and source paths). |
| 8 | "Identical business values" | Each test compares the companion from a post-027 row (`import_source` = `'sms'` and = `null`, plus `future_field: 1`) to the companion from the same pre-027 row (Drift companion equality), and also checks each field against explicit expected values. An extra test shows v1.0.1 still throws on `source: 'sms'` (why provenance is a new column, not a `source` value). | Contract §6 client gate. |
| 9 | Discovery's optional extra assertion (a v1.0.1 apply keeps a local `'sms'` because the companion leaves `importSource` absent) | Not added. | The Drift `importSource` column doesn't exist yet (T146/T035 belong to the other agent). That assertion fits T150. |
| 10 | Fake server for case 7 (discovery-t007-t009 #6) | Not touched. `test/core/sync/fakes/fake_sync_remote.dart`'s financial business lists need `'import_source'` for a fake-side case-7 test. | That's T150's file, outside this slice. Flagged for T150's owner. |

## Proof: 026 `sync_push` vs 027 `sync_push`

Produced with `sed -n '79,462p'` of 026 (function + comment) against the same 384-line span of 027, then `diff -u`:

```diff
--- 026:sync_push
+++ 027:sync_push
@@ -105,7 +105,7 @@
         v_table := 'money_transactions'; v_policy := 'financial'; v_deletable := false;
         v_business := array['person_id','idempotency_key','amount_minor','currency_code','direction','kind',
                             'occurred_at','occurred_on','tz_offset_minutes','note','edited_at','deleted_at',
-                            'occasion_id','counts_toward_balance','source','ocr_scan_id'];
+                            'occasion_id','counts_toward_balance','source','ocr_scan_id','import_source'];
       when 'transaction_audit' then
         v_table := 'transaction_audit_entries'; v_policy := 'append'; v_deletable := false;
         v_business := array['transaction_id','change_type','previous_values','changed_at'];
@@ -115,7 +115,7 @@
       when 'finance_entry' then
         v_table := 'finance_entries'; v_policy := 'financial'; v_deletable := false;
         v_business := array['category_id','idempotency_key','type','amount_minor','currency_code',
-                            'occurred_at','occurred_on','tz_offset_minutes','note','edited_at','deleted_at'];
+                            'occurred_at','occurred_on','tz_offset_minutes','note','edited_at','deleted_at','import_source'];
       when 'exchange_rate' then
         v_table := 'exchange_rates'; v_policy := 'lww'; v_deletable := true;
         v_business := array['currency_code','relative_to_currency_code','rate_micros'];
@@ -381,4 +381,4 @@
 $$;
 
 comment on function public.sync_push(uuid, text, text, jsonb) is
-  'Applies up to 100 client outbox operations, one sub-transaction each. See specs/021-supabase-offline-sync/contracts/sync-rpc.md §2; 022 adds occasion, budget and budget_allocation; 023 adds savings_goal, savings_contribution and savings_contribution_audit; 026 adds finance_entry_audit.';
+  'Applies up to 100 client outbox operations, one sub-transaction each. See specs/021-supabase-offline-sync/contracts/sync-rpc.md §2; 022 adds occasion, budget and budget_allocation; 023 adds savings_goal, savings_contribution and savings_contribution_audit; 026 adds finance_entry_audit; 027 adds import_source to money_transaction and finance_entry.';
```

The revoke/grant pair for `sync_push` is byte-identical to 026 `:731-732` (`diff` of the two-line spans: no output).

## Proof: frozen `fromWire` vs `c86e2df`

`git show c86e2df:<mapper>` body, with `SyncWire.` → `_V101Wire.`, against the frozen copy (the closing `);` lines fall outside the extracted v1.0.1 range). Money transaction:

```diff
8c8,11
<     amountMinorUnits: _V101Wire.parseMoney(json['amount_minor'], 'amount_minor'),
---
>     amountMinorUnits: _V101Wire.parseMoney(
>       json['amount_minor'],
>       'amount_minor',
>     ),
```

Finance entry: the same single re-wrap (`9c9,12`). Class constants and all 9 helper bodies match v1.0.1 after whitespace normalization.

## Owner follow-ups

- Run `supabase start && supabase test db` (or the CI equivalent) and confirm `027_import_source.test.sql` passes before T148 is checked and before 027 is pushed.
- Deploy order stays 025 → 026 → app 1.1.0 → 027 → app 1.2.0 (contract §5). The user runs `supabase db push`.
