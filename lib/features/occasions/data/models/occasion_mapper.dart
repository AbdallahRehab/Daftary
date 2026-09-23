import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/occasion.dart' as domain;
import '../../domain/entities/occasion_attachment.dart' as domain;

/// Maps `drift` rows to the occasions domain entities. Every timestamp is
/// stored as epoch millis, so this is the single place that conversion
/// happens — the domain never sees an `int` date.
extension OccasionMapper on db.Occasion {
  domain.Occasion toDomain() => domain.Occasion(
    id: id,
    idempotencyKey: idempotencyKey,
    name: name,
    date: DateTime.fromMillisecondsSinceEpoch(date),
    type: type,
    notes: notes,
    isArchived: isArchived,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    deletedAt: deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deletedAt!),
  );
}

extension OccasionAttachmentMapper on db.OccasionAttachment {
  domain.OccasionAttachment toDomain() => domain.OccasionAttachment(
    id: id,
    occasionId: occasionId,
    filePath: filePath,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    deletedAt: deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deletedAt!),
  );
}

/// An occasion's `date` is day-granular: two occasions on the same day must
/// compare and filter as the same date regardless of what time of day the
/// user happened to enter them (FR-015's date-range filter depends on it).
int occasionDateOnlyMillis(DateTime date) =>
    DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
