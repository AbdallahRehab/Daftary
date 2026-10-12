-- 027: import_source provenance (023 bank SMS import,
-- specs/023-bank-sms-import/contracts/sync-wire-027.md §6, task T148).
-- sync_push writes the optional key on money_transaction and finance_entry,
-- a v1.0.1-shaped payload (no key) leaves it intact, older rows read null,
-- the check refuses any other value, both pull functions emit the key, RLS is
-- unchanged, and a create retry spanning the deploy is pinned.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into auth.users (id, aud, role, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'a@example.test'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'authenticated', 'authenticated', 'b@example.test');

-- Push responses are kept here so later assertions can reference them.
create temp table r (k text primary key, v jsonb);
grant all on r to public;

create function pg_temp.login(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

-- One operation envelope.
create function pg_temp.op(p_op_id text, p_type text, p_op text, p_id text, p_base bigint, p_payload jsonb)
returns jsonb language sql as $$
  select jsonb_build_object('op_id', p_op_id, 'entity_type', p_type, 'op_type', p_op,
                            'entity_id', p_id, 'base_revision', p_base, 'payload', p_payload)
$$;

-- Push a batch, store the response under p_key, return it.
create function pg_temp.push(p_key text, p_ops jsonb) returns jsonb language plpgsql as $$
declare v jsonb;
begin
  v := public.sync_push('d0d0d0d0-0000-4000-8000-000000000001', '1.2.0', 'android', p_ops);
  insert into r values (p_key, v) on conflict (k) do update set v = excluded.v;
  return v;
end $$;

create function pg_temp.res(p_key text, p_i int default 0) returns jsonb language sql as $$
  select v -> 'results' -> p_i from r where k = p_key
$$;

create function pg_temp.person(p_name text) returns jsonb language sql as $$
  select jsonb_build_object('name', p_name, 'normalized_name', lower(p_name),
    'phone_number', null, 'relationship_tag', null, 'notes', null, 'is_archived', false)
$$;

-- A v1.0.1-shaped transaction payload: no import_source key. Money arrives as
-- a STRING, as every client sends it.
create function pg_temp.tx(p_key text, p_amount text) returns jsonb language sql as $$
  select jsonb_build_object('person_id', 'p1', 'idempotency_key', p_key,
    'amount_minor', p_amount, 'currency_code', 'EGP', 'direction', 'given', 'kind', 'initialExchange',
    'occurred_at', '2026-10-06T09:12:00.000Z', 'occurred_on', '2026-10-06', 'tz_offset_minutes', 180,
    'note', null, 'edited_at', null, 'deleted_at', null,
    'occasion_id', null, 'counts_toward_balance', true, 'source', 'manual', 'ocr_scan_id', null,
    'client_created_at', '2026-10-06T09:12:03.120Z', 'client_updated_at', '2026-10-06T09:12:03.120Z')
$$;

-- A v1.0.1-shaped finance entry payload: no import_source key.
create function pg_temp.entry(p_key text, p_amount text) returns jsonb language sql as $$
  select jsonb_build_object('category_id', 'c1', 'idempotency_key', p_key, 'type', 'expense',
    'amount_minor', p_amount, 'currency_code', 'EGP',
    'occurred_at', '2026-10-06T09:12:00.000Z', 'occurred_on', '2026-10-06', 'tz_offset_minutes', 180,
    'note', null, 'edited_at', null, 'deleted_at', null,
    'client_created_at', '2026-10-06T09:12:03.120Z', 'client_updated_at', '2026-10-06T09:12:03.120Z')
$$;

-- The pulled row of one record, from sync_pull or sync_pull_v2 output.
create function pg_temp.pulled(p_page jsonb, p_type text, p_id text) returns jsonb language sql as $$
  select c -> 'row' from jsonb_array_elements(p_page -> 'changes') c
   where c ->> 'entity_type' = p_type and c -> 'row' ->> 'id' = p_id
$$;

-- ---------------------------------------------------------------------------
-- Schema: a nullable text column with no default on both tables.
-- ---------------------------------------------------------------------------
select has_column('public', 'money_transactions', 'import_source', 'money_transactions.import_source exists');
select col_type_is('public', 'money_transactions', 'import_source', 'text', 'money_transactions.import_source is text');
select col_is_null('public', 'money_transactions', 'import_source', 'money_transactions.import_source is nullable');
select col_hasnt_default('public', 'money_transactions', 'import_source', 'money_transactions.import_source has no default');
select has_column('public', 'finance_entries', 'import_source', 'finance_entries.import_source exists');
select col_type_is('public', 'finance_entries', 'import_source', 'text', 'finance_entries.import_source is text');
select col_is_null('public', 'finance_entries', 'import_source', 'finance_entries.import_source is nullable');
select col_hasnt_default('public', 'finance_entries', 'import_source', 'finance_entries.import_source has no default');
select ok(obj_description('public.sync_push(uuid, text, text, jsonb)'::regprocedure, 'pg_proc') like '%027 adds import_source%',
  'the sync_push comment names 027');

select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');

-- Parents.
select pg_temp.push('parents', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000001', 'person', 'upsert', 'p1', null, pg_temp.person('Ahmed')),
  pg_temp.op('00000000-0000-4000-8000-000000000002', 'finance_category', 'upsert', 'c1', null,
    jsonb_build_object('name', 'Groceries', 'normalized_name', 'groceries', 'type', 'expense',
                       'icon_key', 'cart', 'is_default', false, 'is_archived', false))));
