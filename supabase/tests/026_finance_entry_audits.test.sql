-- 026: finance_entry_audits (D2). sync_push accepts the new entity type,
-- sync_pull (old apps) never returns it, sync_pull_v2 (R2 and later) does,
-- RLS keeps one owner's history from another.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into auth.users (id, aud, role, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'a@example.test'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'authenticated', 'authenticated', 'b@example.test');

create temp table r (k text primary key, v jsonb);
grant all on r to public;

create function pg_temp.login(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function pg_temp.op(p_op_id text, p_type text, p_op text, p_id text, p_payload jsonb)
returns jsonb language sql as $$
  select jsonb_build_object('op_id', p_op_id, 'entity_type', p_type, 'op_type', p_op,
                            'entity_id', p_id, 'base_revision', null, 'payload', p_payload)
$$;

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

create function pg_temp.types(p_page jsonb) returns text[] language sql as $$
  select coalesce(array_agg(distinct c ->> 'entity_type'), array[]::text[])
    from jsonb_array_elements(p_page -> 'changes') c
$$;

select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');

-- Parents: a category and an entry.
select pg_temp.push('parents', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000001', 'finance_category', 'upsert', 'c1',
    jsonb_build_object('name', 'Groceries', 'normalized_name', 'groceries', 'type', 'expense',
                       'icon_key', 'cart', 'is_default', false, 'is_archived', false)),
  pg_temp.op('00000000-0000-4000-8000-000000000002', 'finance_entry', 'upsert', 'e1',
    jsonb_build_object('category_id', 'c1', 'idempotency_key', 'k1', 'type', 'expense',
                       'amount_minor', '30000', 'currency_code', 'EGP',
                       'occurred_at', '2026-10-01T09:00:00.000Z', 'occurred_on', '2026-10-01',
                       'tz_offset_minutes', 180, 'note', null, 'edited_at', null, 'deleted_at', null))));
select is(pg_temp.res('parents', 1) ->> 'result', 'applied', 'the entry is applied');

-- The four change types, created with no previous values.
select pg_temp.push('audits', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000010', 'finance_entry_audit', 'upsert', 'a1',
    jsonb_build_object('finance_entry_id', 'e1', 'change_type', 'created', 'previous_values', null,
                       'changed_at', '2026-10-01T09:00:00.000Z')),
  pg_temp.op('00000000-0000-4000-8000-000000000011', 'finance_entry_audit', 'upsert', 'a2',
    jsonb_build_object('finance_entry_id', 'e1', 'change_type', 'edited',
                       'previous_values', jsonb_build_object('amountMinorUnits', 30000, 'type', 'expense',
                                                             'categoryId', 'c1'),
                       'changed_at', '2026-10-02T09:00:00.000Z')),
  pg_temp.op('00000000-0000-4000-8000-000000000012', 'finance_entry_audit', 'upsert', 'a3',
    jsonb_build_object('finance_entry_id', 'e1', 'change_type', 'deleted', 'previous_values', null,
                       'changed_at', '2026-10-03T09:00:00.000Z')),
  pg_temp.op('00000000-0000-4000-8000-000000000013', 'finance_entry_audit', 'upsert', 'a4',
    jsonb_build_object('finance_entry_id', 'e1', 'change_type', 'restored', 'previous_values', null,
                       'changed_at', '2026-10-04T09:00:00.000Z'))));
select is(pg_temp.res('audits', 0) ->> 'result', 'applied', 'created: applied');
select is(pg_temp.res('audits', 1) ->> 'result', 'applied', 'edited: applied');
select is(pg_temp.res('audits', 3) ->> 'result', 'applied', 'restored: applied');
select is((select count(*)::int from public.finance_entry_audits), 4, 'four history rows stored');

-- Append-only: a repeated id is already_applied and never rewritten.
select pg_temp.push('again', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000014', 'finance_entry_audit', 'upsert', 'a2',
    jsonb_build_object('finance_entry_id', 'e1', 'change_type', 'deleted', 'previous_values', null,
                       'changed_at', '2026-10-09T09:00:00.000Z'))));
select is(pg_temp.res('again') ->> 'result', 'already_applied', 'a repeated audit id is not rewritten');
select is((select change_type from public.finance_entry_audits where id = 'a2'), 'edited', 'the stored row is unchanged');

-- Guards.
select pg_temp.push('bad', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000015', 'finance_entry_audit', 'upsert', 'a5',
    jsonb_build_object('finance_entry_id', 'e1', 'change_type', 'moved', 'previous_values', null,
                       'changed_at', '2026-10-05T09:00:00.000Z')),
  pg_temp.op('00000000-0000-4000-8000-000000000016', 'finance_entry_audit', 'upsert', 'a6',
    jsonb_build_object('finance_entry_id', 'no-such-entry', 'change_type', 'created', 'previous_values', null,
                       'changed_at', '2026-10-05T09:00:00.000Z')),
  pg_temp.op('00000000-0000-4000-8000-000000000017', 'finance_entry_audit', 'delete', 'a1', '{}'::jsonb)));
