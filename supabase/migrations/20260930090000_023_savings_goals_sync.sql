-- =============================================================================
-- 023: cloud sync for Savings Goals (011)
--
--   1. Three new synced tables: savings_goals, savings_contributions and
--      savings_contribution_audits (011 research Decision 8).
--   2. sync_push / sync_pull know the new entity types: savings_goal,
--      savings_contribution and savings_contribution_audit.
--
-- sync_delete_all() (022) is deliberately not replaced: it deletes the
-- caller's auth.users row, and every table here references auth.users
-- ON DELETE CASCADE through owner_id, so the new rows go with it.
--
-- Conflict policy, as 022 chose for occasions and budgets: goals and
-- contributions are last-write-wins (the app's conflict screen only knows
-- money transactions and finance entries), soft-deleted through deleted_at
-- on an upsert; contribution audits are append-only, like 021's
-- transaction_audit_entries.
--
-- Applied migrations are never edited; functions are replaced here.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1a. savings_goals — last-write-wins, soft-deleted through deleted_at (a goal
--     is only ever deleted with no contribution history, 011 FR-021).
-- -----------------------------------------------------------------------------

create table public.savings_goals (
  owner_id                          uuid        not null default auth.uid() references auth.users on delete cascade,
  id                                text        not null check (char_length(id) between 1 and 64),
  revision                          bigint      not null,
  client_created_at                 timestamptz,
  client_updated_at                 timestamptz,
  server_created_at                 timestamptz not null default now(),
  server_updated_at                 timestamptz not null default now(),
  deleted_at                        timestamptz,
  last_device_id                    uuid,
  idempotency_key                   text    not null check (char_length(idempotency_key) <= 64),
  name                              text    not null check (char_length(name) between 1 and 200),
  -- Cosmetic, free-form like occasions.type; null for a plain custom goal.
  type                              text    check (char_length(type) between 1 and 60),
  -- Set at creation and never edited (011 FR-027).
  currency_code                     char(3) not null check (currency_code ~ '^[A-Z]{3}$'),
  target_amount_minor_units         bigint  not null check (target_amount_minor_units > 0),
  monthly_contribution_minor_units  bigint  check (monthly_contribution_minor_units > 0),
  -- Date-only in the app: the device's local midnight, as occasions.occasion_at.
  target_date                       timestamptz,
  is_archived                       boolean not null default false,
  primary key (owner_id, id),
  unique (owner_id, idempotency_key)
);
create index savings_goals_owner_revision_idx on public.savings_goals (owner_id, revision);
create trigger savings_goals_stamp before insert or update on public.savings_goals
  for each row execute function public.sync_stamp();
alter table public.savings_goals enable row level security;
create policy savings_goals_select on public.savings_goals for select to authenticated
  using (owner_id = (select auth.uid()));
create policy savings_goals_insert on public.savings_goals for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy savings_goals_update on public.savings_goals for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));


-- -----------------------------------------------------------------------------
-- 1b. savings_contributions — last-write-wins, soft-deleted through
--     deleted_at. Direction lives in type, never in the sign (011 FR-007).
-- -----------------------------------------------------------------------------

create table public.savings_contributions (
  owner_id                    uuid        not null default auth.uid() references auth.users on delete cascade,
  id                          text        not null check (char_length(id) between 1 and 64),
  revision                    bigint      not null,
  client_created_at           timestamptz,
  client_updated_at           timestamptz,
  server_created_at           timestamptz not null default now(),
  server_updated_at           timestamptz not null default now(),
  deleted_at                  timestamptz,
  last_device_id              uuid,
  idempotency_key             text    not null check (char_length(idempotency_key) <= 64),
  goal_id                     text    not null check (char_length(goal_id) <= 64),
  type                        text    not null check (type in ('contribution','withdrawal')),
  -- In the goal's currency: the only figure progress sums.
  amount_minor_units          bigint  not null check (amount_minor_units > 0),
  -- What the user typed, in entered_currency_code (011 FR-028).
  entered_amount_minor_units  bigint  not null check (entered_amount_minor_units > 0),
  entered_currency_code       char(3) not null check (entered_currency_code ~ '^[A-Z]{3}$'),
  -- Date-only in the app: the device's local midnight, as occasions.occasion_at.
  date                        timestamptz not null,
  note                        text    check (char_length(note) <= 2000),
  edited_at                   timestamptz,
  primary key (owner_id, id),
  unique (owner_id, idempotency_key),
  foreign key (owner_id, goal_id) references public.savings_goals (owner_id, id)
);
create index savings_contributions_owner_revision_idx
  on public.savings_contributions (owner_id, revision);
create index savings_contributions_goal_idx
  on public.savings_contributions (owner_id, goal_id);
create trigger savings_contributions_stamp before insert or update on public.savings_contributions
  for each row execute function public.sync_stamp();
alter table public.savings_contributions enable row level security;
create policy savings_contributions_select on public.savings_contributions for select to authenticated
  using (owner_id = (select auth.uid()));
