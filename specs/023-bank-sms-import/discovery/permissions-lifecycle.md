# Discovery T006: permissions, lifecycle, App Lock, startup, screen protection

Read-only notes for T065 (`AppLockStatus`, `AppExternalActivityRunner`, lifecycle-state source), the permission use cases (`GetSmsPermissionStatus`, `RequestSmsPermission`, `OpenSmsAppInfo`), `SmsCatchUpTrigger`, `SharedTextRouter`, the `main.dart` startup change, and the `MainActivity.kt` registration. Anchors are at commit `4a5565d` plus the working tree on `023-bank-sms-import`.

## Flags: where the plan or contracts are wrong or imprecise

| # | Claim | Reality | What to do |
|---|---|---|---|
| L1 | "the trigger waits for a post-frame callback before reading `isLocked`" (plan.md:271, :451, :601; domain-interfaces.md:319). Accept of T006: "the exact post-frame point at which `isLocked` becomes reliable" | **No frame-based point exists on resume.** In the slow path, `_onResumed` decides the lock only after `_status.lockTimeoutIfEnabled()` completes (`app_lifecycle_observer.dart:143-148`). That is a secure-storage platform read (`RepositoryAppLockStatusProvider.lockTimeoutIfEnabled` → `AppLockRepository.getConfig`, `repository_app_lock_status_provider.dart:20-28`), which can finish after one or more frames. A post-frame callback narrows the window but does not close it. See section 3.3 for exactly when `isLocked` is final. | Treat post-frame as "best effort", and make the design safe without it: (1) `await WidgetsBinding.instance.endOfFrame` before the first `isLocked` read; (2) listen to `isLocked` and cancel the scan token as soon as it becomes `true`; (3) re-check between pages (already planned). A catch-up only stages sealed rows and shows nothing, so a page that runs before a late lock leaks nothing. A real "lock decision settled" signal would require editing `AppLifecycleObserver`, which plan.md:147 says stays untouched. Needs orchestrator approval if anyone wants it. |
| L2 | "`SharedTextRouter` ... routes after unlock (precedent `NotificationTapRouter`)" (plan.md:131) | `NotificationTapRouter` does **not** wait for unlock. It calls `router.go(...)` immediately, for both warm and cold taps (`notification_tap_router.dart:37-42,49-58`). It relies on `AppLockGate` keeping the routed child mounted but offstage while locked (`app_lock_gate.dart:11-15`). | `SharedTextRouter` copies the `start(GoRouter)`/idempotent/`dispose` shape, but adds its own wait on `LockStatus` before calling `go` (domain-interfaces.md:321 requires the wait). Even if that wait races (L1), the paste page would only mount under the lock screen and would not be painted. |
| L3 | "secure-flag screen protection on list, review and paste" (plan.md:300). Accept of T006: "how a route or page opts into secure-flag protection" | **No per-route opt-in exists.** Protection is app-wide and always on: `main.dart:34-38` calls `ScreenshotProtectionService.enable()` once before startup, and Android sets `FLAG_SECURE` on the whole activity window (`SecurityPlugin.kt:86-93`). ui-contract.md:5 already says this correctly. | SMS pages do nothing to opt in. They must never call `ScreenshotProtectionService.disable()` or import that service. A guard test should grep `lib/features/sms_import` for `ScreenshotProtectionService`. |
| L4 | FR-079 coverage on macOS | macOS has **no** `SecurityPlugin` (`macos/Runner/` has no plugin file, and only iOS registers one, `ios/Runner/AppDelegate.swift:20-23`). The Dart service swallows `MissingPluginException` (`screenshot_protection_service.dart:85-87`), so macOS has no capture protection. This was already true before this feature. | No change (briefing rule 10: no native iOS/macOS work). Record it as a known pre-existing gap. On macOS the SMS pages are covered by App Lock only. |
| L5 | `app_settings` "imported `as app_settings` because its `AppSettings` collides with the Drift `AppSettings` data class" (plan.md:19, :250) | Correct only where `app_database.dart` is imported without a prefix. The one existing user, `notification_settings_page.dart:1`, imports `package:app_settings/app_settings.dart` **unprefixed** (no Drift import there). The Drift **table** class is `AppSettings` (`app_database.dart:517`) and its data class is `AppSetting` (`app_database.g.dart:2790`). `app_database.dart` re-exports `package:drift/drift.dart` (`:4`). | Keep the `as app_settings` prefix in `PlatformSmsPermissionService`, because data-layer files often import `app_database.dart`. Harmless either way. |
| L6 | "`RequestSmsPermission` wraps `requestPermission()` in `runExternalActivity`" | The existing notification-permission request is **not** wrapped (`notification_settings_cubit.dart` → `RequestNotificationPermission.call()` → `_scheduler.requestPermission()`, `request_notification_permission.dart:26-29`). A runtime-permission dialog is a translucent activity. `MainActivity` gets `onPause` but not `onStop`, which Flutter reports as `inactive`, and `AppLifecycleObserver` ignores `inactive` (`:103-107`). | Wrapping is harmless and keeps the contract. Do it, but do not rely on it for anything. The `dialogShown` inference in Kotlin (contract §2.3) uses the native `onPause`, not the Flutter lifecycle. |
| L7 | Manifest `tools:node="remove"` markers (plan.md:251) | `android/app/src/main/AndroidManifest.xml:1` declares only `xmlns:android`. There is no `xmlns:tools`. | The manifest task must add `xmlns:tools="http://schemas.android.com/tools"` to `<manifest>` before using `tools:node`. |

