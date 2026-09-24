import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_assistant_settings.dart';
import '../entities/ai_message.dart';

/// Domain/Data boundary for [AIAssistantSettings], the single conversation
/// and its [AIMessage]s (contracts/ai_assistant_repository.md). Local-only
/// from the rest of the app's point of view, so this interface *is* the
/// feature's contract; the one outbound network call lives behind
/// `AIService` instead. No method throws to the caller (constitution
/// Principle VII).
///
/// The API key passes *into* this boundary to be written to
/// `SecureCredentialStore`; the only way back out is [readApiKey], which
/// exists solely so `AskFinancialQuestion`/`GetProactiveObservation` can
/// hand it to `AIService` for one request. It is never logged, cached, or
/// put into a `Failure` message.
abstract class AIAssistantRepository {
  /// Current assistant settings (FR-001). Always succeeds on a healthy
  /// database — a fresh installation returns the default, disabled
  /// singleton.
  Future<Either<Failure, AIAssistantSettings>> getSettings();

  /// Enables the assistant (User Story 1): stores [apiKey] in secure
  /// storage under [providerId], records consent at [consentAcceptedAt],
  /// and flips `isEnabled` to `true` — all three atomically (FR-002/FR-003).
  /// Returns `ValidationFailure` if [apiKey] is empty/obviously malformed
  /// or [providerId] is unrecognized, before ever touching secure storage.
  /// Never contacts the provider: an invalid key surfaces lazily as
  /// `InvalidApiKeyFailure` on the first real question.
  Future<Either<Failure, AIAssistantSettings>> enable({
    required String providerId,
    required String apiKey,
    required DateTime consentAcceptedAt,
  });

  /// Disables the assistant (User Story 5): sets `isEnabled` to `false`,
  /// clears `consentAcceptedAt`, and deletes the credential from secure
  /// storage — one atomic operation (FR-014/FR-016). Does not clear the
  /// conversation.
  Future<Either<Failure, Unit>> disable();

  /// Deletes the API key from every secure-storage slot (every preset plus
  /// the shared custom slot), touching no database row — for the app-wide
  /// "delete all my data" flow (013 FR-016, 014 FR-004), which wipes the
  /// assistant's tables itself but cannot reach secure storage. Idempotent:
  /// deleting an absent key succeeds. `CacheFailure` (carrying only the
  /// exception type) if the keychain rejects any delete.
  Future<Either<Failure, Unit>> purgeCredentials();

  /// Replaces the stored provider/key without otherwise changing
  /// `isEnabled`/consent state (FR-005). Rejects an empty [apiKey] with
  /// `ValidationFailure`.
  Future<Either<Failure, AIAssistantSettings>> updateCredentials({
    required String providerId,
    required String apiKey,
  });

  /// The single conversation's messages in chronological order (FR-011),
  /// creating the conversation lazily if none exists yet. [limit]/[offset]
  /// page through a very long history.
  Future<Either<Failure, List<AIMessage>>> getMessages({
    int limit = 50,
    int offset = 0,
  });

  /// Appends one message to the conversation and returns it with its
  /// generated id, conversation id and timestamp, bumping the
  /// conversation's `lastActivityAt`. Used by `AskFinancialQuestion` only
  /// — never called directly by Presentation. `ValidationFailure` for
  /// empty content on a sent/answered draft.
  Future<Either<Failure, AIMessage>> appendMessage(AIMessageDraft draft);

  /// Permanently deletes every message in the conversation (FR-012).
  /// Leaves [AIAssistantSettings] exactly as it was.
  Future<Either<Failure, Unit>> clearConversation();

  /// The stored API key of the currently configured provider, read from
  /// secure storage for one outbound request. Never logged.
  ///
  /// - `ValidationFailure` when the assistant is not enabled (no code path
  ///   may obtain a key for a disabled assistant, FR-014/FR-016);
  /// - `NotFoundFailure` when enabled but no (non-blank) key is stored;
  /// - `CacheFailure` when the database or keychain read fails (the
  ///   message carries only the exception type).
  Future<Either<Failure, String>> readApiKey();

  /// Deletes message [messageId] only if it is a `failed` question — what
  /// a retry (FR-018) uses to replace the old failed row by the retried
  /// attempt's outcome. `NotFoundFailure` when no failed message has that
  /// id (an answered/sent message is never deleted this way).
  Future<Either<Failure, Unit>> deleteFailedMessage(String messageId);

  /// The `observationKey` of the last proactive observation surfaced
  /// (User Story 7 AC3), or `null` when none ever was.
  Future<Either<Failure, String?>> getLastObservationKey();

  /// Records [observationKey] as surfaced, so the same unchanged
  /// observation is never shown again. Touches no other setting.
  Future<Either<Failure, Unit>> recordSurfacedObservation(
    String observationKey,
  );
}
