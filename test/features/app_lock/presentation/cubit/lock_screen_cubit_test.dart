import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/usecases/get_lockout_state.dart';
import 'package:daftary/features/app_lock/domain/usecases/record_failed_pin_attempt.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_biometric.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:daftary/features/app_lock/presentation/cubit/lock_screen_cubit.dart';
import 'package:daftary/features/app_lock/presentation/cubit/lock_screen_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAppLockConfig extends Mock implements GetAppLockConfig {}

class MockGetLockoutState extends Mock implements GetLockoutState {}

class MockVerifyPin extends Mock implements VerifyPin {}

class MockRecordFailedPinAttempt extends Mock
    implements RecordFailedPinAttempt {}

class MockVerifyBiometric extends Mock implements VerifyBiometric {}

class MockBiometricService extends Mock implements BiometricService {}

/// T028 (PIN unlock), T039 (biometric extension) and T049 (lockout
/// countdown) for `LockScreenCubit`.
void main() {
  late MockGetAppLockConfig getConfig;
  late MockGetLockoutState getLockoutState;
  late MockVerifyPin verifyPin;
  late MockRecordFailedPinAttempt recordFailedPinAttempt;
  late MockVerifyBiometric verifyBiometric;
  late MockBiometricService biometricService;
  late DateTime now;

  const reason = 'Unlock Daftary';
  const pinOnly = AppLockConfig(
    isEnabled: true,
    activeUnlockMethods: {UnlockMethod.pin},
    inactivityTimeout: InactivityTimeout.after1min,
  );
  const withBiometric = AppLockConfig(
    isEnabled: true,
    activeUnlockMethods: {UnlockMethod.pin, UnlockMethod.biometric},
    inactivityTimeout: InactivityTimeout.after1min,
  );
  const incorrect = UnlockAttemptResult(outcome: UnlockOutcome.incorrectPin);
  const bioFailed = UnlockAttemptResult(outcome: UnlockOutcome.biometricFailed);
  const bioUnavailable = UnlockAttemptResult(
    outcome: UnlockOutcome.biometricUnavailable,
  );

  const ready = LockScreenState(status: LockScreenStatus.ready);
  const readyBio = LockScreenState(
    status: LockScreenStatus.ready,
    isBiometricEnabled: true,
    isBiometricAvailable: true,
  );

  void givenConfig(AppLockConfig config, {bool biometricAvailable = true}) {
    when(() => getConfig()).thenAnswer((_) async => Right(config));
    when(
      () => biometricService.isAvailable(),
    ).thenAnswer((_) async => biometricAvailable);
  }

  void givenLockout(LockoutState lockout) {
    when(() => getLockoutState()).thenAnswer((_) async => Right(lockout));
  }

  void givenBiometric(UnlockAttemptResult result) {
    when(
      () => verifyBiometric(localizedReason: reason),
    ).thenAnswer((_) async => Right(result));
  }

  setUp(() {
    getConfig = MockGetAppLockConfig();
    getLockoutState = MockGetLockoutState();
    verifyPin = MockVerifyPin();
    recordFailedPinAttempt = MockRecordFailedPinAttempt();
    verifyBiometric = MockVerifyBiometric();
    biometricService = MockBiometricService();
    now = DateTime(2026, 9, 24, 12);
    givenConfig(pinOnly);
    givenLockout(LockoutState.initial);
  });

  LockScreenCubit buildCubit() => LockScreenCubit(
    getConfig,
    getLockoutState,
    verifyPin,
    recordFailedPinAttempt,
    verifyBiometric,
    biometricService,
    clock: () => now,
  );

  test('starts loading, with PIN entry disabled', () {
    final cubit = buildCubit();
    expect(cubit.state, const LockScreenState());
    expect(cubit.state.isPinEntryEnabled, isFalse);
    cubit.close();
  });

  group('US1 — PIN unlock (T028)', () {
    blocTest<LockScreenCubit, LockScreenState>(
      'start loads a PIN-only lock screen',
      build: buildCubit,
      act: (cubit) => cubit.start(biometricReason: reason),
      expect: () => [ready],
      verify: (cubit) {
        expect(cubit.state.isPinEntryEnabled, isTrue);
        expect(cubit.state.canUseBiometric, isFalse);
        verifyNever(
          () => verifyBiometric(localizedReason: any(named: 'localizedReason')),
        );
      },
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'correct PIN unlocks',
      build: () {
        when(
          () => verifyPin('1234'),
        ).thenAnswer((_) async => const Right(UnlockAttemptResult.success()));
        return buildCubit();
      },
      seed: () => ready,
      act: (cubit) => cubit.submitPin('1234'),
      expect: () => [
        ready.copyWith(status: LockScreenStatus.verifyingPin),
        ready.copyWith(status: LockScreenStatus.unlocked),
      ],
      verify: (_) => verifyNever(() => recordFailedPinAttempt()),
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'incorrect PIN stays locked with a clear error, recording exactly '
      'one failed attempt',
      build: () {
        when(
          () => verifyPin('0000'),
        ).thenAnswer((_) async => const Right(incorrect));
        when(() => recordFailedPinAttempt()).thenAnswer(
          (_) async => const Right(LockoutState(consecutiveFailedAttempts: 1)),
        );
        return buildCubit();
      },
      seed: () => ready,
      act: (cubit) => cubit.submitPin('0000'),
      expect: () => [
        ready.copyWith(status: LockScreenStatus.verifyingPin),
        ready.copyWith(message: LockScreenMessage.incorrectPin),
      ],
      verify: (cubit) {
        verify(() => recordFailedPinAttempt()).called(1);
        expect(cubit.state.isUnlocked, isFalse);
        expect(cubit.state.isPinEntryEnabled, isTrue);
      },
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'a double submit in the same frame verifies only once',
      build: () {
        final gate = Completer<Either<Failure, UnlockAttemptResult>>();
        when(() => verifyPin(any())).thenAnswer((_) => gate.future);
        Future<void>.delayed(
          Duration.zero,
          () => gate.complete(const Right(UnlockAttemptResult.success())),
        );
        return buildCubit();
      },
      seed: () => ready,
      act: (cubit) async {
        final first = cubit.submitPin('1234');
        final second = cubit.submitPin('1234');
        await Future.wait([first, second]);
      },
      expect: () => [
        ready.copyWith(status: LockScreenStatus.verifyingPin),
        ready.copyWith(status: LockScreenStatus.unlocked),
      ],
      verify: (_) => verify(() => verifyPin('1234')).called(1),
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'a storage error keeps the screen locked with a retryable message',
      build: () {
        when(
          () => verifyPin(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('x')));
        return buildCubit();
      },
      seed: () => ready,
      act: (cubit) => cubit.submitPin('1234'),
      expect: () => [
        ready.copyWith(status: LockScreenStatus.verifyingPin),
        ready.copyWith(message: LockScreenMessage.unexpected),
      ],
      verify: (_) => verifyNever(() => recordFailedPinAttempt()),
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'a config read error still leaves PIN entry working',
      build: () {
        when(
          () => getConfig(),
        ).thenAnswer((_) async => const Left(CacheFailure('x')));
        return buildCubit();
      },
      act: (cubit) => cubit.start(biometricReason: reason),
      expect: () => [ready.copyWith(message: LockScreenMessage.unexpected)],
      verify: (cubit) => expect(cubit.state.isPinEntryEnabled, isTrue),
    );
  });

  group('US2 — biometric unlock (T039)', () {
    blocTest<LockScreenCubit, LockScreenState>(
      'auto-prompts on entering the locked state when biometric is active '
      'and available',
      build: () {
        givenConfig(withBiometric);
        givenBiometric(const UnlockAttemptResult.success());
        return buildCubit();
      },
      act: (cubit) => cubit.start(biometricReason: reason),
      expect: () => [
        readyBio,
        readyBio.copyWith(status: LockScreenStatus.verifyingBiometric),
        readyBio.copyWith(status: LockScreenStatus.unlocked),
      ],
      verify: (_) =>
          verify(() => verifyBiometric(localizedReason: reason)).called(1),
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'does not prompt while the app is still in the background, but does '
      'on promptBiometricIfAvailable (resume)',
      build: () {
        givenConfig(withBiometric);
        givenBiometric(const UnlockAttemptResult.success());
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.start(biometricReason: reason, promptBiometric: false);
        verifyNever(
          () => verifyBiometric(localizedReason: any(named: 'localizedReason')),
        );
        await cubit.promptBiometricIfAvailable();
      },
      expect: () => [
        readyBio,
        readyBio.copyWith(status: LockScreenStatus.verifyingBiometric),
        readyBio.copyWith(status: LockScreenStatus.unlocked),
      ],
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'no prompt, PIN-only, when biometric is enabled but the device '
      'cannot do it',
      build: () {
        givenConfig(withBiometric, biometricAvailable: false);
        return buildCubit();
      },
      act: (cubit) => cubit.start(biometricReason: reason),
      expect: () => [
        const LockScreenState(
          status: LockScreenStatus.ready,
          isBiometricEnabled: true,
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.canUseBiometric, isFalse);
        verifyNever(
          () => verifyBiometric(localizedReason: any(named: 'localizedReason')),
        );
      },
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'falls back to PIN-only when availability flips to false mid-session '
      '(FR-007)',
      build: () {
        givenConfig(withBiometric);
        givenBiometric(bioUnavailable);
        return buildCubit();
      },
      act: (cubit) => cubit.start(biometricReason: reason),
      expect: () => [
        readyBio,
        readyBio.copyWith(status: LockScreenStatus.verifyingBiometric),
        readyBio.copyWith(
          status: LockScreenStatus.verifyingBiometric,
          isBiometricAvailable: false,
        ),
        readyBio.copyWith(
          isBiometricAvailable: false,
          message: LockScreenMessage.biometricUnavailable,
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.canUseBiometric, isFalse);
        expect(cubit.state.isPinEntryEnabled, isTrue);
      },
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'a cancelled/failed prompt leaves PIN entry usable and never touches '
      'the PIN counter (FR-008)',
      build: () {
        givenConfig(withBiometric);
        givenBiometric(bioFailed);
        return buildCubit();
      },
      act: (cubit) => cubit.start(biometricReason: reason),
      expect: () => [
        readyBio,
        readyBio.copyWith(status: LockScreenStatus.verifyingBiometric),
        readyBio.copyWith(message: LockScreenMessage.biometricFailed),
      ],
      verify: (cubit) {
        verifyNever(() => recordFailedPinAttempt());
        expect(cubit.state.isPinEntryEnabled, isTrue);
        expect(cubit.state.canUseBiometric, isTrue);
      },
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'the PIN stays usable while the prompt is pending (FR-006)',
      build: () {
        givenConfig(withBiometric);
        final never = Completer<Either<Failure, UnlockAttemptResult>>();
        when(
          () => verifyBiometric(localizedReason: reason),
        ).thenAnswer((_) => never.future);
        when(
          () => verifyPin('1234'),
        ).thenAnswer((_) async => const Right(UnlockAttemptResult.success()));
        return buildCubit();
      },
      act: (cubit) async {
        unawaited(cubit.start(biometricReason: reason));
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.isVerifyingBiometric, isTrue);
        expect(cubit.state.isPinEntryEnabled, isTrue);
        await cubit.submitPin('1234');
      },
      skip: 1,
      expect: () => [
        readyBio.copyWith(status: LockScreenStatus.verifyingBiometric),
        readyBio.copyWith(status: LockScreenStatus.verifyingPin),
        readyBio.copyWith(status: LockScreenStatus.unlocked),
      ],
    );
  });

  group('US3 — lockout countdown (T049)', () {
    test('a persisted cooldown is restored on start (FR-015), disabling '
        'PIN entry and counting down live to re-enable it', () {
      fakeAsync((async) {
        final start = now;
        final cubit = LockScreenCubit(
          getConfig,
          getLockoutState,
          verifyPin,
          recordFailedPinAttempt,
          verifyBiometric,
          biometricService,
          clock: () => start.add(async.elapsed),
        );
        givenLockout(
          LockoutState(
            consecutiveFailedAttempts: 5,
            cooldownEndsAt: start.add(const Duration(seconds: 3)),
          ),
        );

        cubit.start(biometricReason: reason);
        async.flushMicrotasks();
        expect(cubit.state.cooldownRemaining, const Duration(seconds: 3));
        expect(cubit.state.isPinEntryEnabled, isFalse);

        // Input during the cooldown is ignored outright.
        cubit.submitPin('1234');
        async.flushMicrotasks();
        verifyNever(() => verifyPin(any()));

        async.elapse(const Duration(seconds: 1));
        expect(cubit.state.cooldownRemaining, const Duration(seconds: 2));
        async.elapse(const Duration(seconds: 1));
        expect(cubit.state.cooldownRemaining, const Duration(seconds: 1));
        async.elapse(const Duration(seconds: 1));
        expect(cubit.state.cooldownRemaining, isNull);
        expect(cubit.state.isPinEntryEnabled, isTrue);

        cubit.close();
        async.flushTimers();
      });
    });

    blocTest<LockScreenCubit, LockScreenState>(
      'the 5th wrong PIN starts a 30 s cooldown',
      build: () {
        when(
          () => verifyPin(any()),
        ).thenAnswer((_) async => const Right(incorrect));
        when(() => recordFailedPinAttempt()).thenAnswer(
          (_) async => Right(
            LockoutState(
              consecutiveFailedAttempts: 5,
              cooldownEndsAt: now.add(const Duration(seconds: 30)),
            ),
          ),
        );
        return buildCubit();
      },
      seed: () => ready,
      act: (cubit) => cubit.submitPin('0000'),
      expect: () => [
        ready.copyWith(status: LockScreenStatus.verifyingPin),
        ready.copyWith(message: LockScreenMessage.incorrectPin),
        ready.copyWith(
          message: LockScreenMessage.incorrectPin,
          cooldownRemaining: const Duration(seconds: 30),
        ),
      ],
      verify: (cubit) => expect(cubit.state.isPinEntryEnabled, isFalse),
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'a lockedOut answer from VerifyPin shows the remaining cooldown',
      build: () {
        when(() => verifyPin(any())).thenAnswer(
          (_) async =>
              const Right(UnlockAttemptResult.lockedOut(Duration(seconds: 42))),
        );
        return buildCubit();
      },
      seed: () => ready,
      act: (cubit) => cubit.submitPin('1234'),
      expect: () => [
        ready.copyWith(status: LockScreenStatus.verifyingPin),
        ready,
        ready.copyWith(cooldownRemaining: const Duration(seconds: 42)),
      ],
      verify: (_) => verifyNever(() => recordFailedPinAttempt()),
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'biometric still reaches VerifyBiometric — and unlocks — during an '
      'active cooldown (FR-008 / US3 Scenario 4)',
      build: () {
        givenConfig(withBiometric);
        givenLockout(
          LockoutState(
            consecutiveFailedAttempts: 5,
            cooldownEndsAt: now.add(const Duration(seconds: 30)),
          ),
        );
        givenBiometric(const UnlockAttemptResult.success());
        return buildCubit();
      },
      act: (cubit) => cubit.start(biometricReason: reason),
      expect: () => [
        readyBio,
        readyBio.copyWith(cooldownRemaining: const Duration(seconds: 30)),
        readyBio.copyWith(
          status: LockScreenStatus.verifyingBiometric,
          cooldownRemaining: const Duration(seconds: 30),
        ),
        readyBio.copyWith(status: LockScreenStatus.unlocked),
      ],
      verify: (_) {
        verify(() => verifyBiometric(localizedReason: reason)).called(1);
        verifyNever(() => verifyPin(any()));
      },
    );

    blocTest<LockScreenCubit, LockScreenState>(
      'the manual biometric button works during a cooldown after a failed '
      'auto-prompt',
      build: () {
        givenConfig(withBiometric);
        givenLockout(
          LockoutState(
            consecutiveFailedAttempts: 5,
            cooldownEndsAt: now.add(const Duration(seconds: 30)),
          ),
        );
        givenBiometric(bioFailed);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.start(biometricReason: reason);
        givenBiometric(const UnlockAttemptResult.success());
        await cubit.authenticateWithBiometric();
      },
      verify: (cubit) {
        expect(cubit.state.isUnlocked, isTrue);
        verify(() => verifyBiometric(localizedReason: reason)).called(2);
        verifyNever(() => recordFailedPinAttempt());
      },
    );
  });
}
