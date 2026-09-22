# Contract: AIService

The swappable provider boundary (constitution Principle IX) — the only place in the app that knows how to speak to a specific AI provider's HTTP API. `AIServiceImpl` (Data) implements this against whichever adapter `AISettings.providerId` selects (research.md Decision 1); nothing above this interface (Domain use cases, Cubits, UI) knows or cares which provider is in use.

```dart
/// One normalized conversation turn, independent of any specific provider's
/// request/response shape (research.md Decision 1).
abstract class AIService {
  /// Sends [context] (the bounded recent message window, research.md
  /// Decision 5) plus the current [question] and the fixed set of
  /// [availableTools] (contracts/financial_query_tools.md's declarations,
  /// not their implementations — AIService never executes a tool itself)
  /// to the configured provider using [apiKey]/[providerId].
  ///
  /// Returns an [AITurnResult]: either a final narrated [AITurnResult.answer]
  /// ready to show the user, or one-or-more [AITurnResult.toolCalls] the
  /// caller (AskFinancialQuestion) must execute locally and resubmit
  /// (a second [sendTurn] call carrying the tool results) before a final
  /// answer is produced. AIService itself never calls a tool function —
  /// it only ever requests that one be called, by name and arguments.
  ///
  /// Every failure path is mapped to exactly one of five typed failures
  /// (research.md Decision 6) — this method NEVER throws a raw exception,
  /// HTTP error, or unparsed provider error body to its caller:
  /// - [InvalidApiKeyFailure]: provider rejected the key (401/403-class
  ///   response, or an explicit "invalid key" error envelope).
  /// - [RateLimitFailure]: provider signaled too-many-requests (429-class,
  ///   or an explicit rate-limit error envelope).
  /// - [AINetworkFailure]: no connectivity, DNS failure, timeout, or any
  ///   transport-level failure before a response was received at all.
  /// - [AIProviderFailure]: the provider responded but signaled its own
  ///   server-side error (5xx-class, or an explicit provider-error
  ///   envelope) — the provider is having a problem, not the user.
  /// - [UnrecognizedAIResponseFailure]: a response was received and was
  ///   not a transport/HTTP-level error, but its body could not be parsed
  ///   into a valid [AITurnResult] shape (malformed JSON, an unexpected
  ///   schema, or a tool call naming a tool outside availableTools).
  Future<Either<Failure, AITurnResult>> sendTurn({
    required String providerId,
    required String apiKey,
    required List<AITurnMessage> context,
    required String question,
    required List<AIToolDeclaration> availableTools,
  });
}
```

**Grounding enforcement inside this contract**: `availableTools` are declared to the provider using each tool's schema from `contracts/financial_query_tools.md` (name, description, argument shape) — never an open-ended "call any function you like" surface, and never the underlying Dart implementation. A provider response that requests a tool call is only ever treated as *a request*; `AskFinancialQuestion` (not `AIService`) is the only code that actually invokes the corresponding function in `ai_assistant/domain/tools/`, and it does so exactly once per requested call, passing back only that tool's real, unmodified `ToolResult` (data-model.md) on the follow-up `sendTurn`. This is what makes it structurally impossible for the model to "compute" a number that didn't come from a real tool result — `AIService` has no code path that lets a provider-stated number bypass a tool call and land directly in `AIMessage.content` as if it had.

**No tool execution inside `AIService`**: this is a deliberate layering choice — `AIService` (Data) must never import or call anything from `ai_assistant/domain/tools/` or any other feature's use cases; only `AskFinancialQuestion` (Domain) orchestrates both `AIService.sendTurn` and the tool functions, keeping the actual financial-data access entirely inside Domain where constitution Principle I requires it to live.
