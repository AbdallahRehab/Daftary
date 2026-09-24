import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_failures.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/entities/pin_credential.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

/// AppLockRepositoryImpl against an in-memory secure storage, per
/// contracts/app_lock_repository.md.
void main() {
  late FakeSecureAppLockStorage storage;
  late DateTime now;
  late AppLockRepositoryImpl repository;

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
  });

  T right<T>(Either<Failure, T> result) =>
      result.getOrElse((f) => throw StateError('expected Right, got $f'));

  Failure left<T>(Either<Failure, T> result) =>
      result.swap().getOrElse((_) => throw StateError('expected Left'));

  group('getConfig', () {
    test('defaults when never configured', () async {
      expect(
        right(await repository.getConfig()),
        const AppLockConfig.initial(),
      );
      expect(
        right(await repository.getConfig()).inactivityTimeout,
        InactivityTimeout.after1min,
      );
    });

    test('storage error -> CacheFailure without leaking details', () async {
      storage.throwOnNextCall = Exception('keystore exploded 1234');
      final failure = left(await repository.getConfig());
      expect(failure, isA<CacheFailure>());
      expect(failure.message, isNot(contains('1234')));
    });
  });

  group('setPin', () {
    test('stores a hashed credential and adds pin, without enabling', () async {
      right(await repository.setPin('1234'));
      expect(storage.credential, isNotNull);
      expect(storage.credential!.hash, isNot(contains('1234')));
      final config = right(await repository.getConfig());
      expect(config.isEnabled, isFalse);
      expect(config.activeUnlockMethods, {UnlockMethod.pin});
      expect(config.pinLastChangedAt, now);
    });

    test('rejects a malformed PIN with ValidationFailure (FR-003)', () async {
      for (final pin in ['123', '1234567', '12ab']) {
        expect(left(await repository.setPin(pin)), isA<ValidationFailure>());
      }
      expect(storage.credential, isNull);
    });

    test('rejects when a PIN already exists', () async {
      right(await repository.setPin('1234'));
      final before = storage.credential;
      expect(left(await repository.setPin('5678')), isA<ValidationFailure>());
      expect(storage.credential, before);
    });
  });

  group('enable/disable', () {
    test('enable requires a PIN first (FR-002)', () async {
      expect(left(await repository.enableAppLock()), isA<NotFoundFailure>());
      expect(right(await repository.getConfig()).isEnabled, isFalse);
    });

    test('enable after setPin', () async {
      right(await repository.setPin('1234'));
      right(await repository.enableAppLock());
      final config = right(await repository.getConfig());
      expect(config.isEnabled, isTrue);
      expect(config.hasPin, isTrue);
    });

    test(
      'disable wipes credential and lockout, keeps timeout (FR-027)',
      () async {
        right(await repository.setPin('1234'));
        right(await repository.enableAppLock());
        right(await repository.setBiometricEnabled(true));
        right(
          await repository.setInactivityTimeout(InactivityTimeout.after5min),
        );
        right(await repository.recordFailedPinAttempt());

        right(await repository.disableAppLock());

        expect(storage.credential, isNull);
        expect(storage.lockout, isNull);
        final config = right(await repository.getConfig());
        expect(config.isEnabled, isFalse);
        expect(config.activeUnlockMethods, isEmpty);
        expect(config.pinLastChangedAt, isNull);
        expect(config.inactivityTimeout, InactivityTimeout.after5min);
        // Re-enabling requires fresh PIN setup.
        expect(left(await repository.enableAppLock()), isA<NotFoundFailure>());
        right(await repository.setPin('9999'));
      },
    );
  });

  group('verifyPin', () {
    setUp(() async {
      right(await repository.setPin('1234'));
      right(await repository.enableAppLock());
    });

    test('true for the right PIN, false for a wrong one', () async {
      expect(right(await repository.verifyPin('1234')), isTrue);
      expect(right(await repository.verifyPin('4321')), isFalse);
    });

    test('a wrong PIN does not itself touch the counter', () async {
      right(await repository.verifyPin('0000'));
      expect(right(await repository.getLockoutState()), LockoutState.initial);
    });

    test('success resets the lockout (FR-014)', () async {
      for (var i = 0; i < 3; i++) {
        right(await repository.recordFailedPinAttempt());
      }
      expect(right(await repository.verifyPin('1234')), isTrue);
      expect(right(await repository.getLockoutState()), LockoutState.initial);
    });

    test('short-circuits with PinLockedOutFailure during a cooldown', () async {
      for (var i = 0; i < 5; i++) {
        right(await repository.recordFailedPinAttempt());
      }
      now = now.add(const Duration(seconds: 10));
      final failure = left(await repository.verifyPin('1234'));
      expect(failure, isA<PinLockedOutFailure>());
      expect(
        (failure as PinLockedOutFailure).remainingCooldown,
        const Duration(seconds: 20),
      );
      // Even the correct PIN did not reset the counter.
      expect(
        right(await repository.getLockoutState()).consecutiveFailedAttempts,
        5,
      );

      now = now.add(const Duration(seconds: 20));
      expect(right(await repository.verifyPin('1234')), isTrue);
    });

    test('T047: a cooldown refuses WITHOUT comparing the submitted PIN, '
        'reporting the exact remaining time', () async {
      final hasher = _CountingPinHasher(Pbkdf2PinHasher(iterations: 5));
      final counted = AppLockRepositoryImpl(
        storage,
        hasher,
        const EscalatingLockoutPolicy(),
        clock: () => now,
        runPinWork: runPinWorkInline,
      );
      for (var i = 0; i < 5; i++) {
        right(await counted.recordFailedPinAttempt());
      }
      now = now.add(const Duration(seconds: 7));

      for (final attempt in ['1234', '0000']) {
        final failure = left(await counted.verifyPin(attempt));
        expect(failure, isA<PinLockedOutFailure>());
        expect(
          (failure as PinLockedOutFailure).remainingCooldown,
          const Duration(seconds: 23),
        );
      }
      expect(hasher.verifyCalls, 0);

      now = now.add(const Duration(seconds: 23));
      expect(right(await counted.verifyPin('1234')), isTrue);
      expect(hasher.verifyCalls, 1);
    });

    test('NotFoundFailure when no PIN is set', () async {
      right(await repository.disableAppLock());
      expect(left(await repository.verifyPin('1234')), isA<NotFoundFailure>());
    });
  });

  group('recordFailedPinAttempt (FR-013/FR-015)', () {
    test('escalates per LockoutPolicy and persists', () async {
      LockoutState state = LockoutState.initial;
      for (var i = 1; i <= 4; i++) {
        state = right(await repository.recordFailedPinAttempt());
        expect(state.cooldownEndsAt, isNull);
      }
      state = right(await repository.recordFailedPinAttempt());
      expect(state.consecutiveFailedAttempts, 5);
      expect(state.cooldownEndsAt, now.add(const Duration(seconds: 30)));
      expect(storage.lockout, state);

      for (var i = 6; i <= 8; i++) {
        state = right(await repository.recordFailedPinAttempt());
      }
      expect(state.cooldownEndsAt, now.add(const Duration(minutes: 2)));
    });

    test('state survives a new repository instance (relaunch)', () async {
      for (var i = 0; i < 5; i++) {
        right(await repository.recordFailedPinAttempt());
      }
      final relaunched = AppLockRepositoryImpl(
        storage,
        Pbkdf2PinHasher(iterations: 5),
        const EscalatingLockoutPolicy(),
        clock: () => now,
        runPinWork: runPinWorkInline,
      );
      final state = right(await relaunched.getLockoutState());
      expect(state.consecutiveFailedAttempts, 5);
      expect(state.isLockedOutAt(now), isTrue);
    });

    test('resetLockout clears counter and cooldown', () async {
      for (var i = 0; i < 5; i++) {
        right(await repository.recordFailedPinAttempt());
      }
      right(await repository.resetLockout());
      expect(right(await repository.getLockoutState()), LockoutState.initial);
    });
  });

  group('changePin', () {
    test('NotFoundFailure without an existing PIN', () async {
      expect(left(await repository.changePin('5678')), isA<NotFoundFailure>());
    });

    test('replaces the PIN and resets the lockout', () async {
      right(await repository.setPin('1234'));
      for (var i = 0; i < 5; i++) {
        right(await repository.recordFailedPinAttempt());
      }
      now = now.add(const Duration(hours: 1));
      right(await repository.changePin('567890'));

      expect(right(await repository.getLockoutState()), LockoutState.initial);
      expect(right(await repository.verifyPin('567890')), isTrue);
      expect(right(await repository.verifyPin('1234')), isFalse);
      expect(right(await repository.getConfig()).pinLastChangedAt, now);
    });

    test('rejects a malformed new PIN', () async {
      right(await repository.setPin('1234'));
      expect(left(await repository.changePin('12')), isA<ValidationFailure>());
      expect(right(await repository.verifyPin('1234')), isTrue);
    });
  });

  group('settings', () {
    test('setBiometricEnabled toggles biometric only', () async {
      right(await repository.setPin('1234'));
      right(await repository.setBiometricEnabled(true));
      expect(right(await repository.getConfig()).activeUnlockMethods, {
        UnlockMethod.pin,
        UnlockMethod.biometric,
      });
      right(await repository.setBiometricEnabled(false));
      expect(right(await repository.getConfig()).activeUnlockMethods, {
        UnlockMethod.pin,
      });
    });

    test('setInactivityTimeout persists', () async {
      right(
        await repository.setInactivityTimeout(InactivityTimeout.immediately),
      );
      expect(
        right(await repository.getConfig()).inactivityTimeout,
        InactivityTimeout.immediately,
      );
    });
  });

  test('default runner hashes on a background isolate', () async {
    final isolated = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
    );
    right(await isolated.setPin('1234'));
    expect(right(await isolated.verifyPin('1234')), isTrue);
    expect(right(await isolated.verifyPin('4321')), isFalse);
  });
}

/// Delegating [PinHasher] that counts `verify` calls (T047).
class _CountingPinHasher implements PinHasher {
  _CountingPinHasher(this._inner);

  final PinHasher _inner;
  int verifyCalls = 0;

  @override
  void validate(String rawPin) => _inner.validate(rawPin);

  @override
  PinCredential hash(String rawPin) => _inner.hash(rawPin);

  @override
  bool verify(String rawPin, PinCredential credential) {
    verifyCalls++;
    return _inner.verify(rawPin, credential);
  }
}
