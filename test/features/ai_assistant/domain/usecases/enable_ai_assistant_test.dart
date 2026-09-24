import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/enable_ai_assistant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/ai_assistant_harness.dart';

class MockAIAssistantRepository extends Mock implements AIAssistantRepository {}

/// T014 — `EnableAIAssistant`: shape validation happens before secure
/// storage (or any network) is touched, and enabling needs a key *and* a
/// consent timestamp, applied together.
void main() {
  const openAi = AIProviderRegistry.openAiId;
  final consentAt = DateTime(2026, 9, 20, 9);

  group('validation, before the repository is reached', () {
    late MockAIAssistantRepository repository;
    late EnableAIAssistant enable;

    setUp(() {
      repository = MockAIAssistantRepository();
      enable = EnableAIAssistant(repository);
    });

    for (final (label, key) in [
      ('an empty', ''),
      ('a blank', '    '),
      ('a truncated', 'sk-12'),
      ('a whitespace-containing', 'sk-abc defghijk'),
    ]) {
      test('rejects $label key with ValidationFailure and never calls the '
          'repository', () async {
        final result = await enable(
          providerId: openAi,
          apiKey: key,
          consentAcceptedAt: consentAt,
        );

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        verifyZeroInteractions(repository);
      });
    }

    test('passes a well-formed request through unchanged', () async {
      final enabled = AIAssistantSettings.enabled(
        providerId: openAi,
        consentAcceptedAt: consentAt,
        updatedAt: consentAt,
      );
      when(
        () => repository.enable(
          providerId: openAi,
          apiKey: testApiKey,
          consentAcceptedAt: consentAt,
        ),
      ).thenAnswer((_) async => Right(enabled));

      final result = await enable(
        providerId: openAi,
        apiKey: testApiKey,
        consentAcceptedAt: consentAt,
      );

      expect(result.toNullable(), enabled);
    });
  });

  group('against the real repository and a faked keychain', () {
    late AIAssistantHarness h;
    late EnableAIAssistant enable;

    setUp(() {
      h = AIAssistantHarness.open();
      enable = EnableAIAssistant(h.repository);
    });
    tearDown(() => h.close());

    test('a malformed key never reaches secure storage', () async {
      await enable(
        providerId: openAi,
        apiKey: 'short',
        consentAcceptedAt: consentAt,
      );

      expect(h.store.log, isEmpty);
      expect(await h.db.select(h.db.aiSettings).get(), isEmpty);
    });

    test(
      'with a key and a consent timestamp, enables with both recorded',
      () async {
        final settings = (await enable(
          providerId: openAi,
          apiKey: testApiKey,
          consentAcceptedAt: consentAt,
        )).toNullable()!;

        expect(settings.isEnabled, isTrue);
        expect(settings.hasStoredCredential, isTrue);
        expect(settings.consentAcceptedAt, consentAt);
        expect(h.store.keys, {openAi: testApiKey});
      },
    );

    test(
      'atomically: when the key cannot be stored, nothing is enabled',
      () async {
        h.store.failWrites = true;

        final result = await enable(
          providerId: openAi,
          apiKey: testApiKey,
          consentAcceptedAt: consentAt,
        );

        expect(result.isLeft(), isTrue);
        final settings = (await h.repository.getSettings()).toNullable()!;
        expect(settings.isEnabled, isFalse);
        expect(settings.consentAcceptedAt, isNull);
      },
    );
  });
}
