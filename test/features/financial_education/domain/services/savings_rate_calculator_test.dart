import 'package:daftary/features/financial_education/domain/entities/calculator_validation_result.dart';
import 'package:daftary/features/financial_education/domain/services/savings_rate_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// T013 — effective savings rate (FR-012).
void main() {
  const calculator = SavingsRateCalculatorImpl();

  double rateFor({required int income, required int savings}) {
    final outcome = calculator.calculate(
      incomeMinorUnits: income,
      savingsAmountMinorUnits: savings,
    );
    expect(outcome.isSuccess, isTrue);
    return outcome.value!.savingsRatePercent;
  }

  group('reference values', () {
    test('20,000 income / 5,000 saved → 25%', () {
      expect(rateFor(income: 2000000, savings: 500000), 25);
    });

    test('zero savings → 0%', () {
      expect(rateFor(income: 2000000, savings: 0), 0);
    });

    test('savings equal to income → 100%', () {
      expect(rateFor(income: 2000000, savings: 2000000), 100);
    });

    test('non-round result is not rounded by the domain', () {
      // 1,000 / 3,000 = 33.333…%
      expect(
        rateFor(income: 300000, savings: 100000),
        closeTo(33.3333333333, 1e-9),
      );
    });

    test('works on piastre-level amounts', () {
      // 0.50 EGP of 2.00 EGP.
      expect(rateFor(income: 200, savings: 50), 25);
    });
  });

  group('>100% (FR-012/Edge Cases)', () {
    test('25,000 saved of 20,000 income → 125%, accepted and NOT clamped', () {
      final outcome = calculator.calculate(
        incomeMinorUnits: 2000000,
        savingsAmountMinorUnits: 2500000,
      );
      expect(outcome.problem, isNull);
      expect(outcome.value!.savingsRatePercent, 125);
    });
  });

  group('rejections', () {
    test('zero income', () {
      final outcome = calculator.calculate(
        incomeMinorUnits: 0,
        savingsAmountMinorUnits: 500000,
      );
      expect(outcome.value, isNull);
      expect(outcome.problem, CalculatorInputProblem.nonPositiveIncome);
    });

    test('negative income', () {
      expect(
        calculator
            .calculate(incomeMinorUnits: -1, savingsAmountMinorUnits: 0)
            .problem,
        CalculatorInputProblem.nonPositiveIncome,
      );
    });

    test('negative savings', () {
      expect(
        calculator
            .calculate(incomeMinorUnits: 2000000, savingsAmountMinorUnits: -1)
            .problem,
        CalculatorInputProblem.negativeSavings,
      );
    });

    test('income is checked before savings', () {
      expect(
        calculator
            .calculate(incomeMinorUnits: 0, savingsAmountMinorUnits: -1)
            .problem,
        CalculatorInputProblem.nonPositiveIncome,
      );
    });
  });
}