## 1. Notification permission: the prompt-free `refresh()` template

`lib/features/insights_notifications/domain/usecases/request_notification_permission.dart`

- `@injectable class RequestNotificationPermission` (`:17-18`), deps `NotificationScheduler` + `NotificationPreferenceRepository` (`:19-22`).
- `call()` (`:26-29`): the only path that prompts; `_scheduler.requestPermission()` then `_persist`.
- `refresh()` (`:34-37`): `_scheduler.hasPermission()` (never prompts) then `_persist`.
- `_persist(bool granted)` (`:39-49`): read stored, write only when it differs.

Callers:
- `NotificationSettingsCubit.load()` refreshes first (`notification_settings_cubit.dart:27-38`). `refreshPermission()` (`:43-50`) ignores failures and only updates `state.preference`.
- The page re-checks on resume through `WidgetsBindingObserver` (`notification_settings_page.dart:58-79`):

```dart
class _NotificationSettingsViewState extends State<NotificationSettingsView>
    with WidgetsBindingObserver {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }

  /// Returning from device settings may have granted or revoked permission
  /// (FR-012) — re-check live, never prompting.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationSettingsCubit>().refreshPermission();
    }
  }
```

Mapping for SMS: `GetSmsPermissionStatus` = `refresh()` (calls `SmsPermissionService.getStatus()` → `getPermissionState`, never prompts). The SMS settings/hub page re-checks on `resumed` in the same way (FR-070). `RequestSmsPermission` = `call()`, the only caller of `SmsPermissionService.request()`.

## 2. `app_settings` (App info deep link)

- Package `app_settings` 9.0.0 (`pubspec.yaml:58`, `pubspec.lock:60`).
- The only existing use is `notification_settings_page.dart:26-27`:

  ```dart
  Future<void> openDeviceNotificationSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);
  ```

  It is injected into the view as `onOpenDeviceSettings` so widget tests never hit the channel (`:44-51`).
- API: `static Future<void> openAppSettings({AppSettingsType type = AppSettingsType.settings, bool asAnotherTask = false})` (`app_settings-9.0.0/lib/src/app_settings.dart:9-15`). On Android the default `settings` type opens `Settings.ACTION_APPLICATION_DETAILS_SETTINGS` (`AppSettingsPlugin.kt:102,149`), which is the App info screen the restricted-settings guidance needs.
- Method channel `com.spencerccf.app_settings/methods`, method `openSettings` (`app_settings_method_channel.dart:11-23`). Mock it with `TestDefaultBinaryMessengerBinding` in the `PlatformSmsPermissionService` test.
- Snippet for `PlatformSmsPermissionService.openAppInfo()`:

  ```dart
  import 'package:app_settings/app_settings.dart' as app_settings;
  // ...
  @override
  Future<Either<Failure, Unit>> openAppInfo() async {
    try {
      await app_settings.AppSettings.openAppSettings();
      return const Right(unit);
    } on Exception {
      // Map to a fixed-token SmsImportFailure. Never pass e.toString().
      return const Left(SmsAppInfoUnavailableFailure());
    }
  }
  ```