select is(pg_temp.res('parents', 0) ->> 'result', 'applied', 'person parent applied');
select is(pg_temp.res('parents', 1) ->> 'result', 'applied', 'category parent applied');

-- ---------------------------------------------------------------------------
-- (c) Rows without the key (written by v1.0.1, or before 027) read null.
-- ---------------------------------------------------------------------------
select pg_temp.push('old', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000010', 'money_transaction', 'upsert', 't_old', null,
             pg_temp.tx('k_old', '1000')),
  pg_temp.op('00000000-0000-4000-8000-000000000011', 'finance_entry', 'upsert', 'e_old', null,
             pg_temp.entry('ke_old', '2000'))));
select is(pg_temp.res('old', 0) ->> 'result', 'applied', 'a transaction without the key: applied');
select is(pg_temp.res('old', 1) ->> 'result', 'applied', 'an entry without the key: applied');
select is((select import_source from public.money_transactions where id = 't_old'), null,
  'a transaction without the key reads null');
select is((select import_source from public.finance_entries where id = 'e_old'), null,
  'an entry without the key reads null');

-- ---------------------------------------------------------------------------
-- (a) An upsert with import_source = 'sms' persists on both tables.
-- A people-ledger import keeps source = 'manual' (FR-086).
-- ---------------------------------------------------------------------------
select pg_temp.push('sms', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000020', 'money_transaction', 'upsert', 't_sms', null,
             pg_temp.tx('k_sms', '12550') || '{"import_source": "sms"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000021', 'finance_entry', 'upsert', 'e_sms', null,
             pg_temp.entry('ke_sms', '12550') || '{"import_source": "sms"}')));
select is(pg_temp.res('sms', 0) ->> 'result', 'applied', 'an SMS-sourced transaction: applied');
select is(pg_temp.res('sms', 1) ->> 'result', 'applied', 'an SMS-sourced entry: applied');
select is((select import_source from public.money_transactions where id = 't_sms'), 'sms',
  'the transaction stores import_source = sms');
select is((select source from public.money_transactions where id = 't_sms'), 'manual',
  'the transaction source stays manual');
select is((select import_source from public.finance_entries where id = 'e_sms'), 'sms',
  'the entry stores import_source = sms');

-- ---------------------------------------------------------------------------
-- (b) A v1.0.1-shaped edit (current base revision, no import_source key)
-- updates the business values and leaves the column intact.
-- ---------------------------------------------------------------------------
select pg_temp.push('legacy_edit', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000030', 'money_transaction', 'upsert', 't_sms',
             (pg_temp.res('sms', 0) ->> 'revision')::bigint,
             pg_temp.tx('k_sms', '13000') || '{"edited_at": "2026-10-06T10:00:00Z", "note": "edited"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000031', 'finance_entry', 'upsert', 'e_sms',
             (pg_temp.res('sms', 1) ->> 'revision')::bigint,
             pg_temp.entry('ke_sms', '13000') || '{"edited_at": "2026-10-06T10:00:00Z", "note": "edited"}')));
select is(pg_temp.res('legacy_edit', 0) ->> 'result', 'applied', 'a legacy transaction edit: applied');
select is(pg_temp.res('legacy_edit', 1) ->> 'result', 'applied', 'a legacy entry edit: applied');
select is((select amount_minor from public.money_transactions where id = 't_sms'), 13000::bigint,
  'the legacy edit is written (transaction)');
select is((select amount_minor from public.finance_entries where id = 'e_sms'), 13000::bigint,
  'the legacy edit is written (entry)');
select is((select import_source from public.money_transactions where id = 't_sms'), 'sms',
  'a legacy edit leaves the transaction import_source intact');
select is((select import_source from public.finance_entries where id = 'e_sms'), 'sms',
  'a legacy edit leaves the entry import_source intact');

-- A 1.2 edit re-sends the same value: harmless.
select pg_temp.push('new_edit', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000032', 'finance_entry', 'upsert', 'e_sms',
             (pg_temp.res('legacy_edit', 1) ->> 'revision')::bigint,
             pg_temp.entry('ke_sms', '14000') || '{"edited_at": "2026-10-06T11:00:00Z", "import_source": "sms"}')));
