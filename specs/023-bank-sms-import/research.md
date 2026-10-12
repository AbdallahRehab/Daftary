# Phase 0 Research: Bank SMS Transaction Import

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-06 · **Base**: `main` at v1.1.0+3 (`pubspec.yaml:19`)

Every entry below was checked against the code on `main`, the 025/026 migrations and the cited pub packages. Each decision has Decision / Rationale / Alternatives considered / Evidence. Items marked **SPIKE** cannot be settled by reading code and are scheduled as the first tasks of the plan, with a pre-decided fallback.

**Fixed by the spec (not relitigated)**: sideloaded APK reads SMS with READ_SMS only (no RECEIVE_SMS, no receiver, foreground catch-up up to 90 days); Android text share target is `ACTION_SEND text/plain`; iOS is Paste only; raw text is masked then encrypted with a this-device-only key and purged on decision or expiry; staging lives in the main DB; provenance is a new optional synced field (never a new `source` value); fingerprints are per-install HMACs; parsing is on-device, deterministic, no AI; a build without the capability has no SMS permission in the merged manifest (FR-001).

**Deployment context**: migrations 021-024 are live; 025/026 are written but possibly not pushed. Binding order 025 -> 026 -> (v1.1.0, 022) -> 027 -> v1.2.0 (023). Any server change here is migration **027**, after 026. v1.0.1+ apps must keep syncing.

## Decision index

| # | Topic | Decision |
|---|---|---|
| 1 | Inbox access | In-house Kotlin plugin `SmsPlugin`, selection-filtered, keyset-paged query |
| 2 | READ_SMS permission | In-house in the same plugin; no `permission_handler`; restricted-settings inferred in a pure Dart classifier |
| 3 | Capability gate | One Gradle env switch -> READ_SMS manifest overlay (AGP static manifest file if S3 confirms, else manifest-only `:sms_capability` module); capability derived at runtime; CI asserts the merged manifest |
| 4 | Share target | `ShareTargetActivity` trampoline (baseline) carrying the filter, in-process holder read by the plugin; S1 only verifies instance count; always shipped |
| 5 | iOS paste | Nothing native; text field + Paste button via `Clipboard.getData` |
| 6 | Encryption | (a) random 256-bit key in existing secure storage + AES-GCM via `pointycastle`; HMAC via existing `crypto` |
| 7 | Masking | Mask digit groups of 12+ digits except the last 4 before storage; re-parse runs on masked text; fingerprint and reference hash are immutable |
| 8 | Parser | Pure-Dart `data/parsing`, Dart-const `BankProfile` registry, promote `FieldConfidence` to `lib/core` |
| 9 | Persistence | Schema 12 -> 13, 4 local-only tables + 1 settings singleton, nullable `import_source` on both synced tables |
| 10 | Sync | Server whitelists columns and silently drops unknown keys; migration 027 replaces `sync_push` only; pull needs no change |
| 11 | Duplicate lookup | Existing `(date, deleted_at)` indexes suffice; one batched query per scan |
| 12 | Catch-up | Separate `SmsCatchUpTrigger` (NotificationRecomputeTrigger precedent), single-flight, waits for unlock |
| 13 | Localization | `smsImport*` keys, ICU plural/select as in repo, parity test cloned from the AI one |
| 14 | Testing | No Kotlin tests exist: keep Kotlin thin, test logic in Dart behind a gateway fake, manifest check script in CI |
| 15 | Dependencies | One new direct entry (`pointycastle`, already resolved transitively); zero new packages downloaded |

---

## 1. Android SMS inbox access

**Decision**: (a) A small in-house Kotlin plugin, `SmsPlugin` (`android/app/src/main/kotlin/com/daftary/daftary/SmsPlugin.kt`), registered next to `SecurityPlugin` in `MainActivity.configureFlutterEngine`. Dart wraps it behind `domain/services/SmsInboxGateway` (impl `PlatformSmsInboxGateway`, same shape as `PlatformScreenshotProtectionService`). Channel `com.daftary.daftary/sms`.

Method `queryInbox`:
- **In**: `senders: List<String>` (allow-listed minus muted, canonical upper-case, supplied by Dart so rule data lives once), `afterDate: int` (epoch ms), `afterId: int?` (keyset tiebreak), `limit: int` (<= 200).
- **Query**: `Telephony.Sms.Inbox.CONTENT_URI`, projection `_id, address, date, body`; selection `UPPER(address) IN (?,?,...) AND (date > ? OR (date = ? AND _id > ?))`; sort `date ASC, _id ASC`; read at most `limit` rows from the cursor (no SQL `LIMIT`, so no reliance on the `sortOrder` hack and no need for the API 26 `Bundle` query form). minSdk is 24.
- **Out**: `List<Map>` of `{id, address, date, body}` for allow-listed senders only. A page shorter than `limit` means done. Dart keeps the cursor `(date, id)` in the settings singleton (Decision 9).
- Catch-up uses a 24 h overlap before the stored cursor (provider `date` is device receipt time but OEM apps differ); idempotent fingerprints absorb re-reads.
- Errors cross as typed `PlatformException` codes (`permission_denied`, `query_failed`) with no message content; Dart maps to `Failure`.

**Rationale**: FR-020 requires the sender filter inside the query selection, before any body is read. No reviewed package does that (see below). A content-provider query is about 60 lines of Kotlin with no third-party code, no native libraries (so nothing for 16 KB page alignment), and no manifest contributions. It follows the existing precedent exactly (`MainActivity.kt:28`, in-app plugin with method and event channels). Constitution "unjustified new dependencies" (`constitution.md:362`) cuts against a package here.

**Alternatives considered** (pub.dev API and the downloaded archives were inspected):
- `telephony 0.2.0`: discontinued, last release 2022-05-19, Dart <3. Rejected.
- `another_telephony 0.4.1` (2025-04-11): its plugin manifest adds `ACCESS_COARSE_LOCATION` to every merged manifest; its Gradle uses AGP 7.1.3; covers send, call and receive features we must not ship (FR-073, FR-008a). Rejected.
- `flutter_sms_inbox 1.0.5` (2026-05-25): queries with `selection = null` and filters by address in Java **after** reading every body (`SmsQueryHandler.java:64-85`), which violates FR-020 and reads non-bank messages. Its request flow depends on `permission_handler`. Rejected.
- `readsms 0.2.0+4`: manifest declares `RECEIVE_SMS` (forbidden by FR-008a/FR-001), receiver-based design. Rejected.
- Two-phase read (metadata for all rows, bodies by id for matches): never reads non-bank bodies but still reads non-bank metadata and breaks the letter of FR-020. Kept only as **fallback** if the SPIKE below finds `UPPER(address)` rejected.

**SPIKE S2 (device, API 26-36)**: confirm the SMS provider accepts `UPPER(address) IN (...)` in the selection (some providers enable strict grammar). Fallbacks in order: `address COLLATE NOCASE IN (...)`, then `address LIKE ?` per sender joined by OR, then the two-phase read.

**Evidence**: `android/app/src/main/kotlin/com/daftary/daftary/MainActivity.kt:28`; `SecurityPlugin.kt` (method + event channel, `ActivityAware`); `lib/core/security/screenshot_protection_service.dart:40-60` (Dart wrapper, injectable channels); `FlutterExtension.kt:26` (minSdk 24, targetSdk 36 at `:34`); downloaded `another_telephony-0.4.1/android/src/main/AndroidManifest.xml`, `flutter_sms_inbox-1.0.5/.../SmsQueryHandler.java:64-85`, `readsms-0.2.0+4/android/src/main/AndroidManifest.xml`.

---

## 2. READ_SMS runtime permission

**Decision**: Request in-house through `SmsPlugin`; do **not** add `permission_handler`.

Plugin methods:
- `getPermissionState()` -> `{granted: bool, shouldShowRationale: bool}` (no prompt; used on resume for FR-070 revocation detection).
- `requestPermission()` -> `{granted, shouldShowRationale, dialogShown, sdkInt, installSource}`. Implementation: `ActivityCompat.requestPermissions(activity, [READ_SMS], 0x5A11)` (below 16 bits for `FragmentActivity`); result via `binding.addRequestPermissionsResultListener`. `dialogShown` is true when the activity received `onPause` between the request and the result (the system dialog is a separate translucent activity); recorded through the `ActivityPluginBinding` lifecycle.
- `installSource` from `PackageManager.getInstallSourceInfo` (API 30+): `packageSource` on API 33+ (`PACKAGE_SOURCE_STORE` = store; `DOWNLOADED_FILE`, `LOCAL_FILE`, `OTHER` = not a store), otherwise `installingPackageName` against a small store list (`com.android.vending`, Samsung, Huawei, Xiaomi stores). Below API 30 the field is `unknown`.

A **pure Dart** classifier `classifySmsPermission(result, previouslyRequested)` (domain, unit-tested) yields `granted | denied | permanentlyDenied | restrictedBlocked | revoked`:
- granted -> `granted`;
- denied and `dialogShown` is false and `sdkInt >= 35` and install source is not a store -> `restrictedBlocked` (inferred; no public API reports it);
- denied, `shouldShowRationale` false, and the app had requested before (flag in settings singleton, written at request time) -> `permanentlyDenied`;
- otherwise `denied` (can ask again, once, never silently: FR-012).

