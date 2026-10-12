import '../../../../core/confidence/field_confidence.dart';
import '../entities/parse_confidence.dart';
import '../entities/sms_import_enums.dart';

/// The overall confidence of one parse (parser-contract §6, FR-039 to
/// FR-042). Pure.
///
/// - any required field (amount, currency, direction, date) absent -> low
///   (D-C1);
/// - otherwise the lowest level among the required fields that were read;
/// - any inferred required field caps the result at medium (FR-039);
/// - [capMedium] (generic profile, paste or share; see
///   [confidenceCapsAtMedium]) caps the result at medium (FR-041, FR-020).
///
/// Optional fields never change the result. Confidence affects only
/// presentation and ordering: it never blocks Add and never adds anything
/// (FR-042).
OverallConfidence overallConfidence(
  Map<SmsField, FieldConfidence> fields, {
  required bool capMedium,
}) {
  var overall = OverallConfidence.high;
  for (final field in SmsField.required) {
    final confidence = fields[field];
    if (confidence == null) return OverallConfidence.low;
    final level = confidence.isInferred
        ? OverallConfidence.medium
        : _fromLevel(confidence.level);
    overall = _min(overall, level);
  }
  if (capMedium) overall = _min(overall, OverallConfidence.medium);
  return overall;
}

/// Whether a parse is capped at medium: the generic profile (FR-041), or a
/// paste or share, which has no trusted sender (FR-020).
bool confidenceCapsAtMedium({
  required bool isGeneric,
  required SmsSource source,
}) => isGeneric || source.capsConfidenceAtMedium;

OverallConfidence _fromLevel(FieldConfidenceLevel level) => switch (level) {
  FieldConfidenceLevel.high => OverallConfidence.high,
  FieldConfidenceLevel.medium => OverallConfidence.medium,
  // `none` is impossible for a read field (FieldConfidence.read rejects
  // it); treat it as the least trustworthy level if it ever appears.
  FieldConfidenceLevel.low ||
  FieldConfidenceLevel.none => OverallConfidence.low,
};

OverallConfidence _min(OverallConfidence a, OverallConfidence b) =>
    a.index <= b.index ? a : b;
