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

No 021 code change was needed. T043 stayed open until these 6 flows were fixed (see "T043 follow-up" below).

### T043 follow-up: the 6 failing flows fixed (2026-09-28)

**Run**: 2026-09-28, branch `021-supabase-offline-sync` (on top of `9922fb3`), same simulator (**iPhone 17 Pro**, iOS 26.4), `flutter test integration_test/<flow> -d <udid>`, **no `--dart-define`**. `offline_sync_flow_test.dart` skips itself without the defines, as before.

| Flow | Result |
| --- | --- |
| `archive_state_refresh_flow_test.dart` | pass (3/3) |
| `currency_flows_test.dart` | pass (4/4) |
| `finance_flows_test.dart` | pass (8/8) |
| `financial_education_flows_test.dart` | pass (5/5) |
| `insights_notifications_flows_test.dart` | pass (7/7) |
| `language_switch_flow_test.dart` | pass (2/2) |
| `liquid_glass_flow_test.dart` | pass (2/2) |
| `money_relationships_flows_test.dart` | pass (5/5) |
| `onboarding_flow_test.dart` | pass (11/11) |
| `splash_startup_flow_test.dart` | pass (3/3) |
| `theme_switch_flow_test.dart` | pass (3/3) |

**11/11 flows pass.** `flutter analyze`: 0 issues. `flutter test`: 1761 passed (1758 + 3 new regression tests).

Root causes and fixes:

1. **FABs under the glass bottom bar (app bug, from 020 `fbce88f`)**: this caused the FAB failures in currency, finance, money_relationships and language_switch. With Liquid Glass ON (the default), the shell's `Scaffold` extends its body behind the bottom bar and passes the bar's height down as bottom `padding`, but not as `viewPadding`. A page's floating FAB is placed from `viewPadding`, so every in-shell FAB (record transaction, add person, finance add income/expense, add exchange rate) sat under the bar at y≈830, where taps reach the bar instead. The hit test landed on a `NavigationBar` destination. Fix: `AppScaffold` (glass ON, with a FAB) raises `viewPadding.bottom` to `padding.bottom`, so the FAB sits just above the bar, as it does with glass OFF. OFF is unchanged. Covered by a new test in `test/core/design_system/glass/app_scaffold_test.dart`.
2. **Onboarding copy ignored a live language switch (app bug, pre-021)**: `OnboardingPage`'s `PageView` resolved each page's copy from the item builder's context, so the visible page kept the old language while the progress label and buttons switched. Fix: each page resolves its copy in its own `Builder`, which depends on the localizations. Covered by a new test in `test/widget/onboarding_page_test.dart`.
3. **Onboarding `l10nOf` (test bug)**: it read `AppLocalizations` from the `DaftaryApp` element, which is above `MaterialApp`'s `Localizations`, so it got null. It now reads from the router's `Navigator`.
4. **Onboarding simulated restart (test bug)**: `bootApp` pumped the same `const DaftaryApp()` again, which reused the element tree, so `OnboardingPage`'s step survived the "restart". It now unmounts the old tree first.
5. **Keyboard covering Save (test bug)**: on a simulator the real on-screen keyboard stays up after `enterText` and covers Save. The archive flow's `addPerson` and the money flow's double-tap test now dismiss it and call `ensureVisible` before tapping, as the other Save helpers already did.
6. **Finance category chip under the app bar (test bug)**: `tester.ensureVisible` scrolls as little as possible, which left the chip at the top edge under the glass app bar. `selectCategory` now centres the chip (`Scrollable.ensureVisible(alignment: 0.5)`).
7. **Money scroll-performance test (test bug)**: it flung `find.byType(ListView)`, but `PersonDetailPage` has been a `CustomScrollView` since before 020. Its frame budget was also applied to a debug (JIT) build, where frame times swing widely with host load (8–24 slow frames of ~107 across runs; still 8 with glass OFF). It now warms up with one unmeasured scroll. In debug it requires a median frame ≤ 32 ms and at most 25% slow frames, which still catches a rebuild-the-world bug. The strict 5% tolerance applies in profile/release. Last run: 9 of 106 frames over 32 ms, median 23.2 ms.

The "Language switch: no widget has the Arabic label الشخص" failure was cause 1: the FAB tap missed, so the transaction form never opened. No `lib/core/sync` or other 021 code was touched.

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
