import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_failures.dart';
import 'package:daftary/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_biometric_enabled.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAppLockRepository extends Mock implements AppLockRepository {}

class MockBiometricService extends Mock implements BiometricService {}

/// T037 — biometric unlock can only be turned on when the device can do it
/// right now (FR-005/FR-007).
void main() {
  late MockAppLockRepository repository;
  late MockBiometricService biometrics;
  late SetBiometricEnabled setBiometricEnabled;

  setUp(() {
    repository = MockAppLockRepository();
    biometrics = MockBiometricService();
    setBiometricEnabled = SetBiometricEnabled(repository, biometrics);
    when(
      () => repository.setBiometricEnabled(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  test('enables when biometrics are available', () async {
    when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
    expect(await setBiometricEnabled(true), const Right<Failure, Unit>(unit));
    verify(() => repository.setBiometricEnabled(true)).called(1);
  });

  test('refuses with a clear BiometricUnavailableFailure otherwise, '
      'changing nothing', () async {
    when(() => biometrics.isAvailable()).thenAnswer((_) async => false);
    final result = await setBiometricEnabled(true);
    final failure = result.swap().getOrElse((_) => throw StateError('Left'));
    expect(failure, isA<BiometricUnavailableFailure>());
    expect(failure.message, isNotEmpty);
    verifyNever(() => repository.setBiometricEnabled(any()));
  });

  test('disabling never needs the device', () async {
    expect(await setBiometricEnabled(false), const Right<Failure, Unit>(unit));
    verify(() => repository.setBiometricEnabled(false)).called(1);
    verifyNever(() => biometrics.isAvailable());
  });

  test('passes a storage failure through', () async {
    when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
    when(
      () => repository.setBiometricEnabled(true),
    ).thenAnswer((_) async => const Left(CacheFailure('x')));
    expect(
      await setBiometricEnabled(true),
      const Left<Failure, Unit>(CacheFailure('x')),
    );
  });
}
