import 'package:injectable/injectable.dart';

import '../entities/calculator_results.dart';
import '../entities/calculator_validation_result.dart';
import '../services/savings_rate_calculator.dart';

/// Thin use-case wrapper over [SavingsRateCalculator] (T042).
@injectable
class CalculateSavingsRate {
  const CalculateSavingsRate(this._calculator);

  final SavingsRateCalculator _calculator;

  CalculatorValidationResult<SavingsRateResult> call({
    required int incomeMinorUnits,
    required int savingsAmountMinorUnits,
  }) {
    return _calculator.calculate(
      incomeMinorUnits: incomeMinorUnits,
      savingsAmountMinorUnits: savingsAmountMinorUnits,
    );
  }
}
