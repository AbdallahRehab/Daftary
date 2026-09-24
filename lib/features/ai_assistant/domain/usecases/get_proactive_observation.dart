import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_message.dart';
import '../entities/grounding_refs.dart';
import '../services/ai_service.dart';
import '../services/system_prompt_builder.dart';
import '../repositories/ai_assistant_repository.dart';
import '../tools/get_proactive_observation_tool.dart';
import '../tools/tool_arguments.dart';

/// The declaration under which the observation's [ToolResult] is handed to
/// the model. Offered only on the narration turn (providers such as
/// Anthropic reject a tool result for an undeclared tool); never part of
/// `aiToolCatalog`, so the model cannot call it while answering questions.
const AIToolDeclaration proactiveObservationToolDeclaration = AIToolDeclaration(
  name: GetProactiveObservationTool.toolName,
  description:
      "Compares the user's total spending in the last complete month with "
      'the complete month before it (integer minor units).',
  parametersSchema: {'type': 'object', 'properties': <String, Object?>{}},
);

/// Surfaces at most one unprompted, already-computed spending observation
/// when the assistant is opened (User Story 7, FR-020).
///
/// Returns the persisted assistant message, or `null` when nothing should
/// be shown:
/// - the assistant is disabled (no outbound call is ever made);
/// - [GetProactiveObservationTool] finds nothing notable (`foundData:
///   false` — insufficient history or below threshold): no observation is
///   fabricated (AC2);
/// - this exact observation (`observationKey`) was already surfaced (AC3 —
///   the key encodes both months, direction and rounded percent, so a new
///   month or a meaningfully different change yields a new key);
/// - the key is unavailable or the provider turn fails / returns no usable
///   narration — an automatic check never shows a failure banner, and is
///   simply retried on the next open.
///
/// Grounding: the figures are never templated or computed here. The real,
/// unmodified observation [ToolResult] is handed to [AIService] as the
/// result of a (locally executed) tool call, with a fixed instruction to
/// narrate only its figures — the same grounding path as
/// `AskFinancialQuestion`. The persisted message's `groundingRefsJson`
/// names the observation tool and its source use case.
///
/// De-duplication: the surfaced key is stored on the settings singleton
/// (`AIAssistantRepository.recordSurfacedObservation`) only after the
/// message was persisted. It survives clearing the conversation, so
/// clearing does not bring back an unchanged observation.
@injectable
class GetProactiveObservation {
  const GetProactiveObservation(
    this._repository,
    this._aiService,
    this._observationTool,
    this._systemPrompt,
    this._clock,
  );

  final AIAssistantRepository _repository;
  final AIService _aiService;
  final GetProactiveObservationTool _observationTool;
  final SystemPromptBuilder _systemPrompt;
  final AIPeriodResolver _clock;

  /// The id of the synthetic tool call the observation result answers.
  static const String toolCallId = 'proactive-observation';

  /// The fixed instruction sent as the turn's user message. Not typed by
  /// the user and never persisted as a message.
  static String instructionFor(String languageCode) {
    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    return 'This is an automatic check, not a message typed by the user. '
        'The getProactiveObservation result above is a notable change in '
        "the user's total spending between two complete months. In one or "
        'two short, friendly sentences, tell the user about it using only '
        'the figures in that result (state the real percentage and/or '
        'amount it contains), then invite them to ask a question. Do not '
        'call any tool. Reply in $language.';
  }

  /// [languageCode] is the app's current locale language (`'ar'` or
  /// `'en'`), since there is no user question to take the language from.
  Future<Either<Failure, AIMessage?>> call({
    required String languageCode,
  }) async {
    final settingsResult = await _repository.getSettings();
    final settings = settingsResult.toNullable();
    if (settings == null) return Left(settingsResult.getLeft().toNullable()!);
    final providerId = settings.providerId;
    if (!settings.isEnabled || providerId == null) return const Right(null);

    final observationResult = await _observationTool(const {});
    final observation = observationResult.toNullable();
    if (observation == null) {
      return Left(observationResult.getLeft().toNullable()!);
    }
    final key = observation.data[AIObservationDataKeys.observationKey];
    if (!observation.foundData || key is! String) return const Right(null);

    final lastKeyResult = await _repository.getLastObservationKey();
    if (lastKeyResult.isLeft()) {
      return Left(lastKeyResult.getLeft().toNullable()!);
    }
    if (lastKeyResult.toNullable() == key) return const Right(null);

    final apiKey = (await _repository.readApiKey()).toNullable();
    if (apiKey == null) return const Right(null);

    final turn = await _aiService.sendTurn(
      providerId: providerId,
      apiKey: apiKey,
      context: const [],
      question: instructionFor(languageCode),
      availableTools: const [proactiveObservationToolDeclaration],
      toolExchange: [
        const AITurnMessage.toolCallRequest([
          AIToolCallRequest(
            id: toolCallId,
            toolName: GetProactiveObservationTool.toolName,
            arguments: {},
          ),
        ]),
        AITurnMessage.toolResult(
          toolCallId: toolCallId,
          toolResult: observation,
        ),
      ],
      systemPrompt: _systemPrompt.build(currentDate: _clock.now()),
    );
    final narration = turn.toNullable()?.answer;
    if (narration == null || narration.trim().isEmpty) {
      return const Right(null);
    }

    final saved = await _repository.appendMessage(
      AIMessageDraft.assistantAnswer(
        narration,
        groundingRefsJson: GroundingRefsCodec.encode([observation]),
      ),
    );
    final message = saved.toNullable();
    if (message == null) return Left(saved.getLeft().toNullable()!);

    // Best effort: if this write fails, the message is still shown now and
    // the worst case is one repeat on a later open.
    await _repository.recordSurfacedObservation(key);
    return Right(message);
  }
}
