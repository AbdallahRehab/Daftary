import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/features/financial_education/domain/entities/calculator_results.dart';
import 'package:daftary/features/financial_education/domain/services/doubling_time_calculator.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_doubling_time.dart';
import 'package:daftary/features/financial_education/presentation/cubit/calculator_field_error.dart';
import 'package:daftary/features/financial_education/presentation/cubit/doubling_time_calculator_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/doubling_time_calculator_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// T041 (doubling time) — real calculator behind the real use case.
void main() {
  DoublingTimeCalculatorCubit buildCubit() => DoublingTimeCalculatorCubit(
    const CalculateDoublingTime(DoublingTimeCalculatorImpl()),
    EgpFormatter(),
  );

  blocTest<DoublingTimeCalculatorCubit, DoublingTimeCalculatorState>(
    '8% → 9 years',
    build: buildCubit,
    act: (cubit) => cubit
      ..annualRateChanged('8')
      ..calculate(),
    expect: () => [
      const DoublingTimeCalculatorState(annualRateInput: '8'),
      const DoublingTimeCalculatorState(
        annualRateInput: '8',
        result: DoublingTimeResult(approximateDoublingYears: 9),
      ),
    ],
  );

  blocTest<DoublingTimeCalculatorCubit, DoublingTimeCalculatorState>(
    'accepts Arabic-Indic digits, a decimal separator and a % sign',
    build: buildCubit,
    act: (cubit) => cubit
      ..annualRateChanged('٧٫٢ %')
      ..calculate(),
    verify: (cubit) =>
        expect(cubit.state.result?.approximateDoublingYears, closeTo(10, 1e-9)),
  );

  for (final (input, error) in [
    ('0', CalculatorFieldError.mustBePositive),
    ('-3', CalculatorFieldError.mustBePositive),
    ('', CalculatorFieldError.required),
    ('   ', CalculatorFieldError.required),
    ('eight', CalculatorFieldError.invalidNumber),
    ('1.2.3', CalculatorFieldError.invalidNumber),
  ]) {
    blocTest<DoublingTimeCalculatorCubit, DoublingTimeCalculatorState>(
      '"$input" is rejected inline as $error, never thrown',
      build: buildCubit,
      act: (cubit) => cubit
        ..annualRateChanged(input)
        ..calculate(),
      verify: (cubit) {
        expect(cubit.state.annualRateError, error);
        expect(cubit.state.result, isNull);
      },
    );
  }

  blocTest<DoublingTimeCalculatorCubit, DoublingTimeCalculatorState>(
    'editing the rate clears the error and any stale result',
    build: buildCubit,
    act: (cubit) => cubit
      ..annualRateChanged('0')
      ..calculate()
      ..annualRateChanged('6'),
    verify: (cubit) {
      expect(cubit.state.annualRateError, isNull);
      expect(cubit.state.result, isNull);
    },
  );
}
