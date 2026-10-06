-- 025: savings contributions get the manual-conflict ("financial") policy only
-- for app 1.1.0 and later; v1.0.1 keeps last-write-wins. sync_pull (old apps)
-- never returns a savings conflict_resolution row, which v1.0.1 cannot parse.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into auth.users (id, aud, role, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'a@example.test');

create temp table r (k text primary key, v jsonb);
grant all on r to public;

create function pg_temp.login(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function pg_temp.op(p_op_id text, p_type text, p_id text, p_base bigint, p_payload jsonb)
returns jsonb language sql as $$
  select jsonb_build_object('op_id', p_op_id, 'entity_type', p_type, 'op_type', 'upsert',
                            'entity_id', p_id, 'base_revision', p_base, 'payload', p_payload)
$$;

create function pg_temp.push(p_key text, p_version text, p_ops jsonb) returns jsonb language plpgsql as $$
declare v jsonb;
begin
  v := public.sync_push('d0d0d0d0-0000-4000-8000-000000000001', p_version, 'android', p_ops);
  insert into r values (p_key, v) on conflict (k) do update set v = excluded.v;
  return v;
end $$;

create function pg_temp.res(p_key text, p_i int default 0) returns jsonb language sql as $$
  select v -> 'results' -> p_i from r where k = p_key
$$;

create function pg_temp.contribution(p_amount bigint) returns jsonb language sql as $$
  select jsonb_build_object('idempotency_key', 'k-' || p_amount, 'goal_id', 'g1', 'type', 'contribution',
                            'amount_minor_units', p_amount, 'entered_amount_minor_units', p_amount,
                            'entered_currency_code', 'EGP', 'date', '2026-10-01T00:00:00.000Z',
                            'note', null, 'edited_at', null, 'deleted_at', null)
$$;

-- ---------------------------------------------------------------------------
-- app_version_at_least
-- ---------------------------------------------------------------------------
select ok(public.app_version_at_least('1.1.0', '1.1.0'), '1.1.0 >= 1.1.0');
select ok(public.app_version_at_least('1.1.0+3', '1.1.0'), 'build suffix ignored');
select ok(public.app_version_at_least('1.10.0', '1.9.9'), 'numeric, not lexical, compare');
select ok(public.app_version_at_least('2.0', '1.1.0'), 'missing part counts as 0');
select ok(not public.app_version_at_least('1.0.1', '1.1.0'), '1.0.1 < 1.1.0');
select ok(not public.app_version_at_least('unknown', '1.1.0'), 'unknown is not >= 1.1.0');
select ok(not public.app_version_at_least(null, '1.1.0'), 'null is not >= 1.1.0');
select ok(not public.app_version_at_least('1.1.0-rc1', '1.1.0'), 'pre-release tag is unparsable: false');

select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');

-- Parent goal.
select pg_temp.push('goal', '1.1.0', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000001', 'savings_goal', 'g1', null,
    jsonb_build_object('idempotency_key', 'kg1', 'name', 'Car', 'type', null, 'currency_code', 'EGP',
                       'target_amount_minor_units', 1200000, 'monthly_contribution_minor_units', null,
                       'target_date', null, 'is_archived', false, 'deleted_at', null))));
select is(pg_temp.res('goal') ->> 'result', 'applied', 'goal applied');

-- ---------------------------------------------------------------------------
-- v1.0.1: a stale edit still wins (last-write-wins, unchanged behaviour).
-- ---------------------------------------------------------------------------
select pg_temp.push('old-create', '1.0.1', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000010', 'savings_contribution', 'c-old', null,
    pg_temp.contribution(50000))));
select is(pg_temp.res('old-create') ->> 'result', 'applied', 'v1.0.1 create applied');
select pg_temp.push('old-edit-1', '1.0.1', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000011', 'savings_contribution', 'c-old',
    (pg_temp.res('old-create') ->> 'revision')::bigint, pg_temp.contribution(60000))));
select is(pg_temp.res('old-edit-1') ->> 'result', 'applied', 'v1.0.1 edit on current base applied');
select pg_temp.push('old-edit-stale', '1.0.1', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000012', 'savings_contribution', 'c-old',
    (pg_temp.res('old-create') ->> 'revision')::bigint, pg_temp.contribution(70000))));
