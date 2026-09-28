import 'dart:convert';

import 'package:daftary/features/app_lock/data/datasources/secure_app_lock_storage.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_failures.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/entities/pin_credential.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// T015 — round-trips against flutter_secure_storage's in-memory test
/// platform (never the real Keychain/Keystore).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterSecureStorage raw;
  late SecureAppLockStorageImpl storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    raw = const FlutterSecureStorage();
    storage = SecureAppLockStorageImpl(raw);
  });

  test('everything reads null before anything is written', () async {
    expect(await storage.readConfig(), isNull);
    expect(await storage.readPinCredential(), isNull);
    expect(await storage.readLockoutState(), isNull);
  });

  test('AppLockConfig round-trips', () async {
    final config = AppLockConfig(
      isEnabled: true,
      activeUnlockMethods: const {UnlockMethod.pin, UnlockMethod.biometric},
      inactivityTimeout: InactivityTimeout.after5min,
      pinLastChangedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    await storage.writeConfig(config);
    expect(await storage.readConfig(), config);

    const initial = AppLockConfig.initial();
    await storage.writeConfig(initial);
    expect(await storage.readConfig(), initial);
  });

  test('PinCredential round-trips', () async {
    const credential = PinCredential(
      hash: 'aGFzaA==',
      salt: 'c2FsdA==',
      iterations: 120000,
    );
    await storage.writePinCredential(credential);
    expect(await storage.readPinCredential(), credential);
  });

  test('LockoutState round-trips, with and without a cooldown', () async {
    final locked = LockoutState(
      consecutiveFailedAttempts: 5,
      cooldownEndsAt: DateTime.fromMillisecondsSinceEpoch(1700000030000),
    );
    await storage.writeLockoutState(locked);
    expect(await storage.readLockoutState(), locked);

    await storage.writeLockoutState(LockoutState.initial);
    expect(await storage.readLockoutState(), LockoutState.initial);
  });

  test('uses the app_lock.* keys from data-model.md', () async {
    await storage.writeConfig(const AppLockConfig.initial());
    await storage.writePinCredential(
      const PinCredential(hash: 'h', salt: 's', iterations: 1),
    );
    await storage.writeLockoutState(LockoutState.initial);
    final keys = (await raw.readAll()).keys.toSet();
    expect(keys, {
      'app_lock.config',
      'app_lock.pin_credential',
      'app_lock.lockout_state',
    });
  });

  test('individual deletes only remove their own key', () async {
    await storage.writeConfig(const AppLockConfig.initial());
    await storage.writePinCredential(
      const PinCredential(hash: 'h', salt: 's', iterations: 1),
    );
    await storage.writeLockoutState(LockoutState.initial);

    await storage.deletePinCredential();
    expect(await storage.readPinCredential(), isNull);
    expect(await storage.readLockoutState(), isNotNull);

    await storage.deleteLockoutState();
    expect(await storage.readLockoutState(), isNull);
    expect(await storage.readConfig(), isNotNull);
  });

  test('deleteAll removes every app_lock key and nothing else', () async {
    FlutterSecureStorage.setMockInitialValues({
      'daftary.ai_assistant.api_key.openai': 'other-feature',
    });
    await storage.writeConfig(const AppLockConfig.initial());
    await storage.writePinCredential(
      const PinCredential(hash: 'h', salt: 's', iterations: 1),
    );
    await storage.writeLockoutState(LockoutState.initial);

    await storage.deleteAll();

    expect(await raw.readAll(), {
      'daftary.ai_assistant.api_key.openai': 'other-feature',
    });
  });

  test('T048: an active lockout survives a simulated relaunch — a new '
      'storage and repository over the same secure storage (FR-015)', () async {
    var now = DateTime(2026, 9, 24, 12);
    AppLockRepositoryImpl launch() => AppLockRepositoryImpl(
      SecureAppLockStorageImpl(const FlutterSecureStorage()),
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      clock: () => now,
      runPinWork: runPinWorkInline,
    );

    final first = launch();
    await first.setPin('1234');
    await first.enableAppLock();
    for (var i = 0; i < 6; i++) {
      await first.recordFailedPinAttempt();
    }

    // "Force-quit": drop every in-memory object, start over from storage.
    now = now.add(const Duration(seconds: 10));
    final relaunched = launch();
    final lockout = (await relaunched.getLockoutState()).getOrElse(
      (f) => throw StateError('$f'),
    );
    expect(lockout.consecutiveFailedAttempts, 6);
    expect(lockout.remainingCooldownAt(now), const Duration(seconds: 20));
    final verify = await relaunched.verifyPin('1234');
    expect(
      verify.swap().getOrElse((_) => throw StateError('expected Left')),
      const PinLockedOutFailure(Duration(seconds: 20)),
    );
  });

  test(
    'a corrupted stored value throws (mapped to CacheFailure upstream)',
    () async {
      await raw.write(key: 'app_lock.config', value: 'not json');
      expect(storage.readConfig(), throwsA(isA<FormatException>()));

      await raw.write(
        key: 'app_lock.lockout_state',
        value: jsonEncode({'consecutiveFailedAttempts': 'x'}),
      );
      expect(storage.readLockoutState(), throwsA(isA<TypeError>()));
    },
  );
}
