-- =============================================================================
-- 021 Offline-First Cloud Sync: backend foundation
--
-- Implements specs/021-supabase-offline-sync/contracts/supabase-schema.md
-- (§0-§6) and contracts/sync-rpc.md §2 (sync_push).
--
-- Sections:
--   1. Revision counter and stamping (sync_owner_state, next_revision, sync_stamp)
--   2. Server-only tables (sync_operations, devices)
--   3. The 8 synced business tables + row-level security
--   4. Rule-guard triggers
--   5. sync_push
--   6. Privileges (at the END: Supabase default privileges re-grant new objects)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Revision counter and stamping (research Decision 4)
-- -----------------------------------------------------------------------------

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
-- so revisions commit in increasing order.
create function public.next_revision()
returns bigint
language sql
security invoker
set search_path = ''
as $$
  insert into public.sync_owner_state as s (owner_id, last_revision)
  values ((select auth.uid()), 1)
  on conflict (owner_id) do update set last_revision = s.last_revision + 1
  returning last_revision;
$$;

-- Attached BEFORE INSERT OR UPDATE to every synced table.
create function public.sync_stamp()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.owner_id := (select auth.uid());
    new.server_created_at := now();
  elsif new.owner_id <> old.owner_id or new.id <> old.id then
    raise exception 'immutable_identity' using errcode = '23514';
  else
    new.server_created_at := old.server_created_at;
  end if;
  new.revision := public.next_revision();
  new.server_updated_at := now();
  return new;
end
$$;


-- -----------------------------------------------------------------------------
-- 2. Server-only tables
-- -----------------------------------------------------------------------------

-- Operation ledger (research Decision 6). Rows older than 90 days may be pruned;
-- older replays are still caught by idempotency_key and existing-row checks.
create table public.sync_operations (
  owner_id    uuid not null default auth.uid() references auth.users on delete cascade,
  op_id       uuid not null,
  entity_type text not null,
  entity_id   text not null,
  result      text not null
              check (result in ('applied','already_applied','conflict','superseded','rejected')),
  revision    bigint,
  reason      text,
  applied_at  timestamptz not null default now(),
  primary key (owner_id, op_id)
);
alter table public.sync_operations enable row level security;

create policy sync_operations_select on public.sync_operations for select to authenticated
  using (owner_id = (select auth.uid()));
create policy sync_operations_insert on public.sync_operations for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy sync_operations_update on public.sync_operations for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create index sync_operations_applied_at_idx on public.sync_operations (applied_at);

-- Diagnostics (FR-064).
create table public.devices (
  owner_id      uuid not null default auth.uid() references auth.users on delete cascade,
  device_id     uuid not null,
  platform      text not null check (platform in ('android','ios')),
  app_version   text not null,
  first_seen_at timestamptz not null default now(),
  last_sync_at  timestamptz,
  primary key (owner_id, device_id)
);
alter table public.devices enable row level security;

create policy devices_select on public.devices for select to authenticated
  using (owner_id = (select auth.uid()));
create policy devices_insert on public.devices for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy devices_update on public.devices for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));


-- -----------------------------------------------------------------------------
-- 3. Synced business tables
--    Common block: owner_id, id, revision, client_*_at, server_*_at, deleted_at,
--    last_device_id, primary key (owner_id, id), (owner_id, revision) index,
--    sync_stamp trigger, RLS with select/insert/update policies, NO delete policy.
-- -----------------------------------------------------------------------------

-- people ---------------------------------------------------------------------
create table public.people (
  owner_id           uuid        not null default auth.uid() references auth.users on delete cascade,
  id                 text        not null check (char_length(id) between 1 and 64),
  revision           bigint      not null,
  client_created_at  timestamptz,
  client_updated_at  timestamptz,
  server_created_at  timestamptz not null default now(),
  server_updated_at  timestamptz not null default now(),
  deleted_at         timestamptz,
  last_device_id     uuid,
  name               text not null check (char_length(name) between 1 and 200),
  normalized_name    text not null,
  phone_number       text check (char_length(phone_number) <= 40),
  relationship_tag   text check (char_length(relationship_tag) <= 60),
  notes              text check (char_length(notes) <= 2000),
  is_archived        boolean not null default false,
  primary key (owner_id, id)
);
create index people_owner_revision_idx on public.people (owner_id, revision);
create index people_owner_archived_idx on public.people (owner_id, is_archived);
create trigger people_stamp before insert or update on public.people
  for each row execute function public.sync_stamp();
