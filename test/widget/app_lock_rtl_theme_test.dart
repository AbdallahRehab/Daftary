import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/core/security/app_lock_status_provider.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/change_pin.dart';
import 'package:daftary/features/app_lock/domain/usecases/disable_app_lock.dart';
import 'package:daftary/features/app_lock/domain/usecases/enable_app_lock.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_lockout_state.dart';
import 'package:daftary/features/app_lock/domain/usecases/recover_via_biometric.dart';
import 'package:daftary/features/app_lock/domain/usecases/record_failed_pin_attempt.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_biometric_enabled.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_inactivity_timeout.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_pin.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_biometric.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:daftary/features/app_lock/domain/usecases/wipe_all_local_data.dart';
import 'package:daftary/features/app_lock/presentation/cubit/app_lock_settings_cubit.dart';
import 'package:daftary/features/app_lock/presentation/cubit/forgot_pin_cubit.dart';
import 'package:daftary/features/app_lock/presentation/cubit/lock_screen_cubit.dart';
import 'package:daftary/features/app_lock/presentation/cubit/pin_setup_cubit.dart';
import 'package:daftary/features/app_lock/presentation/pages/forgot_pin_page.dart';
import 'package:daftary/features/app_lock/presentation/pages/lock_screen_page.dart';
import 'package:daftary/features/app_lock/presentation/pages/pin_setup_page.dart';
import 'package:daftary/features/app_lock/presentation/pages/security_settings_page.dart';
import 'package:daftary/features/app_lock/presentation/pages/wipe_confirmation_page.dart';
import 'package:daftary/features/app_lock/presentation/widgets/lockout_countdown_banner.dart';
import 'package:daftary/features/app_lock/presentation/widgets/pin_pad.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../features/app_lock/helpers/fake_secure_app_lock_storage.dart';

class _FakeBiometricService implements BiometricService {
  bool available = false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}

class _MockWipeAllLocalData extends Mock implements WipeAllLocalData {}

class _MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

class _Enabled implements AppLockStatusProvider {
  @override
  Future<Duration?> lockTimeoutIfEnabled() async => const Duration(minutes: 1);
}

/// One App Lock surface in the state that puts the most on screen.
class _Surface {
  const _Surface(this.name, {required this.build, this.arrange, this.act});

  final String name;

  /// Persisted App Lock state to set up before pumping.
  final Future<void> Function(_Env env)? arrange;
  final WidgetBuilder build;

  /// Interaction after the first frame (reaching a later step).
  final Future<void> Function(WidgetTester tester)? act;
}

class _Env {
  _Env(this.repository, this.biometrics);

  final AppLockRepositoryImpl repository;
  final _FakeBiometricService biometrics;

  Future<void> enable({bool biometric = false}) async {
    await repository.setPin('1234');
    await repository.enableAppLock();
    if (biometric) {
      biometrics.available = true;
      await repository.setBiometricEnabled(true);
    }
  }

  Future<void> startCooldown() async {
    for (var i = 0; i < 5; i++) {
      await repository.recordFailedPinAttempt();
    }
  }
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pin_pad.digit.$digit')));
    await tester.pump();
  }
  await tester.ensureVisible(find.byKey(const Key('pin_pad.submit')));
  await tester.tap(find.byKey(const Key('pin_pad.submit')));
  await tester.pumpAndSettle();
}

