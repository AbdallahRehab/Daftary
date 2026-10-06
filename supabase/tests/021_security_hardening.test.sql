-- 021e security hardening: size limits, server-owned revision counter,
-- bounded ledger (migration 20260928090000_021e_size_limits).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into auth.users (id, aud, role, email)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'a@example.test');

create temp table r (k text primary key, v jsonb);
grant all on r to public;

create function pg_temp.login(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function pg_temp.push(p_key text, p_ops jsonb) returns jsonb language plpgsql as $$
declare v jsonb;
begin
  v := public.sync_push('d0d0d0d0-0000-4000-8000-000000000001', '1.2.3', 'android', p_ops);
  insert into r values (p_key, v) on conflict (k) do update set v = excluded.v;
  return v;
end $$;

create function pg_temp.res(p_key text, p_i int default 0) returns jsonb language sql as $$
  select v -> 'results' -> p_i from r where k = p_key
$$;

-- ~24 KB of barely compressible jsonb.
create function pg_temp.big_json() returns jsonb language sql as $$
  select jsonb_object_agg(i::text, md5(i::text) || md5((i * 7)::text)) from generate_series(1, 300) i
$$;

select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');

-- ---------------------------------------------------------------------------
-- sync_push still applies (and the SECURITY DEFINER next_revision stamps it).
-- ---------------------------------------------------------------------------
select pg_temp.push('p1', jsonb_build_array(jsonb_build_object(
  'op_id', '10000000-0000-4000-8000-000000000001', 'entity_type', 'person', 'op_type', 'upsert',
  'entity_id', 'p1', 'base_revision', null,
  'payload', jsonb_build_object('name', 'Ali', 'normalized_name', 'ali'))));
select is(pg_temp.res('p1') ->> 'result', 'applied', 'sync_push: a person upsert still applies');
select is((pg_temp.res('p1') ->> 'revision')::bigint, 1::bigint, 'sync_push: stamped with revision 1');
select is((select last_revision from public.sync_owner_state), 1::bigint,
  'the owner can still read its revision counter');

insert into public.money_transactions (id, person_id, idempotency_key, amount_minor, currency_code,
  direction, kind, occurred_at, occurred_on, tz_offset_minutes)
values ('t1', 'p1', 'k1', 100, 'EGP', 'given', 'initialExchange', now(), current_date, 0);
select is((select revision from public.money_transactions where id = 't1'), 2::bigint,
  'a direct insert is stamped through sync_stamp -> next_revision');

-- ---------------------------------------------------------------------------
-- Over-length values are rejected.
-- ---------------------------------------------------------------------------
select throws_ok(
  $$insert into public.people (id, name, normalized_name) values ('p2', 'x', repeat('x', 201))$$,
  '23514', null, 'people.normalized_name over 200 rejected');
select throws_ok(
  $$insert into public.money_transactions (id, person_id, idempotency_key, amount_minor, currency_code,
      direction, kind, occurred_at, occurred_on, tz_offset_minutes)
    values ('t2', 'p1', repeat('k', 65), 100, 'EGP', 'given', 'initialExchange', now(), current_date, 0)$$,
  '23514', null, 'money_transactions.idempotency_key over 64 rejected');
select throws_ok(
  $$insert into public.transaction_audit_entries (id, transaction_id, change_type, changed_at)
    values ('a1', 't1', repeat('c', 33), now())$$,
  '23514', null, 'transaction_audit_entries.change_type over 32 rejected');
select throws_ok(
  $$insert into public.finance_categories (id, name, normalized_name, type, icon_key)
    values ('c1', 'Rent', 'rent', 'expense', repeat('i', 65))$$,
  '23514', null, 'finance_categories.icon_key over 64 rejected');
select throws_ok(
  $$insert into public.devices (device_id, platform, app_version)
    values (gen_random_uuid(), 'ios', repeat('9', 41))$$,
  '23514', null, 'devices.app_version over 40 rejected');
select throws_ok(
  $$insert into public.sync_operations (op_id, entity_type, entity_id, result)
    values (gen_random_uuid(), 'person', repeat('e', 65), 'rejected')$$,
  '23514', null, 'sync_operations.entity_id over 64 rejected');
select throws_ok(
  $$insert into public.sync_operations (op_id, entity_type, entity_id, result)
    values (gen_random_uuid(), repeat('t', 33), 'e', 'rejected')$$,
  '23514', null, 'sync_operations.entity_type over 32 rejected');
select lives_ok(
  $$insert into public.transaction_audit_entries (id, transaction_id, change_type, previous_values, changed_at)
    values ('a2', 't1', 'edited', '{"amount_minor": "100"}', now())$$,
  'values within the limits are accepted');

-- ---------------------------------------------------------------------------
-- jsonb over 16 KB is rejected.
-- ---------------------------------------------------------------------------
select ok(pg_column_size(pg_temp.big_json()) > 16384, 'fixture jsonb is over 16 KB');
select throws_ok(
  $$insert into public.transaction_audit_entries (id, transaction_id, change_type, previous_values, changed_at)
    values ('a3', 't1', 'edited', pg_temp.big_json(), now())$$,
  '23514', null, 'transaction_audit_entries.previous_values over 16 KB rejected');
select throws_ok(
  $$insert into public.conflict_resolutions (id, entity_type, entity_id, chosen_side, discarded_values, resolved_at)
    values ('r1', 'money_transaction', 't1', 'local', pg_temp.big_json(), now())$$,
  '23514', null, 'conflict_resolutions.discarded_values over 16 KB rejected');

-- ---------------------------------------------------------------------------
-- The revision counter is server-owned.
-- ---------------------------------------------------------------------------
select throws_ok(
  $$update public.sync_owner_state set last_revision = 9223372036854775000$$,
  '42501', null, 'authenticated cannot UPDATE sync_owner_state');
select throws_ok(
  $$insert into public.sync_owner_state (owner_id, last_revision)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 9223372036854775000)
    on conflict (owner_id) do update set last_revision = excluded.last_revision$$,
  '42501', null, 'authenticated cannot INSERT/upsert sync_owner_state');
