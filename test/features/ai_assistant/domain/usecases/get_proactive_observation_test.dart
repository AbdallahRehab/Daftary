import 'dart:convert';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_failures.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:daftary/features/ai_assistant/domain/entities/tool_result.dart';
import 'package:daftary/features/ai_assistant/domain/services/ai_service.dart';
import 'package:daftary/features/ai_assistant/domain/services/system_prompt_builder.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_proactive_observation_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_arguments.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_proactive_observation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/ai_assistant_harness.dart';
import '../../helpers/fake_ai_service.dart';

/// Returns whatever [outcome] currently holds and counts calls.
class FakeObservationTool implements GetProactiveObservationTool {
  FakeObservationTool(this.outcome);

  Either<Failure, ToolResult> outcome;
  int calls = 0;

  @override
  String get name => GetProactiveObservationTool.toolName;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    calls++;
    return outcome;
  }
}

ToolResult observation(String key) => ToolResult(
  toolName: GetProactiveObservationTool.toolName,
  sourceUseCase: 'GetFinanceSummary',
  foundData: true,
  data: {
    'percentChange': 25,
    'differenceMinorUnits': 50000,
    AIObservationDataKeys.direction: 'increase',
    AIObservationDataKeys.observationKey: key,
  },
);

/// T072 (+ T074's use case) — `GetProactiveObservation`: surfaces a real
/// observation narrated by the model from the unmodified tool result, and
/// never repeats the same unchanged observation.
void main() {
  const key1 = 'overallSpending:2026-07:2026-08:increase:25';
  const key2 = 'overallSpending:2026-08:2026-09:decrease:30';
  const narration = 'Your spending rose 25% in August — 500.00 EGP more.';

  late AIAssistantHarness h;
  late FakeAIService ai;
  late FakeObservationTool tool;
  late GetProactiveObservation getObservation;

  setUp(() async {
    h = AIAssistantHarness.open();
    ai = FakeAIService();
    tool = FakeObservationTool(Right(observation(key1)));
    getObservation = GetProactiveObservation(
      h.repository,
      ai,
      tool,
      const SystemPromptBuilder(),
      AIPeriodResolver.withClock(() => DateTime(2026, 9, 24)),
    );
    await h.repository.enable(
      providerId: AIProviderRegistry.openAiId,
      apiKey: testApiKey,
      consentAcceptedAt: DateTime(2026, 9, 1),
    );
  });
  tearDown(() => h.close());

  Future<List<AIMessage>> stored() async =>
      (await h.repository.getMessages(limit: 100)).toNullable()!;

  test('a qualifying observation is narrated by the model from the real '
      'tool result and persisted as a grounded assistant message', () async {
    ai.enqueue(const Right(AITurnResult.answer(narration)));

    final message = (await getObservation(languageCode: 'en')).toNullable()!;

    expect(message.sender, MessageSender.assistant);
    expect(message.content, narration);
    expect(jsonDecode(message.groundingRefsJson!), [
      {
        'toolName': 'getProactiveObservation',
        'sourceUseCase': 'GetFinanceSummary',
      },
    ]);
    expect(await stored(), [message]);

    final turn = ai.calls.single;
    expect(turn.context, isEmpty);
    expect(turn.availableTools, [proactiveObservationToolDeclaration]);
    expect(turn.question, contains('Reply in English'));
    expect(turn.apiKey, testApiKey);
    expect(turn.toolExchange.last.toolResult, observation(key1));
    expect(
      turn.toolExchange.first.toolCalls.single.toolName,
      GetProactiveObservationTool.toolName,
    );
    expect((await h.repository.getLastObservationKey()).toNullable(), key1);
  });

  test('asks for Arabic narration in the Arabic locale', () async {
    ai.enqueue(const Right(AITurnResult.answer('زاد إنفاقك ٢٥٪')));

    await getObservation(languageCode: 'ar');

    expect(ai.calls.single.question, contains('Reply in Arabic'));
  });

  test(
    'reopening without a changed observation does not repeat it (AC3)',
    () async {
      ai.enqueue(const Right(AITurnResult.answer(narration)));
      await getObservation(languageCode: 'en');

      final again = await getObservation(languageCode: 'en');

      expect(again.toNullable(), isNull);
      expect(again.isRight(), isTrue);
      expect(ai.calls, hasLength(1));
      expect(await stored(), hasLength(1));
    },
  );

  test('clearing the conversation does not bring back the unchanged '
      'observation', () async {
    ai.enqueue(const Right(AITurnResult.answer(narration)));
    await getObservation(languageCode: 'en');
    await h.repository.clearConversation();

    expect((await getObservation(languageCode: 'en')).toNullable(), isNull);
    expect(ai.calls, hasLength(1));
  });

  test('a meaningfully new observation is surfaced once more', () async {
    ai
      ..enqueue(const Right(AITurnResult.answer(narration)))
      ..enqueue(const Right(AITurnResult.answer('Spending fell 30%.')));
    await getObservation(languageCode: 'en');
    tool.outcome = Right(observation(key2));

    final second = (await getObservation(languageCode: 'en')).toNullable();

    expect(second?.content, 'Spending fell 30%.');
    expect(await stored(), hasLength(2));
    expect((await h.repository.getLastObservationKey()).toNullable(), key2);
  });

  test('nothing notable (foundData=false) → no observation and no AI call '
      '(AC2)', () async {
    tool.outcome = const Right(
      ToolResult(
        toolName: GetProactiveObservationTool.toolName,
        sourceUseCase: 'GetFinanceSummary',
        foundData: false,
        data: {'reason': 'insufficientHistory'},
      ),
    );

    final result = await getObservation(languageCode: 'en');

    expect(result.toNullable(), isNull);
    expect(ai.calls, isEmpty);
    expect(await stored(), isEmpty);
  });

  test('a disabled assistant makes no tool or AI call', () async {
    await h.repository.disable();

    final result = await getObservation(languageCode: 'en');

    expect(result.toNullable(), isNull);
    expect(tool.calls, 0);
    expect(ai.calls, isEmpty);
  });

  test('a failed AI turn surfaces nothing and does not mark the key, so the '
      'next open tries again', () async {
    ai
      ..enqueue(const Left(AINetworkFailure('offline')))
      ..enqueue(const Right(AITurnResult.answer(narration)));

    final first = await getObservation(languageCode: 'en');

    expect(first.toNullable(), isNull);
    expect(await stored(), isEmpty);
    expect((await h.repository.getLastObservationKey()).toNullable(), isNull);

    final second = await getObservation(languageCode: 'en');
    expect(second.toNullable()?.content, narration);
  });

  test(
    'a model that asks for tools instead of narrating surfaces nothing',
    () async {
      ai.enqueue(
        const Right(
          AITurnResult.toolCalls([
            AIToolCallRequest(
              id: 'x',
              toolName: 'getOwedOverview',
              arguments: {},
            ),
          ]),
        ),
      );

      expect((await getObservation(languageCode: 'en')).toNullable(), isNull);
      expect(await stored(), isEmpty);
    },
  );
}
