import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../domain/services/secure_credential_store.dart';
import '../services/ai_provider_registry.dart';

/// [SecureCredentialStore] over `flutter_secure_storage` — the iOS Keychain
/// / Android Keystore (research.md Decision 3). The key is written under a
/// fixed logical name per provider slot and is never logged, never
/// interpolated into an error message, and never part of [toString].
///
/// Exceptions from the platform are deliberately left to propagate (the
/// interface says so): the repository maps them to a `Failure`, and a
/// platform exception never carries the stored value.
@LazySingleton(as: SecureCredentialStore)
class SecureCredentialStoreImpl implements SecureCredentialStore {
  SecureCredentialStoreImpl(this._storage);

  final FlutterSecureStorage _storage;

  /// Namespaced so no other future secure-storage user (e.g. V3.1 App
  /// Lock) can collide with it.
  static const String keyPrefix = 'daftary.ai_assistant.api_key.';

  /// The storage entry name for [providerId]: one fixed name per preset,
  /// and one shared name for every custom provider — never derived from
  /// the key itself (research.md Decision 3).
  static String storageKeyFor(String providerId) =>
      '$keyPrefix${credentialSlot(providerId)}';

  static String credentialSlot(String providerId) =>
      AIProviderRegistry.isCustom(providerId) ? 'custom' : providerId;

  /// One representative provider id per storage slot (every preset, plus
  /// the shared custom slot) — what a disable walks so no key can remain
  /// resident anywhere (FR-014/FR-016).
  static List<String> get everySlotProviderId => [
    for (final preset in AIProviderRegistry.presets) preset.id,
    AIProviderRegistry.customPrefix,
  ];

  @override
  Future<void> write(String providerId, String apiKey) =>
      _storage.write(key: storageKeyFor(providerId), value: apiKey);

  @override
  Future<String?> read(String providerId) =>
      _storage.read(key: storageKeyFor(providerId));

  @override
  Future<void> delete(String providerId) =>
      _storage.delete(key: storageKeyFor(providerId));

  @override
  String toString() => 'SecureCredentialStoreImpl';
}
