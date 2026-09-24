import 'package:daftary/features/financial_education/domain/entities/calculator_results.dart';
import 'package:daftary/features/financial_education/domain/entities/calculator_validation_result.dart';
import 'package:daftary/features/financial_education/domain/services/compound_growth_calculator.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_compound_growth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCompoundGrowthCalculator extends Mock
    implements CompoundGrowthCalculator {}

/// T029 — thin-wrapper correctness around `CompoundGrowthCalculator`.
void main() {
  late MockCompoundGrowthCalculator calculator;
  late CalculateCompoundGrowth useCase;

  setUp(() {
    calculator = MockCompoundGrowthCalculator();
    useCase = CalculateCompoundGrowth(calculator);
  });

  test('forwards every argument unchanged and returns the result as-is', () {
    const expected = CalculatorValidationResult.success(
      CompoundGrowthResult(
        futureValueMinorUnits: 3,
        totalContributedMinorUnits: 2,
        totalGrowthMinorUnits: 1,
        isHighRateWarningShown: true,
      ),
    );
    when(
      () => calculator.calculate(
        monthlyContributionMinorUnits: 100000,
        annualRatePercent: 7.5,
        years: 12,
      ),
    ).thenReturn(expected);

    final result = useCase(
      monthlyContributionMinorUnits: 100000,
      annualRatePercent: 7.5,
      years: 12,
    );

    expect(result, same(expected));
    verify(
      () => calculator.calculate(
        monthlyContributionMinorUnits: 100000,
        annualRatePercent: 7.5,
        years: 12,
      ),
    ).called(1);
  });

  test('passes a validation problem straight through', () {
    when(
      () => calculator.calculate(
        monthlyContributionMinorUnits: 0,
        annualRatePercent: 5,
        years: 1,
      ),
    ).thenReturn(
      const CalculatorValidationResult.invalid(
        CalculatorInputProblem.nonPositiveAmount,
      ),
    );

    final result = useCase(
      monthlyContributionMinorUnits: 0,
      annualRatePercent: 5,
      years: 1,
    );

    expect(result.problem, CalculatorInputProblem.nonPositiveAmount);
  });

  test('matches the real calculator end to end', () {
    final real = CalculateCompoundGrowth(const CompoundGrowthCalculatorImpl());
    expect(
      real(
        monthlyContributionMinorUnits: 100000,
        annualRatePercent: 10,
        years: 10,
      ).value!.futureValueMinorUnits,
      20484498,
    );
  });
}
