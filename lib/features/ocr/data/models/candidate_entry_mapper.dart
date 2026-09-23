import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/candidate_entry.dart';
import '../../domain/entities/field_confidence.dart';
import 'ocr_scan_mapper.dart';

/// Maps between the `candidate_entries` row and [CandidateEntry],
/// including the `kind`/`level` column pair behind each field's
/// [FieldConfidence].
extension CandidateEntryMapper on db.CandidateEntry {
  CandidateEntry toDomain() => CandidateEntry(
    id: id,
    scanId: scanId,
    status: candidateEntryStatusFromDb(status),
    personName: personName,
    personNameConfidence: fieldConfidenceFromDb(
      personNameConfidenceKind,
      personNameConfidenceLevel,
    ),
    matchedPersonId: matchedPersonId,
    amountMinorUnits: amountMinorUnits,
    amountConfidence: fieldConfidenceFromDb(
      amountConfidenceKind,
      amountConfidenceLevel,
    ),
    direction: directionFromDbOrNull(direction),
    directionConfidence: fieldConfidenceFromDb(
      directionConfidenceKind,
      directionConfidenceLevel,
    ),
    date: date == null ? null : DateTime.fromMillisecondsSinceEpoch(date!),
    dateConfidence: fieldConfidenceFromDb(
      dateConfidenceKind,
      dateConfidenceLevel,
    ),
    notes: notes,
    rawOcrText: rawOcrText,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    editedAt: editedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(editedAt!),
  );
}

CandidateEntryStatus candidateEntryStatusFromDb(String value) =>
    switch (value) {
      'pendingReview' => CandidateEntryStatus.pendingReview,
      'confirmed' => CandidateEntryStatus.confirmed,
      'discarded' => CandidateEntryStatus.discarded,
      _ => throw StateError('Unknown candidate entry status: $value'),
    };

extension CandidateEntryStatusDb on CandidateEntryStatus {
  String get dbValue => switch (this) {
    CandidateEntryStatus.pendingReview => 'pendingReview',
    CandidateEntryStatus.confirmed => 'confirmed',
    CandidateEntryStatus.discarded => 'discarded',
  };
}

/// Rebuilds a [FieldConfidence] from its two columns through the same
/// factories the rest of the app uses, so the "an inferred field never
/// carries a level" rule survives a round-trip through the database. A row
/// written by an older build, or hand-edited, cannot reintroduce the
/// forbidden combination here: `inferred` always comes back inferred.
FieldConfidence fieldConfidenceFromDb(String kind, String level) {
  if (kind == 'inferred') return const FieldConfidence.inferred();
  if (kind != 'read') throw StateError('Unknown confidence kind: $kind');
  return switch (level) {
    'low' => FieldConfidence.read(FieldConfidenceLevel.low),
    'medium' => FieldConfidence.read(FieldConfidenceLevel.medium),
    'high' => FieldConfidence.read(FieldConfidenceLevel.high),
    'none' => const FieldConfidence.inferred(),
    _ => throw StateError('Unknown confidence level: $level'),
  };
}

extension FieldConfidenceDb on FieldConfidence {
  String get kindDbValue => switch (kind) {
    FieldConfidenceKind.read => 'read',
    FieldConfidenceKind.inferred => 'inferred',
  };

  String get levelDbValue => switch (level) {
    FieldConfidenceLevel.low => 'low',
    FieldConfidenceLevel.medium => 'medium',
    FieldConfidenceLevel.high => 'high',
    FieldConfidenceLevel.none => 'none',
  };
}
