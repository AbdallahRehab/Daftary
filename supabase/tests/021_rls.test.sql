-- 021 row-level security isolation (contracts/supabase-schema.md §8, task T048).
-- Two users, A and B, across every synced and server-only table.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- ---------------------------------------------------------------------------
-- Fixtures
-- ---------------------------------------------------------------------------
insert into auth.users (id, aud, role, email)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'a@example.test'),
       ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'authenticated', 'authenticated', 'b@example.test');

create function pg_temp.login(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function pg_temp.logout() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '', true);
  perform set_config('role', 'none', true);
end $$;

-- User A writes one row into every synced table, directly through RLS.
select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');

insert into public.people (id, name, normalized_name) values ('pa', 'Ahmed', 'ahmed');
insert into public.money_transactions
  (id, person_id, idempotency_key, amount_minor, currency_code, direction, kind,
   occurred_at, occurred_on, tz_offset_minutes)
values ('ta', 'pa', 'ka', 1000, 'EGP', 'given', 'initialExchange', now(), current_date, 180);
insert into public.transaction_audit_entries (id, transaction_id, change_type, changed_at)
values ('aa', 'ta', 'created', now());
insert into public.finance_categories (id, name, normalized_name, type, icon_key)
values ('ca', 'Rent', 'rent', 'expense', 'home');
insert into public.finance_entries
  (id, category_id, idempotency_key, type, amount_minor, currency_code,
   occurred_at, occurred_on, tz_offset_minutes)
values ('ea', 'ca', 'kea', 'expense', 500, 'EGP', now(), current_date, 180);
insert into public.exchange_rates (id, currency_code, relative_to_currency_code, rate_micros)
values ('rate_USD_EGP', 'USD', 'EGP', 48000000);
insert into public.primary_currency (id, currency_code) values ('singleton', 'EGP');
insert into public.conflict_resolutions (id, entity_type, entity_id, chosen_side, discarded_values, resolved_at)
values ('cra', 'money_transaction', 'ta', 'local', '{}'::jsonb, now());

-- A's first push populates sync_operations and devices.
select public.sync_push('a0a0a0a0-0000-4000-8000-000000000001', '1.0.0', 'android',
  jsonb_build_array(jsonb_build_object(
    'op_id', 'a1a1a1a1-0000-4000-8000-000000000001', 'entity_type', 'person', 'op_type', 'upsert',
    'entity_id', 'pa2', 'base_revision', null,
    'payload', jsonb_build_object('name', 'Mona', 'normalized_name', 'mona'))));

select is((select count(*) from public.people), 2::bigint, 'A sees its own people');
select is((select owner_id from public.people where id = 'pa'),
          'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid, 'owner_id is stamped from auth.uid()');

-- ---------------------------------------------------------------------------
-- Guarantee 1: B sees none of A's rows.
-- ---------------------------------------------------------------------------
select pg_temp.login('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');

select is((select count(*) from public.people),                    0::bigint, 'B: 0 people of A');
select is((select count(*) from public.money_transactions),        0::bigint, 'B: 0 transactions of A');
select is((select count(*) from public.transaction_audit_entries), 0::bigint, 'B: 0 audit entries of A');
select is((select count(*) from public.finance_categories),        0::bigint, 'B: 0 categories of A');
select is((select count(*) from public.finance_entries),           0::bigint, 'B: 0 entries of A');
select is((select count(*) from public.exchange_rates),            0::bigint, 'B: 0 rates of A');
select is((select count(*) from public.primary_currency),          0::bigint, 'B: 0 primary currency of A');
select is((select count(*) from public.conflict_resolutions),      0::bigint, 'B: 0 conflict resolutions of A');
select is((select count(*) from public.sync_operations),           0::bigint, 'B: 0 ledger rows of A');
select is((select count(*) from public.devices),                   0::bigint, 'B: 0 devices of A');
select is((select count(*) from public.sync_owner_state),          0::bigint, 'B: 0 revision counters of A');

-- ---------------------------------------------------------------------------
-- Guarantee 2: B inserting with owner_id = A is re-stamped to B (or rejected).
-- ---------------------------------------------------------------------------
insert into public.people (owner_id, id, name, normalized_name)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'pb', 'Bassem', 'bassem');
insert into public.money_transactions
  (owner_id, id, person_id, idempotency_key, amount_minor, currency_code, direction, kind,
   occurred_at, occurred_on, tz_offset_minutes)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'tb', 'pb', 'kb', 700, 'EGP', 'received', 'repayment',
        now(), current_date, 0);
