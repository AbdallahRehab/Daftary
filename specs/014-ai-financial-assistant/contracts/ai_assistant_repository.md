# Contract: AIAssistantRepository

This feature has no external/network API of its own beyond the outbound call to the user's chosen AI provider (see `ai_service.md`) — from the rest of the app's point of view this is a local-only Domain boundary, matching every other feature. The equivalent contract boundary is the **Domain repository interface**, which Presentation (via use cases) and Data (via `AIAssistantRepositoryImpl`) both depend on, per constitution Principle VI. All methods return `Either<Failure, T>` (Principle VII) — no method throws to the caller.

```dart
abstract class AIAssistantRepository {
  /// Current assistant settings (FR-001). Always succeeds — a fresh
  /// installation returns the default, disabled singleton row
  /// (data-model.md AIAssistantSettings).
  Future<Either<Failure, AIAssistantSettings>> getSettings();

  /// Enables the assistant (User Story 1): stores [apiKey] in secure
  /// storage under [providerId], records consent acceptance, and flips
  /// isEnabled=true — all three atomically (FR-002/FR-003, data-model.md
  /// "isEnabled=true MUST imply..."). Returns [ValidationFailure] if
  /// [apiKey] is empty/obviously malformed before ever touching secure
  /// storage or the network; this call itself never contacts the provider
  /// (a live key-validity check only happens lazily, on the first real
  /// question — see ai_service.md).
  Future<Either<Failure, AIAssistantSettings>> enable({
    required String providerId,
    required String apiKey,
    required DateTime consentAcceptedAt,
  });

  /// Disables the assistant (User Story 5): sets isEnabled=false, clears
  /// consentAcceptedAt, and deletes the credential from secure storage —
  /// one atomic operation (FR-014/FR-016). After this returns, no code
  /// path in the app can construct a valid outbound AI request until
  /// [enable] is called again.
  Future<Either<Failure, Unit>> disable();

  /// Replaces the stored provider/key without otherwise changing
  /// isEnabled/consent state (FR-005). Rejects an empty [apiKey].
  Future<Either<Failure, AIAssistantSettings>> updateCredentials({
    required String providerId,
    required String apiKey,
  });

  /// The single continuous conversation (FR-011), messages in chronological
  /// order. Creates the conversation lazily on first call if none exists
  /// yet (data-model.md AIConversation lifecycle). [limit]/[offset] page
  /// through history for smooth scrolling on a very long conversation
  /// (Edge Cases: "conversation history grows very large").
  Future<Either<Failure, List<AIMessage>>> getMessages({
    int limit = 50,
    int offset = 0,
  });

  /// Appends one message (either sender) to the conversation and returns
  /// it with its generated id/timestamp. Used internally by
  /// AskFinancialQuestion (ai_service.md) to persist both the user's
  /// question and the assistant's answer/failure — never called directly
  /// by Presentation.
  Future<Either<Failure, AIMessage>> appendMessage(AIMessageDraft draft);

  /// Permanently and irreversibly deletes every message in the
  /// conversation (FR-012). Does not affect AIAssistantSettings — the
  /// assistant remains enabled/disabled exactly as it was before.
  Future<Either<Failure, Unit>> clearConversation();
}
```

**Note on `enable`'s failure surface**: this method validates *shape* only (non-empty key, recognized `providerId`). It deliberately does not make a network call to verify the key actually works — that would contradict FR-002's "own API key... never sent anywhere but the chosen provider's API" being scoped to *questions*, and would mean enabling the assistant silently costs the user a provider call before they've asked anything. A genuinely invalid/revoked key is instead caught by the ordinary `InvalidApiKeyFailure` path the very first time `AskFinancialQuestion` runs (see `ai_service.md`), consistent with Edge Cases ("revokes/deletes the API key... the very next question fails with the invalid/revoked key state").
