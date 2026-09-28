import 'package:equatable/equatable.dart';

/// Who authored an [AIMessage] (FR-011).
enum MessageSender { user, assistant }

/// Where an [AIMessage] stands (014 data-model.md).
///
/// A `user` message moves `sent` → `answered` (an assistant reply exists)
/// or `sent` → `failed` (User Story 6, FR-018 — retryable without
/// retyping). An `assistant` message is always created already `answered`.
enum MessageStatus { sent, answered, failed }

/// Why a `failed` [AIMessage] failed — mirrors the five typed failures in
/// `ai_assistant_failures.dart` one-to-one (research.md Decision 6), and
/// drives which localized message is shown.
enum AIFailureReason {
  invalidApiKey,
  rateLimited,
  network,
  providerError,
  unrecognizedResponse,
}

/// One turn within the single `AIConversation` — the user's question or
/// the assistant's answer (014 data-model.md).
///
/// Validation rules, verbatim from data-model.md:
/// - [content] MUST NOT be empty for a `sent`/`answered` message.
/// - A `failed` message MUST have a non-null [failureReason]; an
///   `answered`/`sent` message MUST have a null [failureReason].
///
/// The asserts below guard these on every construction; the only public
/// write path, [AIMessageDraft], cannot express a violating combination at
/// all.
class AIMessage extends Equatable {
  const AIMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.status,
    required this.createdAt,
    this.failureReason,
    this.groundingRefsJson,
  }) : assert(
         status == MessageStatus.failed || content != '',
         'A sent/answered message must have non-empty content',
       ),
       assert(
         (status == MessageStatus.failed) == (failureReason != null),
         'failureReason is required for, and only for, a failed message',
       ),
       assert(
         sender == MessageSender.user || status == MessageStatus.answered,
         'An assistant message is always created answered',
       );

  final String id;
  final String conversationId;
  final MessageSender sender;

  /// The question text (user) or the final narrated answer (assistant).
  /// Never raw provider JSON or tool-call payloads — those live in
  /// [groundingRefsJson].
  final String content;
  final MessageStatus status;

  /// Non-null exactly when [status] is [MessageStatus.failed].
  final AIFailureReason? failureReason;

  /// Assistant messages only: a JSON list of the tool/use-case pairs that
  /// grounded this answer's figures, e.g.
  /// `[{"tool":"getCategorySpend","useCase":"GetCategoryBreakdown"}]`.
  /// Populated exclusively from the actual tool dispatch inside
  /// `AskFinancialQuestion`, never from free-form model output. `null`
  /// for an answer that needed no tool call (e.g. an honest decline).
  final String? groundingRefsJson;
  final DateTime createdAt;

  bool get isFromUser => sender == MessageSender.user;
  bool get isFailed => status == MessageStatus.failed;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    sender,
    content,
    status,
    failureReason,
    groundingRefsJson,
    createdAt,
  ];
}

/// The input to `AIAssistantRepository.appendMessage`: an [AIMessage]
/// before the repository assigns its id, conversation and timestamp.
///
/// Only constructible through the named constructors below, each of which
/// fixes the sender/status/failureReason combination — so an invalid
/// combination (a failed message without a reason, an answered one with
/// one, an assistant message that is not answered) cannot be expressed.
/// Empty [content] is rejected by the repository with a
/// `ValidationFailure` before anything is persisted.
class AIMessageDraft extends Equatable {
  /// The user's question, as first sent.
  const AIMessageDraft.userQuestion(this.content)
    : sender = MessageSender.user,
      status = MessageStatus.sent,
      failureReason = null,
      groundingRefsJson = null;

  /// A user question whose request failed (User Story 6) — kept so it can
  /// be retried without retyping (FR-018).
  const AIMessageDraft.failedQuestion(
    this.content, {
    required AIFailureReason this.failureReason,
  }) : sender = MessageSender.user,
       status = MessageStatus.failed,
       groundingRefsJson = null;

  /// The assistant's final narrated answer. [groundingRefsJson] is `null`
  /// when no tool was called (e.g. a decline or clarifying question).
  const AIMessageDraft.assistantAnswer(this.content, {this.groundingRefsJson})
    : sender = MessageSender.assistant,
      status = MessageStatus.answered,
      failureReason = null;

  final MessageSender sender;
  final String content;
  final MessageStatus status;
  final AIFailureReason? failureReason;
  final String? groundingRefsJson;

  @override
  List<Object?> get props => [
    sender,
    content,
    status,
    failureReason,
    groundingRefsJson,
  ];
}

extension MessageSenderDb on MessageSender {
  /// The `sender` text column's stored value.
  String get dbValue => switch (this) {
    MessageSender.user => 'user',
    MessageSender.assistant => 'assistant',
  };
}

/// Parses a stored `sender` value. Throws [StateError] on an unknown value
/// rather than guessing — a corrupt row must not silently change author.
MessageSender messageSenderFromDb(String value) => switch (value) {
  'user' => MessageSender.user,
  'assistant' => MessageSender.assistant,
  _ => throw StateError('Unknown AI message sender: $value'),
};

extension MessageStatusDb on MessageStatus {
  /// The `status` text column's stored value.
  String get dbValue => switch (this) {
    MessageStatus.sent => 'sent',
    MessageStatus.answered => 'answered',
    MessageStatus.failed => 'failed',
  };
}

/// Parses a stored `status` value. Throws [StateError] on an unknown value.
MessageStatus messageStatusFromDb(String value) => switch (value) {
  'sent' => MessageStatus.sent,
  'answered' => MessageStatus.answered,
  'failed' => MessageStatus.failed,
  _ => throw StateError('Unknown AI message status: $value'),
};

extension AIFailureReasonDb on AIFailureReason {
  /// The `failure_reason` text column's stored value.
  String get dbValue => switch (this) {
    AIFailureReason.invalidApiKey => 'invalidApiKey',
    AIFailureReason.rateLimited => 'rateLimited',
    AIFailureReason.network => 'network',
    AIFailureReason.providerError => 'providerError',
    AIFailureReason.unrecognizedResponse => 'unrecognizedResponse',
  };
}

/// Parses a stored `failure_reason` value. Throws [StateError] on an
/// unknown value.
AIFailureReason aiFailureReasonFromDb(String value) => switch (value) {
  'invalidApiKey' => AIFailureReason.invalidApiKey,
  'rateLimited' => AIFailureReason.rateLimited,
  'network' => AIFailureReason.network,
  'providerError' => AIFailureReason.providerError,
  'unrecognizedResponse' => AIFailureReason.unrecognizedResponse,
  _ => throw StateError('Unknown AI failure reason: $value'),
};