select is((select last_revision from public.sync_owner_state), 3::bigint, 'the counter is unchanged (3 stamped writes so far)');

-- ---------------------------------------------------------------------------
-- Over-length envelopes are rejected and never ledgered.
-- ---------------------------------------------------------------------------
select pg_temp.push('big', jsonb_build_array(
  jsonb_build_object('op_id', '20000000-0000-4000-8000-000000000001', 'entity_type', 'no_such_type',
    'op_type', 'upsert', 'entity_id', repeat('x', 100000), 'base_revision', null, 'payload', '{}'::jsonb),
  jsonb_build_object('op_id', '20000000-0000-4000-8000-000000000002', 'entity_type', repeat('y', 100000),
    'op_type', 'upsert', 'entity_id', 'e1', 'base_revision', null, 'payload', '{}'::jsonb),
  jsonb_build_object('op_id', '20000000-0000-4000-8000-000000000003', 'entity_type', 'person',
    'op_type', 'upsert', 'entity_id', repeat('z', 65), 'base_revision', null,
    'payload', jsonb_build_object('name', 'x', 'normalized_name', 'x'))));
select is(pg_temp.res('big', 0) ->> 'result', 'rejected', 'oversized entity_id on unknown type: rejected');
select is(pg_temp.res('big', 0) ->> 'reason', 'validation', 'oversized entity_id on unknown type: validation');
select is(pg_temp.res('big', 1) ->> 'reason', 'validation', 'oversized entity_type: validation');
select is(pg_temp.res('big', 2) ->> 'reason', 'validation', 'oversized entity_id on a known type: validation');
select is(
  (select count(*) from public.sync_operations
    where op_id in ('20000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002',
                    '20000000-0000-4000-8000-000000000003')),
  0::bigint, 'over-length ops are not ledgered');

-- A short unknown type is answered unknown_entity but, since 026, NOT
-- ledgered: a type the server learns later (a mis-ordered rollout) must be
-- re-evaluated on replay instead of replaying the old rejection.
select pg_temp.push('unk', jsonb_build_array(jsonb_build_object(
  'op_id', '20000000-0000-4000-8000-000000000004', 'entity_type', 'no_such_type',
  'op_type', 'upsert', 'entity_id', 'e1', 'base_revision', null, 'payload', '{}'::jsonb)));
select is(pg_temp.res('unk') ->> 'reason', 'unknown_entity', 'a short unknown type is still unknown_entity');
select is((select count(*) from public.sync_operations where op_id = '20000000-0000-4000-8000-000000000004'),
  0::bigint, 'a short unknown type is not ledgered (026)');

select throws_ok(
  $$select public.sync_push('d0d0d0d0-0000-4000-8000-000000000001', repeat('9', 41), 'android', '[]'::jsonb)$$,
  '22023', 'invalid_app_version', 'sync_push rejects an app_version over 40 up front');

-- ---------------------------------------------------------------------------
-- next_revision() without a user raises.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"role": "authenticated"}', true);
select throws_ok($$select public.next_revision()$$, '42501', 'not_authenticated',
  'next_revision raises without auth.uid()');

reset role;

-- Privilege catalog checks.
select ok(has_table_privilege('authenticated', 'public.sync_owner_state', 'select'),
  'authenticated keeps SELECT on sync_owner_state');
select ok(not has_table_privilege('authenticated', 'public.sync_owner_state', 'insert'),
  'authenticated has no INSERT on sync_owner_state');
select ok(not has_table_privilege('authenticated', 'public.sync_owner_state', 'update'),
  'authenticated has no UPDATE on sync_owner_state');
select ok((select prosecdef from pg_proc where oid = 'public.next_revision()'::regprocedure),
  'next_revision is SECURITY DEFINER');
select is((select proconfig from pg_proc where oid = 'public.next_revision()'::regprocedure),
  array['search_path=""'], 'next_revision pins an empty search_path');
select is((select pg_get_userbyid(proowner) from pg_proc where oid = 'public.next_revision()'::regprocedure),
  'postgres', 'next_revision is owned by postgres');
select ok(has_function_privilege('authenticated', 'public.next_revision()', 'execute'),
  'authenticated can execute next_revision');
select ok(not has_function_privilege('anon', 'public.next_revision()', 'execute'),
  'anon cannot execute next_revision');
select ok(not has_function_privilege('anon', 'public.sync_push(uuid, text, text, jsonb)', 'execute'),
  'anon cannot execute sync_push');
select ok(has_function_privilege('authenticated', 'public.sync_push(uuid, text, text, jsonb)', 'execute'),
  'authenticated can execute sync_push');

select * from finish();
rollback;
