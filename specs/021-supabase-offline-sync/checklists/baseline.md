# Pre-feature Baseline (T001)

**Feature**: 021-supabase-offline-sync | **Recorded**: 2026-09-27 | **Commit**: `c59c735` (branch `021-supabase-offline-sync`)

This file is the regression reference for T086.

## Toolchain

- `flutter --version`: **Flutter 3.47.0** • channel stable • framework revision `4cf2416426` (2026-08-11) • engine `59d54a2b28`. Matches the required 3.47.x.

## Static analysis

- `flutter analyze`: **No issues found** (0 issues).

## Unit and widget tests

- `flutter test`: **1365 passed, 0 failed, 0 skipped** ("All tests passed!").

## Integration flows (`integration_test/*_test.dart`)

No simulator, emulator or desktop target was available when the baseline was recorded (the only attached device was a physical, wirelessly connected iPhone, which was not used for automated runs). The 11 flows are therefore recorded as **not run**; they must be run on a simulator/emulator before T086 compares against them.

| Flow | Status |
| --- | --- |
| `archive_state_refresh_flow_test.dart` | not run (no simulator/emulator) |
| `currency_flows_test.dart` | not run (no simulator/emulator) |
| `finance_flows_test.dart` | not run (no simulator/emulator) |
| `financial_education_flows_test.dart` | not run (no simulator/emulator) |
| `insights_notifications_flows_test.dart` | not run (no simulator/emulator) |
| `language_switch_flow_test.dart` | not run (no simulator/emulator) |
| `liquid_glass_flow_test.dart` | not run (no simulator/emulator) |
| `money_relationships_flows_test.dart` | not run (no simulator/emulator) |
| `onboarding_flow_test.dart` | not run (no simulator/emulator) |
| `splash_startup_flow_test.dart` | not run (no simulator/emulator) |
| `theme_switch_flow_test.dart` | not run (no simulator/emulator) |

## Plan §1 facts (confirmed)

- [X] `AppDatabase.schemaVersion == 8` (`lib/core/database/app_database.dart`).
- [X] The 7 DAOs under `lib/features/*/data/datasources/`: `currency_dao.dart`, `finance_dao.dart`, `notifications_dao.dart`, `onboarding_dao.dart`, `people_dao.dart`, `settings_dao.dart`, `transactions_dao.dart`.
- [X] No `INTERNET` permission in `android/app/src/main/AndroidManifest.xml` (only `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`).

## T043: offline regression over the 11 integration flows

**Run**: 2026-09-27 at `b45189c` (branch `021-supabase-offline-sync`), iOS simulator **iPhone 17 Pro** (iOS 26.4, UDID `62266C4A-…`), `flutter test integration_test/<flow> -d <udid>`, **no `--dart-define`**.

**Offline equivalent**: a simulator cannot toggle airplane mode. Without the defines `CloudConfig.isConfigured` is false, so `SyncScheduler.start()` reports `disabled` and never initializes Supabase or opens a connection. The app therefore runs with no network use at all, which covers what an airplane-mode run checks for the app's own code.

**Pre-021 comparison**: T001 recorded every flow as "not run". To get a real reference, each flow that failed was run again on the same simulator from a separate worktree at `fbce88f` (the last commit before any 021 code). The app was uninstalled first so the schema-v9 database would not be reused.

| Flow | 021 (`b45189c`) | Pre-021 (`fbce88f`) | Verdict |
| --- | --- | --- | --- |
| `splash_startup_flow_test.dart` | pass (3/3) | — | pass |
| `financial_education_flows_test.dart` | pass | — | pass |
| `insights_notifications_flows_test.dart` | pass | — | pass |
| `liquid_glass_flow_test.dart` | pass | — | pass |
| `theme_switch_flow_test.dart` | pass | — | pass |
| `archive_state_refresh_flow_test.dart` | fail (0 pass, 3 fail) | fail (0 pass, 3 fail), same tests | pre-existing |
| `currency_flows_test.dart` | fail (3 pass, 1 fail) | fail (3 pass, 1 fail), same test | pre-existing |
| `finance_flows_test.dart` | fail (4 pass, 4 fail) | fail (4 pass, 4 fail), same tests | pre-existing |
| `language_switch_flow_test.dart` | fail (1 pass, 1 fail) | fail (1 pass, 1 fail), same test | pre-existing |
| `money_relationships_flows_test.dart` | fail (1 pass, 4 fail) | fail (1 pass, 4 fail), same tests | pre-existing |
| `onboarding_flow_test.dart` | fail (5 pass, 6 fail) | fail (5 pass, 6 fail), same tests | pre-existing |

For all 6 failing flows, the failing test names and exception types match between the two commits. These are test-harness and environment problems, not 021 regressions:

- **Taps that miss their target** (archive, currency, finance, money_relationships): `tap()` on bottom-anchored controls (a FAB or Save at y≈830 on this 874-pt screen) lands on the shell's bottom navigation bar instead ("would not hit test on the specified widget"). The next `enterText` then finds no field ("Bad state: No element").
- **Onboarding**: `l10nOf` reads `AppLocalizations.of` from the `DaftaryApp` element, which is above `Localizations`, so it returns null and throws "Null check operator used on a null value".
- **Language switch**: no widget has the Arabic label "الشخص" on the transaction form.

No 021 code change was needed. T043 stays open because the task requires every flow to pass. Fixing these 6 flows is follow-up work outside 021.

## T062: offline sync device flow

`integration_test/offline_sync_flow_test.dart` was run against the local Supabase stack (`supabase start`, all 021 migrations) on the same simulator, with `--dart-define-from-file=config/supabase.local.json` (git-ignored). It passed 3 consecutive runs, 5/5 each time. Connectivity comes from an injected fake `ConnectivityMonitor`. Each run uses a private database file and a fresh anonymous account. Cloud state is read over REST with the app's own session, so RLS scopes every query to that account. `psql` checked the results independently.

| Scenario | Result |
| --- | --- |
| Offline create → restart (container and database reopened) → data present (repositories and the People screen) → online → sync → the cloud has exactly 1 person and 1 transaction | pass |
| Offline update (person and transaction) → sync → the cloud has the new values plus an `edited` audit row | pass |
| Offline soft-delete of the transaction and archive of the person → sync → `deleted_at` set, `is_archived = true` | pass |
| Remote forced down → operations stay `pending` (`error_code = network`) and the scheduler backs off → restored → "Sync now" → synced, `consecutive_failures = 0` | pass |
| Upload interrupted after the server applied it (response lost) → repeated → the server answers `already_applied`, the row exists once, and `GROUP BY idempotency_key HAVING count(*) > 1` returns 0 rows | pass |

`psql` (run 1, owner `4ac0a16b-…`): 2 people (1 archived), 3 transactions (1 deleted). The duplicate `idempotency_key` query returns 0 rows for that owner and across all owners. Audit rows: created 3, edited 1, deleted 1. Without the defines, the file skips itself, so a plain `flutter test integration_test/` stays offline.
