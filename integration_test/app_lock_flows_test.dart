import 'dart:async';

import 'package:daftary/core/database/app_database.dart' hide isNotNull, isNull;
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/core/security/screenshot_protection_service.dart';
import 'package:daftary/features/app_lock/data/datasources/secure_app_lock_storage.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/presentation/cubit/lock_screen_cubit.dart';
import 'package:daftary/features/app_lock/presentation/pages/forgot_pin_page.dart';
import 'package:daftary/features/app_lock/presentation/pages/lock_screen_page.dart';
import 'package:daftary/features/app_lock/presentation/pages/pin_setup_page.dart';
import 'package:daftary/features/app_lock/presentation/pages/security_settings_page.dart';
import 'package:daftary/features/app_lock/presentation/pages/wipe_confirmation_page.dart';
import 'package:daftary/features/app_lock/presentation/widgets/lockout_countdown_banner.dart';
import 'package:daftary/features/dashboard/presentation/pages/home_page.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/settings/presentation/pages/settings_page.dart';
import 'package:daftary/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 015 T081 — quickstart.md's manual scenarios 1-6 end-to-end against the
/// real app shell (real DI graph, real router, real `AppLockGate`, real
/// Cubits, use cases, repository and `SecureAppLockStorageImpl`), with only
/// the OS-facing seams replaced:
///
/// - `FlutterSecureStorage` → the package's in-memory test platform
///   (`setMockInitialValues`), never the real Keychain/Keystore. It
///   survives a simulated relaunch (a fresh GetIt graph) within one test;
/// - `AppDatabase` → an in-memory drift database, so the Forgot-PIN wipe
///   runs the real canonical `DeleteAllUserData` without touching the
///   device's real data;
/// - `BiometricService` → [FakeBiometricService] (no OS prompts);
/// - the SecurityPlugin `MethodChannel` → a recording mock handler;
/// - time → one [TestClock] shared by `AppLifecycleObserver`,
///   `AppLockRepositoryImpl` and `LockScreenCubit`, and a manual
///   inactivity-timer factory ([ManualTimers]);
/// - app lifecycle → driven through
///   `tester.binding.handleAppLifecycleStateChanged`, exactly as the engine
///   would deliver it;
/// - PIN hashing → `Pbkdf2PinHasher(iterations: 5)` run inline.
///
/// While the (simulated) app is `hidden`/`paused` the binding disables
/// frames, so those phases wait on the event loop instead of pumping.
///
/// What this cannot cover: the native side of US5 (FLAG_SECURE / the iOS
/// privacy cover and recording overlay) — only that Dart turns protection
/// on at startup and never turns it off. That part stays a manual check
/// (quickstart.md Scenario 5).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const correctPin = '1234';
  const wrongPin = '9999';
  const securityChannel = MethodChannel(
    PlatformScreenshotProtectionService.methodChannelName,
  );

  late TestClock clock;
  late ManualTimers timers;
  late FakeBiometricService biometrics;
  late List<String> screenshotCalls;
  late AppLocalizations l10n;
  AppDatabase? db;

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    // A fresh, empty in-memory keychain per test.
    FlutterSecureStorage.setMockInitialValues({});
    clock = TestClock();
    timers = ManualTimers();
    biometrics = FakeBiometricService();
    screenshotCalls = [];
    db = null;
    messenger().setMockMethodCallHandler(securityChannel, (call) async {
      screenshotCalls.add(call.method);
      return call.method == 'isCaptured' ? false : null;
    });
  });

  tearDown(() async {
    messenger().setMockMethodCallHandler(securityChannel, null);
    await getIt.reset();
    await db?.close();
  });

  AppLockRepository repository() => getIt<AppLockRepository>();

  /// App Lock's persisted state written straight through the real storage
  /// stack, before the app boots — like a user who set it up last week.
  Future<void> configureAppLock({
    String pin = correctPin,
    bool biometric = false,
    InactivityTimeout timeout = InactivityTimeout.after1min,
  }) async {
    final repo = AppLockRepositoryImpl(
      SecureAppLockStorageImpl(const FlutterSecureStorage()),
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      clock: clock.call,
      runPinWork: runPinWorkInline,
    );
    (await repo.setPin(pin)).getOrElse((f) => throw StateError('$f'));
    (await repo.enableAppLock()).getOrElse((f) => throw StateError('$f'));
    (await repo.setInactivityTimeout(
      timeout,
    )).getOrElse((f) => throw StateError('$f'));
    if (biometric) {
      (await repo.setBiometricEnabled(
        true,
      )).getOrElse((f) => throw StateError('$f'));
    }
  }

  /// Boots the app the way `main()` does, over a fresh GetIt graph. With
  /// [relaunch] the in-memory database and keychain from the previous boot
  /// are kept — a cold relaunch of the same install.
  Future<void> bootApp(
    WidgetTester tester, {
    String location = '/overview',
    bool relaunch = false,
  }) async {
    // A phone-sized surface (390x844 logical), whatever the host window.
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Tear the previous "process" down completely before a relaunch, so no
    // page or Cubit from it survives into the new one.
    await tester.pumpWidget(const SizedBox.shrink());
    await getIt.reset();
    await configureDependencies();
    final database = relaunch && db != null
        ? db!
        : AppDatabase.forTesting(NativeDatabase.memory());
    db = database;
    getIt
      ..unregister<AppDatabase>()
      ..registerSingleton<AppDatabase>(database)
      ..unregister<BiometricService>()
      ..registerSingleton<BiometricService>(biometrics)
      ..unregister<PinHasher>()
      ..registerLazySingleton<PinHasher>(() => Pbkdf2PinHasher(iterations: 5))
      ..unregister<AppLockRepository>()
      ..registerLazySingleton<AppLockRepository>(
        () => AppLockRepositoryImpl(
          getIt<SecureAppLockStorage>(),
          getIt<PinHasher>(),
          getIt<LockoutPolicy>(),
          clock: clock.call,
          runPinWork: runPinWorkInline,
        ),
      )
      ..unregister<AppLifecycleObserver>()
      ..registerLazySingleton<AppLifecycleObserver>(
        () => AppLifecycleObserver(
          getIt(),
          clock: clock.call,
          timerFactory: timers.create,
        ),
        dispose: (observer) => observer.dispose(),
      )
      ..unregister<LockScreenCubit>()
      ..registerFactory<LockScreenCubit>(
        () => LockScreenCubit(
          getIt(),
          getIt(),
          getIt(),
          getIt(),
          getIt(),
          getIt(),
          clock: clock.call,
        ),
      );

    if (!relaunch) {
      // A person on record keeps the onboarding gate out of the way.
      (await getIt<PeopleRepository>().createPerson(
        name: 'Lock Seed',
      )).getOrElse((f) => throw StateError('seed person failed: $f'));
    }

    // Same startup sequence as main().
    await getIt<SettingsCubit>().initialize();
    await getIt<SettingsCubit>().changeLanguage(AppLanguage.english);
    await getIt<OnboardingCubit>().initialize();
    await getIt<ScreenshotProtectionService>().enable();
    await getIt<AppLifecycleObserver>().initialize();

    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    appRouter.go(location);
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  bool isLocked() => getIt<AppLifecycleObserver>().isLocked.value;

  Future<int> peopleCount() async =>
      (await db!.select(db!.people).get()).length;

  /// Scrolls [finder] into view first: the lock screen scrolls on short
  /// windows.
  Future<void> tapOn(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tapOn(tester, find.byKey(Key('pin_pad.digit.$digit')));
      await tester.pump();
    }
    await tapOn(tester, find.byKey(const Key('pin_pad.submit')));
    await tester.pumpAndSettle();
  }

  bool pinPadEnabled(WidgetTester tester) =>
      tester.widget<InkWell>(find.byKey(const Key('pin_pad.digit.1'))).onTap !=
      null;

  /// Frames are disabled while hidden/paused; let the observer's async
  /// timeout read complete on the event loop instead.
  Future<void> letAsyncWorkRun() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  /// Home button: the full resumed → paused sequence the engine delivers.
  Future<void> sendToBackground(WidgetTester tester) async {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await letAsyncWorkRun();
  }

  Future<void> returnToForeground(WidgetTester tester) async {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await letAsyncWorkRun();
    await tester.pumpAndSettle();
  }

  void expectLockScreen() {
    expect(find.byType(LockScreenPage), findsOneWidget);
    expect(isLocked(), isTrue);
  }

  void expectUnlocked() {
    expect(find.byType(LockScreenPage), findsNothing);
    expect(isLocked(), isFalse);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('US1 — PIN lock', () {
    testWidgets('Scenario 1.1-1.3: off by default; enabling sets a PIN twice, '
        'a mismatched confirmation is retried without losing the first '
        'entry', (tester) async {
      await bootApp(tester, location: '/settings/security');

      expectUnlocked();
      expect(find.byType(SecuritySettingsPage), findsOneWidget);
      final toggle = find.widgetWithText(
        SwitchListTile,
        l10n.appLockSettingsToggleTitle,
      );
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(PinSetupPage), findsOneWidget);
      expect(find.text(l10n.appLockPinEnterNewPrompt), findsOneWidget);

      await enterPin(tester, correctPin);
      expect(find.text(l10n.appLockPinConfirmNewPrompt), findsOneWidget);
      await enterPin(tester, '5678');
      expect(find.text(l10n.appLockPinMismatch), findsOneWidget);
      // Still on the confirmation step: the first entry was kept.
      expect(find.text(l10n.appLockPinConfirmNewPrompt), findsOneWidget);

      await enterPin(tester, correctPin);
      expect(find.byType(PinSetupPage), findsNothing);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      final config = (await repository().getConfig()).getOrElse(
        (f) => throw StateError('$f'),
      );
      expect(config.isEnabled, isTrue);
      expect(config.inactivityTimeout, InactivityTimeout.after1min);
      // Enabling does not lock the user out of the screen they're on.
      expectUnlocked();
    });

    testWidgets('Scenario 1.4-1.6: a cold launch is locked before any content '
        'shows; a wrong PIN is rejected; the right one unlocks to the same '
        'screen', (tester) async {
      await configureAppLock();
      await bootApp(tester, location: '/settings');

      expectLockScreen();
      expect(find.byType(SettingsPage), findsNothing);
      // Still mounted underneath (navigation state survives), just hidden.
      expect(find.byType(SettingsPage, skipOffstage: false), findsOneWidget);

      await enterPin(tester, wrongPin);
      expect(find.text(l10n.appLockLockIncorrectPin), findsOneWidget);
      expectLockScreen();

      await enterPin(tester, correctPin);
      expectUnlocked();
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('resuming within the timeout does not lock; past it (or once '
        'the inactivity timer fires) it does, and unlocking returns to the '
        'same screen', (tester) async {
      await configureAppLock(timeout: InactivityTimeout.after1min);
      await bootApp(tester, location: '/settings');
      await enterPin(tester, correctPin);
      expectUnlocked();

      await sendToBackground(tester);
      clock.advance(const Duration(seconds: 30));
      await returnToForeground(tester);
      expectUnlocked();

      await sendToBackground(tester);
      clock.advance(const Duration(seconds: 61));
      await returnToForeground(tester);
      expectLockScreen();
      await enterPin(tester, correctPin);
      expectUnlocked();
      expect(find.byType(SettingsPage), findsOneWidget);

      // The in-process inactivity timer, for OSes that keep the app alive.
      await sendToBackground(tester);
      expect(timers.pending, 1);
      timers.fireAll();
      await returnToForeground(tester);
      expectLockScreen();
    });

    testWidgets('brief interruptions and the app\'s own external activities '
        'never lock, even with the "Immediately" timeout', (tester) async {
      await configureAppLock(timeout: InactivityTimeout.immediately);
      await bootApp(tester);
      await enterPin(tester, correctPin);
      expectUnlocked();

      // Permission dialog / incoming-call banner: `inactive` only.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await letAsyncWorkRun();
      clock.advance(const Duration(minutes: 10));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expectUnlocked();

      // The app's own share sheet / photo picker fully backgrounds it.
      await getIt<AppLifecycleObserver>().runExternalActivity(() async {
        await sendToBackground(tester);
        clock.advance(const Duration(minutes: 10));
        await returnToForeground(tester);
      });
      expectUnlocked();

      // A genuine backgrounding, however short, locks immediately.
      await sendToBackground(tester);
      await returnToForeground(tester);
      expectLockScreen();
    });
  });

  group('US2 — biometric unlock', () {
    testWidgets('Scenario 2.2-2.3: the prompt opens by itself and a success '
        'unlocks with no PIN', (tester) async {
      await configureAppLock(biometric: true);
      biometrics
        ..available = true
        ..succeed = true;
      await bootApp(tester);

      expect(biometrics.prompts, 1);
      expectUnlocked();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('Scenario 2.4: a failed/cancelled prompt offers retry or PIN '
        'and never counts toward the PIN lockout', (tester) async {
      await configureAppLock(biometric: true);
      biometrics
        ..available = true
        ..succeed = false;
      await bootApp(tester);

      expectLockScreen();
      expect(biometrics.prompts, 1);
      expect(find.text(l10n.appLockLockBiometricFailed), findsOneWidget);
      expect(find.byKey(const Key('lock_screen.biometric')), findsOneWidget);

      await tapOn(tester, find.byKey(const Key('lock_screen.biometric')));
      await tester.pumpAndSettle();
      expect(biometrics.prompts, 2);
      expect(
        (await repository().getLockoutState())
            .getOrElse((f) => throw StateError('$f'))
            .consecutiveFailedAttempts,
        0,
      );

      // Two biometric failures consumed no slot: 4 wrong PINs, no cooldown…
      for (var i = 0; i < 4; i++) {
        await enterPin(tester, wrongPin);
      }
      expect(find.byType(LockoutCountdownBanner), findsNothing);
      expect(pinPadEnabled(tester), isTrue);
      // …and the 5th starts it.
      await enterPin(tester, wrongPin);
      expect(find.byType(LockoutCountdownBanner), findsOneWidget);
    });

    testWidgets('Scenario 2.5: biometrics un-enrolled at the OS level falls '
        'back to PIN-only, also mid-session', (tester) async {
      await configureAppLock(biometric: true);
      biometrics.available = false;
      await bootApp(tester);

      expectLockScreen();
      expect(biometrics.prompts, 0);
      expect(find.byKey(const Key('lock_screen.biometric')), findsNothing);
      await enterPin(tester, correctPin);
      expectUnlocked();

      // Available at lock time, gone by the time the user taps it.
      biometrics
        ..available = true
        ..succeed = false;
      await sendToBackground(tester);
      clock.advance(const Duration(minutes: 2));
      await returnToForeground(tester);
      expectLockScreen();
      expect(biometrics.prompts, 1);
      biometrics.available = false;
      await tapOn(tester, find.byKey(const Key('lock_screen.biometric')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.appLockLockBiometricUnavailable), findsOneWidget);
      expect(find.byKey(const Key('lock_screen.biometric')), findsNothing);
      await enterPin(tester, correctPin);
      expectUnlocked();
    });
  });

  group('US3 — lockout', () {
    testWidgets('Scenario 3.1-3.4: 5 wrong PINs → 30 s cooldown with PIN entry '
        'disabled; it lifts by itself; 3 more → 2 min; biometric still '
        'unlocks during a cooldown', (tester) async {
      await configureAppLock(biometric: true);
      biometrics
        ..available = true
        ..succeed = false;
      await bootApp(tester);
      expectLockScreen();

      for (var i = 0; i < 5; i++) {
        await enterPin(tester, wrongPin);
      }
      expect(find.byType(LockoutCountdownBanner), findsOneWidget);
      expect(
        find.text(
          l10n.appLockLockCooldownMessage(
            LockoutCountdownBanner.formatRemaining(const Duration(seconds: 30)),
          ),
        ),
        findsOneWidget,
      );
      expect(pinPadEnabled(tester), isFalse);

      clock.advance(const Duration(seconds: 31));
      // The countdown ticks once a second on a real timer.
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(find.byType(LockoutCountdownBanner), findsNothing);
      expect(pinPadEnabled(tester), isTrue);

      // Every attempt from the 5th on owes a cooldown (SC-006), so each of
      // attempts 6-8 waits out its 30 s first.
      for (var i = 0; i < 3; i++) {
        await enterPin(tester, wrongPin);
        if (i < 2) {
          expect(pinPadEnabled(tester), isFalse);
          clock.advance(const Duration(seconds: 31));
          await tester.pump(const Duration(milliseconds: 1200));
          await tester.pumpAndSettle();
        }
      }
      expect(
        find.text(
          l10n.appLockLockCooldownMessage(
            LockoutCountdownBanner.formatRemaining(const Duration(minutes: 2)),
          ),
        ),
        findsOneWidget,
      );
      expect(pinPadEnabled(tester), isFalse);
      expect(find.text(l10n.appLockLockCooldownBiometricHint), findsOneWidget);

      biometrics.succeed = true;
      await tapOn(tester, find.byKey(const Key('lock_screen.biometric')));
      await tester.pumpAndSettle();
      expectUnlocked();
      // A genuine authentication clears the lockout (FR-014).
      expect(
        (await repository().getLockoutState()).getOrElse(
          (f) => throw StateError('$f'),
        ),
        LockoutState.initial,
      );
    });

    testWidgets('Scenario 3.5: a cooldown survives a force-quit and '
        'relaunch', (tester) async {
      await configureAppLock();
      await bootApp(tester);
      for (var i = 0; i < 5; i++) {
        await enterPin(tester, wrongPin);
      }
      expect(find.byType(LockoutCountdownBanner), findsOneWidget);

      clock.advance(const Duration(seconds: 10));
      await bootApp(tester, relaunch: true);

      expectLockScreen();
      expect(find.byType(LockoutCountdownBanner), findsOneWidget);
      expect(
        find.text(
          l10n.appLockLockCooldownMessage(
            LockoutCountdownBanner.formatRemaining(const Duration(seconds: 20)),
          ),
        ),
        findsOneWidget,
      );
      expect(pinPadEnabled(tester), isFalse);

      clock.advance(const Duration(seconds: 21));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(pinPadEnabled(tester), isTrue);
      await enterPin(tester, correctPin);
      expectUnlocked();
    });
  });

  group('US4 — Forgot PIN', () {
    testWidgets('Scenario 4.1: biometric re-authentication then a new PIN, '
        'with zero data loss', (tester) async {
      await configureAppLock(biometric: true);
      biometrics
        ..available = true
        ..succeed = false; // the automatic prompt is dismissed
      await bootApp(tester);
      expectLockScreen();
      final peopleBefore = await peopleCount();

      await tapOn(tester, find.byKey(const Key('lock_screen.forgot_pin')));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPinPage), findsOneWidget);
      expect(find.text(l10n.appLockForgotBiometricTitle), findsOneWidget);

      biometrics.succeed = true;
      await tapOn(tester, find.text(l10n.appLockForgotBiometricAction));
      await tester.pumpAndSettle();
      expect(find.byType(PinSetupPage), findsOneWidget);
      expect(find.text(l10n.appLockPinResetTitle), findsOneWidget);

      await enterPin(tester, '5678');
      await enterPin(tester, '5678');
      expectUnlocked();
      expect(find.byType(HomePage), findsOneWidget);

      expect(await peopleCount(), peopleBefore);
      final verifyNew = (await repository().verifyPin(
        '5678',
      )).getOrElse((f) => throw StateError('$f'));
      expect(verifyNew, isTrue);
      final verifyOld = (await repository().verifyPin(
        correctPin,
      )).getOrElse((f) => throw StateError('$f'));
      expect(verifyOld, isFalse);
    });

    testWidgets('Scenario 4.2-4.4: without biometrics only the wipe is '
        'offered; cancelling changes nothing; the typed confirmation wipes '
        'everything back to first launch', (tester) async {
      await configureAppLock();
      await bootApp(tester);
      expectLockScreen();
      final peopleBefore = await peopleCount();
      expect(peopleBefore, greaterThan(0));

      await tapOn(tester, find.byKey(const Key('lock_screen.forgot_pin')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.appLockForgotWipeMessage), findsOneWidget);
      expect(find.text(l10n.appLockForgotBiometricAction), findsNothing);

      // Cancel at the confirmation, then back to the lock screen.
      await tapText(tester, l10n.appLockForgotWipeContinueAction);
      expect(find.byType(WipeConfirmationPage), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        l10n.deleteDataConfirmPhrase,
      );
      await tester.pumpAndSettle();
      await tapText(tester, l10n.appLockWipeCancelAction);
      await tapText(tester, l10n.appLockForgotBackAction);
      expectLockScreen();
      expect(find.byType(ForgotPinPage), findsNothing);
      expect(await peopleCount(), peopleBefore);
      expect(
        (await repository().getConfig())
            .getOrElse((f) => throw StateError('$f'))
            .isEnabled,
        isTrue,
      );

      // Now all the way through.
      await tapOn(tester, find.byKey(const Key('lock_screen.forgot_pin')));
      await tester.pumpAndSettle();
      await tapText(tester, l10n.appLockForgotWipeContinueAction);
      final erase = find.widgetWithText(
        FilledButton,
        l10n.appLockWipeConfirmAction,
      );
      expect(tester.widget<FilledButton>(erase).onPressed, isNull);
      await tester.enterText(
        find.byType(TextField),
        l10n.deleteDataConfirmPhrase,
      );
      await tester.pumpAndSettle();
      await tapOn(tester, erase);
      await tester.pumpAndSettle();

      expectUnlocked();
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(await peopleCount(), 0);
      final config = (await repository().getConfig()).getOrElse(
        (f) => throw StateError('$f'),
      );
      expect(config.isEnabled, isFalse);
      expect(config.hasPin, isFalse);

      // App Lock's configuration went too: a relaunch is not locked.
      await bootApp(tester, relaunch: true);
      expectUnlocked();
      expect(find.byType(OnboardingPage), findsOneWidget);
    });
  });

  group('US5 — screenshot protection', () {
    testWidgets('Scenario 5: turned on at startup with App Lock off, and '
        'never turned off by lifecycle changes or by disabling App Lock', (
      tester,
    ) async {
      await bootApp(tester);
      expect(screenshotCalls, ['enable']);
      expectUnlocked();

      await sendToBackground(tester);
      clock.advance(const Duration(minutes: 10));
      await returnToForeground(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await letAsyncWorkRun();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      // App Lock is off: nothing locks, protection is untouched.
      expectUnlocked();
      expect(screenshotCalls, ['enable']);

      // Turn App Lock on and off again: still no `disable`.
      await configureAppLock(timeout: InactivityTimeout.immediately);
      await sendToBackground(tester);
      await returnToForeground(tester);
      expectLockScreen();
      await enterPin(tester, correctPin);
      (await repository().disableAppLock()).getOrElse(
        (f) => throw StateError('$f'),
      );
      await sendToBackground(tester);
      await returnToForeground(tester);
      expectUnlocked();
      expect(screenshotCalls, ['enable']);
    });
  });

  group('US6 — manage security settings', () {
    testWidgets('Scenario 6.1-6.2: Change PIN re-authenticates first; the '
        '"Immediately" timeout applies from the next backgrounding', (
      tester,
    ) async {
      await configureAppLock(timeout: InactivityTimeout.after5min);
      await bootApp(tester, location: '/settings/security');
      await enterPin(tester, correctPin);
      expect(find.byType(SecuritySettingsPage), findsOneWidget);

      await tapText(tester, l10n.appLockSettingsChangePinTile);
      expect(find.byType(PinSetupPage), findsOneWidget);
      expect(find.text(l10n.appLockPinVerifyCurrentPrompt), findsOneWidget);
      await enterPin(tester, wrongPin);
      expect(find.text(l10n.appLockPinIncorrectCurrent), findsOneWidget);
      await enterPin(tester, correctPin);
      expect(find.text(l10n.appLockPinEnterNewPrompt), findsOneWidget);
      await enterPin(tester, '2468');
      await enterPin(tester, '2468');
      expect(find.byType(PinSetupPage), findsNothing);
      expect(find.text(l10n.appLockSettingsPinChangedMessage), findsOneWidget);

      await tapText(tester, l10n.appLockSettingsTimeoutImmediately);
      expect(
        (await repository().getConfig())
            .getOrElse((f) => throw StateError('$f'))
            .inactivityTimeout,
        InactivityTimeout.immediately,
      );

      await sendToBackground(tester);
      await returnToForeground(tester); // zero time elapsed
      expectLockScreen();
      await enterPin(tester, correctPin);
      expectLockScreen(); // the old PIN no longer works
      await enterPin(tester, '2468');
      expectUnlocked();
      expect(find.byType(SecuritySettingsPage), findsOneWidget);
    });

    testWidgets('Scenario 6.3: turning biometric unlock off leaves PIN-only '
        'lock screens', (tester) async {
      await configureAppLock(
        biometric: true,
        timeout: InactivityTimeout.immediately,
      );
      biometrics
        ..available = true
        ..succeed = false;
      await bootApp(tester, location: '/settings/security');
      await enterPin(tester, correctPin);
      final promptsBefore = biometrics.prompts;

      final biometricToggle = find.widgetWithText(
        SwitchListTile,
        l10n.appLockSettingsBiometricTitle,
      );
      expect(tester.widget<SwitchListTile>(biometricToggle).value, isTrue);
      await tester.tap(biometricToggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(biometricToggle).value, isFalse);

      await sendToBackground(tester);
      await returnToForeground(tester);
      expectLockScreen();
      expect(find.byKey(const Key('lock_screen.biometric')), findsNothing);
      expect(biometrics.prompts, promptsBefore);
    });

    testWidgets('Scenario 6.4-6.5: disabling (after PIN re-authentication) '
        'stops all locking; re-enabling needs a fresh PIN', (tester) async {
      await configureAppLock(timeout: InactivityTimeout.immediately);
      await bootApp(tester, location: '/settings/security');
      await enterPin(tester, correctPin);

      final toggle = find.widgetWithText(
        SwitchListTile,
        l10n.appLockSettingsToggleTitle,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.appLockSettingsDisableConfirm),
      );
      await tester.pumpAndSettle();
      // Biometric is off, so the current PIN is asked for.
      expect(find.text(l10n.appLockSettingsReauthTitle), findsOneWidget);
      await tester.enterText(find.byType(TextField), correctPin);
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.appLockSettingsReauthConfirm),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

      await sendToBackground(tester);
      clock.advance(const Duration(minutes: 30));
      await returnToForeground(tester);
      expectUnlocked();
      expect(screenshotCalls, ['enable']);

      // Re-enable: straight to choosing a new PIN, no "current PIN" step.
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(PinSetupPage), findsOneWidget);
      expect(find.text(l10n.appLockPinEnterNewPrompt), findsOneWidget);
      expect(find.text(l10n.appLockPinVerifyCurrentPrompt), findsNothing);
      await enterPin(tester, '8642');
      await enterPin(tester, '8642');
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

      expect(
        (await repository().verifyPin(
          correctPin,
        )).getOrElse((f) => throw StateError('$f')),
        isFalse,
      );
      await sendToBackground(tester);
      await returnToForeground(tester);
      expectLockScreen();
      await enterPin(tester, '8642');
      expectUnlocked();
    });
  });
}

/// A wall clock the test moves by hand.
class TestClock {
  DateTime _now = DateTime(2026, 9, 24, 12);

  DateTime call() => _now;

  void advance(Duration duration) => _now = _now.add(duration);
}

/// `AppLifecycleObserver`'s inactivity timers, fired only on demand.
class ManualTimers {
  final List<_ManualTimer> _timers = [];

  int get pending => _timers.where((t) => t.isActive).length;

  Timer create(Duration duration, void Function() callback) {
    final timer = _ManualTimer(callback);
    _timers.add(timer);
    return timer;
  }

  void fireAll() {
    for (final timer in [..._timers]) {
      timer.fire();
    }
    _timers.clear();
  }
}

class _ManualTimer implements Timer {
  _ManualTimer(this._callback);

  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;
}

/// No OS prompts: availability and the outcome are set by the test.
class FakeBiometricService implements BiometricService {
  bool available = false;
  bool succeed = false;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    prompts++;
    return available && succeed;
  }
}
