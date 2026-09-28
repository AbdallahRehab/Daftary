/// Shape-only API-key checks (contracts/ai_assistant_repository.md:
/// "validates *shape* only"). Never contacts a provider — a genuinely
/// invalid key surfaces lazily as `InvalidApiKeyFailure` on the first
/// question.
abstract final class AIApiKeyRules {
  /// Shorter than any real provider key; catches an accidental paste of a
  /// fragment without guessing at any one provider's format.
  static const int minLength = 8;

  /// Whether [apiKey] (as typed, before trimming) is obviously malformed:
  /// blank, too short, or containing whitespace inside it.
  static bool isMalformed(String apiKey) {
    final trimmed = apiKey.trim();
    return trimmed.length < minLength || trimmed.contains(RegExp(r'\s'));
  }

  /// The value actually stored: surrounding whitespace from a paste is
  /// dropped, nothing else is altered.
  static String normalize(String apiKey) => apiKey.trim();
}
