# Decisions: Phase 11b — sync mappers (T146, T150)

Slice owner: Phase 11b subagent. No build_runner run, no git operation, no remote database contacted.

Files changed:

- `lib/features/transactions/data/sync/money_transaction_sync_mapper.dart` (T146, +9 lines)
- `lib/features/finance/data/sync/finance_entry_sync_mapper.dart` (T146, +9 lines)
- `test/features/transactions/data/sync/money_transaction_sync_mapper_test.dart` (phase 2b edit reverted, +9 tests)
- `test/features/finance/data/sync/finance_entry_sync_mapper_test.dart` (phase 2b edit reverted, +9 tests)
- `test/core/sync/fakes/fake_sync_remote.dart` (test fake: `'import_source'` added to the two financial business lists)
- `test/core/sync/import_source_sync_test.dart` (new, 16 tests)

## Results

| Task | Status | Evidence |
|---|---|---|
| T146 | [X] | `toWire`: `if (row.importSource != null) 'import_source': row.importSource`. `fromWire`: `importSource: Value(SyncWire.stringOrNull(json, 'import_source') ?? existingLocal?.importSource)`. |
| T150 | [X] | 18 mapper tests (9 per mapper) + 16 harness tests, all passing in the local TZ and with `TZ=UTC`. Mutation check: removing `?? existingLocal?.importSource` fails 10+ of them; removing `'import_source'` from the fake's lists fails the case-7 conflict test. Both mutations were reverted (diff verified). |

Verification (observed):

- `fvm dart format` on the 6 files: 0 changed.
- `fvm flutter analyze` on the slice (`lib/features/{transactions,finance}/data/sync`, `test/core/sync`, `test/features/{transactions,finance}/data`): **No issues found**. Full `fvm flutter analyze`: **3 errors, none in this slice**. All are `not_enough_positional_arguments` for `SmsImportRepositoryImpl.new` (in `lib/core/di/injection.config.dart:1239` and two `test/features/sms_import/**` tests). The Phase 3 agent changed that constructor while it was still working, and the DI codegen hasn't been regenerated yet.
- `fvm flutter test test/core/sync test/features/transactions/data test/features/finance/data`: **404 passed, 0 failed, 0 skipped, 2 files failed to load**. With `TZ=UTC`: **404 passed, the same 2 load failures**. The two files are `test/core/sync/sync_mapper_registry_test.dart` and `test/core/sync/table_classification_guard_test.dart`. Both import `core/di/injection.dart`, so they fail to compile on the same stale `injection.config.dart`. This change didn't cause them, and they'll load again once the Phase 3/DI owner reruns build_runner. **Rerun those two files after that regeneration.**

## Decisions