create policy savings_contributions_insert on public.savings_contributions for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy savings_contributions_update on public.savings_contributions for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));


-- -----------------------------------------------------------------------------
-- 1c. savings_contribution_audits — append-only (no update policy), a copy of
--     021's transaction_audit_entries with 021e's size limits built in.
-- -----------------------------------------------------------------------------

create table public.savings_contribution_audits (
  owner_id           uuid        not null default auth.uid() references auth.users on delete cascade,
  id                 text        not null check (char_length(id) between 1 and 64),
  revision           bigint      not null,
  client_created_at  timestamptz,
  client_updated_at  timestamptz,
  server_created_at  timestamptz not null default now(),
  server_updated_at  timestamptz not null default now(),
  deleted_at         timestamptz,
  last_device_id     uuid,
  contribution_id    text  not null check (char_length(contribution_id) <= 64),
  change_type        text  not null check (change_type in ('edited','deleted')),
  -- The row before the change, as a JSON object (the app stores it as text).
  previous_values    jsonb not null
                     check (jsonb_typeof(previous_values) = 'object')
                     check (pg_column_size(previous_values) <= 16384),
  changed_at         timestamptz not null,
  primary key (owner_id, id),
  foreign key (owner_id, contribution_id) references public.savings_contributions (owner_id, id)
);
create index savings_contribution_audits_owner_revision_idx
  on public.savings_contribution_audits (owner_id, revision);
create index savings_contribution_audits_contribution_idx
  on public.savings_contribution_audits (owner_id, contribution_id);
create trigger savings_contribution_audits_stamp before insert or update on public.savings_contribution_audits
  for each row execute function public.sync_stamp();
alter table public.savings_contribution_audits enable row level security;
create policy savings_contribution_audits_select on public.savings_contribution_audits for select to authenticated
  using (owner_id = (select auth.uid()));
create policy savings_contribution_audits_insert on public.savings_contribution_audits for insert to authenticated
  with check (owner_id = (select auth.uid()));


-- -----------------------------------------------------------------------------
-- 2a. sync_push: the savings entity types. Otherwise identical to 022.
-- -----------------------------------------------------------------------------

