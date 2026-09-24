import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/ai_assistant_settings.dart';

/// Direct `drift` access to this feature's three tables — `ai_settings`,
/// `ai_conversations`, `ai_messages` — and nothing else. No other feature's
/// table is ever read or written here (FR-023): financial figures reach the
/// assistant only through other features' own use cases.
///
/// Data export / full deletion integration point (T058, FR-013): these
/// three tables are the complete persisted footprint of the assistant, and
/// they follow the app's existing per-table wipe pattern —
/// `AppDatabase.deleteAllUserData()` (`core/database/data_wipe.dart`)
/// already deletes `ai_messages` → `ai_conversations` → `ai_settings` in
/// child-before-parent order inside its single transaction, and the
/// roadmap's future data-export feature (§V1.5.3, not yet specced) can
/// export them as plain rows with no coupling to this DAO. Deliberately
/// excluded from both: the provider API key, which lives only in secure
/// storage (`SecureCredentialStoreImpl`), never in these tables, and is
/// never exportable. `data_wipe.dart` therefore does NOT remove the
/// secure-stored key; the full-deletion flow (013 `DeleteAllUserData`)
/// forgets it separately through `PurgeAIAssistantCredentials`.
@injectable
class AIAssistantDao {
  AIAssistantDao(this._db);

  final db.AppDatabase _db;

  /// Runs [action] in one DB transaction — what keeps a settings change and
  /// its secure-storage write/delete from leaving a half-applied state, and
  /// a message insert from diverging from its conversation's
  /// `lastActivityAt`.
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // --------------------------------------------------------------- settings

  /// The singleton settings row, or `null` before anything was ever saved
  /// (the repository treats that as the default disabled settings).
  Future<db.AiSettingsRow?> getSettings() =>
      (_db.select(_db.aiSettings)
            ..where((t) => t.id.equals(AIAssistantSettings.singletonId)))
          .getSingleOrNull();

  /// Writes the whole singleton row (insert or replace). Callers always
  /// pass every column, so no stale field from an earlier state survives
  /// (e.g. a disable really clears `consentAcceptedAt`).
  Future<void> upsertSettings({
    required bool isEnabled,
    required String? providerId,
    required bool hasStoredCredential,
    required int? consentAcceptedAt,
    required int updatedAt,
  }) => _db
      .into(_db.aiSettings)
      .insertOnConflictUpdate(
        db.AiSettingsCompanion.insert(
          id: AIAssistantSettings.singletonId,
          isEnabled: db.Value(isEnabled),
          providerId: db.Value(providerId),
          hasStoredCredential: db.Value(hasStoredCredential),
          consentAcceptedAt: db.Value(consentAcceptedAt),
          updatedAt: updatedAt,
        ),
      );

  /// Records [key] as the last surfaced proactive observation on the
  /// singleton row. A no-op when the row does not exist yet (nothing can
  /// have been surfaced by a never-configured assistant). Leaves every
  /// other column untouched.
  Future<void> setLastObservationKey(String key) =>
      (_db.update(_db.aiSettings)
            ..where((t) => t.id.equals(AIAssistantSettings.singletonId)))
          .write(db.AiSettingsCompanion(lastObservationKey: db.Value(key)));

  // ----------------------------------------------------------- conversation

  /// The single conversation, or `null` when none was created yet. Ordered
  /// so that even a (never expected) second row resolves deterministically
  /// to the oldest.
  Future<db.AiConversationRow?> getConversation() =>
      (_db.select(_db.aiConversations)
            ..orderBy([(c) => db.OrderingTerm.asc(c.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  /// The single conversation, creating it under [newId] at [nowMillis]
  /// when none exists yet (data-model.md: created lazily, never
  /// user-creatable). Run inside [transaction] by callers that also write
  /// a message, so two racing first writes cannot create two rows.
  Future<db.AiConversationRow> getOrCreateConversation({
    required String newId,
    required int nowMillis,
  }) async {
    final existing = await getConversation();
    if (existing != null) return existing;
    final row = db.AiConversationRow(
      id: newId,
      createdAt: nowMillis,
      lastActivityAt: nowMillis,
    );
    await _db.into(_db.aiConversations).insert(row);
    return row;
  }

  Future<void> touchConversation(String id, int nowMillis) =>
      (_db.update(_db.aiConversations)..where((c) => c.id.equals(id))).write(
        db.AiConversationsCompanion(lastActivityAt: db.Value(nowMillis)),
      );

  // --------------------------------------------------------------- messages

  Future<void> insertMessage(db.AiMessagesCompanion companion) =>
      _db.into(_db.aiMessages).insert(companion);

  Future<db.AiMessageRow?> getMessageById(String id) => (_db.select(
    _db.aiMessages,
  )..where((m) => m.id.equals(id))).getSingleOrNull();

  /// One page of [conversationId]'s messages, returned oldest → newest.
  ///
  /// Paging runs backwards from the newest message, the way a chat screen
  /// loads: `offset: 0` is the latest [limit] messages, `offset: limit` the
  /// page before that, and so on. Ties on `created_at` (two writes in the
  /// same millisecond) are broken by insertion order via `rowid`, so a
  /// question can never sort after its own answer. Served by
  /// `idx_ai_messages_conversation_created`.
  Future<List<db.AiMessageRow>> getMessagesPage({
    required String conversationId,
    required int limit,
    required int offset,
  }) async {
    final newestFirst =
        await (_db.select(_db.aiMessages)
              ..where((m) => m.conversationId.equals(conversationId))
              ..orderBy([
                (m) => db.OrderingTerm.desc(m.createdAt),
                (m) => db.OrderingTerm.desc(_db.aiMessages.rowId),
              ])
              ..limit(limit, offset: offset))
            .get();
    return newestFirst.reversed.toList(growable: false);
  }

  /// Deletes message [id] only when its status is [failedStatus]; returns
  /// the number of rows deleted (0 or 1).
  Future<int> deleteMessageWithStatus(String id, String failedStatus) =>
      (_db.delete(
        _db.aiMessages,
      )..where((m) => m.id.equals(id) & m.status.equals(failedStatus))).go();

  /// Permanently deletes every message (FR-012). The conversation row and
  /// the settings row are left in place.
  Future<int> deleteAllMessages() => _db.delete(_db.aiMessages).go();
}
