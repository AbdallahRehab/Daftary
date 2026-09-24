import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_assistant_failures.dart';
import '../entities/ai_message.dart';
import '../entities/grounding_refs.dart';
import '../entities/tool_result.dart';
import '../repositories/ai_assistant_repository.dart';
import '../services/ai_service.dart';
import '../services/system_prompt_builder.dart';
import '../tools/ai_tool.dart';
import '../tools/ai_tool_registry.dart';
import '../tools/tool_arguments.dart';
import '../tools/tool_catalog.dart';

/// The two messages a successful [AskFinancialQuestion] persisted, returned
/// so the caller can render them without reloading the conversation.
class AskFinancialQuestionResult extends Equatable {
  const AskFinancialQuestionResult({
    required this.question,
    required this.answer,
  });

  /// The user's question, persisted with status `sent`.
  final AIMessage question;

  /// The assistant's narrated answer (status `answered`), carrying the
  /// grounding refs of every tool that actually produced data for it.
  final AIMessage answer;

  @override
  List<Object?> get props => [question, answer];
}

/// Keys of the `ToolResult.data` [AskFinancialQuestion] hands back to the
/// model when a requested tool call could not be executed.
abstract final class AIToolErrorDataKeys {
  /// A short, key-free explanation for the model (e.g. which argument was
  /// malformed), so it can correct the call or tell the user it cannot
  /// answer — never a figure.
  static const String error = 'error';
}

/// `AIToolDataKeys.reason` value for a tool call that could not run.
const String aiToolErrorReason = 'toolError';

/// `ToolResult.sourceUseCase` of a tool call that could not run: no use
/// case produced any data, so it is never recorded as grounding.
const String aiToolErrorSourceUseCase = 'none';

/// Answers one natural-language question from the user's own data
/// (User Story 2, contracts/ai_service.md) — the only code that
/// orchestrates both [AIService.sendTurn] and the local tool functions.
///
/// Flow:
/// 1. Blank question → `ValidationFailure`. Disabled assistant →
///    [AIAssistantDisabledFailure] with zero [AIService] calls and nothing
///    persisted (User Story 5, T059).
/// 2. The API key is read from secure storage. A missing/unreadable key is
///    treated as [InvalidApiKeyFailure] (the user must re-enter it).
/// 3. Context = the latest [contextWindowSize] stored messages
///    (research.md Decision 5), minus `failed` questions (they were never
///    answered, so they would only confuse the model) and minus any
///    assistant messages cut off from their question at the window's
///    start (some providers reject a history that opens with an assistant
///    turn, and an answer without its question is noise). The fixed
///    [SystemPromptBuilder] preamble is built for today's date from the
///    injected clock ([AIPeriodResolver.now]).
/// 4. `sendTurn` with the full `aiToolCatalog`. While the model requests
///    tool calls, each requested call is dispatched **exactly once**
///    through [AIToolRegistry] and its real, unmodified [ToolResult] is
///    resubmitted in `toolExchange` (accumulated across rounds). At most
///    [maxToolRounds] rounds of tool calls are served; a model still
///    asking for tools after that is an [UnrecognizedAIResponseFailure].
///    Before every follow-up call the enabled state is re-read: if the
///    assistant was disabled mid-turn, [AIAssistantDisabledFailure] is
///    returned with no further provider call and nothing persisted
///    (FR-014, T062).
/// 5. A tool call that cannot run (malformed arguments →
///    `ValidationFailure`, unknown tool, wrapped use case failure) does
///    **not** abort the turn: the model receives a `foundData: false`
///    result with `reason: "toolError"` and a short `error` text, so it can
///    fix its call or honestly say it cannot answer. Such a result is not
///    grounding and is left out of `groundingRefsJson`.
/// 6. Final answer → persist the question (`sent`) then the answer
///    (`answered`, `groundingRefsJson` = every distinct
///    tool/source-use-case pair that produced a result, `null` when none
///    did — T047).
/// 7. Any [AIAssistantFailure] → the question is persisted as `failed`
///    with that failure's reason (never silently dropped, FR-018/T065) and
///    the failure is returned. A non-AI failure from the service (should
///    not happen per its contract) is normalized to
///    [UnrecognizedAIResponseFailure].
///
/// Retry (FR-018): pass the failed message's id as [call]'s
/// `retryOfMessageId` together with its content. Once the new attempt has
/// an outcome (answer *or* failure), the old failed row is deleted before
/// the outcome is persisted, so the conversation holds exactly one copy of
/// the question — at the end, in its new state. Only a `failed` message
/// can be removed this way; an unknown/non-failed id is ignored.
///
/// Never logs anything, and the API key never enters a [Failure].
@injectable
class AskFinancialQuestion {
  const AskFinancialQuestion(
    this._repository,
    this._aiService,
    this._tools,
    this._systemPrompt,
    this._clock,
  );

