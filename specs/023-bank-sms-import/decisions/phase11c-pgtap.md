# Phase 11c: pgTAP for migration 027 (T148) and T147 acceptance check

## T147 acceptance: diff of the sync_push bodies
I pulled the `create or replace function public.sync_push(` … `$$;` block out of the 026 and 027 migrations (381 lines each) and diffed them. They differ in two lines only:
- line 108 (`money_transaction` branch): `…,'source','ocr_scan_id'` → `…,'source','ocr_scan_id','import_source'`
- line 118 (`finance_entry` branch): `…,'edited_at','deleted_at'` → `…,'edited_at','deleted_at','import_source'`

T147 acceptance is met.

## T148 test file
An interrupted run had already written `supabase/tests/027_import_source.test.sql`. I reviewed it against the migrations, the contract and the 021/026 test conventions (`begin`/`no_plan`/`finish`/`rollback`, `pg_temp` helpers, JWT claims login). It already covered (a)–(f), the schema, RLS and privileges. I made no edits.

## Run (local only)
- Docker (colima) was installed but not running. I started colima, then `supabase start`. The local DB already had 021–026 applied. I applied 027 to the **local** DB with `supabase migration up --local`. Nothing was linked or pushed, and no remote DB was touched.
- `supabase test db --local`: Files=10, Tests=383, Result: PASS. 027 alone: 67/67 ok.
- Afterwards I ran `supabase stop` and `colima stop`, which put things back as they were.

## Interpretation decisions
- **§6 case 7 ("same op")**: if the retry reuses the same `op_id`, the operation ledger answers it before any comparison runs, so the result is `already_applied`, not `conflict`. A conflict only happens when the same create arrives under a **new** `op_id` with no base revision, for example after an outbox re-enqueue. The test pins both outcomes (f1 `already_applied`, f2 `conflict` with `server_row.import_source = null`, no write), plus a keyless control that returns `already_applied`. The control proves `import_source` alone causes the conflict. The contract wording "same op" should be read as "same create".
- **Keyless legacy create replay of an sms row** returns `already_applied`, because the comparison only covers columns present in the payload. The test asserts this too.
