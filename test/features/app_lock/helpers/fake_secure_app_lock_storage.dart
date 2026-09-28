import 'package:daftary/features/app_lock/data/datasources/secure_app_lock_storage.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/entities/lockout_state.dart';
import 'package:daftary/features/app_lock/domain/entities/pin_credential.dart';

/// In-memory [SecureAppLockStorage] — never the real Keychain/Keystore in
/// tests. Set [throwOnNextCall] to simulate a platform storage error.
class FakeSecureAppLockStorage implements SecureAppLockStorage {
  AppLockConfig? config;
  PinCredential? credential;
  LockoutState? lockout;

  /// When non-null, the next storage call throws this and resets it.
  Object? throwOnNextCall;

  void _maybeThrow() {
    final error = throwOnNextCall;
    if (error != null) {
      throwOnNextCall = null;
      throw error;
    }
  }

  @override
  Future<AppLockConfig?> readConfig() async {
    _maybeThrow();
    return config;
  }

  @override
  Future<void> writeConfig(AppLockConfig value) async {
    _maybeThrow();
    config = value;
  }

  @override
  Future<PinCredential?> readPinCredential() async {
    _maybeThrow();
    return credential;
  }

  @override
  Future<void> writePinCredential(PinCredential value) async {
    _maybeThrow();
    credential = value;
  }

  @override
  Future<void> deletePinCredential() async {
    _maybeThrow();
    credential = null;
  }

  @override
  Future<LockoutState?> readLockoutState() async {
    _maybeThrow();
    return lockout;
  }

  @override
  Future<void> writeLockoutState(LockoutState value) async {
    _maybeThrow();
    lockout = value;
  }

  @override
  Future<void> deleteLockoutState() async {
    _maybeThrow();
    lockout = null;
  }

  @override
  Future<void> deleteAll() async {
    _maybeThrow();
    credential = null;
    lockout = null;
    config = null;
  }
}
