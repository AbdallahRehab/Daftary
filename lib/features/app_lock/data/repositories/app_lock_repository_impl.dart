import 'dart:isolate';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/app_lock_config.dart';
import '../../domain/entities/app_lock_failures.dart';
import '../../domain/entities/lockout_state.dart';
import '../../domain/entities/pin_credential.dart';
import '../../domain/repositories/app_lock_repository.dart';
import '../../domain/services/lockout_policy.dart';
import '../../domain/services/pin_hasher.dart';
import '../datasources/secure_app_lock_storage.dart';

/// Runs one CPU-heavy PIN hashing operation. Production runs it on a
/// background isolate so the deliberately slow KDF never janks the lock
/// screen; tests pass [runPinWorkInline].
typedef PinWorkRunner = Future<T> Function<T>(T Function() work);

/// Runs [work] synchronously on the current isolate (tests, or callers that
/// already are off the UI isolate).
Future<T> runPinWorkInline<T>(T Function() work) async => work();

Future<T> _runPinWorkInIsolate<T>(T Function() work) => Isolate.run(work);

/// [AppLockRepository] over [SecureAppLockStorage], composing [PinHasher]
/// and [LockoutPolicy] per contracts/app_lock_repository.md.
///
/// PIN hygiene: the raw PIN only flows *into* this class, is handed to the
/// hasher, and is never stored, logged, or interpolated into a [Failure]
/// message (FR-004/FR-016). Failure messages carry only the exception type.
@LazySingleton(as: AppLockRepository)
class AppLockRepositoryImpl implements AppLockRepository {
  AppLockRepositoryImpl(
    this._storage,
    this._hasher,
    this._policy, {
    @ignoreParam DateTime Function()? clock,
    @ignoreParam PinWorkRunner? runPinWork,
  }) : _now = clock ?? DateTime.now,
       _runPinWork = runPinWork ?? _runPinWorkInIsolate;

  final SecureAppLockStorage _storage;
  final PinHasher _hasher;
  final LockoutPolicy _policy;
  final DateTime Function() _now;
  final PinWorkRunner _runPinWork;

  // ----------------------------------------------------------------- config

