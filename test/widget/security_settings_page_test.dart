import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/disable_app_lock.dart';
import 'package:daftary/features/app_lock/domain/usecases/enable_app_lock.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/usecases/record_failed_pin_attempt.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_biometric_enabled.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_inactivity_timeout.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_biometric.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:daftary/features/app_lock/presentation/cubit/app_lock_settings_cubit.dart';
import 'package:daftary/features/app_lock/presentation/pages/security_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../features/app_lock/helpers/fake_secure_app_lock_storage.dart';

class _MockBiometricService extends Mock implements BiometricService {}

/// T077 — Security settings over the real cubit, use cases and repository
/// (in-memory secure storage, mocked biometrics).
void main() {
  late FakeSecureAppLockStorage storage;
  late AppLockRepositoryImpl repository;
  late _MockBiometricService biometrics;

  setUp(() {
    storage = FakeSecureAppLockStorage();
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      runPinWork: runPinWorkInline,
    );
    biometrics = _MockBiometricService();
    when(() => biometrics.isAvailable()).thenAnswer((_) async => false);
    getIt.registerFactory<AppLockSettingsCubit>(
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
    );
  });

  tearDown(() => getIt.reset());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SecuritySettingsPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enableWithPin(String pin) async {
    await repository.setPin(pin);
    await repository.enableAppLock();
  }

  testWidgets('App Lock off: only the switch and the always-on screenshot '
      'note are shown', (tester) async {
    await pumpPage(tester);

    expect(find.text('Lock Daftary'), findsOneWidget);
    expect(find.text('Change PIN'), findsNothing);
    expect(find.text('After 1 minute'), findsNothing);
    expect(find.text('Always on'), findsOneWidget);
  });

  testWidgets('App Lock on: timeout, Change PIN, and an explained, disabled '
      'biometric toggle when biometrics are unavailable', (tester) async {
    await enableWithPin('1234');
    await pumpPage(tester);

    expect(find.text('Change PIN'), findsOneWidget);
    expect(find.textContaining('Not available on this device'), findsOneWidget);
    final biometricSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Unlock with fingerprint or face'),
    );
    expect(biometricSwitch.onChanged, isNull);

    await tester.scrollUntilVisible(find.text('Immediately'), 100);
    await tester.tap(find.text('Immediately'));
    await tester.pumpAndSettle();
    expect(storage.config?.inactivityTimeout, InactivityTimeout.immediately);
  });

  testWidgets('turning App Lock off asks for confirmation, then the current '
      'PIN, then deletes it', (tester) async {
    await enableWithPin('1234');
    await pumpPage(tester);

    await tester.tap(find.text('Lock Daftary'));
    await tester.pumpAndSettle();
    expect(find.text('Turn off app lock?'), findsOneWidget);
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();

    // Biometric is not an active method, so the PIN prompt comes up.
    expect(find.text('Enter your PIN'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text("That PIN isn't right. Try again."), findsOneWidget);
    expect(storage.config?.isEnabled, isTrue);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(storage.config?.isEnabled, isFalse);
    expect(storage.credential, isNull);
    expect(find.text('App lock is off'), findsOneWidget);
    expect(find.text('Change PIN'), findsNothing);
  });

  testWidgets('cancelling the confirmation keeps App Lock on', (tester) async {
    await enableWithPin('1234');
    await pumpPage(tester);

    await tester.tap(find.text('Lock Daftary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(storage.config?.isEnabled, isTrue);
    expect(find.text('Enter your PIN'), findsNothing);
  });
}
