import 'package:daftary/features/ai_assistant/data/datasources/ai_provider_catalog_impl.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/services/ai_service.dart';
import 'package:daftary/features/ai_assistant/domain/services/system_prompt_builder.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool_registry.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_arguments.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/ask_financial_question.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/clear_conversation.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/disable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/enable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_conversation.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_proactive_observation.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/update_provider_credentials.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/ai_settings_cubit.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/chat_cubit.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/chat_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/ai_assistant_harness.dart';
import '../../helpers/fake_ai_service.dart';

class MockGetObservation extends Mock implements GetProactiveObservation {}

/// T061 — after `AISettingsCubit.disable()`, a `ChatCubit.send()` fails
/// fast with zero `AIService` interactions. Both cubits share one real
/// repository (in-memory DB, faked keychain); only the provider is faked.
void main() {
  final now = DateTime(2026, 9, 24, 12);
  late AIAssistantHarness h;
  late FakeAIService ai;
  late AISettingsCubit settingsCubit;
  late ChatCubit chatCubit;

  setUp(() async {
    h = AIAssistantHarness.open();
    ai = FakeAIService();
    await h.repository.enable(
      providerId: AIProviderRegistry.openAiId,
      apiKey: testApiKey,
      consentAcceptedAt: now,
    );
    final getSettings = GetAIAssistantSettings(h.repository);
    settingsCubit = AISettingsCubit(
      getSettings,
      EnableAIAssistant(h.repository),
      DisableAIAssistant(h.repository),
      UpdateProviderCredentials(h.repository),
      const AIProviderCatalogImpl(),
    );
    final observation = MockGetObservation();
    when(
      () => observation(languageCode: any(named: 'languageCode')),
    ).thenAnswer((_) async => const Right(null));
    chatCubit = ChatCubit(
      getSettings,
      GetConversation(h.repository),
      AskFinancialQuestion(
        h.repository,
        ai,
        AIToolRegistry.fromTools(const []),
        const SystemPromptBuilder(),
        AIPeriodResolver.withClock(() => now),
      ),
      ClearConversation(h.repository),
      observation,
    );
  });

  tearDown(() async {
    await settingsCubit.close();
    await chatCubit.close();
    await h.close();
  });

  test('control: while enabled, a send reaches the provider once', () async {
    ai.enqueue(const Right(AITurnResult.answer('You spent nothing yet.')));
    await chatCubit.load(languageCode: 'en');

    await chatCubit.send('How much did I spend?');

    expect(ai.calls, hasLength(1));
    expect(chatCubit.state.messages, hasLength(2));
  });

  test('after AISettingsCubit.disable(), ChatCubit.send() fails fast with '
      'zero AIService interactions', () async {
    await chatCubit.load(languageCode: 'en');
    expect(chatCubit.state.status, ChatStatus.ready);

    await settingsCubit.load();
    await settingsCubit.disable();
    expect(settingsCubit.state.isEnabled, isFalse);

    // The chat screen has not reloaded yet — the send still must not go out.
    await chatCubit.send('How much did I spend?');

    expect(ai.calls, isEmpty);
    expect(chatCubit.state.status, ChatStatus.disabled);
    expect(chatCubit.state.interruptedQuestion, 'How much did I spend?');
    expect(
      (await h.repository.getMessages()).toNullable(),
      isEmpty,
      reason: 'nothing is persisted for a question refused while disabled',
    );

    // Any further attempt is refused by the cubit itself.
    await chatCubit.send('Again?');
    expect(ai.calls, isEmpty);
  });
}
