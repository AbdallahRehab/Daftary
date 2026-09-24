import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/change_pin.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_lockout_state.dart';
import 'package:daftary/features/app_lock/domain/usecases/record_failed_pin_attempt.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_pin.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_biometric.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:daftary/features/app_lock/presentation/cubit/pin_setup_cubit.dart';
import 'package:daftary/features/app_lock/presentation/pages/pin_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

class MockBiometricService extends Mock implements BiometricService {}

/// T035 — `PinSetupPage`'s navigation contract: pops `true` once saved,
/// `false` when closed.
void main() {
  late FakeSecureAppLockStorage storage;
  late AppLockRepositoryImpl repository;
  late MockBiometricService biometrics;

  setUp(() {
    storage = FakeSecureAppLockStorage();
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      runPinWork: runPinWorkInline,
    );
    biometrics = MockBiometricService();
    when(() => biometrics.isAvailable()).thenAnswer((_) async => false);
    getIt.registerFactoryParam<PinSetupCubit, PinSetupMode, dynamic>(
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
      ),
    );
  });

  tearDown(() => getIt.reset());

  /// Pushes the page and returns a getter for its pop result.
  Future<Object? Function()> open(
    WidgetTester tester,
    PinSetupMode mode,
  ) async {
    // A typical phone: 360x800 logical pixels.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Object? result = 'not popped';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => PinSetupPage(mode: mode)),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
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

  testWidgets('initialSetup: enter + confirm pops true and stores the PIN', (
    tester,
  ) async {
    final result = await open(tester, PinSetupMode.initialSetup);
    expect(find.text('Set a PIN'), findsOneWidget);
    expect(find.text('Choose a PIN'), findsOneWidget);

    await enterPin(tester, '2580');
    expect(find.text('Enter the same PIN again'), findsOneWidget);
    await enterPin(tester, '2581');
    expect(
      find.text("The PINs don't match. Enter the confirmation again."),
      findsOneWidget,
    );
    await enterPin(tester, '2580');

    expect(result(), isTrue);
    expect(storage.credential, isNotNull);
    expect(storage.config!.isEnabled, isFalse);
  });

  testWidgets('close pops false and stores nothing', (tester) async {
    final result = await open(tester, PinSetupMode.initialSetup);
    await tester.tap(find.byKey(const Key('pin_setup.close')));
    await tester.pumpAndSettle();
    expect(result(), isFalse);
    expect(storage.credential, isNull);
  });

  testWidgets('change: asks for the current PIN first', (tester) async {
    await repository.setPin('1234');
    await repository.enableAppLock();
    final result = await open(tester, PinSetupMode.change);
    expect(find.text('Enter your current PIN'), findsOneWidget);

    await enterPin(tester, '1234');
    await enterPin(tester, '4321');
    await enterPin(tester, '4321');
    expect(result(), isTrue);
    expect(
      (await repository.verifyPin('4321')).getOrElse((_) => false),
      isTrue,
    );
  });
}
