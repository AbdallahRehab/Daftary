import '../../../domain/services/ai_service.dart';

/// What a provider's own error envelope says went wrong, before it is
/// turned into one of the five typed failures by `AIServiceImpl`.
enum AIErrorEnvelopeKind { invalidKey, rateLimited, providerError }

/// Thrown by an adapter's [AIProviderAdapter.parseResponse] when a
/// non-error body cannot be read as a valid turn. Never escapes
/// `AIServiceImpl` — it becomes an `UnrecognizedAIResponseFailure`.
class AIResponseFormatException implements Exception {
  const AIResponseFormatException(this.reason);

  final String reason;

  @override
  String toString() => 'AIResponseFormatException: $reason';
}

/// Translates the normalized `AIService` turn shape to and from one
/// provider protocol's JSON (research.md Decision 1). Pure: no I/O, no
/// logging, never sees anything but the request/response it is handed.
abstract class AIProviderAdapter {
  const AIProviderAdapter();

  /// Request headers, including authentication with [apiKey].
  Map<String, String> headers(String apiKey);

  /// The JSON request body for one call.
  ///
  /// [messages] is the full ordered conversation for this call: the
  /// context window, the current question, then any tool exchange.
  Map<String, Object?> buildBody({
    required String model,
    required String systemPrompt,
    required List<AITurnMessage> messages,
    required List<AIToolDeclaration> tools,
  });

  /// Reads a decoded success body into a turn result.
  ///
  /// Throws [AIResponseFormatException] on any unexpected shape, or when a
  /// requested tool is not in [allowedToolNames].
  AITurnResult parseResponse(Object? body, Set<String> allowedToolNames);

  /// Classifies [body] if it is this protocol's error envelope; `null`
  /// when it is not an error envelope at all.
  AIErrorEnvelopeKind? classifyErrorEnvelope(Object? body);
}

/// Shared helpers for adapters.
abstract final class AdapterJson {
  static Map<String, Object?> asMap(Object? value, String what) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return value.cast<String, Object?>();
    throw AIResponseFormatException('$what is not an object');
  }

  static List<Object?> asList(Object? value, String what) {
    if (value is List) return value.cast<Object?>();
    throw AIResponseFormatException('$what is not a list');
  }

  static String asNonEmptyString(Object? value, String what) {
    if (value is String && value.isNotEmpty) return value;
    throw AIResponseFormatException('$what is missing or empty');
  }

  static void checkToolAllowed(String name, Set<String> allowed) {
    if (!allowed.contains(name)) {
      throw const AIResponseFormatException(
        'tool call names a tool outside availableTools',
      );
    }
  }

  /// Markers providers use in error `type`/`code`/`status`/`message`
  /// fields, lower-cased.
  static AIErrorEnvelopeKind classifyByText(Iterable<Object?> fields) {
    final text = fields.whereType<String>().join(' ').toLowerCase();
    const keyMarkers = [
      'invalid_api_key',
      'api_key_invalid',
      'authentication_error',
      'permission_error',
      'unauthenticated',
      'permission_denied',
      'invalid api key',
      'incorrect api key',
      'api key not valid',
      'invalid x-api-key',
    ];
    const rateMarkers = [
      'rate_limit',
      'resource_exhausted',
      'too many requests',
      'rate limit',
    ];
    if (keyMarkers.any(text.contains)) return AIErrorEnvelopeKind.invalidKey;
    if (rateMarkers.any(text.contains)) return AIErrorEnvelopeKind.rateLimited;
    return AIErrorEnvelopeKind.providerError;
  }
}
