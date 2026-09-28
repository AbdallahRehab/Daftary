import 'dart:async';

import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_failures.dart';
import 'package:daftary/features/ai_assistant/domain/entities/tool_result.dart';
import 'package:daftary/features/ai_assistant/domain/services/ai_service.dart';
import 'package:daftary/features/ai_assistant/domain/services/secure_credential_store.dart';
import 'package:daftary/features/ai_assistant/domain/tools/category_breakdown_data.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_owed_overview_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_person_balance_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_proactive_observation_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_catalog.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/clear_conversation.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/disable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/enable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_conversation.dart';
import 'package:daftary/features/ai_assistant/presentation/pages/ai_settings_page.dart';
import 'package:daftary/features/ai_assistant/presentation/pages/chat_page.dart';
import 'package:daftary/features/dashboard/presentation/pages/home_page.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/presentation/pages/people_list_page.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/get_overview.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';

/// 014 T082 — quickstart.md Scenarios 1-9 end-to-end against the real app
/// (real DI, real on-device SQLite, real tools over real use cases), with
/// exactly two seams replaced in GetIt:
///
/// - `AIService` → [ScriptedAIService]: scripted turns, no network, never
///   a real provider (plan.md Testing strategy);
/// - `SecureCredentialStore` → [InMemoryCredentialStore]: never the real
///   keychain.
///
/// Every test starts from a fresh-install assistant (disabled, empty
/// conversation) and seeds uniquely-named rows, so the shared on-device
/// database's other contents never affect the figures asserted here.
///
/// Scenario 5 as written needs feature 011 (Savings), which is not built:
/// `getSavingsGoalStatus` does not exist. Its savings-specific step is
/// skipped; the same honest-decline guarantee (a `foundData: false` tool
/// result never becomes a figure) is exercised with `getPersonBalance` for
/// a person who does not exist.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const uuid = Uuid();
  const testKey = 'sk-test-integration-0123456789';
  final egp = EgpFormatter(locale: 'en');
  String money(int minorUnits) => egp.formatWithSymbol(Money.egp(minorUnits));

  late ScriptedAIService ai;
  late InMemoryCredentialStore store;
  late AppLocalizations l10n;

  Future<AppLocalizations> load(String code) =>
      AppLocalizations.delegate.load(Locale(code));

  /// Frames without waiting to settle — used while a question is in
  /// flight, since the typing indicator animates until it resolves.
  Future<void> pumpFrames(WidgetTester tester, [int count = 10]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> bootApp(
    WidgetTester tester, {
    AppLanguage language = AppLanguage.english,
    bool enabled = true,
  }) async {
    await getIt.reset();
    await configureDependencies();
    ai = ScriptedAIService();
    store = InMemoryCredentialStore();
    getIt
      ..unregister<AIService>()
      ..registerLazySingleton<AIService>(() => ai)
      ..unregister<SecureCredentialStore>()
      ..registerLazySingleton<SecureCredentialStore>(() => store);

    // A fresh-install assistant: off, nothing stored, empty conversation.
    await getIt<DisableAIAssistant>()();
    await getIt<ClearConversation>()();
    if (enabled) {
      (await getIt<EnableAIAssistant>()(
        providerId: 'openai',
        apiKey: testKey,
        consentAcceptedAt: DateTime.now(),
      )).getOrElse((f) => throw StateError('enable failed: $f'));
    }

    // A person on record keeps the onboarding gate out of the way.
    (await getIt<PeopleRepository>().createPerson(
      name: 'AI Boot ${uuid.v4().substring(0, 8)}',
    )).getOrElse((f) => throw StateError('seed person failed: $f'));

    await getIt<SettingsCubit>().initialize();
    await getIt<SettingsCubit>().changeLanguage(language);
    await getIt<OnboardingCubit>().initialize();
    l10n = await load(language.name == 'arabic' ? 'ar' : 'en');
    appRouter.go('/overview');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Future<void> openChat(WidgetTester tester) async {
    appRouter.push(ChatPage.location);
    await tester.pumpAndSettle();
    expect(find.byType(ChatView), findsOneWidget);
  }

  Future<void> ask(
    WidgetTester tester,
    String question, {
    bool settle = true,
  }) async {
    // Any snackbar (e.g. "conversation cleared") would cover the input.
    ScaffoldMessenger.of(
      tester.element(find.byType(ChatView)),
    ).removeCurrentSnackBar();
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), question);
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.aiChatSendAction));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await pumpFrames(tester, 3);
    }
  }

  /// A unique expense category with [minorUnits] spent in it today.
  Future<Category> seedFoodSpend(int minorUnits) async {
    final category = (await getIt<CategoryRepository>().createCategory(
      name: 'IT Food ${uuid.v4().substring(0, 8)}',
      type: CategoryType.expense,
      icon: 'other',
    )).getOrElse((f) => throw StateError('category failed: $f'));
    (await getIt<FinanceRepository>().addEntry(
      idempotencyKey: uuid.v4(),
      categoryId: category.id,
      type: FinanceEntryType.expense,
      amount: Money.egp(minorUnits),
      date: DateTime.now(),
    )).getOrElse((f) => throw StateError('entry failed: $f'));
    return category;
  }

  /// Scripts "call getCategorySpend, then narrate exactly what it
  /// returned" — the fake never invents a number of its own.
  void scriptCategorySpend(String categoryName, {required bool arabic}) {
    ai
      ..enqueue(
        (_) => Right(
          AITurnResult.toolCalls([
            AIToolCallRequest(
              id: 'call-${uuid.v4()}',
              toolName: AIToolNames.getCategorySpend,
              arguments: {
                AIToolArgs.period: {'preset': AIPeriodPresets.thisMonth},
                AIToolArgs.categoryName: categoryName,
              },
            ),
          ]),
        ),
      )
      ..enqueue((turn) {
        final result = turn.toolResults.single;
        final category =
            result.data[AICategoryDataKeys.category]! as Map<String, Object?>;
        final amount = money(
          category[AICategoryDataKeys.amountMinorUnits]! as int,
        );
        return Right(
          AITurnResult.answer(
            arabic
                ? 'صرفت $amount على $categoryName الشهر ده.'
                : 'You spent $amount on $categoryName this month.',
          ),
        );
      });
  }

  Future<int> financeEntryCount() async {
    final db = getIt<AppDatabase>();
    return (await db.select(db.financeEntries).get()).length;
  }

  group('US1 — setup', () {
    testWidgets('Scenario 1: off by default, with zero AI calls', (
      tester,
    ) async {
      await bootApp(tester, enabled: false);

      final home = find.descendant(
        of: find.byType(HomePage),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text(l10n.aiAssistantTitle),
        200,
        scrollable: home.first,
      );
      await tester.tap(find.text(l10n.aiAssistantTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ChatView), findsOneWidget);
      expect(find.text(l10n.aiChatDisabledTitle), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(ai.totalCalls, 0);
    });

    testWidgets('Scenario 2: enabling needs both a key and consent', (
      tester,
    ) async {
      await bootApp(tester, enabled: false);
      appRouter.push(AISettingsPage.location);
      await tester.pumpAndSettle();

      Future<void> fillAndContinue() async {
        await tester.tap(find.text('OpenAI'));
        await tester.enterText(
          find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.labelText == l10n.aiSettingsApiKeyLabel,
          ),
          testKey,
        );
        await tester.ensureVisible(find.text(l10n.aiSettingsContinueAction));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.aiSettingsContinueAction));
        await tester.pumpAndSettle();
      }

      // Key entered, disclosure declined: still off, nothing stored.
      await fillAndContinue();
      await tester.tap(find.text(l10n.aiConsentDeclineAction));
      await tester.pumpAndSettle();
      var settings = (await getIt<GetAIAssistantSettings>()()).toNullable()!;
      expect(settings.isEnabled, isFalse);
      expect(store.keys, isEmpty);

      // Accepted: on, consent timestamp recorded, key in secure storage.
      await fillAndContinue();
      await tester.ensureVisible(find.text(l10n.aiConsentAcceptAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.aiConsentAcceptAction));
      await tester.pumpAndSettle();
      settings = (await getIt<GetAIAssistantSettings>()()).toNullable()!;
      expect(settings.isEnabled, isTrue);
      expect(settings.consentAcceptedAt, isNotNull);
      expect(store.keys.values, contains(testKey));
      // The key is never displayed back.
      expect(find.textContaining(testKey), findsNothing);
      expect(ai.totalCalls, 0);
    });
  });

  group('US2/US3 — grounded answers and honest declines', () {
    for (final language in AppLanguage.values) {
      testWidgets('Scenario 3 (${language.name}): category spend equals '
          'GetCategoryBreakdown exactly', (tester) async {
        await bootApp(tester, language: language);
        final food = await seedFoodSpend(12345);
        await openChat(tester);

        final arabic = language == AppLanguage.arabic;
        scriptCategorySpend(food.name, arabic: arabic);
        await ask(
          tester,
          arabic
              ? 'أنا صرفت كام على ${food.name} الشهر ده؟'
              : 'How much did I spend on ${food.name} this month?',
        );

        final breakdown = (await getIt<GetCategoryBreakdown>()(
          DateRange.thisMonth(),
          type: FinanceEntryType.expense,
        )).getOrElse((f) => throw StateError('breakdown failed: $f'));
        final expected = breakdown.items
            .singleWhere((item) => item.categoryId == food.id)
            .total!
            .minorUnits;
        expect(expected, 12345);

        final toolResult = ai.calls.last.toolResults.single;
        expect(toolResult.sourceUseCase, 'GetCategoryBreakdown');
        final category =
            toolResult.data[AICategoryDataKeys.category]!
                as Map<String, Object?>;
        expect(category[AICategoryDataKeys.amountMinorUnits], expected);
        expect(find.textContaining(money(expected)), findsOneWidget);
        // Each turn carried the stored key, read from (fake) secure storage.
        expect(ai.calls.every((c) => c.apiKey == testKey), isTrue);
      });
    }

    testWidgets('Scenario 4: who owes me matches GetOverview exactly', (
      tester,
    ) async {
      await bootApp(tester);
      final name = 'IT Debtor ${uuid.v4().substring(0, 8)}';
      final person = (await getIt<PeopleRepository>().createPerson(
        name: name,
      )).getOrElse((f) => throw StateError('person failed: $f'));
      (await getIt<TransactionsRepository>().addTransaction(
        idempotencyKey: uuid.v4(),
        personId: person.id,
        amount: const Money.egp(25000),
        direction: TransactionDirection.given,
        date: DateTime.now(),
      )).getOrElse((f) => throw StateError('transaction failed: $f'));
      await openChat(tester);

      ai
        ..enqueue(
          (_) => const Right(
            AITurnResult.toolCalls([
              AIToolCallRequest(
                id: 'call-owed',
                toolName: AIToolNames.getOwedOverview,
                arguments: {},
              ),
            ]),
          ),
        )
        ..enqueue((turn) {
          final owe =
              turn.toolResults.single.data[AIOverviewDataKeys.peopleTheyOweYou]!
                  as List<Object?>;
          final entry = owe.cast<Map<String, Object?>>().singleWhere(
            (p) => p[AIPersonDataKeys.personName] == name,
          );
          final net = money(entry[AIPersonDataKeys.netMinorUnits]! as int);
          return Right(AITurnResult.answer('$name owes you $net.'));
        });
      await ask(tester, 'Who still owes me money?');

      final overview = (await getIt<GetOverview>()()).getOrElse(
        (f) => throw StateError('overview failed: $f'),
      );
      final expected = overview.peopleTheyOweYou.singleWhere(
        (p) => p.personId == person.id,
      );
      expect(expected.net!.minorUnits, 25000);
      expect(
        find.textContaining('$name owes you ${money(25000)}'),
        findsOneWidget,
      );
    });

    testWidgets('Scenario 5: no data on record → an honest decline with no '
        'figures', (tester) async {
      // Savings step skipped: feature 011 (getSavingsGoalStatus) is not
      // built. Same guarantee, via a person who does not exist.
      await bootApp(tester);
      await openChat(tester);
      final ghost = 'Nobody ${uuid.v4()}';

      ai
        ..enqueue(
          (_) => Right(
            AITurnResult.toolCalls([
              AIToolCallRequest(
                id: 'call-ghost',
                toolName: AIToolNames.getPersonBalance,
                arguments: {AIToolArgs.personName: ghost},
              ),
            ]),
          ),
        )
        ..enqueue((turn) {
          expect(turn.toolResults.single.foundData, isFalse);
          return const Right(
            AITurnResult.answer(
              "I don't have anyone by that name on record, so I can't say.",
            ),
          );
        });
      await ask(tester, 'How much does $ghost owe me?');

      expect(ai.calls.last.toolResults.single.foundData, isFalse);
      const reply =
          "I don't have anyone by that name on record, so I can't "
          'say.';
      expect(find.text(reply), findsOneWidget);
      expect(RegExp(r'\d').hasMatch(reply), isFalse);
    });

    testWidgets('Scenario 6: write and investment requests are declined; '
        'nothing is written', (tester) async {
      await bootApp(tester);
      await openChat(tester);
      final before = await financeEntryCount();

      const declineAdd =
          "I can only read your records — I can't add an expense for you.";
      const declineInvest =
          "I can't give personalised investment recommendations.";
      ai
        ..enqueue((_) => const Right(AITurnResult.answer(declineAdd)))
        ..enqueue((_) => const Right(AITurnResult.answer(declineInvest)));
      await ask(tester, 'Add a 500 EGP expense for me');
      await ask(tester, 'What stock should I invest in?');

      expect(find.text(declineAdd), findsOneWidget);
      expect(find.text(declineInvest), findsOneWidget);
      expect(await financeEntryCount(), before);
      // Only the read-only catalog is ever offered to the model.
      for (final call in ai.calls) {
        expect(
          call.availableTools.map((t) => t.name).toSet(),
          everyElement(isIn(AIToolNames.all)),
        );
      }
    });
  });

  group('US4-US6 — history, disable, failures', () {
    testWidgets('Scenario 7: clear empties the conversation; the next '
        'question still works', (tester) async {
      await bootApp(tester);
      final food = await seedFoodSpend(4200);
      await openChat(tester);

      ai.enqueue((_) => const Right(AITurnResult.answer('Hello there.')));
      await ask(tester, 'Hi');
      expect(find.text('Hello there.'), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.aiChatClearAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.aiChatClearConfirmAction));
      await tester.pumpAndSettle();

      final messages = (await getIt<GetConversation>()()).getOrElse(
        (f) => throw StateError('conversation failed: $f'),
      );
      expect(messages, isEmpty);
      expect(find.text('Hello there.'), findsNothing);

      scriptCategorySpend(food.name, arabic: false);
      await ask(tester, 'How much did I spend on ${food.name} this month?');
      expect(find.textContaining(money(4200)), findsOneWidget);
    });

    testWidgets('Scenario 8: disabling mid-flight stops every further call '
        'and marks the question interrupted', (tester) async {
      await bootApp(tester);
      await openChat(tester);

      final inFlight = Completer<Either<Failure, AITurnResult>>();
      ai.enqueue((_) => inFlight.future);
      await ask(tester, 'How much did I spend this month?', settle: false);
      expect(ai.calls, hasLength(1));

      // Turn it off through the real settings flow while it is in flight.
      await tester.tap(find.byTooltip(l10n.aiChatSettingsAction));
      await pumpFrames(tester);
      await tester.ensureVisible(find.text(l10n.aiSettingsDisableAction));
      await pumpFrames(tester);
      await tester.tap(find.text(l10n.aiSettingsDisableAction));
      await pumpFrames(tester);
      await tester.tap(find.text(l10n.aiSettingsDisableConfirmAction));
      await pumpFrames(tester);
      expect(store.keys, isEmpty);
      await tester.pageBack();
      await pumpFrames(tester);

      // The provider "answers" with a tool request: no further round may
      // be sent for a disabled assistant.
      inFlight.complete(
        const Right(
          AITurnResult.toolCalls([
            AIToolCallRequest(
              id: 'late',
              toolName: AIToolNames.getOwedOverview,
              arguments: {},
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(ai.calls, hasLength(1));
      expect(find.text(l10n.aiChatDisabledTitle), findsOneWidget);
      expect(find.text(l10n.aiChatInterruptedLabel), findsOneWidget);

      // Every other feature keeps working.
      appRouter.go('/people');
      await tester.pumpAndSettle();
      expect(find.byType(PeopleListPage), findsOneWidget);
      expect(ai.calls, hasLength(1));
    });

    final cases = <(String, AIAssistantFailure, String Function())>[
      (
        'offline',
        const AINetworkFailure('scripted: no connectivity'),
        () => l10n.aiFailureNetworkTitle,
      ),
      (
        'invalid key',
        const InvalidApiKeyFailure('scripted: key rejected (401)'),
        () => l10n.aiFailureInvalidApiKeyTitle,
      ),
      (
        'rate limited',
        const RateLimitFailure('scripted: rate limit (429)'),
        () => l10n.aiFailureRateLimitedTitle,
      ),
      (
        'provider error',
        const AIProviderFailure('scripted: provider error (503)'),
        () => l10n.aiFailureProviderErrorTitle,
      ),
      (
        'unrecognized response',
        const UnrecognizedAIResponseFailure('scripted: garbled response'),
        () => l10n.aiFailureUnrecognizedTitle,
      ),
    ];
    for (final (name, failure, title) in cases) {
      testWidgets('Scenario 9 ($name): friendly message, question kept and '
          'retryable, no raw error text', (tester) async {
        await bootApp(tester);
        await openChat(tester);
        const question = 'How much did I spend on transport?';

        ai.enqueue((_) => Left(failure));
        await ask(tester, question);

        expect(find.text(title()), findsOneWidget);
        expect(find.text(question), findsOneWidget);
        expect(find.text(l10n.aiChatMessageFailedLabel), findsOneWidget);
        expect(find.textContaining('scripted:'), findsNothing);

        if (failure is InvalidApiKeyFailure) {
          expect(find.text(l10n.aiFailureUpdateKeyAction), findsOneWidget);
          expect(find.text(l10n.aiFailureRetryAction), findsNothing);
          return;
        }

        // Retry without retyping: the same question is re-sent.
        ai.enqueue((_) => const Right(AITurnResult.answer('Recovered.')));
        await tester.tap(find.text(l10n.aiFailureRetryAction));
        await tester.pumpAndSettle();

        expect(ai.calls.last.question, question);
        expect(find.text('Recovered.'), findsOneWidget);
        expect(find.text(title()), findsNothing);
        expect(find.text(question), findsOneWidget);
      });
    }
  });
}

/// One question-answering [AIService.sendTurn] call.
class RecordedTurn {
  RecordedTurn({
    required this.apiKey,
    required this.question,
    required this.availableTools,
    required this.toolExchange,
  });

  final String apiKey;
  final String question;
  final List<AIToolDeclaration> availableTools;
  final List<AITurnMessage> toolExchange;

  /// The tool results handed back to the model in this call.
  List<ToolResult> get toolResults => [
    for (final m in toolExchange) ?m.toolResult,
  ];
}

typedef TurnScript =
    FutureOr<Either<Failure, AITurnResult>> Function(RecordedTurn turn);

/// A scripted, network-free [AIService]. Question turns are answered by
/// the next queued [TurnScript]; the automatic proactive-observation turn
/// is counted separately and always fails (which the app treats as
/// "nothing to show"), so it can never consume a scripted answer.
class ScriptedAIService implements AIService {
  final List<TurnScript> _scripts = [];
  final List<RecordedTurn> calls = [];
  int observationCalls = 0;

  int get totalCalls => calls.length + observationCalls;

  void enqueue(TurnScript script) => _scripts.add(script);

  @override
  Future<Either<Failure, AITurnResult>> sendTurn({
    required String providerId,
    required String apiKey,
    required List<AITurnMessage> context,
    required String question,
    required List<AIToolDeclaration> availableTools,
    List<AITurnMessage> toolExchange = const [],
    String systemPrompt = '',
  }) async {
    if (availableTools.any(
      (t) => t.name == GetProactiveObservationTool.toolName,
    )) {
      observationCalls++;
      return const Left(AIProviderFailure('observation not scripted'));
    }
    final turn = RecordedTurn(
      apiKey: apiKey,
      question: question,
      availableTools: availableTools,
      toolExchange: List.of(toolExchange),
    );
    calls.add(turn);
    if (_scripts.isEmpty) {
      return const Left(UnrecognizedAIResponseFailure('no turn scripted'));
    }
    return _scripts.removeAt(0)(turn);
  }
}

/// An in-memory stand-in for the platform keychain.
class InMemoryCredentialStore implements SecureCredentialStore {
  final Map<String, String> keys = {};

  @override
  Future<void> write(String providerId, String apiKey) async =>
      keys[providerId] = apiKey;

  @override
  Future<String?> read(String providerId) async => keys[providerId];

  @override
  Future<void> delete(String providerId) async => keys.remove(providerId);
}