create or replace function public.sync_push(
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
  if char_length(p_app_version) > 40 then
    raise exception 'invalid_app_version' using errcode = '22023';
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
      v_op_type := null;
    end;

    -- 021e: an over-length envelope never reaches the ledger.
    if char_length(v_entity_type) > 32 or char_length(v_entity_id) > 64 then
      v_results := v_results || jsonb_build_array(jsonb_build_object(
        'op_id', v_op_id, 'result', 'rejected', 'reason', 'validation'));
      continue;
    end if;

    case v_entity_type
      when 'person' then
        v_table := 'people'; v_policy := 'lww'; v_deletable := true;
        v_business := array['name','normalized_name','phone_number','relationship_tag','notes','is_archived'];
      when 'money_transaction' then
        v_table := 'money_transactions'; v_policy := 'financial'; v_deletable := false;
        v_business := array['person_id','idempotency_key','amount_minor','currency_code','direction','kind',
                            'occurred_at','occurred_on','tz_offset_minutes','note','edited_at','deleted_at',
                            'occasion_id','counts_toward_balance','source','ocr_scan_id'];
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
      -- 022 ------------------------------------------------------------------
      when 'occasion' then
        -- Soft-deleted by an upsert carrying deleted_at, as the app does.
        v_table := 'occasions'; v_policy := 'lww'; v_deletable := false;
        v_business := array['idempotency_key','name','occasion_at','type','notes','is_archived'];
      when 'budget' then
        v_table := 'budgets'; v_policy := 'lww'; v_deletable := false;
        v_business := array['idempotency_key','month','expected_income_minor','currency_code'];
      when 'budget_allocation' then
        -- Hard-deleted in the app, so removed here by a delete op.
        v_table := 'budget_category_allocations'; v_policy := 'lww'; v_deletable := true;
        v_business := array['idempotency_key','budget_id','category_id','planned_minor'];
      -- 023 ------------------------------------------------------------------
      when 'savings_goal' then
        -- Soft-deleted by an upsert carrying deleted_at, as the app does.
        v_table := 'savings_goals'; v_policy := 'lww'; v_deletable := false;
        v_business := array['idempotency_key','name','type','currency_code','target_amount_minor_units',
                            'monthly_contribution_minor_units','target_date','is_archived'];
      when 'savings_contribution' then
        -- Soft-deleted by an upsert carrying deleted_at, as the app does.
        v_table := 'savings_contributions'; v_policy := 'lww'; v_deletable := false;
        v_business := array['idempotency_key','goal_id','type','amount_minor_units','entered_amount_minor_units',
                            'entered_currency_code','date','note','edited_at'];
      when 'savings_contribution_audit' then
        v_table := 'savings_contribution_audits'; v_policy := 'append'; v_deletable := false;
        v_business := array['contribution_id','change_type','previous_values','changed_at'];
      else
        v_table := null;
    end case;

    select so.result, so.revision, so.reason into v_ledger
    from public.sync_operations so
    where so.owner_id = v_uid and so.op_id = v_op_id;

    if found then
      if v_ledger.result in ('applied','already_applied') then
        v_result := 'already_applied';
        v_revision := v_ledger.revision;
      else
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
      v_writable := v_business
        || array['client_created_at','client_updated_at']
        || case when 'deleted_at' = any(v_business) then array[]::text[] else array['deleted_at'] end;

      if v_policy = 'lww' and v_op_type = 'upsert' and not (v_payload ? 'deleted_at') then
        v_payload := v_payload || jsonb_build_object('deleted_at', null);
      end if;

      select coalesce(array_agg(c order by ord), array[]::text[]) into v_cols
      from unnest(v_writable) with ordinality as w(c, ord)
      where v_payload ? c;

      begin
        execute format('select to_jsonb(t) from public.%I t where t.owner_id = $1 and t.id = $2%s',
                       v_table, case when v_policy = 'append' then '' else ' for update' end)
          into v_current using v_uid, v_entity_id;

        if v_op_type = 'upsert' then
          if v_current is null then
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
            v_result := 'already_applied';
            v_revision := (v_current ->> 'revision')::bigint;

          elsif v_policy = 'financial'
                and (v_base is null or v_base <> (v_current ->> 'revision')::bigint) then
            if v_base is null then
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
              v_result := 'conflict';
              v_revision := (v_current ->> 'revision')::bigint;
              v_server_row := v_current;
            end if;

          else
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
          if v_current is null or v_current ->> 'deleted_at' is not null then
            v_result := 'already_applied';
            v_revision := (v_current ->> 'revision')::bigint;
          elsif v_base is not null and v_base <> (v_current ->> 'revision')::bigint then
            v_result := 'superseded';
            v_revision := (v_current ->> 'revision')::bigint;
            v_server_row := v_current;
          elsif v_table = 'finance_categories' and exists (
                  select 1 from public.finance_entries fe
                  where fe.owner_id = v_uid and fe.category_id = v_entity_id) then
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
          raise;
        elsif v_state = '23503' then
          v_reason := 'missing_parent';
          v_record := false;
        elsif v_state = '23505' and v_policy = 'financial' then
          execute format('select to_jsonb(t) from public.%I t where t.owner_id = $1 and t.idempotency_key = $2', v_table)
            into v_row using v_uid, v_payload ->> 'idempotency_key';
          if v_row is not null then
            v_result := 'already_applied';
            v_revision := (v_row ->> 'revision')::bigint;
          else
            v_reason := 'validation';
          end if;
        elsif v_state = '23505' and v_policy = 'append' then
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
          v_reason := 'validation';
        else
          raise;
        end if;
      end;
    end if;

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
  'Applies up to 100 client outbox operations, one sub-transaction each. See specs/021-supabase-offline-sync/contracts/sync-rpc.md §2; 022 adds occasion, budget and budget_allocation; 023 adds savings_goal, savings_contribution and savings_contribution_audit.';


-- -----------------------------------------------------------------------------
-- 2b. sync_pull: the three savings tables. Otherwise identical to 022.
-- -----------------------------------------------------------------------------

create or replace function public.sync_pull(p_since bigint, p_limit int default 500)
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
    union all
    (select 'occasion', t.revision, to_jsonb(t)
       from public.occasions t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'budget', t.revision, to_jsonb(t)
       from public.budgets t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'budget_allocation', t.revision, to_jsonb(t)
       from public.budget_category_allocations t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'savings_goal', t.revision, to_jsonb(t)
       from public.savings_goals t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'savings_contribution', t.revision, to_jsonb(t)
       from public.savings_contributions t
      where t.owner_id = v_uid and t.revision > v_since
      order by t.revision limit v_limit + 1)
    union all
    (select 'savings_contribution_audit', t.revision, to_jsonb(t)
       from public.savings_contribution_audits t
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
  'Returns one page of owner changes with revision > p_since across the 14 synced tables, ordered by revision. See specs/021-supabase-offline-sync/contracts/sync-rpc.md §3.';


-- -----------------------------------------------------------------------------
-- Privileges at the END (Supabase default privileges re-grant new objects).
-- As 021: DML only through RLS, no DELETE (soft deletes only) and no TRUNCATE
-- (it bypasses RLS); the append-only audits get no UPDATE either.
-- -----------------------------------------------------------------------------

revoke all on
  public.savings_goals, public.savings_contributions, public.savings_contribution_audits
from anon, authenticated, public;

grant select, insert, update on public.savings_goals, public.savings_contributions to authenticated;
grant select, insert on public.savings_contribution_audits to authenticated;

revoke all on function public.sync_push(uuid, text, text, jsonb) from anon, authenticated, public;
grant execute on function public.sync_push(uuid, text, text, jsonb) to authenticated;

revoke all on function public.sync_pull(bigint, int) from anon, public;
grant execute on function public.sync_pull(bigint, int) to authenticated;
