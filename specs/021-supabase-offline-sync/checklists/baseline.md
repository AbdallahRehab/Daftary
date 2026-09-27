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
