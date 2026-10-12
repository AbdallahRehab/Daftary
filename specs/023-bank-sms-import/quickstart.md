# Quickstart: validating Bank SMS Transaction Import

Runnable scenarios that prove feature 023 end to end. Shapes and rules are defined elsewhere, not repeated here: [data-model.md](data-model.md), [contracts/sms-platform-channel.md](contracts/sms-platform-channel.md), [contracts/parser-contract.md](contracts/parser-contract.md), [contracts/domain-interfaces.md](contracts/domain-interfaces.md), [contracts/sync-wire-027.md](contracts/sync-wire-027.md), [contracts/ui-contract.md](contracts/ui-contract.md). All SMS below are **synthetic**.

## Prerequisites

- `fvm flutter` 3.47.0 (`.fvmrc`), then `fvm flutter pub get`, then `fvm dart run build_runner build --delete-conflicting-outputs` after any Drift or injectable change.
- An Android 14 or 15 device or emulator (API 34/35). Use a real Android 15 device installed from a downloaded APK for the restricted-settings scenario; an emulator installs from `adb` and may not reproduce it.
- An iOS 17+ simulator or device for the paste check.
- For the server check: Colima running (`colima start`), the Supabase CLI, and Docker available.
- Build with the SMS capability on (default is off):

  ```bash
  export DAFTARY_SMS_IMPORT=true          # one Gradle switch; no --dart-define
  fvm flutter run -d <android-device>
  # release shape:
  fvm flutter build apk --release
  ```

  Without the variable the build must behave as "paste/share only" (scenario 9).
- Inject synthetic SMS into an **emulator** inbox (numeric sender only; alphanumeric sender IDs such as `NBE` need a real device or the debug "inject synthetic message" tile):

  ```bash
  adb emu sms send 15550100 "Your card ending 1234 was charged EGP 125.50 at TEST MARKET on 04/03/2026"
  adb shell content query --uri content://sms/inbox --projection _id,address,date | head   # verify arrival
  ```

  To test sender filtering with a numeric bank sender, temporarily add `15550100` to a debug-only profile via the debug seed tile; never commit it.

## 1. Automated suites

```bash
fvm flutter analyze
dart format --output=none --set-exit-if-changed lib test
fvm flutter test                                                  # everything; must be green with no existing test changed in behavior
fvm flutter test test/features/sms_import/data/parsing            # normalization, masking, splitter, bank profiles, corpus gate
fvm flutter test test/features/sms_import/data/parsing/corpus_test.dart   # SC-001 per-bank accuracy gate
fvm flutter test test/features/sms_import/data/crypto             # AES-GCM, HMAC, key loss
fvm flutter test test/features/sms_import/domain                  # confidence, permission classifier, duplicate tiers, mapping
fvm flutter test test/features/sms_import/presentation            # cubits, widgets, RTL/theme, l10n parity, string guard
fvm flutter test test/features/sms_import/privacy                 # sentinel leak suite and static no-logging guard
fvm flutter test test/core/database/v13_migration_test.dart test/core/database/data_wipe_test.dart test/core/sync/table_classification_guard_test.dart   # v13 test covers 11->13 and 12->13
TZ=UTC fvm flutter test test/core/sync test/features/transactions/data/sync test/features/finance/data/sync   # includes legacy v1.0.1 compat
fvm flutter test test/performance/sms_ingest_scale_test.dart      # 500-message budget (SC-005)
fvm flutter test integration_test/sms_import_flows_test.dart -d <device>   # device only, not run in CI
tool/check_merged_manifest.sh                                      # merged manifest, capability off and on
```

Expected: all pass; the corpus test prints a per-bank accuracy table with every shipped bank at or above 95% and noise rejection at 100%.

## 2. Manual walkthrough by user story (Android, capability build)

**US2 enable and scan**
1. Fresh install (or clear data). Home shows a one-time "Bank messages" card; nothing asked yet. Expected: no permission dialog at startup.
2. Settings -> Bank messages -> Enable. Expected: explanation sheet first (what is read, what is never done, how to turn off), then the system READ_SMS dialog. Grant.
3. Choose 30 days, tap Scan. Expected: progress with a Cancel button, then a content-free summary (found, ready, needs review, skipped, unreadable). Cancel mid-way: items already staged stay.
4. Deny instead: expected the denied card with "Paste a message" fallback; deny again: permanently denied card with "Open App info". On Android 15 from a downloaded APK: expected the restricted-settings guide with numbered steps.

**US1 review and add**
5. Open a pending item (a card purchase). Expected: type Expense, amount, currency, date, suggested category, bank and masked last four, confidence label with icon, "Show original message" in the message's own direction. Add stays disabled until required fields are valid.
6. Edit category, tap Add. Expected: one new expense in Finance history labeled "Imported from a bank message"; the review advances to the next item; the original text is gone (Show original unavailable for that item). Open the record's change history: a `created` entry exists.
7. Switch a transfer item to Given with a matching person: expected one-tap person pre-selected; Repayment is not offered.

**US3 catch-up**
8. With the feature on, background the app, `adb emu sms send` a recognized message, reopen. Expected: it appears as pending with no notification and no duplicate; reopening again within 60 s does nothing; turning the feature off stops catch-up immediately.

