import 'package:equatable/equatable.dart';

/// What happened to the audited [FinanceEntryAudit.financeEntryId]
/// (022 D2). One value per create, edit, delete and restore.
enum FinanceAuditChange {
  created('created'),
  edited('edited'),
  deleted('deleted'),
  restored('restored');

  const FinanceAuditChange(this.value);

  /// The stored and wire value.
  final String value;

  /// Parses a stored [value]. Throws [ArgumentError] on an unknown value.
  static FinanceAuditChange fromValue(String value) {
    for (final change in values) {
      if (change.value == value) return change;
    }
    throw ArgumentError.value(value, 'value', 'Unknown audit change type');
  }
}

/// One append-only row in an income or expense entry's change history,
/// written in the same transaction as the change (constitution Financial
/// Domain Override). Never edited, never deleted except by the full data
/// wipe, and never counted in any total.
class FinanceEntryAudit extends Equatable {
  const FinanceEntryAudit({
    required this.id,
    required this.financeEntryId,
    required this.changeType,
    required this.changedAt,
    this.previousValuesJson,
  });

  final String id;
  final String financeEntryId;
  final FinanceAuditChange changeType;

  /// JSON of the entry before an edit: `amountMinorUnits`, `currencyCode`,
  /// `type`, `categoryId`, `date`, `note` (RF-08: the type and category
  /// make a switch between income and expense traceable). Null for every
  /// other change type.
  final String? previousValuesJson;
  final DateTime changedAt;

  @override
  List<Object?> get props => [
    id,
    financeEntryId,
    changeType,
    previousValuesJson,
    changedAt,
  ];
}
