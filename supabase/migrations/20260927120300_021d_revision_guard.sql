-- 021: the per-owner revision counter must only move forward. Clients hold
-- UPDATE on sync_owner_state (next_revision() runs as the invoker), so without
-- this guard a tampered client could lower its own counter, reuse revisions,
-- and make its other devices' `revision > cursor` pulls skip changes.

create function public.sync_owner_state_forward_only() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  if new.owner_id <> old.owner_id then
    raise exception 'immutable_identity' using errcode = '23514';
  end if;
  if new.last_revision < old.last_revision then
    raise exception 'revision_regression' using errcode = '23514';
  end if;
  return new;
end $$;

create trigger sync_owner_state_forward_only
  before update on public.sync_owner_state
  for each row execute function public.sync_owner_state_forward_only();

revoke all on function public.sync_owner_state_forward_only() from anon, authenticated, public;
