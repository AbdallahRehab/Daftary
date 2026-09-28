-- 021: sync_owner_state.last_revision is forward-only and server-owned (021d, 021e).
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

insert into auth.users (id, aud, role, email)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'a@example.test');

select set_config('request.jwt.claims',
  json_build_object('sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'role', 'authenticated')::text, true);
select set_config('role', 'authenticated', true);

select public.next_revision();
select public.next_revision();

-- 021e: clients have no direct write access to the counter.
select throws_ok(
  $$update public.sync_owner_state set last_revision = 0$$,
  '42501', null,
  'a client cannot write its revision counter directly');

-- The forward-only trigger still guards privileged writers.
reset role;
select throws_ok(
  $$update public.sync_owner_state set last_revision = 0
    where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'$$,
  '23514', 'revision_regression',
  'the counter cannot be lowered');

select lives_ok(
  $$update public.sync_owner_state set last_revision = last_revision + 5
    where owner_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'$$,
  'moving the counter forward is allowed');

select set_config('role', 'authenticated', true);
select is(public.next_revision(), 8::bigint, 'next_revision keeps counting forward');

select * from finish();
rollback;
