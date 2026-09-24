import 'dart:math' as math;

import 'package:injectable/injectable.dart';

import '../entities/calculator_results.dart';
import '../entities/calculator_validation_result.dart';

/// Pure future-value-of-an-annuity calculator (FR-007..FR-010).
///
/// No I/O and no repository dependency of any kind (research.md
/// Decision 3): every input arrives as a plain argument the user typed.
abstract class CompoundGrowthCalculator {
  /// Annual rates strictly above this (in percent) set
  /// [CompoundGrowthResult.isHighRateWarningShown] (FR-010, spec.md
  /// Assumptions). Exactly 30% does not trigger the note.
  static const double highRateWarningThresholdPercent = 30;

  /// Computes the projected total, total contributed and total growth for a
  /// fixed [monthlyContributionMinorUnits] paid at the end of each month for
  /// [years] years, compounded monthly at [annualRatePercent] / 12.
  ///
  /// Rejects (never throws) `monthlyContributionMinorUnits <= 0`,
  /// `annualRatePercent < 0` (zero is valid) and `years <= 0`, checked in
  /// that order.
  CalculatorValidationResult<CompoundGrowthResult> calculate({
    required int monthlyContributionMinorUnits,
    required double annualRatePercent,
    required int years,
  });
}

/// research.md Decision 4:
///
/// ```text
/// monthlyRate  = annualRatePercent / 100 / 12
/// months       = years × 12
/// futureValue  = monthly × (((1 + monthlyRate)^months − 1) / monthlyRate)
/// contributed  = monthly × months
/// growth       = futureValue − contributed
/// ```
///
/// **Rounding.** `contributed` is exact integer arithmetic. `futureValue`
/// is evaluated in `double` and rounded ONCE, at the very end, to the
/// nearest piastre with ties away from zero (`double.round()`; the value is
/// always positive, so ties round up). `growth` is then derived by integer
/// subtraction, so `contributed + growth == futureValue` holds exactly and
/// the displayed breakdown always adds up. The same inputs always produce
/// the same output (pure, deterministic).
///
/// **0% rate.** `monthlyRate == 0` is handled as an explicit branch
/// (`futureValue = contributed`), avoiding the division by zero.
/// For a very small positive rate (`months × monthlyRate < 1e-6`) the
/// closed form suffers catastrophic cancellation in `(1 + r)^n − 1`, so the
/// second-order series `n × (1 + (n − 1) × r / 2)` is used instead — it
/// agrees with the exact factor to within ~1e-12 relative error there.
@LazySingleton(as: CompoundGrowthCalculator)
class CompoundGrowthCalculatorImpl implements CompoundGrowthCalculator {
  const CompoundGrowthCalculatorImpl();

  /// 2^53: the largest magnitude below which every integer is exactly
  /// representable as a `double`. Results above it are reported as
  /// [CalculatorInputProblem.resultTooLarge] rather than shown imprecisely.
  static const double _maxExactMinorUnits = 9007199254740992;

  @override
  CalculatorValidationResult<CompoundGrowthResult> calculate({
    required int monthlyContributionMinorUnits,
    required double annualRatePercent,
    required int years,
  }) {
    if (monthlyContributionMinorUnits <= 0) {
      return const CalculatorValidationResult.invalid(
        CalculatorInputProblem.nonPositiveAmount,
      );
    }
    // `!(x >= 0)` also rejects NaN.
    if (!(annualRatePercent >= 0)) {
      return const CalculatorValidationResult.invalid(
        CalculatorInputProblem.negativeRate,
      );
    }
    if (years <= 0) {
      return const CalculatorValidationResult.invalid(
        CalculatorInputProblem.nonPositiveDuration,
      );
    }

    // Guard the integer arithmetic below against overflow before doing it.
    final monthsAsDouble = years.toDouble() * 12;
    if (monthsAsDouble * monthlyContributionMinorUnits > _maxExactMinorUnits) {
      return const CalculatorValidationResult.invalid(
        CalculatorInputProblem.resultTooLarge,
      );
    }

    final months = years * 12;
    final totalContributed = monthlyContributionMinorUnits * months;
    final monthlyRate = annualRatePercent / 100 / 12;

    final int futureValue;
    if (monthlyRate == 0) {
      futureValue = totalContributed;
    } else {
      final factor = _annuityFactor(monthlyRate, months);
      final raw = monthlyContributionMinorUnits * factor;
      if (!raw.isFinite || raw > _maxExactMinorUnits) {
        return const CalculatorValidationResult.invalid(
          CalculatorInputProblem.resultTooLarge,
        );
      }
      futureValue = raw.round();
    }

    return CalculatorValidationResult.success(
      CompoundGrowthResult(
        futureValueMinorUnits: futureValue,
        totalContributedMinorUnits: totalContributed,
        totalGrowthMinorUnits: futureValue - totalContributed,
        isHighRateWarningShown:
            annualRatePercent >
            CompoundGrowthCalculator.highRateWarningThresholdPercent,
      ),
    );
  }

  /// `((1 + r)^n − 1) / r`, the future value of 1 paid each period.
  static double _annuityFactor(double r, int n) {
    if (n * r < 1e-6) {
      return n * (1 + (n - 1) * r / 2);
    }
    return (math.pow(1 + r, n) - 1) / r;
  }
}
