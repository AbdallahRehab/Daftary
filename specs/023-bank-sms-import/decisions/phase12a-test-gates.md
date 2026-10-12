# Phase 12a: test gates (T152, T153, T154, T155, T166, T168, T169)

All new test files. No `lib/` file was edited, and build_runner was not run.

## Status per task

| Task | Status | File | Tests |
|---|---|---|---|
| T152 | [X] | `test/features/sms_import/privacy/leak_suite_test.dart` | 6 pass |
| T153 | [X] | `test/features/sms_import/offline_flows_test.dart` | 6 pass |
| T154 | [X] | `test/performance/sms_ingest_scale_test.dart` | 2 pass |
| T155 | [X] | `test/features/sms_import/privacy/export_isolation_test.dart` | 5 pass |
| T166 | [ ] owner | `integration_test/sms_ingest_device_benchmark_test.dart` | written and analyzed, **not run** (needs the reference device) |
| T168 | [X] | `test/features/sms_import/domain/rescan_90_day_test.dart` | 2 pass |
| T169 | [X] | `test/features/dashboard/sms_import_totals_test.dart` | 3 pass |

Combined run of the six test files: 24 passed, 0 failed. `fvm dart format`: clean. `fvm flutter analyze` on the 7 files: no issues.

These tests found no production bug.

## T154 benchmark result and the compute/index decision

Measured on the development machine (macOS host VM, `flutter test`, in-memory SQLite, real parser, HMAC and AES-GCM):

- **First scan of 500 allow-listed messages** (plus 150 unknown-sender rows that the gateway filters out): **404–419 ms** over several runs. The result was 316 staged, 64 already known (repeated Arabic-digit bodies collapse by fingerprint), 87 noise and 42 unreadable.
- **Re-scan of the same 500** (all known): **70–331 ms**. It used **7 staging-table SELECTs over 3 pages**. The exact-tier lookup is batched per page (`findKnown`), and the per-row `_isKnown` re-check runs only for rows actually inserted.

**Decision:** the budget (≤ 5 s) is met with more than 10× headroom on the host. The parse stays on the UI isolate (no `compute`), and **no partial indexes are added (no v14 follow-up)**. The test asserts ≤ 5 s per scan and ≤ 8 staging SELECTs per page on a re-scan, as a regression alarm for a per-row round trip.

This is not the SC-005 device figure. T166 must still be run on the reference device. If T166 misses 5 s, this decision is revisited: move `ParseMessages` per page to `compute`, and only after that consider indexes.

## T166 (owner)

`integration_test/sms_ingest_device_benchmark_test.dart` is self-contained, because integration tests in this repo do not import `test/` helpers. It uses the real parser registry, normalizer, HMAC, AES-GCM with keys in the device's real `FlutterSecureStorage`, and a **file-backed** SQLite database in the documents directory. The only fakes are the inbox gateway, the permission and the lifecycle. The input is 500 synthetic allow-listed messages plus 150 unknown-sender rows. The keys are warmed before the stopwatch starts. The test asserts ≤ 5 s and prints the time.

**Owner action:** run it in profile mode on the reference device (4 GB RAM or less, released 2022 or later):

```sh
fvm flutter drive --profile -d DEVICE_ID \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/sms_ingest_device_benchmark_test.dart
```

(`screenshot_driver.dart` is a plain `integrationDriver()` host.) Then record the device, the Android version and the printed time in `quickstart.md`. T166 stays `[ ]` until then.

## Decisions and interpretations