  final AIAssistantRepository _repository;
  final AIService _aiService;
  final AIToolRegistry _tools;
  final SystemPromptBuilder _systemPrompt;
  final AIPeriodResolver _clock;

  /// How many of the most recent stored messages are sent as context
  /// (research.md Decision 5: ~10 question/answer turns).
  static const int contextWindowSize = 20;

  /// The most tool-call rounds served in one turn before the response is
  /// treated as unrecognized. Every catalog question needs one round
  /// (occasionally two, e.g. after a clarifying tool error); a model still
  /// asking after three is looping, and each round costs the user a
  /// provider request.
  static const int maxToolRounds = 3;

  Future<Either<Failure, AskFinancialQuestionResult>> call(
    String question, {
    String? retryOfMessageId,
  }) async {
    final text = question.trim();
    if (text.isEmpty) {
      return const Left(ValidationFailure('The question must not be empty'));
    }

    final settingsResult = await _repository.getSettings();
    final settings = settingsResult.toNullable();
    if (settings == null) return Left(settingsResult.getLeft().toNullable()!);
    final providerId = settings.providerId;
    if (!settings.isEnabled || providerId == null) {
      return const Left(AIAssistantDisabledFailure());
    }

    final keyResult = await _repository.readApiKey();
    final apiKey = keyResult.toNullable();
    if (apiKey == null) {
      return _persistFailure(
        text,
        const InvalidApiKeyFailure('No usable API key is stored'),
        retryOfMessageId,
      );
    }

    final historyResult = await _repository.getMessages(
      limit: contextWindowSize,
    );
    final history = historyResult.toNullable();
    if (history == null) return Left(historyResult.getLeft().toNullable()!);
    final context = [
      for (final m
          in history.where((m) => !m.isFailed).skipWhile((m) => !m.isFromUser))
        m.isFromUser
            ? AITurnMessage.user(m.content)
            : AITurnMessage.assistant(m.content),
    ];

    final systemPrompt = _systemPrompt.build(currentDate: _clock.now());
    final toolExchange = <AITurnMessage>[];
    final grounding = <ToolResult>[];

    for (var round = 0; ; round++) {
      // FR-014: a disable that lands while tools run stops the turn before
      // any further provider call. Nothing is persisted — the chat shows
      // the question as interrupted.
      if (round > 0 && !await _isStillEnabled()) {
        return const Left(AIAssistantDisabledFailure());
      }
      final turn = await _aiService.sendTurn(
        providerId: providerId,
        apiKey: apiKey,
        context: context,
        question: text,
        availableTools: aiToolCatalog,
        toolExchange: List.unmodifiable(toolExchange),
        systemPrompt: systemPrompt,
      );
      final Failure? failure = turn.getLeft().toNullable();
      if (failure != null) {
        return _persistFailure(text, _asAIFailure(failure), retryOfMessageId);
      }
      final result = turn.toNullable()!;

      final answer = result.answer;
      if (answer != null &&
          answer.trim().isNotEmpty &&
          !result.requestsToolCalls) {
        return _persistAnswer(
          text,
          answer,
          GroundingRefsCodec.encode(grounding),
          retryOfMessageId,
        );
      }
      if (!result.requestsToolCalls || round >= maxToolRounds) {
        return _persistFailure(
          text,
          UnrecognizedAIResponseFailure(
            result.requestsToolCalls
                ? 'AI kept requesting tools after $maxToolRounds rounds'
                : 'AI turn had no usable answer',
          ),
          retryOfMessageId,
        );
      }

      toolExchange.add(AITurnMessage.toolCallRequest(result.toolCalls));
      for (final call in result.toolCalls) {
        final toolResult = await _dispatch(call);
        if (toolResult.sourceUseCase != aiToolErrorSourceUseCase) {
          grounding.add(toolResult);
        }
        toolExchange.add(
          AITurnMessage.toolResult(toolCallId: call.id, toolResult: toolResult),
        );
      }
    }
  }