**App Lock**: wrap `requestPermission()` in `AppLifecycleObserver.runExternalActivity` (its future completes when the result arrives, like the picker precedent). The permission dialog normally only produces `AppLifecycleState.inactive`, which the observer already ignores (`app_lifecycle_observer.dart:103-107`), so the wrapper is a cheap defense against OEM full-screen permission activities. **Do not** wrap the App-info deep link: `runExternalActivity` ends when its future completes, and a fire-and-forget `startActivity` completes immediately, so it would suppress nothing. Leaving the app to App info is a real backgrounding and the user's lock timeout correctly applies.

**Deep link**: reuse the existing `app_settings` package: `AppSettings.openAppSettings()` (default type opens the app's details screen on Android). No native code.

**Rationale**: `permission_handler` (13.0.2) is a heavy multi-platform dependency (all permission groups, iOS pod macros, build flags per permission) for one Android permission, and it adds nothing for the restricted-settings inference that the app has to do itself. The notification precedent keeps permission logic in a use case behind a service interface (`request_notification_permission.dart`: `call()` prompts, `refresh()` is prompt-free); `RequestSmsPermission` mirrors it.

**Alternatives considered**: `permission_handler` (rejected: dependency weight, and its `permanentlyDenied` is exactly the flag we still must reinterpret for restricted settings); elapsed-time-only heuristic for "no dialog" (rejected as the sole signal: fragile on slow devices; kept only as a secondary tiebreak). Restricted-settings behavior varies by OS version and OEM; correctness is a release gate (OQ6/FR-003), verified on real devices.

**Evidence**: `lib/features/insights_notifications/domain/usecases/request_notification_permission.dart:19-45`; `lib/core/security/app_lifecycle_observer.dart:87-93,103-107`; `lib/core/media/attachment_picker_service_impl.dart:55` (`runExternalActivity` wraps an awaited result); `pubspec.yaml:58` + `notification_settings_page.dart:27` (`app_settings`); `pubspec.lock` has no `permission_handler`.

---

## 3. Capability gating (FR-001)

**Decision**: One environment variable, `DAFTARY_SMS_IMPORT=true`, read by Gradle only (no Dart const, no `--dart-define`; review B10).

1. **Gradle** (S3 first checks whether AGP 8.11 `androidComponents.onVariants { it.sources.manifests.addStaticManifestFile(...) }` works: then one overlay file `android/app/sms_capability/AndroidManifest.xml` and no module, no hard-coded `compileSdk`; the module below is the fallback): `android/settings.gradle.kts` always includes a manifest-only library module `:sms_capability` (`android/sms_capability/{build.gradle.kts,src/main/AndroidManifest.xml}`; manifest = `<uses-permission android:name="android.permission.READ_SMS"/>`). `android/app/build.gradle.kts` adds `implementation(project(":sms_capability"))` only when `providers.environmentVariable("DAFTARY_SMS_IMPORT").orNull == "true"` (a `-Pdaftary.smsImport=true` fallback for IDE users; provider-based so it is configuration-cache safe). The main manifest never mentions READ_SMS.
2. **Dart**: no const. `SmsCapability.available = readSmsDeclared && Platform.isAndroid`, where `getCapabilities()` in `SmsPlugin` reads `PackageInfo.requestedPermissions`. With one switch, a READ_SMS-shipped-but-feature-dark mismatch (which `aapt` cannot detect) cannot exist. Share-text availability is `Platform.isAndroid` only, independent of the capability.
3. **Never-wanted permissions**: the main manifest carries `tools:node="remove"` markers for `RECEIVE_SMS, SEND_SMS, RECEIVE_MMS, RECEIVE_WAP_PUSH, WRITE_SMS, READ_PHONE_STATE`, so no future dependency can add them (FR-008a, FR-073). READ_SMS has no remove marker in main (it would also strip the library's declaration); its absence in the off state is guaranteed by the CI assertion instead.
4. **CI**: `release-android.yml` sets job-level `env: DAFTARY_SMS_IMPORT: "true"` for both `flutter build apk` calls (universal and split-per-abi, `:97,:106`); a following step runs `aapt dump permissions` on both APKs and fails unless READ_SMS is present and RECEIVE_SMS/SEND_SMS/READ_PHONE_STATE are absent. `ci.yml` gains an `android-manifest` job (Ubuntu runner has the Android SDK; `flutter pub get` writes `local.properties`) running `tool/check_merged_manifest.sh`, which executes `./gradlew :app:processReleaseMainManifest` twice (env unset, env set) and greps `app/build/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml` (path re-verified at implementation): unset -> no `READ_SMS` and no `android.permission.*SMS*` at all; set -> exactly READ_SMS; both -> no `<receiver>` whose filter contains `SMS_RECEIVED` or `WAP_PUSH`, and the `SEND text/plain` filter present (FR-011, always).
5. Default is **off**, so a plain `flutter run` / `flutter test` / CI build is SMS-free; a developer enables it with `export DAFTARY_SMS_IMPORT=true`.

**Rationale**: It is the smallest mechanism that changes the merged manifest without touching how the app is built, run or signed, and it keeps the iOS and macOS pipelines unaware of the switch. A library manifest is merged by AGP's standard dependency merge, so "includes permissions contributed by dependencies" is checkable in one place.

**Alternatives considered**:
- Gradle **product flavors** (`standard`/`sms`): the conventional tool, rejected here. `flutter build apk` then needs `--flavor` (or `default-flavor`, which Flutter also applies to iOS and then expects a matching Xcode scheme), output file names change (`app-sms-release.apk`), and every IDE run config, the arm64/universal copy steps and the integration-test commands change. Large blast radius for a one-permission switch.
- **Build-type source-set manifest overlay** chosen by property: `debug` and `profile` already own `src/<type>/AndroidManifest.xml` (INTERNET), so replacing the file path would drop their content unless duplicated.
- **Manifest placeholder in `tools:node`** or in the permission name: placeholders are resolved after merge, so a `tools:node="${x}"` is unreliable, and a placeholder permission name would leave a bogus declaration in the off build.
- Runtime-only gating (no manifest change): violates FR-001 outright.

**Open point**: only the fallback `:sms_capability` module needs a `compileSdk` (hardcode 36 to match `FlutterExtension`, or read it from `rootProject.extra`) because the `flutter` extension exists only in the app module; the AGP static-manifest overlay avoids it.

**Evidence**: `android/app/build.gradle.kts:1-90` (single app module, no flavors, `flutter.minSdkVersion` etc.); `android/app/src/main/AndroidManifest.xml:1-35` (permissions are all in main); `android/app/src/debug/AndroidManifest.xml` (INTERNET); `lib/core/config/feature_flags.dart:9-14`; `.github/workflows/release-android.yml:94-114`; `.github/workflows/ci.yml:35`.

---

## 4. Android share target

**Decision**: A dedicated `ShareTargetActivity` (translucent, `noHistory`, `excludeFromRecents`) carries the filter in `AndroidManifest.xml` (always, in every build; sharing needs no permission and FR-011 puts paste/share in every build). `MainActivity` and its `singleTop` launch mode are untouched.

```xml
<activity android:name=".ShareTargetActivity" android:exported="true" android:noHistory="true"
          android:excludeFromRecents="true" android:theme="@style/Theme.Translucent">
  <intent-filter>
    <action android:name="android.intent.action.SEND"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <data android:mimeType="text/plain"/>
  </intent-filter>
</activity>
```

- **Flow**: `ShareTargetActivity.onCreate` reads `EXTRA_TEXT` (as `CharSequence`), puts it into an in-process `SharedTextHolder` read by `SmsPlugin` (never an Intent extra), starts `MainActivity` with `NEW_TASK | CLEAR_TOP | SINGLE_TOP` (the flags the launcher uses) and calls `finish()`.
- **Cold start**: `getInitialSharedText()` drains the holder and returns the text **once**, clearing it (the text comes from the holder, not `activity.intent`), so recreation or process restore cannot replay it.
- **Warm**: the holder pushes to the `EventChannel` (`com.daftary.daftary/sms/shared_text`) when a listener exists, else buffers one pending event.
- Truncated at 10,001 characters with a `truncated` flag (FR-017 bound); the 50-message bound is enforced by the splitter in Dart. Nothing is logged; the text is not placed in any Intent extra, route URL or restoration state.
- **Dart**: `SharedTextRouter` (precedent `NotificationTapRouter.start(router)`, started in the same `startup.whenReady` block in `main.dart:50`). It holds the text in an in-memory `SharedTextInbox`, waits for `AppLifecycleObserver.isLocked` to be false, then `router.go('/bank-messages/paste')`; the Paste screen's cubit consumes the inbox. No text in the URL. `AppLockGate` keeps the routed child mounted but offstage while locked; deferring the parse until unlock keeps the text only in memory until then (FR-016a, FR-079).
- Not-recognized shares store nothing (FR-018); the same pipeline parses paste and share.

**Why the trampoline is the baseline (review A4)**: `MainActivity` is `singleTop` with `taskAffinity=""` (`AndroidManifest.xml:38-39`), so a share from Google Messages can create a second `MainActivity` and a second `FlutterEngine`. That does **not** bypass App Lock (`main()` runs again and `AppLifecycleObserver.initialize()` locks at cold launch, `:68-70`). The real hazards are two isolates with two Drift connections on one SQLite file (stream invalidation does not cross isolates, writes can hit "database is locked"), duplicate `SyncScheduler` and notification triggers, and a Daftary screen opening inside the Messages task. The trampoline avoids all three and leaves notification taps without regression risk.

**SPIKE S1 (device)**: with the app in the background, share from Messages and count activities (`adb shell dumpsys activity activities`); expect exactly one `MainActivity`. Alternative `launchMode="singleTask"` is rejected (notification-tap and cold-start regression risk).

**Rationale**: Precedent for external entry plus lock-aware routing already exists; the plugin and trampoline keep all share handling in two small Kotlin files and leave `MainActivity`'s launch mode unchanged.

**Alternatives considered**: `receive_sharing_intent` / `share_handler` packages (more surface and manifest edits than the 40 lines needed; extra permission/data-type handling we do not want); gating the filter by capability (rejected: no permission involved); `ACTION_PROCESS_TEXT` (a different UX; the existing `<queries>` entry is unrelated).

**Evidence**: `AndroidManifest.xml:30-47,86-92`; `lib/core/routing/notification_tap_router.dart:28-45` (start/`launchTarget` for cold start, stream for warm); `lib/main.dart:50-58`; `lib/core/security/app_lock_gate.dart:11-20` (child offstage while locked); `app_lifecycle_observer.dart:74-77` (cold launch locks).

---

## 5. iOS paste

**Decision**: Nothing native. The Paste screen has (a) a multi-line editable `TextField` (system edit-menu paste, which shows no iOS paste prompt) and (b) a Paste button that calls `Clipboard.getData(Clipboard.kTextPlain)` only inside its `onPressed`. Null, empty or non-text -> the "nothing to paste" state pointing to the text field. No read in `initState`, route push, `didChangeAppLifecycleState` or a focus listener; a widget test asserts the mocked `flutter/platform` channel receives no `Clipboard.getData` call until the tap (US4-2). `UIPasteControl` (a platform view) is rejected as over-engineering, as the clarify review noted.

**Rationale**: `Clipboard.getData` on iOS 16+ may show the "Allow Paste" prompt or return empty when the user has denied paste; both are covered by the specified UI states. `SecurityPlugin.swift` and `Info.plist` stay untouched; the Runner gets no new files, entitlements or App Group (NG11).

**Alternatives considered**: clipboard polling or reading on resume (violates FR-015, triggers prompts); `UIPasteControl` (platform view and Swift); a Share extension (NG11).

**Evidence**: `ios/Runner/SecurityPlugin.swift` is the only native Swift file; spec FR-015, US4.

---

## 6. Raw-text encryption and keyed hashing

**Decision**: (a) A random 256-bit key held in the existing `FlutterSecureStorage`, with AES-256-GCM done in Dart by `pointycastle` (`GCMBlockCipher(AESEngine())`). Behind `domain/services/RawTextVault` (`seal(plain, aad) -> Uint8List`, `open(blob, aad) -> String?`; `null` means unreadable) with impl `AesGcmRawTextVault`; a second interface `FingerprintHasher` (impl `HmacFingerprintHasher`) uses the already-direct `crypto` package: `Hmac(sha256, key).convert(bytes)`.

- **Keys**: two independent random 32-byte keys, `sms_import.enc_key.v1` and `sms_import.mac_key.v1`, base64 in the same secure storage the app already uses, each generated lazily by a single-flight `SmsKeyStore` (mutex, write then read-back verify). Reuse the existing singleton; add no options. Existing options: iOS `first_unlock_this_device` (not migrated to another device; excluded from restore onto a new device); Android default `AndroidOptions()` = RSA-OAEP-wrapped AES-GCM, the wrapping RSA key in the Android Keystore, ciphertext in a SharedPreferences file.
- **Stored format** (BLOB column `raw_blob`): `0x01 (format version) | nonce(12, Random.secure) | ciphertext | tag(16)`. AAD = pending-import id (UTF-8), which binds a blob to its row so a copied blob never opens under another id. Fresh random nonce per seal; with one key and at most thousands of items the collision risk is negligible.
- **Key loss**: any exception or `null` from secure storage, or a GCM tag failure, means the text is **purged**: `open` returns `null`, the row's `raw_blob` is set to `NULL` the first time the failure is seen, and "Show original" is unavailable (FR-074a, FR-045). Failures are never logged with content. Losing the MAC key means old tombstones stop matching (accepted, FR-062); the new key is generated on next use. Both keys are deleted by Delete-all-data through a `PurgeSmsImportKeys` use case beside `PurgeAIAssistantCredentials`.
- **After an Android Auto Backup restore** (manifest has no `allowBackup`/rules, so the default is on): the secure-storage preferences file is restored but the Keystore RSA key is not. flutter_secure_storage 11 then throws on read and, with its default `resetOnError: true`, wipes all its entries. Our keys vanish, so raw blobs are unreadable and tombstones stop matching, which is the specified outcome. This also resets the existing cloud session, PIN hash and AI key on a restore: pre-existing behavior, noted in Spec feedback, not changed here.
- **HMAC inputs**: fingerprint = `HMAC(macKey, "fp1|" + FingerprintNormalizer.v1(body))` (a frozen normalizer, independent of the parser's matching normalization, see Decision 8 and analysis H1; a fee split from its message uses the prefix `fp1|fee|`); `ref_hash = HMAC(macKey, "ref|"+bank+"|"+referenceId)`; `ref_amount_hash = HMAC(macKey, "ra|"+bank+"|"+ref+"|"+currency+"|"+amountMinor+"|"+direction)` (Decision 9 explains why both).

**Rationale**: Pure Dart is unit-testable with fixed keys and nonces, identical on Android, iOS and the macOS runner, and adds no Swift or Kotlin (the repo has no native test harness, Decision 14). The AES key is protected the same way the PIN hash, cloud session and AI key already are (constitution XII precedent); the spec's key protection (FR-074a, reworded in review A2) is met as: random per-install key, wrapped on Android by a non-exportable Keystore RSA key, and on iOS held as a this-device-only Keychain item, so no backup restores a usable key. The existing secure-storage singleton uses `resetOnError: true`, where any read failure wipes every entry (cloud session, PIN hash, AI key). The SMS keys therefore live in a **dedicated `FlutterSecureStorage` instance** with the same platform options but `resetOnError: false`, so an SMS key error maps to "key lost" and never touches other entries (analysis M7). `SmsKeyStore` caches keys per process to minimize reads. `pointycastle 4.0.0` is already resolved in `pubspec.lock` (via `dart_jsonwebtoken` <- `gotrue` <- `supabase_flutter`); importing a transitive package needs a direct pubspec entry (`depend_on_referenced_packages`), but no new package is downloaded. Cost is trivial: raw text is a few hundred bytes per recognized item.

**Alternatives considered**:
- (b) Native Keystore AES-GCM (Kotlin) and CryptoKit (Swift): non-exportable hardware-backed keys, a stronger root-attacker story; rejected because it needs new Swift in the Xcode project, a second implementation for macOS, native tests that do not exist, and a method-channel hop per item. A rooted or jailbroken device defeats either option for an app-sandbox secret.
- `cryptography` 2.9.0 (clean API): not in `pubspec.lock`, so a genuinely new package. `encrypt` 5.0.3: new package over pointycastle. Both rejected as unjustified dependencies.
- Encrypting the whole DB (SQLCipher): out of scope; spec accepts an unencrypted DB (Risks).

**Evidence**: `lib/core/di/register_module.dart:96-100` (secure storage, `first_unlock_this_device`); `pubspec.yaml:107` (`crypto: ^3.0.7`, comment "HMAC-SHA256 ... PinHasher"); `pubspec.lock:1159-1165` (pointycastle 4.0.0, transitive), `:300` (dart_jsonwebtoken); `flutter_secure_storage-11.2.0/README.md:124-137,150-157` (backup exception, default cipher table), `lib/options/android_options.dart:51` (`resetOnError = true`); `lib/features/ai_assistant/domain/usecases/purge_ai_assistant_credentials.dart:14`; `AndroidManifest.xml:30` (no backup attributes).

---

## 7. Masking rules (FR-031a) and re-parse (FR-026)

**Decision**: `SmsMasker` (pure, domain) runs on the **original** message text (not the digit-normalized copy) before it is sealed, so "Show original" keeps the message's own characters and direction.

- **A digit group** is a run of ASCII or Arabic-Indic or Eastern Arabic-Indic digits (`0-9`, `U+0660-0669`, `U+06F0-06F9`), optionally separated by single spaces or hyphens between groups of digits (card and account formatting like `1234 5678 9012 3456`). Commas and periods are **not** separators, so grouped amounts such as `1,234,567.50` are never grouped into a long run.
- If a group holds **12 or more digits**, replace every digit except the last four with `•` and keep separators (`•••• •••• •••• 3456`). Threshold default 12; a `BankProfile` may set a stricter (lower) value, never a higher one.
- Already-masked patterns (`XXXX1234`, `****1234`, `...1234`) are left as they are: they hold at most four real digits.
- Egyptian mobile numbers are 11 digits and fall under the 12 threshold, so a rule masks `(\+?20|0)1[0125]\d{8}` all but the last four. It runs on a digit-normalized shadow copy of the original with an index map (a raw-text regex would miss Arabic-Indic digits and `010 1234 5678`) and allows single-space or hyphen separators. Space-joining can merge an amount with a neighbouring number (`EGP 1500 01012345678` becomes one 15-digit group and the amount is masked), so masker tests cover amount-adjacent runs and re-parse treats a masked amount as unreadable rather than a different value. Reference IDs are rarely mobile-shaped and their hash is taken before masking.

**Can re-parse work on masked text?** Yes, with two invariants. Everything re-parse needs (amount, currency, direction, kind keywords, date, time, merchant, counterparty, last four of the card) sits outside 12+ digit groups or is preserved by the "last four" rule. What masking destroys is a long reference ID or account number. Therefore:
1. `fingerprint`, `ref_hash` and `ref_amount_hash` are computed once, at first parse, from the unmasked normalized body, stored on the row, and **never recomputed** by re-parse.
2. A re-parse that extracts a reference containing `•` keeps the stored hashes; one that extracts a fully-visible reference (< 12 digits) recomputes nothing either, since the hash exists. `received_at`, `source`, `created_at` are likewise immutable.
3. Items whose blob cannot be opened keep their parsed fields (FR-026). Re-parse results replace only the parsed-field columns and `rule_version`, in one transaction per item, and a re-parse is skipped if the user has edits in an open review (the review cubit holds the draft).

**Rationale**: This matches FR-031a's goal (nothing that identifies a full account or card is ever persisted, FR-031, FR-077) while keeping FR-026 workable. The spec text "keeps reference IDs for re-parse" is true only for IDs under 12 digits; the stored hash is what actually serves duplicate detection (Spec feedback).

**Alternatives considered**: masking only recognized card/account tokens by rule set (misses unrecognized formats; rejected as unsafe default); masking every digit run of 8+ (destroys short reference IDs and, worse, amounts like `12345678` with no separators); storing the unmasked text (forbidden by FR-031a).

**Evidence**: `lib/core/money/numeral_parser.dart:8` (only `U+0660-0669` handled); spec FR-031, FR-031a, FR-026, FR-045.

---

## 8. Parser architecture

**Decision**: A new feature `lib/features/sms_import/` with the OCR layout. The parser is a pure-Dart service in `data/parsing/` (no Flutter, no `dart:io`), exercised from a fixture table exactly like `CandidateEntryParser`.

- **Registry** `SmsParserRegistry`: an **ordered const list** of `BankProfile` Dart objects, one file per bank under `data/parsing/profiles/` (`nbe_profile.dart`, ...), plus `generic_profile.dart`. A profile holds `id`, `version` (int), `senders` (normalized sender IDs, the per-bank allow-list), `signatures` (content patterns), `templates` (`SmsTemplate{kind, direction, RegExp with named groups amount/currency/date/time/merchant/last4/ref/balance/fee}`), `merchantKeywordRules`, `maskThreshold`, `defaultCurrency`, `dateOrder`. Regexes are compiled once (`static final`). **Not JSON assets**: rule updates ship with the app anyway (remote rules are out of scope, Assumptions), Dart gives compile-time checking and no async asset load or schema validation, and `pubspec.yaml` asset directories are non-recursive (`pubspec.yaml:150-156`), so each new asset folder would need listing. The data that *is* data (synthetic corpus) lives in fixtures (Decision 14).
- **Allow-list** = union of `senders` across profiles, minus the user's mutes (`SmsSenderMutes`), handed to the Kotlin query (Decision 1). Matching is on the normalized sender (case-insensitive, trimmed, no spaces). Paste and share have no sender: profile selection by `signatures` alone (FR-020, FR-028).
- **Versioning**: each profile has `version`; `parser_id = "<profileId>"` and `rule_version = "<profileId>@<n>"` are stored on the pending row (FR-032). `SmsParserRegistry.currentVersions` is compared with stored values when the pending list opens and after an app update; a mismatch queues the re-parse (Decision 7). Corpus tests pin the versions so a rule edit without a bump fails.
- **Precedence** (FR-028) is a pure function `selectParse(text, sender)`: (1) profiles whose `senders` match and whose `signatures` match; (2) no sender (paste/share): profiles whose `signatures` match; (3) generic. Several matches -> highest overall confidence, then registry order; **no field-level merging**. A corpus test asserts no supported bank's samples match another bank's signatures.
- **Normalization pipeline** (`SmsTextNormalizer`, pure): (1) strip bidi controls (`U+200E/F`, `U+061C`, `U+202A-202E`, `U+2066-2069`) and zero-width characters; (2) collapse whitespace; (3) **extend `NumeralParser.toWesternDigits` to cover Eastern Arabic-Indic `U+06F0-06F9`** (FR-034 names them; today only `U+0660-0669` are handled, `numeral_parser.dart:8`), keeping its separator mapping (`٫` -> `.`, `٬` -> `,`); (4) Arabic letter folding for **matching only** (strip tatweel `U+0640` and harakat `U+064B-065F`, fold alef forms `أإآٱ` -> `ا`, `ى` -> `ي`, `ة` -> `ه`, and `ؤ/ئ` conservatively), implemented in `sms_import` until a second feature needs it (constitution II; the repo has no Arabic normalizer, `normalizedName` is lower-casing only); (5) lower-case Latin. The folded text is used for rule matching **only**. The **fingerprint** uses a separate, frozen `FingerprintNormalizer` v1 (steps 1-3 only: bidi and zero-width removal, whitespace collapse, digit normalization; no folding or lower-casing), so parser, folding or rule updates never change a fingerprint and tombstones keep matching across app updates (analysis H1). Merchant display text is taken from the digit-normalized, unfolded text.
- **Amounts**: capture with `\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?`, strip commas, then `CurrencyFormatter(currency: ..., locale: 'en').parse(captured)` (`currency_formatter.dart:67`) for exact minor units; it throws `FormatException` for more than 2 decimals or more than 12 whole digits (`maxWholeDigits`, `:24`), which becomes "amount unreadable" (FR-039a), never a clamped value. Currency words map to ISO codes in a const table (EGP, LE, L.E., جنيه, ج.م, USD, $, ...); a three-letter code outside the catalog (`currency.dart`: EGP, USD, EUR, SAR, AED, GBP) yields the FR-053 "choose a currency and re-enter" state. The balance group is never a candidate.
- **Dates**: regex plus manual `DateTime(y, m, d)` with a round-trip validity check (the `SyncWire.parseLocalDay` idiom, `sync_mapper_registry.dart:141`); no `intl` parsing (locale-dependent). Month names: const normalized table, English (full and 3-letter) and Arabic in both Egyptian (`يناير فبراير مارس ابريل مايو يونيو يوليو اغسطس سبتمبر اكتوبر نوفمبر ديسمبر`) and Levantine (`كانون الثاني شباط اذار نيسان ايار حزيران تموز اب ايلول تشرين الاول تشرين الثاني كانون الاول`) spellings, keyed after alef folding. Two-digit years -> `2000 + yy`. **Year inference** (FR-036): year of the received timestamp, minus one if that date would be after it; paste/share use the current year via the injected `AppClock` (`core/date/app_clock.dart`); always `FieldConfidence.inferred()`. Day-month order is a profile field; the generic profile assumes day-month.
- **Confidence**: reuse the OCR model. It is shared by two features, so per constitution II **promote** `FieldConfidence`, `FieldConfidenceKind`, `FieldConfidenceLevel` to `lib/core/confidence/field_confidence.dart` (a `git mv` plus import updates in the 8 lib and 10 test importers; no behavior change, existing `field_confidence` tests move with it) and the stateless `ConfidenceIndicator` widget to `lib/core/design_system/`. Per the clarify review the model stays as is: *inferred always has level `none`*, so the spec's rule "overall = lowest read level among required read fields; any inferred required field caps at Medium; generic and paste/share cap at Medium" is a small pure function `overallConfidence(fields, {capMedium})` in `sms_import/domain`, with calibration tests (FR-039-042).

**Rationale**: Mirrors the shipped OCR precedent (pure parser behind an injectable class, fixture-table tests, provenance recorded per field), keeps every rule diff-reviewable and testable without a device, and makes SC-001's per-bank accuracy gate a plain `flutter test`.

**Alternatives considered**: JSON/YAML rule files (above); a Dart `package:petitparser` grammar (new dependency, heavier than regex templates for single-line SMS); sharing the OCR parser (different input model); duplicating `FieldConfidence` into the new feature (rejected: two divergent copies of the same read-vs-inferred contract).

**Evidence**: `lib/features/ocr/data/parsing/candidate_entry_parser.dart:7-24` (pure, injectable, "Pure Dart by construction"); `test/features/ocr/data/parsing/candidate_entry_parser_test.dart` (fixture table); `lib/features/ocr/domain/entities/field_confidence.dart:7-60`; `lib/core/money/currency_formatter.dart:24,67-110`; `lib/core/money/numeral_parser.dart:8-28`; `lib/core/date/app_clock.dart:6`; importers of `field_confidence`: 8 lib files (`ocr_repository_impl.dart`, `candidate_entry_parser.dart`, `text_recognition_service*.dart`, `candidate_entry*.dart`, `confidence_indicator.dart`, `candidate_entry_card.dart`) + 10 tests; `.specify/memory/constitution.md:46-52`.

---

## 9. Persistence (Drift schema 12 -> 13)

**Decision**: `AppDatabase.schemaVersion` 12 -> 13 with one additive step, `migrateToSmsImport(db, m)` in `lib/core/database/migrations/v13_sms_import.dart`, called under `if (from < 13)` after the v12 block. One `db.transaction`, every object guarded, no existing row read or rewritten. Reuse `ensureTable` and `ensureIndex` from `migration_guards.dart`; **add `ensureColumn(db, m, table, column)`** to the same file (PRAGMA `table_info` check, lifted from the inline copy in `v12_finance_entry_audits.dart`, which also keeps its own private `_exists`; leave v12 alone).

**New tables, all local-only** (add the five names to `localOnlyTables`, `delete(...)` them in `DataWipe.deleteAllUserData`, list them in `@DriftDatabase(tables: [...])`):

| Table (class) | Key columns | Indexes |
|---|---|---|
| `pending_sms_imports` (`PendingSmsImports`) | `id` uuid pk; `fingerprint` (HMAC hex); `status` pending/added/ignored/duplicate/expired; `origin` scan/catchup/paste/share; `sender_id`; `bank_id`; `parser_id`; `rule_version`; parsed fields (`amount_minor_units`, `currency_code`, `direction`/`entry_type`, `txn_kind`, `occurred_on`, `time_minutes`, `merchant`, `counterparty`, `card_last4`, `suggested_category_id`, `suggested_person_id`, `suggested_action`); `confidence_json` (per-field kind and level); `warnings_json`; `ref_hash`; `ref_amount_hash`; `received_at`; `created_at`; `expires_at`; `decided_at`; `saved_record_id`; `raw_blob` BLOB null | unique `(fingerprint)`; `(status, expires_at)`; `(ref_hash)`; `(amount_minor_units, currency_code, status)` for the 10-minute pending-pair rule |
| `sms_import_tombstones` (`SmsImportTombstones`) | `fingerprint` pk; `outcome` added/ignored/duplicate/expired; `bank_id`; `ref_hash`; `ref_amount_hash`; `saved_record_id`; `saved_record_type`; `created_at`; `purge_after` (>= created + 97 days) | `(ref_hash)`; `(ref_amount_hash)`; `(saved_record_id)`; `(purge_after)` |
| `sms_sender_mutes` | `sender_id` pk; `created_at` | none |
| `sms_merchant_category_mappings` | `merchant_key` + `entry_type` composite pk; `category_id` (plain text, **no FK**, like `ocr_scan_id`, so a category delete is never blocked); `updated_at` | none |
| `sms_import_settings` (singleton, `id = 'singleton'`) | `is_enabled`; `onboarding_dismissed`; `scan_window_days` (30); `cursor_date`, `cursor_id`; `last_scan_at`; `last_catchup_at`; `count_cash_withdrawals`; `permission_requested`; counters `scanned/recognized/added/ignored` (FR-102); `rules_seen` | none |

- **Why a new singleton, not `app_settings`**: `AppSettings` is language/theme/glass for the settings feature; widening it couples the SMS feature into `SettingsCubit` and its mapper tests. `NotificationPreferences` is the precedent for a per-feature singleton (`app_database.dart:549-553`).
- **Why two reference hashes on tombstones** (spec gap, FR-059b): tier 2 needs same bank + reference + **amount + direction**, tier 3 needs "both reference IDs present and different"; tombstones must hold no content. `ref_hash = HMAC(bank|ref)` serves tier 3, `ref_amount_hash = HMAC(bank|ref|currency|amount|direction)` serves tier 2; no plain amount is stored on a tombstone. The Undo list (30 days) reads the decided `pending_sms_imports` row, whose `raw_blob` is nulled on decision; a purge pass deletes decided rows after 30 days and tombstones after `purge_after`.
- **Atomic Add (FR-075a)**: `SmsImportRepositoryImpl.confirm` runs one `_db.transaction`: re-read the pending row and require `status == 'pending'`, call `TransactionsRepository.addSmsSourcedTransaction` or `FinanceRepository.addSmsSourcedEntry` (new methods modeled on `addOcrSourcedTransaction`, documented "only the SMS repository calls this"), write the tombstone, mark the row added with `saved_record_id`. Idempotency key `sms-import:<pendingId>` for both tables; the status guard inside the same transaction covers a retry after a type switch. A `Left` from an inner repository throws a private `_ConfirmAborted(failure)` so the whole transaction rolls back, exactly the `_BatchAborted` idiom in the OCR confirm.

**Provenance columns**: `import_source TEXT NULL` on `money_transactions` and `finance_entries` (`MoneyTransactions.importSource`, `FinanceEntries.importSource`), no default, **no index** (read per row for the label; duplicate reasoning goes through `tombstones.saved_record_id`). Existing rows stay `NULL` (= not SMS, FR-057). The local column stores the raw wire string; the domain exposes `ImportSource? importSource` (`sms`; any other string maps to `unknown`, kept and round-tripped). `TransactionSource` (`manual`, `ocr`) is untouched and SMS-imported people-ledger rows keep `source = 'manual'` (FR-086).

**Export**: excluded (FR-076). `ExportUserData` composes five repositories explicitly (`export_user_data.dart:53`), so no new table reaches the CSV; add a regression test that fails if its constructor gains an SMS dependency or a CSV header carries provenance. No new CSV column in v1.

**Tests**: `test/core/database/v13_migration_test.dart` upgrades the committed v11 fixture through 12 to 13 (pattern of `v12_migration_test.dart`), asserts no existing row changed, new columns null, new tables empty, re-open is idempotent; change `v12_migration_test.dart:40`-style `schemaVersion` assertions to 13; update `table_classification_guard_test.dart:157` (exact set) and rely on `data_wipe_test.dart` iterating `allTables` (`:36,:43,:356`).

**Alternatives considered**: a second database file (rejected earlier by the clarify review: breaks atomic Add, doubles migrations and wipe); storing parsed fields JSON in one column (rejected: duplicate-lookup and pair rule need indexed columns); adding a `reference` column on saved records (rejected: FR-088).

**Evidence**: `app_database.dart:756` (`schemaVersion => 12`), `:829-833` (v12 guard), `:708-736` (table list); `migrations/migration_guards.dart:1-30`; `migrations/v12_finance_entry_audits.dart:14-35`; `sync_entity_type.dart:55-76`; `data_wipe.dart:23-72`; `table_classification_guard_test.dart:157-175`; `transactions_repository_impl.dart:545-571`; `ocr_repository_impl.dart:425-495,694`.

---

## 10. Sync of provenance (migration 027)

**How the server handles columns today** (026, latest): `sync_push` is a **whitelist**. Each entity branch sets `v_business` (money_transaction `:185-186`, finance_entry `:195-196`); the writable set is `v_business` + client stamps, and `v_cols` is the writable columns **present in the payload** (`:283-286`). Inserts and updates then copy only `v_cols` through `jsonb_populate_record`. So an **unknown payload key is silently ignored** (no error, not stored), and on update a column missing from the payload is **left unchanged**. `sync_pull`/`sync_pull_v2` return `to_jsonb(t)` for each table (`:497,512,623,638`), so any new column is returned automatically.

**Migration 027** (`20261006..._027_import_source.sql`, additive, after 026; applied migrations are never edited):
1. `alter table public.money_transactions add column import_source text check (import_source in ('sms'));` and the same for `public.finance_entries`. Nullable, no default, no backfill, no index; table-level grants already cover new columns (021 grants at table level).
2. `create or replace function public.sync_push(...)` = **026's body verbatim** plus `'import_source'` appended to the two `v_business` arrays. Nothing else changes (no policy, ledger or version gating).
3. `sync_pull`, `sync_pull_v2`: **no change** (they already emit the column). Restating them is unnecessary and would only enlarge the diff.
4. A comment line on `sync_push` naming 027.
Server tests: pgTAP `supabase/tests/027_import_source.test.sql` (pattern of `021_rls.test.sql`): (a) upsert with `import_source: 'sms'` persists on both tables; (b) a **v1.0.1-shaped** update payload without the key leaves the column intact; (c) existing rows read `null`; (d) the check rejects `'x'`; (e) pull output contains the key.

**Old clients**: the v1.0.1 mappers read named keys only (`SyncWire.string`, `oneOf`, ... by field name; `money_transaction_sync_mapper.dart:50-85`, `finance_entry_sync_mapper.dart:36-60`), so an extra key in a pulled row is ignored. **Test**: `test/core/sync/legacy/v101_mappers.dart` is a frozen verbatim copy of the two v1.0.1 `fromWire` bodies (from commit `c86e2df`); `v101_pull_compat_test.dart` feeds a post-027 `to_jsonb`-shaped JSON (with `import_source: 'sms'` and an invented future key) and asserts no throw and identical business values. Also a 1.1 two-device test on the existing `SyncHarness`/`FakeSyncRemote` (`sync_log_scrub_test.dart` shows the harness): device A saves an SMS-sourced row, B pulls it and shows provenance, a legacy-shaped edit-and-push leaves the field intact on the fake server.

**1.2 mappers**: `toWire` adds `'import_source'` **only when non-null** (keeps the existing exact-shape tests valid and never sends `null` over a set value); `fromWire` sets `importSource: Value((json['import_source'] as String?) ?? existingLocal?.importSource)`, so a non-null local value is never downgraded to null whether the key is absent or present-but-null (`sync_applier.dart:154` passes `existingLocal`; review B2). Unknown strings are stored as-is.

**Deployment order** (binding): **025 -> 026 -> 027 -> app that writes provenance**. 027 depends on nothing in 025/026 beyond the function text it replaces, so push all three in one `db push` and ship the app afterwards. Add 027 to `quickstart.md` and the release checklist.

**If the app ships before 027**: pushes do **not** fail. The extra key is silently dropped by the server, so the record syncs without provenance (it stays on the local device). The duplicate warning loses only the "same bank, different reference" nuance for such rows on other devices, and the label does not appear there. Consequence is cosmetic and recoverable; no data is lost. Optional repair, only if the order is violated: re-enqueue rows with non-null `import_source` once after 027 (the existing `sync_state` flag pattern from `b1_repull_done`); not built in v1. If 027 ships but the app does not use it: no effect.

**Alternatives considered**: a new value in `source` (rejected by the spec: `money_transaction_sync_mapper.dart:15,66-70` uses `oneOf(... sources)` which throws on an unknown value, so every v1.0.1 device would fail its pull, a 022 P0); a separate `sms_provenance` synced table (needs a new entity type, which v1.0.1 throws on, `sync_entity_type.dart:fromWire`); riding `note` (rejected: user text); gating `sync_push` behavior on `app_version_at_least` (unnecessary, the column is simply optional).

**Evidence**: `supabase/migrations/20261005100000_026_finance_entry_audits.sql:185-196,283-286,300-360,497,512,623,638`; `...021_offline_sync.sql:159-185` (money_transactions DDL), `:832-846` (grants); `...022_merged_features_sync.sql:71-74` (precedent: `source ... check (...)`, `ocr_scan_id`); `lib/core/sync/sync_mapper_registry.dart:11-28,175-235` (`SyncWire`); `lib/core/sync/local/sync_applier.dart:152-156`; `supabase/tests/021_rls.test.sql`; `.github/workflows/ci.yml:43` (UTC re-run of the sync suites; add the new legacy test dir to it).

---

## 11. Probable-duplicate lookup queries

**Decision**: No new index in v13. Use a new SMS-specific read, `CheckDuplicates` (domain use case) over `SmsDuplicateLookup`, implemented by a small `SmsDuplicateDao` that queries both tables with `currency_code = ? AND amount_minor_units = ? AND date BETWEEN ? AND ? AND deleted_at IS NULL`, returning `(id, type/direction, date, importSource)` only. The date window is computed with calendar arithmetic, `DateTime(y, m, d - 1)` and `DateTime(y, m, d + 1)`, then `millisecondsSinceEpoch`, because stored `date` is local midnight (`dateOnlyMillis`) and `Duration` math breaks across DST. Direction matching is in Dart: expense matches `given` (people ledger) and expense entries; income matches `received` and income entries (FR-060).

**Rationale / performance**: Both tables already have `(date, deleted_at)` indexes, so the range predicate is an index range scan over at most three days of rows and the amount and currency predicates filter that handful. During ingestion do **not** run one query per message: load once all rows of both tables for `[minDate - 1d, maxDate + 1d]` of the batch (a 90-day window is roughly hundreds of rows), build an in-memory `Map<(currency, amount), List<...>>` and evaluate the three tiers in memory. SC-005 (500 messages in 5 s) is dominated by the SMS query and regex work, not duplicate checks; the probable-duplicate check is only required at review open and Add (single indexed query each). The pending-pair rule uses the `(amount_minor_units, currency_code, status)` index on `pending_sms_imports`. If the benchmark in `test/performance/` (clone of `ocr_batch_scale_test.dart`) misses the budget, add `(currency_code, amount_minor_units, date)` partial indexes in a later migration.

**Alternatives considered**: reuse `FindPossibleDuplicate` (person-scoped, `find_possible_duplicate.dart:17-22`, rejected by FR-060: it must not change); denormalizing a `dup_key` column (rejected: write cost on two synced tables for no measured need).

**Evidence**: `app_database.dart:48,315` (date indexes); `transactions_repository_impl.dart:680` (`_dateOnlyMillis`), `finance_repository_impl.dart:56`; `lib/features/transactions/domain/usecases/find_possible_duplicate.dart:12-22`; `test/performance/ocr_batch_scale_test.dart`.

---

## 12. Catch-up trigger

**Decision**: A new `SmsCatchUpTrigger` (`features/sms_import/presentation/sms_catch_up_trigger.dart`, `@lazySingleton`, `WidgetsBindingObserver`), a sibling of `NotificationRecomputeTrigger`; **not** a change to `AppLifecycleObserver`.

- Started from the `startup.whenReady` block in `main.dart:50-58` (`getIt<SmsCatchUpTrigger>().start()`), which also covers the first foreground after a cold start; `didChangeAppLifecycleState(resumed)` triggers later ones.
- **Single-flight**: `Future<bool>? _inFlight` joined by concurrent callers, the identical idiom as `notification_recompute_trigger.dart:69`.
- **Debounce**: skip when `lastCatchUpAt` is under 60 seconds old (resume also fires after the permission dialog, App info and share sheets); the explicit scan and the enable flow bypass the debounce, and set `lastCatchUpAt`. "At most once per foreground session" (FR-013) = one run per `resumed` transition after the debounce.
- **Not while locked**: if `AppLifecycleObserver.isLocked.value` is true the trigger registers a one-shot listener and runs on unlock; the observer's cold-launch lock (`initialize`, `app_lifecycle_observer.dart:74-77`) therefore also defers the first run. The trigger reads `isLocked` through a tiny injected interface so the sms feature does not import core internals beyond the existing `ValueListenable`.
- **Preconditions** each run (cheap, in order): capability available; `is_enabled`; `getPermissionState().granted` (no prompt; a revoked grant flips the UI to the "permission off" state, FR-070, FR-013-4); not already scanning. It stops immediately on disable or revocation by checking between pages. Never throws; failures are counted content-free and retried at the next resume.
- Work: `queryInbox` pages with the cursor, then the ingestion pipeline of Decisions 7-9, then purge/expire (30-day pending expiry, Undo and tombstone retention) and the rule-version re-parse. Runs on the UI isolate in small awaited pages; regex work per page is millisecond-scale, but the benchmark (Decision 11) decides whether to hand pages to `compute`.

**Rationale**: `AppLifecycleObserver` is a security component whose single job is the lock decision, and `core/` must not import features (constitution II, `app_lock_status_provider.dart:1-5`); the recompute trigger's doc comment does suggest consolidating onto the observer, but that note predates the observer's current lock-only role (it exposes no resume stream), and consolidating would put SMS work inside security code. A sibling observer keeps SMS out of it and reuses a proven pattern; consolidating both triggers onto one shared lifecycle stream is a separate refactor.

**Alternatives considered**: hooking the observer (couples security and SMS); a startup-only run (misses every later foreground, violating FR-013); `workmanager` or a periodic task (NG10/FR-008a: no background work).

**Evidence**: `lib/features/insights_notifications/presentation/notification_recompute_trigger.dart:35-77`; `lib/main.dart:50-58`; `lib/core/security/app_lifecycle_observer.dart:66-77,100-110`; `lib/core/security/app_lock_status_provider.dart:1-5`.

---

## 13. Localization

**Decision**: All strings are ARB keys prefixed `smsImport` in `lib/core/l10n/app_en.arb` (template, `l10n.yaml`) and `app_ar.arb`, each with an `@key` description and typed placeholders.

- **Plural and select syntax already in use** (so no new mechanism): ICU `plural` with `=0/=1/other` in English, e.g. `syncStatusPending` (`app_en.arb:720`, `{count, plural, =1{...} other{...}}`); Arabic uses the full set `=1`, `=2`, `few`, `many`, `other` (`app_ar.arb:284`, `:1360`, `:615`; `syncStatusPending` at `:368` lacks `many` and is left alone as a separate follow-up); ICU `select` appears at `app_en.arb:2687` (`repaymentFlipConfirmMessage`). New plural keys: scan summary counts ("N bank messages found, M need review"), "N suggestions expired" (US1-10), "N selected", paste summary (recognized/skipped). Arabic forms must be written out for 0/1/2/few/many/other.
- **Formatting**: amounts through `CurrencyFormatter(currency: ..., locale: ...)` (`format`/`formatWithSymbol`, always Western digits); dates through `AppDateFormatter(locale: ...)` (`.format`, `.formatDateTime`); both resolve the locale via `numeralLocaleFor` (`core/l10n/numeral_locale.dart`: `ar` -> `ar_u_nu_latn`) and post-process with `NumeralParser.toWesternDigits`. No new formatters. The message time of day, shown read-only in review (FR-058), uses `formatDateTime`'s time part or `DateFormat.jm(numeralLocaleFor(...))` post-processed the same way.
- **Original text display** (FR-091): `Text(maskedText, textDirection: detectedDirection)` where direction is derived from the first strong character (Dart `intl` `Bidi.detectRtlDirectionality`), independent of the app locale.
- **Parity test**: `test/features/sms_import/presentation/l10n_parity_test.dart`, cloned from `test/features/ai_assistant/presentation/l10n_parity_test.dart` (reads `lib/core/l10n/app_<locale>.arb`, filters by the feature prefix, checks both languages non-empty, no AR-only keys, matching `{placeholder` names). Extend the clone to compare plural/select category sets in Arabic (`few`/`many` present where the English uses `plural`), for `smsImport*` keys only.
- **Hardcoded-string guard**: a source-grep test over `lib/features/sms_import/presentation` for string literals passed to `Text(` (the rule is Principle XIII); the rule-set keyword tables are data, not UI strings, and live outside `presentation`.

**Alternatives considered**: a separate `app_sms_*.arb` (rejected: `l10n.yaml` has one template and one output); Arabic-only `few/many` omission (rejected: `gen-l10n` would fall back to `other`, producing wrong grammar for 3-10 and 11-99).

**Evidence**: `l10n.yaml`; `app_en.arb:720,2142,2326,2687`; `app_ar.arb:284,615,1360`; `lib/core/l10n/numeral_locale.dart`; `lib/core/date/app_date_formatter.dart:11-48`; `lib/core/money/currency_formatter.dart:67`; `test/features/ai_assistant/presentation/l10n_parity_test.dart:9-40`.

---

## 14. Testing infrastructure

**Findings**: There is **no Kotlin test infrastructure**: `android/app/src` holds only `main`, `debug`, `profile`, with no `test` source set, and no `testImplementation` in `build.gradle.kts`; CI (`ci.yml`) runs only `flutter analyze` and `flutter test`. Native plugin behavior is verified today only by a Dart-side `MethodChannel` double (`test/core/security/screenshot_protection_service_test.dart:9-30`, `setMockMethodCallHandler`) and quickstart scenarios.

**Decision**:
- **Kotlin**: keep `SmsPlugin.kt` thin (OS calls and argument shaping only; all rules, cursor logic, classification and parsing stay in Dart). No new Gradle test setup in this feature. Verification: (1) a Dart **channel contract test** that records the exact arguments `PlatformSmsInboxGateway` sends and feeds canned replies (page boundaries, `permission_denied`, empty page), and (2) device quickstart scenarios (Decisions 1, 2, 4 SPIKES S1/S2) using `adb emu sms send` on an emulator (numeric senders only) and a real device for alphanumeric sender IDs; a debug-only "inject synthetic message" tile modeled on `debug_seed_tile.dart` feeds the pipeline without the OS.
- **Dart fakes** (`test/features/sms_import/helpers/`): `FakeSmsInboxGateway` (scripted pages, call log), `FakeSmsPermissionService`, `FakeSharedTextSource`, `InMemorySecureStorage` (implements the `FlutterSecureStorage` surface used by `SmsKeyStore`, with a switch to throw "unwrap failure" for key-loss tests), fixed `AppClock`, deterministic `Random` for nonces. The vault and hasher take keys by interface so tests use fixed keys.
- **Integration** (`integration_test/sms_import_flows_test.dart`): same shape as `ocr_flows_test.dart` (real DI via `configureDependencies`, `getIt.unregister<...>()` then `registerSingleton` of the fake gateway, `appRouter.go(...)`, `pumpWidget(DaftaryApp())`; `ocr_flows_test.dart:62-64`). Journeys: paste then review then Add; Android scan with a fake gateway then Ignore; duplicate warning; permission-off state. Per `integration_test/readme`, not run in CI.
- **Corpus**: `test/fixtures/sms/<bankId>/<case>.txt` (the synthetic message exactly as received, UTF-8) plus `<case>.json` (`{"synthetic": true, "sender": "NBE" | null, "classification": "transaction|non_transactional|unreadable", "kind": "...", "amountMinor": 12550, "currency": "EGP", "direction": "debit", "date": "2026-03-04", "dateInferred": false, "merchant": "...", "last4": "1234", "refPresent": true, "confidence": {"overall": "high", "amount": "read:high", "date": "inferred"}}`). Folders `_noise/` (OTP, promo, decline, balance inquiry), `_paste/` (multi-message and bounds), `_cross/` (cross-bank non-match). One loader test iterates the tree (adding a case adds no code), asserts `synthetic: true` on every file, computes per-bank field accuracy and fails below the SC-001 gate (95% of amount/currency/direction/date, 100% of noise rejected), and asserts the FR-028 cross-bank invariant. A guard test fails the build if any `.txt` contains a 16-digit run or a number matching a real-looking Egyptian mobile prefix (no real data committed).
- **Privacy leak test** (`test/features/sms_import/privacy/`): a sentinel message (unique merchant, amount 987654.32, card `4111111111111111`, reference `998877665544`) runs end to end through scan, paste, share, review, Add, Ignore, expiry, and re-parse with (a) `debugPrint` replaced by a capturing function and the repo `SyncLogger` spy (pattern of `sync_log_scrub_test.dart`), (b) the real `SyncOutbox` rows after Add (payload must carry only user-confirmed fields and `import_source`; `note` null), (c) `ExportUserData` CSV output, (d) a raw `SELECT *` over every table in `db.allTables` searching all TEXT and BLOB cells for the sentinel strings (they may appear only in confirmed fields of the saved row), (e) `raw_blob` is `NULL` after each decision and, while pending, does not contain the plaintext bytes and decodes only with the vault. A static guard greps `lib/features/sms_import` and `SmsPlugin.kt` for `print(`, `debugPrint(`, `developer.log`, `Log.` and fails on any hit (the feature has no logging at all, FR-100/101; counts are persisted, not logged). Masking tests cover separators, Arabic-Indic digits, grouped amounts untouched.
- **Sync, DB, manifest**: legacy-mapper pull test and pgTAP file (Decision 10); v13 migration test (Decision 9); `tool/check_merged_manifest.sh` plus the APK `aapt` assertion (Decision 3); table classification and data-wipe tests updated; RTL/theme widget tests per new screen (pattern `test/features/ocr/presentation/widgets/ocr_rtl_theme_test.dart`).

**Alternatives considered**: introducing JUnit for the selection builder (new infrastructure and CI minutes for about 15 lines whose correctness is only provable on real provider behavior); a `flutter_driver`/emulator SMS CI job (not available on the Ubuntu runner without an emulator).

**Evidence**: `android/app/src/` listing; `android/app/build.gradle.kts:84-86` (no test deps); `.github/workflows/ci.yml:30-43`; `test/features/ocr/data/parsing/candidate_entry_parser_test.dart`; `test/core/sync/sync_log_scrub_test.dart:12-40`; `test/core/sync/dao_outbox_guard_test.dart` (static-guard style); `integration_test/ocr_flows_test.dart:62-64`; `lib/features/settings/presentation/debug/debug_seed_tile.dart:23-30`; `test/performance/ocr_batch_scale_test.dart`.

---

## 15. New dependencies summary

| Dependency | Why | Wrapper interface | Alternative rejected |
|---|---|---|---|
| `pointycastle: ^4.0.0` (direct pubspec entry; already resolved as transitive, `pubspec.lock:1159`) | AES-256-GCM for raw SMS text at rest (Decision 6) | `RawTextVault` (impl `AesGcmRawTextVault`), the only importer | `cryptography` 2.9.0 and `encrypt` 5.0.3 (new packages); native Keystore/CryptoKit (new Swift, no native tests, macOS gap) |
| `crypto` (already direct, `pubspec.yaml:107`) | HMAC-SHA256 for fingerprints, reference hashes | `FingerprintHasher` (impl `HmacFingerprintHasher`) | none needed |
| `flutter_secure_storage` (already direct) | Holds the two random keys | `SmsKeyStore` over the injected singleton | new storage: no |
| `app_settings` (already direct) | Open App info for the permission/restricted-settings guidance | existing call style, behind the permission service | in-Kotlin intent: unnecessary |
| `SmsPlugin.kt` (in-app, no package) | Inbox query, READ_SMS request, install source, share intent | `SmsInboxGateway`, `SmsPermissionService`, `SharedTextSource` | `another_telephony`, `flutter_sms_inbox`, `readsms`, `telephony` (Decision 1); `permission_handler` (Decision 2); `receive_sharing_intent` (Decision 4) |
| READ_SMS manifest overlay (AGP static manifest file, or in-repo manifest-only `:sms_capability` module, S3) | Conditional READ_SMS declaration (Decision 3) | none (build-time) | product flavors, source-set overlay, placeholders |

Net: **one new line in `pubspec.yaml`, zero new packages in the lockfile**, no new `pubspec` assets, no iOS native change. Per the pubspec convention, annotate the new entry: `# 023 Bank SMS import: AES-GCM for raw message text at rest (research.md Decision 6). Wrapped behind sms_import/RawTextVault; only AesGcmRawTextVault imports it.` Also run `dart pub deps` after adding to confirm the resolved version stays 4.0.0.

---

## Spec feedback

Requirements the real code contradicts or leaves infeasible as written (each with the proposed edit):

1. **FR-034 / Eastern Arabic-Indic digits.** `NumeralParser` handles only `U+0660-0669` (`numeral_parser.dart:8`); `U+06F0-06F9` are not converted. Needs a small core change and test (Decision 8). Not infeasible, but the spec reads as if already supported.
2. **FR-031a "keeps reference IDs for re-parse".** Reference IDs of 12 or more digits are masked, so they cannot be re-read. Edit: say that fingerprints and reference hashes are computed once before masking and are immutable under re-parse (Decision 7).
3. **FR-059b(2) / FR-066 vs tombstone content.** Tier 2 needs amount and direction, but the tombstone entity lists no amount. Edit: tombstones hold two keyed hashes (`ref_hash`, `ref_amount_hash`), still content-free (Decision 9).
4. **US1-8 / SC-013 "audit entry identifies SMS as the source".** The audit tables (`transaction_audit_entries`, `finance_entry_audits`) have only `changeType`, `previousValuesJson`, `changedAt` (`app_database.dart:247-274`) and sync as such; there is no source field. Edit: the `created` audit row plus the record's `import_source` identify the source; a source column on audits would need a server and wire change on two more entity types and is out of scope.
5. **FR-016 / manifest "singleTop".** The existing `singleTop` + `taskAffinity=""` can start a second `MainActivity` (second engine) for a share arriving while the app is in the background (SPIKE S1); the Architecture Impact section implies no manifest change beyond an intent filter. Edit: the `ShareTargetActivity` trampoline is the baseline (applied in plan and contracts; spec wording still to reconcile).
6. **FR-001 "including permissions contributed by dependencies".** Feasible, but only with a CI assertion on the merged manifest; the clarify note that "no build contains a receive-SMS permission" is enforced by `tools:node="remove"` markers plus the script (Decision 3). Note: the release workflow builds two APKs (`:97,:106`), both must be asserted.
7. **FR-020 / FR-072 platform inference.** The "no dialog shown" signal is inferred from an activity pause, not an API; correctness is device-dependent (already OQ6). The `UPPER(address)` selection is unverified (SPIKE S2).
8. **FR-013 "at most once per foreground session".** Android resume also fires after the permission dialog, App info and share sheets; "session" must be defined as a resumed transition plus a 60-second debounce (Decision 12).
9. **FR-031 / FR-077 and phone numbers.** 11-digit Egyptian mobile numbers (InstaPay counterparties) fall under the 12-digit mask threshold and would be stored in the encrypted text; add an explicit mobile-number masking rule (Decision 7).
10. **FR-062 and FR-074a key loss, pre-existing side effect.** After an Android Auto Backup restore flutter_secure_storage's default `resetOnError: true` clears every secure entry, including the cloud session, App Lock PIN hash and AI key (the manifest has no backup rules). Not caused by this feature, but its "after a restore" claim is the same event; consider a separate fix (exclude the plugin's preferences file from backup).
11. **Process**: the Principle X amendment (SMS) is a pre-approval gate (spec Governance Alignment), recorded in plan.md as an owner action via `/speckit.constitution` before `/speckit.tasks`; it is not an implementation step.

Resolved by the plan review: items 2 and 4 are applied to spec.md (FR-031a, US1-8, SC-013), plus FR-074a wording, FR-039 (absent required field gives Low) and the "Imported from a bank message" copy (US1-9, FR-057). Items 3, 5 and 8 were applied to spec.md by the 2026-10-07 analysis remediation (FR-059a/b, FR-016 and Architecture Impact, FR-013); item 11 is done (constitution v1.1.0, 2026-10-07).

**Spikes to schedule first**: S1 share launch mode (device); S2 provider selection grammar (device, API 26-36); S3 AGP merged-manifest path for `processReleaseMainManifest` and `:sms_capability` merge; S4 restricted-settings inference and Play Protect on Egyptian-market devices (FR-003 gate, OQ5/OQ6); S5 copy and share envelope formats from Google Messages, Samsung Messages and iOS Messages (single and multiple messages), re-authored as synthetic fixtures (FR-017a).

## Analysis remediation (2026-10-07)

Decisions taken after `/speckit-analyze`. Each is reflected in spec.md, the contracts, data-model.md and tasks.md.

| Finding | Decision |
|---|---|
| H1 fingerprint tied to the evolving normalizer | Frozen `FingerprintNormalizer` v1 (steps 1-3 of the pipeline, no folding), `fp1|` prefix, golden fingerprints pinned in `_fingerprints.json`. A future change needs `fp2|` plus dual lookup (out of v1 scope). |
| H2 authorization reversal dropped | `authorizationReversal` becomes a pending kind with Ignore suggested, a fixed hint and the matched saved record (FR-024b). Pending-authorization wording is calibrated per bank. |
| H3 own transfers double-counted | `CheckDuplicates` adds `possibleOwnTransfer` for an opposite-direction pair of equal amount and currency within one day across banks or channels (FR-051d). No name-based detection. |
| H4 in-message fee lost | Ingestion stages a separate pending fee item (`parent_import_id`, fingerprint `fp1|fee|...`), never merged into the amount (FR-030a). |
| H5 paste/share envelopes | Spike S5 captures real formats; the splitter strips envelope lines first (FR-017a); cross-path fingerprint test. |
| M1 paste year | Current year, minus one if the date would be in the future. |
| M2 cross-currency | The stated original amount is also compared (no conversion). |
| M3 short reused references | `BankProfile.refIsUnique`; when false, tier 2 also needs a date within one day. |
| M7 `resetOnError` blast radius | A dedicated secure-storage instance with `resetOnError: false` for the SMS keys. |
| M8 two provenance fields | Derived getter `MoneyTransaction.provenance`; never test `source == manual` alone. |
| M11 cursor race | `ScanCoordinator` mutex across explicit scan and catch-up. |

## Spike addendum (2026-10-09): defaults pending device verification

**None of the spikes S1-S5 has run.** This environment has no physical devices or emulators, so T010-T013, T163 and this consolidation (T014) stay unchecked. The entries below are the **defaults pending device verification**: the primary choices the decisions above already designate, which implementation follows until a device run confirms or overturns them. No decision is overturned, so `contracts/sms-platform-channel.md` §2.4 is unchanged. Details, fallbacks and device checklists are in `spikes/S1`-`S5`.

| Spike | Default pending verification | Fallback if a device overturns it | Must be verified on a device |
|---|---|---|---|
| S1 share instance (`spikes/S1-share-instance.md`) | `ShareTargetActivity` trampoline, `NEW_TASK\|CLEAR_TOP\|SINGLE_TOP` start of `MainActivity`; `MainActivity` stays `singleTop` (Decision 4) | Try `REORDER_TO_FRONT` in the trampoline only; never `singleTask`; otherwise record the OEM as a known limitation for the owner | Exactly one `MainActivity` in `dumpsys activity activities` after a background share, on Pixel, Samsung and one Egyptian-market OEM |
| S2 selection grammar (`spikes/S2-provider-selection.md`) | `UPPER(address) IN (?,...) AND (date > ? OR (date = ? AND _id > ?))`, bound values, `date ASC, _id ASC`, at most 200 rows read (Decision 1, contract §2.4) | `address COLLATE NOCASE IN (...)`, then OR-joined `address LIKE ?`, then two-phase read (the last one amends §2.4 and FR-020 in the same change) | Grammar accepted on API 26-36 emulators and one real OEM provider; keyset paging exact |
| S3 overlay mechanism (`spikes/S3-manifest-overlay.md`) | AGP 8.11.1 `androidComponents.onVariants { it.sources.manifests.addStaticManifestFile(...) }` with `android/app/sms_capability/AndroidManifest.xml`, switched by `DAFTARY_SMS_IMPORT` / `-Pdaftary.smsImport=true` (Decision 3) | Manifest-only `:sms_capability` library module (hard-coded `compileSdk = 36`) | READ_SMS present only when switched on in `processReleaseMainManifest`; merged-manifest path for T105 (default `app/build/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`, located by `find` so a layout change fails loudly). Needs only an SDK build, no device |
| S4 restricted settings (`spikes/S4-restricted-settings.md`) | Infer `restrictedBlocked` when not granted, no dialog shown (no `onPause`), `sdkInt >= 35`, install source not a store; generic four-step guidance (App info → overflow (three dots) → "Allow restricted settings" → Try again), copy never claims certainty (Decision 2, ui-contract §3.2) | Widen the copy to offer both "Try again" and the guidance when no prompt appeared; no per-OEM wording in v1 | Inference on Android 14/15/16 sideloaded installs incl. an Egyptian-market OEM; verbatim step wording in English and Arabic |
| S4 / OQ5 Play Protect in Egypt | **Open release gate.** Assume it may block (spec OQ5); verify before release | Two APKs (SMS-free standard + "with bank SMS"), or no Android SMS reading in v1 (owner decision) | Install and update of an SMS-declaring sideloaded APK on a device in Egypt |
| S4 / OQ6 restricted-settings flow | **Open release gate.** Ship the inference and guidance (spec OQ6) | Static written instructions only | Real-device walkthrough (owner, T160) |
| S5 envelopes (`spikes/S5-copy-share-envelopes.md`) | Splitter step (0) table with rule classes E0-E5, header-position only, under-strip on doubt (parser-contract §3, FR-017a) | Add a versioned rule per newly observed shape; never change `FingerprintNormalizer` v1 | Exact copy/share output of Google Messages, Samsung Messages and iOS Messages, single and multi-select, EN/AR, 12/24 h; single copy byte-identical to the inbox body |

**Envelope table for the splitter (all UNVERIFIED; placeholders, no real content)**:

| App | Single copy / share | Multi-select |
|---|---|---|
| Google Messages | `<BODY>` | Not offered, or `<BODY>` joined by blank lines/line breaks, possibly with a `<SENDER>` and/or `<DATE> <TIME>` header line per message |
| Samsung Messages | `<BODY>` | Per message `<SENDER>⏎<DATE> <TIME>⏎<BODY>`, or `[<DATE> <TIME>] <SENDER>: <BODY>`, possibly with separator lines |
| iOS Messages | `<BODY>` (copy only; no share target on iOS) | No multi-copy; one message at a time |

Rule classes: E0 line-ending normalization; E1 sender-only line; E2 date/time-only line; E3 sender + date/time line (E1-E3 only in header position at the start of a chunk); E4 bracketed prefix removed, body kept; E5 separator line treated as a boundary. A line holding a currency token or matching a profile signature or `messageStart` is never stripped. A single-message copy is expected (unverified) to equal the inbox body up to line endings and bidi/zero-width marks, which `FingerprintNormalizer` v1 steps 1-2 absorb.
