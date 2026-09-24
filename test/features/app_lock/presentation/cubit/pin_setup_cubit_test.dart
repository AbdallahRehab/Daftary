import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
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
import 'package:daftary/features/app_lock/presentation/cubit/pin_setup_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

class MockBiometricService extends Mock implements BiometricService {}

/// Counts credential writes, so "exactly one PinCredential write" is
/// checked against storage itself.
class _CountingStorage extends FakeSecureAppLockStorage {
  int credentialWrites = 0;

  @override
  Future<void> writePinCredential(value) async {
    credentialWrites++;
    await super.writePinCredential(value);
  }
}

/// T027 — `PinSetupCubit` against the real use cases and repository over
/// in-memory secure storage (only the biometric hardware is mocked), plus
/// the change/reset modes other flows rely on.
void main() {
  late _CountingStorage storage;
  late DateTime now;
  late AppLockRepositoryImpl repository;
  late MockBiometricService biometrics;

  const reason = 'Confirm';

  setUp(() {
    storage = _CountingStorage();
    now = DateTime(2026, 9, 24, 12);
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      clock: () => now,
      runPinWork: runPinWorkInline,
    );
    biometrics = MockBiometricService();
    when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
  });

  PinSetupCubit buildCubit(PinSetupMode mode) => PinSetupCubit(
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
  );

  const enterNew = PinSetupState(
    mode: PinSetupMode.initialSetup,
    step: PinSetupStep.enterNew,
  );
  final confirmNew = enterNew.copyWith(step: PinSetupStep.confirmNew);

  Future<bool> pinVerifies(String pin) async =>
      (await repository.verifyPin(pin)).getOrElse((_) => false);

  group('initialSetup (T027)', () {
    test('starts on entering the new PIN', () {
      expect(
        PinSetupState.initial(PinSetupMode.initialSetup).step,
        PinSetupStep.enterNew,
      );
    });

    blocTest<PinSetupCubit, PinSetupState>(
      'happy path: enter + matching confirm stores the PIN, without '
      'enabling App Lock',
      build: () => buildCubit(PinSetupMode.initialSetup),
      act: (cubit) async {
        cubit.submitNewPin('4321');
        await cubit.submitConfirmation('4321');
      },
      expect: () => [
        confirmNew,
        confirmNew.copyWith(status: PinSetupStatus.saving),
        confirmNew.copyWith(status: PinSetupStatus.success),
      ],
      verify: (_) async {
        expect(await pinVerifies('4321'), isTrue);
        expect(storage.config!.isEnabled, isFalse);
        expect(storage.credentialWrites, 1);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'mismatch keeps the first entry: retyping only the confirmation '
      'succeeds (US1 Scenario 3)',
      build: () => buildCubit(PinSetupMode.initialSetup),
      act: (cubit) async {
        cubit.submitNewPin('1357');
        await cubit.submitConfirmation('1358');
        await cubit.submitConfirmation('1357');
      },
      expect: () => [
        confirmNew,
        confirmNew.copyWith(message: PinSetupMessage.mismatch),
        confirmNew.copyWith(status: PinSetupStatus.saving),
        confirmNew.copyWith(status: PinSetupStatus.success),
      ],
      verify: (_) async {
        expect(await pinVerifies('1357'), isTrue);
        expect(storage.credentialWrites, 1);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'a mismatch persists nothing',
      build: () => buildCubit(PinSetupMode.initialSetup),
      act: (cubit) async {
        cubit.submitNewPin('1357');
        await cubit.submitConfirmation('7531');
      },
      verify: (cubit) {
        expect(cubit.state.message, PinSetupMessage.mismatch);
        expect(storage.credential, isNull);
        expect(storage.credentialWrites, 0);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'duplicate taps on save produce exactly one PinCredential write',
      build: () => buildCubit(PinSetupMode.initialSetup),
      act: (cubit) async {
        cubit.submitNewPin('9876');
        await Future.wait([
          cubit.submitConfirmation('9876'),
          cubit.submitConfirmation('9876'),
          cubit.submitConfirmation('9876'),
        ]);
        // And after success, too.
        await cubit.submitConfirmation('9876');
      },
      expect: () => [
        confirmNew,
        confirmNew.copyWith(status: PinSetupStatus.saving),
        confirmNew.copyWith(status: PinSetupStatus.success),
      ],
      verify: (_) => expect(storage.credentialWrites, 1),
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'startOver discards the first entry',
      build: () => buildCubit(PinSetupMode.initialSetup),
      act: (cubit) async {
        cubit
          ..submitNewPin('1111')
          ..startOver()
          ..submitNewPin('2222');
        await cubit.submitConfirmation('1111'); // the old one no longer counts
        await cubit.submitConfirmation('2222');
      },
      expect: () => [
        confirmNew,
        enterNew,
        confirmNew,
        confirmNew.copyWith(message: PinSetupMessage.mismatch),
        confirmNew.copyWith(status: PinSetupStatus.saving),
        confirmNew.copyWith(status: PinSetupStatus.success),
      ],
      verify: (_) async => expect(await pinVerifies('2222'), isTrue),
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'a malformed first entry is rejected up front (FR-003)',
      build: () => buildCubit(PinSetupMode.initialSetup),
      act: (cubit) => cubit
        ..submitNewPin('12')
        ..submitNewPin('1234567'),
      expect: () => [enterNew.copyWith(message: PinSetupMessage.invalidPin)],
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'a storage error keeps the first entry so saving can be retried',
      build: () => buildCubit(PinSetupMode.initialSetup),
      act: (cubit) async {
        cubit.submitNewPin('2468');
        storage.throwOnNextCall = Exception('keystore');
        await cubit.submitConfirmation('2468');
        await cubit.submitConfirmation('2468');
      },
      expect: () => [
        confirmNew,
        confirmNew.copyWith(status: PinSetupStatus.saving),
        confirmNew.copyWith(message: PinSetupMessage.unexpected),
        confirmNew.copyWith(status: PinSetupStatus.saving),
        confirmNew.copyWith(status: PinSetupStatus.success),
      ],
      verify: (_) async => expect(await pinVerifies('2468'), isTrue),
    );
  });

  group('change mode', () {
    const verifyCurrent = PinSetupState(
      mode: PinSetupMode.change,
      step: PinSetupStep.verifyCurrent,
    );

    Future<void> enableWith(String pin, {bool biometric = false}) async {
      await repository.setPin(pin);
      await repository.enableAppLock();
      if (biometric) await repository.setBiometricEnabled(true);
    }

    blocTest<PinSetupCubit, PinSetupState>(
      'requires the current PIN first, then enter + confirm replaces it '
      '(FR-023)',
      setUp: () => enableWith('1234'),
      build: () => buildCubit(PinSetupMode.change),
      act: (cubit) async {
        await cubit.start();
        await cubit.submitCurrentPin('1234');
        cubit.submitNewPin('567890');
        await cubit.submitConfirmation('567890');
      },
      expect: () => [
        verifyCurrent.copyWith(status: PinSetupStatus.verifying),
        verifyCurrent.copyWith(step: PinSetupStep.enterNew),
        verifyCurrent.copyWith(step: PinSetupStep.confirmNew),
        verifyCurrent.copyWith(
          step: PinSetupStep.confirmNew,
          status: PinSetupStatus.saving,
        ),
        verifyCurrent.copyWith(
          step: PinSetupStep.confirmNew,
          status: PinSetupStatus.success,
        ),
      ],
      verify: (_) async {
        expect(await pinVerifies('567890'), isTrue);
        expect(await pinVerifies('1234'), isFalse);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'new-PIN steps are unreachable before re-authentication',
      setUp: () => enableWith('1234'),
      build: () => buildCubit(PinSetupMode.change),
      act: (cubit) async {
        cubit.submitNewPin('5555');
        await cubit.submitConfirmation('5555');
      },
      expect: () => <PinSetupState>[],
      verify: (_) async => expect(await pinVerifies('1234'), isTrue),
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'a wrong current PIN is recorded against the lockout',
      setUp: () => enableWith('1234'),
      build: () => buildCubit(PinSetupMode.change),
      act: (cubit) => cubit.submitCurrentPin('0000'),
      expect: () => [
        verifyCurrent.copyWith(status: PinSetupStatus.verifying),
        verifyCurrent.copyWith(message: PinSetupMessage.incorrectCurrentPin),
      ],
      verify: (_) => expect(storage.lockout!.consecutiveFailedAttempts, 1),
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'an active cooldown is restored and disables current-PIN entry, but '
      'biometric re-authentication still works',
      setUp: () async {
        await enableWith('1234', biometric: true);
        for (var i = 0; i < 5; i++) {
          await repository.recordFailedPinAttempt();
        }
        when(
          () => biometrics.authenticate(localizedReason: reason),
        ).thenAnswer((_) async => true);
      },
      build: () => buildCubit(PinSetupMode.change),
      act: (cubit) async {
        await cubit.start();
        expect(cubit.state.isPinEntryEnabled, isFalse);
        await cubit.submitCurrentPin('1234'); // ignored
        await cubit.authenticateWithBiometric(localizedReason: reason);
      },
      expect: () => [
        verifyCurrent.copyWith(canUseBiometric: true),
        verifyCurrent.copyWith(
          canUseBiometric: true,
          cooldownRemaining: const Duration(seconds: 30),
        ),
        verifyCurrent.copyWith(
          canUseBiometric: true,
          cooldownRemaining: const Duration(seconds: 30),
          status: PinSetupStatus.verifying,
        ),
        verifyCurrent.copyWith(
          canUseBiometric: true,
          step: PinSetupStep.enterNew,
        ),
      ],
      verify: (_) => expect(storage.lockout, LockoutState.initial),
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'a failed biometric attempt is never counted (FR-008)',
      setUp: () async {
        await enableWith('1234', biometric: true);
        when(
          () => biometrics.authenticate(localizedReason: reason),
        ).thenAnswer((_) async => false);
      },
      build: () => buildCubit(PinSetupMode.change),
      act: (cubit) async {
        await cubit.start();
        await cubit.authenticateWithBiometric(localizedReason: reason);
      },
      verify: (cubit) {
        expect(cubit.state.message, PinSetupMessage.biometricFailed);
        expect(cubit.state.step, PinSetupStep.verifyCurrent);
        expect(storage.lockout?.consecutiveFailedAttempts ?? 0, 0);
      },
    );
  });

  group('reset mode', () {
    blocTest<PinSetupCubit, PinSetupState>(
      'skips re-authentication (the caller did it) and replaces the PIN',
      setUp: () async {
        await repository.setPin('1234');
        await repository.enableAppLock();
      },
      build: () => buildCubit(PinSetupMode.reset),
      act: (cubit) async {
        await cubit.start();
        cubit.submitNewPin('8642');
        await cubit.submitConfirmation('8642');
      },
      verify: (cubit) async {
        expect(cubit.state.isSuccess, isTrue);
        expect(await pinVerifies('8642'), isTrue);
        expect(storage.config!.isEnabled, isTrue);
      },
    );
  });

  test('close() during a save never emits afterwards', () async {
    final cubit = buildCubit(PinSetupMode.initialSetup)..submitNewPin('1234');
    final save = cubit.submitConfirmation('1234');
    await cubit.close();
    await save;
    expect(cubit.isClosed, isTrue);
    expect(storage.config?.activeUnlockMethods, {UnlockMethod.pin});
  });
}
