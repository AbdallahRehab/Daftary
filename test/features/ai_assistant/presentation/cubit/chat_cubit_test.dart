import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_failures.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_proactive_observation_tool.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/ask_financial_question.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/clear_conversation.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_conversation.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_proactive_observation.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/chat_cubit.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/chat_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSettings extends Mock implements GetAIAssistantSettings {}

class MockGetConversation extends Mock implements GetConversation {}

class MockAsk extends Mock implements AskFinancialQuestion {}

class MockClear extends Mock implements ClearConversation {}

class MockGetObservation extends Mock implements GetProactiveObservation {}

final _t0 = DateTime(2026, 9, 24, 10);

AIMessage userMsg(String id, String content) => AIMessage(
  id: id,
  conversationId: 'c',
  sender: MessageSender.user,
  content: content,
  status: MessageStatus.sent,
  createdAt: _t0,
);

AIMessage answerMsg(String id, String content, {String? grounding}) =>
    AIMessage(
      id: id,
      conversationId: 'c',
      sender: MessageSender.assistant,
      content: content,
      status: MessageStatus.answered,
      createdAt: _t0,
      groundingRefsJson: grounding,
    );

AIMessage failedMsg(String id, String content, AIFailureReason reason) =>
    AIMessage(
      id: id,
      conversationId: 'c',
      sender: MessageSender.user,
      content: content,
      status: MessageStatus.failed,
      createdAt: _t0,
      failureReason: reason,
    );

