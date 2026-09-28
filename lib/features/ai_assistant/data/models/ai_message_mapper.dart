import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/ai_conversation.dart';
import '../../domain/entities/ai_message.dart';

/// Maps `ai_messages` rows to [AIMessage]. Enum columns go through the
/// entity's own strict parsers, so a corrupt value throws (and the
/// repository reports a `CacheFailure`) rather than silently changing a
/// message's author or status.
extension AIMessageMapper on db.AiMessageRow {
  AIMessage toDomain() => AIMessage(
    id: id,
    conversationId: conversationId,
    sender: messageSenderFromDb(sender),
    content: content,
    status: messageStatusFromDb(status),
    failureReason: failureReason == null
        ? null
        : aiFailureReasonFromDb(failureReason!),
    groundingRefsJson: groundingRefsJson,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
  );
}

/// Builds the insert companion for [draft] once the repository has
/// assigned its [id], [conversationId] and [createdAtMillis].
extension AIMessageDraftMapper on AIMessageDraft {
  db.AiMessagesCompanion toCompanion({
    required String id,
    required String conversationId,
    required int createdAtMillis,
  }) => db.AiMessagesCompanion.insert(
    id: id,
    conversationId: conversationId,
    sender: sender.dbValue,
    content: content,
    status: status.dbValue,
    failureReason: db.Value(failureReason?.dbValue),
    groundingRefsJson: db.Value(groundingRefsJson),
    createdAt: createdAtMillis,
  );
}

extension AIConversationMapper on db.AiConversationRow {
  AIConversation toDomain() => AIConversation(
    id: id,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    lastActivityAt: DateTime.fromMillisecondsSinceEpoch(lastActivityAt),
  );
}
