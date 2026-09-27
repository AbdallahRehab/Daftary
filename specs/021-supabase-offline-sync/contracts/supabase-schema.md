# Contract: Supabase Postgres Schema

**Feature**: 021-supabase-offline-sync

This contract is the definition that the migration file `supabase/migrations/<ts>_021_offline_sync.sql` must implement. The SQL below is **normative for names, types, constraints and policies**. The final migration may reformat it but must not weaken it.

It follows the `supabase-postgres-best-practices` guidance:

- `(select auth.uid())` inside policies;
- an index on every column used by a policy or a foreign key;
- lowercase identifiers;
- `bigint` for money;
- `security_invoker` views;
- `search_path = ''` on functions.

---

## 0. Privileges

```sql
-- Supabase's default privileges grant new public tables and functions to anon, authenticated and public.
-- These revokes therefore go at the END of the migration, after every table, function and view exists:
revoke all on all tables    in schema public from anon;
revoke all on all functions in schema public from anon, public;
grant execute on function public.sync_push(uuid, text, text, jsonb), public.sync_pull(bigint, int) to authenticated;
-- next_revision() and sync_stamp() are called only from triggers and RPCs, and are not granted to any client role.
-- Every later 021 migration (sync_pull, views) repeats the relevant revokes and grants for its own objects.
-- anon (not signed in) gets nothing. Anonymous *users* use the authenticated role.
-- authenticated gets DML only through the RLS policies below.
-- There is NO delete policy on any business table, so physical deletes are impossible (FR-015).
```

## 1. Revision counter and stamping

```sql
create table public.sync_owner_state (
  owner_id      uuid primary key references auth.users on delete cascade,
  last_revision bigint not null default 0
);
alter table public.sync_owner_state enable row level security;
create policy sync_owner_state_own on public.sync_owner_state
  for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- The row lock taken by this upsert serializes one owner's writes until commit,
-- so revisions commit in increasing order (research Decision 4).
create function public.next_revision() returns bigint
language sql security invoker set search_path = '' as $$
  insert into public.sync_owner_state as s (owner_id, last_revision)
  values ((select auth.uid()), 1)
  on conflict (owner_id) do update set last_revision = s.last_revision + 1
  returning last_revision;
$$;

-- Attached BEFORE INSERT OR UPDATE to every synced table.
create function public.sync_stamp() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    new.owner_id := (select auth.uid());
    new.server_created_at := now();
  elsif new.owner_id <> old.owner_id or new.id <> old.id then
    raise exception 'immutable_identity' using errcode = '23514';
  end if;
  new.revision := public.next_revision();
  new.server_updated_at := now();
  return new;
end $$;
```

## 2. Common column block (on every synced table)

```sql
  owner_id           uuid        not null default auth.uid() references auth.users on delete cascade,
  id                 text        not null check (char_length(id) between 1 and 64),
  revision           bigint      not null,
  client_created_at  timestamptz,
  client_updated_at  timestamptz,
  server_created_at  timestamptz not null default now(),
  server_updated_at  timestamptz not null default now(),
  deleted_at         timestamptz,
  last_device_id     uuid,
  primary key (owner_id, id)
-- plus, per table:
create index <t>_owner_revision_idx on public.<t> (owner_id, revision);
create trigger <t>_stamp before insert or update on public.<t>
  for each row execute function public.sync_stamp();
alter table public.<t> enable row level security;
```

## 3. Business tables

```sql
create table public.people (
  <common>,
  name             text not null check (char_length(name) between 1 and 200),
  normalized_name  text not null,
  phone_number     text check (char_length(phone_number) <= 40),
  relationship_tag text check (char_length(relationship_tag) <= 60),
  notes            text check (char_length(notes) <= 2000),
  is_archived      boolean not null default false
);
create index people_owner_archived_idx on public.people (owner_id, is_archived);

create table public.money_transactions (
  <common>,
  person_id         text   not null,
  idempotency_key   text   not null,
  amount_minor      bigint not null check (amount_minor > 0),
  currency_code     char(3) not null check (currency_code ~ '^[A-Z]{3}$'),
  direction         text   not null check (direction in ('given','received')),
  kind              text   not null check (kind in ('initialExchange','repayment')),
  occurred_at       timestamptz not null,
  occurred_on       date   not null,
  tz_offset_minutes smallint not null check (tz_offset_minutes between -840 and 840),
  note              text check (char_length(note) <= 2000),
  edited_at         timestamptz,
  foreign key (owner_id, person_id) references public.people (owner_id, id),
  unique (owner_id, idempotency_key)
);
create index money_transactions_person_idx on public.money_transactions (owner_id, person_id);
create index money_transactions_occurred_idx on public.money_transactions (owner_id, occurred_on) where deleted_at is null;

create table public.transaction_audit_entries (
  <common>,
  transaction_id  text not null,
  change_type     text not null,          -- existing local values: created | edited | deleted
  previous_values jsonb,
  changed_at      timestamptz not null,
  foreign key (owner_id, transaction_id) references public.money_transactions (owner_id, id)
);
create index transaction_audit_tx_idx on public.transaction_audit_entries (owner_id, transaction_id);

create table public.finance_categories (
  <common>,
  name            text not null check (char_length(name) between 1 and 100),
  normalized_name text not null,
  type            text not null check (type in ('income','expense')),
  icon_key        text not null,
  is_default      boolean not null default false,
  is_archived     boolean not null default false
);
create index finance_categories_type_idx on public.finance_categories (owner_id, type);

create table public.finance_entries (
  <common>,
  category_id       text   not null,
  idempotency_key   text   not null,
  type              text   not null check (type in ('income','expense')),
  amount_minor      bigint not null check (amount_minor > 0),
  currency_code     char(3) not null check (currency_code ~ '^[A-Z]{3}$'),
  occurred_at       timestamptz not null,
  occurred_on       date   not null,
  tz_offset_minutes smallint not null check (tz_offset_minutes between -840 and 840),
  note              text check (char_length(note) <= 2000),
  edited_at         timestamptz,
  foreign key (owner_id, category_id) references public.finance_categories (owner_id, id),
  unique (owner_id, idempotency_key)
);
create index finance_entries_category_idx on public.finance_entries (owner_id, category_id);
create index finance_entries_occurred_idx on public.finance_entries (owner_id, occurred_on) where deleted_at is null;
-- Trigger finance_entry_type_matches_category (BEFORE INSERT OR UPDATE):
-- raises errcode 23514 'category_type_mismatch' when the type differs from the category's type.

create table public.exchange_rates (
  <common>,
  currency_code             char(3) not null check (currency_code ~ '^[A-Z]{3}$'),
  relative_to_currency_code char(3) not null check (relative_to_currency_code ~ '^[A-Z]{3}$'),
  rate_micros               bigint  not null check (rate_micros > 0),
  check (id = 'rate_' || currency_code || '_' || relative_to_currency_code)
);
-- Id = pair (research Decision 9), so the primary key already enforces "one row per pair per owner".

create table public.primary_currency (
  <common>,
  currency_code char(3) not null check (currency_code ~ '^[A-Z]{3}$'),
  check (id = 'singleton')
);

create table public.conflict_resolutions (
  <common>,
  entity_type      text not null check (entity_type in ('money_transaction','finance_entry')),
  entity_id        text not null,
  chosen_side      text not null check (chosen_side in ('local','server')),
  discarded_values jsonb not null,
  resolved_at      timestamptz not null
);
```

