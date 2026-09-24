import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ai_assistant_settings.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/entities/ai_api_key_rules.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../domain/services/secure_credential_store.dart';
import '../datasources/ai_assistant_dao.dart';
import '../datasources/secure_credential_store_impl.dart';
import '../models/ai_message_mapper.dart';
import '../models/ai_settings_mapper.dart';
import '../services/ai_provider_registry.dart';

/// Persists the assistant's settings/conversation in drift and its API key
/// in [SecureCredentialStore] (research.md Decision 3).
///
/// Atomicity across the two stores: every settings change runs inside one
/// drift transaction with the secure-storage write/delete as its last
/// step, so a keychain failure rolls the settings row back and a DB
/// failure never leaves an "enabled" row without its key.
///
/// Key hygiene: the key only ever flows *into* this class. It is never
/// returned, never logged, and never interpolated into a [Failure] message
/// (failure messages carry only the exception's type, never its text).
@LazySingleton(as: AIAssistantRepository)
class AIAssistantRepositoryImpl implements AIAssistantRepository {
  AIAssistantRepositoryImpl(this._dao, this._credentials);

  final AIAssistantDao _dao;
  final SecureCredentialStore _credentials;
  static const _uuid = Uuid();

  // --------------------------------------------------------------- settings

  @override
  Future<Either<Failure, AIAssistantSettings>> getSettings() async {
    try {
      final row = await _dao.getSettings();
      if (row == null) {
        // Fresh install: the default, disabled singleton (FR-001). Not
        // written here — a read never has a side effect.
        return Right(
          AIAssistantSettings.disabled(
            updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      }
      return Right(row.toDomain());
    } catch (e) {
      return Left(_cache('load the AI assistant settings', e));
    }
  }

  @override
  Future<Either<Failure, AIAssistantSettings>> enable({
    required String providerId,
    required String apiKey,
    required DateTime consentAcceptedAt,
  }) async {
    final invalid = _validateCredentials(providerId, apiKey);
    if (invalid != null) return Left(invalid);

    var keyWritten = false;
    try {
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      await _dao.transaction(() async {
        await _dao.upsertSettings(
          isEnabled: true,
          providerId: providerId,
          hasStoredCredential: true,
          consentAcceptedAt: consentAcceptedAt.millisecondsSinceEpoch,
          updatedAt: nowMillis,
        );
        // data-model.md: the conversation is created lazily on first
        // enable (and again, if ever missing, on first message).
        await _dao.getOrCreateConversation(
          newId: _uuid.v4(),
          nowMillis: nowMillis,
        );
        // Last, so any DB failure above rolls back before the key exists.
        await _credentials.write(providerId, AIApiKeyRules.normalize(apiKey));
        keyWritten = true;
      });
      return Right((await _dao.getSettings())!.toDomain());
    } catch (e) {
      // The only way to get here with the key written is a failed commit:
      // don't leave a key behind for a row that never became enabled.
      if (keyWritten) await _bestEffortDelete(providerId);
      return Left(_cache('enable the AI assistant', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> disable() async {
    try {
      await _dao.transaction(() async {
        // Flip the row first: from this write on, nothing can read an
        // enabled assistant, even while the key deletion is in progress.
        await _dao.upsertSettings(
          isEnabled: false,
          providerId: null,
          hasStoredCredential: false,
          consentAcceptedAt: null,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        // Every slot, not just the current provider's, so no key can stay
        // resident after a disable (FR-014/FR-016). A keychain failure
        // throws and rolls the row back — never a partial disable.
        for (final id in SecureCredentialStoreImpl.everySlotProviderId) {
          await _credentials.delete(id);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(_cache('disable the AI assistant', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> purgeCredentials() async {
    try {
      for (final id in SecureCredentialStoreImpl.everySlotProviderId) {
        await _credentials.delete(id);
      }
      return const Right(unit);
    } catch (e) {
      return Left(_cache('delete the stored AI credentials', e));
    }
  }

  @override
  Future<Either<Failure, AIAssistantSettings>> updateCredentials({
    required String providerId,
    required String apiKey,
  }) async {
    final invalid = _validateCredentials(providerId, apiKey);
    if (invalid != null) return Left(invalid);

    var newKeyWritten = false;
    String? previousProviderId;
    try {
      final row = await _dao.getSettings();
      final current = row?.toDomain();
      // Replacing a key is only meaningful for an enabled assistant; a
      // disabled one must go through the full enable flow (key + consent)
      // again (FR-016), so this is not a back door to storing a key.
      if (row == null || current == null || !current.isEnabled) {
        return const Left(
          ValidationFailure(
            'The AI assistant must be enabled before its provider '
            'credentials can be updated',
          ),
        );
      }
      previousProviderId = current.providerId;
      await _dao.transaction(() async {
        await _dao.upsertSettings(
          isEnabled: true,
          providerId: providerId,
          hasStoredCredential: true,
          consentAcceptedAt: row.consentAcceptedAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _credentials.write(providerId, AIApiKeyRules.normalize(apiKey));
        newKeyWritten = true;
        // FR-005: the previous key is fully discarded once replaced. Same
        // slot → the write above already overwrote it.
        final previous = previousProviderId;
        if (previous != null &&
            SecureCredentialStoreImpl.credentialSlot(previous) !=
                SecureCredentialStoreImpl.credentialSlot(providerId)) {
          await _credentials.delete(previous);
        }
      });
      return Right((await _dao.getSettings())!.toDomain());
    } catch (e) {
      final previous = previousProviderId;
      if (newKeyWritten &&
          previous != null &&
          SecureCredentialStoreImpl.credentialSlot(previous) !=
              SecureCredentialStoreImpl.credentialSlot(providerId)) {
        await _bestEffortDelete(providerId);
      }
      return Left(_cache('update the AI provider credentials', e));
    }
  }

  // ----------------------------------------------------------- conversation

  @override
  Future<Either<Failure, List<AIMessage>>> getMessages({
    int limit = 50,
    int offset = 0,
  }) async {
    if (limit <= 0 || offset < 0) {
      return const Left(
        ValidationFailure('limit must be positive and offset non-negative'),
      );
    }
    try {
      final rows = await _dao.transaction(() async {
        final conversation = await _dao.getOrCreateConversation(
          newId: _uuid.v4(),
          nowMillis: DateTime.now().millisecondsSinceEpoch,
        );
        return _dao.getMessagesPage(
          conversationId: conversation.id,
          limit: limit,
          offset: offset,
        );
      });
      return Right([for (final row in rows) row.toDomain()]);
    } catch (e) {
      return Left(_cache('load the conversation', e));
    }
  }

  @override
  Future<Either<Failure, AIMessage>> appendMessage(AIMessageDraft draft) async {
    if (draft.status != MessageStatus.failed && draft.content.trim().isEmpty) {
      return const Left(ValidationFailure('A message must not be empty'));
    }
    try {
      final id = _uuid.v4();
      await _dao.transaction(() async {
        final nowMillis = DateTime.now().millisecondsSinceEpoch;
        final conversation = await _dao.getOrCreateConversation(
          newId: _uuid.v4(),
          nowMillis: nowMillis,
        );
        await _dao.insertMessage(
          draft.toCompanion(
            id: id,
            conversationId: conversation.id,
            createdAtMillis: nowMillis,
          ),
        );
        await _dao.touchConversation(conversation.id, nowMillis);
      });
      return Right((await _dao.getMessageById(id))!.toDomain());
    } catch (e) {
      return Left(_cache('save the message', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearConversation() async {
    try {
      await _dao.deleteAllMessages();
      return const Right(unit);
    } catch (e) {
      return Left(_cache('clear the conversation', e));
    }
  }

  @override
  Future<Either<Failure, String>> readApiKey() async {
    try {
      final settings = (await _dao.getSettings())?.toDomain();
      final providerId = settings?.providerId;
      if (settings == null || !settings.isEnabled || providerId == null) {
        return const Left(ValidationFailure('The AI assistant is not enabled'));
      }
      final key = await _credentials.read(providerId);
      if (key == null || key.trim().isEmpty) {
        return const Left(NotFoundFailure('No AI provider API key is stored'));
      }
      return Right(key);
    } catch (e) {
      return Left(_cache('read the AI provider API key', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteFailedMessage(String messageId) async {
    try {
      final deleted = await _dao.deleteMessageWithStatus(
        messageId,
        MessageStatus.failed.dbValue,
      );
      if (deleted == 0) {
        return const Left(NotFoundFailure('No failed message with that id'));
      }
      return const Right(unit);
    } catch (e) {
      return Left(_cache('delete the failed message', e));
    }
  }

  @override
  Future<Either<Failure, String?>> getLastObservationKey() async {
    try {
      return Right((await _dao.getSettings())?.lastObservationKey);
    } catch (e) {
      return Left(_cache('load the last surfaced observation', e));
    }
  }

  @override
  Future<Either<Failure, Unit>> recordSurfacedObservation(
    String observationKey,
  ) async {
    try {
      await _dao.setLastObservationKey(observationKey);
      return const Right(unit);
    } catch (e) {
      return Left(_cache('record the surfaced observation', e));
    }
  }

  // ---------------------------------------------------------------- helpers

  /// Shape-only checks shared by [enable] and [updateCredentials]; runs
  /// before either store is touched.
  ValidationFailure? _validateCredentials(String providerId, String apiKey) {
    if (AIProviderRegistry.resolve(providerId) == null) {
      return const ValidationFailure('Unrecognized AI provider');
    }
    if (AIApiKeyRules.isMalformed(apiKey)) {
      return const ValidationFailure('The API key is empty or malformed');
    }
    return null;
  }

  Future<void> _bestEffortDelete(String providerId) async {
    try {
      await _credentials.delete(providerId);
    } catch (_) {
      // Nothing more can be done here; the original failure is reported.
    }
  }

  /// Only the exception's *type* is kept: its text could, in principle,
  /// echo a value passed to the platform channel — and the key is one.
  CacheFailure _cache(String action, Object error) =>
      CacheFailure('Failed to $action (${error.runtimeType})');
}
