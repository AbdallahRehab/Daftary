import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_biometric.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAppLockRepository extends Mock implements AppLockRepository {}

class MockBiometricService extends Mock implements BiometricService {}

/// T038 — a biometric success resets the lockout like a correct PIN
/// (FR-014); a failure never reaches the PIN lockout path (FR-008).
void main() {
  late MockAppLockRepository repository;
  late MockBiometricService biometrics;
  late VerifyBiometric verifyBiometric;

  const reason = 'Unlock Daftary';

  setUp(() {
    repository = MockAppLockRepository();
    biometrics = MockBiometricService();
    verifyBiometric = VerifyBiometric(repository, biometrics);
    when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
    when(
      () => repository.resetLockout(),
    ).thenAnswer((_) async => const Right(unit));
  });

  test('success -> success and the lockout is reset (FR-014)', () async {
    when(
      () => biometrics.authenticate(localizedReason: reason),
    ).thenAnswer((_) async => true);

    expect(
      await verifyBiometric(localizedReason: reason),
      const Right<Failure, UnlockAttemptResult>(UnlockAttemptResult.success()),
    );
    verify(() => repository.resetLockout()).called(1);
  });

  test('cancelled/failed -> biometricFailed, with zero interactions with '
      'the PIN lockout path (FR-008)', () async {
    when(
      () => biometrics.authenticate(localizedReason: reason),
    ).thenAnswer((_) async => false);

    expect(
      await verifyBiometric(localizedReason: reason),
      const Right<Failure, UnlockAttemptResult>(
        UnlockAttemptResult(outcome: UnlockOutcome.biometricFailed),
      ),
    );
    verifyNever(() => repository.recordFailedPinAttempt());
    verifyNever(() => repository.resetLockout());
    verifyNoMoreInteractions(repository);
  });

  test('unavailable -> biometricUnavailable without prompting '
      '(FR-007)', () async {
    when(() => biometrics.isAvailable()).thenAnswer((_) async => false);

    expect(
      await verifyBiometric(localizedReason: reason),
      const Right<Failure, UnlockAttemptResult>(
        UnlockAttemptResult(outcome: UnlockOutcome.biometricUnavailable),
      ),
    );
    verifyNever(
      () => biometrics.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    );
    verifyZeroInteractions(repository);
  });

  test('a lockout-reset storage error surfaces as a Left', () async {
    when(
      () => biometrics.authenticate(localizedReason: reason),
    ).thenAnswer((_) async => true);
    when(
      () => repository.resetLockout(),
    ).thenAnswer((_) async => const Left(CacheFailure('x')));

    expect(
      await verifyBiometric(localizedReason: reason),
      const Left<Failure, UnlockAttemptResult>(CacheFailure('x')),
    );
  });
}