- Not wrapped in `runExternalActivity` (contract §2.3, last paragraph). Leaving for Settings is a real `paused`, so the user's lock timeout applies on return (with "Immediately", they come back to the lock screen). This is intended.

## 3. `AppLifecycleObserver` (App Lock timing)

`lib/core/security/app_lifecycle_observer.dart`, `@lazySingleton class AppLifecycleObserver with WidgetsBindingObserver` (`:28-29`), generated at `injection.config.dart:1107-1110`.

### 3.1 API the SMS adapters wrap (T065)

| Member | Anchor | Notes |
|---|---|---|
| `ValueListenable<bool> get isLocked` | `:57-58` (backing `ValueNotifier` `:41`) | `true` while the lock screen covers the app. No `Stream`: the `LockStatus.changes` adapter must convert listener callbacks to a broadcast stream and remove the listener on cancel. |
| `Future<void> initialize()` | `:64-70` | Adds the binding observer once (`:65-68`). **Cold-launch lock** at `:69`: `if (await _status.lockTimeoutIfEnabled() != null) lock();` |
| `void lock()` / `void unlock()` | `:73-82` | Only the lock screen calls `unlock`. |
| `Future<T> runExternalActivity<T>(Future<T> Function() action)` | `:87-94` | A depth counter. While it is above 0, `_onPaused` returns early (`:112`), so a `paused` caused by the action does not start the inactivity timer. It suppresses **only** `paused` handling, not `resumed`. |
| `didChangeAppLifecycleState` | `:96-109` | `paused` → `_onPaused`, `resumed` → `_onResumed`; `inactive`/`hidden`/`detached` ignored. |

`AppExternalActivityRunner` adapter (T065):

```dart
@LazySingleton(as: ExternalActivityRunner)
class AppExternalActivityRunner implements ExternalActivityRunner {
  AppExternalActivityRunner(this._observer);
  final AppLifecycleObserver _observer;
  @override
  Future<T> run<T>(Future<T> Function() action) =>
      _observer.runExternalActivity(action);
}
```

Lifecycle-state source adapter: the precedent for reading the current state is `lock_screen_page.dart:73-75`, which treats `null` as foreground:

```dart
final state = WidgetsBinding.instance.lifecycleState;
return state == null || state == AppLifecycleState.resumed;
```

### 3.2 Lock paths

- **Paused** (`_onPaused`, `:111-130`): records `_pausedAt`, then **asynchronously** reads the timeout. With timeout `<= 0` ("Immediately") it calls `lock()` as soon as the read resolves, while still in the background (`:123-124`). Otherwise it starts the timer (`:126`).
- **Resumed** (`_onResumed`, `:132-149`): cancels the timer, bumps the generation, returns if already locked (`:137`).
  - Read already resolved: decides **synchronously** (`:139-141`).
  - Read not resolved yet (background shorter than the secure-storage read): decides **asynchronously** in the `.then` at `:143-148`. This is the race the plan cites.

### 3.3 When `isLocked` is final

1. **Cold launch: final once startup is ready.** `AppStartupCubit._runSteps` awaits `_appLock.initialize()` (`app_startup_cubit.dart:120-126`) before it emits `ready` (`:127`). So inside the `startup.whenReady.then((_) { if (!startup.state.isReady) return; ... })` block in `main.dart:49-58`, `isLocked` already reflects the cold-launch rule. A catch-up started from there can read it directly, with no post-frame wait.
2. **Resume, fast path: final before any later observer runs.** `WidgetsBinding.handleAppLifecycleStateChanged` notifies observers in registration order (`flutter/lib/src/widgets/binding.dart:1330-1334`, Flutter 3.47.0). `AppLifecycleObserver` registers in `initialize()` during startup, before anything that `main.dart` starts in `whenReady` (including `AppLifecycleListener`s, which are also binding observers). So if the timeout read had resolved, `lock()` has already run when the SMS trigger's `resumed` callback fires.
3. **Resume, slow path: final only after a platform read.** Only when the app was backgrounded for less than the secure-storage read latency **and** the timeout is "Immediately" (a non-zero timeout cannot be reached in that time) does the lock land after the `.then` at `:145-147`, at an unknown frame. Use the L1 mitigation: `await WidgetsBinding.instance.endOfFrame`, then read `isLocked`, keep a listener that cancels the scan on `true`, and re-check between pages.

