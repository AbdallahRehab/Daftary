import 'package:daftary/features/financial_education/domain/entities/calculator_results.dart';
import 'package:daftary/features/financial_education/domain/entities/calculator_validation_result.dart';
import 'package:daftary/features/financial_education/domain/services/doubling_time_calculator.dart';
import 'package:daftary/features/financial_education/domain/services/savings_rate_calculator.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_doubling_time.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_savings_rate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDoublingTimeCalculator extends Mock
    implements DoublingTimeCalculator {}

class MockSavingsRateCalculator extends Mock implements SavingsRateCalculator {}

/// T040 — thin-wrapper correctness around the doubling-time and
/// savings-rate calculators.
void main() {
  group('CalculateDoublingTime', () {
    test('forwards the rate and returns the calculator result as-is', () {
      final calculator = MockDoublingTimeCalculator();
      const expected = CalculatorValidationResult.success(
        DoublingTimeResult(approximateDoublingYears: 9),
      );
      when(
        () => calculator.calculate(annualRatePercent: 8),
      ).thenReturn(expected);

      final result = CalculateDoublingTime(calculator)(annualRatePercent: 8);

      expect(result, same(expected));
      verify(() => calculator.calculate(annualRatePercent: 8)).called(1);
    });

    test('passes a rejection straight through', () {
      final calculator = MockDoublingTimeCalculator();
      when(() => calculator.calculate(annualRatePercent: 0)).thenReturn(
        const CalculatorValidationResult.invalid(
          CalculatorInputProblem.nonPositiveRate,
        ),
      );

      expect(
        CalculateDoublingTime(calculator)(annualRatePercent: 0).problem,
        CalculatorInputProblem.nonPositiveRate,
      );
    });

    test('matches the real calculator end to end', () {
      final useCase = CalculateDoublingTime(const DoublingTimeCalculatorImpl());
      expect(useCase(annualRatePercent: 8).value!.approximateDoublingYears, 9);
    });
  });

  group('CalculateSavingsRate', () {
    test('forwards both amounts and returns the calculator result as-is', () {
      final calculator = MockSavingsRateCalculator();
      const expected = CalculatorValidationResult.success(
        SavingsRateResult(savingsRatePercent: 25),
      );
      when(
        () => calculator.calculate(
          incomeMinorUnits: 2000000,
          savingsAmountMinorUnits: 500000,
        ),
      ).thenReturn(expected);

      final result = CalculateSavingsRate(calculator)(
        incomeMinorUnits: 2000000,
        savingsAmountMinorUnits: 500000,
      );

      expect(result, same(expected));
      verify(
        () => calculator.calculate(
          incomeMinorUnits: 2000000,
          savingsAmountMinorUnits: 500000,
        ),
      ).called(1);
    });

    test('passes a rejection straight through', () {
      final calculator = MockSavingsRateCalculator();
      when(
        () => calculator.calculate(
          incomeMinorUnits: 0,
          savingsAmountMinorUnits: 1,
        ),
      ).thenReturn(
        const CalculatorValidationResult.invalid(
          CalculatorInputProblem.nonPositiveIncome,
        ),
      );

      expect(
        CalculateSavingsRate(calculator)(
          incomeMinorUnits: 0,
          savingsAmountMinorUnits: 1,
        ).problem,
        CalculatorInputProblem.nonPositiveIncome,
      );
    });

    test('matches the real calculator end to end, >100% unclamped', () {
      final useCase = CalculateSavingsRate(const SavingsRateCalculatorImpl());
      expect(
        useCase(
          incomeMinorUnits: 2000000,
          savingsAmountMinorUnits: 2500000,
        ).value!.savingsRatePercent,
        125,
      );
    });
  });
}
