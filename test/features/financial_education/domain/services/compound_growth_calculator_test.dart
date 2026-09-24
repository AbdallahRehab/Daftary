import 'package:daftary/features/financial_education/domain/entities/calculator_results.dart';
import 'package:daftary/features/financial_education/domain/entities/calculator_validation_result.dart';
import 'package:daftary/features/financial_education/domain/services/compound_growth_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// T009 — the release-blocking correctness anchor for SC-002.
void main() {
  const calculator = CompoundGrowthCalculatorImpl();

  CompoundGrowthResult compute({
    required int monthly,
    required double rate,
    required int years,
  }) {
    final outcome = calculator.calculate(
      monthlyContributionMinorUnits: monthly,
      annualRatePercent: rate,
      years: years,
    );
    expect(outcome.isSuccess, isTrue, reason: 'problem: ${outcome.problem}');
    return outcome.value!;
  }

  CalculatorInputProblem? problemFor({
    required int monthly,
    required double rate,
    required int years,
  }) {
    final outcome = calculator.calculate(
      monthlyContributionMinorUnits: monthly,
      annualRatePercent: rate,
      years: years,
    );
    expect(outcome.value, isNull);
    return outcome.problem;
  }

  group('reference values', () {
    test('1,000 EGP/month at 10% for 10 years', () {
      // Hand calculation (future value of an ordinary annuity, research.md
      // Decision 4):
      //   r = 10 / 100 / 12          = 0.0083333333…
      //   n = 10 × 12                = 120 months
      //   (1 + r)^n                  = 1.0083333…^120 ≈ 2.7070414909
      //   factor = ((1 + r)^n − 1)/r = 1.7070414909 / 0.0083333333
      //                              ≈ 204.84497890
      //   FV = 1,000 × 204.84497890  ≈ 204,844.9789 EGP
      //      → 20,484,497.89 piastres → rounded to 20,484,498 piastres
      //        (= 204,844.98 EGP)
      //   contributed = 1,000 × 120  = 120,000.00 EGP = 12,000,000 piastres
      //   growth      = 204,844.98 − 120,000.00 = 84,844.98 EGP
      final result = compute(monthly: 100000, rate: 10, years: 10);

      expect(result.futureValueMinorUnits, 20484498);
      expect(result.totalContributedMinorUnits, 12000000);
      expect(result.totalGrowthMinorUnits, 8484498);
      expect(result.isHighRateWarningShown, isFalse);
    });

    test('500 EGP/month at 6% for 5 years', () {
      // r = 0.005, n = 60: factor = (1.005^60 − 1)/0.005 ≈ 69.77003051
      // FV ≈ 34,885.02 EGP (3,488,501.53 piastres → 3,488,502).
      final result = compute(monthly: 50000, rate: 6, years: 5);

      expect(result.futureValueMinorUnits, 3488502);
      expect(result.totalContributedMinorUnits, 3000000);
      expect(result.totalGrowthMinorUnits, 488502);
    });

    test('1,000 EGP/month at 12% for 1 year', () {
      // r = 0.01, n = 12: factor = (1.01^12 − 1)/0.01 ≈ 12.68250301
      final result = compute(monthly: 100000, rate: 12, years: 1);

      expect(result.futureValueMinorUnits, 1268250);
      expect(result.totalContributedMinorUnits, 1200000);
      expect(result.totalGrowthMinorUnits, 68250);
    });

    test('breakdown always sums exactly to the projected total', () {
      for (final (monthly, rate, years) in <(int, double, int)>[
        (1, 0.01, 1),
        (99, 7.25, 3),
        (123456, 4.5, 17),
        (100000, 45, 40),
        (1000001, 0.5, 50),
      ]) {
        final result = compute(monthly: monthly, rate: rate, years: years);
        expect(
          result.totalContributedMinorUnits + result.totalGrowthMinorUnits,
          result.futureValueMinorUnits,
        );
        expect(result.totalContributedMinorUnits, monthly * years * 12);
        expect(result.totalGrowthMinorUnits, greaterThanOrEqualTo(0));
      }
    });

    test('is deterministic: identical inputs give identical results', () {
      final first = compute(monthly: 100000, rate: 10, years: 10);
      final second = compute(monthly: 100000, rate: 10, years: 10);
      expect(second, first);
    });

    test('a long, high-rate duration still computes (no artificial cap)', () {
      final result = compute(monthly: 100000, rate: 20, years: 50);
      expect(result.futureValueMinorUnits, greaterThan(0));
      expect(result.totalContributedMinorUnits, 60000000);
      expect(result.isHighRateWarningShown, isFalse);
    });
  });

  group('0% rate degenerate branch', () {
    test('future value equals total contributed, zero growth', () {
      final result = compute(monthly: 100000, rate: 0, years: 10);

      expect(result.futureValueMinorUnits, 12000000);
      expect(result.totalContributedMinorUnits, 12000000);
      expect(result.totalGrowthMinorUnits, 0);
      expect(result.isHighRateWarningShown, isFalse);
    });

    test('a vanishingly small rate stays continuous with the 0% branch', () {
      // 1e-7 % a year: the closed form would lose precision to
      // cancellation; the series branch keeps it at the contributed total.
      final result = compute(monthly: 100000, rate: 1e-7, years: 1);
      expect(result.futureValueMinorUnits, 1200000);
      expect(result.totalGrowthMinorUnits, 0);
    });
  });

  group('rejections (FR-008)', () {
    test('zero monthly amount', () {
      expect(
        problemFor(monthly: 0, rate: 10, years: 10),
        CalculatorInputProblem.nonPositiveAmount,
      );
    });

    test('negative monthly amount', () {
      expect(
        problemFor(monthly: -100, rate: 10, years: 10),
        CalculatorInputProblem.nonPositiveAmount,
      );
    });

    test('negative rate', () {
      expect(
        problemFor(monthly: 100000, rate: -0.01, years: 10),
        CalculatorInputProblem.negativeRate,
      );
      expect(
        problemFor(monthly: 100000, rate: -5, years: 10),
        CalculatorInputProblem.negativeRate,
      );
    });

    test('NaN rate is rejected rather than propagated', () {
      expect(
        problemFor(monthly: 100000, rate: double.nan, years: 10),
        CalculatorInputProblem.negativeRate,
      );
    });

    test('zero years', () {
      expect(
        problemFor(monthly: 100000, rate: 10, years: 0),
        CalculatorInputProblem.nonPositiveDuration,
      );
    });

    test('negative years', () {
      expect(
        problemFor(monthly: 100000, rate: 10, years: -3),
        CalculatorInputProblem.nonPositiveDuration,
      );
    });

    test('checks run in order: amount, then rate, then years', () {
      expect(
        problemFor(monthly: 0, rate: -1, years: 0),
        CalculatorInputProblem.nonPositiveAmount,
      );
      expect(
        problemFor(monthly: 1, rate: -1, years: 0),
        CalculatorInputProblem.negativeRate,
      );
    });

    test('a figure beyond exact minor-unit range is reported, not shown', () {
      expect(
        problemFor(monthly: 100000, rate: 1000, years: 100),
        CalculatorInputProblem.resultTooLarge,
      );
      expect(
        problemFor(monthly: 1 << 50, rate: 0, years: 100),
        CalculatorInputProblem.resultTooLarge,
      );
    });
  });

  group('high-rate warning threshold (FR-010)', () {
    test('29% does not show the note', () {
      final result = compute(monthly: 100000, rate: 29, years: 1);
      expect(result.isHighRateWarningShown, isFalse);
      expect(result.futureValueMinorUnits, 1373075);
    });

    test('exactly 30% does not show the note', () {
      expect(
        compute(monthly: 100000, rate: 30, years: 1).isHighRateWarningShown,
        isFalse,
      );
    });

    test('31% shows the note and still computes accurately', () {
      final result = compute(monthly: 100000, rate: 31, years: 1);
      expect(result.isHighRateWarningShown, isTrue);
      // r = 0.31/12, n = 12: FV ≈ 13,860.72 EGP.
      expect(result.futureValueMinorUnits, 1386072);
    });

    test('threshold constant is 30%', () {
      expect(CompoundGrowthCalculator.highRateWarningThresholdPercent, 30);
    });
  });
}