select is(pg_temp.res('new_edit') ->> 'result', 'applied', 'a 1.2 edit re-sending the value: applied');
select is((select import_source from public.finance_entries where id = 'e_sms'), 'sms',
  'the re-sent value is unchanged');

-- A legacy create replay of an SMS-sourced row (no key, no base, equal
-- business values) is still the "same create": the comparison covers only the
-- columns present in the payload.
select pg_temp.push('legacy_replay', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000033', 'money_transaction', 'upsert', 't_sms', null,
             pg_temp.tx('k_sms', '13000') || '{"edited_at": "2026-10-06T10:00:00Z", "note": "edited"}')));
select is(pg_temp.res('legacy_replay') ->> 'result', 'already_applied',
  'a keyless create replay of an sms row: already_applied');

-- ---------------------------------------------------------------------------
-- (d) The check refuses any other value: a validation rejection, not a crash,
-- and the batch continues.
-- ---------------------------------------------------------------------------
select pg_temp.push('bad', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000040', 'money_transaction', 'upsert', 't_bad', null,
             pg_temp.tx('k_bad', '100') || '{"import_source": "x"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000041', 'finance_entry', 'upsert', 'e_bad', null,
             pg_temp.entry('ke_bad', '100') || '{"import_source": "x"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000042', 'finance_entry', 'upsert', 'e_ok', null,
             pg_temp.entry('ke_ok', '100'))));
select is(pg_temp.res('bad', 0) ->> 'result', 'rejected', 'transaction import_source x: rejected');
select is(pg_temp.res('bad', 0) ->> 'reason', 'validation', 'transaction import_source x: reason validation');
select is(pg_temp.res('bad', 1) ->> 'result', 'rejected', 'entry import_source x: rejected');
select is(pg_temp.res('bad', 1) ->> 'reason', 'validation', 'entry import_source x: reason validation');
select is(pg_temp.res('bad', 2) ->> 'result', 'applied', 'the next operation in the batch still applies');
select is((select count(*) from public.money_transactions where id = 't_bad'), 0::bigint, 'the bad transaction is not written');
select is((select count(*) from public.finance_entries where id = 'e_bad'), 0::bigint, 'the bad entry is not written');
select throws_ok(
  $$update public.money_transactions set import_source = 'wallet' where id = 't_sms'$$,
  '23514', null, 'a direct write of an unknown value violates the check');

-- ---------------------------------------------------------------------------
-- (e) Both pull functions emit the key: 'sms' for the imported rows, null
-- (present, not absent) for the others.
-- ---------------------------------------------------------------------------
create temp table pages as
  select public.sync_pull(0, 1000) as v1, public.sync_pull_v2(0, 1000) as v2;
grant all on pages to public;

select is((select pg_temp.pulled(v1, 'money_transaction', 't_sms') ->> 'import_source' from pages), 'sms',
  'sync_pull: the imported transaction carries sms');
select is((select pg_temp.pulled(v1, 'finance_entry', 'e_sms') ->> 'import_source' from pages), 'sms',
  'sync_pull: the imported entry carries sms');
select ok((select pg_temp.pulled(v1, 'money_transaction', 't_old') ? 'import_source' from pages),
  'sync_pull: an old transaction has the key');
select is((select pg_temp.pulled(v1, 'money_transaction', 't_old') -> 'import_source' from pages), 'null'::jsonb,
  'sync_pull: an old transaction has import_source null');
select is((select pg_temp.pulled(v1, 'finance_entry', 'e_old') -> 'import_source' from pages), 'null'::jsonb,
  'sync_pull: an old entry has import_source null');
select is((select pg_temp.pulled(v2, 'money_transaction', 't_sms') ->> 'import_source' from pages), 'sms',
  'sync_pull_v2: the imported transaction carries sms');
select is((select pg_temp.pulled(v2, 'finance_entry', 'e_sms') ->> 'import_source' from pages), 'sms',
  'sync_pull_v2: the imported entry carries sms');
select is((select pg_temp.pulled(v2, 'money_transaction', 't_old') -> 'import_source' from pages), 'null'::jsonb,
  'sync_pull_v2: an old transaction has import_source null');
select is((select pg_temp.pulled(v2, 'finance_entry', 'e_old') -> 'import_source' from pages), 'null'::jsonb,
  'sync_pull_v2: an old entry has import_source null');
select is((select pg_temp.pulled(v1, 'money_transaction', 't_sms') ->> 'source' from pages), 'manual',
  'sync_pull: the source enum is unchanged (v1.0.1 reads it with oneOf)');

