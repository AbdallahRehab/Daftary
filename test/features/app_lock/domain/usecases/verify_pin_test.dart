import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

/// T026 — `VerifyPin` maps the repository's answer to an
/// [UnlockAttemptResult] and never touches the failed-attempt counter
/// itself (the Cubit calls `RecordFailedPinAttempt` separately).
void main() {
  late FakeSecureAppLockStorage storage;
  late DateTime now;
  late AppLockRepositoryImpl repository;
  late VerifyPin verifyPin;

  setUp(() async {
    storage = FakeSecureAppLockStorage();
    now = DateTime(2026, 9, 24, 12);
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      clock: () => now,
      runPinWork: runPinWorkInline,
    );
    verifyPin = VerifyPin(repository);
    await repository.setPin('1234');
    await repository.enableAppLock();
  });

  test('correct PIN -> success, and the lockout state is reset '
      '(FR-014)', () async {
    for (var i = 0; i < 3; i++) {
      await repository.recordFailedPinAttempt();
    }
    expect(
      await verifyPin('1234'),
      const Right<Failure, UnlockAttemptResult>(UnlockAttemptResult.success()),
    );
    expect(storage.lockout, LockoutState.initial);
  });

  test('incorrect PIN -> incorrectPin, and the counter is NOT '
      'incremented', () async {
    await repository.recordFailedPinAttempt();
    expect(
      await verifyPin('9999'),
      const Right<Failure, UnlockAttemptResult>(
        UnlockAttemptResult(outcome: UnlockOutcome.incorrectPin),
      ),
    );
    expect(storage.lockout!.consecutiveFailedAttempts, 1);
  });

  test('during a cooldown -> lockedOut with the time left, even for the '
      'correct PIN', () async {
    for (var i = 0; i < 5; i++) {
      await repository.recordFailedPinAttempt();
    }
    now = now.add(const Duration(seconds: 12));
    expect(
      await verifyPin('1234'),
      const Right<Failure, UnlockAttemptResult>(
        UnlockAttemptResult.lockedOut(Duration(seconds: 18)),
      ),
    );
    expect(storage.lockout!.consecutiveFailedAttempts, 5);
  });

  test('no PIN stored -> NotFoundFailure stays a Left', () async {
    await repository.disableAppLock();
    final result = await verifyPin('1234');
    expect(result.isLeft(), isTrue);
    expect(
      result.swap().getOrElse((_) => throw StateError('Left expected')),
      isA<NotFoundFailure>(),
    );
  });
}