| # | Ambiguity | Choice | Why |
|---|---|---|---|
| 1 | T152 says "no sentinel in `SELECT *` over every table". Research says the sentinels "may appear only in confirmed fields of the saved row". But parsed fields (merchant, amount) are legitimately stored on the pending row (FR-075), and the Undo shell keeps merchant and amount. | The sentinels fall into tiers. **Never anywhere** (no log, `toString`, TEXT or BLOB cell, outbox or CSV): the full card `4111111111111111`, its first 12 digits, the reference `998877665544`, and a raw-only tail `QZSENTINELQZ` that no parser field reads. **Merchant**: allowed only in `pending_sms_imports.merchant` and `merchant_key`, and in `sms_merchant_category_mappings.merchant_key`. **Amount**: never as text (`987654.32` or `987,654.32`) in any TEXT cell. The minor-unit string `98765432` is allowed only in `sync_outbox` (the confirmed amount). Integer columns are not scanned. **Logs and every `toString`**: none of these sentinels, including the merchant and both amount forms. | This is the strictest reading that the spec's own data model allows. The raw-only tail proves that no raw text leaks beyond parsed fields. |
| 2 | "Crash-report sanitization" with no crash reporter in the app | `FlutterError.onError` is replaced with a capture. Every failure the flows return (for example a second Add, a second close-as-duplicate, an export result) is reported through `FlutterError.reportError`, as a reporter would see it. The flows run inside `runZonedGuarded`, which forwards any uncaught error to `FlutterError.reportError`, with `Zone` `print` captured. `debugPrint` is swapped for a capture and restored in `tearDown`. A positive-control test proves that all three channels capture a sentinel. | This covers every path through which a crash report could carry content. |
| 3 | `SyncLogger` spy (research (a)) | Not used. The SMS flows never run the sync engine. The outbox rows are inspected directly instead: no sentinel, `note` null, `import_source == 'sms'`, and no `merchant` or `fingerprint` key. | The logger is only reachable from a sync cycle, which the existing 021 scrub test already covers. |
| 4 | Review flow "driven by presentation" | The review step runs through a real `ImportReviewCubit` built over the real repositories: `load`, `toggleOriginal`, `categorySelected`, `add`. Every emitted state's `toString` is checked. The leak suite and the offline suite build this cubit with its current 10-argument constructor. | Instruction: use cubits directly. If the presentation agent changes that constructor, these two files need the same one-line update as `review_harness.dart`. |
| 5 | The value returned by "Show original" | The decrypted, masked text is the feature's own display value. It is checked for masking (no full card or reference) and that it opens only through the vault, but it is not treated as a log or `toString` leak. | It is meant to be displayed. |
| 6 | `logStatements` | The test greps all of `lib/` for `logStatements` (expects none) and asserts that `_openConnection` uses `NativeDatabase.createInBackground(dbFile)`. | The production connection can't be opened in a unit test. |
| 7 | T153 "no-connectivity fake" | `IOOverrides` (`socketConnect`, `socketStartConnect`) and `HttpOverrides` (`createHttpClient`) refuse and record every attempt for the whole flow, with a positive control. A static guard checks that no `sms_import` file imports `http`, `dio`, `supabase*`, `connectivity_plus`, `web_socket_channel`, `core/sync/remote/` or `connectivity_monitor.dart`. Failures are checked to be neither `Network`, `Timeout`, `Server`, `Unauthorized` nor `Forbidden`. | Nothing in the feature consumes `ConnectivityMonitor`, so a monitor fake would prove nothing. Refusing the sockets themselves is the stronger proof. |
| 8 | T154 "recognized and unrecognized" | 500 rows from allow-listed senders: corpus bank fixtures with their first amount varied, plus 10% wording no template reads. Another 150 rows come from unknown senders, which the gateway filters. `scanned == 500`. | SC-005 counts messages that are read. Unknown senders are filtered by the platform query. |
| 9 | T155 "no provenance header" | The test checks that every CSV section header has no column containing `provenance`, `import_source` or `sms`, and that the headers are identical before and after an SMS Add. The whole CSV has no `sms` and no merchant. The SMS-sourced transaction exports `source = manual` (the existing 2-value enum) with an empty note. A static import closure from `export_user_data.dart` reaches no `lib/features/sms_import` file (with a positive control). `export_user_data.dart` has no diff against `main`. | Invariant 7 plus the "untouched" requirement. |
| 10 | T168 "day 90" with a 30-day default window | The re-scan uses `ScanWindow.days90` at day 90 08:30, so the day-0 messages are still in the window. Calendar: Add, Ignore and "It's the same" on day 0; expiry on day 30; decided rows purged by day 61; re-scan, re-paste, re-share and catch-up on day 90 give 0 new items. A second test checks that tombstones survive until `purge_after − 1 min` and are deleted at `purge_after` (created + 97 days). By then the messages are outside even the 90-day window (`scanned == 0`). | A 90-day re-scan is the only reading under which SC-014 can resurface anything. |
| 11 | T169 dates | The items are added with `date = today` (wall clock), because Home's `DateRange.thisMonth()` reads the real clock. The amounts come from the parsed messages. Given and Received use the one-tap type switch and existing people inserted into the database. | `DashboardCubit` cannot take a fixed clock. |
| 12 | T169 "a split fee counts as one expense" | Generic "Purchase … Foreign transaction fee EGP 7.50" stages a parent and a linked fee item. Both are added. Expense = 250.00 + 300.00 + 7.50, with exactly 4 finance entries. | The fee is its own item (FR-051d) and is counted once, never folded into the parent and never doubled. |

## Notes for the orchestrator

- The `sms_import` presentation suite was not re-run, because the presentation agent is editing that code. These tests touch no shared helper files.
- The scratch exploration file used while writing the tests was deleted.
