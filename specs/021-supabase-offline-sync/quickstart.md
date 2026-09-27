# Quickstart: Validating Offline-First Cloud Sync

**Feature**: 021-supabase-offline-sync

This guide covers how to prove the feature works from end to end. For the definitions it relies on, see [data-model.md](data-model.md), [contracts/sync-rpc.md](contracts/sync-rpc.md) and [contracts/supabase-schema.md](contracts/supabase-schema.md).

## Prerequisites

| Item | How to get it |
| --- | --- |
| Flutter 3.47.x, Dart ≥3.10 | Already installed |
| Supabase CLI (dev only) | `brew install supabase/tap/supabase` |
| Docker (for the local Supabase stack) | Docker Desktop |
| Remote project | `https://nnrmghwqihqnmtnuxzoq.supabase.co`. In the dashboard: enable **Anonymous sign-ins**, and set the email OTP template to use `{{ .Token }}` |
| Client config (never committed) | Copy `config/supabase.example.json` to `config/supabase.dev.json` and fill in `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. Only the publishable key goes here. |

## 1. Database: schema, row-level security and RPC semantics

```bash
supabase start
supabase db reset          # applies supabase/migrations/*_021_offline_sync.sql
supabase test db           # pgTAP: supabase/tests/021_*.test.sql
```

Expected result: every test passes, including the 7 isolation guarantees in contracts/supabase-schema.md §8, the `sync_push` outcome matrix, and a pull that fetches a page with no gaps even under concurrent pushes.

Then push the migration to the remote project with `supabase link --project-ref nnrmghwqihqnmtnuxzoq` followed by `supabase db push`. The database password is typed at the CLI prompt and never stored in the repository.

## 2. Dart unit, Cubit and migration tests (no network, no secrets)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Expected results:

- All existing tests pass.
- The new suites pass: `test/core/sync/**`, `test/core/database/sync_v9_migration_test.dart`, the `watch_*` tests in each feature, and `test/features/cloud_sync/**`.
- With no `--dart-define-from-file`, `CloudConfig.isConfigured` is false and nothing reaches the network.

## 3. On-device offline and online scenarios

```bash
flutter run --dart-define-from-file=config/supabase.dev.json
```

| # | Scenario | Expected result |
| --- | --- | --- |
| 1 | Airplane mode ON, fresh launch. Add a person and 3 transactions, edit one, delete one, archive the person, then unarchive. | Every action shows at once. Settings → Cloud backup shows "Offline · 7 changes waiting". |
| 2 | Force-quit, then relaunch while still offline. | All the data is there, with the same pending count. |
| 3 | Airplane mode OFF. | Within about 10 s the status goes Syncing, then Up to date, with 0 pending. In the Supabase table editor there is exactly 1 person, 3 transactions (1 with `deleted_at`) and the audit rows. |
| 4 | Kill the app while "Syncing" during a 500-change backlog, then relaunch online. | The upload finishes, and the cloud row count equals the local row count. There are no duplicates (check with `select idempotency_key, count(*) … having count(*) > 1`, which should return 0 rows). |
| 5 | Keep Person Detail open. In the dashboard, insert a transaction for that person (with the same owner). Tap "Sync now". | The row and the balance update with no navigation. |
| 6 | Edit the same transaction on the device (while offline) and in the dashboard (bump its fields), then go online. | A conflict badge appears on the row, and Settings shows 1 conflict. "Keep mine" pushes the local version, and a `conflict_resolutions` row exists. |
| 7 | Wi-Fi with no internet (a router with its WAN unplugged). | The app keeps working. The status shows "Retrying in …". There is no error on any existing screen. |
| 8 | Turn the Settings switch OFF, make changes, and watch the network. | 0 requests, while the pending count grows. Switch ON, and everything uploads. |
| 9 | Link email: enter an email, then the 6-digit code. | The status shows the masked email, and `auth.uid()` is unchanged (the same rows remain). |
| 10 | Upgrade path: install the previous release, create data, then install this build over it. | The data is intact, all of it uploads once, and the balances are identical before and after. |

## 4. Builds

```bash
flutter build apk --release --dart-define-from-file=config/supabase.prod.json
flutter build ios --release --no-codesign --dart-define-from-file=config/supabase.prod.json
```

Expected results:

- Both builds succeed.
- The Android release manifest contains `android.permission.INTERNET`.
- iOS resolves the new plugins; if CocoaPods was introduced, the change is reviewed.
- `git grep -nE "service_role|sb_secret_|SUPABASE_PUBLISHABLE_KEY=.+"` finds nothing.

## 5. Checking the logs

Run scenario 3 with `flutter logs`. You should see `SYNC_STARTED`, `SYNC_UPLOAD_SUCCESS count=…`, `SYNC_DOWNLOAD_SUCCESS count=…` and `SYNC_COMPLETED durationMs=…`. No amounts, names, notes, emails or tokens should appear.
