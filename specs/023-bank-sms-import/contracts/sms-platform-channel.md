# Contract: SMS Platform Channel (`SmsPlugin`)

**Feature**: 023 Bank SMS Import · **Research**: Decisions 1, 2, 3, 4, 14 · **Requirements**: FR-001, FR-002, FR-008a, FR-011, FR-012, FR-013, FR-016, FR-016a, FR-020, FR-069, FR-070, FR-072, FR-073, FR-074, FR-080, FR-098, FR-101

The only native code of the feature: one in-app Kotlin plugin, `android/app/src/main/kotlin/com/daftary/daftary/SmsPlugin.kt`, registered next to `SecurityPlugin` in `MainActivity.configureFlutterEngine` (`flutterEngine.plugins.add(SmsPlugin())`) **in every Android build, with or without the READ_SMS capability** (sharing needs no permission, FR-001/FR-011), plus a small `ShareTargetActivity.kt` trampoline that carries the share filter (section 2.5). `SmsPlugin` is an `ActivityAware` `FlutterPlugin`. `MainActivity`'s launch mode is not changed. iOS and macOS have **no** native counterpart: on those platforms the Dart adapters report `unavailable` without touching a channel (a `MissingPluginException` is also mapped to `unavailable`, never logged).

The plugin is **thin**: OS calls and argument shaping only. Rules, cursor logic, classification, masking, parsing and every decision live in Dart (research Decision 14).

## 1. Channels

| Channel | Type | Name |
|---|---|---|
| Methods | `MethodChannel` | `com.daftary.daftary/sms` |
| Shared text | `EventChannel` | `com.daftary.daftary/sms/shared_text` |

Both names are `static const` on the Dart adapter, injectable for tests (precedent: `PlatformScreenshotProtectionService`). Codec: `StandardMethodCodec`. Every value that crosses is a primitive, `List` or `Map<String, Object?>`; no custom classes.

## 2. Methods

### 2.1 `getCapabilities`

| | |
|---|---|
| Arguments | none |
| Result | `{ "readSmsDeclared": bool, "sdkInt": int, "isStoreInstall": bool? }` |
| Errors | none (never throws) |
| Thread | main |

`readSmsDeclared` = `READ_SMS` appears in `PackageInfo.requestedPermissions` of the installed package (research Decision 3). It is the only capability signal: the manifest overlay is switched by the single Gradle variable `DAFTARY_SMS_IMPORT`, and there is no Dart const or `--dart-define`. Dart computes `SmsCapability.available = readSmsDeclared && Platform.isAndroid`. Share-text availability does **not** depend on it (`SharedTextSource` is available on `Platform.isAndroid` only).

### 2.2 `getPermissionState`

| | |
|---|---|
| Arguments | none |
| Result | `{ "granted": bool, "shouldShowRationale": bool }` |
| Errors | `unavailable` (READ_SMS not declared) |
| Thread | main |

Never prompts. Used on every resume to detect revocation (FR-070), by the catch-up preconditions and by the enable flow. `shouldShowRationale` comes from `ActivityCompat.shouldShowRequestPermissionRationale`; when no activity is attached the plugin answers `{granted: <checkSelfPermission>, shouldShowRationale: false}`.

### 2.3 `requestPermission`

| | |
|---|---|
| Arguments | none |
| Result | `{ "granted": bool, "shouldShowRationale": bool, "dialogShown": bool, "sdkInt": int, "installSource": "store" \| "notStore" \| "unknown" }` |
| Errors | `unavailable`, `no_activity` (no attached activity), `request_in_progress` (a second call while one is pending) |
| Thread | main; result delivered on the permission-result callback |

Implementation: `ActivityCompat.requestPermissions(activity, arrayOf(READ_SMS), 0x5A11)` (request code below 16 bits for `FragmentActivity`), result via `binding.addRequestPermissionsResultListener`. At most one request is in flight. **Only `READ_SMS` is ever requested** (FR-069, FR-073). The call is made only from the explicit enable flow after the explanation (FR-002, FR-005); no other Dart code path may call it (guarded by a test that greps for `requestPermission(` outside `RequestSmsPermission`).

`dialogShown` is true when the activity received `onPause` between the request and the result (the system dialog is a separate translucent activity); it is recorded through the `ActivityPluginBinding` lifecycle. `installSource`: `PackageManager.getInstallSourceInfo` on API 30+ (`packageSource` on API 33+: `PACKAGE_SOURCE_STORE` -> `store`; `DOWNLOADED_FILE`, `LOCAL_FILE`, `OTHER` -> `notStore`; otherwise `installingPackageName` against a small store list); below API 30 the value is `unknown`.

