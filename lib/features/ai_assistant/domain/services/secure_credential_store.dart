/// The only place the user's provider API key is ever kept (research.md
/// Decision 3) — the OS keychain/keystore, never drift, never logs.
///
/// Called only by `AIAssistantRepositoryImpl` (to write/delete) and by the
/// code that builds an outbound provider request (to read). Nothing above
/// the repository ever sees the key value.
///
/// Implementations may throw on a platform storage error; the calling
/// repository maps that to a `Failure` (constitution Principle VII).
abstract class SecureCredentialStore {
  /// Stores [apiKey] for [providerId], replacing any existing key.
  Future<void> write(String providerId, String apiKey);

  /// The key stored for [providerId], or `null` when none is stored.
  Future<String?> read(String providerId);

  /// Removes the key for [providerId]. A no-op when none is stored.
  Future<void> delete(String providerId);
}
