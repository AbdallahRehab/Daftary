# Discovery T008: Sync

Read-only inspection, working tree on `023-bank-sms-import` (HEAD `4a5565d`). v1.0.1 = commit `c86e2df` ("chore(release): v1.0.1"). Line numbers are as of these commits.

## 1. Current mappers (HEAD)

| File | `toWire` | `fromWire` | Notes |
|---|---|---|---|
| `lib/features/transactions/data/sync/money_transaction_sync_mapper.dart` | `:20-43` (map literal) | `:45-83` (`MoneyTransactionsCompanion.insert(...)`) | enum sets `directions` `:13`, `kinds` `:14`, `sources = {'manual','ocr'}` `:15`; `source` read with `SyncWire.oneOf` `:67-71` (throws on an unknown value, which is why provenance must not be a new `source` value). |
| `lib/features/finance/data/sync/finance_entry_sync_mapper.dart` | `:19-35` | `:37-60` (`FinanceEntriesCompanion.insert(...)`) | `types = {'income','expense'}` `:14`. |

Both import only `app_database.dart` (which re-exports `package:drift/drift.dart`, `app_database.dart:4`, so `Value` is available), `sync_entity_type.dart` and `sync_mapper_registry.dart`. Both are `@lazySingleton` and `const`.

The only change between v1.0.1 and HEAD in both mappers is the date line (`git diff c86e2df HEAD -- <mapper>`):

```diff
-    date: SyncWire.parseInstant(json['occurred_at'], 'occurred_at'),
+    date: SyncWire.parseLocalDay(json),
```

(transactions `:57`, finance `:48`). `toWire` is byte-identical between the two commits.

### Where T146 adds `import_source`

- `toWire`: add `if (row.importSource != null) 'import_source': row.importSource,` to the map literal (transactions before `:43`, finance before `:35`). Must be conditional: the transactions exact-shape test compares the **whole map** (`test/features/transactions/data/sync/money_transaction_sync_mapper_test.dart:44-73`, `expect(wire, {...})` at `:47-70`), so an always-present `'import_source': null` would break it. The finance shape test (`test/features/finance/data/sync/finance_entry_sync_mapper_test.dart:39-50`) checks individual keys only.
- `fromWire`: add `importSource: Value((json['import_source'] as String?) ?? existingLocal?.importSource),` (sync-wire-027 §3). Prefer `SyncWire.stringOrNull(json, 'import_source') ?? existingLocal?.importSource` (the contract asks to reuse `SyncWire.stringOrNull`): same result, and a non-string value fails as a `FormatException` like every other field instead of a `TypeError` from `as String?`.

## 2. v1.0.1 `fromWire` bodies (to freeze verbatim in T149)

Source: `git show c86e2df:lib/features/transactions/data/sync/money_transaction_sync_mapper.dart` lines 45-83 (class constants `:13-15`):

```dart
  static const directions = {'given', 'received'};
  static const kinds = {'initialExchange', 'repayment', 'occasionContribution'};
  static const sources = {'manual', 'ocr'};

  @override
  MoneyTransactionsCompanion fromWire(
    Map<String, Object?> json, {
    MoneyTransaction? existingLocal,
  }) => MoneyTransactionsCompanion.insert(
    id: SyncWire.string(json, 'id'),
    idempotencyKey: SyncWire.string(json, 'idempotency_key'),
    personId: SyncWire.string(json, 'person_id'),
    amountMinorUnits: SyncWire.parseMoney(json['amount_minor'], 'amount_minor'),
    currencyCode: Value(SyncWire.string(json, 'currency_code')),
    direction: SyncWire.oneOf(json, 'direction', directions),
    kind: SyncWire.oneOf(json, 'kind', kinds),
    date: SyncWire.parseInstant(json['occurred_at'], 'occurred_at'),
    note: Value(SyncWire.stringOrNull(json, 'note')),
    occasionId: Value(SyncWire.stringOrNull(json, 'occasion_id')),
    // A row the server stored before 022 has none of these: it was an
    // ordinary, counting, hand-typed transaction.
    countsTowardBalance: Value(
      json['counts_toward_balance'] == null
          ? true
          : SyncWire.boolean(json, 'counts_toward_balance'),
    ),
    source: Value(
      json['source'] == null
          ? 'manual'
          : SyncWire.oneOf(json, 'source', sources),
    ),
    ocrScanId: Value(SyncWire.stringOrNull(json, 'ocr_scan_id')),
    createdAt: SyncWire.parseFirstInstant(json, const [
      'client_created_at',
      'server_created_at',
    ]),
    editedAt: Value(
      SyncWire.parseInstantOrNull(json['edited_at'], 'edited_at'),
    ),
    deletedAt: Value(
      SyncWire.parseInstantOrNull(json['deleted_at'], 'deleted_at'),
    ),
  );
```

