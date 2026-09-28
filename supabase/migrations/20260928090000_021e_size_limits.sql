-- =============================================================================
-- 021e: security hardening (LOW findings)
--
--   1. Size limits on client-supplied text/jsonb columns, and sync_push rejects
--      an over-length entity_type / entity_id before touching the ledger.
--   2. The revision counter is server-owned: authenticated loses INSERT/UPDATE
--      on sync_owner_state, and next_revision() becomes SECURITY DEFINER.
--
-- Applied migrations are never edited; functions are replaced here.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1a. Size limits. Columns that already carry a length check (ids, name,
--     notes, phone_number, relationship_tag, note, platform, enum-like
--     columns) are left as they are.
-- -----------------------------------------------------------------------------

alter table public.people
  add constraint people_normalized_name_len check (char_length(normalized_name) <= 200);

alter table public.money_transactions
  add constraint money_transactions_person_id_len       check (char_length(person_id) <= 64),
  add constraint money_transactions_idempotency_key_len check (char_length(idempotency_key) <= 64);

alter table public.transaction_audit_entries
  add constraint transaction_audit_entries_transaction_id_len  check (char_length(transaction_id) <= 64),
  add constraint transaction_audit_entries_change_type_len     check (char_length(change_type) <= 32),
  add constraint transaction_audit_entries_previous_values_size check (pg_column_size(previous_values) <= 16384);

alter table public.finance_categories
  add constraint finance_categories_normalized_name_len check (char_length(normalized_name) <= 200),
  add constraint finance_categories_icon_key_len        check (char_length(icon_key) <= 64);

alter table public.finance_entries
  add constraint finance_entries_category_id_len     check (char_length(category_id) <= 64),
  add constraint finance_entries_idempotency_key_len check (char_length(idempotency_key) <= 64);

-- entity_type already has an IN (...) check.
alter table public.conflict_resolutions
  add constraint conflict_resolutions_entity_id_len         check (char_length(entity_id) <= 64),
  add constraint conflict_resolutions_discarded_values_size check (pg_column_size(discarded_values) <= 16384);

-- Server-only tables (authenticated can also insert into these through RLS).
alter table public.sync_operations
  add constraint sync_operations_entity_type_len check (char_length(entity_type) <= 32),
  add constraint sync_operations_entity_id_len   check (char_length(entity_id) <= 64);

alter table public.devices
  add constraint devices_app_version_len check (char_length(app_version) <= 40);


-- -----------------------------------------------------------------------------
-- 2. Server-owned revision counter.
--    Before: next_revision() ran as the invoker, so authenticated needed
--    INSERT/UPDATE on sync_owner_state and could jump its own counter to
--    bigint max (the forward-only trigger allows any increase), after which
--    every write of that owner would fail. Now only next_revision() writes it.
-- -----------------------------------------------------------------------------

create or replace function public.next_revision()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid      uuid := (select auth.uid());
  v_revision bigint;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  -- The row lock taken by this upsert serializes one owner's writes until
  -- commit, so revisions commit in increasing order.
  insert into public.sync_owner_state as s (owner_id, last_revision)
  values (v_uid, 1)
  on conflict (owner_id) do update set last_revision = s.last_revision + 1
  returning s.last_revision into v_revision;
  return v_revision;
end
$$;

alter function public.next_revision() owner to postgres;

comment on function public.next_revision() is
  'Bumps and returns the caller''s own revision counter (keyed by auth.uid()). SECURITY DEFINER: clients have no direct write access to sync_owner_state.';

-- Read-only for clients: the old FOR ALL policy is narrowed to SELECT.
drop policy sync_owner_state_own on public.sync_owner_state;
create policy sync_owner_state_select on public.sync_owner_state
  for select to authenticated
  using (owner_id = (select auth.uid()));

revoke insert, update on public.sync_owner_state from authenticated;
-- The forward-only trigger (021d) is kept as defence in depth.


-- -----------------------------------------------------------------------------
-- 1b. sync_push: reject over-length envelopes before the ledger, and cap
--     p_app_version. Otherwise identical to 20260927120000_021_offline_sync.
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
  -- devices.app_version is capped at 40: checked here so the diagnostics
  -- insert at the end can never fail (and roll back) an otherwise good batch.
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

    -- 021e: an over-length entity_type or entity_id is rejected before the
    -- ledger is read or written, so a client cannot store unbounded text in
    -- sync_operations (whose columns are capped at 32 / 64 characters).
    if char_length(v_entity_type) > 32 or char_length(v_entity_id) > 64 then
      v_results := v_results || jsonb_build_array(jsonb_build_object(
        'op_id', v_op_id, 'result', 'rejected', 'reason', 'validation'));
      continue;
    end if;

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
-- Privileges at the END (Supabase default privileges re-grant replaced objects).
-- -----------------------------------------------------------------------------

revoke all on function public.next_revision() from anon, authenticated, public;
-- sync_stamp() runs as the invoker and calls next_revision().
grant execute on function public.next_revision() to authenticated;

revoke all on function public.sync_push(uuid, text, text, jsonb) from anon, authenticated, public;
grant execute on function public.sync_push(uuid, text, text, jsonb) to authenticated;

revoke all on public.sync_owner_state from anon;
revoke all on public.sync_owner_state from authenticated;
grant select on public.sync_owner_state to authenticated;