Test helpers: `test/core/security/app_lifecycle_observer_test.dart:11-36` (`FakeStatusProvider`, `FakeAsync`, building the observer with an injected timer factory and clock). The SMS tests should use the `FakeLockStatus` port fake (T034) rather than the real observer.

## 4. `NotificationTapRouter` (shape for `SharedTextRouter`)

`lib/core/routing/notification_tap_router.dart`

- `@lazySingleton` (`:28`), deps `NotificationScheduler`, `HandleNotificationTap` (`:30-33`); generated `injection.config.dart:2219`.
- `Future<void> start(GoRouter router)` (`:37-42`): idempotent through `_subscription != null`. It subscribes to warm taps first, then handles the cold-launch target once (`launchTarget()`).
- `dispose()` (`:44-47`).
- Routes with `router.go(path)` (`:53-55`), with no unlock wait (L2).
- `appScaffoldMessengerKey` (`:15-16`) is the context-free snackbar channel, if `SharedTextRouter` needs to show "too long" or "nothing recognized" without a page.

`SharedTextRouter` skeleton following that shape plus the unlock wait:

```dart
@lazySingleton
class SharedTextRouter {
  SharedTextRouter(this._source, this._inbox, this._lock);

  final SharedTextSource _source;
  final SharedTextInbox _inbox;     // in-memory holder, never a URL
  final LockStatus _lock;
  StreamSubscription<SharedText>? _subscription;

  /// Idempotent. Warm shares first, then the one cold-start share.
  Future<void> start(GoRouter router) async {
    if (_subscription != null) return;
    _subscription = _source.stream.listen((text) => _open(router, text));
    final initial = await _source.takeInitial();
    if (initial != null) await _open(router, initial);
  }

  Future<void> _open(GoRouter router, SharedText text) async {
    _inbox.put(text);
    if (_lock.isLocked) {
      await _lock.changes.firstWhere((locked) => !locked);
    }
    router.go(BankMessagesRoutes.paste);   // no text in the URL (FR-079)
  }

  Future<void> dispose() async { await _subscription?.cancel(); _subscription = null; }
}
```

## 5. `main.dart` startup block

`lib/main.dart:49-58`:

```dart
  unawaited(
    startup.whenReady.then((_) {
      if (!startup.state.isReady) return;
      getIt<NotificationRecomputeTrigger>().start();
      unawaited(getIt<NotificationTapRouter>().start(appRouter));
      // 021: cloud sync starts only once startup is ready. It initializes
      // Supabase lazily, and never when unconfigured or switched off.
      unawaited(getIt<SyncScheduler>().start());
    }),
  );
```

Insert after the `SyncScheduler` line (`:56`), and add the two imports next to `:19` (the `notification_recompute_trigger.dart` import):

```dart
      // 023: bank SMS import. Started only once startup is ready, so the
      // cold-launch App Lock state is already settled. The catch-up checks
      // capability, enablement and permission itself, so it is a no-op on
      // iOS/macOS and in a build without READ_SMS. Shared text is routed
      // only after unlock.
      getIt<SmsCatchUpTrigger>().start();
      unawaited(getIt<SharedTextRouter>().start(appRouter));
```

- `appRouter` is the global `GoRouter` (`lib/core/routing/app_router.dart:81`), already imported (`main.dart:12`).
- `configureDependencies()` runs at `:33` (registration only). `ScreenshotProtectionService.enable()` runs at `:38`, before startup.
- `SmsCatchUpTrigger` template: `NotificationRecomputeTrigger` (`lib/features/insights_notifications/presentation/notification_recompute_trigger.dart`): `@lazySingleton ... with WidgetsBindingObserver` (`:28-29`), idempotent `start()` that adds the observer and kicks a first run (`:45-50`), `dispose()` (`:54-58`), `resumed` → `runIfDue()` (`:60-63`), single-flight `_inFlight ??= ...whenComplete(() => _inFlight = null)` (`:69-71`), never throws (`:73-84`). The other lifecycle style in use is `AppLifecycleListener(onResume: ..., onPause: ...)` (`sync_scheduler.dart:103-107`, `lock_screen_page.dart:55-65`). Either is fine. Pick the `WidgetsBindingObserver` one to match the trigger precedent.