/// T034/T048/T053/T060/T066/T073 — `ChatCubit` against mocked use cases.
void main() {
  late MockGetSettings getSettings;
  late MockGetConversation getConversation;
  late MockAsk ask;
  late MockClear clear;
  late MockGetObservation getObservation;

  final enabled = AIAssistantSettings.enabled(
    providerId: 'openai',
    consentAcceptedAt: _t0,
    updatedAt: _t0,
  );
  final disabled = AIAssistantSettings.disabled(updatedAt: _t0);

  final q1 = userMsg('q1', 'How much on food?');
  final a1 = answerMsg(
    'a1',
    'You spent 3,500.00 EGP on food.',
    grounding: '[{"toolName":"getCategorySpend","sourceUseCase":"X"}]',
  );

  ChatCubit build() =>
      ChatCubit(getSettings, getConversation, ask, clear, getObservation);

  void stubPage(
    List<AIMessage> messages, {
    int limit = ChatCubit.pageSize,
    int offset = 0,
  }) => when(
    () => getConversation(limit: limit, offset: offset),
  ).thenAnswer((_) async => Right(messages));

  void stubAsk(
    String question,
    Future<Either<Failure, AskFinancialQuestionResult>> Function() answer, {
    String? retryOf,
  }) => when(
    () => ask(question, retryOfMessageId: retryOf),
  ).thenAnswer((_) => answer());

  Future<ChatCubit> loaded() async {
    final cubit = build();
    await cubit.load(languageCode: 'en');
    return cubit;
  }

  setUp(() {
    getSettings = MockGetSettings();
    getConversation = MockGetConversation();
    ask = MockAsk();
    clear = MockClear();
    getObservation = MockGetObservation();
    when(() => getSettings()).thenAnswer((_) async => Right(enabled));
    stubPage(const []);
    when(
      () => getObservation(languageCode: any(named: 'languageCode')),
    ).thenAnswer((_) async => const Right(null));
  });

  group('load', () {
    blocTest<ChatCubit, ChatState>(
      'enabled: loading → ready with the latest page',
      setUp: () => stubPage([q1, a1]),
      build: build,
      act: (c) => c.load(languageCode: 'en'),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        ChatState(status: ChatStatus.ready, messages: [q1, a1]),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'disabled: shows the disabled state and loads nothing',
      setUp: () =>
          when(() => getSettings()).thenAnswer((_) async => Right(disabled)),
      build: build,
      act: (c) => c.load(languageCode: 'en'),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        const ChatState(status: ChatStatus.disabled),
      ],
      verify: (_) {
        verifyNever(
          () => getConversation(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        );
        verifyNever(
          () => getObservation(languageCode: any(named: 'languageCode')),
        );
      },
    );

    blocTest<ChatCubit, ChatState>(
      'a settings read failure is a load failure',
      setUp: () => when(
        () => getSettings(),
      ).thenAnswer((_) async => const Left(CacheFailure('db'))),
      build: build,
      act: (c) => c.load(languageCode: 'en'),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        const ChatState(
          status: ChatStatus.loadFailure,
          failure: CacheFailure('db'),
        ),
      ],
    );
  });

  group('send (T034)', () {
    blocTest<ChatCubit, ChatState>(
      'shows the question as pending (typing) then appends question + '
      'grounded answer',
      setUp: () => stubAsk(
        'How much on food?',
        () async => Right(AskFinancialQuestionResult(question: q1, answer: a1)),
      ),
      build: build,
      seed: () => const ChatState(status: ChatStatus.ready),
      act: (c) => c.send('  How much on food?  '),
      expect: () => [
        const ChatState(
          status: ChatStatus.ready,
          pendingQuestion: 'How much on food?',
        ),
        ChatState(status: ChatStatus.ready, messages: [q1, a1]),
      ],
      verify: (c) {
        expect(c.state.isSending, isFalse);
        verify(() => ask('How much on food?')).called(1);
      },
    );

    test('a rapid duplicate send while one is in flight is refused '
        '(FR-019)', () async {
      final completer =
          Completer<Either<Failure, AskFinancialQuestionResult>>();
      stubAsk('How much on food?', () => completer.future);
      final cubit = await loaded();

      final first = cubit.send('How much on food?');
      expect(cubit.state.isSending, isTrue);
      expect(cubit.state.canSend, isFalse);
      await cubit.send('How much on food?');
      await cubit.send('Another question');
      await cubit.retry(failedMsg('f', 'old', AIFailureReason.network));

      completer.complete(
        Right(AskFinancialQuestionResult(question: q1, answer: a1)),
      );
      await first;

      verify(
        () => ask(any(), retryOfMessageId: any(named: 'retryOfMessageId')),
      ).called(1);
      expect(cubit.state.messages, [q1, a1]);
      await cubit.close();
    });

    blocTest<ChatCubit, ChatState>(
      'a blank question is ignored',
      build: build,
      seed: () => const ChatState(status: ChatStatus.ready),
      act: (c) => c.send('   '),
      expect: () => const <ChatState>[],
      verify: (_) => verifyNever(
        () => ask(any(), retryOfMessageId: any(named: 'retryOfMessageId')),
      ),
    );
  });

  group('decline / clarifying question (T048)', () {
    blocTest<ChatCubit, ChatState>(
      'an ungrounded decline renders as an ordinary answer — no special '
      'state',
      setUp: () {
        final q = userMsg('q', 'Delete my Food budget');
        final decline = answerMsg(
          'a',
          "I can't change anything — I can only read your figures.",
        );
        stubAsk(
          'Delete my Food budget',
          () async =>
              Right(AskFinancialQuestionResult(question: q, answer: decline)),
        );
      },
      build: build,
      seed: () => const ChatState(status: ChatStatus.ready),
      act: (c) => c.send('Delete my Food budget'),
      skip: 1,
      expect: () => [
        ChatState(
          status: ChatStatus.ready,
          messages: [
            userMsg('q', 'Delete my Food budget'),
            answerMsg(
              'a',
              "I can't change anything — I can only read your figures.",
            ),
          ],
        ),
      ],
      verify: (c) {
        final answer = c.state.messages.last;
        expect(answer.isFailed, isFalse);
        expect(ChatState.isObservation(answer), isFalse);
      },
    );
  });

  group('history (T053)', () {
    final fullPage = [
      for (var i = 0; i < ChatCubit.pageSize; i++) userMsg('n$i', 'new $i'),
    ];
    final older = [for (var i = 0; i < 3; i++) userMsg('o$i', 'old $i')];

    test('a full first page offers more; loadEarlier prepends the next '
        'older page and stops at the start', () async {
      stubPage(fullPage);
      stubPage(older, offset: ChatCubit.pageSize);
      final cubit = await loaded();
      expect(cubit.state.hasMore, isTrue);

      final loading = cubit.loadEarlier();
      expect(cubit.state.isLoadingMore, isTrue);
      await loading;

      expect(cubit.state.messages, [...older, ...fullPage]);
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.isLoadingMore, isFalse);

      await cubit.loadEarlier(); // no more: ignored
      verify(
        () => getConversation(limit: ChatCubit.pageSize, offset: 50),
      ).called(1);
      await cubit.close();
    });

    blocTest<ChatCubit, ChatState>(
      'a failed loadEarlier keeps what is shown and reports once',
      setUp: () => when(
        () => getConversation(limit: ChatCubit.pageSize, offset: 1),
      ).thenAnswer((_) async => const Left(CacheFailure('db'))),
      build: build,
      seed: () =>
          ChatState(status: ChatStatus.ready, messages: [q1], hasMore: true),
      act: (c) => c.loadEarlier(),
      skip: 1,
      expect: () => [
        ChatState(
          status: ChatStatus.ready,
          messages: [q1],
          hasMore: true,
          outcome: ChatOutcome.loadEarlierFailed,
        ),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'clear resets the visible list to empty',
      setUp: () =>
          when(() => clear()).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => ChatState(
        status: ChatStatus.ready,
        messages: [q1, a1],
        hasMore: true,
      ),
      act: (c) => c.clear(),
      expect: () => [
        ChatState(
          status: ChatStatus.ready,
          messages: [q1, a1],
          hasMore: true,
          isClearing: true,
        ),
        const ChatState(status: ChatStatus.ready, outcome: ChatOutcome.cleared),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'a failed clear keeps the conversation and reports it',
      setUp: () => when(
        () => clear(),
      ).thenAnswer((_) async => const Left(CacheFailure('db'))),
      build: build,
      seed: () => ChatState(status: ChatStatus.ready, messages: [q1, a1]),
      act: (c) => c.clear(),
      skip: 1,
      expect: () => [
        ChatState(
          status: ChatStatus.ready,
          messages: [q1, a1],
          outcome: ChatOutcome.clearFailed,
        ),
      ],
    );

    test('a question asked right after clearing succeeds on its own '
        'merits', () async {
      when(() => clear()).thenAnswer((_) async => const Right(unit));
      final q2 = userMsg('q2', 'And transport?');
      final a2 = answerMsg('a2', 'You spent 900.00 EGP on transport.');
      stubAsk(
        'And transport?',
        () async => Right(AskFinancialQuestionResult(question: q2, answer: a2)),
      );
      stubPage([q1, a1]);
      final cubit = await loaded();

      await cubit.clear();
      await cubit.send('And transport?');

      expect(cubit.state.messages, [q2, a2]);
      expect(cubit.state.isSending, isFalse);
      await cubit.close();
    });

    test('clear is refused while a question is in flight', () async {
      final completer =
          Completer<Either<Failure, AskFinancialQuestionResult>>();
      stubAsk('q', () => completer.future);
      stubPage([q1, a1]);
      final cubit = await loaded();

      final sending = cubit.send('q');
      await cubit.clear();
      verifyNever(() => clear());

      completer.complete(const Left(AINetworkFailure('x')));
      await sending;
      await cubit.close();
    });
  });

  group('disable while in flight (T060/T062)', () {
    test('a late result after disabling is discarded and the pending '
        'question is shown as interrupted', () async {
      final completer =
          Completer<Either<Failure, AskFinancialQuestionResult>>();
      stubAsk('How much on food?', () => completer.future);
      final cubit = await loaded();

      final sending = cubit.send('How much on food?');
      cubit.assistantDisabled();
      completer.complete(
        Right(AskFinancialQuestionResult(question: q1, answer: a1)),
      );
      await sending;

      expect(cubit.state.status, ChatStatus.disabled);
      expect(cubit.state.interruptedQuestion, 'How much on food?');
      expect(cubit.state.messages, isEmpty);
      expect(cubit.state.isSending, isFalse);
      await cubit.close();
    });

    test('a reload that finds the assistant off (returning from settings) '
        'interrupts the in-flight question', () async {
      final completer =
          Completer<Either<Failure, AskFinancialQuestionResult>>();
      stubAsk('q', () => completer.future);
      final cubit = await loaded();
      final sending = cubit.send('q');

      when(() => getSettings()).thenAnswer((_) async => Right(disabled));
      await cubit.load();
      completer.complete(const Left(AINetworkFailure('late')));
      await sending;

      expect(cubit.state.status, ChatStatus.disabled);
      expect(cubit.state.interruptedQuestion, 'q');
      // The late failure never triggered a reload of the conversation.
      verify(() => getConversation(limit: ChatCubit.pageSize)).called(1);
      await cubit.close();
    });

    blocTest<ChatCubit, ChatState>(
      'the use case reporting the assistant off mid-turn interrupts the '
      'question',
      setUp: () =>
          stubAsk('q', () async => const Left(AIAssistantDisabledFailure())),
      build: build,
      seed: () => ChatState(status: ChatStatus.ready, messages: [q1, a1]),
      act: (c) => c.send('q'),
      skip: 1,
      expect: () => [
        const ChatState(status: ChatStatus.disabled, interruptedQuestion: 'q'),
      ],
    );

    test('after disabling nothing more is sent, and a reload never '
        'silently resumes — re-enabling is the settings flow only', () async {
      final cubit = await loaded();
      cubit.assistantDisabled();

      await cubit.send('anything');
      when(() => getSettings()).thenAnswer((_) async => Right(disabled));
      await cubit.load();

      expect(cubit.state.status, ChatStatus.disabled);
      verifyNever(
        () => ask(any(), retryOfMessageId: any(named: 'retryOfMessageId')),
      );

      // Once settings report it enabled again (full flow done there), the
      // chat is usable and the interruption notice is gone.
      when(() => getSettings()).thenAnswer((_) async => Right(enabled));
      await cubit.load();
      expect(cubit.state.status, ChatStatus.ready);
      expect(cubit.state.interruptedQuestion, isNull);
      await cubit.close();
    });
  });

  group('failures and retry (T066/T068)', () {
    final failures = <AIAssistantFailure>[
      const InvalidApiKeyFailure('x'),
      const RateLimitFailure('x'),
      const AINetworkFailure('x'),
      const AIProviderFailure('x'),
      const UnrecognizedAIResponseFailure('x'),
    ];

    for (final failure in failures) {
      test('${failure.runtimeType}: the persisted failed question is shown '
          'with reason ${failure.reason.name}', () async {
        final failed = failedMsg('f', 'How much?', failure.reason);
        stubAsk('How much?', () async => Left(failure));
        stubPage([q1, a1]);
        final cubit = await loaded();
        stubPage([q1, a1, failed]);

        await cubit.send('How much?');

        expect(cubit.state.messages, [q1, a1, failed]);
        expect(cubit.state.messages.last.failureReason, failure.reason);
        expect(cubit.state.isSending, isFalse);
        expect(cubit.state.unsavedQuestion, isNull);
        expect(cubit.state.failure, isNull);
        await cubit.close();
      });
    }

    test('each reason yields a distinct failed row (one banner variant '
        'per reason)', () {
      expect({
        for (final f in failures) f.reason,
      }, AIFailureReason.values.toSet());
    });

    test('retry re-sends the failed message\'s own content with its id, '
        'removing the failed row and appending the outcome', () async {
      final failed = failedMsg(
        'f',
        'How much on food?',
        AIFailureReason.network,
      );
      final completer =
          Completer<Either<Failure, AskFinancialQuestionResult>>();
      stubAsk('How much on food?', () => completer.future, retryOf: 'f');
      stubPage([failed]);
      final cubit = await loaded();

      final retrying = cubit.retry(failed);
      expect(cubit.state.messages, isEmpty);
      expect(cubit.state.pendingQuestion, 'How much on food?');
      completer.complete(
        Right(AskFinancialQuestionResult(question: q1, answer: a1)),
      );
      await retrying;

      expect(cubit.state.messages, [q1, a1]);
      verify(() => ask('How much on food?', retryOfMessageId: 'f')).called(1);
      await cubit.close();
    });

    test('retry of a non-failed message is ignored', () async {
      final cubit = await loaded();
      await cubit.retry(q1);
      verifyNever(
        () => ask(any(), retryOfMessageId: any(named: 'retryOfMessageId')),
      );
      await cubit.close();
    });

    test(
      'a local failure keeps the unsaved question for a local retry',
      () async {
        stubAsk('q', () async => const Left(CacheFailure('db')));
        final cubit = await loaded();

        await cubit.send('q');
        expect(cubit.state.unsavedQuestion, 'q');
        expect(cubit.state.failure, const CacheFailure('db'));
        expect(cubit.state.isSending, isFalse);

        final q = userMsg('q', 'q');
        stubAsk(
          'q',
          () async =>
              Right(AskFinancialQuestionResult(question: q, answer: a1)),
        );
        await cubit.retryUnsaved();
        expect(cubit.state.unsavedQuestion, isNull);
        expect(cubit.state.messages, [q, a1]);
        await cubit.close();
      },
    );
  });

  group('proactive observation (T073/T076)', () {
    final observation = answerMsg(
      'obs',
      'Your spending rose 25% last month compared with the month before.',
      grounding:
          '[{"toolName":"${GetProactiveObservationTool.toolName}",'
          '"sourceUseCase":"GetFinanceSummary"}]',
    );

    blocTest<ChatCubit, ChatState>(
      'a qualifying observation is appended as an assistant message with '
      'no preceding question',
      setUp: () => when(
        () => getObservation(languageCode: 'ar'),
      ).thenAnswer((_) async => Right(observation)),
      build: build,
      act: (c) => c.load(languageCode: 'ar'),
      skip: 2,
      expect: () => [
        ChatState(status: ChatStatus.ready, messages: [observation]),
      ],
      verify: (c) {
        final shown = c.state.messages.single;
        expect(shown.isFromUser, isFalse);
        expect(ChatState.isObservation(shown), isTrue);
        verify(() => getObservation(languageCode: 'ar')).called(1);
      },
    );

    blocTest<ChatCubit, ChatState>(
      'a non-qualifying account shows none',
      build: build,
      act: (c) => c.load(languageCode: 'en'),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        const ChatState(status: ChatStatus.ready),
      ],
    );

    test('an ordinary grounded answer is not an observation', () {
      expect(ChatState.isObservation(a1), isFalse);
      expect(ChatState.isObservation(q1), isFalse);
    });
  });
}
