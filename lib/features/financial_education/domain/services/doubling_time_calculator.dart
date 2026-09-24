import 'package:injectable/injectable.dart';

import '../entities/calculator_results.dart';
import '../entities/calculator_validation_result.dart';

/// Pure rule-of-72 doubling-time estimate (FR-011). No I/O, no repository
/// dependency (research.md Decision 3).
abstract class DoublingTimeCalculator {
  /// `72 / annualRatePercent`. Rejects `annualRatePercent <= 0` with
  /// [CalculatorInputProblem.nonPositiveRate] — a doubling time is
  /// undefined at 0% and meaningless below it.
  CalculatorValidationResult<DoublingTimeResult> calculate({
    required double annualRatePercent,
  });
}

/// The result is an unrounded `double`; rounding for display (to one
/// decimal place) is a Presentation concern.
@LazySingleton(as: DoublingTimeCalculator)
class DoublingTimeCalculatorImpl implements DoublingTimeCalculator {
  const DoublingTimeCalculatorImpl();

  static const double _ruleOf72 = 72;

  @override
  CalculatorValidationResult<DoublingTimeResult> calculate({
    required double annualRatePercent,
  }) {
    // `!(x > 0)` also rejects NaN.
    if (!(annualRatePercent > 0) || !annualRatePercent.isFinite) {
      return const CalculatorValidationResult.invalid(
        CalculatorInputProblem.nonPositiveRate,
      );
    }
    return CalculatorValidationResult.success(
      DoublingTimeResult(
        approximateDoublingYears: _ruleOf72 / annualRatePercent,
      ),
    );
  }
}
