import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../data_privacy/domain/services/secure_storage_wiper.dart';
import '../../domain/entities/app_lock_config.dart';
import '../../domain/entities/lockout_state.dart';
import '../../domain/entities/pin_credential.dart';
import '../datasources/secure_app_lock_storage.dart';

/// App Lock's side of the canonical full-data wipe (015 T085): clears all
/// three `app_lock.*` keys (config, PIN credential, lockout state) whenever
/// `DeleteAllUserData` runs — from 013's "Delete my data" or 015's
/// Forgot-PIN wipe alike.
///
/// All-or-nothing via a snapshot (see [SecureStorageWiper]): every value is
/// read before anything is deleted, so a failed delete here — or a failed
/// database wipe afterwards — can put each key back exactly.
///
/// Failure messages carry only the exception type, never a stored value
/// (FR-016).
@LazySingleton(as: SecureStorageWiper)
class AppLockSecureStorageWiper implements SecureStorageWiper {
  AppLockSecureStorageWiper(this._storage);

  final SecureAppLockStorage _storage;

  @override
  Future<Either<Failure, SecureStorageRestore>> wipe() async {
    final _Snapshot snapshot;
    try {
      snapshot = _Snapshot(
        config: await _storage.readConfig(),
        credential: await _storage.readPinCredential(),
        lockout: await _storage.readLockoutState(),
      );
    } catch (e) {
      // Nothing deleted yet — refusing keeps the wipe restorable.
      return Left(_cache('read App Lock data before erasing it', e));
    }

    Future<Either<Failure, Unit>> restore() => _restore(snapshot);

    try {
      await _storage.deleteAll();
    } catch (e) {
      await restore();
      return Left(_cache('erase App Lock data', e));
    }
    return Right(restore);
  }

  /// Rewrites every snapshotted key. The config goes first so that, should
  /// a later write also fail, App Lock is left enabled — failing closed
  /// (still locked) rather than open. Keys that did not exist at snapshot
  /// time are deleted again, so the result matches the snapshot exactly.
  Future<Either<Failure, Unit>> _restore(_Snapshot snapshot) async {
    try {
      final config = snapshot.config;
      final credential = snapshot.credential;
      final lockout = snapshot.lockout;
      if (config != null) await _storage.writeConfig(config);
      if (credential != null) {
        await _storage.writePinCredential(credential);
      } else {
        await _storage.deletePinCredential();
      }
      if (lockout != null) {
        await _storage.writeLockoutState(lockout);
      } else {
        await _storage.deleteLockoutState();
      }
      return const Right(unit);
    } catch (e) {
      return Left(_cache('restore App Lock data', e));
    }
  }

  CacheFailure _cache(String action, Object error) =>
      CacheFailure('Failed to $action: ${error.runtimeType}');
}

class _Snapshot {
  const _Snapshot({this.config, this.credential, this.lockout});

  final AppLockConfig? config;
  final PinCredential? credential;
  final LockoutState? lockout;
}
