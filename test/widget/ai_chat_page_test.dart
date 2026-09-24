import 'dart:async';

import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/l10n/app_localizations_ar.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/ask_financial_question.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/clear_conversation.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_conversation.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_proactive_observation.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/chat_cubit.dart';
import 'package:daftary/features/ai_assistant/presentation/pages/chat_page.dart';
import 'package:daftary/features/ai_assistant/presentation/widgets/ai_failure_banner.dart';
import 'package:daftary/features/ai_assistant/presentation/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSettings extends Mock implements GetAIAssistantSettings {}

class MockGetConversation extends Mock implements GetConversation {}

class MockAsk extends Mock implements AskFinancialQuestion {}

class MockClear extends Mock implements ClearConversation {}

class MockGetObservation extends Mock implements GetProactiveObservation {}

/// T043/T057/T069 — the chat page: send flow with typing indicator and
/// in-flight guard, failure banner + retry, clear with confirmation, RTL
/// bubble placement, and the disabled state.
void main() {
  final t0 = DateTime(2026, 9, 24, 10);
  late MockGetSettings getSettings;
  late MockGetConversation getConversation;
  late MockAsk ask;
  late MockClear clear;

  AIMessage msg(
    String id,
    String content, {
    MessageSender sender = MessageSender.user,
    AIFailureReason? failure,
  }) => AIMessage(
    id: id,
    conversationId: 'c',
    sender: sender,
    content: content,
    status: failure != null
        ? MessageStatus.failed
        : sender == MessageSender.user
        ? MessageStatus.sent
        : MessageStatus.answered,
    createdAt: t0,
    failureReason: failure,
  );

  final question = msg('q1', 'How much on food?');
  final answer = msg(
    'a1',
    'You spent 3,500.00 EGP on food.',
    sender: MessageSender.assistant,
  );

  void stubPage(List<AIMessage> messages) => when(
    () => getConversation(
      limit: any(named: 'limit'),
      offset: any(named: 'offset'),
    ),
  ).thenAnswer((_) async => Right(messages));

  setUp(() {
    getSettings = MockGetSettings();
    getConversation = MockGetConversation();
    ask = MockAsk();
    clear = MockClear();
    when(() => getSettings()).thenAnswer(
      (_) async => Right(
        AIAssistantSettings.enabled(
          providerId: 'openai',
          consentAcceptedAt: t0,
          updatedAt: t0,
        ),
      ),
    );
    stubPage(const []);
  });

  Future<ChatCubit> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    final observation = MockGetObservation();
    when(
      () => observation(languageCode: any(named: 'languageCode')),
    ).thenAnswer((_) async => const Right(null));
    final cubit = ChatCubit(
      getSettings,
      getConversation,
      ask,
      clear,
      observation,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit..load(languageCode: locale.languageCode),
          child: const ChatView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  IconButton sendButton(WidgetTester tester) => tester.widget<IconButton>(
    find.ancestor(
      of: find.byIcon(Icons.send_rounded),
      matching: find.byType(IconButton),
    ),
  );

  testWidgets('empty state, then send: typing indicator and disabled send '
      'while in flight, then the answer', (tester) async {
    final completer = Completer<Either<Failure, AskFinancialQuestionResult>>();
    when(
      () => ask('How much on food?', retryOfMessageId: null),
    ).thenAnswer((_) => completer.future);
    await pump(tester);

    expect(find.text('Ask about your own money'), findsOneWidget);
    expect(sendButton(tester).onPressed, isNull, reason: 'empty input');
    expect(find.byTooltip('Send question'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'How much on food?');
    await tester.pump();
    expect(sendButton(tester).onPressed, isNotNull);

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(find.byType(TypingIndicator), findsOneWidget);
    expect(find.text('How much on food?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Another');
    await tester.pump();
    expect(sendButton(tester).onPressed, isNull, reason: 'FR-019');

    completer.complete(
      Right(AskFinancialQuestionResult(question: question, answer: answer)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TypingIndicator), findsNothing);
    expect(find.text('You spent 3,500.00 EGP on food.'), findsOneWidget);
    verify(() => ask('How much on food?', retryOfMessageId: null)).called(1);
  });

  testWidgets('a failed question shows its banner; retry re-sends it '
      'without retyping', (tester) async {
    final failed = msg(
      'f1',
      'How much on food?',
      failure: AIFailureReason.network,
    );
    stubPage([failed]);
    when(() => ask('How much on food?', retryOfMessageId: 'f1')).thenAnswer(
      (_) async =>
          Right(AskFinancialQuestionResult(question: question, answer: answer)),
    );
    await pump(tester);

    expect(find.byType(AIFailureBanner), findsOneWidget);
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Not answered'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    verify(() => ask('How much on food?', retryOfMessageId: 'f1')).called(1);
    expect(find.byType(AIFailureBanner), findsNothing);
    expect(find.text('You spent 3,500.00 EGP on food.'), findsOneWidget);
  });

  testWidgets('an invalid key offers "Update API key", not retry', (
    tester,
  ) async {
    stubPage([msg('f1', 'q', failure: AIFailureReason.invalidApiKey)]);
    await pump(tester);

    expect(find.text('API key not accepted'), findsOneWidget);
    expect(find.text('Update API key'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('clear asks for confirmation, then empties the conversation', (
    tester,
  ) async {
    stubPage([question, answer]);
    when(() => clear()).thenAnswer((_) async => const Right(unit));
    await pump(tester);

    await tester.tap(find.byTooltip('Clear conversation'));
    await tester.pumpAndSettle();
    expect(find.text('Clear this conversation?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    verify(() => clear()).called(1);
    expect(find.text('How much on food?'), findsNothing);
    expect(find.text('Ask about your own money'), findsOneWidget);
    expect(find.text('Conversation cleared'), findsOneWidget);
  });

  testWidgets('cancelling the clear confirmation keeps everything', (
    tester,
  ) async {
    stubPage([question, answer]);
    await pump(tester);

    await tester.tap(find.byTooltip('Clear conversation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => clear());
    expect(find.text('How much on food?'), findsOneWidget);
  });

  for (final (locale, userOnRight) in [
    (const Locale('en'), true),
    (const Locale('ar'), false),
  ]) {
    testWidgets('bubble placement follows reading direction '
        '(${locale.languageCode})', (tester) async {
      stubPage([question, answer]);
      await pump(tester, locale: locale);

      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final userX = tester.getCenter(find.text('How much on food?')).dx;
      final assistantX = tester
          .getCenter(find.text('You spent 3,500.00 EGP on food.'))
          .dx;
      expect(userX > width / 2, userOnRight);
      expect(assistantX > width / 2, !userOnRight);
    });
  }

  testWidgets('disabled: explains and links to settings, with no input', (
    tester,
  ) async {
    when(() => getSettings()).thenAnswer(
      (_) async => Right(AIAssistantSettings.disabled(updatedAt: t0)),
    );
    await pump(tester);

    expect(find.text('The assistant is off'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    verifyNever(
      () => getConversation(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    );
  });

  testWidgets('a question interrupted by disabling is shown as not '
      'answered', (tester) async {
    final completer = Completer<Either<Failure, AskFinancialQuestionResult>>();
    when(
      () => ask('How much on food?', retryOfMessageId: null),
    ).thenAnswer((_) => completer.future);
    final cubit = await pump(tester);

    await tester.enterText(find.byType(TextField), 'How much on food?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    cubit.assistantDisabled();
    completer.complete(
      Right(AskFinancialQuestionResult(question: question, answer: answer)),
    );
    await tester.pumpAndSettle();

    expect(find.text('The assistant is off'), findsOneWidget);
    expect(find.text('How much on food?'), findsOneWidget);
    expect(
      find.text(
        'Not answered: the assistant was turned off before a reply arrived',
      ),
      findsOneWidget,
    );
    expect(find.text('You spent 3,500.00 EGP on food.'), findsNothing);
  });

  // T079 — every icon-only action carries a localized tooltip (which is
  // also its semantics label), and the input keeps an accessible name.
  testWidgets('icon-only actions have tooltips; the input has a label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    stubPage([question, answer]);
    await pump(tester);

    expect(find.byTooltip('Send question'), findsOneWidget);
    expect(find.byTooltip('Clear conversation'), findsOneWidget);
    expect(find.byTooltip('Assistant settings'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Ask about your spending')),
      findsWidgets,
    );
    handle.dispose();
  });

  // T081/T083 — a mixed conversation with a failed question renders in
  // Arabic (RTL) in both themes without layout errors, bubbles mirrored.
  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    testWidgets('ar RTL ($name): conversation with a failure banner renders '
        'mirrored without overflow', (tester) async {
      final ar = AppLocalizationsAr();
      stubPage([
        question,
        answer,
        msg('q2', 'كام صرفت على الأكل؟', failure: AIFailureReason.rateLimited),
      ]);
      await pump(tester, locale: const Locale('ar'), theme: theme);

      expect(tester.takeException(), isNull);
      expect(find.text(ar.aiFailureRateLimitedTitle), findsOneWidget);
      expect(find.text(ar.aiFailureRetryAction), findsOneWidget);
      expect(find.text(ar.aiChatMessageFailedLabel), findsOneWidget);
      expect(find.byTooltip(ar.aiChatSendAction), findsOneWidget);

      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      // User questions sit at the end edge — the left in RTL.
      expect(
        tester.getCenter(find.text('كام صرفت على الأكل؟')).dx,
        lessThan(width / 2),
      );
      expect(
        tester.getCenter(find.text('You spent 3,500.00 EGP on food.')).dx,
        greaterThan(width / 2),
      );
    });
  }

  // Regression (found by T082): the routed ChatPage must not read an
  // InheritedWidget inside BlocProvider.create.
  testWidgets('the routed ChatPage builds its own cubit without errors', (
    tester,
  ) async {
    final observation = MockGetObservation();
    when(
      () => observation(languageCode: any(named: 'languageCode')),
    ).thenAnswer((_) async => const Right(null));
    getIt.registerFactory<ChatCubit>(
      () => ChatCubit(getSettings, getConversation, ask, clear, observation),
    );
    addTearDown(() => getIt.unregister<ChatCubit>());

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ChatPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ChatView), findsOneWidget);
    verify(() => observation(languageCode: 'en')).called(1);
  });
}
