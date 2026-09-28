import '../../../../core/error/failure.dart';
import 'ai_message.dart';

/// The five distinct, mutually exclusive ways a provider turn can fail
/// (research.md Decision 6). `AIService` maps every outcome — HTTP status,
/// connectivity exception, parse error, provider error envelope — to
/// exactly one of these; never a generic catch-all.
///
/// Sealed so callers can switch exhaustively; [reason] is what a failed
/// `AIMessage` persists.
sealed class AIAssistantFailure extends Failure {
  const AIAssistantFailure(super.message);

  AIFailureReason get reason;
}

/// The provider rejected the API key (401/403-class, or an explicit
/// invalid-key envelope).
class InvalidApiKeyFailure extends AIAssistantFailure {
  const InvalidApiKeyFailure(super.message);

  @override
  AIFailureReason get reason => AIFailureReason.invalidApiKey;
}

/// The provider signaled too many requests (429-class, or an explicit
/// rate-limit envelope).
class RateLimitFailure extends AIAssistantFailure {
  const RateLimitFailure(super.message);

  @override
  AIFailureReason get reason => AIFailureReason.rateLimited;
}

/// No response was received at all: no connectivity, DNS failure, timeout,
/// or any other transport-level failure.
class AINetworkFailure extends AIAssistantFailure {
  const AINetworkFailure(super.message);

  @override
  AIFailureReason get reason => AIFailureReason.network;
}

/// The provider responded but signaled its own server-side error
/// (5xx-class, or an explicit provider-error envelope) — the provider's
/// problem, not the user's.
class AIProviderFailure extends AIAssistantFailure {
  const AIProviderFailure(super.message);

  @override
  AIFailureReason get reason => AIFailureReason.providerError;
}

/// A non-error response arrived but could not be parsed into a valid turn:
/// malformed JSON, an unexpected schema, or a tool call naming a tool
/// outside the declared catalog.
class UnrecognizedAIResponseFailure extends AIAssistantFailure {
  const UnrecognizedAIResponseFailure(super.message);

  @override
  AIFailureReason get reason => AIFailureReason.unrecognizedResponse;
}

/// A question was asked while the assistant is disabled (User Story 5,
/// FR-014). Deliberately *outside* the sealed [AIAssistantFailure]
/// hierarchy: nothing reached the provider, so there is no provider
/// failure reason to persist — `AskFinancialQuestion` returns it before
/// any `AIService` call and persists nothing.
class AIAssistantDisabledFailure extends Failure {
  const AIAssistantDisabledFailure([
    super.message = 'The AI assistant is disabled',
  ]);
}