insert into public.transaction_audit_entries (owner_id, id, transaction_id, change_type, changed_at)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'ab', 'tb', 'created', now());
insert into public.finance_categories (owner_id, id, name, normalized_name, type, icon_key)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'cb', 'Salary', 'salary', 'income', 'work');
insert into public.finance_entries
  (owner_id, id, category_id, idempotency_key, type, amount_minor, currency_code,
   occurred_at, occurred_on, tz_offset_minutes)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'eb', 'cb', 'keb', 'income', 900, 'EGP', now(), current_date, 0);
insert into public.exchange_rates (owner_id, id, currency_code, relative_to_currency_code, rate_micros)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'rate_EUR_EGP', 'EUR', 'EGP', 52000000);
insert into public.primary_currency (owner_id, id, currency_code)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'singleton', 'USD');
insert into public.conflict_resolutions (owner_id, id, entity_type, entity_id, chosen_side, discarded_values, resolved_at)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'crb', 'finance_entry', 'eb', 'server', '{}'::jsonb, now());

select is((select owner_id from public.people where id = 'pb'),
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid, 'people: forged owner_id re-stamped to B');
select is((select owner_id from public.money_transactions where id = 'tb'),
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid, 'money_transactions: forged owner_id re-stamped to B');
select is((select owner_id from public.transaction_audit_entries where id = 'ab'),
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid, 'transaction_audit_entries: forged owner_id re-stamped to B');
select is((select owner_id from public.finance_categories where id = 'cb'),
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid, 'finance_categories: forged owner_id re-stamped to B');
select is((select owner_id from public.finance_entries where id = 'eb'),
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid, 'finance_entries: forged owner_id re-stamped to B');
select is((select owner_id from public.exchange_rates where id = 'rate_EUR_EGP'),
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid, 'exchange_rates: forged owner_id re-stamped to B');
select is((select owner_id from public.primary_currency where id = 'singleton'),
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid, 'primary_currency: forged owner_id re-stamped to B');
select is((select owner_id from public.conflict_resolutions where id = 'crb'),
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid, 'conflict_resolutions: forged owner_id re-stamped to B');

-- B cannot attach a row to A's parent: A's person is invisible, so the FK fails.
select throws_ok(
  $$insert into public.money_transactions
      (id, person_id, idempotency_key, amount_minor, currency_code, direction, kind,
       occurred_at, occurred_on, tz_offset_minutes)
    values ('tx_on_a', 'pa', 'kx', 1, 'EGP', 'given', 'initialExchange', now(), current_date, 0)$$,
  '23503', null, 'B cannot reference A''s person');

-- Server-only tables have no stamp trigger: a forged owner is rejected by WITH CHECK.
select throws_ok(
  $$insert into public.sync_operations (owner_id, op_id, entity_type, entity_id, result)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', gen_random_uuid(), 'person', 'x', 'applied')$$,
  '42501', null, 'sync_operations: forged owner_id rejected');
select throws_ok(
  $$insert into public.devices (owner_id, device_id, platform, app_version)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', gen_random_uuid(), 'ios', '1')$$,
  '42501', null, 'devices: forged owner_id rejected');
select throws_ok(
  $$insert into public.sync_owner_state (owner_id, last_revision)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 999)$$,
  '42501', null, 'sync_owner_state: forged owner_id rejected');

-- An owner cannot move its row to another owner.
select throws_ok(
  $$update public.people set owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' where id = 'pb'$$,
  '23514', 'immutable_identity', 'owner_id is immutable');

-- ---------------------------------------------------------------------------
-- Guarantee 3: B updating or soft-deleting A's rows affects 0 rows.
-- ---------------------------------------------------------------------------
select results_eq($$with u as (update public.people set name = 'x' where id = 'pa' returning 1) select count(*) from u$$,
  array[0::bigint], 'people: B update of A''s row affects 0 rows');