alter table public.people enable row level security;
create policy people_select on public.people for select to authenticated
  using (owner_id = (select auth.uid()));
create policy people_insert on public.people for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy people_update on public.people for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- money_transactions -----------------------------------------------------------
create table public.money_transactions (
  owner_id           uuid        not null default auth.uid() references auth.users on delete cascade,
  id                 text        not null check (char_length(id) between 1 and 64),
  revision           bigint      not null,
  client_created_at  timestamptz,
  client_updated_at  timestamptz,
  server_created_at  timestamptz not null default now(),
  server_updated_at  timestamptz not null default now(),
  deleted_at         timestamptz,
  last_device_id     uuid,
  person_id          text    not null,
  idempotency_key    text    not null,
  amount_minor       bigint  not null check (amount_minor > 0),
  currency_code      char(3) not null check (currency_code ~ '^[A-Z]{3}$'),
  direction          text    not null check (direction in ('given','received')),
  kind               text    not null check (kind in ('initialExchange','repayment')),
  occurred_at        timestamptz not null,
  occurred_on        date    not null,
  tz_offset_minutes  smallint not null check (tz_offset_minutes between -840 and 840),
  note               text check (char_length(note) <= 2000),
  edited_at          timestamptz,
  primary key (owner_id, id),
  foreign key (owner_id, person_id) references public.people (owner_id, id),
  unique (owner_id, idempotency_key)
);
create index money_transactions_owner_revision_idx on public.money_transactions (owner_id, revision);
create index money_transactions_person_idx on public.money_transactions (owner_id, person_id);
create index money_transactions_occurred_idx on public.money_transactions (owner_id, occurred_on)
  where deleted_at is null;
create trigger money_transactions_stamp before insert or update on public.money_transactions
  for each row execute function public.sync_stamp();
alter table public.money_transactions enable row level security;
create policy money_transactions_select on public.money_transactions for select to authenticated
  using (owner_id = (select auth.uid()));
create policy money_transactions_insert on public.money_transactions for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy money_transactions_update on public.money_transactions for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- transaction_audit_entries (append-only: no update policy) -----------------------
create table public.transaction_audit_entries (
  owner_id           uuid        not null default auth.uid() references auth.users on delete cascade,
  id                 text        not null check (char_length(id) between 1 and 64),
  revision           bigint      not null,
  client_created_at  timestamptz,
  client_updated_at  timestamptz,
  server_created_at  timestamptz not null default now(),
  server_updated_at  timestamptz not null default now(),
  deleted_at         timestamptz,
  last_device_id     uuid,
  transaction_id     text not null,
  change_type        text not null,          -- existing local values: created | edited | deleted
  previous_values    jsonb,
  changed_at         timestamptz not null,
  primary key (owner_id, id),
  foreign key (owner_id, transaction_id) references public.money_transactions (owner_id, id)
);
create index transaction_audit_entries_owner_revision_idx on public.transaction_audit_entries (owner_id, revision);
create index transaction_audit_tx_idx on public.transaction_audit_entries (owner_id, transaction_id);
create trigger transaction_audit_entries_stamp before insert or update on public.transaction_audit_entries
  for each row execute function public.sync_stamp();
alter table public.transaction_audit_entries enable row level security;
create policy transaction_audit_entries_select on public.transaction_audit_entries for select to authenticated
  using (owner_id = (select auth.uid()));
create policy transaction_audit_entries_insert on public.transaction_audit_entries for insert to authenticated
  with check (owner_id = (select auth.uid()));

-- finance_categories -------------------------------------------------------------
create table public.finance_categories (
  owner_id           uuid        not null default auth.uid() references auth.users on delete cascade,
  id                 text        not null check (char_length(id) between 1 and 64),
  revision           bigint      not null,
  client_created_at  timestamptz,
  client_updated_at  timestamptz,
  server_created_at  timestamptz not null default now(),
  server_updated_at  timestamptz not null default now(),
  deleted_at         timestamptz,
  last_device_id     uuid,
  name               text not null check (char_length(name) between 1 and 100),
  normalized_name    text not null,
  type               text not null check (type in ('income','expense')),
  icon_key           text not null,
  is_default         boolean not null default false,
  is_archived        boolean not null default false,
  primary key (owner_id, id)
);
create index finance_categories_owner_revision_idx on public.finance_categories (owner_id, revision);
create index finance_categories_type_idx on public.finance_categories (owner_id, type);
create trigger finance_categories_stamp before insert or update on public.finance_categories
  for each row execute function public.sync_stamp();
