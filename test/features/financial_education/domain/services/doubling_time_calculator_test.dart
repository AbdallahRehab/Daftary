import 'package:daftary/features/financial_education/domain/entities/calculator_validation_result.dart';
import 'package:daftary/features/financial_education/domain/services/doubling_time_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// T011 — rule of 72 (FR-011).
void main() {
  const calculator = DoublingTimeCalculatorImpl();

  double yearsFor(double rate) {
    final outcome = calculator.calculate(annualRatePercent: rate);
    expect(outcome.isSuccess, isTrue);
    return outcome.value!.approximateDoublingYears;
  }

  group('reference values', () {
    test('8% doubles in 9 years', () => expect(yearsFor(8), 9));
    test('6% doubles in 12 years', () => expect(yearsFor(6), 12));
    test('12% doubles in 6 years', () => expect(yearsFor(12), 6));
    test('72% doubles in 1 year', () => expect(yearsFor(72), 1));
    test('7% ≈ 10.2857 years', () {
      expect(yearsFor(7), closeTo(10.2857142857, 1e-9));
    });
    test('a tiny positive rate is accepted', () {
      expect(yearsFor(0.01), closeTo(7200, 1e-9));
    });
    test('is deterministic', () {
      expect(
        calculator.calculate(annualRatePercent: 9.5),
        calculator.calculate(annualRatePercent: 9.5),
      );
    });
  });

  group('rejections', () {
    for (final rate in [0.0, -0.0, -0.01, -8.0, double.nan, double.infinity]) {
      test('rate $rate is rejected as nonPositiveRate', () {
        final outcome = calculator.calculate(annualRatePercent: rate);
        expect(outcome.value, isNull);
        expect(outcome.problem, CalculatorInputProblem.nonPositiveRate);
      });
    }
  });
}
