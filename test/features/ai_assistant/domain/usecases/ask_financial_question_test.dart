import 'dart:convert';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_failures.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:daftary/features/ai_assistant/domain/entities/tool_result.dart';
import 'package:daftary/features/ai_assistant/domain/services/ai_service.dart';
import 'package:daftary/features/ai_assistant/domain/services/system_prompt_builder.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool_registry.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_arguments.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_catalog.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/ask_financial_question.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/ai_assistant_harness.dart';
import '../../helpers/fake_ai_service.dart';

/// T033/T046/T047/T059/T065 — `AskFinancialQuestion` against a real
/// in-memory repository, a scripted `AIService` and fake tools.
void main() {
  const openAi = AIProviderRegistry.openAiId;
  final today = DateTime(2026, 9, 24, 14, 5);

  const spendResult = ToolResult(
    toolName: AIToolNames.getCategorySpend,
    sourceUseCase: 'GetCategoryBreakdown',
    data: {'categoryName': 'Food', 'amountMinorUnits': 350000},
    foundData: true,
  );
  const owedResult = ToolResult(
    toolName: AIToolNames.getOwedOverview,
    sourceUseCase: 'GetOverview',
    data: {'totalOwedToUserMinorUnits': 120000},
    foundData: true,
  );
  const noBudgetResult = ToolResult(
    toolName: AIToolNames.getBudgetStatus,
    sourceUseCase: 'GetBudgetForMonth',
    data: {'month': '2026-09', 'reason': 'noBudgetForMonth'},
    foundData: false,
  );

  AIToolCallRequest call(
    String id,
    String tool, [
    Map<String, Object?> args = const {},
  ]) => AIToolCallRequest(id: id, toolName: tool, arguments: args);

  Either<Failure, AITurnResult> answer(String text) =>
      Right(AITurnResult.answer(text));
  Either<Failure, AITurnResult> toolCalls(List<AIToolCallRequest> calls) =>
      Right(AITurnResult.toolCalls(calls));

  late AIAssistantHarness h;
  late FakeAIService ai;
  late FakeAITool spendTool;
  late FakeAITool owedTool;
  late FakeAITool budgetTool;
  late FakeAITool brokenTool;
  late AskFinancialQuestion ask;

  setUp(() async {
    h = AIAssistantHarness.open();
    ai = FakeAIService();
    spendTool = FakeAITool(
      AIToolNames.getCategorySpend,
      const Right(spendResult),
    );
    owedTool = FakeAITool(AIToolNames.getOwedOverview, const Right(owedResult));
    budgetTool = FakeAITool(
      AIToolNames.getBudgetStatus,
      const Right(noBudgetResult),
    );
    brokenTool = FakeAITool(
      AIToolNames.getPersonBalance,
      const Left(ValidationFailure('"personName" must be a non-empty string')),
    );
    ask = AskFinancialQuestion(
      h.repository,
      ai,
      AIToolRegistry.fromTools([spendTool, owedTool, budgetTool, brokenTool]),
      const SystemPromptBuilder(),
      AIPeriodResolver.withClock(() => today),
    );
    await h.repository.enable(
      providerId: openAi,
      apiKey: testApiKey,
      consentAcceptedAt: today,
    );
  });
  tearDown(() => h.close());

  Future<List<AIMessage>> stored() async =>
      (await h.repository.getMessages(limit: 500)).toNullable()!;

  List<Map<String, Object?>> refs(String? json) =>
      (jsonDecode(json!) as List).cast<Map<String, Object?>>();

  group('grounded answer (T033)', () {
    test(
      'dispatches the requested tool exactly once, resubmits its real '
      'unmodified ToolResult, and persists question + grounded answer',
      () async {
        final spend = call('c1', AIToolNames.getCategorySpend, {
          'period': {'preset': 'thisMonth'},
          'categoryName': 'Food',
        });
        ai
          ..enqueue(toolCalls([spend]))
          ..enqueue(answer('You spent 3,500.00 EGP on Food this month.'));

        final result = await ask('  How much on food this month?  ');

        final value = result.toNullable()!;
        expect(spendTool.calls, [spend.arguments]);
        expect(ai.calls, hasLength(2));
        expect(ai.calls.first.toolExchange, isEmpty);
        expect(ai.calls.last.toolExchange, [
          AITurnMessage.toolCallRequest([spend]),
          const AITurnMessage.toolResult(
            toolCallId: 'c1',
            toolResult: spendResult,
          ),
        ]);
        for (final turn in ai.calls) {
          expect(turn.question, 'How much on food this month?');
          expect(turn.availableTools, aiToolCatalog);
          expect(turn.providerId, openAi);
          expect(turn.apiKey, testApiKey);
          expect(turn.systemPrompt, contains('2026-09-24'));
        }

        expect(value.question.sender, MessageSender.user);
        expect(value.question.status, MessageStatus.sent);
        expect(value.question.content, 'How much on food this month?');
        expect(value.answer.sender, MessageSender.assistant);
        expect(
          value.answer.content,
          'You spent 3,500.00 EGP on Food this month.',
        );
        expect(refs(value.answer.groundingRefsJson), [
          {
            'toolName': 'getCategorySpend',
            'sourceUseCase': 'GetCategoryBreakdown',
          },
        ]);
        expect(await stored(), [value.question, value.answer]);
      },
    );

    test(
      'several calls across two rounds: each dispatched once, exchange '
      'accumulated in order, grounding lists each distinct pair once',
      () async {
        final a = call('a', AIToolNames.getCategorySpend);
        final b = call('b', AIToolNames.getOwedOverview);
        final c = call('c', AIToolNames.getCategorySpend, {'x': 1});
        ai
          ..enqueue(toolCalls([a, b]))
          ..enqueue(toolCalls([c]))
          ..enqueue(answer('done'));

        final value = (await ask('q')).toNullable()!;

        expect(spendTool.calls, hasLength(2));
        expect(owedTool.calls, hasLength(1));
        expect(ai.calls[2].toolExchange, [
          AITurnMessage.toolCallRequest([a, b]),
          const AITurnMessage.toolResult(
            toolCallId: 'a',
            toolResult: spendResult,
          ),
          const AITurnMessage.toolResult(
            toolCallId: 'b',
            toolResult: owedResult,
          ),
          AITurnMessage.toolCallRequest([c]),
          const AITurnMessage.toolResult(
            toolCallId: 'c',
            toolResult: spendResult,
          ),
        ]);
        expect(refs(value.answer.groundingRefsJson), [
          {
            'toolName': 'getCategorySpend',
            'sourceUseCase': 'GetCategoryBreakdown',
          },
          {'toolName': 'getOwedOverview', 'sourceUseCase': 'GetOverview'},
        ]);
      },
    );

    test('sends only the bounded recent window as context, oldest → newest, '
        'excluding failed questions', () async {
      for (var i = 0; i < 15; i++) {
        await h.repository.appendMessage(AIMessageDraft.userQuestion('q$i'));
        await h.repository.appendMessage(AIMessageDraft.assistantAnswer('a$i'));
      }
      await h.repository.appendMessage(
        const AIMessageDraft.failedQuestion(
          'failed one',
          failureReason: AIFailureReason.network,
        ),
      );
      final all = await stored();
      final window = all.sublist(
        all.length - AskFinancialQuestion.contextWindowSize,
      );
      ai.enqueue(answer('ok'));

      await ask('new question');

      // The window's leading answer (a5) lost its question to the cut-off
      // and is dropped: the context always opens with a user turn.
      final expected = [
        for (final m in window.skip(1))
          if (!m.isFailed)
            m.isFromUser
                ? AITurnMessage.user(m.content)
                : AITurnMessage.assistant(m.content),
      ];
      final context = ai.calls.single.context;
      expect(context, expected);
      expect(context, hasLength(AskFinancialQuestion.contextWindowSize - 2));
      expect(context.first, const AITurnMessage.user('q6'));
      expect(context.last, const AITurnMessage.assistant('a14'));
      expect(context.map((m) => m.content), isNot(contains('failed one')));
    });

    test(
      'a tool failure is handed back to the model as a foundData=false '
      'toolError result, not aborting the turn and not counted as grounding',
      () async {
        final bad = call('p', AIToolNames.getPersonBalance, {'personName': ''});
        final unknown = call('u', 'deleteEverything');
        ai
          ..enqueue(toolCalls([bad, unknown]))
          ..enqueue(answer('Which person did you mean?'));

        final value = (await ask('how much does he owe?')).toNullable()!;

        expect(brokenTool.calls, hasLength(1));
        final results = ai.calls.last.toolExchange
            .where((m) => m.role == AITurnRole.tool)
            .map((m) => m.toolResult!)
            .toList();
        expect(results, hasLength(2));
        for (final r in results) {
          expect(r.foundData, isFalse);
          expect(r.data[AIToolDataKeys.reason], aiToolErrorReason);
          expect(r.data[AIToolErrorDataKeys.error], isA<String>());
        }
        expect(
          results.first.data[AIToolErrorDataKeys.error],
          contains('personName'),
        );
        expect(value.answer.groundingRefsJson, isNull);
      },
    );

    test(
      'a model still requesting tools after maxToolRounds fails as '
      'UnrecognizedAIResponseFailure and persists the question as failed',
      () async {
        for (var i = 0; i <= AskFinancialQuestion.maxToolRounds; i++) {
          ai.enqueue(toolCalls([call('c$i', AIToolNames.getCategorySpend)]));
        }

        final result = await ask('loop?');

        expect(
          result.getLeft().toNullable(),
          isA<UnrecognizedAIResponseFailure>(),
        );
        expect(ai.calls, hasLength(AskFinancialQuestion.maxToolRounds + 1));
        expect(spendTool.calls, hasLength(AskFinancialQuestion.maxToolRounds));
        final messages = await stored();
        expect(messages.single.status, MessageStatus.failed);
        expect(
          messages.single.failureReason,
          AIFailureReason.unrecognizedResponse,
        );
      },
    );

    test('a blank final answer is treated as unrecognized, never persisted '
        'as an empty assistant message', () async {
      ai.enqueue(answer('   '));

      final result = await ask('q');

      expect(
        result.getLeft().toNullable(),
        isA<UnrecognizedAIResponseFailure>(),
      );
      expect((await stored()).single.isFailed, isTrue);
    });

    test('a blank question is a ValidationFailure with no calls', () async {
      final result = await ask('   ');

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(ai.calls, isEmpty);
      expect(await stored(), isEmpty);
    });
  });

  group('foundData=false (T046)', () {
    test('the decline is persisted verbatim, carries no figure, and its '
        'grounding still records which tool was called', () async {
      ai
        ..enqueue(toolCalls([call('b', AIToolNames.getBudgetStatus)]))
        ..enqueue(answer("You haven't set a budget for this month yet."));

      final value = (await ask('How is my budget?')).toNullable()!;

      expect(
        value.answer.content,
        "You haven't set a budget for this month yet.",
      );
      expect(RegExp(r'\d').hasMatch(value.answer.content), isFalse);
      expect(ai.calls.last.toolExchange.last.toolResult, noBudgetResult);
      expect(refs(value.answer.groundingRefsJson), [
        {'toolName': 'getBudgetStatus', 'sourceUseCase': 'GetBudgetForMonth'},
      ]);
    });
  });

  group('no tool matched (T047)', () {
    test('a direct answer/decline is persisted with groundingRefsJson = null '
        'and no tool is dispatched', () async {
      ai.enqueue(answer("I can't give investment advice."));

      final value = (await ask('Should I buy gold?')).toNullable()!;

      expect(value.answer.groundingRefsJson, isNull);
      expect(value.answer.status, MessageStatus.answered);
      expect(
        [
          spendTool,
          owedTool,
          budgetTool,
          brokenTool,
        ].every((t) => t.calls.isEmpty),
        isTrue,
      );
    });
  });

  group('enabled-check short-circuit (T059)', () {
    test('a disabled assistant returns AIAssistantDisabledFailure with zero '
        'AIService calls and nothing persisted', () async {
      await h.repository.disable();

      final result = await ask('How much on food?');

      expect(result.getLeft().toNullable(), isA<AIAssistantDisabledFailure>());
      expect(result.getLeft().toNullable(), isNot(isA<AIAssistantFailure>()));
      expect(ai.calls, isEmpty);
      expect(spendTool.calls, isEmpty);
      expect(await stored(), isEmpty);
    });

    test('a disable that lands while a tool runs stops the turn before the '
        'follow-up provider call (FR-014, T062)', () async {
      final disablingTool = _DisablingTool(
        AIToolNames.getCategorySpend,
        onCall: () => h.repository.disable(),
        result: spendResult,
      );
      final askWithDisable = AskFinancialQuestion(
        h.repository,
        ai,
        AIToolRegistry.fromTools([disablingTool]),
        const SystemPromptBuilder(),
        AIPeriodResolver.withClock(() => today),
      );
      ai
        ..enqueue(toolCalls([call('c1', AIToolNames.getCategorySpend)]))
        ..enqueue(answer('never requested'));

      final result = await askWithDisable('How much on food?');

      expect(result.getLeft().toNullable(), isA<AIAssistantDisabledFailure>());
      expect(ai.calls, hasLength(1));
      expect(disablingTool.callCount, 1);
      expect(await stored(), isEmpty);
    });
  });

  group('failure persistence (T065)', () {
    for (final failure in <AIAssistantFailure>[
      const InvalidApiKeyFailure('401'),
      const RateLimitFailure('429'),
      const AINetworkFailure('offline'),
      const AIProviderFailure('500'),
      const UnrecognizedAIResponseFailure('garbage'),
    ]) {
      test('${failure.runtimeType} persists the question as failed with '
          'reason ${failure.reason.name} and is returned', () async {
        ai.enqueue(Left(failure));

        final result = await ask('How much on food?');

        expect(result.getLeft().toNullable(), failure);
        final message = (await stored()).single;
        expect(message.sender, MessageSender.user);
        expect(message.status, MessageStatus.failed);
        expect(message.content, 'How much on food?');
        expect(message.failureReason, failure.reason);
      });
    }

    test('a failure on the follow-up call (after a tool ran) still persists '
        'the question as failed and no answer', () async {
      ai
        ..enqueue(toolCalls([call('c', AIToolNames.getCategorySpend)]))
        ..enqueue(const Left(RateLimitFailure('429')));

      final result = await ask('q');

      expect(result.getLeft().toNullable(), isA<RateLimitFailure>());
      final messages = await stored();
      expect(messages.single.failureReason, AIFailureReason.rateLimited);
    });

    test('a missing stored key fails as InvalidApiKeyFailure without any '
        'provider call', () async {
      h.store.keys.clear();

      final result = await ask('q');

      expect(result.getLeft().toNullable(), isA<InvalidApiKeyFailure>());
      expect(ai.calls, isEmpty);
      expect(
        (await stored()).single.failureReason,
        AIFailureReason.invalidApiKey,
      );
    });

    test('a non-AI failure from the service is normalized to '
        'UnrecognizedAIResponseFailure', () async {
      ai.enqueue(const Left(UnknownFailure('?')));

      final result = await ask('q');

      expect(
        result.getLeft().toNullable(),
        isA<UnrecognizedAIResponseFailure>(),
      );
      expect(
        (await stored()).single.failureReason,
        AIFailureReason.unrecognizedResponse,
      );
    });
  });

  group('retry (FR-018)', () {
    Future<AIMessage> failOnce() async {
      ai.enqueue(const Left(AINetworkFailure('offline')));
      await ask('How much on food?');
      return (await stored()).single;
    }

    test(
      'a successful retry replaces the failed row with question + answer',
      () async {
        final failed = await failOnce();
        ai.enqueue(answer('ok'));

        final value = (await ask(
          failed.content,
          retryOfMessageId: failed.id,
        )).toNullable()!;

        expect(await stored(), [value.question, value.answer]);
      },
    );

    test('a retry that fails again leaves exactly one failed copy, with the '
        'new reason', () async {
      final failed = await failOnce();
      ai.enqueue(const Left(RateLimitFailure('429')));

      await ask(failed.content, retryOfMessageId: failed.id);

      final messages = await stored();
      expect(messages.single.id, isNot(failed.id));
      expect(messages.single.failureReason, AIFailureReason.rateLimited);
    });

    test('a retry id that is not a failed message never deletes it', () async {
      ai.enqueue(answer('first'));
      final first = (await ask('q1')).toNullable()!;
      ai.enqueue(answer('second'));

      await ask('q2', retryOfMessageId: first.question.id);

      expect(await stored(), hasLength(4));
    });
  });
}

/// A tool that runs a side effect (e.g. disabling the assistant) when
/// called, then returns [result].
class _DisablingTool extends AITool {
  _DisablingTool(this.name, {required this.onCall, required this.result});

  @override
  final String name;
  final Future<Object?> Function() onCall;
  final ToolResult result;
  int callCount = 0;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    callCount++;
    await onCall();
    return Right(result);
  }
}
