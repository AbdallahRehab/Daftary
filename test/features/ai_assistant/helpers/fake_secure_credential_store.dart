import 'package:daftary/features/ai_assistant/domain/services/secure_credential_store.dart';

/// An in-memory [SecureCredentialStore] that records every call, so tests
/// can assert what was written/deleted and in which order relative to the
/// database, and can force a platform failure on demand.
class FakeSecureCredentialStore implements SecureCredentialStore {
  final Map<String, String> keys = {};

  /// Every call as `'write:<providerId>'`, `'read:<providerId>'` or
  /// `'delete:<providerId>'` — never the key value.
  final List<String> log = [];

  bool failWrites = false;
  bool failDeletes = false;

  /// Runs inside each call before it takes effect — lets a test observe the
  /// database state at that exact moment (e.g. inside the repository's
  /// transaction).
  Future<void> Function(String operation, String providerId)? onCall;

  @override
  Future<void> write(String providerId, String apiKey) async {
    log.add('write:$providerId');
    await onCall?.call('write', providerId);
    if (failWrites) throw StateError('keychain unavailable');
    keys[providerId] = apiKey;
  }

  @override
  Future<String?> read(String providerId) async {
    log.add('read:$providerId');
    await onCall?.call('read', providerId);
    return keys[providerId];
  }

  @override
  Future<void> delete(String providerId) async {
    log.add('delete:$providerId');
    await onCall?.call('delete', providerId);
    if (failDeletes) throw StateError('keychain unavailable');
    keys.remove(providerId);
  }
}
