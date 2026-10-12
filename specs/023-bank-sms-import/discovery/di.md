# Discovery T005: dependency injection

Read-only notes for T063 (`Unavailable*` ports), T064 (`SmsChannelClient`), T039 (dedicated secure storage), T065 (app adapters) and T069 (DI registration + `build_runner`). Anchors are at commit `4a5565d` plus the working tree on `023-bank-sms-import`.

## Decision: how to register "Platform* on Android, Unavailable* on iOS/macOS"

**Use one feature-level `@module` with `@lazySingleton` factory methods that choose the adapter with `dart:io` `Platform.isAndroid`.** The `Platform*` and `Unavailable*` classes themselves carry **no** injectable annotation.

Why this one:

1. **It matches existing code.** Feature-level `@module` classes already exist: `AppLockModule` (`lib/features/app_lock/data/services/app_lock_module.dart:6-10`) and `AIHttpModule` (`lib/features/ai_assistant/data/services/ai_http_module.dart:7-11`), alongside the root `RegisterModule` (`lib/core/di/register_module.dart:37-150`). Module methods that take injected parameters are already used: `RegisterModule.appDatabase(SyncBootstrap)` (`:41-43`), `syncApplier(...)` (`:56-61`), `syncMapperRegistry(...)` (`:114-145`).
2. **`dart:io` `Platform.isAndroid` is the existing platform check in the data layer**: `image_preparation_service_impl.dart:246` and `text_recognition_service_impl.dart:82` (`return Platform.isAndroid || Platform.isIOS;`). It is also the exact term in the capability formula (`readSmsDeclared && Platform.isAndroid`, sms-platform-channel.md §2.1).
3. **It is safe in tests.** Under `flutter test` the host is macOS or Linux, so `Platform.isAndroid` is `false` and the `Unavailable*` adapters are registered. No test that calls `configureDependencies()` (`test/core/sync/table_classification_guard_test.dart:43`, `test/core/di/ai_assistant_di_test.dart:21`) ever reaches the SMS channel.

Rejected options:

| Option | Why not |
|---|---|
| injectable `@Environment` / `@Named` environments | **No environment is used anywhere.** `configureDependencies()` calls `getIt.init()` with no `environment` (`lib/core/di/injection.dart:11-12`; generated `init({String? environment, ...})` at `injection.config.dart:680-684`). Registrations tagged with an environment are **skipped** when no environment is passed, so every test that calls `configureDependencies()` would lose the SMS ports. Adding environments would introduce a second DI style (briefing rule 2). |
| `defaultTargetPlatform == TargetPlatform.android` (precedent: `flutter_local_notifications_scheduler.dart:55-58`) | Under `flutter test`, `defaultTargetPlatform` **is `android`** whenever `FLUTTER_TEST` is set (`flutter/lib/src/foundation/_platform_io.dart:30-31`, Flutter 3.47.0). DI would then register the `Platform*` adapters in every test. Use it only inside widgets that need the Material platform look, never for DI. |
| One `Platform*` class that short-circuits internally and is always registered (`PlatformScreenshotProtectionService` style, `screenshot_protection_service.dart:35-95`, which swallows `MissingPluginException`) | Closest to precedent, but tasks T063/T069, plan.md:249 and :258 explicitly require separate `Unavailable*` classes registered on iOS/macOS. The `Platform*` adapters still keep their own `MissingPluginException` → `unavailable` mapping as defence in depth (contract §3, `:125`). |
| `@LazySingleton(as: SmsInboxGateway)` on **both** `PlatformSmsInboxGateway` and `UnavailableSmsInboxGateway` (as sms-platform-channel.md §6 literally says, "Data adapters ... `@LazySingleton(as: ...)`") | Both would be registered for the same type. get_it throws on the duplicate at `init()` (`allowReassignment` is false). **Flag:** the contract's `@LazySingleton(as: ...)` wording applies only to adapters with a single implementation (`SmsChannelClient`, `SystemClipboardReader`, `InMemoryReviewLeaseRegistry`, `AppLockStatus`, `AppExternalActivityRunner`, `InMemoryScanCoordinator`, crypto, DAOs, repositories). The three platform-split ports go through the module. |

### Snippet to copy (T069)

File: `lib/features/sms_import/data/platform/sms_platform_module.dart`

