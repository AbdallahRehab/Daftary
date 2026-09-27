-- 021 sync_push outcomes (contracts/sync-rpc.md §2, task T049).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into auth.users (id, aud, role, email)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'a@example.test');

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
  v := public.sync_push('d0d0d0d0-0000-4000-8000-000000000001', '1.2.3', 'android', p_ops);
  insert into r values (p_key, v) on conflict (k) do update set v = excluded.v;
  return v;
end $$;

create function pg_temp.res(p_key text, p_i int default 0) returns jsonb language sql as $$
  select v -> 'results' -> p_i from r where k = p_key
$$;

create function pg_temp.person(p_name text) returns jsonb language sql as $$
  select jsonb_build_object('name', p_name, 'normalized_name', lower(p_name),
    'phone_number', null, 'relationship_tag', null, 'notes', null, 'is_archived', false,
    'deleted_at', null, 'client_created_at', '2026-09-27T09:00:00.000Z',
    'client_updated_at', '2026-09-27T09:00:00.000Z')
$$;

-- Money arrives as a STRING (research Decision 17).
create function pg_temp.tx(p_person text, p_key text, p_amount text) returns jsonb language sql as $$
  select jsonb_build_object('person_id', p_person, 'idempotency_key', p_key,
    'amount_minor', p_amount, 'currency_code', 'EGP', 'direction', 'given', 'kind', 'initialExchange',
    'occurred_at', '2026-09-27T09:12:00.000Z', 'occurred_on', '2026-09-27', 'tz_offset_minutes', 180,
    'note', null, 'edited_at', null, 'deleted_at', null,
    'client_created_at', '2026-09-27T09:12:03.120Z', 'client_updated_at', '2026-09-27T09:12:03.120Z')
$$;

create function pg_temp.category(p_type text) returns jsonb language sql as $$
  select jsonb_build_object('name', 'Rent', 'normalized_name', 'rent', 'type', p_type,
    'icon_key', 'home', 'is_default', false, 'is_archived', false)
$$;

create function pg_temp.entry(p_category text, p_key text, p_type text) returns jsonb language sql as $$
  select jsonb_build_object('category_id', p_category, 'idempotency_key', p_key, 'type', p_type,
    'amount_minor', '2500', 'currency_code', 'EGP',
    'occurred_at', '2026-09-27T09:12:00.000Z', 'occurred_on', '2026-09-27', 'tz_offset_minutes', 180,
    'note', null, 'edited_at', null, 'deleted_at', null)
$$;

select pg_temp.login('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');

-- ---------------------------------------------------------------------------
-- Insert, replay by op_id, replay by idempotency key.
-- ---------------------------------------------------------------------------
select pg_temp.push('p1', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000001', 'person', 'upsert', 'p1', null, pg_temp.person('Ahmed'))));
select is(pg_temp.res('p1') ->> 'result', 'applied', 'person insert: applied');
select is((pg_temp.res('p1') ->> 'revision')::bigint, 1::bigint, 'first write of an owner gets revision 1');
select ok((select v ? 'server_time' from r where k = 'p1'), 'response carries server_time');

select pg_temp.push('t1', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000002', 'money_transaction', 'upsert', 't1', null,
             pg_temp.tx('p1', 'k1', '150000'))));
select is(pg_temp.res('t1') ->> 'result', 'applied', 'transaction insert: applied');
select is((select amount_minor from public.money_transactions where id = 't1'), 150000::bigint,
  'string money is stored as bigint');
select is((select last_device_id from public.money_transactions where id = 't1'),
  'd0d0d0d0-0000-4000-8000-000000000001'::uuid, 'last_device_id is stamped');

select pg_temp.push('t1_replay', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000002', 'money_transaction', 'upsert', 't1', null,
             pg_temp.tx('p1', 'k1', '150000'))));
select is(pg_temp.res('t1_replay') ->> 'result', 'already_applied', 'same op_id: already_applied');
select is(pg_temp.res('t1_replay') ->> 'revision', pg_temp.res('t1') ->> 'revision',
  'same op_id: original revision returned');
select is((select count(*) from public.money_transactions), 1::bigint, 'same op_id: still 1 row');

select pg_temp.push('t1_idem', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000003', 'money_transaction', 'upsert', 't1_rebuilt', null,
             pg_temp.tx('p1', 'k1', '150000'))));