/// 015 T079 (FR-029, SC-007) — every App Lock screen in Arabic (RTL) and
/// English (LTR), light and dark, on a typical and a narrow phone: no
/// overflow or other layout exception anywhere on the (fully scrolled)
/// page, the ambient direction and theme are the requested ones, and the
/// PIN pad keeps its fixed left-to-right keypad order under RTL.
void main() {
  final now = DateTime(2026, 9, 24, 12);

  late FakeSecureAppLockStorage storage;
  late AppLockRepositoryImpl repository;
  late _FakeBiometricService biometrics;
  late AppLifecycleObserver observer;

  setUp(() {
    storage = FakeSecureAppLockStorage();
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      clock: () => now,
      runPinWork: runPinWorkInline,
    );
    biometrics = _FakeBiometricService();
    observer = AppLifecycleObserver(_Enabled())..lock();

    final wipe = _MockWipeAllLocalData();
    when(() => wipe()).thenAnswer((_) async => const Right(unit));
    final onboarding = _MockOnboardingCubit();
    when(() => onboarding.state).thenReturn(
      const OnboardingState(status: OnboardingLoadStatus.showOnboarding),
    );

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
      )
      ..registerFactoryParam<PinSetupCubit, PinSetupMode, void>(
        (mode, _) => PinSetupCubit(
          mode,
          SetPin(repository),
          ChangePin(repository),
          VerifyPin(repository),
          RecordFailedPinAttempt(repository),
          GetLockoutState(repository),
          GetAppLockConfig(repository),
          VerifyBiometric(repository, biometrics),
          biometrics,
          clock: () => now,
        ),
      )
      ..registerFactory<AppLockSettingsCubit>(
        () => AppLockSettingsCubit(
          GetAppLockConfig(repository),
          biometrics,
          EnableAppLock(repository),
          DisableAppLock(repository),
          SetBiometricEnabled(repository, biometrics),
          SetInactivityTimeout(repository),
          VerifyPin(repository),
          VerifyBiometric(repository, biometrics),
          RecordFailedPinAttempt(repository),
        ),
      )
      ..registerFactory<ForgotPinCubit>(
        () => ForgotPinCubit(
          RecoverViaBiometric(repository, biometrics),
          wipe,
          onboarding,
        ),
      );
  });

  tearDown(() async {
    await getIt.reset(dispose: false);
    observer.dispose();
  });

  final surfaces = <_Surface>[
    _Surface(
      'lock screen (biometric offered, failed prompt message)',
      arrange: (env) => env.enable(biometric: true),
      build: (_) => const LockScreenPage(),
    ),
    _Surface(
      'lock screen during a lockout countdown',
      arrange: (env) async {
        await env.enable(biometric: true);
        await env.startCooldown();
      },
      build: (_) => const LockScreenPage(),
    ),
    _Surface(
      'PIN setup: confirmation step with a mismatch',
      build: (_) => const PinSetupPage(mode: PinSetupMode.initialSetup),
      act: (tester) async {
        await _enterPin(tester, '1234');
        await _enterPin(tester, '5678');
        expect(find.byKey(const Key('pin_setup.message')), findsOneWidget);
        expect(find.byKey(const Key('pin_setup.start_over')), findsOneWidget);
      },
    ),
    _Surface(
      'change PIN: current-PIN step during a lockout countdown',
      arrange: (env) async {
        await env.enable(biometric: true);
        await env.startCooldown();
      },
      build: (_) => const PinSetupPage(mode: PinSetupMode.change),
    ),
    _Surface(
      'Security settings (enabled, biometric unavailable)',
      arrange: (env) async {
        await env.enable(biometric: true);
        env.biometrics.available = false;
      },
      build: (_) => const SecuritySettingsPage(),
    ),
    _Surface(
      'Forgot PIN: biometric recovery',
      arrange: (env) => env.enable(biometric: true),
      build: (_) => const ForgotPinPage(),
    ),
    _Surface(
      'Forgot PIN: wipe explanation',
      arrange: (env) => env.enable(),
      build: (_) => const ForgotPinPage(),
    ),
    _Surface(
      'wipe confirmation',
      arrange: (env) => env.enable(),
      build: (_) => BlocProvider<ForgotPinCubit>(
        create: (_) => getIt<ForgotPinCubit>(),
        child: const WipeConfirmationPage(),
      ),
    ),
  ];

  const phones = {'360x640': Size(360, 640), '320x568': Size(320, 568)};
  const locales = {
    'ar': (Locale('ar'), TextDirection.rtl),
    'en': (Locale('en'), TextDirection.ltr),
  };
  const themes = {'light': Brightness.light, 'dark': Brightness.dark};

  for (final surface in surfaces) {
    group(surface.name, () {
      for (final MapEntry(key: phoneName, value: phone) in phones.entries) {
        for (final MapEntry(key: localeName, value: (locale, direction))
            in locales.entries) {
          for (final MapEntry(key: themeName, value: brightness)
              in themes.entries) {
            testWidgets('$localeName · $themeName · $phoneName', (
              tester,
            ) async {
              await surface.arrange?.call(_Env(repository, biometrics));
              tester.view
                ..physicalSize = phone * 3
                ..devicePixelRatio = 3;
              addTearDown(tester.view.reset);

              await tester.pumpWidget(
                MaterialApp(
                  theme: buildLightTheme(),
                  darkTheme: buildDarkTheme(),
                  themeMode: brightness == Brightness.dark
                      ? ThemeMode.dark
                      : ThemeMode.light,
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Builder(builder: surface.build),
                ),
              );
              await tester.pumpAndSettle();
              await surface.act?.call(tester);
              expect(tester.takeException(), isNull);

              final page = tester.element(find.byType(Scaffold).first);
              expect(Directionality.of(page), direction);
              expect(Theme.of(page).brightness, brightness);

              // The keypad keeps phone-keypad order in every locale.
              final pad = find.byType(PinPad);
              if (pad.evaluate().isNotEmpty) {
                final digit = find.byKey(const Key('pin_pad.digit.1'));
                expect(
                  Directionality.of(tester.element(digit)),
                  TextDirection.ltr,
                );
                expect(
                  tester.getCenter(digit).dx,
                  lessThan(
                    tester
                        .getCenter(find.byKey(const Key('pin_pad.digit.3')))
                        .dx,
                  ),
                );
              }
              if (find.byType(LockoutCountdownBanner).evaluate().isNotEmpty) {
                expect(
                  find.textContaining(
                    LockoutCountdownBanner.formatRemaining(
                      const Duration(seconds: 30),
                    ),
                  ),
                  findsOneWidget,
                );
              }

              // Lay out everything below the fold too.
              final scrollable = find.byType(Scrollable);
              if (scrollable.evaluate().isNotEmpty) {
                await tester.drag(scrollable.first, const Offset(0, -2000));
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
              }

              // Dispose the page (and its countdown ticker) inside the test.
              await tester.pumpWidget(const SizedBox.shrink());
            });
          }
        }
      }
    });
  }
}