select results_eq($$with u as (update public.people set deleted_at = now() where id = 'pa2' returning 1) select count(*) from u$$,
  array[0::bigint], 'people: B soft-delete of A''s row affects 0 rows');
select results_eq($$with u as (update public.money_transactions set amount_minor = 1 where id = 'ta' returning 1) select count(*) from u$$,
  array[0::bigint], 'money_transactions: B update affects 0 rows');
select results_eq($$with u as (update public.money_transactions set deleted_at = now() where id = 'ta' returning 1) select count(*) from u$$,
  array[0::bigint], 'money_transactions: B soft-delete affects 0 rows');
select results_eq($$with u as (update public.finance_categories set name = 'x' where id = 'ca' returning 1) select count(*) from u$$,
  array[0::bigint], 'finance_categories: B update affects 0 rows');
select results_eq($$with u as (update public.finance_entries set deleted_at = now() where id = 'ea' returning 1) select count(*) from u$$,
  array[0::bigint], 'finance_entries: B soft-delete affects 0 rows');
select results_eq($$with u as (update public.exchange_rates set rate_micros = 1 where id = 'rate_USD_EGP' returning 1) select count(*) from u$$,
  array[0::bigint], 'exchange_rates: B update affects 0 rows');
select results_eq($$with u as (update public.primary_currency set currency_code = 'SAR' where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' returning 1) select count(*) from u$$,
  array[0::bigint], 'primary_currency: B update affects 0 rows');
select results_eq($$with u as (update public.devices set app_version = 'x' where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' returning 1) select count(*) from u$$,
  array[0::bigint], 'devices: B update affects 0 rows');
select results_eq($$with u as (update public.sync_operations set result = 'rejected' where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' returning 1) select count(*) from u$$,
  array[0::bigint], 'sync_operations: B update affects 0 rows');
-- 021e: sync_owner_state is read-only for clients (next_revision() owns it).
select throws_ok($$update public.sync_owner_state set last_revision = 0 where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'$$,
  '42501', null, 'sync_owner_state: B update denied');

-- ---------------------------------------------------------------------------
-- Guarantee 7: sync_push / sync_pull as B never touch or return A's rows.
-- ---------------------------------------------------------------------------
select is(
  public.sync_push('b0b0b0b0-0000-4000-8000-000000000001', '1.0.0', 'ios',
    jsonb_build_array(
      jsonb_build_object('op_id', 'b1b1b1b1-0000-4000-8000-000000000001', 'entity_type', 'person',
        'op_type', 'upsert', 'entity_id', 'pa', 'base_revision', null,
        'payload', jsonb_build_object('name', 'Hijack', 'normalized_name', 'hijack')),
      jsonb_build_object('op_id', 'b1b1b1b1-0000-4000-8000-000000000002', 'entity_type', 'person',
        'op_type', 'delete', 'entity_id', 'pa2', 'base_revision', null, 'payload', '{}'::jsonb)
    )) -> 'results' -> 0 ->> 'result',
  'applied', 'B pushing A''s person id creates B''s own row');
select is((select count(*) from public.people where id = 'pa'), 1::bigint, 'B sees only its own pa');
select is(
  (select count(*) from jsonb_array_elements(public.sync_pull(0, 1000) -> 'changes') c
    where c -> 'row' ->> 'owner_id' <> 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
  0::bigint, 'sync_pull as B returns none of A''s rows');
select ok(
  (select count(*) from jsonb_array_elements(public.sync_pull(0, 1000) -> 'changes')) > 0,
  'sync_pull as B returns B''s rows');

-- ---------------------------------------------------------------------------
-- Guarantees 4 and 5, as the owner A: no physical delete, no audit rewrite.
-- ---------------------------------------------------------------------------
select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');

select is((select name from public.people where id = 'pa'), 'Ahmed', 'A''s pa untouched by B''s push');
select is((select deleted_at from public.people where id = 'pa2'), null, 'A''s pa2 not deleted by B''s push');

select throws_ok($$delete from public.people where id = 'pa2'$$, '42501', null, 'people: owner delete denied');
select throws_ok($$delete from public.money_transactions$$, '42501', null, 'money_transactions: owner delete denied');
select throws_ok($$delete from public.transaction_audit_entries$$, '42501', null, 'transaction_audit_entries: owner delete denied');
select throws_ok($$delete from public.finance_categories$$, '42501', null, 'finance_categories: owner delete denied');
select throws_ok($$delete from public.finance_entries$$, '42501', null, 'finance_entries: owner delete denied');
select throws_ok($$delete from public.exchange_rates$$, '42501', null, 'exchange_rates: owner delete denied');
select throws_ok($$delete from public.primary_currency$$, '42501', null, 'primary_currency: owner delete denied');
select throws_ok($$delete from public.conflict_resolutions$$, '42501', null, 'conflict_resolutions: owner delete denied');
select throws_ok($$delete from public.sync_operations$$, '42501', null, 'sync_operations: owner delete denied');
select throws_ok($$delete from public.devices$$, '42501', null, 'devices: owner delete denied');
select throws_ok($$truncate public.people cascade$$, '42501', null, 'truncate (which bypasses RLS) denied');

select throws_ok($$update public.transaction_audit_entries set change_type = 'edited' where id = 'aa'$$,
  '42501', null, 'audit entries cannot be updated');
select throws_ok($$update public.conflict_resolutions set chosen_side = 'server' where id = 'cra'$$,
  '42501', null, 'conflict resolutions cannot be updated');

-- ---------------------------------------------------------------------------
-- Guarantee 6: anon (no JWT) is denied every table and function.
-- ---------------------------------------------------------------------------
select pg_temp.logout();
set local role anon;

select throws_ok($$select 1 from public.people$$,                    '42501', null, 'anon: people denied');
select throws_ok($$select 1 from public.money_transactions$$,        '42501', null, 'anon: money_transactions denied');
select throws_ok($$select 1 from public.transaction_audit_entries$$, '42501', null, 'anon: transaction_audit_entries denied');
select throws_ok($$select 1 from public.finance_categories$$,        '42501', null, 'anon: finance_categories denied');
select throws_ok($$select 1 from public.finance_entries$$,           '42501', null, 'anon: finance_entries denied');
select throws_ok($$select 1 from public.exchange_rates$$,            '42501', null, 'anon: exchange_rates denied');
select throws_ok($$select 1 from public.primary_currency$$,          '42501', null, 'anon: primary_currency denied');
select throws_ok($$select 1 from public.conflict_resolutions$$,      '42501', null, 'anon: conflict_resolutions denied');
select throws_ok($$select 1 from public.sync_operations$$,           '42501', null, 'anon: sync_operations denied');
select throws_ok($$select 1 from public.devices$$,                   '42501', null, 'anon: devices denied');
select throws_ok($$select 1 from public.sync_owner_state$$,          '42501', null, 'anon: sync_owner_state denied');
select throws_ok($$insert into public.people (id, name, normalized_name) values ('z', 'z', 'z')$$,
  '42501', null, 'anon: insert denied');
select throws_ok($$select public.sync_push(gen_random_uuid(), '1', 'ios', '[]'::jsonb)$$,
  '42501', null, 'anon: sync_push denied');
select throws_ok($$select public.sync_pull(0, 10)$$, '42501', null, 'anon: sync_pull denied');
select throws_ok($$select public.next_revision()$$,  '42501', null, 'anon: next_revision denied');

reset role;

-- Privilege catalog checks (independent of the session).
select ok(not has_function_privilege('anon', 'public.sync_push(uuid, text, text, jsonb)', 'execute'),
  'anon has no execute on sync_push');
select ok(has_function_privilege('authenticated', 'public.sync_push(uuid, text, text, jsonb)', 'execute'),
  'authenticated can execute sync_push');
select ok(not has_function_privilege('authenticated', 'public.sync_stamp()', 'execute'),
  'sync_stamp is not granted to authenticated');
select ok(not has_table_privilege('authenticated', 'public.people', 'delete'),
  'authenticated has no DELETE on people');
select ok(not has_table_privilege('authenticated', 'public.people', 'truncate'),
  'authenticated has no TRUNCATE on people');
select is(
  (select count(*)::int from pg_policies where schemaname = 'public' and cmd in ('DELETE', 'ALL')
     and tablename <> 'sync_owner_state'),
  0, 'no delete policy exists on any business table');
select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
  0, 'every public table has RLS enabled');

select * from finish();
rollback;