Source: `git show c86e2df:lib/features/finance/data/sync/finance_entry_sync_mapper.dart` lines 37-60 (constant `:14`):

```dart
  static const types = {'income', 'expense'};

  @override
  FinanceEntriesCompanion fromWire(
    Map<String, Object?> json, {
    FinanceEntry? existingLocal,
  }) => FinanceEntriesCompanion.insert(
    id: SyncWire.string(json, 'id'),
    idempotencyKey: SyncWire.string(json, 'idempotency_key'),
    categoryId: SyncWire.string(json, 'category_id'),
    type: SyncWire.oneOf(json, 'type', types),
    amountMinorUnits: SyncWire.parseMoney(json['amount_minor'], 'amount_minor'),
    currencyCode: Value(SyncWire.string(json, 'currency_code')),
    date: SyncWire.parseInstant(json['occurred_at'], 'occurred_at'),
    note: Value(SyncWire.stringOrNull(json, 'note')),
    createdAt: SyncWire.parseFirstInstant(json, const [
      'client_created_at',
      'server_created_at',
    ]),
    editedAt: Value(
      SyncWire.parseInstantOrNull(json['edited_at'], 'edited_at'),
    ),
    deletedAt: Value(
      SyncWire.parseInstantOrNull(json['deleted_at'], 'deleted_at'),
    ),
  );
```

### `SyncWire` helpers those bodies call (freeze these too)

From `git show c86e2df:lib/core/sync/sync_mapper_registry.dart` (`abstract final class SyncWire` at `:74`):

| Helper | v1.0.1 lines | Used by |
|---|---|---|
| `parseMoney(Object? value, String field)` | `:80-84` | both |
| `parseInstant(Object? value, String field)` | `:95-100` | both (date, via `parseFirstInstant`/`parseInstantOrNull`) |
| `parseInstantOrNull(Object? value, String field)` | `:102-103` | both |
| `parseFirstInstant(Map json, List<String> fields)` | `:107-113` | both |
| `string(Map json, String field)` | `:137-140` | both (also inside `oneOf`) |
| `stringOrNull(Map json, String field)` | `:142-146` | both |
| `boolean(Map json, String field)` | `:148-151` | transactions |
| `oneOf(Map json, String field, Set<String> allowed)` | `:159-166` | both |
| `_bad(String field, Object? value)` (private `Never`, throws `FormatException('Invalid wire value for "$field"', value?.runtimeType.toString())`) | `:168-171` | all of the above |

Verbatim text of those helpers at v1.0.1:

```dart
  static int parseMoney(Object? value, String field) => switch (value) {
    final String s => int.tryParse(s) ?? _bad(field, value),
    final int i => i,
    _ => _bad(field, value),
  };

  static int parseInstant(Object? value, String field) {
    if (value is! String) return _bad(field, value);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return _bad(field, value);
    return parsed.millisecondsSinceEpoch;
  }

  static int? parseInstantOrNull(Object? value, String field) =>
      value == null ? null : parseInstant(value, field);

  static int parseFirstInstant(Map<String, Object?> json, List<String> fields) {
    for (final field in fields) {
      final value = json[field];
      if (value != null) return parseInstant(value, field);
    }
    return _bad(fields.join('|'), null);
  }

  static String string(Map<String, Object?> json, String field) {
    final value = json[field];
    return value is String ? value : _bad(field, value);
  }

  static String? stringOrNull(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value == null) return null;
    return value is String ? value : _bad(field, value);
  }

  static bool boolean(Map<String, Object?> json, String field) {
    final value = json[field];
    return value is bool ? value : _bad(field, value);
  }

  static String oneOf(
    Map<String, Object?> json,
    String field,
    Set<String> allowed,
  ) {
    final value = string(json, field);
    return allowed.contains(value) ? value : _bad(field, value);
  }

  static Never _bad(String field, Object? value) => throw FormatException(
    'Invalid wire value for "$field"',
    value?.runtimeType.toString(),
  );
```

