-- 022: occasions, budgets and budget allocations sync; money_transactions
-- carries occasion contributions; v_person_balances; sync_delete_all.
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

create function pg_temp.tx(p_key text, p_kind text, p_occasion text, p_counts boolean) returns jsonb language sql as $$
  select jsonb_build_object('person_id', 'p1', 'idempotency_key', p_key,
    'amount_minor', '50000', 'currency_code', 'EGP', 'direction', 'given', 'kind', p_kind,
    'occurred_at', '2026-09-27T09:12:00.000Z', 'occurred_on', '2026-09-27', 'tz_offset_minutes', 180,
    'note', null, 'edited_at', null, 'deleted_at', null,
    'occasion_id', p_occasion, 'counts_toward_balance', p_counts, 'source', 'ocr', 'ocr_scan_id', 's1')
$$;

select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');

-- Parents: a person, an occasion, a category.
select pg_temp.push('parents', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000001', 'person', 'upsert', 'p1',
    jsonb_build_object('name', 'Ahmed', 'normalized_name', 'ahmed', 'is_archived', false)),
  pg_temp.op('00000000-0000-4000-8000-000000000002', 'occasion', 'upsert', 'o1',
    jsonb_build_object('idempotency_key', 'ok1', 'name', 'Wedding', 'occasion_at', '2026-10-01T21:00:00.000Z',
                       'type', 'wedding', 'notes', null, 'is_archived', false, 'deleted_at', null)),
  pg_temp.op('00000000-0000-4000-8000-000000000003', 'finance_category', 'upsert', 'c1',
    jsonb_build_object('name', 'Groceries', 'normalized_name', 'groceries', 'type', 'expense',
                       'icon_key', 'cart', 'is_default', false, 'is_archived', false))));
select is(pg_temp.res('parents', 1) ->> 'result', 'applied', 'occasion upsert: applied');

-- Occasion contributions, counting and not.
select pg_temp.push('tx', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000010', 'money_transaction', 'upsert', 't1',
    pg_temp.tx('k1', 'occasionContribution', 'o1', false)),
  pg_temp.op('00000000-0000-4000-8000-000000000011', 'money_transaction', 'upsert', 't2',
    pg_temp.tx('k2', 'initialExchange', null, true))));
select is(pg_temp.res('tx', 0) ->> 'result', 'applied', 'a non-counting occasion contribution is accepted');
select is(
  (select jsonb_build_object('o', occasion_id, 'c', counts_toward_balance, 's', source, 'scan', ocr_scan_id)
     from public.money_transactions where id = 't1'),
  jsonb_build_object('o', 'o1', 'c', false, 's', 'ocr', 'scan', 's1'),
  'the four 022 columns are stored');

-- Guards: a contribution names its occasion; only a contribution may not count.
select pg_temp.push('bad', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000012', 'money_transaction', 'upsert', 't3',
    pg_temp.tx('k3', 'initialExchange', null, false)),
  pg_temp.op('00000000-0000-4000-8000-000000000013', 'money_transaction', 'upsert', 't4',
    pg_temp.tx('k4', 'occasionContribution', null, true))));
select is(pg_temp.res('bad', 0) ->> 'reason', 'validation', 'an ordinary transaction must count toward the balance');
select is(pg_temp.res('bad', 1) ->> 'reason', 'validation', 'a contribution must name its occasion');

-- A contribution to an occasion not uploaded yet is a transient missing_parent.
select pg_temp.push('orphan', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000014', 'money_transaction', 'upsert', 't5',
    pg_temp.tx('k5', 'occasionContribution', 'o-later', true))));
select is(pg_temp.res('orphan') ->> 'reason', 'missing_parent', 'an unknown occasion is missing_parent');

-- The balance view leaves the non-counting contribution out (008 FR-018).
select is(
  (select net_given_minor from public.v_person_balances where person_id = 'p1'),
  50000::bigint,
  'v_person_balances counts only t2');