select is(pg_temp.res('t1_idem') ->> 'result', 'already_applied', 'new op_id, same idempotency_key: already_applied');
select is((select count(*) from public.money_transactions), 1::bigint, 'same idempotency_key: still 1 row');

select pg_temp.push('t1_same', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000004', 'money_transaction', 'upsert', 't1', null,
             pg_temp.tx('p1', 'k1', '150000'))));
select is(pg_temp.res('t1_same') ->> 'result', 'already_applied', 'create replay with equal fields: already_applied');

select pg_temp.push('t1_diff', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000005', 'money_transaction', 'upsert', 't1', null,
             pg_temp.tx('p1', 'k1', '999'))));
select is(pg_temp.res('t1_diff') ->> 'result', 'conflict', 'create hitting a different existing row: conflict');

-- ---------------------------------------------------------------------------
-- Base-revision checks.
-- ---------------------------------------------------------------------------
select pg_temp.push('t1_edit', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000006', 'money_transaction', 'upsert', 't1',
             (pg_temp.res('t1') ->> 'revision')::bigint,
             pg_temp.tx('p1', 'k1', '2000') || '{"edited_at": "2026-09-27T10:00:00Z"}')));
select is(pg_temp.res('t1_edit') ->> 'result', 'applied', 'matching base revision: applied');
select ok((pg_temp.res('t1_edit') ->> 'revision')::bigint > (pg_temp.res('t1') ->> 'revision')::bigint,
  'an update gets a higher revision');
select is((select amount_minor from public.money_transactions where id = 't1'), 2000::bigint, 'edit written');

select pg_temp.push('t1_stale', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000007', 'money_transaction', 'upsert', 't1',
             (pg_temp.res('t1') ->> 'revision')::bigint, pg_temp.tx('p1', 'k1', '3000'))));
select is(pg_temp.res('t1_stale') ->> 'result', 'conflict', 'stale-base financial update: conflict');
select is(pg_temp.res('t1_stale') -> 'server_row' ->> 'amount_minor', '2000', 'conflict returns the server row');
select is((pg_temp.res('t1_stale') ->> 'revision')::bigint, (pg_temp.res('t1_edit') ->> 'revision')::bigint,
  'conflict returns the current revision');
select is((select amount_minor from public.money_transactions where id = 't1'), 2000::bigint, 'conflict: no write');

select pg_temp.push('t1_stale_replay', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000007', 'money_transaction', 'upsert', 't1',
             (pg_temp.res('t1') ->> 'revision')::bigint, pg_temp.tx('p1', 'k1', '3000'))));
select is(pg_temp.res('t1_stale_replay') ->> 'result', 'conflict', 'a replayed conflict op stays a conflict');

select pg_temp.push('p1_lww', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000008', 'person', 'upsert', 'p1',
             (pg_temp.res('p1') ->> 'revision')::bigint - 1, pg_temp.person('Renamed'))));
select is(pg_temp.res('p1_lww') ->> 'result', 'applied', 'stale-base last-write-wins update: applied');
select is((select name from public.people where id = 'p1'), 'Renamed', 'last write wins');

-- Stale-base delete loses to the concurrent edit.
select pg_temp.push('p2', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000009', 'person', 'upsert', 'p2', null, pg_temp.person('Mona'))));
select pg_temp.push('p2_edit', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000010', 'person', 'upsert', 'p2',
             (pg_temp.res('p2') ->> 'revision')::bigint, pg_temp.person('Mona B'))));
select pg_temp.push('p2_del', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000011', 'person', 'delete', 'p2',
             (pg_temp.res('p2') ->> 'revision')::bigint, '{}'::jsonb)));
select is(pg_temp.res('p2_del') ->> 'result', 'superseded', 'stale-base delete: superseded');
select is(pg_temp.res('p2_del') -> 'server_row' ->> 'name', 'Mona B', 'superseded returns the server row');
select is((select deleted_at from public.people where id = 'p2'), null, 'superseded: not deleted');

-- A current-base delete of a person without transactions: soft-deleted.
select pg_temp.push('p2_del_ok', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000012', 'person', 'delete', 'p2',
             (pg_temp.res('p2_edit') ->> 'revision')::bigint, '{}'::jsonb)));
select is(pg_temp.res('p2_del_ok') ->> 'result', 'applied', 'person delete without transactions: applied');
select isnt((select deleted_at from public.people where id = 'p2'), null, 'person soft-deleted (tombstone kept)');