`git diff c86e2df HEAD -- lib/core/sync/sync_mapper_registry.dart` shows the **only** change is the new `parseLocalDay` + `_day` regex (HEAD `:133-159`); every helper above is still textually identical at HEAD. Freezing them is still required so a future edit to `SyncWire` cannot silently change the "v1.0.1" test (plan Step 9).

### Notes for T149 (`test/core/sync/legacy/v101_mappers.dart`)

- The bodies return Drift companions (`MoneyTransactionsCompanion.insert` / `FinanceEntriesCompanion.insert`) generated from the **current** schema. That is fine: v13 only adds a nullable `importSource` column, so the v1.0.1 `.insert(...)` call compiles unchanged and leaves `importSource` as `Value.absent()`. Freeze them as top-level functions (e.g. `v101MoneyTransactionFromWire(json)`) plus a private `_V101Wire` class holding the helpers above, and replace `SyncWire.` with `_V101Wire.` only; keep every other character.
- Because a v1.0.1 companion leaves `importSource` **absent**, and the applier writes with `insertOnConflictUpdate` (`lib/core/sync/local/sync_applier.dart:150-155`), absent columns are not touched on conflict: a v1.0.1-shaped apply keeps a local `'sms'`. Useful as an extra assertion.
- Inputs: build the JSON as `to_jsonb(t)` of the server row (sync-wire-027 §6): money as JSON number, `occurred_on`/`occurred_at`/`tz_offset_minutes`, `server_created_at`, `revision`, `owner_id`, `last_device_id`, `import_source: 'sms'` and `future_field: 1`.

## 3. Applier and `ConflictResolver.keepTheirs`

- `DriftSyncApplier.applyServerRow(type, row)` `lib/core/sync/local/sync_applier.dart:92-101` → `_apply` `:103-174`. The existing local row is loaded at `:113-116` (`existing`) and passed as `mapper.fromWire(row, existingLocal: existing)` at `:154` inside `insertOnConflictUpdate` `:150-155`. A row with an open outbox op is skipped (`:117-140`), or refreshes an open conflict (`:122-125`, `_refreshConflict` `:178`).
- `ConflictResolver` interface `lib/core/sync/local/conflict_resolver.dart:38-47` (`keepTheirs` declared `:46`). Implementation `DriftConflictResolver.keepTheirs` `:128-151`: in one transaction it loads the open conflict (`_openConflict` `:153`), deletes every queued op for the record, decodes `conflict.serverPayloadJson` and calls `_applier.applyServerRow(type, {...server, 'revision': conflict.serverRevision})` (`:141-144`), then writes the `conflict_resolutions` record and closes the conflict. So `keepTheirs` goes through the same `fromWire(existingLocal:)` path; the `serverPayloadJson` is the server's `to_jsonb` row (`server_row` from `sync_push`, stored at `sync_local_store.dart:307,318`), which after 027 contains `import_source: null` for a pre-027 row. That is the "key present and null keeps local `'sms'`" case.
- Existing `keepTheirs` tests to pattern from: `test/core/sync/local/conflict_resolver_test.dart:78,124`, `test/core/sync/sync_engine_conflict_test.dart:92`, `test/core/sync/local/sync_local_store_conflict_test.dart:173`.

## 4. `SyncHarness` and `FakeSyncRemote`

