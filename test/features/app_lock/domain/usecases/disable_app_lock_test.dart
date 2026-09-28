import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/disable_app_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

/// T071 — `DisableAppLock` clears the PIN credential and lockout state
/// (FR-027) and never touches screenshot protection (FR-020).
void main() {
  late FakeSecureAppLockStorage storage;
  late AppLockRepositoryImpl repository;
  late DisableAppLock disableAppLock;

  setUp(() async {
    storage = FakeSecureAppLockStorage();
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      runPinWork: runPinWorkInline,
    );
    disableAppLock = DisableAppLock(repository);
    await repository.setPin('1234');
    await repository.enableAppLock();
    await repository.setBiometricEnabled(true);
    await repository.setInactivityTimeout(InactivityTimeout.after5min);
    for (var i = 0; i < 3; i++) {
      await repository.recordFailedPinAttempt();
    }
  });

  test('disables App Lock and deletes the PIN credential and lockout '
      'state', () async {
    expect(storage.credential, isNotNull);
    expect(storage.lockout, isNotNull);

    expect(await disableAppLock(), const Right<Failure, Unit>(unit));

    expect(storage.credential, isNull);
    expect(storage.lockout, isNull);
    final config = (await repository.getConfig()).getOrElse((f) => fail('$f'));
    expect(config.isEnabled, isFalse);
    expect(config.activeUnlockMethods, isEmpty);
  });

  test('the old PIN cannot be reused: re-enabling needs a fresh '
      'SetPin (FR-027)', () async {
    await disableAppLock();

    expect(
      (await repository.enableAppLock()).getLeft().toNullable(),
      isA<NotFoundFailure>(),
    );
    expect(
      (await repository.verifyPin('1234')).getLeft().toNullable(),
      isA<NotFoundFailure>(),
    );
    expect((await repository.setPin('9876')).isRight(), isTrue);
  });

  test('keeps the inactivity timeout preference', () async {
    await disableAppLock();
    expect(storage.config?.inactivityTimeout, InactivityTimeout.after5min);
  });

  // FR-020: screenshot protection is independent of App Lock. The use case
  // has no path to it — pinned at the source level, like main.dart's
  // unconditional enable() in screenshot_protection_service_test.dart.
  test('leaves screenshot protection untouched (FR-020)', () {
    final source = File(
      'lib/features/app_lock/domain/usecases/disable_app_lock.dart',
    ).readAsStringSync();
    final code = source
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
    expect(code, isNot(contains('ScreenshotProtection')));
    expect(code, isNot(contains('core/security')));
  });

  test('storage error -> Left', () async {
    storage.throwOnNextCall = Exception('keystore');
    expect((await disableAppLock()).isLeft(), isTrue);
  });
}