select pg_temp.push('p2_del_again', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000013', 'person', 'delete', 'p2', null, '{}'::jsonb)));
select is(pg_temp.res('p2_del_again') ->> 'result', 'already_applied', 'deleting a deleted row: already_applied');

select pg_temp.push('p2_undelete', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000014', 'person', 'upsert', 'p2', null, pg_temp.person('Mona C'))));
select is(pg_temp.res('p2_undelete') ->> 'result', 'applied', 'upsert on a deleted last-write-wins row: applied');
select is((select deleted_at from public.people where id = 'p2'), null, 'upsert undeletes');

-- ---------------------------------------------------------------------------
-- Rule guards.
-- ---------------------------------------------------------------------------
select pg_temp.push('p1_del', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000015', 'person', 'delete', 'p1', null, '{}'::jsonb)));
select is(pg_temp.res('p1_del') ->> 'result', 'rejected', 'person delete with transactions: rejected');
select is(pg_temp.res('p1_del') ->> 'reason', 'person_has_transactions', 'reason person_has_transactions');
select is(pg_temp.res('p1_del') -> 'server_row' ->> 'id', 'p1', 'the person row is returned as server_row');
select is((select deleted_at from public.people where id = 'p1'), null, 'person kept');

-- Even a soft-deleted transaction blocks the person delete.
select pg_temp.push('t1_soft_del', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000016', 'money_transaction', 'upsert', 't1',
             (pg_temp.res('t1_edit') ->> 'revision')::bigint,
             pg_temp.tx('p1', 'k1', '2000') || '{"edited_at": "2026-09-27T10:00:00Z", "deleted_at": "2026-09-27T11:00:00Z"}')));
select is(pg_temp.res('t1_soft_del') ->> 'result', 'applied', 'transaction soft delete via upsert: applied');
select pg_temp.push('p1_del2', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000017', 'person', 'delete', 'p1', null, '{}'::jsonb)));
select is(pg_temp.res('p1_del2') ->> 'reason', 'person_has_transactions',
  'a soft-deleted transaction still blocks the person delete');

-- Category delete with entries becomes an archive.
select pg_temp.push('c1', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000018', 'finance_category', 'upsert', 'c1', null, pg_temp.category('expense')),
  pg_temp.op('00000000-0000-4000-8000-000000000019', 'finance_entry', 'upsert', 'e1', null, pg_temp.entry('c1', 'ke1', 'expense'))));
select is(pg_temp.res('c1', 1) ->> 'result', 'applied', 'entry insert: applied');
select pg_temp.push('c1_del', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000020', 'finance_category', 'delete', 'c1', null, '{}'::jsonb)));
select is(pg_temp.res('c1_del') ->> 'result', 'applied', 'category delete with entries: applied');
select is(pg_temp.res('c1_del') -> 'server_row' ->> 'is_archived', 'true', 'the archived category is returned');
select is((select is_archived from public.finance_categories where id = 'c1'), true, 'category archived');
select is((select deleted_at from public.finance_categories where id = 'c1'), null, 'category not deleted');

-- Category delete without entries is a soft delete.
select pg_temp.push('c2', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000021', 'finance_category', 'upsert', 'c2', null, pg_temp.category('income')),
  pg_temp.op('00000000-0000-4000-8000-000000000022', 'finance_category', 'delete', 'c2', null, '{}'::jsonb)));
select is(pg_temp.res('c2', 1) ->> 'result', 'applied', 'unreferenced category delete: applied');
select isnt((select deleted_at from public.finance_categories where id = 'c2'), null, 'unreferenced category soft-deleted');

-- Type mismatch.
select pg_temp.push('e_mismatch', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000023', 'finance_entry', 'upsert', 'e2', null, pg_temp.entry('c1', 'ke2', 'income'))));
select is(pg_temp.res('e_mismatch') ->> 'result', 'rejected', 'type mismatch: rejected');
select is(pg_temp.res('e_mismatch') ->> 'reason', 'category_type_mismatch', 'reason category_type_mismatch');
select is((select count(*) from public.finance_entries where id = 'e2'), 0::bigint, 'mismatched entry not written');

-- ---------------------------------------------------------------------------
-- missing_parent is transient: not recorded, so the retry applies.
-- ---------------------------------------------------------------------------
select pg_temp.push('orphan', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000024', 'money_transaction', 'upsert', 't_orphan', null,
             pg_temp.tx('p_later', 'k_orphan', '100'))));
