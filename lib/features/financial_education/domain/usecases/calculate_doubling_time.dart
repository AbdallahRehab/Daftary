import 'package:injectable/injectable.dart';

import '../entities/calculator_results.dart';
import '../entities/calculator_validation_result.dart';
import '../services/doubling_time_calculator.dart';

/// Thin use-case wrapper over [DoublingTimeCalculator] (T042).
@injectable
class CalculateDoublingTime {
  const CalculateDoublingTime(this._calculator);

  final DoublingTimeCalculator _calculator;

  CalculatorValidationResult<DoublingTimeResult> call({
    required double annualRatePercent,
  }) {
    return _calculator.calculate(annualRatePercent: annualRatePercent);
  }
}
