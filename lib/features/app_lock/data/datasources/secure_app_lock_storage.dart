import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/app_lock_config.dart';
import '../../domain/entities/lockout_state.dart';
import '../../domain/entities/pin_credential.dart';

/// The sole data source touching App Lock's `app_lock.*` secure-storage keys
/// (015 data-model.md "Secure Storage Key Sketch").
///
/// Implementations may throw on a platform error or on a stored value that
/// fails to parse; `AppLockRepositoryImpl` maps both to a `CacheFailure`.
abstract class SecureAppLockStorage {
  /// `null` when never written.
  Future<AppLockConfig?> readConfig();
  Future<void> writeConfig(AppLockConfig config);

  /// `null` when no PIN has been set (or it was deleted).
  Future<PinCredential?> readPinCredential();
  Future<void> writePinCredential(PinCredential credential);
  Future<void> deletePinCredential();

  /// `null` when never written.
  Future<LockoutState?> readLockoutState();
  Future<void> writeLockoutState(LockoutState state);
  Future<void> deleteLockoutState();

  /// Deletes every `app_lock.*` key (config, credential, lockout) — used by
  /// the full local-data wipe. The credential is deleted first so a failure
  /// part-way can never leave a stale PIN behind an "enabled" config.
  Future<void> deleteAll();
}

@LazySingleton(as: SecureAppLockStorage)
class SecureAppLockStorageImpl implements SecureAppLockStorage {
  SecureAppLockStorageImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const String configKey = 'app_lock.config';
  static const String pinCredentialKey = 'app_lock.pin_credential';
  static const String lockoutStateKey = 'app_lock.lockout_state';

  static const List<String> allKeys = [
    pinCredentialKey,
    lockoutStateKey,
    configKey,
  ];

  // ----------------------------------------------------------------- config

  @override
  Future<AppLockConfig?> readConfig() async {
    final json = await _readJson(configKey);
    if (json == null) return null;
    final methods = (json['activeUnlockMethods'] as List<dynamic>)
        .cast<String>()
        .map(UnlockMethod.values.byName)
        .toSet();
    final changedAt = json['pinLastChangedAt'] as int?;
    return AppLockConfig(
      isEnabled: json['isEnabled'] as bool,
      activeUnlockMethods: Set<UnlockMethod>.unmodifiable(methods),
      inactivityTimeout: InactivityTimeout.values.byName(
        json['inactivityTimeout'] as String,
      ),
      pinLastChangedAt: changedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(changedAt),
    );
  }

  @override
  Future<void> writeConfig(AppLockConfig config) => _writeJson(configKey, {
    'isEnabled': config.isEnabled,
    'activeUnlockMethods': [
      for (final m in UnlockMethod.values)
        if (config.activeUnlockMethods.contains(m)) m.name,
    ],
    'inactivityTimeout': config.inactivityTimeout.name,
    'pinLastChangedAt': config.pinLastChangedAt?.millisecondsSinceEpoch,
  });

  // ------------------------------------------------------------- credential

  @override
  Future<PinCredential?> readPinCredential() async {
    final json = await _readJson(pinCredentialKey);
    if (json == null) return null;
    return PinCredential(
      hash: json['hash'] as String,
      salt: json['salt'] as String,
      iterations: json['iterations'] as int,
    );
  }

  @override
  Future<void> writePinCredential(PinCredential credential) =>
      _writeJson(pinCredentialKey, {
        'hash': credential.hash,
        'salt': credential.salt,
        'iterations': credential.iterations,
      });

  @override
  Future<void> deletePinCredential() => _storage.delete(key: pinCredentialKey);

  // ---------------------------------------------------------------- lockout

  @override
  Future<LockoutState?> readLockoutState() async {
    final json = await _readJson(lockoutStateKey);
    if (json == null) return null;
    final endsAt = json['cooldownEndsAt'] as int?;
    return LockoutState(
      consecutiveFailedAttempts: json['consecutiveFailedAttempts'] as int,
      cooldownEndsAt: endsAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(endsAt),
    );
  }

  @override
  Future<void> writeLockoutState(LockoutState state) =>
      _writeJson(lockoutStateKey, {
        'consecutiveFailedAttempts': state.consecutiveFailedAttempts,
        'cooldownEndsAt': state.cooldownEndsAt?.millisecondsSinceEpoch,
      });

  @override
  Future<void> deleteLockoutState() => _storage.delete(key: lockoutStateKey);

  // -------------------------------------------------------------------- all

  @override
  Future<void> deleteAll() async {
    for (final key in allKeys) {
      await _storage.delete(key: key);
    }
  }

  // ---------------------------------------------------------------- helpers

  Future<Map<String, dynamic>?> _readJson(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeJson(String key, Map<String, Object?> json) =>
      _storage.write(key: key, value: jsonEncode(json));

  @override
  String toString() => 'SecureAppLockStorageImpl';
}