- `test/core/sync/fakes/sync_harness.dart` (426 lines). `realMapperRegistry()` `:38-54` (all 15 real mappers), `realApplier` `:57-63`, `realStore` `:66-82`, `TickingClock` `:86-94`. `class SyncHarness` `:99`: constructor `SyncHarness({AppDatabase? db, FakeClock? clock, FakeSyncRemote? remote})` `:102` uses an in-memory `AppDatabase.forTesting(NativeDatabase.memory())`; **pass one `FakeSyncRemote` to two harnesses to simulate two devices** (doc `:100-101`). Fields: `db`, `clock`, `remote`, `auth`, `supabase`, `connectivity`, `logger` (`RecordingSyncLogger`), `applier`, `store`, `outbox`, `resolver` (`DriftConflictResolver`, `:152`), `engine` (`:159`). Helpers: `createPerson` `:192`, `createTransaction(id, {personId, amount, key})` `:234-255`, `editTransaction` `:257-268`, `softDeleteTransaction` `:270`, `_recordTransaction` (`outbox.recordUpsert(..., _txn.toWire(row))`) `:276-285`, `outboxRows` `:387`, `opFor` `:390`, `metaFor` `:394`, `openConflict` `:401`, `resolutions` `:406`, `transaction(id)` `:409`, `skipBackoff` `:414`.
- **Gap**: the harness has **no finance-entry helpers** (no `createEntry`/`entry(id)`), only person/transaction/audit/goal/contribution. A two-device finance-entry provenance test (T150) needs a small `createFinanceEntry`/`financeEntry` helper added there (it also needs a seeded finance category; `isPristineSeed` is already wired). Creating a transaction with `importSource: Value('sms')` needs either a new optional parameter on `createTransaction` or a direct insert in the test.
- Two-device pattern: `test/core/sync/sync_log_scrub_test.dart:25-32` (`server = FakeSyncRemote(); a = SyncHarness(remote: server); b = SyncHarness(remote: server);`).
- `test/core/sync/fakes/fake_sync_remote.dart` (650 lines): reproduces `sync_push`/`sync_pull` semantics (doc `:8-29`). Business-column specs at `:545-558` (`money_transaction`) and `:573-585` (`finance_entry`) are **narrower than 026's `v_business`**: the fake's `money_transaction` list lacks `occasion_id`, `counts_toward_balance`, `source`, `ocr_scan_id`. The fake's `_write` (`:431-449`) stores `{...?current, ...payload}`, i.e. it keeps **every** payload key (no writable whitelist), and a key never pushed is absent on pull (the real server emits it as `null` via `to_jsonb`). Consequences for T150: (a) a legacy edit-push without `import_source` keeps the stored value on the fake, matching the real server; (b) to model "present and null" from a real post-027 pull, seed the row with `seedServerRow` (`:147`) including `'import_source': null`; (c) to test the case-7 create-retry conflict on the fake, `'import_source'` must be added to the fake's `financial` business list (`:356-362` compares only `spec.business`), otherwise the fake answers `already_applied` where the server answers `conflict`. Adding it mirrors 027; it is a test-fake edit not named in T150's file list, so whoever owns T148/T150 should note it in their decisions file.

## 5. Server: 026 `sync_push` (the base 027 must copy)

File `supabase/migrations/20261005100000_026_finance_entry_audits.sql` (738 lines).

| Part | Lines |
|---|---|
| Header comment describing 026 | `:1-30` |
| Section banner "2. sync_push: 025's definition; only the finance_entry_audit branch is new." | `:75-77` |
| `create or replace function public.sync_push(p_device_id uuid, p_app_version text, p_platform text, p_ops jsonb) returns jsonb language plpgsql security invoker set search_path = '' as $$` | `:79-89` |
| `declare` (incl. `v_writable` `:104`, `v_business` `:105`, `v_cols` `:106`) | `:90-…` |
| entity `case` | `:178-238` |
| `money_transaction` branch | `:182-186` |
| `finance_entry` branch | `:193-196` |
| `v_writable := v_business || client_created_at/client_updated_at || deleted_at` | `:276-278` |
| `v_cols` = writable columns present in payload | `:284-286` |
| insert (create) using `v_cols` | `:300-312` |
| "same create" (3b) comparison over `v_business` columns present in the payload | `:322-337` |
| update using `v_cols` only | `:342-357` |
| `end` / `$$;` | `:458-459` |
| `comment on function public.sync_push(...)` | `:461-462` |
| `sync_pull` (`to_jsonb(t)` for money_transaction `:497-498`, finance_entry `:512-513`) | `:472-587` |
| `sync_pull_v2` (`to_jsonb(t)` `:623-624`, `:638-639`) | `:598-716` |
| Privileges: `revoke all on function public.sync_push(...) from anon, authenticated, public;` / `grant execute … to authenticated;` | `:731-732` (banner `:720-724` explains Supabase default privileges re-grant new objects) |

