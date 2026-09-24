import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_failures.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/change_pin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

/// T069 — `ChangePin` against the real repository over in-memory secure
/// storage.
///
/// The "re-authenticate first" rule (FR-023) is deliberately NOT in this
/// use case, which trusts its caller (contracts/app_lock_repository.md): it
/// is enforced by `PinSetupPage`'s change mode, which verifies the current
/// PIN or biometrics before ever calling `ChangePin`, and by
/// `AppLockSettingsCubit`, which only offers Change PIN through that page
/// (see app_lock_settings_cubit_test.dart).
void main() {
  late FakeSecureAppLockStorage storage;
  late DateTime now;
  late AppLockRepositoryImpl repository;
  late ChangePin changePin;

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
    changePin = ChangePin(repository);
    await repository.setPin('1234');
    await repository.enableAppLock();
  });

  test('replaces the PIN: the new one verifies, the old one no longer '
      'does', () async {
    expect(await changePin('567890'), const Right<Failure, Unit>(unit));

    expect(
      await repository.verifyPin('567890'),
      const Right<Failure, bool>(true),
    );
    expect(
      await repository.verifyPin('1234'),
      const Right<Failure, bool>(false),
    );
  });

  test('resets the lockout state on success (data-model.md '
      'Assumptions)', () async {
    for (var i = 0; i < 5; i++) {
      await repository.recordFailedPinAttempt();
    }
    expect(storage.lockout?.consecutiveFailedAttempts, 5);

    await changePin('567890');

    final lockout = (await repository.getLockoutState()).getOrElse(
      (f) => fail('$f'),
    );
    expect(lockout, LockoutState.initial);
  });

  test('leaves App Lock enabled', () async {
    await changePin('567890');
    final config = (await repository.getConfig()).getOrElse((f) => fail('$f'));
    expect(config.isEnabled, isTrue);
    expect(config.hasPin, isTrue);
  });

  test('an invalid new PIN is rejected and the old PIN keeps '
      'working', () async {
    final result = await changePin('12');

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    expect(
      await repository.verifyPin('1234'),
      const Right<Failure, bool>(true),
    );
  });

  test('a mismatched confirmation persists nothing', () async {
    final result = await changePin('567890', confirmation: '567891');

    expect(result.getLeft().toNullable(), isA<PinMismatchFailure>());
    expect(
      await repository.verifyPin('1234'),
      const Right<Failure, bool>(true),
    );
  });

  test('with no PIN configured -> NotFoundFailure', () async {
    storage
      ..credential = null
      ..config = null;

    final result = await changePin('567890');

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });
}
