import 'package:equatable/equatable.dart';

/// The outcome of a "what if" exploration (FR-013/FR-014). Ephemeral: it is
/// never written anywhere, and only `ApplyWhatIfScenario` can turn it into
/// a change to the goal (FR-015).
///
/// One of the two hypothetical fields is the user's input and the other is
/// the calculated answer:
/// - "what if I save X per month": [hypotheticalMonthlyContributionMinorUnits]
///   is X, [hypotheticalTargetDate] is when the goal would be reached;
/// - "what do I need to finish by Y": [hypotheticalTargetDate] is Y,
///   [hypotheticalMonthlyContributionMinorUnits] is the required amount.
class WhatIfResult extends Equatable {
  const WhatIfResult({
    this.hypotheticalMonthlyContributionMinorUnits,
    this.hypotheticalTargetDate,
    this.estimatedMonths,
  });

  final int? hypotheticalMonthlyContributionMinorUnits;
  final DateTime? hypotheticalTargetDate;

  /// Months to reach the goal under the hypothetical plan, by the same
  /// formula as `EstimatedCompletion.estimatedMonths`.
  final int? estimatedMonths;

  @override
  List<Object?> get props => [
    hypotheticalMonthlyContributionMinorUnits,
    hypotheticalTargetDate,
    estimatedMonths,
  ];
}