## 6. Screen-capture protection

- Port: `abstract class ScreenshotProtectionService` with `enable`, `disable`, `isScreenCaptured`, `screenCaptureChanges` (`lib/core/security/screenshot_protection_service.dart:12-27`). Impl `PlatformScreenshotProtectionService` (`:35-95`), channels `com.daftary.daftary/security` and `.../security/recording` (`:44-46`).
- Enabled once, unconditionally, at `main.dart:38` (comment `:34-37`). It is not a user toggle (`security_settings_page.dart:23`), and `DisableAppLock` deliberately leaves it on (`disable_app_lock.dart:11`).
- Android: `SecurityPlugin.applyFlag()` adds `FLAG_SECURE` to the attached activity's window (`SecurityPlugin.kt:86-93`) and re-applies it on (re)attach (`:101-114`). The flag covers screenshots, recording, casting and the recents thumbnail (class doc `:12-41`).
- iOS: `ios/Runner/SecurityPlugin.swift`, registered by hand in `AppDelegate.swift:20-23`. Blur cover on resign-active and during recording (`lib/core/security/app_switcher_placeholder.dart:1-26`).
- macOS: none (L4).
- **How a page opts in: it does not need to.** Every route sits in `MainActivity`'s flagged window and under `AppLockGate` (`main.dart:141-145`). The `ShareTargetActivity` trampoline is a separate, unflagged window, so it must **never** set a content view or render the shared text. It reads `EXTRA_TEXT`, hands it to the holder, starts `MainActivity` and calls `finish()` in `onCreate` (contract §2.5). `noHistory` and `excludeFromRecents` keep it out of the recents list.

## 7. `MainActivity.kt` and plugin registration

`android/app/src/main/kotlin/com/daftary/daftary/MainActivity.kt`

- `class MainActivity : FlutterFragmentActivity()` (`:12`), required by `local_auth`. A `FragmentActivity` accepts only 16-bit request codes, and the contract's `0x5A11` fits.
- `configureFlutterEngine` (`:24-29`):

```kotlin
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // In-app plugin (research.md Decision 1): FLAG_SECURE toggling for
        // the always-on screenshot/recording protection (FR-020/FR-021).
        flutterEngine.plugins.add(SecurityPlugin())
        // 023: bank SMS import. Registered in every build: sharing needs no
        // permission, and without READ_SMS the inbox/permission methods
        // answer `unavailable` (sms-platform-channel.md).
        flutterEngine.plugins.add(SmsPlugin())
    }
```

  Only add the last line and its comment. `onCreate` (`:13-22`) and the launch mode stay untouched.
- Manifest (`android/app/src/main/AndroidManifest.xml`): `MainActivity` is at `:35-56`, with `launchMode="singleTop"` (`:38`) and `taskAffinity=""` (`:39`), and its only intent filter is `MAIN/LAUNCHER` (`:52-55`). The other declared activity is `UCropActivity` (`:71-74`). Permissions are at `:5-28`, with no SMS permissions today. `xmlns:tools` is missing (L7).
- `SmsPlugin` should copy the `ActivityAware` shape of `SecurityPlugin.kt`: channels created in `onAttachedToEngine` and nulled in `onDetachedFromEngine` (`:53-67`); `activity` set or cleared in `onAttachedToActivity`, `onDetachedFromActivityForConfigChanges`, `onReattachedToActivityForConfigChanges` and `onDetachedFromActivity` (`:101-119`). In addition, `SmsPlugin` keeps the `ActivityPluginBinding` so it can `addRequestPermissionsResultListener` on attach and `removeRequestPermissionsResultListener` on detach and on config-change detach. `SecurityPlugin` has no logging calls. `SmsPlugin` must have none either (briefing rule 6, static guard T067).
