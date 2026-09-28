import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_failures.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/change_pin.dart';
import 'package:daftary/features/app_lock/domain/usecases/recover_via_biometric.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

class FakeBiometricService implements BiometricService {
  bool available = true;
  bool succeeds = true;
  final List<String> prompts = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    prompts.add(localizedReason);
    return succeeds;
  }
}

/// T056 — `RecoverViaBiometric` is the Forgot-PIN path's zero-data-loss
/// branch (FR-017): a genuine biometric check, after which `ChangePin` sets
/// a new PIN — and nothing outside App Lock's own PIN credential (and the
/// lockout it clears) changes. Runs against the real
/// `AppLockRepositoryImpl` over in-memory secure storage.
void main() {
  const oldPin = '1357';
  const newPin = '246810';
  const reason = 'Verify to reset your PIN';

  late FakeSecureAppLockStorage storage;
  late AppLockRepositoryImpl repository;
  late FakeBiometricService biometric;
  late RecoverViaBiometric recover;
  late ChangePin changePin;

  setUp(() async {
    storage = FakeSecureAppLockStorage();
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      clock: () => DateTime(2026, 9, 24, 12),
      runPinWork: runPinWorkInline,
    );
    biometric = FakeBiometricService();
    recover = RecoverViaBiometric(repository, biometric);
    changePin = ChangePin(repository);

    await repository.setPin(oldPin);
    await repository.enableAppLock();
    await repository.setBiometricEnabled(true);
    // The user has been guessing: 6 failures, cooldown running.
    for (var i = 0; i < 6; i++) {
      await repository.recordFailedPinAttempt();
    }
  });

  test('offered only when biometric is enabled AND the device can do '
      'it', () async {
    expect(await recover.isAvailable(), isTrue);

    biometric.available = false;
    expect(await recover.isAvailable(), isFalse);

    biometric.available = true;
    await repository.setBiometricEnabled(false);
    expect(await recover.isAvailable(), isFalse);
  });

  test('unavailable -> BiometricUnavailableFailure without prompting or '
      'touching storage', () async {
    biometric.available = false;
    final before = (storage.config, storage.credential, storage.lockout);

    expect(
      await recover(localizedReason: reason),
      const Left<Failure, bool>(BiometricUnavailableFailure()),
    );
    expect(biometric.prompts, isEmpty);
    expect((storage.config, storage.credential, storage.lockout), before);
  });

  test('a cancelled/failed prompt -> Right(false) and changes '
      'nothing', () async {
    biometric.succeeds = false;
    final before = (storage.config, storage.credential, storage.lockout);

    expect(
      await recover(localizedReason: reason),
      const Right<Failure, bool>(false),
    );
    expect(biometric.prompts, [reason]);
    expect((storage.config, storage.credential, storage.lockout), before);
  });

  test('success lets ChangePin set a new PIN with zero other side '
      'effects', () async {
    final configBefore = storage.config!;
    final credentialBefore = storage.credential;

    expect(
      await recover(localizedReason: reason),
      const Right<Failure, bool>(true),
    );
    // A genuine authentication clears the PIN lockout (FR-014) …
    expect(storage.lockout ?? LockoutState.initial, LockoutState.initial);
    // … but the PIN itself is only replaced by ChangePin.
    expect(storage.credential, credentialBefore);

    expect(
      await changePin(newPin, confirmation: newPin),
      const Right<Failure, Unit>(unit),
    );

    expect(storage.credential, isNot(credentialBefore));
    expect(
      await repository.verifyPin(newPin),
      const Right<Failure, bool>(true),
    );
    expect(
      await repository.verifyPin(oldPin),
      const Right<Failure, bool>(false),
    );
    // App Lock stays enabled with the same methods and timeout — only the
    // PIN's change timestamp moves.
    final configAfter = storage.config!;
    expect(configAfter.isEnabled, configBefore.isEnabled);
    expect(configAfter.activeUnlockMethods, configBefore.activeUnlockMethods);
    expect(configAfter.inactivityTimeout, configBefore.inactivityTimeout);
  });
}
