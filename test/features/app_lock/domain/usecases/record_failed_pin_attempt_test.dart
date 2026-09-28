import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/record_failed_pin_attempt.dart';
import 'package:daftary/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

/// T046 — `RecordFailedPinAttempt` counts and escalates per FR-013, and can
/// never see, store or log a PIN (FR-016).
void main() {
  late FakeSecureAppLockStorage storage;
  late DateTime now;
  late AppLockRepositoryImpl repository;
  late RecordFailedPinAttempt recordFailedPinAttempt;

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
    recordFailedPinAttempt = RecordFailedPinAttempt(repository);
    await repository.setPin('246810');
    await repository.enableAppLock();
  });

  LockoutState right(Either<Failure, LockoutState> result) =>
      result.getOrElse((f) => throw StateError('expected Right, got $f'));

  test('increments the counter and applies the policy at every '
      'threshold', () async {
    const policy = EscalatingLockoutPolicy();
    for (var attempt = 1; attempt <= 14; attempt++) {
      final state = right(await recordFailedPinAttempt());
      expect(state.consecutiveFailedAttempts, attempt);
      final cooldown = policy.cooldownFor(attempt);
      expect(
        state.cooldownEndsAt,
        cooldown == null ? isNull : now.add(cooldown),
        reason: 'attempt $attempt',
      );
      expect(storage.lockout, state, reason: 'persisted (FR-015)');
    }
    // Spot-check the FR-013 schedule itself.
    expect(policy.cooldownFor(4), isNull);
    expect(policy.cooldownFor(5), const Duration(seconds: 30));
    expect(policy.cooldownFor(8), const Duration(minutes: 2));
    expect(policy.cooldownFor(11), const Duration(minutes: 5));
  });

  test('takes no parameters — a PIN can never be passed in (FR-016)', () {
    // Compile-time assertion: `call` has exactly this zero-argument shape.
    final Future<Either<Failure, LockoutState>> Function() call =
        recordFailedPinAttempt.call;
    expect(call, isNotNull);
  });

  test('a wrong-PIN round never prints, logs, or persists the attempted '
      'PIN', () async {
    const attempted = '135791';
    final captured = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) => captured.add(message ?? '');
    addTearDown(() => debugPrint = originalDebugPrint);

    await runZoned(
      () async {
        final verify = VerifyPin(repository);
        for (var i = 0; i < 6; i++) {
          final result = await verify(attempted);
          captured.add(result.toString());
          final state = await recordFailedPinAttempt();
          captured.add(state.toString());
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => captured.add(line),
      ),
    );

    captured
      ..add(storage.lockout.toString())
      ..add(storage.config.toString())
      ..add(storage.credential.toString());
    for (final line in captured) {
      expect(line, isNot(contains(attempted)));
      expect(line, isNot(contains('246810')));
    }
  });
}
