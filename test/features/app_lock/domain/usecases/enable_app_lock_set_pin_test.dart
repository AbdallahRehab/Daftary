import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_failures.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/enable_app_lock.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_pin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

/// T025 — `EnableAppLock` / `SetPin` against the real repository over
/// in-memory secure storage (FR-002/FR-003).
void main() {
  late FakeSecureAppLockStorage storage;
  late AppLockRepositoryImpl repository;
  late SetPin setPin;
  late EnableAppLock enableAppLock;

  setUp(() {
    storage = FakeSecureAppLockStorage();
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      runPinWork: runPinWorkInline,
    );
    setPin = SetPin(repository);
    enableAppLock = EnableAppLock(repository);
  });

  Failure left<T>(Either<Failure, T> result) =>
      result.swap().getOrElse((_) => throw StateError('expected Left'));

  group('EnableAppLock', () {
    test('fails with a clear NotFoundFailure before any PIN is set '
        '(FR-002)', () async {
      final failure = left(await enableAppLock());
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, contains('PIN'));
      expect(storage.config?.isEnabled ?? false, isFalse);
    });

    test('enables once a PIN is set', () async {
      expect(await setPin('1234'), const Right<Failure, Unit>(unit));
      expect(await enableAppLock(), const Right<Failure, Unit>(unit));
      expect(storage.config!.isEnabled, isTrue);
      expect(storage.config!.hasPin, isTrue);
    });

    test('surfaces a storage error as CacheFailure', () async {
      storage.throwOnNextCall = Exception('keystore');
      expect(left(await enableAppLock()), isA<CacheFailure>());
    });
  });

  group('SetPin', () {
    test('stores a hashed credential without enabling App Lock', () async {
      expect(
        await setPin('1234', confirmation: '1234'),
        const Right<Failure, Unit>(unit),
      );
      expect(storage.credential, isNotNull);
      expect(storage.credential.toString(), isNot(contains('1234')));
      expect(storage.config!.isEnabled, isFalse);
    });

    for (final bad in ['123', '1234567', '12a4', '', ' 1234']) {
      test('rejects "$bad" with ValidationFailure (FR-003)', () async {
        expect(left(await setPin(bad)), isA<ValidationFailure>());
        expect(storage.credential, isNull);
      });
    }

    test('rejects a mismatched confirm-entry with PinMismatchFailure, '
        'persisting nothing', () async {
      expect(
        left(await setPin('1234', confirmation: '1243')),
        isA<PinMismatchFailure>(),
      );
      expect(storage.credential, isNull);
      expect(storage.config, isNull);
    });

    test('replaces a credential left by an abandoned setup (App Lock '
        'never enabled)', () async {
      await setPin('1234');
      final first = storage.credential;
      expect(await setPin('5678'), const Right<Failure, Unit>(unit));
      expect(storage.credential, isNot(first));
      expect(
        await repository.verifyPin('5678'),
        const Right<Failure, bool>(true),
      );
    });

    test('never overwrites the PIN while App Lock is enabled — that is '
        'ChangePin behind re-authentication (FR-023)', () async {
      await setPin('1234');
      await enableAppLock();
      expect(left(await setPin('5678')), isA<ValidationFailure>());
      expect(
        await repository.verifyPin('1234'),
        const Right<Failure, bool>(true),
      );
    });

    test('default config after a set still has the 1-minute timeout', () async {
      await setPin('1234');
      expect(storage.config!.inactivityTimeout, InactivityTimeout.after1min);
    });
  });
}