```dart
import 'dart:io' show Platform;

import 'package:injectable/injectable.dart';

import '../../domain/services/shared_text_source.dart';
import '../../domain/services/sms_inbox_gateway.dart';
import '../../domain/services/sms_permission_service.dart';
import 'platform_shared_text_source.dart';
import 'platform_sms_inbox_gateway.dart';
import 'platform_sms_permission_service.dart';
import 'sms_channel_client.dart';
import 'unavailable_shared_text_source.dart';
import 'unavailable_sms_inbox_gateway.dart';
import 'unavailable_sms_permission_service.dart';

/// Chooses the SMS platform adapters once, at the composition root, so the
/// domain and presentation layers never branch on the platform
/// (constitution X, briefing rule 11).
///
/// - Android (every build, with or without the READ_SMS capability): the
///   `Platform*` adapters. They read `getCapabilities().readSmsDeclared`
///   and short-circuit inbox and permission calls when it is false, while
///   sharing keeps working (sms-platform-channel.md §2.1, §6).
/// - iOS, macOS and the host `flutter test` platform: the `Unavailable*`
///   adapters, which never touch a channel.
///
/// `Platform.isAndroid` (dart:io), not `defaultTargetPlatform`: under
/// `flutter test` the latter reports android.
@module
abstract class SmsPlatformModule {
  @lazySingleton
  SmsInboxGateway smsInboxGateway(SmsChannelClient channel) =>
      Platform.isAndroid
      ? PlatformSmsInboxGateway(channel)
      : const UnavailableSmsInboxGateway();

  @lazySingleton
  SmsPermissionService smsPermissionService(SmsChannelClient channel) =>
      Platform.isAndroid
      ? PlatformSmsPermissionService(channel)
      : const UnavailableSmsPermissionService();

  @lazySingleton
  SharedTextSource sharedTextSource(SmsChannelClient channel) =>
      Platform.isAndroid
      ? PlatformSharedTextSource(channel)
      : const UnavailableSharedTextSource();
}
```

Rules that go with it:

- `PlatformSmsInboxGateway`, `PlatformSmsPermissionService`, `PlatformSharedTextSource` and the three `Unavailable*` classes get **no** `@injectable`/`@LazySingleton` annotation. Otherwise injectable registers the same type twice.
- `SmsChannelClient` is a normal `@lazySingleton` class with channels injectable for tests, copied from `PlatformScreenshotProtectionService` (`screenshot_protection_service.dart:38-46`):

  ```dart
  @lazySingleton
  class SmsChannelClient {
    SmsChannelClient({
      @ignoreParam MethodChannel? methodChannel,
      @ignoreParam EventChannel? eventChannel,
    }) : _methods = methodChannel ?? const MethodChannel(methodChannelName),
         _events = eventChannel ?? const EventChannel(eventChannelName);

    static const String methodChannelName = 'com.daftary.daftary/sms';
    static const String eventChannelName = 'com.daftary.daftary/sms/shared_text';
    // ...
  }
  ```

  It is registered on every platform. Constructing it does nothing; only a call touches the channel, and on iOS/macOS nothing calls it.
- Generated code: injectable emits `final smsPlatformModule = _$SmsPlatformModule();` next to `registerModule`/`aIHttpModule`/`appLockModule` (`injection.config.dart:685-687`) and `gh.lazySingleton<SmsInboxGateway>(() => smsPlatformModule.smsInboxGateway(gh<SmsChannelClient>()))`. Regenerate with `fvm dart run build_runner build --delete-conflicting-outputs` (T069 owns this).
- `GetSmsCapability` (domain) only asks `SmsInboxGateway.getCapability()`. It must **not** evaluate `Platform.isAndroid`. The `&& Platform.isAndroid` half of the formula is realized by this module (iOS/macOS get `Unavailable*`, which return `available: false`), and the `readSmsDeclared` half by the Android adapter. **Flag:** domain-interfaces.md:16 and sms-platform-channel.md §2.1 write the formula as if one place computes both. Do not put it in the domain.
- If the selection itself needs a unit test, extract a pure top-level `T selectForPlatform<T>({required bool isAndroid, required T Function() android, required T Function() other})` and test that function. Do not try to fake `Platform.isAndroid`.

## Existing registrations referenced by the tasks

