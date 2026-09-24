import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/update_provider_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/ai_assistant_harness.dart';

/// T016 — `UpdateProviderCredentials`: replaces the stored key without
/// changing `isEnabled`/`consentAcceptedAt`; rejects an empty key.
void main() {
  late AIAssistantHarness h;
  late UpdateProviderCredentials update;
  const openAi = AIProviderRegistry.openAiId;
  const gemini = AIProviderRegistry.geminiId;
  final consentAt = DateTime(2026, 9, 1, 8);

  setUp(() async {
    h = AIAssistantHarness.open();
    update = UpdateProviderCredentials(h.repository);
    await h.repository.enable(
      providerId: openAi,
      apiKey: testApiKey,
      consentAcceptedAt: consentAt,
    );
    h.store.log.clear();
  });
  tearDown(() => h.close());

  test(
    'replaces the key; isEnabled and consentAcceptedAt are unchanged',
    () async {
      final settings = (await update(
        providerId: openAi,
        apiKey: otherTestApiKey,
      )).toNullable()!;

      expect(settings.isEnabled, isTrue);
      expect(settings.consentAcceptedAt, consentAt);
      expect(h.store.keys, {openAi: otherTestApiKey});
    },
  );

  test('switching provider replaces and fully discards the old key', () async {
    final settings = (await update(
      providerId: gemini,
      apiKey: otherTestApiKey,
    )).toNullable()!;

    expect(settings.providerId, gemini);
    expect(settings.consentAcceptedAt, consentAt);
    expect(h.store.keys, {gemini: otherTestApiKey});
  });

  for (final key in ['', '   ']) {
    test(
      'rejects an empty key ("$key") without touching secure storage',
      () async {
        final result = await update(providerId: openAi, apiKey: key);

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        expect(h.store.log, isEmpty);
        expect(h.store.keys, {openAi: testApiKey});
      },
    );
  }
}