  @override
  Future<Either<Failure, AppLockConfig>> getConfig() async {
    try {
      return Right(await _readConfig());
    } catch (e) {
      return Left(_cache('load the App Lock configuration', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> enableAppLock() async {
    try {
      final credential = await _storage.readPinCredential();
      if (credential == null) {
        return const Left(
          NotFoundFailure('Set a PIN before enabling App Lock'),
        );
      }
      final config = await _readConfig();
      await _storage.writeConfig(
        config.copyWith(
          isEnabled: true,
          activeUnlockMethods: {
            ...config.activeUnlockMethods,
            UnlockMethod.pin,
          },
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(_cache('enable App Lock', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> disableAppLock() async {
    try {
      // Credential first: whatever fails after this, no stale PIN can be
      // silently reused by a later re-enable (FR-027).
      await _storage.deletePinCredential();
      await _storage.deleteLockoutState();
      final config = await _readConfig();
      await _storage.writeConfig(
        config.copyWith(
          isEnabled: false,
          activeUnlockMethods: const <UnlockMethod>{},
          clearPinLastChangedAt: true,
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(_cache('disable App Lock', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> setBiometricEnabled(bool enabled) async {
    try {
      final config = await _readConfig();
      final methods = {...config.activeUnlockMethods};
      enabled
          ? methods.add(UnlockMethod.biometric)
          : methods.remove(UnlockMethod.biometric);
      await _storage.writeConfig(config.copyWith(activeUnlockMethods: methods));
      return const Right(unit);
    } catch (e) {
      return Left(_cache('update the biometric unlock setting', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> setInactivityTimeout(
    InactivityTimeout timeout,
  ) async {
    try {
      final config = await _readConfig();
      await _storage.writeConfig(config.copyWith(inactivityTimeout: timeout));
      return const Right(unit);
    } catch (e) {
      return Left(_cache('update the inactivity timeout', e));
    }
  }

  // -------------------------------------------------------------------- PIN

  @override
  Future<Either<Failure, Unit>> setPin(String rawPin) async {
    final invalid = _validate(rawPin);
    if (invalid != null) return Left(invalid);
    try {
      if (await _storage.readPinCredential() != null) {
        return const Left(
          ValidationFailure('A PIN is already set; change it instead'),
        );
      }
      await _storeNewPin(rawPin);
      return const Right(unit);
    } catch (e) {
      return Left(_cache('save the PIN', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> changePin(String newRawPin) async {
    final invalid = _validate(newRawPin);
    if (invalid != null) return Left(invalid);
    try {
      if (await _storage.readPinCredential() == null) {
        return const Left(NotFoundFailure('No PIN is set'));
      }
      await _storeNewPin(newRawPin);
      return const Right(unit);
    } catch (e) {
      return Left(_cache('change the PIN', e));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String rawPin) async {
    try {
      final lockout = await _readLockout();
      final remaining = lockout.remainingCooldownAt(_now());
      if (remaining != null) {
        // FR-013: refuse without even comparing while a cooldown runs.
        return Left(PinLockedOutFailure(remaining));
      }
      final credential = await _storage.readPinCredential();
      if (credential == null) {
        return const Left(NotFoundFailure('No PIN is set'));
      }
      final matches = await _verifyOffThread(
        _runPinWork,
        _hasher,
        rawPin,
        credential,
      );
      if (matches && lockout != LockoutState.initial) {
        await _storage.writeLockoutState(LockoutState.initial); // FR-014
      }
      return Right(matches);
    } catch (e) {
      return Left(_cache('verify the PIN', e));
    }
  }

  // ---------------------------------------------------------------- lockout

  @override
  Future<Either<Failure, LockoutState>> recordFailedPinAttempt() async {
    try {
      final current = await _readLockout();
      final attempts = current.consecutiveFailedAttempts + 1;
      final cooldown = _policy.cooldownFor(attempts);
      final next = LockoutState(
        consecutiveFailedAttempts: attempts,
        cooldownEndsAt: cooldown == null ? null : _now().add(cooldown),
      );
      await _storage.writeLockoutState(next);
      return Right(next);
    } catch (e) {
      return Left(_cache('record the failed PIN attempt', e));
    }
  }

  @override
  Future<Either<Failure, LockoutState>> getLockoutState() async {
    try {
      return Right(await _readLockout());
    } catch (e) {
      return Left(_cache('load the PIN lockout state', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetLockout() async {
    try {
      await _storage.writeLockoutState(LockoutState.initial);
      return const Right(unit);
    } catch (e) {
      return Left(_cache('reset the PIN lockout state', e));
    }
  }

  // ---------------------------------------------------------------- helpers

  Future<AppLockConfig> _readConfig() async =>
      await _storage.readConfig() ?? const AppLockConfig.initial();

  Future<LockoutState> _readLockout() async =>
      await _storage.readLockoutState() ?? LockoutState.initial;

  /// Hashes and stores [rawPin] as the credential, resets the lockout
  /// (a new PIN supersedes attempts against the old one — data-model.md
  /// Assumptions), and records `pin` + `pinLastChangedAt` on the config.
  Future<void> _storeNewPin(String rawPin) async {
    final credential = await _hashOffThread(_runPinWork, _hasher, rawPin);
    await _storage.writePinCredential(credential);
    await _storage.writeLockoutState(LockoutState.initial);
    final config = await _readConfig();
    await _storage.writeConfig(
      config.copyWith(
        activeUnlockMethods: {...config.activeUnlockMethods, UnlockMethod.pin},
        pinLastChangedAt: _now(),
      ),
    );
  }

  ValidationFailure? _validate(String rawPin) {
    try {
      _hasher.validate(rawPin);
      return null;
    } on ArgumentError {
      return const ValidationFailure('PIN must be 4-6 numeric digits');
    }
  }

  // Static so the isolate closure captures only the hasher and its inputs,
  // never `this` (and with it the storage handle).
  static Future<PinCredential> _hashOffThread(
    PinWorkRunner run,
    PinHasher hasher,
    String rawPin,
  ) => run(() => hasher.hash(rawPin));

  static Future<bool> _verifyOffThread(
    PinWorkRunner run,
    PinHasher hasher,
    String rawPin,
    PinCredential credential,
  ) => run(() => hasher.verify(rawPin, credential));

  CacheFailure _cache(String action, Object error) =>
      CacheFailure('Failed to $action (${error.runtimeType})');

  @override
  String toString() => 'AppLockRepositoryImpl';
}
