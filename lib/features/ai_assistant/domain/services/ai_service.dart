import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_assistant_failures.dart';
import '../entities/tool_result.dart';

/// The swappable provider boundary (constitution Principle IX,
/// contracts/ai_service.md) — the only place in the app that knows how to
/// speak to a specific AI provider's HTTP API. Nothing above this
/// interface knows which provider is in use.
///
/// `AIService` never executes a tool: it only relays the provider's
/// *request* for one ([AITurnResult.toolCalls]). `AskFinancialQuestion` is
/// the only code that invokes a tool function, exactly once per request,
/// and hands back that tool's real, unmodified [ToolResult].
abstract class AIService {
  /// Sends [context] (the bounded recent message window, research.md
  /// Decision 5) plus the current [question] and the fixed set of
  /// [availableTools] (contracts/financial_query_tools.md's declarations,
  /// not their implementations — AIService never executes a tool itself)
  /// to the configured provider using [apiKey]/[providerId].
  ///
  /// [toolExchange] carries, on a follow-up call, the messages of *this*
  /// turn that come after [question]: the assistant's
  /// [AITurnMessage.toolCallRequest] and the matching
  /// [AITurnMessage.toolResult]s, in order. Empty on the first call of a
  /// turn.
  ///
  /// [systemPrompt] is the fixed instruction preamble (built by the caller
  /// via `SystemPromptBuilder`, never by the adapter) sent ahead of
  /// [context] in whatever slot the provider reserves for it (a `system`
  /// message for OpenAI-compatible APIs, the top-level `system` field for
  /// Anthropic). Empty means no preamble is sent.
  ///
  /// Returns an [AITurnResult]: either a final narrated
  /// [AITurnResult.answer] ready to show the user, or one-or-more
  /// [AITurnResult.toolCalls] the caller (AskFinancialQuestion) must
  /// execute locally and resubmit (a second [sendTurn] call carrying the
  /// tool results) before a final answer is produced. AIService itself
  /// never calls a tool function — it only ever requests that one be
  /// called, by name and arguments.
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
    List<AITurnMessage> toolExchange = const [],
    String systemPrompt = '',
  });
}

/// Who a normalized [AITurnMessage] is from, independent of any provider's
/// own role vocabulary.
enum AITurnRole { user, assistant, tool }

/// One normalized message sent to the provider (research.md Decision 1).
/// Adapters translate it to their provider's wire shape.
class AITurnMessage extends Equatable {
  /// A past user question from the context window.
  const AITurnMessage.user(this.content)
    : role = AITurnRole.user,
      toolCalls = const [],
      toolCallId = null,
      toolResult = null;

  /// A past narrated assistant answer from the context window.
  const AITurnMessage.assistant(this.content)
    : role = AITurnRole.assistant,
      toolCalls = const [],
      toolCallId = null,
      toolResult = null;

  /// Echoes the provider's own tool-call request back on the follow-up
  /// call, so the tool results that follow have something to answer.
  const AITurnMessage.toolCallRequest(this.toolCalls)
    : role = AITurnRole.assistant,
      content = '',
      toolCallId = null,
      toolResult = null;

  /// The real, unmodified result of executing the requested call
  /// [toolCallId]. The adapter serializes [toolResult] for the wire.
  const AITurnMessage.toolResult({
    required String this.toolCallId,
    required ToolResult this.toolResult,
  }) : role = AITurnRole.tool,
       content = '',
       toolCalls = const [];

  final AITurnRole role;

  /// Plain text for user/assistant messages; empty for tool plumbing.
  final String content;

  /// Non-empty only for [AITurnMessage.toolCallRequest].
  final List<AIToolCallRequest> toolCalls;

  /// Set only for [AITurnMessage.toolResult].
  final String? toolCallId;
  final ToolResult? toolResult;

  @override
  List<Object?> get props => [role, content, toolCalls, toolCallId, toolResult];
}

/// One tool offered to the provider: name, description and a JSON-schema
/// object describing its arguments (contracts/financial_query_tools.md).
/// A declaration only — never the Dart implementation.
class AIToolDeclaration extends Equatable {
  const AIToolDeclaration({
    required this.name,
    required this.description,
    required this.parametersSchema,
  });

  /// An `AIToolNames` value.
  final String name;
  final String description;

  /// A JSON-schema `object` (`type`/`properties`/`required`).
  final Map<String, Object?> parametersSchema;

  @override
  List<Object?> get props => [name, description, parametersSchema];
}

/// The provider's request that a tool be called — only ever a request,
/// executed (or not) by `AskFinancialQuestion`.
class AIToolCallRequest extends Equatable {
  const AIToolCallRequest({
    required this.id,
    required this.toolName,
    required this.arguments,
  });

  /// The provider-assigned call id, echoed back with the result.
  final String id;
  final String toolName;

  /// The decoded argument object, unvalidated — the tool itself validates
  /// and coerces it.
  final Map<String, Object?> arguments;

  @override
  List<Object?> get props => [id, toolName, arguments];
}

/// The outcome of one successful [AIService.sendTurn]: exactly one of a
/// final [answer] or a non-empty list of [toolCalls].
class AITurnResult extends Equatable {
  /// The model's final narrated answer, ready to show the user.
  const AITurnResult.answer(String this.answer) : toolCalls = const [];

  /// The model wants these tools executed and their results resubmitted
  /// before it answers.
  const AITurnResult.toolCalls(this.toolCalls) : answer = null;

  final String? answer;
  final List<AIToolCallRequest> toolCalls;

  bool get isFinalAnswer => answer != null;
  bool get requestsToolCalls => toolCalls.isNotEmpty;

  @override
  List<Object?> get props => [answer, toolCalls];
}