select is(pg_temp.res('old-edit-stale') ->> 'result', 'applied', 'v1.0.1 stale edit: applied (lww)');
select is((select amount_minor_units from public.savings_contributions where id = 'c-old'),
  70000::bigint, 'v1.0.1: the last write wins');

-- ---------------------------------------------------------------------------
-- 1.1.0: the same stale edit is a conflict and changes nothing.
-- ---------------------------------------------------------------------------
select pg_temp.push('new-create', '1.1.0', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000020', 'savings_contribution', 'c-new', null,
    pg_temp.contribution(50001))));
select is(pg_temp.res('new-create') ->> 'result', 'applied', '1.1.0 create applied');
select pg_temp.push('new-edit-1', '1.1.0', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000021', 'savings_contribution', 'c-new',
    (pg_temp.res('new-create') ->> 'revision')::bigint, pg_temp.contribution(60001))));
select is(pg_temp.res('new-edit-1') ->> 'result', 'applied', '1.1.0 edit on current base applied');
select pg_temp.push('new-edit-stale', '1.1.0', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000022', 'savings_contribution', 'c-new',
    (pg_temp.res('new-create') ->> 'revision')::bigint, pg_temp.contribution(70001))));
select is(pg_temp.res('new-edit-stale') ->> 'result', 'conflict', '1.1.0 stale edit: conflict');
select is((select amount_minor_units from public.savings_contributions where id = 'c-new'),
  60001::bigint, '1.1.0: the server value is kept until the user chooses');

-- A delete-only difference with no base revision is not "already applied"
-- (deleted_at is a business column for the financial policy).
select pg_temp.push('new-delete-nobase', '1.1.0', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000023', 'savings_contribution', 'c-new', null,
    pg_temp.contribution(60001) || jsonb_build_object('deleted_at', '2026-10-05T00:00:00.000Z'))));
select isnt(pg_temp.res('new-delete-nobase') ->> 'result', 'already_applied',
  'a delete-only difference is never answered already_applied');

-- ---------------------------------------------------------------------------
-- Conflict resolutions: savings rows are accepted, hidden from sync_pull
-- (v1.0.1 rejects them), returned by sync_pull_v2.
-- ---------------------------------------------------------------------------
select pg_temp.push('res', '1.1.0', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000030', 'conflict_resolution', 'r-sav', null,
    jsonb_build_object('entity_type', 'savings_contribution', 'entity_id', 'c-new', 'chosen_side', 'server',
                       'discarded_values', jsonb_build_object('amount_minor_units', 70001),
                       'resolved_at', '2026-10-05T10:00:00.000Z')),
  pg_temp.op('00000000-0000-4000-8000-000000000031', 'conflict_resolution', 'r-fin', null,
    jsonb_build_object('entity_type', 'finance_entry', 'entity_id', 'e-x', 'chosen_side', 'local',
                       'discarded_values', jsonb_build_object('amount_minor', 1),
                       'resolved_at', '2026-10-05T10:00:00.000Z'))));
select is(pg_temp.res('res', 0) ->> 'result', 'applied', 'a savings conflict_resolution is accepted');
select is(pg_temp.res('res', 1) ->> 'result', 'applied', 'a finance conflict_resolution is accepted');

select is(
  (select count(*)::int from jsonb_array_elements(public.sync_pull(0, 1000) -> 'changes') c
    where c ->> 'entity_type' = 'conflict_resolution' and c -> 'row' ->> 'entity_type' = 'savings_contribution'),
  0, 'sync_pull never returns a savings conflict_resolution (v1.0.1 cannot parse it)');
select is(
  (select count(*)::int from jsonb_array_elements(public.sync_pull(0, 1000) -> 'changes') c
    where c ->> 'entity_type' = 'conflict_resolution' and c -> 'row' ->> 'entity_type' = 'finance_entry'),
  1, 'sync_pull still returns the finance conflict_resolution');
select is(
  (select count(*)::int from jsonb_array_elements(public.sync_pull_v2(0, 1000) -> 'changes') c
    where c ->> 'entity_type' = 'conflict_resolution'),
  2, 'sync_pull_v2 returns both conflict_resolutions');

select * from finish();
rollback;
