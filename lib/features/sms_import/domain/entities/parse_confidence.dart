import 'package:equatable/equatable.dart';

import '../../../../core/confidence/field_confidence.dart';

/// The fields a parse can produce, each with its own confidence
/// (data-model §2.6).
enum SmsField {
  amount,
  currency,
  direction,
  date,
  time,
  merchant,
  counterparty,
  cardLast4,
  reference,
  kind;

  /// Required for confidence purposes (FR-043a).
  static const Set<SmsField> required = {amount, currency, direction, date};

  bool get isRequired => required.contains(this);
}

/// The overall confidence of one parsed message. Never `none`, never a
/// number or a percentage (FR-040).
enum OverallConfidence {
  low('low'),
  medium('medium'),
  high('high');

  const OverallConfidence(this.dbValue);

  final String dbValue;

  /// Unknown or null -> [low]: an unreadable confidence is never shown as
  /// trustworthy, and Low sorts first in the pending list.
  static OverallConfidence fromDb(String? value) {
    for (final level in values) {
      if (level.dbValue == value) return level;
    }
    return low;
  }
}

/// Per-field and overall confidence of one parse (parser-contract §6).
///
/// Reuses the core [FieldConfidence] model: a field is `read(level)` or
/// `inferred()`, and an inferred field always has level `none`.
class ParseConfidence extends Equatable {
  ParseConfidence({
    required Map<SmsField, FieldConfidence> fields,
    required this.overall,
  }) : fields = Map.unmodifiable(fields);

  /// One entry per extracted field; an absent key means the field is not
  /// present.
  final Map<SmsField, FieldConfidence> fields;

  /// The output of `overallConfidence(...)`.
  final OverallConfidence overall;

  /// The confidence of [field], or `null` when the field is absent.
  FieldConfidence? operator [](SmsField field) => fields[field];

  bool isInferred(SmsField field) => fields[field]?.isInferred ?? false;

  @override
  List<Object?> get props => [fields, overall];

  @override
  String toString() =>
      'ParseConfidence(overall: ${overall.name}, fields: ${fields.length})';
}
