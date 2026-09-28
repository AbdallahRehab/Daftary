import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_failures.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/disable_app_lock.dart';
import 'package:daftary/features/app_lock/domain/usecases/enable_app_lock.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/usecases/record_failed_pin_attempt.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_biometric_enabled.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_inactivity_timeout.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_pin.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_biometric.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:daftary/features/app_lock/presentation/cubit/app_lock_settings_cubit.dart';
import 'package:daftary/features/app_lock/presentation/cubit/app_lock_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

class _MockBiometricService extends Mock implements BiometricService {}

/// T072 — `AppLockSettingsCubit` over the real use cases and repository
/// (in-memory secure storage, mocked biometrics), so each flow is proven
/// end to end against what is actually persisted.
void main() {
  late FakeSecureAppLockStorage storage;
  late DateTime now;
  late AppLockRepositoryImpl repository;
  late _MockBiometricService biometrics;

  setUp(() {
    storage = FakeSecureAppLockStorage();
    now = DateTime(2026, 9, 24, 12);
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      clock: () => now,
      runPinWork: runPinWorkInline,
    );
    biometrics = _MockBiometricService();
    when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
    when(
      () => biometrics.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).thenAnswer((_) async => true);
  });

  AppLockSettingsCubit buildCubit() => AppLockSettingsCubit(
    GetAppLockConfig(repository),
    biometrics,
    EnableAppLock(repository),
    DisableAppLock(repository),
    SetBiometricEnabled(repository, biometrics),
    SetInactivityTimeout(repository),
    VerifyPin(repository),
    VerifyBiometric(repository, biometrics),
    RecordFailedPinAttempt(repository),
    clock: () => now,
  );

  /// What `PinSetupPage` (initial setup) does before popping `true`.
  Future<void> completePinSetup(String pin) async {
    await SetPin(repository)(pin);
  }

  Future<void> enableWithPin(String pin) async {
    await completePinSetup(pin);
    await repository.enableAppLock();
  }

  Future<AppLockConfig> storedConfig() async =>
      (await repository.getConfig()).getOrElse((f) => fail('$f'));

  group('load', () {
    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'reads the config and live biometric availability',
      setUp: () =>
          when(() => biometrics.isAvailable()).thenAnswer((_) async => false),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const AppLockSettingsState(),
        const AppLockSettingsState(status: AppLockSettingsStatus.ready),
      ],
    );

    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'an unreadable config -> loadFailure',
      setUp: () => storage.throwOnNextCall = Exception('keystore'),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<AppLockSettingsState>()
            .having(
              (s) => s.status,
              'status',
              AppLockSettingsStatus.loadFailure,
            )
            .having((s) => s.failure, 'failure', isA<CacheFailure>()),
      ],
    );
  });

  group('enable', () {
    test('needs PIN setup when no PIN exists', () async {
      final cubit = buildCubit();
      await cubit.load();
      expect(cubit.needsPinSetup, isTrue);
      await cubit.close();
    });

    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'after PIN setup, enables with the default 1-minute timeout',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await completePinSetup('1234');
        await cubit.enableAfterPinSetup();
      },
      skip: 2,
      expect: () => [
        isA<AppLockSettingsState>().having(
          (s) => s.status,
          'status',
          AppLockSettingsStatus.submitting,
        ),
        isA<AppLockSettingsState>()
            .having((s) => s.isEnabled, 'isEnabled', isTrue)
            .having(
              (s) => s.config.inactivityTimeout,
              'timeout',
              InactivityTimeout.after1min,
            )
            .having(
              (s) => s.outcome,
              'outcome',
              AppLockSettingsOutcome.enabled,
            ),
      ],
      verify: (_) async => expect((await storedConfig()).isEnabled, isTrue),
    );

    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'without a PIN, enabling fails and App Lock stays off (FR-002)',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.enableAfterPinSetup();
      },
      skip: 3,
      expect: () => [
        isA<AppLockSettingsState>()
            .having((s) => s.isEnabled, 'isEnabled', isFalse)
            .having((s) => s.failure, 'failure', isA<NotFoundFailure>())
            .having((s) => s.outcome, 'outcome', isNull),
      ],
    );
  });

  group('timeout selection', () {
    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'persists the chosen timeout',
      setUp: () => enableWithPin('1234'),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.setInactivityTimeout(InactivityTimeout.immediately);
      },
      skip: 3,
      expect: () => [
        isA<AppLockSettingsState>().having(
          (s) => s.config.inactivityTimeout,
          'timeout',
          InactivityTimeout.immediately,
        ),
      ],
      verify: (_) async => expect(
        (await storedConfig()).inactivityTimeout,
        InactivityTimeout.immediately,
      ),
    );

    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'is ignored while App Lock is off',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.setInactivityTimeout(InactivityTimeout.after5min);
      },
      skip: 2,
      expect: () => <AppLockSettingsState>[],
    );
  });

  group('biometric toggle', () {
    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'turns biometric on and off without touching the PIN (FR-024)',
      setUp: () => enableWithPin('1234'),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.setBiometricEnabled(true);
        await cubit.setBiometricEnabled(false);
      },
      skip: 2,
      expect: () => [
        isA<AppLockSettingsState>().having(
          (s) => s.status,
          'status',
          AppLockSettingsStatus.submitting,
        ),
        isA<AppLockSettingsState>().having(
          (s) => s.config.isBiometricEnabled,
          'biometric',
          isTrue,
        ),
        isA<AppLockSettingsState>().having(
          (s) => s.status,
          'status',
          AppLockSettingsStatus.submitting,
        ),
        isA<AppLockSettingsState>()
            .having((s) => s.config.isBiometricEnabled, 'biometric', isFalse)
            .having((s) => s.config.hasPin, 'hasPin', isTrue),
      ],
      verify: (_) async => expect(
        (await repository.verifyPin('1234')).getOrElse((f) => fail('$f')),
        isTrue,
      ),
    );

    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'enrolment lost since the screen loaded -> BiometricUnavailableFailure, '
      'toggle shown as unavailable',
      setUp: () => enableWithPin('1234'),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        when(() => biometrics.isAvailable()).thenAnswer((_) async => false);
        await cubit.setBiometricEnabled(true);
      },
      skip: 3,
      expect: () => [
        isA<AppLockSettingsState>()
            .having((s) => s.config.isBiometricEnabled, 'biometric', isFalse)
            .having((s) => s.isBiometricAvailable, 'available', isFalse)
            .having(
              (s) => s.failure,
              'failure',
              isA<BiometricUnavailableFailure>(),
            ),
      ],
    );
  });

  group('change PIN', () {
    // The re-authentication itself happens inside `PinSetupPage`'s change
    // mode before `ChangePin` runs; the cubit is only told afterwards.
    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'reports the change once the PIN flow succeeded',
      setUp: () => enableWithPin('1234'),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.pinChanged();
      },
      skip: 3,
      expect: () => [
        isA<AppLockSettingsState>()
            .having((s) => s.isEnabled, 'isEnabled', isTrue)
            .having(
              (s) => s.outcome,
              'outcome',
              AppLockSettingsOutcome.pinChanged,
            ),
      ],
    );
  });

  group('disable', () {
    test('requires re-authentication first (FR-026)', () async {
      await enableWithPin('1234');
      final cubit = buildCubit();
      await cubit.load();

      await cubit.disable();

      expect((await storedConfig()).isEnabled, isTrue);
      expect(storage.credential, isNotNull);
      await cubit.close();
    });

    test('a wrong PIN does not authorize it, and counts toward the '
        'lockout (FR-013)', () async {
      await enableWithPin('1234');
      final cubit = buildCubit();
      await cubit.load();

      final attempt = await cubit.reauthenticateWithPin('9999');
      await cubit.disable();

      expect(attempt?.outcome, UnlockOutcome.incorrectPin);
      expect(storage.lockout?.consecutiveFailedAttempts, 1);
      expect((await storedConfig()).isEnabled, isTrue);
      await cubit.close();
    });

    test('the 5th wrong PIN reports the cooldown', () async {
      await enableWithPin('1234');
      final cubit = buildCubit();
      await cubit.load();

      UnlockAttemptResult? attempt;
      for (var i = 0; i < 5; i++) {
        attempt = await cubit.reauthenticateWithPin('9999');
      }

      expect(attempt?.outcome, UnlockOutcome.lockedOut);
      expect(attempt?.remainingCooldown, const Duration(seconds: 30));
      // During the cooldown even the right PIN is refused.
      final blocked = await cubit.reauthenticateWithPin('1234');
      expect(blocked?.outcome, UnlockOutcome.lockedOut);
      await cubit.close();
    });

    test('a failed biometric prompt does not authorize it', () async {
      await enableWithPin('1234');
      await repository.setBiometricEnabled(true);
      when(
        () => biometrics.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => false);
      final cubit = buildCubit();
      await cubit.load();

      expect(
        await cubit.reauthenticateWithBiometric(localizedReason: 'why'),
        isFalse,
      );
      await cubit.disable();

      expect((await storedConfig()).isEnabled, isTrue);
      await cubit.close();
    });

    test('biometric is not offered when it is not an active method', () async {
      await enableWithPin('1234');
      final cubit = buildCubit();
      await cubit.load();

      expect(
        await cubit.reauthenticateWithBiometric(localizedReason: 'why'),
        isFalse,
      );
      verifyNever(
        () => biometrics.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      );
      await cubit.close();
    });

    test('a cancelled prompt revokes the authorization', () async {
      await enableWithPin('1234');
      final cubit = buildCubit();
      await cubit.load();

      await cubit.reauthenticateWithPin('1234');
      cubit.cancelReauthentication();
      await cubit.disable();

      expect((await storedConfig()).isEnabled, isTrue);
      await cubit.close();
    });

    blocTest<AppLockSettingsCubit, AppLockSettingsState>(
      'after biometric re-auth, disables and deletes the PIN',
      setUp: () async {
        await enableWithPin('1234');
        await repository.setBiometricEnabled(true);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.reauthenticateWithBiometric(localizedReason: 'why');
        await cubit.disable();
      },
      skip: 3,
      expect: () => [
        isA<AppLockSettingsState>()
            .having((s) => s.isEnabled, 'isEnabled', isFalse)
            .having((s) => s.config.activeUnlockMethods, 'methods', isEmpty)
            .having(
              (s) => s.outcome,
              'outcome',
              AppLockSettingsOutcome.disabled,
            ),
      ],
      verify: (_) {
        expect(storage.credential, isNull);
        expect(storage.lockout, isNull);
      },
    );
  });

  test('disable then re-enable requires a fresh PIN setup, end to end '
      '(FR-027)', () async {
    await enableWithPin('1234');
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.needsPinSetup, isFalse);

    // Disable, authorized by the current PIN.
    final attempt = await cubit.reauthenticateWithPin('1234');
    expect(attempt?.isSuccess, isTrue);
    await cubit.disable();
    expect(cubit.state.isEnabled, isFalse);

    // Re-enable: the old PIN is gone, so PIN setup is required again, and
    // skipping it cannot enable App Lock.
    expect(cubit.needsPinSetup, isTrue);
    await cubit.enableAfterPinSetup();
    expect(cubit.state.isEnabled, isFalse);

    await completePinSetup('5678');
    await cubit.enableAfterPinSetup();
    expect(cubit.state.isEnabled, isTrue);
    expect(cubit.state.outcome, AppLockSettingsOutcome.enabled);

    // Only the NEW PIN works.
    expect(
      (await repository.verifyPin('5678')).getOrElse((f) => fail('$f')),
      isTrue,
    );
    expect(
      (await repository.verifyPin('1234')).getOrElse((f) => fail('$f')),
      isFalse,
    );
    await cubit.close();
  });

  test('actions are refused while a change is being saved', () async {
    await enableWithPin('1234');
    final cubit = buildCubit();
    await cubit.load();

    final first = cubit.setInactivityTimeout(InactivityTimeout.after30s);
    await cubit.setInactivityTimeout(InactivityTimeout.after5min);
    await first;

    expect(
      (await storedConfig()).inactivityTimeout,
      InactivityTimeout.after30s,
    );
    await cubit.close();
  });
}
