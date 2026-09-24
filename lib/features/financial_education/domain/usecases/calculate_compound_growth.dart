import 'package:injectable/injectable.dart';

import '../entities/calculator_results.dart';
import '../entities/calculator_validation_result.dart';
import '../services/compound_growth_calculator.dart';

/// Thin use-case wrapper over [CompoundGrowthCalculator] (T032), so the
/// Presentation layer depends on a use case like everywhere else in the app.
@injectable
class CalculateCompoundGrowth {
  const CalculateCompoundGrowth(this._calculator);

  final CompoundGrowthCalculator _calculator;

  CalculatorValidationResult<CompoundGrowthResult> call({
    required int monthlyContributionMinorUnits,
    required double annualRatePercent,
    required int years,
  }) {
    return _calculator.calculate(
      monthlyContributionMinorUnits: monthlyContributionMinorUnits,
      annualRatePercent: annualRatePercent,
      years: years,
    );
  }
}
