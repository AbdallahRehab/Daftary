import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/datasources/secure_credential_store_impl.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/ai_assistant_harness.dart';

/// T017/T052 — `AIAssistantRepositoryImpl` against an in-memory database
/// and a faked keychain.
void main() {
  late AIAssistantHarness h;

  setUp(() => h = AIAssistantHarness.open());
  tearDown(() => h.close());

  final consentAt = DateTime(2026, 9, 20, 10, 30);
  const openAi = AIProviderRegistry.openAiId;
  const anthropic = AIProviderRegistry.anthropicId;

  Future<AIAssistantSettings> enable({
    String providerId = openAi,
    String apiKey = testApiKey,
  }) async {
    final result = await h.repository.enable(
      providerId: providerId,
      apiKey: apiKey,
      consentAcceptedAt: consentAt,
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }

  group('getSettings (T017)', () {
    test('a fresh install reads as the default, disabled singleton, without '
        'writing a row', () async {
      final settings = (await h.repository.getSettings()).toNullable()!;

      expect(settings.id, AIAssistantSettings.singletonId);
      expect(settings.isEnabled, isFalse);
      expect(settings.hasStoredCredential, isFalse);
      expect(settings.providerId, isNull);
      expect(settings.consentAcceptedAt, isNull);
      expect(await h.db.select(h.db.aiSettings).get(), isEmpty);
    });

    test('a row claiming enabled but missing its consent is read as '
        'disabled (invariant enforced on read)', () async {
      await h.dao.upsertSettings(
        isEnabled: true,
        providerId: openAi,
        hasStoredCredential: true,
        consentAcceptedAt: null,
        updatedAt: 1,
      );

      final settings = (await h.repository.getSettings()).toNullable()!;
      expect(settings.isEnabled, isFalse);
    });
  });

  group('enable (T017)', () {
    test('stores the key, records consent and enables — together', () async {
      final settings = await enable();

      expect(settings.isEnabled, isTrue);
      expect(settings.providerId, openAi);
      expect(settings.hasStoredCredential, isTrue);
      expect(settings.consentAcceptedAt, consentAt);
      expect(h.store.keys, {openAi: testApiKey});

      final row = (await h.db.select(h.db.aiSettings).getSingle());
      expect(row.isEnabled, isTrue);
      expect(row.consentAcceptedAt, consentAt.millisecondsSinceEpoch);
    });

    test('creates the single conversation lazily on first enable', () async {
      await enable();
      await h.repository.disable();
      await enable();

      expect(await h.db.select(h.db.aiConversations).get(), hasLength(1));
    });

    test('trims whitespace pasted around the key before storing it', () async {
      await enable(apiKey: '  $testApiKey\n');
      expect(h.store.keys[openAi], testApiKey);
    });

    for (final (label, key) in [
      ('empty', ''),
      ('blank', '   '),
      ('too short', 'sk-1'),
      ('containing whitespace', 'sk-test 0123456789'),
    ]) {
      test('rejects a $label key before touching either store', () async {
        final result = await h.repository.enable(
          providerId: openAi,
          apiKey: key,
          consentAcceptedAt: consentAt,
        );

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        expect(h.store.log, isEmpty);
        expect(await h.db.select(h.db.aiSettings).get(), isEmpty);
      });
    }

    test(
      'rejects an unrecognized provider before touching either store',
      () async {
        final result = await h.repository.enable(
          providerId: 'no-such-provider',
          apiKey: testApiKey,
          consentAcceptedAt: consentAt,
        );

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        expect(h.store.log, isEmpty);
      },
    );

    test('accepts a well-formed custom provider', () async {
      final custom = AIProviderRegistry.encodeCustom(
        baseUrl: 'https://llm.example.com/v1',
        model: 'model-1',
      )!;

      final settings = await enable(providerId: custom);

      expect(settings.providerId, custom);
      expect(h.store.keys[custom], testApiKey);
    });

    test('a keychain failure rolls the settings row back — never an enabled '
        'row without its key', () async {
      h.store.failWrites = true;

      final result = await h.repository.enable(
        providerId: openAi,
        apiKey: testApiKey,
        consentAcceptedAt: consentAt,
      );

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
      final settings = (await h.repository.getSettings()).toNullable()!;
      expect(settings.isEnabled, isFalse);
      expect(settings.hasStoredCredential, isFalse);
    });

    test('a failure message never contains the key', () async {
      h.store.failWrites = true;

      final result = await h.repository.enable(
        providerId: openAi,
        apiKey: testApiKey,
        consentAcceptedAt: consentAt,
      );

      final failure = result.getLeft().toNullable()!;
      expect(failure.message, isNot(contains(testApiKey)));
      expect(failure.toString(), isNot(contains(testApiKey)));
    });
  });

  group('disable (T017)', () {
    test('disables, clears consent and provider, and deletes the key from '
        'every slot', () async {
      await enable();

      final result = await h.repository.disable();

      expect(result.isRight(), isTrue);
      final settings = (await h.repository.getSettings()).toNullable()!;
      expect(settings.isEnabled, isFalse);
      expect(settings.consentAcceptedAt, isNull);
      expect(settings.hasStoredCredential, isFalse);
      expect(settings.providerId, isNull);
      expect(h.store.keys, isEmpty);
      expect(h.store.log.where((e) => e.startsWith('delete:')), [
        for (final id in SecureCredentialStoreImpl.everySlotProviderId)
          'delete:$id',
      ]);
    });

    test('keeps the conversation history (only an explicit clear removes '
        'it)', () async {
      await enable();
      await h.repository.appendMessage(
        const AIMessageDraft.userQuestion('How much on food?'),
      );

      await h.repository.disable();

      expect(await h.db.select(h.db.aiMessages).get(), hasLength(1));
    });

    test('a keychain failure rolls the whole disable back', () async {
      await enable();
      h.store.failDeletes = true;

      final result = await h.repository.disable();

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
      final settings = (await h.repository.getSettings()).toNullable()!;
      expect(settings.isEnabled, isTrue);
    });

    test('is safe on a fresh install', () async {
      final result = await h.repository.disable();

      expect(result.isRight(), isTrue);
      final settings = (await h.repository.getSettings()).toNullable()!;
      expect(settings.isEnabled, isFalse);
    });
  });

  group('updateCredentials (T017)', () {
    test('replaces the key without changing isEnabled or consent', () async {
      await enable();

      final result = await h.repository.updateCredentials(
        providerId: openAi,
        apiKey: otherTestApiKey,
      );

      final settings = result.toNullable()!;
      expect(settings.isEnabled, isTrue);
      expect(settings.consentAcceptedAt, consentAt);
      expect(h.store.keys, {openAi: otherTestApiKey});
    });

    test('switching provider discards the previous provider\'s key '
        '(FR-005)', () async {
      await enable();

      await h.repository.updateCredentials(
        providerId: anthropic,
        apiKey: otherTestApiKey,
      );

      final settings = (await h.repository.getSettings()).toNullable()!;
      expect(settings.providerId, anthropic);
      expect(settings.consentAcceptedAt, consentAt);
      expect(h.store.keys, {anthropic: otherTestApiKey});
    });

    test('rejects an empty key without touching either store', () async {
      await enable();
      h.store.log.clear();

      final result = await h.repository.updateCredentials(
        providerId: openAi,
        apiKey: '',
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(h.store.log, isEmpty);
      expect(h.store.keys, {openAi: testApiKey});
    });

    test('is refused while disabled — storing a key needs the full enable '
        'flow with consent (FR-016)', () async {
      final result = await h.repository.updateCredentials(
        providerId: openAi,
        apiKey: testApiKey,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(h.store.keys, isEmpty);
      final settings = (await h.repository.getSettings()).toNullable()!;
      expect(settings.isEnabled, isFalse);
    });
  });

  group('appendMessage (T038)', () {
    test('assigns id, conversation and timestamp, and bumps the '
        'conversation\'s lastActivityAt', () async {
      final before = DateTime.now();
      final message = (await h.repository.appendMessage(
        const AIMessageDraft.userQuestion('Who owes me money?'),
      )).toNullable()!;

      final conversation = await h.db.select(h.db.aiConversations).getSingle();
      expect(message.id, isNotEmpty);
      expect(message.conversationId, conversation.id);
      expect(message.sender, MessageSender.user);
      expect(message.status, MessageStatus.sent);
      expect(message.content, 'Who owes me money?');
      expect(
        message.createdAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
      expect(
        conversation.lastActivityAt,
        message.createdAt.millisecondsSinceEpoch,
      );
    });

    test('round-trips an assistant answer with its grounding refs, and a '
        'failed question with its reason', () async {
      const refs =
          '[{"tool":"getCategorySpend","useCase":"GetCategoryBreakdown"}]';
      await h.repository.appendMessage(
        const AIMessageDraft.failedQuestion(
          'Food this month?',
          failureReason: AIFailureReason.rateLimited,
        ),
      );
      await h.repository.appendMessage(
        const AIMessageDraft.assistantAnswer(
          'You spent 350 EGP.',
          groundingRefsJson: refs,
        ),
      );

      final messages = (await h.repository.getMessages()).toNullable()!;
      expect(messages, hasLength(2));
      expect(messages[0].status, MessageStatus.failed);
      expect(messages[0].failureReason, AIFailureReason.rateLimited);
      expect(messages[1].sender, MessageSender.assistant);
      expect(messages[1].status, MessageStatus.answered);
      expect(messages[1].groundingRefsJson, refs);
    });

    test('rejects empty content on a sent/answered message', () async {
      final user = await h.repository.appendMessage(
        const AIMessageDraft.userQuestion('   '),
      );
      final assistant = await h.repository.appendMessage(
        const AIMessageDraft.assistantAnswer(''),
      );

      expect(user.getLeft().toNullable(), isA<ValidationFailure>());
      expect(assistant.getLeft().toNullable(), isA<ValidationFailure>());
      expect(await h.db.select(h.db.aiMessages).get(), isEmpty);
    });

    test('every message lands in the one conversation, however many are '
        'appended concurrently', () async {
      await Future.wait([
        for (var i = 0; i < 10; i++)
          h.repository.appendMessage(AIMessageDraft.userQuestion('q$i')),
      ]);

      expect(await h.db.select(h.db.aiConversations).get(), hasLength(1));
      expect(await h.db.select(h.db.aiMessages).get(), hasLength(10));
    });
  });

  group('getMessages / clearConversation (T052)', () {
    Future<void> appendMany(int count) async {
      for (var i = 0; i < count; i++) {
        await h.repository.appendMessage(
          i.isEven
              ? AIMessageDraft.userQuestion('m$i')
              : AIMessageDraft.assistantAnswer('m$i'),
        );
      }
    }

    test(
      'an empty conversation is created lazily and reads as empty',
      () async {
        final messages = (await h.repository.getMessages()).toNullable()!;

        expect(messages, isEmpty);
        expect(await h.db.select(h.db.aiConversations).get(), hasLength(1));
      },
    );

    test('a page is chronological, and a question never sorts after its own '
        'answer even within the same millisecond', () async {
      await appendMany(6);

      final contents = [
        for (final m in (await h.repository.getMessages()).toNullable()!)
          m.content,
      ];
      expect(contents, ['m0', 'm1', 'm2', 'm3', 'm4', 'm5']);
    });

    test('pages walk backwards from the newest message over a large history '
        'with no gaps or duplicates', () async {
      const total = 530;
      const pageSize = 50;
      await appendMany(total);

      final loaded = <String>[];
      var offset = 0;
      while (true) {
        final page = (await h.repository.getMessages(
          limit: pageSize,
          offset: offset,
        )).toNullable()!;
        if (offset == 0) {
          expect(page.last.content, 'm${total - 1}');
        }
        // Each older page is prepended, exactly as a chat screen would.
        loaded.insertAll(0, [for (final m in page) m.content]);
        offset += page.length;
        if (page.length < pageSize) break;
      }

      expect(loaded, [for (var i = 0; i < total; i++) 'm$i']);
    });

    test('an out-of-range page is empty, and a bad limit/offset is a '
        'ValidationFailure', () async {
      await appendMany(3);

      expect(
        (await h.repository.getMessages(offset: 10)).toNullable(),
        isEmpty,
      );
      expect(
        (await h.repository.getMessages(limit: 0)).getLeft().toNullable(),
        isA<ValidationFailure>(),
      );
      expect(
        (await h.repository.getMessages(offset: -1)).getLeft().toNullable(),
        isA<ValidationFailure>(),
      );
    });

    test('clearing removes every message and leaves the settings exactly as '
        'they were', () async {
      final enabled = await enable();
      await appendMany(20);

      final result = await h.repository.clearConversation();

      expect(result.isRight(), isTrue);
      expect(await h.db.select(h.db.aiMessages).get(), isEmpty);
      expect((await h.repository.getSettings()).toNullable(), enabled);
      expect(h.store.keys, {openAi: testApiKey});
    });

    test('a message appended after clearing starts a fresh history', () async {
      await appendMany(4);
      await h.repository.clearConversation();

      await h.repository.appendMessage(
        const AIMessageDraft.userQuestion('fresh'),
      );

      final messages = (await h.repository.getMessages()).toNullable()!;
      expect([for (final m in messages) m.content], ['fresh']);
    });
  });

  group('readApiKey (014 orchestration)', () {
    test('returns the enabled provider\'s stored key', () async {
      await enable();

      expect((await h.repository.readApiKey()).toNullable(), testApiKey);
    });

    test('a disabled assistant yields ValidationFailure without touching '
        'the keychain', () async {
      h.store.log.clear();

      final result = await h.repository.readApiKey();

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(h.store.log, isEmpty);
    });

    test('enabled but no stored key → NotFoundFailure', () async {
      await enable();
      h.store.keys.clear();

      final result = await h.repository.readApiKey();

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test(
      'a keychain error is a CacheFailure that never carries the key',
      () async {
        await enable();
        h.store.onCall = (op, _) async {
          if (op == 'read') throw StateError('boom $testApiKey');
        };

        final failure = (await h.repository.readApiKey())
            .getLeft()
            .toNullable();

        expect(failure, isA<CacheFailure>());
        expect(failure!.message, isNot(contains(testApiKey)));
      },
    );
  });

  group('deleteFailedMessage (014 retry)', () {
    test('deletes a failed question', () async {
      final failed = (await h.repository.appendMessage(
        const AIMessageDraft.failedQuestion(
          'q?',
          failureReason: AIFailureReason.network,
        ),
      )).toNullable()!;

      final result = await h.repository.deleteFailedMessage(failed.id);

      expect(result.isRight(), isTrue);
      expect(await h.db.select(h.db.aiMessages).get(), isEmpty);
    });

    test('never deletes a sent or answered message', () async {
      final sent = (await h.repository.appendMessage(
        const AIMessageDraft.userQuestion('q?'),
      )).toNullable()!;

      final result = await h.repository.deleteFailedMessage(sent.id);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      expect(await h.db.select(h.db.aiMessages).get(), hasLength(1));
    });
  });

  group('last surfaced observation (T074)', () {
    test('is null until recorded, then persists across other settings '
        'writes', () async {
      await enable();
      expect((await h.repository.getLastObservationKey()).toNullable(), isNull);

      await h.repository.recordSurfacedObservation('k1');
      await h.repository.updateCredentials(
        providerId: anthropic,
        apiKey: otherTestApiKey,
      );

      expect((await h.repository.getLastObservationKey()).toNullable(), 'k1');
    });
  });

  group('purgeCredentials (T084)', () {
    test('deletes every slot and leaves the database rows untouched', () async {
      await enable();
      // The fake keychain is keyed by provider id, one per slot.
      h.store.keys[AIProviderRegistry.customPrefix] = otherTestApiKey;
      h.store.log.clear();

      final result = await h.repository.purgeCredentials();

      expect(result.isRight(), isTrue);
      expect(h.store.keys, isEmpty);
      expect(h.store.log, [
        for (final id in SecureCredentialStoreImpl.everySlotProviderId)
          'delete:$id',
      ]);
      // Only the key is forgotten here — the table wipe owns the rows.
      final settings = (await h.repository.getSettings()).toNullable()!;
      expect(settings.isEnabled, isTrue);
    });

    test('is idempotent when no key is stored', () async {
      expect((await h.repository.purgeCredentials()).isRight(), isTrue);
    });

    test('a keychain failure is a CacheFailure that never carries the '
        'key', () async {
      await enable();
      h.store.failDeletes = true;

      final result = await h.repository.purgeCredentials();

      final failure = result.getLeft().toNullable()!;
      expect(failure, isA<CacheFailure>());
      expect(failure.message, isNot(contains(testApiKey)));
    });
  });
}