| # | Doc conflict or ambiguity | Choice | Why |
|---|---|---|---|
| 1 | The task text has `json['import_source'] as String?`, but discovery/sync.md §1 and the contract §3 ("A tiny `SyncWire.stringOrNull` reuse") suggest `SyncWire.stringOrNull` | `SyncWire.stringOrNull(json, 'import_source') ?? existingLocal?.importSource` | Strings and null give the same result. A non-string value throws a `FormatException` (the per-row "unreadable" path the applier already handles), not a `TypeError`. A test pins this. |
| 2 | The 3 phase-2b expectations (`.copyWith(importSource: const Value.absent())`) | Reverted to the original HEAD expectations, `row.copyWith(date: …).toCompanion(false)`, byte-identical to HEAD. | With T146, `fromWire` on a row with no local copy returns `importSource: Value(null)`, exactly what `toCompanion(false)` of a null-provenance row carries. The original "round-trips losslessly" assertions are therefore correct again, at full strength. New tests cover `'sms'` round-trips and the keep-local cases. |
| 3 | No local row and the key absent: `Value(null)` or `Value.absent()`? | `Value(null)` (the task's literal formula) | Only the applier calls `fromWire`, and it passes `existingLocal` whenever a local row exists. With no local row, there is nothing to preserve, and `Value(null)` on insert is the same as the column default. The legacy T149 copy leaves it absent, which is also harmless. |
| 4 | Where the DB-backed T150 cases go ("the same through `keepTheirs`", "legacy edit-push") | The pure mapper cases are in the two feature test files the task names. The cases that need a database, outbox, engine or resolver are in `test/core/sync/import_source_sync_test.dart`, next to the other `SyncHarness` tests. | `keepTheirs` and pushes need the harness, which lives in `test/core/sync/fakes/`. The contract §6 also places the import-source sync test under `test/core/sync/`. CI's UTC re-run (`ci.yml:43`) covers both locations. |
| 5 | `SyncHarness` has no finance-entry helpers and no `importSource` parameter (discovery-t007-t009 #6) | `sync_harness.dart` is **not** edited. Local helpers in the new test file insert with `importSource: const Value('sms')` and record through `outbox.recordUpsert(…, mapper.toWire(row))` inside one `db.transaction`, the way the DAOs do. | Keeps shared test infrastructure unchanged (the briefing's minimal-change rule). The Phase 3 repository write path (`confirm`) belongs to the other agent. Its own scrub test (contract §6 bullet 5) should use the real `SyncOutbox` payload. |
| 6 | Fake business lists (`fake_sync_remote.dart`) | Added `'import_source'` to the `money_transaction` and `finance_entry` lists only. I didn't backfill the four 022 columns the fake's `money_transaction` list also lacks (`occasion_id`, `counts_toward_balance`, `source`, `ocr_scan_id`). | This mirrors 027 exactly. Backfilling 022 would change existing "same create" behaviour in unrelated tests, which is out of scope. That pre-existing gap is noted here for whoever owns the fake. |
| 7 | sync-wire-027 §6 case 7 ("same op → conflict") | Followed phase11a decision 5. **Same `op_id`** (response lost after a commit on a pre-027 server that dropped the key) → `already_applied` from the ledger: no conflict, the server column stays null, local `'sms'` is kept. **New `op_id`**, no base revision, key differs → `conflict`. `keepTheirs` then keeps local `'sms'`. A control (the same create with no provenance) → `already_applied`. | The fake reproduces the ledger the same way as the real `sync_push`. All three outcomes are pinned, like the pgTAP f1/f2/control. |
| 8 | How to model a "v1.0.1 edit-push" on the harness | Today's `toWire` minus the `import_source` key. | discovery/sync.md §1: `toWire` is byte-identical between v1.0.1 (`c86e2df`) and HEAD, apart from the date line that `fromWire` reads. T146 adds only the conditional key, so removing it gives the v1.0.1 shape. |
| 9 | How to model "key present and null" and "key absent" on pull | A rewritten server row at a new revision (`seedServerRow`) with `import_source: null` (a post-027 `to_jsonb` of a pre-027 row) or with the key removed (a server before 027). Each case also checks that the pulled amount was applied, so the keep-local assertion can't pass because nothing was pulled. | discovery/sync.md §4(b). |
| 10 | Unknown provenance strings | `fromWire` stores them as they are (`'wallet'` is tested). It doesn't validate against `{'sms'}`. | Contract §3: "Unknown strings are stored as-is (domain `ImportProvenance.unknown`)". Rejecting them would bring back the 022-class pull failure for a future value. |

## Follow-ups

- **DI/codegen owner (Phase 3)**: regenerate `injection.config.dart`, then rerun `test/core/sync/sync_mapper_registry_test.dart` and `test/core/sync/table_classification_guard_test.dart` (local and `TZ=UTC`).
- **T148** is still unexecuted (phase11a). The fake now mirrors 027's comparison, but only pgTAP proves what the real server does.
- **Phase 3 `confirm`**: the SMS Add must set `importSource: 'sms'` on the inserted row *before* `toWire` is recorded in the outbox (same transaction), or the push won't carry it.