The exact `v_business` arrays that 027 extends (verbatim, `:182-186` and `:193-196`):

```sql
      when 'money_transaction' then
        v_table := 'money_transactions'; v_policy := 'financial'; v_deletable := false;
        v_business := array['person_id','idempotency_key','amount_minor','currency_code','direction','kind',
                            'occurred_at','occurred_on','tz_offset_minutes','note','edited_at','deleted_at',
                            'occasion_id','counts_toward_balance','source','ocr_scan_id'];
```

```sql
      when 'finance_entry' then
        v_table := 'finance_entries'; v_policy := 'financial'; v_deletable := false;
        v_business := array['category_id','idempotency_key','type','amount_minor','currency_code',
                            'occurred_at','occurred_on','tz_offset_minutes','note','edited_at','deleted_at'];
```

027 target: append `,'import_source'` to each array (after `'ocr_scan_id'` and after `'deleted_at'` respectively). Since `v_writable` is derived from `v_business` (`:276`) and `v_cols` keeps only payload-present columns (`:284-286`), this one change makes the column writable on insert/update and leaves it untouched when a v1.0.1 payload omits it. It also adds it to the "same create" comparison (`:322-337`), which is exactly why sync-wire-027 §6 case 7 (create retry spanning the deploy) answers `conflict`.

Recommendations for T147 (no edits made here):

1. Generate 027 by copying `:79-459` (function) and `:461-462` (comment, extended with "027 adds import_source to money_transaction and finance_entry") then patching only the two arrays, so `diff` against 026 shows two lines plus the comment.
2. Restate `:731-732` (revoke/grant on `sync_push`) at the end of 027, as 026 does. `create or replace` keeps existing ACLs in Postgres, but the repo convention restates them.
3. Column DDL: `alter table public.money_transactions add column import_source text check (import_source in ('sms'));` and the same for `public.finance_entries`. Table grants are table-level (`20260927120000_021_offline_sync.sql:832-846`: `grant select, insert, update on … public.money_transactions, … public.finance_entries …`), so the new columns need no grant.
4. Analytics views in `20260927120200_021c_analytics_views.sql` (`:11,28,51,68`) do not `select *` (no `.*` found), so they are unaffected.
5. pgTAP pattern for T148: `supabase/tests/026_finance_entry_audits.test.sql`, `021_sync_push.test.sql`, `021_rls.test.sql`.

## 6. CI UTC re-run (T151)

`.github/workflows/ci.yml:40-43`: "Test sync in UTC", `TZ: UTC`, `flutter test --reporter=github test/core/sync test/features/transactions/data/sync test/features/finance/data/sync`. `test/core/sync/legacy/` is a subdirectory of `test/core/sync`, so it is **already covered** by the existing command; T151 may only need a comment or nothing. The orchestrator should decide whether T151 is a no-op.

## 7. Other anchors

- `SyncMapper` interface (unchanged since v1.0.1): `lib/core/sync/sync_mapper_registry.dart:16-28` (`fromWire(json, {Row? existingLocal})`).
- `sync_entity_type.dart` needs no change for 027 (no new entity type; sync-wire-027 §3).
- No `import_source` exists anywhere in `lib`, `test` or `supabase` today (grep, empty).
- Precedent for a frozen legacy copy in tests: `test/core/money/egp_formatter_regression_test.dart` (header `:9-14`: the pre-018 implementation from `git show d4c2515~1:...` frozen as `_LegacyEgpFormatter`, and outputs compared against it). T149 can follow the same header style, naming `c86e2df` and the source paths.
