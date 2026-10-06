# Quickstart: validating the Financial Trust Audit

## Baseline (T002, recorded 2026-10-05 on branch `022-financial-trust-audit`)

- `fvm flutter test`: **3,699 passed, 0 failed** (run on `main` at c86e2df; the branch has no code changes)
- `fvm flutter analyze`: **No issues found**
- `dart format --output=none --set-exit-if-changed lib test`: **exit 0**

## Prerequisites

- fvm Flutter 3.47.0, with `fvm flutter pub get` already run
- An Android emulator (API 34+), plus a v1.0.1 APK for the upgrade and older-app checks
- Optional: a development Supabase project linked for the sync scenarios. You run `supabase db push` yourself.

## Track 1: the audit document

1. Baseline: `fvm flutter test`. Expected: **All tests passed (3,699)**, as recorded on 2026-10-05.
2. Run the app and step through the 29 flows in spec FR-006 in Arabic and English, each in light and dark. Record the results in `audit.md` §5.
3. Reproduce each P0/P1 by hand. For example, A1:
   1. Create "Ahmed" and record "I gave" 1,000 EGP. The balance shows "Ahmed owes you 1,000".
   2. Record a repayment of 400. The balance is now 600.
   3. Edit that repayment and switch the direction to "I gave". **Today**: the balance becomes 1,400 and the row still says "Repayment". **After A1**: the direction is read-only and the balance stays 600.
4. Count repayments already flipped by the A1 defect (research R8) on a debug build's DB with `sqlite3`:

   ```sql
   SELECT DISTINCT t.id, t.person_id, t.direction AS now_direction,
          json_extract(a.previous_values_json, '$.direction') AS earlier_direction
   FROM money_transactions t
   JOIN transaction_audit_entries a ON a.transaction_id = t.id
   WHERE t.kind = 'repayment' AND t.deleted_at IS NULL
     AND a.change_type = 'edited'
     AND json_extract(a.previous_values_json, '$.direction') <> t.direction;
   ```

   Report the count in audit §16. Nothing is rewritten automatically (Financial Domain Override).
5. Check `audit.md` against [contracts/audit-report.md](contracts/audit-report.md).

## Track 2: per wave

| Wave | Command | Expected |
| --- | --- | --- |
| 0 | `fvm flutter test test/features/transactions/domain/catalogue test/features/occasions/domain/catalogue test/features/finance/domain/catalogue test/features/budgets/domain/catalogue test/features/savings/domain/catalogue test/core/money/amount_input_catalogue_test.dart test/core/database/upgrade_financial_snapshot_test.dart` | All green on *current* code. The only skips are `Known fail A1`, `Known fail B2` and `Known fail RF-07`. |
| 1 | `fvm flutter test test/features/transactions test/core/sync` and `TZ=UTC fvm flutter test test/core/sync test/features/transactions/data/sync test/features/finance/data/sync` | S0, A1, B1 (including the repair) and B2 tests pass. The A1 and B2 catalogue skips are removed. |
| 2 | `fvm flutter test test/core/sync test/features/cloud_sync` | The savings conflict lifecycle passes in the fake remote. |
| 3–4 | `fvm flutter test`, plus RTL/theme goldens (`--update-goldens` only for E1, after the owner signs off §8) | Full suite green. Golden diffs only on screens with reworded or new copy. |
| Every wave | `fvm flutter analyze` and `dart format --set-exit-if-changed .` | Clean |

## Sync rollout order (you deploy; binding; revised 2026-10-06)

1. `supabase test db` (runs `supabase/tests/026_finance_entry_audits.test.sql`), then `supabase db push` migration **025**.
2. `supabase db push` migration **026**.
3. Ship app **1.1.0**, built with `--dart-define=DAFTARY_APP_VERSION=1.1.0` (the release workflow does this).

Never ship 1.1.0 before 026 is live: the app downloads through `sync_pull_v2`, which only 026 creates.
The app version is **1.1.0** (`pubspec.yaml` `version: 1.1.0+3`). Migration 025 compares `p_app_version` against `'1.1.0'`. The app reports its version through `--dart-define=DAFTARY_APP_VERSION` (`syncAppVersion`), which `.github/workflows/release-android.yml` now passes from the tag; a build without it reports `unknown` and stays last-write-wins. `release-android.yml` refuses to build pre-release tags such as `v1.1.0-rc1`; a manual build with such a version is unparsable for `app_version_at_least` and stays last-write-wins. Debug and CI builds report `unknown` (last-write-wins) unless built with `--dart-define=DAFTARY_APP_VERSION=1.1.0`. The `config/supabase.*.json` files carry the project URL and key, so the define is not added there. Any iOS or manual release build must also pass `--dart-define=DAFTARY_APP_VERSION=<x.y.z>` (for example `1.1.0`); without it the build reports `unknown` and the savings-conflict policy silently stays last-write-wins.

## SQL checks (dev project, SQL editor, signed in as a test user)

| Check | How | Expected |
| --- | --- | --- |
| Old app keeps last-write-wins (025) | Call `sync_push` twice for the same savings contribution, the second time with a stale `base_revision` and `p_app_version = '1.0.1'` | The second result is `applied` |
| New app gets conflicts (025) | Same, with `p_app_version = '1.1.0'` | The second result is `conflict` |
| Old download unchanged (026) | Insert a finance-entry audit through 1.1.0, then call `sync_pull(0, 500)` | No row has `entity_type = 'finance_entry_audit'` |
| New download complete (026) | `sync_pull_v2(0, 500)` | It includes the `finance_entry_audit` rows |
| RLS on the new table (026) | As user B, `select * from finance_entry_audits` for user A's rows | 0 rows; inserting for A fails |

## Older-app check (CHK163, CHK165)

Install v1.0.1 on phone 1 and the branch build on phone 2, signed in to the same account, after 025 and 026 are deployed.
- Edit the same savings contribution offline on both phones, then sync both.
- Edit a finance entry on phone 2.

Phone 1 keeps syncing with no errors and no stuck items. Phone 2 shows a savings conflict when its edit loses.