select is(pg_temp.res('bad', 0) ->> 'reason', 'validation', 'an unknown change type is refused');
select is(pg_temp.res('bad', 1) ->> 'reason', 'missing_parent', 'an unknown entry is missing_parent');
select is(pg_temp.res('bad', 2) ->> 'reason', 'validation', 'an audit cannot be deleted');

-- An unknown entity type is rejected without being ledgered, so the same op
-- succeeds once the server knows the type (mis-ordered rollout recovers).
select pg_temp.push('unknown', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000019', 'no_such_type', 'upsert', 'x', '{}'::jsonb)));
select is(pg_temp.res('unknown') ->> 'reason', 'unknown_entity', 'an unknown type is rejected');
select is((select count(*)::int from public.sync_operations
            where op_id = '00000000-0000-4000-8000-000000000019'), 0,
  'an unknown_entity rejection is not ledgered');

-- A savings-contribution resolution, which only R2 and later can read.
select pg_temp.push('resolution', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000018', 'conflict_resolution', 'upsert', 'cr1',
    jsonb_build_object('entity_type', 'savings_contribution', 'entity_id', 'sc1', 'chosen_side', 'local',
                       'discarded_values', '{}'::jsonb, 'resolved_at', '2026-10-05T09:00:00.000Z'))));
select is(pg_temp.res('resolution') ->> 'result', 'applied', 'a savings resolution is recorded');

-- sync_pull (v1.0.1 and R1) never returns finance_entry_audit, nor the
-- savings resolution (025); sync_pull_v2 returns both.
select ok(not ('finance_entry_audit' = any (pg_temp.types(public.sync_pull(0, 1000)))),
  'sync_pull never returns finance_entry_audit');
select ok(not ('conflict_resolution' = any (pg_temp.types(public.sync_pull(0, 1000)))),
  'sync_pull still hides a savings resolution (025 filter)');
select ok('finance_entry_audit' = any (pg_temp.types(public.sync_pull_v2(0, 1000))),
  'sync_pull_v2 returns finance_entry_audit');
select ok('conflict_resolution' = any (pg_temp.types(public.sync_pull_v2(0, 1000))),
  'sync_pull_v2 returns every conflict_resolution row');
select is(
  (select count(*)::int from jsonb_array_elements(public.sync_pull_v2(0, 1000) -> 'changes') c
    where c ->> 'entity_type' = 'finance_entry_audit'),
  4, 'sync_pull_v2 returns all four history rows');
select ok(
  (select array_agg(rev order by ord) = array_agg(rev order by rev)
     from (select (c ->> 'revision')::bigint as rev, ord
             from jsonb_array_elements(public.sync_pull_v2(0, 1000) -> 'changes') with ordinality as t(c, ord)) s),
  'sync_pull_v2 rows are in revision order');
select is(public.sync_pull_v2(0, 2) ->> 'has_more', 'true', 'sync_pull_v2 pages with has_more');

-- RLS: B sees none of A's history and cannot write for A.
select pg_temp.login('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
select is((select count(*)::int from public.finance_entry_audits), 0, 'B reads 0 of A''s audit rows');
select is(public.sync_pull_v2(0, 1000) -> 'changes', '[]'::jsonb, 'B pulls none of A''s rows');
select throws_ok(
  $$insert into public.finance_entry_audits (owner_id, id, revision, finance_entry_id, change_type, changed_at)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'x1', 0, 'e1', 'created', now())$$,
  '23503', null, 'B cannot insert an audit row for A (sync_stamp re-stamps owner_id to B, so the row has no parent entry)');

-- No UPDATE or DELETE privilege for authenticated (append-only).
select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
select ok(not has_table_privilege('authenticated', 'public.finance_entry_audits', 'update'), 'no UPDATE privilege');
select ok(not has_table_privilege('authenticated', 'public.finance_entry_audits', 'delete'), 'no DELETE privilege');
select ok(not has_table_privilege('anon', 'public.finance_entry_audits', 'select'), 'no anon access');
select ok(has_function_privilege('authenticated', 'public.sync_pull_v2(bigint,int)', 'execute'), 'authenticated can call sync_pull_v2');
select ok(not has_function_privilege('anon', 'public.sync_pull_v2(bigint,int)', 'execute'), 'anon cannot call sync_pull_v2');

select * from finish();
rollback;
