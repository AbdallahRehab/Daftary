import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 021: persists the cloud session in the Keychain / Keystore instead of
/// SharedPreferences (constitution XII, research.md Decision 11).
///
/// The session string holds the access and refresh tokens, so it never
/// touches plain-text storage and is never logged.
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage(this._storage);

  /// The one key the session lives under.
  static const sessionKey = 'daftary.supabase.session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: sessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: sessionKey);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: sessionKey, value: persistSessionString);
}

/// 021: the PKCE code-verifier store, also kept in secure storage so that
/// nothing auth-related reaches SharedPreferences. The one-time-code email
/// flow does not use PKCE, but the client requires a store.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  const SecureGotrueAsyncStorage(this._storage);

  static const _prefix = 'daftary.supabase.pkce.';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '$_prefix$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$_prefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '$_prefix$key');
}
