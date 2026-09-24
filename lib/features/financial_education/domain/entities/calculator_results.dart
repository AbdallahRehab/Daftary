import 'package:equatable/equatable.dart';

/// The outcome of one compound-growth calculation (FR-007/FR-009/FR-010).
///
/// Ephemeral: never persisted, never linked to any other entity
/// (data-model.md). Every amount is in minor units (piastres), matching the
/// rest of the app's money handling.
class CompoundGrowthResult extends Equatable {
  const CompoundGrowthResult({
    required this.futureValueMinorUnits,
    required this.totalContributedMinorUnits,
    required this.totalGrowthMinorUnits,
    required this.isHighRateWarningShown,
  });

  /// The projected total after the full duration, rounded to the nearest
  /// piastre (see `CompoundGrowthCalculator` for the rounding rule).
  final int futureValueMinorUnits;

  /// `monthlyContribution × months` — exact integer arithmetic.
  final int totalContributedMinorUnits;

  /// `futureValue − totalContributed`, so the breakdown always sums exactly
  /// to the projected total shown alongside it.
  final int totalGrowthMinorUnits;

  /// True when the entered annual rate is above the sanity-check threshold
  /// (FR-010). The result is still computed and shown in full.
  final bool isHighRateWarningShown;

  @override
  List<Object?> get props => [
    futureValueMinorUnits,
    totalContributedMinorUnits,
    totalGrowthMinorUnits,
    isHighRateWarningShown,
  ];
}

/// The outcome of one rule-of-72 doubling-time estimate (FR-011).
class DoublingTimeResult extends Equatable {
  const DoublingTimeResult({required this.approximateDoublingYears});

  /// `72 / annualRatePercent` — an approximation by definition, and labeled
  /// as such wherever it is shown.
  final double approximateDoublingYears;

  @override
  List<Object?> get props => [approximateDoublingYears];
}

/// The outcome of one effective-savings-rate calculation (FR-012).
class SavingsRateResult extends Equatable {
  const SavingsRateResult({required this.savingsRatePercent});

  /// `savings / income × 100`. Deliberately unclamped: a savings amount
  /// above the income yields a figure above 100 (FR-012/Edge Cases).
  final double savingsRatePercent;

  @override
  List<Object?> get props => [savingsRatePercent];
}