alter table public.finance_categories enable row level security;
create policy finance_categories_select on public.finance_categories for select to authenticated
  using (owner_id = (select auth.uid()));
create policy finance_categories_insert on public.finance_categories for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy finance_categories_update on public.finance_categories for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- finance_entries ------------------------------------------------------------------
create table public.finance_entries (
  owner_id           uuid        not null default auth.uid() references auth.users on delete cascade,
  id                 text        not null check (char_length(id) between 1 and 64),
  revision           bigint      not null,
  client_created_at  timestamptz,
  client_updated_at  timestamptz,
  server_created_at  timestamptz not null default now(),
  server_updated_at  timestamptz not null default now(),
  deleted_at         timestamptz,
  last_device_id     uuid,
  category_id        text    not null,
  idempotency_key    text    not null,
  type               text    not null check (type in ('income','expense')),
  amount_minor       bigint  not null check (amount_minor > 0),
  currency_code      char(3) not null check (currency_code ~ '^[A-Z]{3}$'),
  occurred_at        timestamptz not null,
  occurred_on        date    not null,
  tz_offset_minutes  smallint not null check (tz_offset_minutes between -840 and 840),
  note               text check (char_length(note) <= 2000),
  edited_at          timestamptz,
  primary key (owner_id, id),
  foreign key (owner_id, category_id) references public.finance_categories (owner_id, id),
  unique (owner_id, idempotency_key)
);
create index finance_entries_owner_revision_idx on public.finance_entries (owner_id, revision);
create index finance_entries_category_idx on public.finance_entries (owner_id, category_id);
create index finance_entries_occurred_idx on public.finance_entries (owner_id, occurred_on)
  where deleted_at is null;
create trigger finance_entries_stamp before insert or update on public.finance_entries
  for each row execute function public.sync_stamp();
alter table public.finance_entries enable row level security;
create policy finance_entries_select on public.finance_entries for select to authenticated
  using (owner_id = (select auth.uid()));
create policy finance_entries_insert on public.finance_entries for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy finance_entries_update on public.finance_entries for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- exchange_rates (id = pair, research Decision 9) -------------------------------------
create table public.exchange_rates (
  owner_id                  uuid        not null default auth.uid() references auth.users on delete cascade,
  id                        text        not null check (char_length(id) between 1 and 64),
  revision                  bigint      not null,
  client_created_at         timestamptz,
  client_updated_at         timestamptz,
  server_created_at         timestamptz not null default now(),
  server_updated_at         timestamptz not null default now(),
  deleted_at                timestamptz,
  last_device_id            uuid,
  currency_code             char(3) not null check (currency_code ~ '^[A-Z]{3}$'),
  relative_to_currency_code char(3) not null check (relative_to_currency_code ~ '^[A-Z]{3}$'),
  rate_micros               bigint  not null check (rate_micros > 0),
  primary key (owner_id, id),
  check (id = 'rate_' || currency_code || '_' || relative_to_currency_code)
);
create index exchange_rates_owner_revision_idx on public.exchange_rates (owner_id, revision);
create trigger exchange_rates_stamp before insert or update on public.exchange_rates
  for each row execute function public.sync_stamp();
alter table public.exchange_rates enable row level security;
create policy exchange_rates_select on public.exchange_rates for select to authenticated
  using (owner_id = (select auth.uid()));
create policy exchange_rates_insert on public.exchange_rates for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy exchange_rates_update on public.exchange_rates for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- primary_currency (one singleton row per owner) --------------------------------------
create table public.primary_currency (
  owner_id           uuid        not null default auth.uid() references auth.users on delete cascade,
  id                 text        not null check (char_length(id) between 1 and 64),
  revision           bigint      not null,
  client_created_at  timestamptz,
  client_updated_at  timestamptz,
  server_created_at  timestamptz not null default now(),
  server_updated_at  timestamptz not null default now(),
  deleted_at         timestamptz,
  last_device_id     uuid,
  currency_code      char(3) not null check (currency_code ~ '^[A-Z]{3}$'),
  primary key (owner_id, id),
  check (id = 'singleton')
);
create index primary_currency_owner_revision_idx on public.primary_currency (owner_id, revision);
create trigger primary_currency_stamp before insert or update on public.primary_currency
  for each row execute function public.sync_stamp();
