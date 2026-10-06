-- =============================================================================
-- 025: savings contribution conflicts (022 financial-trust audit, A3)
--
-- Two devices that edit the same savings contribution used to overwrite each
-- other silently (last write wins). That is the wrong rule for money, so a
-- stale edit now becomes a manual conflict, like money transactions and
-- finance entries (research PF-11 / R3).
--
-- Installed older apps cannot show a savings conflict: the conflict screen of
-- v1.0.1 filters the type out and the edit would be parked where nothing ever
-- displays it. So the financial policy applies only to app versions that can
-- show it, 1.1.0 and later (research R6, release R1). Older apps, and a call
-- without a version, keep last-write-wins exactly as in 023.
--
--   1. public.app_version_at_least(text, text): dotted numeric compare.
--   2. sync_push: 023's function, verbatim, except the savings_contribution
--      policy line.
--   2b. sync_pull: 023's function, verbatim, except that conflict_resolution
--      rows of other entity types are not served (v1.0.1 cannot read them).
--   3. conflict_resolutions.entity_type also accepts 'savings_contribution',
--      so the app can upload the record of a resolved savings conflict.
--
-- Rollout (specs/022-financial-trust-audit/quickstart.md): deploy AFTER the
-- 1.1.0 release has shipped. Applied migrations are never edited.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. app_version_at_least: true when p_version >= p_min.
--    Splits on '.', ignores a '+build' suffix, compares the numeric parts left
--    to right (a missing part counts as 0). A null or unparsable version, or
--    minimum, is never "at least": the safe answer is the old behavior.
-- -----------------------------------------------------------------------------

create or replace function public.app_version_at_least(p_version text, p_min text)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_a text[];
  v_b text[];
  v_len int;
  v_x int;
  v_y int;
  i int;
begin
  if p_version is null or p_min is null then
    return false;
  end if;
  if split_part(p_version, '+', 1) !~ '^[0-9]{1,9}(\.[0-9]{1,9})*$'
     or split_part(p_min, '+', 1) !~ '^[0-9]{1,9}(\.[0-9]{1,9})*$' then
    return false;
  end if;
  v_a := string_to_array(split_part(p_version, '+', 1), '.');
  v_b := string_to_array(split_part(p_min, '+', 1), '.');
  v_len := greatest(array_length(v_a, 1), array_length(v_b, 1));
  for i in 1 .. v_len loop
    v_x := coalesce(v_a[i]::int, 0);
    v_y := coalesce(v_b[i]::int, 0);
    if v_x <> v_y then
      return v_x > v_y;
    end if;
  end loop;
  return true;
end
$$;

comment on function public.app_version_at_least(text, text) is
  'True when the dotted numeric version p_version is at least p_min (a +build suffix is ignored). Null or unparsable input is false. Used by sync_push to gate the savings contribution conflict policy on the app version.';


-- -----------------------------------------------------------------------------
-- 2. sync_push: 023's definition; only the savings_contribution policy changes.
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
        v_table := 'savings_contributions'; v_policy := case when public.app_version_at_least(p_app_version, '1.1.0') then 'financial' else 'lww' end; v_deletable := false;
        v_business := array['idempotency_key','goal_id','type','amount_minor_units','entered_amount_minor_units',
                            'entered_currency_code','date','note','edited_at','deleted_at'];
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
-- 2b. sync_pull: 023's definition; only the conflict_resolution branch gains a
--     filter. A v1.0.1 app rejects a resolution row of any other entity_type
--     (its mapper only knows money_transaction and finance_entry), which would
--     fail every download page that contains one. The savings resolutions
--     recorded by 1.1.0+ apps are therefore not served here.
--     When v1.0.1 is retired, a later migration drops this filter and bumps
--     those rows' revisions (a no-op update firing sync_stamp); otherwise
--     devices already past the cursor never receive them.
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
        -- 025: v1.0.1 clients reject other types
        and t.entity_type in ('money_transaction','finance_entry')
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
-- 3. The record of a resolved conflict may now name a savings contribution.
--    (021 created the check inline, so Postgres named it
--    conflict_resolutions_entity_type_check.)
-- -----------------------------------------------------------------------------

alter table public.conflict_resolutions
  drop constraint conflict_resolutions_entity_type_check;
alter table public.conflict_resolutions
  add constraint conflict_resolutions_entity_type_check
  check (entity_type in ('money_transaction','finance_entry','savings_contribution'));


-- -----------------------------------------------------------------------------
-- Privileges at the END (as 023): repeat the function grants.
-- -----------------------------------------------------------------------------

revoke all on function public.app_version_at_least(text, text) from anon, authenticated, public;
grant execute on function public.app_version_at_least(text, text) to authenticated;

revoke all on function public.sync_push(uuid, text, text, jsonb) from anon, authenticated, public;
grant execute on function public.sync_push(uuid, text, text, jsonb) to authenticated;

revoke all on function public.sync_pull(bigint, int) from anon, public;
grant execute on function public.sync_pull(bigint, int) to authenticated;
