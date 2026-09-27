-- =============================================================================
-- 021b Offline-First Cloud Sync: sync_pull (contracts/sync-rpc.md §3)
--
-- A NEW migration: the already-deployed _021_offline_sync.sql is never edited.
-- =============================================================================

create function public.sync_pull(p_since bigint, p_limit int default 500)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_uid     uuid   := (select auth.uid());
  v_since   bigint := coalesce(p_since, 0);
  v_limit   int    := least(greatest(coalesce(p_limit, 500), 1), 1000);
  v_changes jsonb;
  v_max     bigint;
  v_count   int;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  -- Each branch reads at most limit + 1 rows through its (owner_id, revision)
  -- index; the extra row tells whether another page exists. Tombstones
  -- (deleted_at not null) are included. Per-owner revisions are unique across
  -- the 8 tables, so ordering by revision keeps causal order (a person is
  -- always before the transactions created after it).
  with candidates as (
    (select 'person'::text as entity_type, t.revision, to_jsonb(t) as row
       from public.people t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'money_transaction', t.revision, to_jsonb(t)
       from public.money_transactions t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'transaction_audit', t.revision, to_jsonb(t)
       from public.transaction_audit_entries t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'finance_category', t.revision, to_jsonb(t)
       from public.finance_categories t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'finance_entry', t.revision, to_jsonb(t)
       from public.finance_entries t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'exchange_rate', t.revision, to_jsonb(t)
       from public.exchange_rates t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'primary_currency', t.revision, to_jsonb(t)
       from public.primary_currency t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'conflict_resolution', t.revision, to_jsonb(t)
       from public.conflict_resolutions t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
  ),
  ranked as (
    select c.entity_type, c.revision, c.row,
           row_number() over (order by c.revision) as rn
    from candidates c
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_build_object('entity_type', r.entity_type, 'revision', r.revision, 'row', r.row)
        order by r.revision
      ) filter (where r.rn <= v_limit),
      '[]'::jsonb),
    max(r.revision) filter (where r.rn <= v_limit),
    count(*)::int
  into v_changes, v_max, v_count
  from ranked r;

  return jsonb_build_object(
    'changes',      v_changes,
    'max_revision', coalesce(v_max, v_since),
    'has_more',     v_count > v_limit
  );
end
$$;

comment on function public.sync_pull(bigint, int) is
  'Returns one page of owner changes with revision > p_since across the 8 synced tables, ordered by revision. See specs/021-supabase-offline-sync/contracts/sync-rpc.md §3.';

-- Privileges at the END (Supabase default privileges grant new functions to anon/public).
revoke all on function public.sync_pull(bigint, int) from anon, public;
grant execute on function public.sync_pull(bigint, int) to authenticated;
