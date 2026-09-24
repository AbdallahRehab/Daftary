import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/features/financial_education/domain/entities/calculator_results.dart';
import 'package:daftary/features/financial_education/domain/services/savings_rate_calculator.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_savings_rate.dart';
import 'package:daftary/features/financial_education/presentation/cubit/calculator_field_error.dart';
import 'package:daftary/features/financial_education/presentation/cubit/savings_rate_calculator_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/savings_rate_calculator_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// T041 (savings rate) — real calculator behind the real use case.
void main() {
  SavingsRateCalculatorCubit buildCubit() => SavingsRateCalculatorCubit(
    const CalculateSavingsRate(SavingsRateCalculatorImpl()),
    EgpFormatter(),
  );

  blocTest<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
    '20,000 income / 5,000 saved → 25%',
    build: buildCubit,
    act: (cubit) => cubit
      ..incomeChanged('20000')
      ..savingsAmountChanged('5000')
      ..calculate(),
    skip: 2,
    expect: () => [
      const SavingsRateCalculatorState(
        incomeInput: '20000',
        savingsAmountInput: '5000',
        result: SavingsRateResult(savingsRatePercent: 25),
      ),
    ],
  );

  blocTest<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
    '>100%: 25,000 saved of 20,000 income is ACCEPTED as 125%, not clamped',
    build: buildCubit,
    act: (cubit) => cubit
      ..incomeChanged('20,000')
      ..savingsAmountChanged('25000')
      ..calculate(),
    verify: (cubit) {
      expect(cubit.state.incomeError, isNull);
      expect(cubit.state.savingsAmountError, isNull);
      expect(cubit.state.result?.savingsRatePercent, 125);
    },
  );

  blocTest<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
    'zero savings is a valid 0%',
    build: buildCubit,
    act: (cubit) => cubit
      ..incomeChanged('20000')
      ..savingsAmountChanged('0')
      ..calculate(),
    verify: (cubit) => expect(cubit.state.result?.savingsRatePercent, 0),
  );

  blocTest<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
    'Arabic-Indic digits are accepted',
    build: buildCubit,
    act: (cubit) => cubit
      ..incomeChanged('٢٠٠٠٠')
      ..savingsAmountChanged('٥٠٠٠')
      ..calculate(),
    verify: (cubit) => expect(cubit.state.result?.savingsRatePercent, 25),
  );

  group('rejections surface as inline errors, never exceptions', () {
    blocTest<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
      'zero income',
      build: buildCubit,
      act: (cubit) => cubit
        ..incomeChanged('0')
        ..savingsAmountChanged('5000')
        ..calculate(),
      verify: (cubit) {
        expect(cubit.state.incomeError, CalculatorFieldError.mustBePositive);
        expect(cubit.state.savingsAmountError, isNull);
        expect(cubit.state.result, isNull);
      },
    );

    blocTest<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
      'negative income',
      build: buildCubit,
      act: (cubit) => cubit
        ..incomeChanged('-100')
        ..savingsAmountChanged('5000')
        ..calculate(),
      verify: (cubit) =>
          expect(cubit.state.incomeError, CalculatorFieldError.mustBePositive),
    );

    blocTest<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
      'negative savings',
      build: buildCubit,
      act: (cubit) => cubit
        ..incomeChanged('20000')
        ..savingsAmountChanged('-1')
        ..calculate(),
      verify: (cubit) {
        expect(
          cubit.state.savingsAmountError,
          CalculatorFieldError.mustNotBeNegative,
        );
        expect(cubit.state.result, isNull);
      },
    );

    blocTest<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
      'empty and unparseable fields are both reported',
      build: buildCubit,
      act: (cubit) => cubit
        ..incomeChanged('')
        ..savingsAmountChanged('lots')
        ..calculate(),
      verify: (cubit) {
        expect(cubit.state.incomeError, CalculatorFieldError.required);
        expect(
          cubit.state.savingsAmountError,
          CalculatorFieldError.invalidNumber,
        );
        expect(cubit.state.result, isNull);
      },
    );

    blocTest<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
      'editing a field clears its error and the stale result',
      build: buildCubit,
      act: (cubit) => cubit
        ..incomeChanged('0')
        ..savingsAmountChanged('')
        ..calculate()
        ..incomeChanged('100'),
      verify: (cubit) {
        expect(cubit.state.incomeError, isNull);
        expect(cubit.state.savingsAmountError, CalculatorFieldError.required);
        expect(cubit.state.incomeInput, '100');
      },
    );
  });
}
