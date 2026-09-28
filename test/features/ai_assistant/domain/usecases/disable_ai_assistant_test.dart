import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/datasources/secure_credential_store_impl.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/disable_ai_assistant.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/ai_assistant_harness.dart';

/// T015 — `DisableAIAssistant`: `isEnabled=false`, consent cleared and the
/// credential deleted as one atomic operation, with the call order
/// verified against the real database.
void main() {
  late AIAssistantHarness h;
  late DisableAIAssistant disable;
  const openAi = AIProviderRegistry.openAiId;

  setUp(() async {
    h = AIAssistantHarness.open();
    disable = DisableAIAssistant(h.repository);
    await h.repository.enable(
      providerId: openAi,
      apiKey: testApiKey,
      consentAcceptedAt: DateTime(2026, 9, 1),
    );
    h.store.log.clear();
  });
  tearDown(() => h.close());

  test('disables, clears consent and deletes the credential', () async {
    final result = await disable();

    expect(result.isRight(), isTrue);
    final settings = (await h.repository.getSettings()).toNullable()!;
    expect(settings.isEnabled, isFalse);
    expect(settings.consentAcceptedAt, isNull);
    expect(settings.hasStoredCredential, isFalse);
    expect(h.store.keys, isEmpty);
  });

  test('call order: the settings row is already disabled when the key is '
      'deleted, and every credential slot is deleted', () async {
    final enabledAtDelete = <bool>[];
    h.store.onCall = (operation, _) async {
      if (operation != 'delete') return;
      // Runs inside the repository's transaction, so this read sees the
      // transaction's own writes.
      final row = await h.dao.getSettings();
      enabledAtDelete.add(row!.isEnabled);
    };

    await disable();

    expect(h.store.log, [
      for (final id in SecureCredentialStoreImpl.everySlotProviderId)
        'delete:$id',
    ]);
    expect(enabledAtDelete, everyElement(isFalse));
    expect(h.store.log, isNot(contains(startsWith('write:'))));
  });

  test('atomic: if the key cannot be deleted, the disable is rolled back '
      'as a whole — never a disabled row with the key left resident', () async {
    h.store.failDeletes = true;

    final result = await disable();

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
    final settings = (await h.repository.getSettings()).toNullable()!;
    expect(settings.isEnabled, isTrue);
    expect(settings.hasStoredCredential, isTrue);
    expect(h.store.keys, {openAi: testApiKey});
  });
}
