-- =============================================================================
-- 021c Offline-First Cloud Sync: owner-scoped analytics views (FR-061, FR-063)
--
-- contracts/supabase-schema.md §7. A NEW migration: earlier 021 migrations are
-- never edited. Every view is security_invoker, so the base tables' RLS scopes
-- it to the caller. Views never convert currencies (constitution VIII) and
-- skip soft-deleted rows; archived and deleted counts come from the base tables.
-- =============================================================================

-- owner x month x currency x direction x kind
create view public.v_monthly_person_flows
with (security_invoker = true)
as
select
  t.owner_id,
  date_trunc('month', t.occurred_on)::date      as month,
  t.currency_code,
  t.direction,
  t.kind,
  count(*)::bigint                              as tx_count,
  sum(t.amount_minor)::bigint                   as total_minor,
  round(avg(t.amount_minor))::bigint            as avg_minor
from public.money_transactions t
where t.deleted_at is null
group by t.owner_id, date_trunc('month', t.occurred_on), t.currency_code, t.direction, t.kind;

-- owner x person x currency
create view public.v_person_balances
with (security_invoker = true)
as
select
  p.owner_id,
  p.id                                                                         as person_id,
  p.is_archived,
  t.currency_code,
  coalesce(sum(t.amount_minor) filter (where t.direction = 'given'), 0)::bigint    as given_minor,
  coalesce(sum(t.amount_minor) filter (where t.direction = 'received'), 0)::bigint as received_minor,
  (coalesce(sum(t.amount_minor) filter (where t.direction = 'given'), 0)
   - coalesce(sum(t.amount_minor) filter (where t.direction = 'received'), 0))::bigint as net_given_minor,
  count(*)::bigint                                                             as tx_count,
  max(t.occurred_on)                                                           as last_occurred_on
from public.people p
join public.money_transactions t
  on t.owner_id = p.owner_id
 and t.person_id = p.id
 and t.deleted_at is null
where p.deleted_at is null
group by p.owner_id, p.id, p.is_archived, t.currency_code;

-- owner x month x category x currency
create view public.v_monthly_finance_by_category
with (security_invoker = true)
as
select
  e.owner_id,
  date_trunc('month', e.occurred_on)::date as month,
  e.category_id,
  e.type,
  e.currency_code,
  count(*)::bigint                         as entry_count,
  sum(e.amount_minor)::bigint              as total_minor
from public.finance_entries e
where e.deleted_at is null
group by e.owner_id, date_trunc('month', e.occurred_on), e.category_id, e.type, e.currency_code;

-- owner x day (the UTC day the server received the record). The lag is
-- server_created_at - client_created_at, which measures offline activity (FR-062).
create view public.v_daily_activity
with (security_invoker = true)
as
with created as (
  select t.owner_id,
         (t.server_created_at at time zone 'UTC')::date as day,
         true as is_transaction,
         extract(epoch from (t.server_created_at - t.client_created_at)) as lag_seconds
  from public.money_transactions t
  where t.deleted_at is null
  union all
  select e.owner_id,
         (e.server_created_at at time zone 'UTC')::date,
         false,
         extract(epoch from (e.server_created_at - e.client_created_at))
  from public.finance_entries e
  where e.deleted_at is null
)
select
  c.owner_id,
  c.day,
  count(*) filter (where c.is_transaction)::bigint     as transactions_created,
  count(*) filter (where not c.is_transaction)::bigint as entries_created,
  percentile_cont(0.5) within group (order by c.lag_seconds) as offline_lag_p50_seconds
from created c
group by c.owner_id, c.day;

-- Privileges at the END (Supabase default privileges grant new views to anon).
revoke all on
  public.v_monthly_person_flows, public.v_person_balances,
  public.v_monthly_finance_by_category, public.v_daily_activity
from anon, public, authenticated;

grant select on
  public.v_monthly_person_flows, public.v_person_balances,
  public.v_monthly_finance_by_category, public.v_daily_activity
to authenticated;
