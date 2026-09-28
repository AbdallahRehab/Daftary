import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/clear_conversation.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_conversation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/ai_assistant_harness.dart';

/// T051 — `GetConversation`/`ClearConversation`: pages come back in
/// chronological order; clearing permanently removes every message without
/// touching `AIAssistantSettings`.
void main() {
  late AIAssistantHarness h;
  late GetConversation getConversation;
  late ClearConversation clearConversation;

  setUp(() {
    h = AIAssistantHarness.open();
    getConversation = GetConversation(h.repository);
    clearConversation = ClearConversation(h.repository);
  });
  tearDown(() => h.close());

  Future<void> seed(int count) async {
    for (var i = 0; i < count; i++) {
      await h.repository.appendMessage(AIMessageDraft.userQuestion('q$i'));
    }
  }

  List<String> contents(List<AIMessage> messages) => [
    for (final m in messages) m.content,
  ];

  test('the first page is the newest messages, oldest first', () async {
    await seed(8);

    final page = (await getConversation(limit: 3)).toNullable()!;

    expect(contents(page), ['q5', 'q6', 'q7']);
  });

  test('offset pages further back, still in chronological order', () async {
    await seed(8);

    final older = (await getConversation(limit: 3, offset: 3)).toNullable()!;
    final oldest = (await getConversation(limit: 3, offset: 6)).toNullable()!;

    expect(contents(older), ['q2', 'q3', 'q4']);
    expect(contents(oldest), ['q0', 'q1']);
  });

  test('the default page size is 50', () async {
    await seed(60);

    final page = (await getConversation()).toNullable()!;

    expect(page, hasLength(GetConversation.defaultPageSize));
    expect(page.first.content, 'q10');
    expect(page.last.content, 'q59');
  });

  test('clearing permanently removes every message and leaves the settings '
      'untouched', () async {
    final enabled = (await h.repository.enable(
      providerId: AIProviderRegistry.openAiId,
      apiKey: testApiKey,
      consentAcceptedAt: DateTime(2026, 9, 1),
    )).toNullable()!;
    await seed(5);

    final result = await clearConversation();

    expect(result.isRight(), isTrue);
    expect((await getConversation()).toNullable(), isEmpty);
    expect(await h.db.select(h.db.aiMessages).get(), isEmpty);
    expect((await h.repository.getSettings()).toNullable(), enabled);
    expect(h.store.keys, isNotEmpty);
  });
}
