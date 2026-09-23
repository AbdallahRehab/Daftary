import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/data_privacy/domain/usecases/delete_all_user_data.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/delete_account_cubit.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/delete_account_state.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/delete_confirmation_input.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDeleteAllUserData extends Mock implements DeleteAllUserData {}

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

/// T033 — `DeleteAccountCubit` owns the post-wipe orchestration
/// (research.md Decision 6) and the FR-021 at-most-once guard.
void main() {
  late MockDeleteAllUserData deleteAllUserData;
  late MockOnboardingCubit onboardingCubit;

  const phrase = 'DELETE';
  const ready = DeleteAccountState(
    input: DeleteConfirmationInput(expectedPhrase: phrase, typedPhrase: phrase),
  );
  const failure = CacheFailure('disk full');

  setUp(() {
    deleteAllUserData = MockDeleteAllUserData();
    onboardingCubit = MockOnboardingCubit();
    when(() => onboardingCubit.initialize()).thenAnswer((_) async {});
  });

  DeleteAccountCubit buildCubit() =>
      DeleteAccountCubit(deleteAllUserData, onboardingCubit);

  group('DeleteConfirmationInput', () {
    test('is enabled only when the trimmed typed phrase matches exactly', () {
      const input = DeleteConfirmationInput(expectedPhrase: phrase);
      expect(input.isConfirmationEnabled, isFalse);
      expect(input.copyWith(typedPhrase: 'DELET').isConfirmationEnabled, false);
      expect(
        input.copyWith(typedPhrase: 'delete').isConfirmationEnabled,
        false,
      );
      expect(input.copyWith(typedPhrase: 'DELETE').isConfirmationEnabled, true);
      expect(
        input.copyWith(typedPhrase: '  DELETE ').isConfirmationEnabled,
        true,
      );
    });

    test('is never enabled before the expected phrase is known', () {
      const input = DeleteConfirmationInput();
      expect(input.isConfirmationEnabled, isFalse);
    });
  });

  test('starts confirming, with nothing typed and nothing enabled', () {
    final cubit = buildCubit();
    expect(cubit.state.status, DeleteStatus.confirming);
    expect(cubit.state.input.isConfirmationEnabled, isFalse);
    expect(cubit.state.canConfirm, isFalse);
  });

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'typing the expected phrase enables confirmation',
    build: buildCubit,
    act: (cubit) => cubit
      ..setExpectedPhrase(phrase)
      ..updateTypedPhrase('DEL')
      ..updateTypedPhrase(phrase),
    expect: () => [
      const DeleteAccountState(
        input: DeleteConfirmationInput(expectedPhrase: phrase),
      ),
      const DeleteAccountState(
        input: DeleteConfirmationInput(
          expectedPhrase: phrase,
          typedPhrase: 'DEL',
        ),
      ),
      ready,
    ],
    verify: (cubit) => expect(cubit.state.canConfirm, isTrue),
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'confirmDelete before the phrase matches does nothing',
    build: buildCubit,
    seed: () => const DeleteAccountState(
      input: DeleteConfirmationInput(expectedPhrase: phrase, typedPhrase: 'x'),
    ),
    act: (cubit) => cubit.confirmDelete(),
    expect: () => <DeleteAccountState>[],
    verify: (_) {
      verifyNever(() => deleteAllUserData());
      verifyNever(() => onboardingCubit.initialize());
    },
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'success: inProgress -> success, re-resolving onboarding exactly once',
    build: () {
      when(
        () => deleteAllUserData(),
      ).thenAnswer((_) async => const Right(unit));
      return buildCubit();
    },
    seed: () => ready,
    act: (cubit) => cubit.confirmDelete(),
    expect: () => [
      ready.copyWith(status: DeleteStatus.inProgress),
      ready.copyWith(status: DeleteStatus.success),
    ],
    verify: (_) {
      verify(() => deleteAllUserData()).called(1);
      verify(() => onboardingCubit.initialize()).called(1);
    },
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'onboarding is re-resolved only after the wipe has succeeded',
    build: () {
      when(
        () => deleteAllUserData(),
      ).thenAnswer((_) async => const Right(unit));
      return buildCubit();
    },
    seed: () => ready,
    act: (cubit) => cubit.confirmDelete(),
    verify: (_) {
      verifyInOrder([
        () => deleteAllUserData(),
        () => onboardingCubit.initialize(),
      ]);
    },
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'failure: inProgress -> error carrying the failure; onboarding untouched',
    build: () {
      when(
        () => deleteAllUserData(),
      ).thenAnswer((_) async => const Left(failure));
      return buildCubit();
    },
    seed: () => ready,
    act: (cubit) => cubit.confirmDelete(),
    expect: () => [
      ready.copyWith(status: DeleteStatus.inProgress),
      ready.copyWith(status: DeleteStatus.error, failure: failure),
    ],
    verify: (cubit) {
      verifyNever(() => onboardingCubit.initialize());
      // The typed phrase survives, so the user can retry straight away.
      expect(cubit.state.hasFailed, isTrue);
      expect(cubit.state.canConfirm, isTrue);
    },
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'a retry after a failure runs the wipe again and can succeed',
    build: () {
      var calls = 0;
      when(() => deleteAllUserData()).thenAnswer(
        (_) async => calls++ == 0 ? const Left(failure) : const Right(unit),
      );
      return buildCubit();
    },
    seed: () => ready,
    act: (cubit) async {
      await cubit.confirmDelete();
      await cubit.confirmDelete();
    },
    expect: () => [
      ready.copyWith(status: DeleteStatus.inProgress),
      ready.copyWith(status: DeleteStatus.error, failure: failure),
      ready.copyWith(status: DeleteStatus.inProgress),
      ready.copyWith(status: DeleteStatus.success),
    ],
    verify: (_) {
      verify(() => deleteAllUserData()).called(2);
      verify(() => onboardingCubit.initialize()).called(1);
    },
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'a rapid double tap runs the wipe exactly once (FR-021)',
    build: () {
      final completer = Completer<Either<Failure, Unit>>();
      when(() => deleteAllUserData()).thenAnswer((_) => completer.future);
      Future<void>.delayed(
        Duration.zero,
        () => completer.complete(right(unit)),
      );
      return buildCubit();
    },
    seed: () => ready,
    act: (cubit) async {
      final first = cubit.confirmDelete();
      final second = cubit.confirmDelete();
      await Future.wait([first, second]);
    },
    expect: () => [
      ready.copyWith(status: DeleteStatus.inProgress),
      ready.copyWith(status: DeleteStatus.success),
    ],
    verify: (_) {
      verify(() => deleteAllUserData()).called(1);
      verify(() => onboardingCubit.initialize()).called(1);
    },
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'confirmDelete after success never runs a second wipe',
    build: () {
      when(
        () => deleteAllUserData(),
      ).thenAnswer((_) async => const Right(unit));
      return buildCubit();
    },
    seed: () => ready,
    act: (cubit) async {
      await cubit.confirmDelete();
      await cubit.confirmDelete();
    },
    verify: (_) => verify(() => deleteAllUserData()).called(1),
  );
}
