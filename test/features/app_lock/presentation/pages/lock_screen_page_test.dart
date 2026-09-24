import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/core/security/app_lock_status_provider.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_lockout_state.dart';
import 'package:daftary/features/app_lock/domain/usecases/record_failed_pin_attempt.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_biometric.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:daftary/features/app_lock/presentation/cubit/lock_screen_cubit.dart';
import 'package:daftary/features/app_lock/presentation/pages/lock_screen_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

class MockBiometricService extends Mock implements BiometricService {}

class _Enabled implements AppLockStatusProvider {
  @override
  Future<Duration?> lockTimeoutIfEnabled() async => const Duration(minutes: 1);
}

/// T035/T044/T055 — the lock screen wired to the real use cases over
/// in-memory secure storage.
void main() {
  late FakeSecureAppLockStorage storage;
  late DateTime now;
  late AppLockRepositoryImpl repository;
  late MockBiometricService biometrics;
  late AppLifecycleObserver observer;

  setUp(() async {
    storage = FakeSecureAppLockStorage();
    now = DateTime(2026, 9, 24, 12);
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      clock: () => now,
      runPinWork: runPinWorkInline,
    );
    await repository.setPin('1234');
    await repository.enableAppLock();
    biometrics = MockBiometricService();
    when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
    observer = AppLifecycleObserver(_Enabled())..lock();
    getIt
      ..registerSingleton<AppLifecycleObserver>(observer)
      ..registerFactory<LockScreenCubit>(
        () => LockScreenCubit(
          GetAppLockConfig(repository),
          GetLockoutState(repository),
          VerifyPin(repository),
          RecordFailedPinAttempt(repository),
          VerifyBiometric(repository, biometrics),
          biometrics,
          clock: () => now,
        ),
      );
  });

  tearDown(() async {
    await getIt.reset(dispose: false);
    observer.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    // A typical phone: 360x800 logical pixels.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LockScreenPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Settles frames, letting any pending async use-case work finish.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.byKey(Key('pin_pad.digit.$digit')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('pin_pad.submit')));
    await settle(tester);
  }

  testWidgets('the correct PIN releases the gate', (tester) async {
    await pump(tester);
    expect(find.text('Daftary is locked'), findsOneWidget);
    expect(find.byKey(const Key('lock_screen.biometric')), findsNothing);

    await enterPin(tester, '1234');
    expect(observer.isLocked.value, isFalse);
  });

  testWidgets('a wrong PIN shows a clear error and stays locked', (
    tester,
  ) async {
    await pump(tester);
    await enterPin(tester, '9999');
    expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
    expect(observer.isLocked.value, isTrue);
    expect(storage.lockout!.consecutiveFailedAttempts, 1);
  });

  testWidgets('a restored cooldown shows the countdown and disables the '
      'pad, while biometric stays offered', (tester) async {
    await repository.setBiometricEnabled(true);
    when(
      () => biometrics.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).thenAnswer((_) async => false);
    for (var i = 0; i < 5; i++) {
      await repository.recordFailedPinAttempt();
    }
    await pump(tester);

    expect(find.text('Too many incorrect attempts'), findsOneWidget);
    expect(
      find.textContaining('\u20660:30\u2069'),
      findsOneWidget,
      reason: 'm:ss inside an LTR isolate',
    );
    expect(find.text('You can still unlock with biometrics.'), findsOneWidget);
    final submit = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const Key('pin_pad.submit')),
        matching: find.byType(IconButton),
      ),
    );
    expect(submit.onPressed, isNull);

    when(
      () => biometrics.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).thenAnswer((_) async => true);
    await tester.ensureVisible(find.byKey(const Key('lock_screen.biometric')));
    await tester.tap(find.byKey(const Key('lock_screen.biometric')));
    await settle(tester);
    expect(observer.isLocked.value, isFalse);
  });

  testWidgets('renders in Arabic', (tester) async {
    await pump(tester, locale: const Locale('ar'));
    expect(find.text('دفتري مقفل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