**Restricted-settings inference inputs** (FR-072): the plugin only reports facts. The decision is the pure Dart `classifySmsPermission(result, previouslyRequested)` (domain, unit-tested), inputs exactly `granted`, `shouldShowRationale`, `dialogShown`, `sdkInt`, `installSource`, and the persisted `permissionRequested` flag:

| Condition | Result |
|---|---|
| `granted` | `granted` |
| not granted, `dialogShown == false`, `sdkInt >= 35`, `installSource != store` | `restrictedBlocked` (inferred; no public API reports it) |
| not granted, `shouldShowRationale == false`, `permissionRequested == true` | `permanentlyDenied` |
| not granted otherwise | `denied` (may ask again once, never silently, FR-012) |
| `getPermissionState` says not granted after a prior grant | `revoked` |

**App Lock**: Dart wraps this call in `AppLifecycleObserver.runExternalActivity` (its future completes when the result arrives). The App-info deep link is **not** wrapped (a fire-and-forget `startActivity` completes immediately, so wrapping would suppress nothing; leaving the app is a real backgrounding and the user's lock timeout correctly applies).

### 2.4 `queryInbox`

| | |
|---|---|
| Arguments | `{ "senders": List<String>, "afterDate": int, "afterId": int?, "limit": int }` |
| Result | `List<Map>` of `{ "id": int, "address": String, "date": int, "body": String, "truncated": bool }` |
| Errors | `permission_denied`, `query_failed`, `invalid_args`, `unavailable` |
| Thread | **background single-thread executor**; result posted to the main thread |

Argument rules (validated in Kotlin before touching the provider):

- `senders`: non-empty, at most 200 entries, each 1..32 characters, canonical upper-case with no spaces (Dart normalizes; Kotlin only rejects violations). The list is the **allow-list minus muted senders** supplied by Dart so the rule data lives once (FR-020, FR-065). An empty list is `invalid_args`, never "match everything".
- `afterDate`: epoch ms (>= 0). `afterId`: provider `_id` tiebreak, null on the first page. `limit`: 1..200 (values above 200 are rejected, not clamped).

Query: `Telephony.Sms.Inbox.CONTENT_URI`, projection `_id, address, date, body`; selection `UPPER(address) IN (?,?,...) AND (date > ? OR (date = ? AND _id > ?))` with all values as bind arguments (never string-concatenated); sort `date ASC, _id ASC`; read at most `limit` rows from the cursor (no SQL `LIMIT`; minSdk 24). **The sender filter is inside the selection, so a non-allow-listed message body is never read** (FR-020). SPIKE S2 settles the selection grammar; the pre-decided fallbacks in order are `address COLLATE NOCASE IN (...)`, then OR-joined `address LIKE ?`, then a two-phase read (and if the two-phase fallback is taken, this contract and FR-020 wording are amended in the same change).

Result rules: only allow-listed rows; ordered `(date, id)` ascending; a page shorter than `limit` means "no more". Bodies are truncated by Kotlin at **4,000 characters** with `truncated: true` (hostile or huge messages must not exhaust memory, FR-098); Dart treats a truncated body as parseable but never fingerprints beyond the received text. MMS-only or null bodies are skipped by Kotlin and reported only as absence. Dart owns the cursor `(date, id)` in `sms_import_settings`; catch-up starts 24 hours before the stored cursor (provider `date` is device receipt time but OEM apps differ) and idempotent fingerprints absorb the overlap.

### 2.5 `getInitialSharedText`

| | |
|---|---|
| Arguments | none |
| Result | `{ "text": String, "truncated": bool }?` (null when no share launched the app) |
| Errors | none |
| Thread | main |

Share entry (baseline, spike S1 only verifies the instance count is 1): a translucent `ShareTargetActivity` (`noHistory`, `excludeFromRecents`) carries the `ACTION_SEND` + `text/plain` intent filter in every build. In `onCreate` it reads `EXTRA_TEXT` (as `CharSequence`), puts it into an in-process `SharedTextHolder` (a Kotlin object, never an Intent extra), starts `MainActivity` with `FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TOP | FLAG_ACTIVITY_SINGLE_TOP` and calls `finish()`. `MainActivity` and its `singleTop` launch mode are untouched, so notification taps carry no regression risk, and no second Flutter engine is created.

Cold start: the cold-start text comes from the holder, **not** from `activity.intent`. `getInitialSharedText` drains the holder and returns the text **once**, clearing it, so recreation or process restore cannot replay it. The `ACTION_SEND` filter is never on `MainActivity`, so `activity.intent` never carries share text. Text is truncated at **10,001 characters** with `truncated: true` (the 10,000 bound of FR-017; one extra character lets Dart report "too long" precisely). The 50-message bound is enforced by the Dart splitter.

### 2.6 Shared-text event stream (`EventChannel`)

| | |
|---|---|
| Stream element | `{ "text": String, "truncated": bool }` |
| Errors | none sent on the stream (a malformed intent is dropped) |
| Thread | main |

Warm start: `ShareTargetActivity` offers the text to the `SharedTextHolder`; if `SmsPlugin` has a stream listener the holder pushes it immediately, otherwise it buffers one pending event until a listener subscribes, then delivers it once and clears it. Same truncation and `ACTION_SEND text/plain` rules as 2.5.

### 2.7 Open app info (**no channel method**)

The research decision is to reuse the existing `app_settings` package (`AppSettings.openAppSettings()`, default type = this app's details screen on Android), behind `SmsPermissionService.openAppInfo()`. There is no `openAppInfo` method on `SmsPlugin`. This is deliberate (no native code, same call as `notification_settings_page.dart:27`) and noted here so the contract list is complete.

## 3. Error codes

`PlatformException.code` values (the `message` and `details` are always null or a fixed English token, **never** message content, sender, count or address):

| Code | Meaning | Dart mapping |
|---|---|---|
| `unavailable` | READ_SMS not declared (capability off) | `SmsCapabilityUnavailableFailure` |
| `permission_denied` | `SecurityException` from the provider, or permission not granted | `SmsPermissionFailure(status)` |
| `query_failed` | Cursor null, provider rejected the selection, any other exception during the query | `SmsInboxQueryFailure` |
| `invalid_args` | Argument rule violated (empty/oversized senders, limit out of range) | `SmsInboxQueryFailure` (a programming error; asserts in debug) |
| `no_activity` | `requestPermission` with no attached activity | `SmsPermissionFailure(denied)` (retry later) |
| `request_in_progress` | Concurrent `requestPermission` | the second caller awaits the first (Dart single-flight), so this should not surface; if it does, `SmsPermissionFailure(denied)` |

`MissingPluginException` (iOS, macOS, widget tests with no handler) -> `SmsCapabilityUnavailableFailure`. No retry loops in the adapter; callers decide.

## 4. What never crosses the channel

- Any message from a sender not in the supplied allow-list (enforced by the selection).
- Thread IDs, contact names, phone-book data, `person`, `seen`, `read`, `type`, `service_center` or any provider column beyond `_id, address, date, body`.
- Outgoing, draft or MMS content; the SENT/DRAFT boxes are never queried.
- Anything from Dart to Kotlin except the allow-list, cursor, limit and (separately) nothing at all for the other methods. No parsed field, amount, category or decision ever goes native.
- Log output: `SmsPlugin.kt` and `ShareTargetActivity.kt` contain **no** logging (`Log.`, `println(`, `printStackTrace(`, `System.out`); a static guard test greps both Kotlin files for those and `lib/features/sms_import` for `print(`, `debugPrint(`, `developer.log`, `Log.` and fails on any hit (FR-100, FR-101). Unlike `PlatformScreenshotProtectionService`, the SMS adapters have no `_log` helper.
- Intent extras beyond `EXTRA_TEXT` (read only by `ShareTargetActivity`); the shared text is never put in the `MainActivity` Intent, a route URL, saved state, notification or file (FR-016a, FR-080).
- Permissions beyond `READ_SMS`: no `RECEIVE_SMS`, `SEND_SMS`, `READ_PHONE_STATE`, contacts, storage, notification, or battery permission; the main manifest carries `tools:node="remove"` markers for `RECEIVE_SMS, SEND_SMS, RECEIVE_MMS, RECEIVE_WAP_PUSH, WRITE_SMS, READ_PHONE_STATE` (FR-008a, FR-073).
- No broadcast receiver and no background work is registered by the plugin (FR-008a).

## 5. Threading summary

| Operation | Thread | Notes |
|---|---|---|
| `getCapabilities`, `getPermissionState`, `getInitialSharedText`, event delivery | main | O(1) |
| `requestPermission` | main (callback on the activity's main thread) | single in-flight |
| `queryInbox` | one background executor (`Executors.newSingleThreadExecutor`), cursor closed in `finally` | at most one query at a time; Dart also single-flights scans. Result via `Handler(Looper.getMainLooper())` |
| Plugin detach | cancels the executor's pending task, unregisters the share sink and the permission listener; the `SharedTextHolder` keeps at most one unconsumed text until read or process death | no leaks across engine restarts |
| `ShareTargetActivity` | main | O(1): copy `EXTRA_TEXT` to the holder, start `MainActivity`, finish |

## 6. Dart side: ports (domain) and adapters (data)

Domain ports (`lib/features/sms_import/domain/services/`), all pure Dart, all returning `Either<Failure, T>`:

```dart
abstract class SmsInboxGateway {
  /// Capability and platform check; never throws, never prompts.
  Future<SmsCapability> getCapability();

  /// One keyset page of allow-listed messages strictly after the cursor.
  /// [limit] 1..200; [senders] canonical, non-empty. A page shorter than
  /// [limit] means the inbox is exhausted for this cursor.
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  });
}

class InboxSmsMessage extends Equatable {
  final int id;               // provider _id
  final String address;       // raw address as stored by the provider
  final DateTime date;        // receipt time
  final String body;
  final bool truncated;
}

abstract class SmsPermissionService {
  /// Prompt-free. Detects revocation on resume (FR-070).
  Future<Either<Failure, SmsPermissionStatus>> getStatus();

  /// Prompts at most once per call; wrapped in runExternalActivity by the
  /// RequestSmsPermission use case. Persists `permissionRequested` through
  /// the settings repository before invoking the platform.
  /// [previouslyRequested]: the persisted flag as it was BEFORE this
  /// request was recorded (read by RequestSmsPermission before it persists;
  /// phase6b decision).
  Future<Either<Failure, SmsPermissionStatus>> request({
    required bool previouslyRequested,
  });

  /// Opens this app's system App info screen (restricted-settings and
  /// permanently-denied guidance). Not wrapped by runExternalActivity.
  Future<Either<Failure, Unit>> openAppInfo();
}

abstract class SharedTextSource {
  /// Cold-start share, returned once.
  Future<SharedText?> takeInitial();

  /// Warm shares. Single-subscription, buffered by the platform until
  /// listened to.
  Stream<SharedText> get stream;
}

class SharedText extends Equatable {
  final String text;
  final bool truncated;
}
```

`classifySmsPermission(SmsPermissionResult result, {required bool previouslyRequested})` is a top-level pure function in `domain/rules/classify_sms_permission.dart`; `SmsPermissionResult` carries the five fields of 2.3.

Data adapters (`lib/features/sms_import/data/platform/`), `@LazySingleton(as: ...)`:

| Adapter | Implements | Notes |
|---|---|---|
| `SmsChannelClient` | (internal) | Holds the `MethodChannel` and `EventChannel`; injectable (`@ignoreParam`); converts `PlatformException`/`MissingPluginException` into a small internal `SmsChannelError(code)`; no logging |
| `PlatformSmsInboxGateway` | `SmsInboxGateway` | Validates arguments in Dart as well (same rules as 2.4) before invoking; maps result maps to `InboxSmsMessage`; short-circuits to `unavailable` when `!SmsCapability.available` (`readSmsDeclared && Platform.isAndroid`) so no inbox call is made on iOS, macOS or a non-SMS build |
| `PlatformSmsPermissionService` | `SmsPermissionService` | `request(previouslyRequested:)` calls `requestPermission`, then `classifySmsPermission` with the caller's pre-persist flag (single flight); `getStatus()` classifies `getPermissionState` with the stored `permissionRequested` and `isEnabled` (as `previouslyGranted`, for `revoked`); `openAppInfo()` uses `app_settings.AppSettings.openAppSettings()` (default type opens the app details screen); on a non-Android platform or when `readSmsDeclared` is false every method returns `SmsPermissionStatus.unavailable` / `Right` without a permission channel call; imports `package:app_settings` with the prefix `as app_settings` because its `AppSettings` collides with the Drift `AppSettings` data class |
| `PlatformSharedTextSource` | `SharedTextSource` | `takeInitial()` -> `getInitialSharedText`; `stream` -> `EventChannel.receiveBroadcastStream` mapped to `SharedText`, deduplicated by a monotonic event counter, never logged; available whenever `Platform.isAndroid` (**also in a capability-off build**, so sharing works in every Android build); `UnavailableSharedTextSource` (empty stream) is registered only for iOS and macOS |

Test doubles (`test/features/sms_import/helpers/`): `FakeSmsInboxGateway` (scripted pages, call log), `FakeSmsPermissionService`, `FakeSharedTextSource`. A **channel contract test** (`platform_sms_inbox_gateway_test.dart`, `setMockMethodCallHandler`) records the exact arguments sent and feeds canned replies: page boundary, empty page, `permission_denied`, `query_failed`, oversized sender list, `limit` 201 rejected before the call.

## 7. Invariants (tested)

1. READ_SMS is requested only from `RequestSmsPermission`, and only after the explanation screen was shown (FR-002, FR-005).
2. `queryInbox` is called only with a non-empty allow-list that excludes every muted sender.
3. Nothing from the channel is persisted before it has passed `SmsMasker` + the ingestion pipeline; the raw body object is not retained after a page is processed.
4. `getInitialSharedText` returns a given share at most once per process.
5. A build without the capability makes no inbox or permission channel call on any path (the adapters short-circuit), while `SmsPlugin` stays registered and the share path keeps working; the merged manifest has no `READ_SMS` (CI `tool/check_merged_manifest.sh`).
6. The plugin, `ShareTargetActivity` and the adapters contain no logging call.
