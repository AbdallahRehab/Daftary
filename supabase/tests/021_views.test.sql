-- 021 analytics views (contracts/supabase-schema.md §7, task T082).
-- Every FR-061 question is answered by one owner-scoped query.
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

create function pg_temp.tx(p_id text, p_person text, p_amount bigint, p_currency text, p_direction text,
                           p_kind text, p_on date, p_deleted boolean default false)
returns void language sql as $$
  insert into public.money_transactions
    (id, person_id, idempotency_key, amount_minor, currency_code, direction, kind,
     occurred_at, occurred_on, tz_offset_minutes, deleted_at, client_created_at)
  values (p_id, p_person, 'k_' || p_id, p_amount, p_currency, p_direction, p_kind,
          p_on::timestamptz, p_on, 0, case when p_deleted then now() end, now() - interval '60 seconds');
$$;

-- Owner A: 3 people (1 archived, 1 deleted), transactions across 2 months, 2 years and 2 currencies.
select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
insert into public.people (id, name, normalized_name, is_archived) values
  ('p1', 'Ahmed', 'ahmed', false), ('p2', 'Mona', 'mona', true), ('p3', 'Gone', 'gone', false);
update public.people set deleted_at = now() where id = 'p3';

select pg_temp.tx('t1', 'p1', 1000, 'EGP', 'given',    'initialExchange', '2026-08-10');
select pg_temp.tx('t2', 'p1',  400, 'EGP', 'received', 'repayment',       '2026-09-05');
select pg_temp.tx('t3', 'p1',  200, 'EGP', 'given',    'initialExchange', '2026-09-20');
select pg_temp.tx('t4', 'p2',  500, 'USD', 'received', 'initialExchange', '2025-12-31');
select pg_temp.tx('t5', 'p1', 9999, 'EGP', 'given',    'initialExchange', '2026-09-21', true);

insert into public.finance_categories (id, name, normalized_name, type, icon_key) values
  ('c_rent', 'Rent', 'rent', 'expense', 'home'), ('c_sal', 'Salary', 'salary', 'income', 'work');
insert into public.finance_entries
  (id, category_id, idempotency_key, type, amount_minor, currency_code, occurred_at, occurred_on, tz_offset_minutes, deleted_at)
values
  ('e1', 'c_rent', 'ke1', 'expense', 3000, 'EGP', '2026-09-01', '2026-09-01', 0, null),
  ('e2', 'c_rent', 'ke2', 'expense', 3000, 'EGP', '2026-09-15', '2026-09-15', 0, null),
  ('e3', 'c_sal',  'ke3', 'income', 20000, 'EGP', '2026-09-01', '2026-09-01', 0, null),
  ('e4', 'c_rent', 'ke4', 'expense', 7777, 'EGP', '2026-09-02', '2026-09-02', 0, now());

