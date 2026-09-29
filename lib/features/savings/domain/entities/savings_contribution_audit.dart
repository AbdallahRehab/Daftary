import 'package:equatable/equatable.dart';

/// What happened to the audited [SavingsContributionAudit.contributionId].
enum ContributionAuditChange {
  edited('edited'),
  deleted('deleted');

  const ContributionAuditChange(this.value);

  /// The stored and wire value.
  final String value;

  /// Parses a stored [value]. Throws [ArgumentError] on an unknown value.
  static ContributionAuditChange fromValue(String value) {
    for (final change in values) {
      if (change.value == value) return change;
    }
    throw ArgumentError.value(value, 'value', 'Unknown audit change type');
  }
}

/// The prior values of one `SavingsContribution`, captured when it was
/// edited or deleted (FR-030, research.md Decision 10) — a copy of 001's
/// transaction audit trail.
///
/// Append-only: never edited, never deleted (except by the full data wipe),
/// never counted toward progress and never shown as a history entry.
class SavingsContributionAudit extends Equatable {
  const SavingsContributionAudit({
    required this.id,
    required this.contributionId,
    required this.changeType,
    required this.previousValuesJson,
    required this.changedAt,
  });

  final String id;
  final String contributionId;
  final ContributionAuditChange changeType;

  /// JSON of the row before the change: `amountMinorUnits`,
  /// `enteredAmountMinorUnits`, `enteredCurrencyCode`, `date`, `note`.
  final String previousValuesJson;
  final DateTime changedAt;

  @override
  List<Object?> get props => [
    id,
    contributionId,
    changeType,
    previousValuesJson,
    changedAt,
  ];
}
