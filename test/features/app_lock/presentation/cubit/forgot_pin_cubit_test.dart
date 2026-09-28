import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_failures.dart';
import 'package:daftary/features/app_lock/domain/usecases/recover_via_biometric.dart';
import 'package:daftary/features/app_lock/domain/usecases/wipe_all_local_data.dart';
import 'package:daftary/features/app_lock/presentation/cubit/forgot_pin_cubit.dart';
import 'package:daftary/features/app_lock/presentation/cubit/forgot_pin_state.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/delete_confirmation_input.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockRecoverViaBiometric extends Mock implements RecoverViaBiometric {}

class MockWipeAllLocalData extends Mock implements WipeAllLocalData {}

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

/// T058 — `ForgotPinCubit` routes to biometric recovery when it can work
/// and straight to the wipe explanation otherwise (FR-017/FR-018), with no
/// third route; the wipe runs only behind the typed confirmation (FR-019),
/// and backing out at any point before it deletes nothing.
void main() {
  const phrase = 'DELETE';
  const reason = 'Verify to reset your PIN';
  const failure = CacheFailure('disk full');

  late MockRecoverViaBiometric recover;
  late MockWipeAllLocalData wipe;
  late MockOnboardingCubit onboarding;

  setUp(() {
    recover = MockRecoverViaBiometric();
    wipe = MockWipeAllLocalData();
    onboarding = MockOnboardingCubit();
    when(() => onboarding.initialize()).thenAnswer((_) async {});
    when(() => wipe()).thenAnswer((_) async => const Right(unit));
  });

  ForgotPinCubit buildCubit() => ForgotPinCubit(recover, wipe, onboarding);

  const biometricStep = ForgotPinState(step: ForgotPinStep.biometricRecovery);
  const explanation = ForgotPinState(step: ForgotPinStep.wipeExplanation);
  const confirming = ForgotPinState(
    step: ForgotPinStep.wipeConfirmation,
    wipeInput: DeleteConfirmationInput(expectedPhrase: phrase),
  );
  final ready = confirming.copyWith(
    wipeInput: const DeleteConfirmationInput(
      expectedPhrase: phrase,
      typedPhrase: phrase,
    ),
  );

  group('routing', () {
    blocTest<ForgotPinCubit, ForgotPinState>(
      'offers biometric recovery first when it is available',
      setUp: () =>
          when(() => recover.isAvailable()).thenAnswer((_) async => true),
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      expect: () => [biometricStep],
      verify: (_) => verifyNever(() => wipe()),
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'goes straight to the wipe explanation when it is not',
      setUp: () =>
          when(() => recover.isAvailable()).thenAnswer((_) async => false),
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      expect: () => [explanation],
      verify: (_) => verifyNever(() => wipe()),
    );

    test('the flow has exactly two recovery routes, no third', () {
      expect(ForgotPinStep.values, [
        ForgotPinStep.resolving,
        ForgotPinStep.biometricRecovery,
        ForgotPinStep.wipeExplanation,
        ForgotPinStep.wipeConfirmation,
      ]);
    });
  });

  group('biometric recovery', () {
    blocTest<ForgotPinCubit, ForgotPinState>(
      'success -> verified (hand-off to the reset-PIN screen), no wipe',
      setUp: () => when(
        () => recover(localizedReason: reason),
      ).thenAnswer((_) async => const Right(true)),
      build: buildCubit,
      seed: () => biometricStep,
      act: (cubit) => cubit.recoverWithBiometric(localizedReason: reason),
      expect: () => [
        biometricStep.copyWith(
          biometricStatus: BiometricRecoveryStatus.authenticating,
        ),
        biometricStep.copyWith(
          biometricStatus: BiometricRecoveryStatus.verified,
        ),
      ],
      verify: (_) => verifyNever(() => wipe()),
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'a cancelled prompt -> failed and retryable, still on biometric',
      setUp: () => when(
        () => recover(localizedReason: reason),
      ).thenAnswer((_) async => const Right(false)),
      build: buildCubit,
      seed: () => biometricStep,
      act: (cubit) => cubit.recoverWithBiometric(localizedReason: reason),
      expect: () => [
        biometricStep.copyWith(
          biometricStatus: BiometricRecoveryStatus.authenticating,
        ),
        biometricStep.copyWith(biometricStatus: BiometricRecoveryStatus.failed),
      ],
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'biometric became unavailable -> only the wipe explanation remains',
      setUp: () => when(
        () => recover(localizedReason: reason),
      ).thenAnswer((_) async => const Left(BiometricUnavailableFailure())),
      build: buildCubit,
      seed: () => biometricStep,
      act: (cubit) => cubit.recoverWithBiometric(localizedReason: reason),
      expect: () => [
        biometricStep.copyWith(
          biometricStatus: BiometricRecoveryStatus.authenticating,
        ),
        explanation,
      ],
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'abandoning PIN setup requires a fresh biometric check',
      build: buildCubit,
      seed: () => biometricStep.copyWith(
        biometricStatus: BiometricRecoveryStatus.verified,
      ),
      act: (cubit) => cubit.pinResetAbandoned(),
      expect: () => [biometricStep],
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'the user may explicitly choose the wipe route instead — which only '
      'shows the explanation',
      build: buildCubit,
      seed: () => biometricStep.copyWith(
        biometricStatus: BiometricRecoveryStatus.failed,
      ),
      act: (cubit) => cubit.chooseWipe(),
      expect: () => [explanation],
      verify: (_) => verifyNever(() => wipe()),
    );
  });

  group('wipe gate', () {
    blocTest<ForgotPinCubit, ForgotPinState>(
      'continuing from the explanation opens the typed confirmation, '
      'deleting nothing',
      build: buildCubit,
      seed: () => explanation.copyWith(
        wipeInput: const DeleteConfirmationInput(expectedPhrase: phrase),
      ),
      act: (cubit) => cubit.proceedToWipeConfirmation(),
      expect: () => [confirming],
      verify: (_) => verifyNever(() => wipe()),
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'confirm is ignored until the phrase is typed exactly',
      build: buildCubit,
      seed: () => confirming,
      act: (cubit) async {
        cubit.updateTypedPhrase('delete');
        await cubit.confirmWipe();
        cubit.updateTypedPhrase('DELET');
        await cubit.confirmWipe();
      },
      verify: (_) => verifyNever(() => wipe()),
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'confirm is ignored from any step but the confirmation, even with '
      'the phrase typed',
      build: buildCubit,
      seed: () => ready.copyWith(step: ForgotPinStep.wipeExplanation),
      act: (cubit) => cubit.confirmWipe(),
      expect: () => <ForgotPinState>[],
      verify: (_) => verifyNever(() => wipe()),
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'the typed phrase + confirm runs the wipe once, then re-resolves '
      'onboarding',
      build: buildCubit,
      seed: () => ready,
      act: (cubit) async {
        final first = cubit.confirmWipe();
        final second = cubit.confirmWipe(); // same-frame double tap
        await Future.wait([first, second]);
      },
      expect: () => [
        ready.copyWith(wipeStatus: WipeStatus.inProgress),
        ready.copyWith(wipeStatus: WipeStatus.success),
      ],
      verify: (_) {
        verify(() => wipe()).called(1);
        verify(() => onboarding.initialize()).called(1);
      },
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'a failed wipe reports the error, allows a retry, and does not '
      'leave for onboarding',
      setUp: () =>
          when(() => wipe()).thenAnswer((_) async => const Left(failure)),
      build: buildCubit,
      seed: () => ready,
      act: (cubit) => cubit.confirmWipe(),
      expect: () => [
        ready.copyWith(wipeStatus: WipeStatus.inProgress),
        ready.copyWith(wipeStatus: WipeStatus.error, failure: failure),
      ],
      verify: (cubit) {
        expect(cubit.state.canConfirmWipe, isTrue);
        verifyNever(() => onboarding.initialize());
      },
    );
  });

  group('cancel before final confirmation leaves all data untouched', () {
    blocTest<ForgotPinCubit, ForgotPinState>(
      'leaving the confirmation returns to the explanation and discards '
      'the typed phrase',
      build: buildCubit,
      seed: () => ready,
      act: (cubit) => cubit.cancelWipeConfirmation(),
      expect: () => [
        explanation.copyWith(
          wipeInput: const DeleteConfirmationInput(expectedPhrase: phrase),
        ),
      ],
      verify: (_) => verifyNever(() => wipe()),
    );

    blocTest<ForgotPinCubit, ForgotPinState>(
      'walking the whole flow and backing out at every step never wipes',
      setUp: () {
        when(() => recover.isAvailable()).thenAnswer((_) async => true);
        when(
          () => recover(localizedReason: reason),
        ).thenAnswer((_) async => const Right(false));
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize();
        await cubit.recoverWithBiometric(localizedReason: reason);
        cubit
          ..chooseWipe()
          ..setExpectedPhrase(phrase)
          ..proceedToWipeConfirmation()
          ..updateTypedPhrase(phrase)
          ..cancelWipeConfirmation();
        // The typed phrase was discarded: confirming now does nothing.
        await cubit.confirmWipe();
      },
      verify: (cubit) {
        verifyNever(() => wipe());
        verifyNever(() => onboarding.initialize());
        expect(cubit.state.step, ForgotPinStep.wipeExplanation);
        expect(cubit.state.wipeInput.typedPhrase, isEmpty);
      },
    );
  });
}