alter table public.primary_currency enable row level security;
create policy primary_currency_select on public.primary_currency for select to authenticated
  using (owner_id = (select auth.uid()));
create policy primary_currency_insert on public.primary_currency for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy primary_currency_update on public.primary_currency for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- conflict_resolutions (append-only: no update policy, research Decision 8) -------------
create table public.conflict_resolutions (
  owner_id           uuid        not null default auth.uid() references auth.users on delete cascade,
  id                 text        not null check (char_length(id) between 1 and 64),
  revision           bigint      not null,
  client_created_at  timestamptz,
  client_updated_at  timestamptz,
  server_created_at  timestamptz not null default now(),
  server_updated_at  timestamptz not null default now(),
  deleted_at         timestamptz,
  last_device_id     uuid,
  entity_type        text not null check (entity_type in ('money_transaction','finance_entry')),
  entity_id          text not null,
  chosen_side        text not null check (chosen_side in ('local','server')),
  discarded_values   jsonb not null,
  resolved_at        timestamptz not null,
  primary key (owner_id, id)
);
create index conflict_resolutions_owner_revision_idx on public.conflict_resolutions (owner_id, revision);
create trigger conflict_resolutions_stamp before insert or update on public.conflict_resolutions
  for each row execute function public.sync_stamp();
alter table public.conflict_resolutions enable row level security;
create policy conflict_resolutions_select on public.conflict_resolutions for select to authenticated
  using (owner_id = (select auth.uid()));
create policy conflict_resolutions_insert on public.conflict_resolutions for insert to authenticated
  with check (owner_id = (select auth.uid()));


-- -----------------------------------------------------------------------------
-- 4. Rule guards
-- -----------------------------------------------------------------------------

-- A person with any transaction (soft-deleted ones included, spec 001 FR-017)
-- can never be deleted.
create function public.people_guard_delete()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.money_transactions t
    where t.owner_id = new.owner_id
      and t.person_id = new.id
  ) then
    raise exception 'person_has_transactions' using errcode = 'P0001';
  end if;
  return new;
end
$$;

create trigger people_guard_delete
  before update of deleted_at on public.people
  for each row
  when (old.deleted_at is null and new.deleted_at is not null)
  execute function public.people_guard_delete();

create function public.finance_entry_type_matches_category()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_category_type text;
begin
  select c.type into v_category_type
  from public.finance_categories c
  where c.owner_id = new.owner_id
    and c.id = new.category_id;

  -- A missing category is left to the foreign key (23503, missing_parent).
  if v_category_type is not null and v_category_type <> new.type then
    raise exception 'category_type_mismatch' using errcode = '23514';
  end if;
  return new;
end
$$;

-- Triggers fire in name order: "finance_entries_stamp" sorts before
-- "finance_entry_type_matches_category", so NEW.owner_id is already stamped.
create trigger finance_entry_type_matches_category
  before insert or update of type, category_id on public.finance_entries
  for each row execute function public.finance_entry_type_matches_category();


-- -----------------------------------------------------------------------------
-- 5. sync_push (contracts/sync-rpc.md §2)
-- -----------------------------------------------------------------------------

