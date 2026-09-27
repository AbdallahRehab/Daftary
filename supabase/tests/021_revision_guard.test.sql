-- 021: sync_owner_state.last_revision is forward-only.
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

insert into auth.users (id, aud, role, email)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'a@example.test');

select set_config('request.jwt.claims',
  json_build_object('sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'role', 'authenticated')::text, true);
select set_config('role', 'authenticated', true);

select public.next_revision();
select public.next_revision();

select throws_ok(
  $$update public.sync_owner_state set last_revision = 0$$,
  '23514', 'revision_regression',
  'a client cannot lower its revision counter');

select lives_ok(
  $$update public.sync_owner_state set last_revision = last_revision + 5$$,
  'moving the counter forward is allowed');

select is(public.next_revision(), 8::bigint, 'next_revision keeps counting forward');

select * from finish();
rollback;