-- Budgets and allocations; the derived allocation id is longer than 64.
select pg_temp.push('budget', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000020', 'budget', 'upsert', 'budget_2026-10',
    jsonb_build_object('idempotency_key', 'bk', 'month', '2026-10', 'expected_income_minor', '1500000',
                       'currency_code', 'EGP', 'deleted_at', null)),
  pg_temp.op('00000000-0000-4000-8000-000000000021', 'budget_allocation', 'upsert',
    'alloc_budget_2026-10_c1',
    jsonb_build_object('idempotency_key', 'ak', 'budget_id', 'budget_2026-10', 'category_id', 'c1',
                       'planned_minor', '250000'))));
select is(pg_temp.res('budget', 0) ->> 'result', 'applied', 'budget upsert: applied');
select is(pg_temp.res('budget', 1) ->> 'result', 'applied', 'allocation upsert: applied');

select pg_temp.push('bad-month', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000022', 'budget', 'upsert', 'budget_2026-13',
    jsonb_build_object('idempotency_key', 'bk2', 'month', '2026-13', 'currency_code', 'EGP'))));
select is(pg_temp.res('bad-month') ->> 'reason', 'validation', 'a malformed month is rejected');

-- An allocation removed on the device is a delete op; a second device re-adding
-- the same category converges on the same row and undeletes it.
select pg_temp.push('unplan', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000023', 'budget_allocation', 'delete',
    'alloc_budget_2026-10_c1', '{}'::jsonb)));
select is(pg_temp.res('unplan') ->> 'result', 'applied', 'allocation delete: applied');
select isnt((select deleted_at from public.budget_category_allocations where id = 'alloc_budget_2026-10_c1'),
  null, 'the deleted allocation is a tombstone');
select pg_temp.push('replan', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000024', 'budget_allocation', 'upsert',
    'alloc_budget_2026-10_c1',
    jsonb_build_object('idempotency_key', 'ak2', 'budget_id', 'budget_2026-10', 'category_id', 'c1',
                       'planned_minor', '300000'))));
select is((select deleted_at from public.budget_category_allocations where id = 'alloc_budget_2026-10_c1'),
  null, 're-planning the category undeletes the same row');

-- Occasions and budgets cannot be deleted by a delete op (soft delete by upsert).
select pg_temp.push('del-occ', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000025', 'occasion', 'delete', 'o1', '{}'::jsonb)));
select is(pg_temp.res('del-occ') ->> 'reason', 'validation', 'an occasion delete op is refused');

-- Pull returns the three new entity types.
select ok(
  (select bool_and(t in (select c ->> 'entity_type' from jsonb_array_elements(public.sync_pull(0) -> 'changes') c))
     from unnest(array['occasion','budget','budget_allocation']) t),
  'sync_pull carries occasion, budget and budget_allocation');

-- There is no delete path besides sync_delete_all. Since 024 the privilege
-- itself is revoked, so a plain delete is refused outright.
select throws_ok($$delete from public.occasions$$, '42501', null,
  'authenticated cannot DELETE occasions (024)');
select is((select count(*) from public.occasions), 1::bigint, 'no delete path besides sync_delete_all');

-- Another account sees nothing of it.
select pg_temp.login('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
select is((select count(*) from public.occasions), 0::bigint, 'RLS: occasions are owner-scoped');
select is((select count(*) from public.budgets), 0::bigint, 'RLS: budgets are owner-scoped');
select is((select count(*) from public.budget_category_allocations), 0::bigint,
  'RLS: allocations are owner-scoped');

-- sync_delete_all erases the caller's account and every row it owns, and no one else's.
select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
select lives_ok($$ select public.sync_delete_all() $$, 'sync_delete_all runs for the caller');
reset role;
select is((select count(*) from auth.users where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'), 0::bigint,
  'the account is gone');
select is(
  (select count(*) from public.people where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')
  + (select count(*) from public.money_transactions where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')
  + (select count(*) from public.occasions where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')
  + (select count(*) from public.budgets where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')
  + (select count(*) from public.budget_category_allocations where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')
  + (select count(*) from public.sync_operations where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  0::bigint, 'every row it owned is gone');
select is((select count(*) from auth.users where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'), 1::bigint,
  'another account is untouched');

select * from finish();
rollback;
