import 'package:daftary/features/ai_assistant/data/datasources/secure_credential_store_impl.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/ai_assistant_harness.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// T019 — the keychain wrapper: one fixed logical entry per provider slot,
/// and the key value never in its `toString`.
void main() {
  late MockFlutterSecureStorage storage;
  late SecureCredentialStoreImpl store;

  setUp(() {
    storage = MockFlutterSecureStorage();
    store = SecureCredentialStoreImpl(storage);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  test('a preset writes under its own fixed entry name', () async {
    await store.write(AIProviderRegistry.openAiId, testApiKey);

    verify(
      () => storage.write(
        key: 'daftary.ai_assistant.api_key.openai',
        value: testApiKey,
      ),
    ).called(1);
  });

  test(
    'every custom provider shares one entry, never derived from its URL',
    () async {
      final custom = AIProviderRegistry.encodeCustom(
        baseUrl: 'https://llm.example.com/v1',
        model: 'm1',
      )!;

      await store.write(custom, testApiKey);

      verify(
        () => storage.write(
          key: 'daftary.ai_assistant.api_key.custom',
          value: testApiKey,
        ),
      ).called(1);
    },
  );

  test('reads and deletes the same entry it writes', () async {
    when(
      () => storage.read(key: 'daftary.ai_assistant.api_key.gemini'),
    ).thenAnswer((_) async => testApiKey);

    expect(await store.read(AIProviderRegistry.geminiId), testApiKey);
    await store.delete(AIProviderRegistry.geminiId);

    verify(
      () => storage.delete(key: 'daftary.ai_assistant.api_key.gemini'),
    ).called(1);
  });

  test('toString never exposes a stored key', () async {
    await store.write(AIProviderRegistry.openAiId, testApiKey);

    expect(store.toString(), isNot(contains(testApiKey)));
  });

  test('every slot is covered once by the disable walk', () {
    final slots = {
      for (final id in SecureCredentialStoreImpl.everySlotProviderId)
        SecureCredentialStoreImpl.storageKeyFor(id),
    };

    expect(slots, hasLength(AIProviderRegistry.presets.length + 1));
    expect(slots, contains('daftary.ai_assistant.api_key.custom'));
  });
}