## 4. Rule guards (triggers)

| Trigger | Table | Rule | Error |
| --- | --- | --- | --- |
| `people_guard_delete` | `people`, BEFORE UPDATE when `deleted_at` changes from null to not null | Rejects the delete if any `money_transactions` row with this `person_id` exists, including soft-deleted rows (spec 001 FR-017). | `P0001`, message `person_has_transactions` |
| `finance_entry_type_matches_category` | `finance_entries` | `type` must equal the category's `type`. | `23514`, message `category_type_mismatch` |
| `append_only` | `transaction_audit_entries`, `conflict_resolutions` | Enforced by having no UPDATE policy. | RLS denial |

The rule that a category delete becomes an archive is applied inside `sync_push`, not in a trigger (contracts/sync-rpc.md).

## 5. Row-level security policies (the same shape on every synced table)

```sql
create policy <t>_select on public.<t> for select to authenticated
  using (owner_id = (select auth.uid()));
create policy <t>_insert on public.<t> for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy <t>_update on public.<t> for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
-- NO delete policy. Append-only tables (audit, conflict_resolutions) get NO update policy.
```

Both `sync_operations` and `devices` have owner-only select, insert and update policies.

## 6. Server-only tables

```sql
create table public.sync_operations (
  owner_id   uuid not null default auth.uid() references auth.users on delete cascade,
  op_id      uuid not null,
  entity_type text not null,
  entity_id   text not null,
  result     text not null check (result in ('applied','already_applied','conflict','superseded','rejected')),
  revision   bigint,
  reason     text,
  applied_at timestamptz not null default now(),
  primary key (owner_id, op_id)
);
-- Retention: rows older than 90 days may be pruned. Replays older than that are
-- still caught by the idempotency_key and existing-row checks (research Decision 6).

create table public.devices (
  owner_id     uuid not null default auth.uid() references auth.users on delete cascade,
  device_id    uuid not null,
  platform     text not null check (platform in ('android','ios')),
  app_version  text not null,
  first_seen_at timestamptz not null default now(),
  last_sync_at  timestamptz,
  primary key (owner_id, device_id)
);
```

## 7. Analytics views (FR-063), all `with (security_invoker = true)`

| View | Grain | Columns |
| --- | --- | --- |
| `v_monthly_person_flows` | owner × month × currency × direction × kind | `month date` (`date_trunc('month', occurred_on)`), `currency_code`, `direction`, `kind`, `tx_count`, `total_minor`, `avg_minor` |
| `v_person_balances` | owner × person × currency | `person_id`, `is_archived`, `currency_code`, `given_minor`, `received_minor`, `net_given_minor` (= given − received), `tx_count`, `last_occurred_on` |
| `v_monthly_finance_by_category` | owner × month × category × currency | `month`, `category_id`, `type`, `currency_code`, `entry_count`, `total_minor` |
| `v_daily_activity` | owner × day | `day`, `transactions_created`, `entries_created`, `offline_lag_p50_seconds` (from `server_created_at − client_created_at`) |

Every view filters `deleted_at is null`, except the archived and deleted counts, which are derivable from the base tables. Views never convert currencies: conversion stays in the app (constitution VIII).

## 8. Isolation guarantees to prove in pgTAP (`supabase/tests/021_rls.test.sql`)

1. User B selects each table and view → 0 rows belonging to user A.
2. User B inserts with `owner_id = A` → the value is overwritten to B by the stamp trigger, or rejected by the check.
3. User B updates or soft-deletes a row of A's → 0 rows affected.
4. A `delete from <t>` by the owner → denied, because there is no delete policy.
5. An update of an audit or conflict-resolution row → denied.
6. The `anon` role (no JWT) → permission denied on every table, view and function.
7. `sync_push` and `sync_pull` called as B never touch or return A's rows.
