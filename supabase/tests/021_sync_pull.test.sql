-- 021 sync_pull (contracts/sync-rpc.md §3, task T066).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into auth.users (id, aud, role, email)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'a@example.test'),
       ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'authenticated', 'authenticated', 'b@example.test');

create function pg_temp.login(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function pg_temp.op(p_type text, p_op text, p_id text, p_base bigint, p_payload jsonb)
returns jsonb language sql as $$
  select jsonb_build_object('op_id', gen_random_uuid(), 'entity_type', p_type, 'op_type', p_op,
                            'entity_id', p_id, 'base_revision', p_base, 'payload', p_payload)
$$;

create function pg_temp.person(p_name text) returns jsonb language sql as $$
  select jsonb_build_object('name', p_name, 'normalized_name', lower(p_name), 'is_archived', false)
$$;

create function pg_temp.tx(p_person text, p_key text) returns jsonb language sql as $$
  select jsonb_build_object('person_id', p_person, 'idempotency_key', p_key,
    'amount_minor', '1000', 'currency_code', 'EGP', 'direction', 'given', 'kind', 'initialExchange',
    'occurred_at', '2026-09-27T09:12:00Z', 'occurred_on', '2026-09-27', 'tz_offset_minutes', 180)
$$;

-- "Device 1" and "device 2" push interleaved batches for owner A.
select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');

select public.sync_push('d1000000-0000-4000-8000-000000000001', '1.0.0', 'android', jsonb_build_array(
  pg_temp.op('person', 'upsert', 'p1', null, pg_temp.person('Ahmed')),
  pg_temp.op('money_transaction', 'upsert', 't1', null, pg_temp.tx('p1', 'k1')),
  pg_temp.op('finance_category', 'upsert', 'c1', null,
    '{"name": "Rent", "normalized_name": "rent", "type": "expense", "icon_key": "home"}'),
  pg_temp.op('person', 'upsert', 'p_gone', null, pg_temp.person('Gone'))));
select public.sync_push('d2000000-0000-4000-8000-000000000002', '1.0.0', 'ios', jsonb_build_array(
  pg_temp.op('person', 'upsert', 'p2', null, pg_temp.person('Mona')),
  pg_temp.op('money_transaction', 'upsert', 't2', null, pg_temp.tx('p2', 'k2')),
  pg_temp.op('person', 'delete', 'p_gone', null, '{}'::jsonb)));
select public.sync_push('d1000000-0000-4000-8000-000000000001', '1.0.0', 'android', jsonb_build_array(
  pg_temp.op('money_transaction', 'upsert', 't3', null, pg_temp.tx('p2', 'k3')),
  pg_temp.op('exchange_rate', 'upsert', 'rate_USD_EGP', null,
    '{"currency_code": "USD", "relative_to_currency_code": "EGP", "rate_micros": "48000000"}'),
  pg_temp.op('primary_currency', 'upsert', 'singleton', null, '{"currency_code": "EGP"}')));

create temp table pulled as select public.sync_pull(0, 1000) as v;
grant all on pulled to public;

select is(jsonb_typeof((select v -> 'changes' from pulled)), 'array', 'changes is an array');
select is((select v ->> 'has_more' from pulled), 'false', 'a full page: has_more false');
select is((select (v ->> 'max_revision')::bigint from pulled),
  (select last_revision from public.sync_owner_state), 'max_revision is the owner''s last revision');

-- Order follows revision, and every current row version is present (nothing
-- skipped). Revisions of rows that were later updated are legitimately absent.
select is(
  (select array_agg((c ->> 'revision')::bigint order by ord)
     from pulled, jsonb_array_elements(v -> 'changes') with ordinality as e(c, ord)),
  (select array_agg(rev order by rev) from (
     select revision as rev from public.people union all
     select revision from public.money_transactions union all
     select revision from public.transaction_audit_entries union all
     select revision from public.finance_categories union all
     select revision from public.finance_entries union all
     select revision from public.exchange_rates union all
     select revision from public.primary_currency union all
     select revision from public.conflict_resolutions) x),
  'changes are ordered by revision and include every row written by both devices');

-- The page holds one change per stored row version (latest of each row).
select is((select jsonb_array_length(v -> 'changes') from pulled),
  (select (select count(*) from public.people) + (select count(*) from public.money_transactions)
        + (select count(*) from public.finance_categories) + (select count(*) from public.exchange_rates)
        + (select count(*) from public.primary_currency))::int,
  'every current row is in the page');

-- A person arrives before its transaction.
select ok(
  (select min(ord) filter (where c ->> 'entity_type' = 'person' and c -> 'row' ->> 'id' = 'p2')
        < min(ord) filter (where c ->> 'entity_type' = 'money_transaction' and c -> 'row' ->> 'id' = 't2')
     from pulled, jsonb_array_elements(v -> 'changes') with ordinality as e(c, ord)),
  'a person is pulled before its transaction');

-- Tombstones are included.
select isnt(
  (select c -> 'row' ->> 'deleted_at'
     from pulled, jsonb_array_elements(v -> 'changes') c
    where c ->> 'entity_type' = 'person' and c -> 'row' ->> 'id' = 'p_gone'),
  null, 'tombstones are included');

select is(
  (select count(*) from pulled, jsonb_array_elements(v -> 'changes') c
    where c ->> 'entity_type' not in ('person','money_transaction','transaction_audit','finance_category',
                                      'finance_entry','exchange_rate','primary_currency','conflict_resolution')),
  0::bigint, 'entity_type values match the push vocabulary');

-- Paging: a cursor walk with a small limit visits every revision exactly once.
create temp table walk (rev bigint);
grant all on walk to public;
do $$
declare v_since bigint := 0; v_page jsonb; v_guard int := 0;
begin
  loop
    v_page := public.sync_pull(v_since, 3);
    insert into walk select (c ->> 'revision')::bigint from jsonb_array_elements(v_page -> 'changes') c;
    v_since := (v_page ->> 'max_revision')::bigint;
    v_guard := v_guard + 1;
    exit when not (v_page ->> 'has_more')::boolean or v_guard > 50;
  end loop;
end $$;
select is((select array_agg(rev order by rev) from walk),
  (select array_agg((c ->> 'revision')::bigint order by (c ->> 'revision')::bigint)
     from pulled, jsonb_array_elements(v -> 'changes') c),
  'paging with limit 3 returns the same changes, none skipped or repeated');

select is((public.sync_pull(1000000, 10) -> 'changes'), '[]'::jsonb, 'past the end: empty changes');
select is((public.sync_pull(1000000, 10) ->> 'max_revision')::bigint, 1000000::bigint,
  'empty page: max_revision == p_since');
select is(jsonb_array_length(public.sync_pull(0, 5000) -> 'changes'),
  least(1000, (select jsonb_array_length(v -> 'changes') from pulled)), 'limit is capped at 1000');
select is(jsonb_array_length(public.sync_pull(0, 1) -> 'changes'), 1, 'limit is honored');
select is(public.sync_pull(0, 1) ->> 'has_more', 'true', 'has_more is true when more rows exist');

-- Incremental: an edit after the cursor is the only change returned.
select public.sync_push('d2000000-0000-4000-8000-000000000002', '1.0.0', 'ios', jsonb_build_array(
  pg_temp.op('person', 'upsert', 'p1', null, pg_temp.person('Ahmed 2'))));
select is(
  (select jsonb_agg(c -> 'row' ->> 'name')
     from jsonb_array_elements(public.sync_pull((select (v ->> 'max_revision')::bigint from pulled), 500) -> 'changes') c),
  '["Ahmed 2"]'::jsonb, 'an incremental pull returns only the newer change');

-- User B sees none of A's rows.
select pg_temp.login('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
select is(public.sync_pull(0, 1000) -> 'changes', '[]'::jsonb, 'B pulls none of A''s rows');
select is((public.sync_pull(0, 1000) ->> 'max_revision')::bigint, 0::bigint, 'B: max_revision stays 0');

select * from finish();
rollback;