| Service | Annotation | Generated (`injection.config.dart`) |
|---|---|---|
| `PlatformScreenshotProtectionService` → `ScreenshotProtectionService` | `@LazySingleton(as: ScreenshotProtectionService)` at `lib/core/security/screenshot_protection_service.dart:35`; channels via `@ignoreParam` (`:38-42`) | `:782-783`: `gh.lazySingleton<ScreenshotProtectionService>(() => PlatformScreenshotProtectionService())`. One impl on every platform, no platform split. |
| `SecureCredentialStoreImpl` → `SecureCredentialStore` (AI key) | `@LazySingleton(as: SecureCredentialStore)` at `lib/features/ai_assistant/data/datasources/secure_credential_store_impl.dart:15`; takes the shared `FlutterSecureStorage` | `:776-777` |
| `FlutterSecureStorage` (shared by cloud session, AI key, App Lock PIN) | `RegisterModule.secureStorage` getter, `@lazySingleton` at `register_module.dart:95-100`; only `iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)`, **no `AndroidOptions`** | `:701-702` |
| `AppLifecycleObserver` | `@lazySingleton` + `@disposeMethod` (`app_lifecycle_observer.dart:28,159`) | `:1107-1110` with `dispose: (i) => i.dispose()` |
| `NotificationRecomputeTrigger`, `NotificationTapRouter` | `@lazySingleton` | `:2101`, `:2219` |

There is **no** `@Named`/`instanceName` registration anywhere in `lib/` (`grep -rn "@Named(" lib` returns nothing).

## Side flag for T039 (dedicated secure storage, analysis M7)

T039 says to use "the same platform options as `register_module.dart:96-100` but `resetOnError: false`, registered under its own DI name". Facts:

- `flutter_secure_storage` 11.2.0 (`pubspec.lock:523-530`): `AndroidOptions({bool resetOnError = true, ..., String? storageNamespace, String? preferencesKeyPrefix})` (`~/.pub-cache/.../flutter_secure_storage-11.2.0/lib/options/android_options.dart:50-66`). The app's shared instance passes no `AndroidOptions`, so it runs with `resetOnError: true` on Android.
- A second instance with **no** `storageNamespace` shares the default Android backing store (data SharedPreferences, KeyStore alias, wrapped key) with the app's instance. `resetOnError: false` on the SMS instance only stops the SMS instance from triggering a reset; a reset triggered by the **shared** instance (`resetOnError: true`) would still erase the SMS keys. `storageNamespace` "provides full namespace isolation ... Data SharedPreferences, config/algorithm markers, Android KeyStore aliases, wrapped-key SharedPreferences" (`android_options.dart:200-213`). **Recommendation:** `AndroidOptions(resetOnError: false, storageNamespace: 'daftary_sms_import')` plus the same `IOSOptions` as the shared instance. On iOS, keychain items are per key, so `accountName` isolation is optional.
- Two ways to give it "its own" registration without adding a new DI style:
  1. **Preferred (precedent):** do not register a second `FlutterSecureStorage`. `SecureStorageSmsKeyStore` builds its own instance through an `@ignoreParam FlutterSecureStorage? storage` constructor parameter with a `const FlutterSecureStorage(aOptions: ..., iOptions: ...)` default, exactly as `PlatformScreenshotProtectionService` defaults its channels. Tests pass an in-memory fake.
  2. `@Named('smsImportSecureStorage')` on a second `RegisterModule`/`SmsPlatformModule` getter, with `@Named(...)` on the constructor parameter. Supported by injectable 3.x, but it would be the first named registration in the app.
- `SecureStorageWiper.wipe()` (`delete_all_user_data.dart:68`, impl `lib/features/app_lock/data/services/app_lock_secure_storage_wiper.dart:22-45`) snapshots and then deletes App Lock keys only. Its `deleteAll()` loops `_storage.delete(key: ...)` over App Lock's own `allKeys` (`lib/features/app_lock/data/datasources/secure_app_lock_storage.dart:138-142`), never `FlutterSecureStorage.deleteAll()`. So delete-all does **not** remove the SMS keys by accident. `PurgeSmsImportKeys` must delete them explicitly (data-model §10).

## DI tests to copy

- `test/core/di/ai_assistant_di_test.dart:18-44`: `configureDependencies()`, swap `AppDatabase` for an in-memory one, resolve the feature graph, `getIt.reset()` in tearDown. T069 can clone it as `test/features/sms_import/di/sms_import_di_test.dart` and assert `getIt<SmsInboxGateway>()` is `UnavailableSmsInboxGateway` on the host platform.
- `test/core/sync/table_classification_guard_test.dart:39-51` also calls `configureDependencies()`, so any constructor in the SMS graph that throws at construction breaks this unrelated test.