-- ---------------------------------------------------------------------------
-- (f) Create retry spanning the deploy (sync-wire-027 §6 case 7). A 1.2 create
-- reached the server before 027 (the key was dropped, the column is null)
-- and its acknowledgement was lost. A keyless create stands in for that
-- pre-027 write.
-- ---------------------------------------------------------------------------
select pg_temp.push('span', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000050', 'money_transaction', 'upsert', 't_span', null,
             pg_temp.tx('k_span', '5000')),
  pg_temp.op('00000000-0000-4000-8000-000000000051', 'finance_entry', 'upsert', 'e_span', null,
             pg_temp.entry('ke_span', '5000'))));
select is(pg_temp.res('span', 0) ->> 'result', 'applied', 'pre-deploy transaction create: applied');
select is(pg_temp.res('span', 1) ->> 'result', 'applied', 'pre-deploy entry create: applied');

-- f1. The retry with the SAME op_id is answered from the operation ledger
-- before any comparison: already_applied, and the column stays null.
select pg_temp.push('span_same_op', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000050', 'money_transaction', 'upsert', 't_span', null,
             pg_temp.tx('k_span', '5000') || '{"import_source": "sms"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000051', 'finance_entry', 'upsert', 'e_span', null,
             pg_temp.entry('ke_span', '5000') || '{"import_source": "sms"}')));
select is(pg_temp.res('span_same_op', 0) ->> 'result', 'already_applied',
  'same-op retry (transaction): already_applied from the ledger');
select is(pg_temp.res('span_same_op', 1) ->> 'result', 'already_applied',
  'same-op retry (entry): already_applied from the ledger');
select is((select import_source from public.money_transactions where id = 't_span'), null,
  'same-op retry: the transaction column stays null');

-- f2. The same create carried by a NEW op_id (no base revision) reaches the
-- "same create" comparison, which now includes import_source and differs only
-- there: conflict, with the server row returned.
select pg_temp.push('span_new_op', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000052', 'money_transaction', 'upsert', 't_span', null,
             pg_temp.tx('k_span', '5000') || '{"import_source": "sms"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000053', 'finance_entry', 'upsert', 'e_span', null,
             pg_temp.entry('ke_span', '5000') || '{"import_source": "sms"}')));
select is(pg_temp.res('span_new_op', 0) ->> 'result', 'conflict',
  'create retry spanning the deploy (transaction): conflict');
select is(pg_temp.res('span_new_op', 1) ->> 'result', 'conflict',
  'create retry spanning the deploy (entry): conflict');
select is(pg_temp.res('span_new_op', 0) -> 'server_row' -> 'import_source', 'null'::jsonb,
  'the conflict returns the server row with import_source null');
select is((select import_source from public.money_transactions where id = 't_span'), null,
  'conflict: no write (transaction)');
select is((select import_source from public.finance_entries where id = 'e_span'), null,
  'conflict: no write (entry)');

-- Control: the same new-op retry WITHOUT the key is already_applied, so the
-- conflict above is caused by import_source alone.
select pg_temp.push('span_control', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000054', 'money_transaction', 'upsert', 't_span', null,
             pg_temp.tx('k_span', '5000'))));
select is(pg_temp.res('span_control') ->> 'result', 'already_applied',
  'the same retry without the key: already_applied');

-- ---------------------------------------------------------------------------
-- RLS (unchanged): another owner can neither read nor change the column.
-- ---------------------------------------------------------------------------
select pg_temp.login('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
select is((select count(*)::int from public.money_transactions where import_source = 'sms'), 0,
  'B reads none of A''s imported transactions');
select is((select count(*)::int from public.finance_entries where import_source = 'sms'), 0,
  'B reads none of A''s imported entries');
select is(public.sync_pull_v2(0, 1000) -> 'changes', '[]'::jsonb, 'B pulls none of A''s rows');
update public.money_transactions set import_source = null where id = 't_sms';
update public.finance_entries set import_source = null where id = 'e_sms';

select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
select is((select import_source from public.money_transactions where id = 't_sms'), 'sms',
  'B''s update did not reach A''s transaction');
select is((select import_source from public.finance_entries where id = 'e_sms'), 'sms',
  'B''s update did not reach A''s entry');

-- Privileges are as 026 left them.
select ok(has_function_privilege('authenticated', 'public.sync_push(uuid,text,text,jsonb)', 'execute'),
  'authenticated can call sync_push');
select ok(not has_function_privilege('anon', 'public.sync_push(uuid,text,text,jsonb)', 'execute'),
  'anon cannot call sync_push');
select ok(not has_table_privilege('anon', 'public.money_transactions', 'select'), 'no anon access (transactions)');
select ok(not has_table_privilege('authenticated', 'public.finance_entries', 'delete'), 'no DELETE privilege (entries)');

select * from finish();
rollback;