  /// Runs [call] once. A tool failure becomes a `foundData: false` result
  /// the model can react to (see the class doc, step 5).
  Future<ToolResult> _dispatch(AIToolCallRequest call) async {
    final outcome = await _tools.dispatch(call.toolName, call.arguments);
    return outcome.fold(
      (failure) => ToolResult(
        toolName: call.toolName,
        sourceUseCase: aiToolErrorSourceUseCase,
        foundData: false,
        data: {
          AIToolDataKeys.reason: aiToolErrorReason,
          AIToolErrorDataKeys.error: switch (failure) {
            // Argument problems are safe and useful for the model to see.
            ValidationFailure(:final message) => message,
            UnknownAIToolFailure(:final message) => message,
            _ => 'The tool could not be run',
          },
        },
      ),
      (result) => result,
    );
  }

  Future<bool> _isStillEnabled() async {
    final settings = (await _repository.getSettings()).toNullable();
    return settings != null && settings.isEnabled;
  }

  static AIAssistantFailure _asAIFailure(Failure failure) =>
      failure is AIAssistantFailure
      ? failure
      : const UnrecognizedAIResponseFailure('The AI turn failed unexpectedly');

  Future<void> _dropRetriedFailure(String? retryOfMessageId) async {
    if (retryOfMessageId == null) return;
    // Ignored when absent/not failed: the attempt's own outcome still
    // gets persisted.
    await _repository.deleteFailedMessage(retryOfMessageId);
  }

  Future<Either<Failure, AskFinancialQuestionResult>> _persistFailure(
    String question,
    AIAssistantFailure failure,
    String? retryOfMessageId,
  ) async {
    await _dropRetriedFailure(retryOfMessageId);
    final saved = await _repository.appendMessage(
      AIMessageDraft.failedQuestion(question, failureReason: failure.reason),
    );
    // A DB failure while saving outranks the AI failure: it is the reason
    // the question is not visible.
    return saved.fold(Left.new, (_) => Left(failure));
  }

  Future<Either<Failure, AskFinancialQuestionResult>> _persistAnswer(
    String question,
    String answer,
    String? groundingRefsJson,
    String? retryOfMessageId,
  ) async {
    await _dropRetriedFailure(retryOfMessageId);
    final savedQuestion = await _repository.appendMessage(
      AIMessageDraft.userQuestion(question),
    );
    final questionMessage = savedQuestion.toNullable();
    if (questionMessage == null) {
      return Left(savedQuestion.getLeft().toNullable()!);
    }
    final savedAnswer = await _repository.appendMessage(
      AIMessageDraft.assistantAnswer(
        answer,
        groundingRefsJson: groundingRefsJson,
      ),
    );
    return savedAnswer.map(
      (answerMessage) => AskFinancialQuestionResult(
        question: questionMessage,
        answer: answerMessage,
      ),
    );
  }
}