select is(pg_temp.res('orphan') ->> 'result', 'rejected', 'transaction without its person: rejected');
select is(pg_temp.res('orphan') ->> 'reason', 'missing_parent', 'reason missing_parent');
select is((select count(*) from public.sync_operations where op_id = '00000000-0000-4000-8000-000000000024'),
  0::bigint, 'missing_parent is not recorded in the ledger');

select pg_temp.push('orphan_retry', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000025', 'person', 'upsert', 'p_later', null, pg_temp.person('Later')),
  pg_temp.op('00000000-0000-4000-8000-000000000024', 'money_transaction', 'upsert', 't_orphan', null,
             pg_temp.tx('p_later', 'k_orphan', '100'))));
select is(pg_temp.res('orphan_retry', 1) ->> 'result', 'applied', 'retry of the same op_id after the parent: applied');

-- ---------------------------------------------------------------------------
-- A bad operation never aborts the batch (FR-029).
-- ---------------------------------------------------------------------------
select pg_temp.push('batch3', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000026', 'money_transaction', 'upsert', 'tb1', null, pg_temp.tx('p1', 'kb1', '10')),
  pg_temp.op('00000000-0000-4000-8000-000000000027', 'money_transaction', 'upsert', 'tb2', null, pg_temp.tx('p1', 'kb2', '-5')),
  pg_temp.op('00000000-0000-4000-8000-000000000028', 'money_transaction', 'upsert', 'tb3', null, pg_temp.tx('p1', 'kb3', '30'))));
select is(pg_temp.res('batch3', 0) ->> 'result', 'applied', 'batch op 1: applied');
select is(pg_temp.res('batch3', 1) ->> 'result', 'rejected', 'batch op 2 (invalid amount): rejected');
select is(pg_temp.res('batch3', 1) ->> 'reason', 'validation', 'batch op 2: reason validation');
select is(pg_temp.res('batch3', 2) ->> 'result', 'applied', 'batch op 3: applied');
select is((select count(*) from public.money_transactions where id in ('tb1', 'tb2', 'tb3')), 2::bigint,
  'the 2 valid operations are written');
select is((pg_temp.res('batch3', 1) ->> 'op_id'), '00000000-0000-4000-8000-000000000027', 'results keep request order');

select pg_temp.push('bad_input', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000029', 'money_transaction', 'upsert', 'tb4', null,
             pg_temp.tx('p1', 'kb4', 'not-a-number')),
  pg_temp.op('00000000-0000-4000-8000-000000000030', 'spaceship', 'upsert', 'x', null, '{}'::jsonb),
  pg_temp.op('00000000-0000-4000-8000-000000000031', 'money_transaction', 'delete', 'tb1', null, '{}'::jsonb),
  pg_temp.op('not-a-uuid', 'person', 'upsert', 'x', null, pg_temp.person('X'))));
select is(pg_temp.res('bad_input', 0) ->> 'reason', 'validation', 'unparsable money: rejected validation');
select is(pg_temp.res('bad_input', 1) ->> 'reason', 'unknown_entity', 'unknown entity type: rejected unknown_entity');
select is(pg_temp.res('bad_input', 2) ->> 'reason', 'validation', 'delete op on a financial type: rejected validation');
select is(pg_temp.res('bad_input', 3) ->> 'reason', 'validation', 'malformed op_id: rejected validation');

-- ---------------------------------------------------------------------------
-- Append-only and other types.
-- ---------------------------------------------------------------------------
select pg_temp.push('audit', jsonb_build_array(
  pg_temp.op('00000000-0000-4000-8000-000000000032', 'transaction_audit', 'upsert', 'au1', null,
    '{"transaction_id": "t1", "change_type": "edited", "previous_values": {"amount_minor": "150000"}, "changed_at": "2026-09-27T10:00:00Z"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000033', 'transaction_audit', 'upsert', 'au1', 5,
    '{"transaction_id": "t1", "change_type": "deleted", "previous_values": null, "changed_at": "2026-09-27T10:00:00Z"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000034', 'conflict_resolution', 'upsert', 'cr1', null,
    '{"entity_type": "money_transaction", "entity_id": "t1", "chosen_side": "local", "discarded_values": {"amount_minor": "3000"}, "resolved_at": "2026-09-27T10:00:00Z"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000035', 'exchange_rate', 'upsert', 'rate_USD_EGP', null,
    '{"currency_code": "USD", "relative_to_currency_code": "EGP", "rate_micros": "48250000"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000036', 'primary_currency', 'upsert', 'singleton', null,
    '{"currency_code": "EGP"}'),
  pg_temp.op('00000000-0000-4000-8000-000000000037', 'exchange_rate', 'upsert', 'rate_bad', null,
    '{"currency_code": "USD", "relative_to_currency_code": "EGP", "rate_micros": "1"}')));