**US4 paste and share**
9. Open Paste, paste two messages, one unrecognized. Expected: summary "1 recognized, 1 skipped", the unrecognized text is stored nowhere. Share a message from Google Messages (or `adb shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "<synthetic>" com.daftary.daftary/.ShareTargetActivity`) with App Lock on: expected routing only after unlock; share while the app is backgrounded creates no second app instance (`adb shell dumpsys activity activities | grep -c MainActivity` stays 1).

**US5 duplicates**
10. Add an expense by hand with the same amount and currency as a pending item, one day apart. Open the item: expected the side-by-side sheet with Add anyway / It's the same - don't add. Choose "same": item closes, no record changes. Re-scan 90 days: expected 0 resurfaced items (SC-014). Re-paste the same message: 0 new items.

**US6 ignore, mute, undo**
11. Ignore one item, then multi-select and ignore two more (confirm dialog). Open Ignored: Undo one. Expected the copy "it returns after re-scan or re-paste"; after a re-scan it is pending again. Mute a sender: its pending items are deleted (no tombstones) and no new ones appear.

**US7 transfers, people, categories**
12. Toggle "count cash withdrawals as spending": an ATM item flips from Ignore suggested to Expense. Save an item with a non-suggested category, then scan a second message from the same merchant: expected the learned category.

**US8 lifecycle**
13. Revoke SMS permission in system settings, return to the app: expected "automatic import is off", pending items still reviewable, no prompt. Delete all data (Settings): expected every pending item, tombstone, mute, mapping and both keys gone.

## 3. iOS paste check

1. Run on iOS with no capability. Settings shows no scan option; Home quick action opens Paste.
2. Open Paste with text on the clipboard. Expected: **no** iOS paste prompt on open or resume and the field empty.
3. Long-press the field and use the system Paste. Expected: no prompt, text appears. Tap the Paste button: iOS 16+ may show its prompt (expected), then the text appears. Empty clipboard: "nothing to paste" state.
4. Confirm `git diff --stat -- ios/` shows no changes for this feature.

## 4. Privacy checks

1. `fvm flutter test test/features/sms_import/privacy`: sentinel message (unique merchant, amount 987654.32, card `4111111111111111`, reference `998877665544`) never appears in captured logs, outbox payloads, CSV export, any table cell (TEXT or BLOB) outside confirmed fields, or the saved `note`.
2. On a debug build, after Add or Ignore, pull the DB and inspect: `adb exec-out run-as com.daftary.daftary cat databases/<db file> > /tmp/d.db; sqlite3 /tmp/d.db "select count(*) from pending_sms_imports where status!='pending' and raw_blob is not null;"` Expected 0. While pending, `raw_blob` must not contain the plaintext (`strings` shows nothing readable).
3. `adb logcat -d | grep -i -E "TEST MARKET|987654|4111"` after a full scan and Add. Expected no output.
4. Export CSV: no SMS column or provenance header. Delete all data: the five new tables are empty.
5. Backup: `adb shell bmgr backupnow com.daftary.daftary` is optional; after a simulated restore Show original must be unavailable (key-loss path is also unit-tested).

## 5. Manifest and build checks

```bash
tool/check_merged_manifest.sh                      # unset: no SMS permission at all; set: exactly READ_SMS; both: no SMS receiver, ShareTargetActivity with the SEND text/plain filter present
fvm flutter build apk --release                    # without the env: aapt dump permissions must list no READ_SMS
$ANDROID_HOME/build-tools/<ver>/aapt dump permissions build/app/outputs/flutter-apk/app-release.apk | grep -i sms
```

Expected for the capability build: READ_SMS present; RECEIVE_SMS, SEND_SMS, READ_PHONE_STATE absent. In the SMS-free build sharing still works (share a message and it reaches Paste). Two APKs built with and without the switch share one `versionCode`; installing one over the other keeps pending rows.

## 6. Migration 027 compat check (local Supabase)

```bash
colima start                       # Docker runtime for Supabase
supabase start
supabase db reset                  # applies 021 ... 027 in order on a clean database
supabase test db                   # runs supabase/tests/*.test.sql, including 027_import_source.test.sql
```

Expected: 027 tests pass: (a) `import_source: 'sms'` persists on both tables, (b) a v1.0.1-shaped update without the key leaves it intact, (c) old rows read null, (d) the check rejects other values, (e) pull output contains the key. Client side: `TZ=UTC fvm flutter test test/core/sync/legacy` proves frozen v1.0.1 mappers accept post-027 rows with an unknown extra key and a legacy edit-and-push keeps provenance.

**Deploy order for real environments** (you run these): 025 -> 026 -> v1.1.0 (022) -> 027 -> v1.2.0 (023). `supabase db push` may apply 027 together with 025/026 (the column is optional), but never release 1.2.0 before 027 is live.

## 7. Release gates (manual, on target devices)

- Play Protect: install the capability APK from a browser download on an Egyptian-market device with enhanced fraud protection on (OQ5). If blocked, build the two-APK fallback.
- Android 15 restricted settings: complete the enable flow from a downloaded APK and time it (SC-015, 2 minutes).
- Version and tag: confirm `pubspec.yaml` is `1.2.0+4`, tag `v1.2.0` matches `x.y.z`, release job output contains both APKs and the `aapt` assertion step passed.