-- Owner B: one transaction, which A must never see.
select pg_temp.login('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
insert into public.people (id, name, normalized_name) values ('pb', 'B', 'b');
select pg_temp.tx('tb', 'pb', 123456, 'EGP', 'given', 'initialExchange', '2026-09-01');

-- ---------------------------------------------------------------------------
-- User isolation.
-- ---------------------------------------------------------------------------
select is((select count(*) from public.v_person_balances), 1::bigint, 'B sees only its own balance row');
select is((select sum(total_minor) from public.v_monthly_person_flows), 123456::numeric, 'B flows are B''s only');
select is((select count(*) from public.v_monthly_finance_by_category), 0::bigint, 'B sees none of A''s finance');

select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
select is((select count(*) from public.v_person_balances where person_id = 'pb'), 0::bigint, 'A never sees B''s person');
select is((select count(*) from public.v_monthly_person_flows where total_minor = 123456), 0::bigint, 'A never sees B''s flows');
select is((select count(distinct owner_id) from public.v_daily_activity), 1::bigint, 'A daily activity is A''s only');

-- ---------------------------------------------------------------------------
-- FR-061 questions, one query each (as A).
-- ---------------------------------------------------------------------------
-- Total given / received / net / outstanding, per currency.
select results_eq(
  $$select currency_code::text, sum(given_minor)::bigint, sum(received_minor)::bigint, sum(net_given_minor)::bigint
      from public.v_person_balances group by currency_code order by currency_code$$,
  $$values ('EGP', 1200::bigint, 400::bigint, 800::bigint), ('USD', 0::bigint, 500::bigint, -500::bigint)$$,
  'total given, received and net per currency (soft-deleted excluded)');
-- Outstanding per person.
select results_eq(
  $$select person_id, net_given_minor from public.v_person_balances where currency_code = 'EGP'$$,
  $$values ('p1'::text, 800::bigint)$$, 'outstanding balance per person');
-- Transaction count.
select is((select sum(tx_count)::bigint from public.v_monthly_person_flows), 4::bigint, 'transaction count');
-- Monthly frequency.
select results_eq(
  $$select month, sum(tx_count)::bigint from public.v_monthly_person_flows group by month order by month$$,
  $$values ('2025-12-01'::date, 1::bigint), ('2026-08-01'::date, 1::bigint), ('2026-09-01'::date, 2::bigint)$$,
  'monthly transaction frequency');
-- Yearly frequency.
select results_eq(
  $$select extract(year from month)::int, sum(tx_count)::bigint from public.v_monthly_person_flows group by 1 order by 1$$,
  $$values (2025, 1::bigint), (2026, 3::bigint)$$, 'yearly transaction frequency');
-- Kind and direction distribution.
select results_eq(
  $$select direction, kind, sum(tx_count)::bigint from public.v_monthly_person_flows group by 1, 2 order by 1, 2$$,
  $$values ('given'::text, 'initialExchange'::text, 2::bigint), ('received', 'initialExchange', 1::bigint), ('received', 'repayment', 1::bigint)$$,
  'distribution of kind and direction');
-- Average amount.
select is((select avg_minor from public.v_monthly_person_flows
            where month = '2026-08-01' and direction = 'given' and currency_code = 'EGP'), 1000::bigint,
  'average transaction amount');
-- People count (active and archived) with balances.
select results_eq(
  $$select is_archived, count(distinct person_id)::bigint from public.v_person_balances group by 1 order by 1$$,
  $$values (false, 1::bigint), (true, 1::bigint)$$, 'people count, active and archived');
-- People with outstanding balances.
select is((select count(distinct person_id) from public.v_person_balances where net_given_minor <> 0), 2::bigint,
  'people with outstanding balances');
-- Most active relationships.
select is((select person_id from public.v_person_balances order by tx_count desc, person_id limit 1), 'p1',
  'most active relationship');
-- Income and expense by category and period.
select results_eq(
  $$select category_id, type, total_minor, entry_count from public.v_monthly_finance_by_category
     where month = '2026-09-01' order by category_id$$,
  $$values ('c_rent'::text, 'expense'::text, 6000::bigint, 2::bigint), ('c_sal', 'income', 20000::bigint, 1::bigint)$$,
  'income and expense by category and month (soft-deleted excluded)');
-- Daily activity and offline lag.
select is((select sum(transactions_created)::bigint from public.v_daily_activity), 4::bigint,
  'daily activity counts non-deleted transactions');
select is((select sum(entries_created)::bigint from public.v_daily_activity), 3::bigint,
  'daily activity counts non-deleted entries');
select ok((select max(offline_lag_p50_seconds) from public.v_daily_activity) >= 59,
  'offline lag p50 is server_created_at - client_created_at');
-- Archived and deleted counts (from the base tables).
select results_eq(
  $$select count(*) filter (where is_archived and deleted_at is null), count(*) filter (where deleted_at is not null)
      from public.people$$,
  $$values (1::bigint, 1::bigint)$$, 'archived and deleted people counts');

-- ---------------------------------------------------------------------------
-- Security.
-- ---------------------------------------------------------------------------
reset role;
select ok(
  (select bool_and(coalesce(c.reloptions @> array['security_invoker=true'], false))
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'v' and c.relname like 'v\_%'),
  'every analytics view is security_invoker');
select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'v' and c.relname like 'v\_%'),
  4, 'the 4 analytics views exist');

set local role anon;
select throws_ok($$select 1 from public.v_monthly_person_flows$$,        '42501', null, 'anon: v_monthly_person_flows denied');
select throws_ok($$select 1 from public.v_person_balances$$,             '42501', null, 'anon: v_person_balances denied');
select throws_ok($$select 1 from public.v_monthly_finance_by_category$$, '42501', null, 'anon: v_monthly_finance_by_category denied');
select throws_ok($$select 1 from public.v_daily_activity$$,              '42501', null, 'anon: v_daily_activity denied');
reset role;

select * from finish();
rollback;