select is(pg_temp.res('audit', 0) ->> 'result', 'applied', 'audit insert: applied');
select is(pg_temp.res('audit', 1) ->> 'result', 'already_applied', 'append-only rewrite: already_applied');
select is((select change_type from public.transaction_audit_entries where id = 'au1'), 'edited', 'audit row unchanged');
select is(pg_temp.res('audit', 2) ->> 'result', 'applied', 'conflict_resolution insert: applied');
select is(pg_temp.res('audit', 3) ->> 'result', 'applied', 'exchange rate upsert: applied');
select is(pg_temp.res('audit', 4) ->> 'result', 'applied', 'primary currency upsert: applied');
select is(pg_temp.res('audit', 5) ->> 'reason', 'validation', 'rate id not matching its pair: rejected');

-- ---------------------------------------------------------------------------
-- Limits, ledger, devices, revisions.
-- ---------------------------------------------------------------------------
select throws_ok(
  $$select public.sync_push('d0d0d0d0-0000-4000-8000-000000000001', '1.2.3', 'android',
      (select jsonb_agg(pg_temp.op(gen_random_uuid()::text, 'person', 'upsert', 'bulk' || g, null, pg_temp.person('P' || g)))
         from generate_series(1, 101) g))$$,
  '22023', 'too_many_operations', '101 operations are rejected');
select is((select count(*) from public.people where id like 'bulk%'), 0::bigint, 'nothing from the 101-op batch is written');

select lives_ok(
  $$select public.sync_push('d0d0d0d0-0000-4000-8000-000000000001', '1.2.3', 'android',
      (select jsonb_agg(pg_temp.op(gen_random_uuid()::text, 'person', 'upsert', 'bulk' || g, null, pg_temp.person('P' || g)))
         from generate_series(1, 100) g))$$,
  '100 operations are accepted');

select throws_ok(
  $$select public.sync_push('d0d0d0d0-0000-4000-8000-000000000001', '1.2.3', 'windows', '[]'::jsonb)$$,
  '22023', 'invalid_platform', 'unknown platform rejected');

select is((select result from public.sync_operations where op_id = '00000000-0000-4000-8000-000000000001'),
  'applied', 'applied operations are recorded in the ledger');
select is((select reason from public.sync_operations where op_id = '00000000-0000-4000-8000-000000000015'),
  'person_has_transactions', 'final rejections are recorded with their reason');
select is((select app_version from public.devices where device_id = 'd0d0d0d0-0000-4000-8000-000000000001'),
  '1.2.3', 'the device row is upserted');
select isnt((select last_sync_at from public.devices where device_id = 'd0d0d0d0-0000-4000-8000-000000000001'),
  null, 'the device last_sync_at is set');

-- Revisions are unique across tables and never exceed the owner counter.
select is(
  (with all_rows as (
     select revision from public.people union all
     select revision from public.money_transactions union all
     select revision from public.transaction_audit_entries union all
     select revision from public.finance_categories union all
     select revision from public.finance_entries union all
     select revision from public.exchange_rates union all
     select revision from public.primary_currency union all
     select revision from public.conflict_resolutions)
   select count(*) = count(distinct revision)
      and max(revision) <= (select last_revision from public.sync_owner_state)
   from all_rows),
  true, 'revisions are unique per owner and bounded by the counter');

-- Within one batch, successive writes get strictly increasing revisions.
select ok(
  (pg_temp.res('audit', 0) ->> 'revision')::bigint < (pg_temp.res('audit', 2) ->> 'revision')::bigint
  and (pg_temp.res('audit', 2) ->> 'revision')::bigint < (pg_temp.res('audit', 3) ->> 'revision')::bigint
  and (pg_temp.res('audit', 3) ->> 'revision')::bigint < (pg_temp.res('audit', 4) ->> 'revision')::bigint,
  'revisions increase monotonically');

select * from finish();
rollback;