create function public.sync_push(
  p_device_id   uuid,
  p_app_version text,
  p_platform    text,
  p_ops         jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid          uuid := (select auth.uid());
  v_results      jsonb := '[]'::jsonb;
  v_op           jsonb;
  v_op_id_text   text;
  v_op_id        uuid;
  v_entity_type  text;
  v_op_type      text;
  v_entity_id    text;
  v_base         bigint;
  v_payload      jsonb;
  v_table        text;
  v_policy       text;     -- financial | append | lww
  v_deletable    boolean;
  v_writable     text[];   -- client-writable columns
  v_business     text[];   -- columns compared for "same create" (3b)
  v_cols         text[];
  v_current      jsonb;
  v_row          jsonb;
  v_equal        boolean;
  v_result       text;
  v_revision     bigint;
  v_reason       text;
  v_server_row   jsonb;
  v_record       boolean;
  v_ledger       record;
  v_state        text;
  v_message      text;
  v_item         jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if p_device_id is null then
    raise exception 'device_id_required' using errcode = '22023';
  end if;
  if p_platform is null or p_platform not in ('android','ios') then
    raise exception 'invalid_platform' using errcode = '22023';
  end if;
  if p_app_version is null then
    raise exception 'app_version_required' using errcode = '22023';
  end if;
  if p_ops is null or jsonb_typeof(p_ops) <> 'array' then
    raise exception 'ops_must_be_array' using errcode = '22023';
  end if;
  if jsonb_array_length(p_ops) > 100 then
    raise exception 'too_many_operations' using errcode = '22023';
  end if;

  for v_op in
    select e.value from jsonb_array_elements(p_ops) with ordinality as e(value, ord) order by e.ord
  loop
    v_result := null; v_revision := null; v_reason := null; v_server_row := null;
    v_current := null; v_row := null; v_record := true; v_table := null;

    -- Parse the envelope. A malformed op_id cannot be recorded in the ledger.
    v_op_id_text := v_op ->> 'op_id';
    begin
      v_op_id := v_op_id_text::uuid;
    exception when others then
      v_op_id := null;
    end;
    if v_op_id is null then
      v_results := v_results || jsonb_build_array(jsonb_build_object(
        'op_id', v_op_id_text, 'result', 'rejected', 'reason', 'validation'));
      continue;
    end if;

    v_entity_type := v_op ->> 'entity_type';
    v_op_type     := v_op ->> 'op_type';
    v_entity_id   := v_op ->> 'entity_id';
    v_payload     := coalesce(v_op -> 'payload', '{}'::jsonb);
    begin
      v_base := (v_op ->> 'base_revision')::bigint;
    exception when others then
      v_base := null;
      v_op_type := null;  -- forces a validation rejection below
    end;

    -- Entity configuration.
    case v_entity_type
      when 'person' then
        v_table := 'people'; v_policy := 'lww'; v_deletable := true;
        v_business := array['name','normalized_name','phone_number','relationship_tag','notes','is_archived'];
      when 'money_transaction' then
        v_table := 'money_transactions'; v_policy := 'financial'; v_deletable := false;
        v_business := array['person_id','idempotency_key','amount_minor','currency_code','direction','kind',
                            'occurred_at','occurred_on','tz_offset_minutes','note','edited_at','deleted_at'];
      when 'transaction_audit' then
        v_table := 'transaction_audit_entries'; v_policy := 'append'; v_deletable := false;
        v_business := array['transaction_id','change_type','previous_values','changed_at'];
      when 'finance_category' then
        v_table := 'finance_categories'; v_policy := 'lww'; v_deletable := true;
        v_business := array['name','normalized_name','type','icon_key','is_default','is_archived'];
      when 'finance_entry' then
        v_table := 'finance_entries'; v_policy := 'financial'; v_deletable := false;
        v_business := array['category_id','idempotency_key','type','amount_minor','currency_code',
                            'occurred_at','occurred_on','tz_offset_minutes','note','edited_at','deleted_at'];
      when 'exchange_rate' then
        v_table := 'exchange_rates'; v_policy := 'lww'; v_deletable := true;
        v_business := array['currency_code','relative_to_currency_code','rate_micros'];
      when 'primary_currency' then
        v_table := 'primary_currency'; v_policy := 'lww'; v_deletable := false;
        v_business := array['currency_code'];
      when 'conflict_resolution' then
        v_table := 'conflict_resolutions'; v_policy := 'append'; v_deletable := false;
        v_business := array['entity_type','entity_id','chosen_side','discarded_values','resolved_at'];
      else
        v_table := null;
    end case;

    -- Step 1: the ledger. A replayed op_id never writes.
    select so.result, so.revision, so.reason into v_ledger
    from public.sync_operations so
    where so.owner_id = v_uid and so.op_id = v_op_id;

    if found then
      if v_ledger.result in ('applied','already_applied') then
        v_result := 'already_applied';
        v_revision := v_ledger.revision;
      else
        -- conflict / superseded / rejected are replayed as they were, with the
        -- current server row, so a lost response never turns into data loss.
        v_result := v_ledger.result;
        v_revision := v_ledger.revision;
        v_reason := v_ledger.reason;
        if v_table is not null and v_entity_id is not null
           and (v_ledger.result in ('conflict','superseded') or v_ledger.reason = 'person_has_transactions') then
          execute format('select to_jsonb(t) from public.%I t where t.owner_id = $1 and t.id = $2', v_table)
            into v_server_row using v_uid, v_entity_id;
        end if;
      end if;
      v_item := jsonb_build_object('op_id', v_op_id, 'result', v_result);
      if v_revision is not null then v_item := v_item || jsonb_build_object('revision', v_revision); end if;
      if v_reason is not null then v_item := v_item || jsonb_build_object('reason', v_reason); end if;
      if v_server_row is not null then v_item := v_item || jsonb_build_object('server_row', v_server_row); end if;
      v_results := v_results || jsonb_build_array(v_item);
      continue;
    end if;

    if v_table is null then
      v_result := 'rejected'; v_reason := 'unknown_entity';
    elsif v_entity_id is null or v_op_type is null or v_op_type not in ('upsert','delete')
          or jsonb_typeof(v_payload) <> 'object'
          or (v_op_type = 'delete' and not v_deletable) then
      v_result := 'rejected'; v_reason := 'validation';
    else
      -- Client-writable columns: the business columns plus client metadata.
      -- The server owns owner_id, revision, server_* and last_device_id.
      v_writable := v_business
        || array['client_created_at','client_updated_at']
        || case when 'deleted_at' = any(v_business) then array[]::text[] else array['deleted_at'] end;

      -- Step 4: an upsert of a last-write-wins row always (re)states deleted_at,
      -- so re-creating a deleted person or rate pair undeletes it.
      if v_policy = 'lww' and v_op_type = 'upsert' and not (v_payload ? 'deleted_at') then
        v_payload := v_payload || jsonb_build_object('deleted_at', null);
      end if;

      -- Only the keys present in the payload are written: an absent key keeps
      -- the column default on insert and the current value on update.
      select coalesce(array_agg(c order by ord), array[]::text[]) into v_cols
      from unnest(v_writable) with ordinality as w(c, ord)
      where v_payload ? c;

      -- Per-operation sub-transaction (FR-029).
      begin
        -- Step 2. Append-only tables grant no UPDATE, which FOR UPDATE needs;
        -- their rows are never rewritten, so a plain read is enough.
        execute format('select to_jsonb(t) from public.%I t where t.owner_id = $1 and t.id = $2%s',
                       v_table, case when v_policy = 'append' then '' else ' for update' end)
          into v_current using v_uid, v_entity_id;

        if v_op_type = 'upsert' then
          if v_current is null then
            -- 3a. Same business create replayed under a new op_id and id.
            if v_policy = 'financial' then
              execute format('select to_jsonb(t) from public.%I t where t.owner_id = $1 and t.idempotency_key = $2', v_table)
                into v_row using v_uid, v_payload ->> 'idempotency_key';
            end if;
            if v_row is not null then
              v_result := 'already_applied';
              v_revision := (v_row ->> 'revision')::bigint;
            else
              execute format(
                'insert into public.%1$I as t (id, last_device_id%2$s) '
                'select $1, $2%3$s from jsonb_populate_record(null::public.%1$I, $3) r '
                'returning to_jsonb(t)',
                v_table,
                (select coalesce(string_agg(', ' || quote_ident(c), '' order by ord), '')
                   from unnest(v_cols) with ordinality as x(c, ord)),
                (select coalesce(string_agg(', r.' || quote_ident(c), '' order by ord), '')
                   from unnest(v_cols) with ordinality as x(c, ord)))
                into v_row using v_entity_id, p_device_id, v_payload;
              v_result := 'applied';
              v_revision := (v_row ->> 'revision')::bigint;
            end if;

          elsif v_policy = 'append' then
            -- Append-only rows never conflict and are never rewritten.
            v_result := 'already_applied';
            v_revision := (v_current ->> 'revision')::bigint;

          elsif v_policy = 'financial'
                and (v_base is null or v_base <> (v_current ->> 'revision')::bigint) then
            if v_base is null then
              -- 3b. A create hitting an existing row: same fields means a replay.
              execute format(
                'select (select to_jsonb(x) from (select %2$s from jsonb_populate_record(null::public.%1$I, $1) r) x) '
                '     = (select to_jsonb(y) from (select %2$s from jsonb_populate_record(null::public.%1$I, $2) r) y)',
                v_table,
                (select string_agg('r.' || quote_ident(c), ', ') from unnest(v_business) c where v_payload ? c))
                into v_equal using v_payload, v_current;
            else
              v_equal := false;
            end if;
            if coalesce(v_equal, false) then
              v_result := 'already_applied';
              v_revision := (v_current ->> 'revision')::bigint;
            else
              -- 3b/3d: financial records are never merged automatically (FR-035).
              v_result := 'conflict';
              v_revision := (v_current ->> 'revision')::bigint;
              v_server_row := v_current;
            end if;

          else
            -- 3b/3c/3d: matching base, or last-write-wins in server order (FR-037).
            if array_length(v_cols, 1) is null then
              execute format(
                'update public.%1$I as t set last_device_id = $2 '
                'where t.owner_id = $3 and t.id = $1 returning to_jsonb(t)', v_table)
                into v_row using v_entity_id, p_device_id, v_uid;
            else
              execute format(
                'update public.%1$I as t set (%2$s, last_device_id) = '
                '(select %3$s, $2 from jsonb_populate_record(null::public.%1$I, $4) r) '
                'where t.owner_id = $3 and t.id = $1 returning to_jsonb(t)',
                v_table,
                (select string_agg(quote_ident(c), ', ' order by ord) from unnest(v_cols) with ordinality as x(c, ord)),
                (select string_agg('r.' || quote_ident(c), ', ' order by ord) from unnest(v_cols) with ordinality as x(c, ord)))
                into v_row using v_entity_id, p_device_id, v_uid, v_payload;
            end if;
            v_result := 'applied';
            v_revision := (v_row ->> 'revision')::bigint;
          end if;

        else
          -- 3e. Delete (person, finance_category, exchange_rate).
          if v_current is null or v_current ->> 'deleted_at' is not null then
            v_result := 'already_applied';
            v_revision := (v_current ->> 'revision')::bigint;
          elsif v_base is not null and v_base <> (v_current ->> 'revision')::bigint then
            -- A delete loses to a concurrent edit (FR-037b).
            v_result := 'superseded';
            v_revision := (v_current ->> 'revision')::bigint;
            v_server_row := v_current;
          elsif v_table = 'finance_categories' and exists (
                  select 1 from public.finance_entries fe
                  where fe.owner_id = v_uid and fe.category_id = v_entity_id) then
            -- Referenced (soft-deleted entries included): archive instead (FR-037d).
            update public.finance_categories c
               set is_archived = true,
                   last_device_id = p_device_id,
                   client_updated_at = coalesce((v_payload ->> 'client_updated_at')::timestamptz, c.client_updated_at)
             where c.owner_id = v_uid and c.id = v_entity_id
            returning to_jsonb(c) into v_row;
            v_result := 'applied';
            v_revision := (v_row ->> 'revision')::bigint;
            v_server_row := v_row;
          else
            execute format(
              'update public.%1$I as t set deleted_at = now(), last_device_id = $2, '
              'client_updated_at = coalesce(($4 ->> ''client_updated_at'')::timestamptz, t.client_updated_at) '
              'where t.owner_id = $3 and t.id = $1 returning to_jsonb(t)', v_table)
              into v_row using v_entity_id, p_device_id, v_uid, v_payload;
            v_result := 'applied';
            v_revision := (v_row ->> 'revision')::bigint;
          end if;
        end if;

      exception when others then
        get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
        v_result := 'rejected';
        v_revision := null;
        v_server_row := null;
        if v_state = '42501' then
          raise;  -- fails the whole call (ForbiddenFailure client-side)
        elsif v_state = '23503' then
          -- Parent not uploaded yet: transient, so never recorded in the ledger.
          v_reason := 'missing_parent';
          v_record := false;
        elsif v_state = '23505' and v_policy = 'financial' then
          -- A concurrent push inserted the same business create first.
          execute format('select to_jsonb(t) from public.%I t where t.owner_id = $1 and t.idempotency_key = $2', v_table)
            into v_row using v_uid, v_payload ->> 'idempotency_key';
          if v_row is not null then
            v_result := 'already_applied';
            v_revision := (v_row ->> 'revision')::bigint;
          else
            v_reason := 'validation';
          end if;
        elsif v_state = '23505' and v_policy = 'append' then
          -- A concurrent push inserted the same append-only row first.
          execute format('select to_jsonb(t) from public.%I t where t.owner_id = $1 and t.id = $2', v_table)
            into v_row using v_uid, v_entity_id;
          if v_row is not null then
            v_result := 'already_applied';
            v_revision := (v_row ->> 'revision')::bigint;
          else
            v_reason := 'validation';
          end if;
        elsif v_state = 'P0001' and v_message = 'person_has_transactions' then
          v_reason := 'person_has_transactions';
          select to_jsonb(p) into v_server_row
          from public.people p
          where p.owner_id = v_uid and p.id = v_entity_id;
          v_revision := (v_server_row ->> 'revision')::bigint;
        elsif v_state = '23514' and v_message = 'category_type_mismatch' then
          v_reason := 'category_type_mismatch';
        elsif v_state like '22%' or v_state like '23%' or v_state = 'P0001' then
          -- check, not-null, invalid input, too long, bad date, ...
          v_reason := 'validation';
        else
          raise;
        end if;
      end;
    end if;

    -- Step 6: the ledger (except transient missing_parent).
    if v_record then
      insert into public.sync_operations (owner_id, op_id, entity_type, entity_id, result, revision, reason)
      values (v_uid, v_op_id, coalesce(v_entity_type, ''), coalesce(v_entity_id, ''), v_result, v_revision, v_reason)
      on conflict (owner_id, op_id) do nothing;
    end if;

    v_item := jsonb_build_object('op_id', v_op_id, 'result', v_result);
    if v_revision is not null then v_item := v_item || jsonb_build_object('revision', v_revision); end if;
    if v_reason is not null then v_item := v_item || jsonb_build_object('reason', v_reason); end if;
    if v_server_row is not null then v_item := v_item || jsonb_build_object('server_row', v_server_row); end if;
    v_results := v_results || jsonb_build_array(v_item);
  end loop;

  -- Step 7: diagnostics.
  insert into public.devices as d (owner_id, device_id, platform, app_version, last_sync_at)
  values (v_uid, p_device_id, p_platform, p_app_version, now())
  on conflict (owner_id, device_id) do update
    set platform = excluded.platform,
        app_version = excluded.app_version,
        last_sync_at = excluded.last_sync_at;

  return jsonb_build_object('results', v_results, 'server_time', now());
end
$$;

comment on function public.sync_push(uuid, text, text, jsonb) is
  'Applies up to 100 client outbox operations, one sub-transaction each. See specs/021-supabase-offline-sync/contracts/sync-rpc.md §2.';


-- -----------------------------------------------------------------------------
-- 6. Privileges. Kept at the END: Supabase default privileges grant every new
--    public table and function to anon, authenticated and public.
-- -----------------------------------------------------------------------------

-- anon (not signed in) gets nothing. Anonymous *users* use the authenticated role.
revoke all on all tables    in schema public from anon;
-- Supabase default privileges also grant new functions to authenticated
-- directly, so it is revoked here and re-granted only what it needs. Trigger
-- functions (sync_stamp, people_guard_delete, finance_entry_type_matches_category)
-- need no EXECUTE grant to fire.
revoke all on all functions in schema public from anon, authenticated, public;

-- authenticated: DML only through RLS. No DELETE (no physical deletes, FR-015),
-- no TRUNCATE (it bypasses RLS), no TRIGGER/REFERENCES.
revoke all on
  public.sync_owner_state, public.sync_operations, public.devices,
  public.people, public.money_transactions, public.transaction_audit_entries,
  public.finance_categories, public.finance_entries, public.exchange_rates,
  public.primary_currency, public.conflict_resolutions
from authenticated;

grant select, insert, update on
  public.sync_owner_state, public.sync_operations, public.devices,
  public.people, public.money_transactions,
  public.finance_categories, public.finance_entries, public.exchange_rates,
  public.primary_currency
to authenticated;

-- Append-only tables.
grant select, insert on public.transaction_audit_entries, public.conflict_resolutions to authenticated;

-- sync_stamp() calls next_revision() as the invoking role, so authenticated needs
-- EXECUTE on it. Calling it directly only bumps the caller's own counter (a gap
-- in its own revisions, which the "revision > cursor" pull tolerates).
grant execute on function public.next_revision() to authenticated;
grant execute on function public.sync_push(uuid, text, text, jsonb) to authenticated;
-- sync_pull is added (and granted) by the later _021b_sync_pull migration.
