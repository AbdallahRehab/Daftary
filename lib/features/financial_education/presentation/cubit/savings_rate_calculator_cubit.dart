import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/money/egp_formatter.dart';
import '../../domain/entities/calculator_validation_result.dart';
import '../../domain/usecases/calculate_savings_rate.dart';
import 'calculator_field_error.dart';
import 'savings_rate_calculator_state.dart';

/// Drives the effective-savings-rate calculator (US3, FR-012). Both figures
/// are typed by the user (FR-013). A savings amount above the income is
/// accepted and yields a rate above 100% — never clamped.
@injectable
class SavingsRateCalculatorCubit extends Cubit<SavingsRateCalculatorState> {
  SavingsRateCalculatorCubit(
    this._calculateSavingsRate,
    EgpFormatter egpFormatter,
  ) : _parser = CalculatorInputParser(egpFormatter),
      super(const SavingsRateCalculatorState());

  final CalculateSavingsRate _calculateSavingsRate;
  final CalculatorInputParser _parser;

  void incomeChanged(String text) {
    emit(
      state.copyWith(
        incomeInput: text,
        clearIncomeError: true,
        clearResult: true,
      ),
    );
  }

  void savingsAmountChanged(String text) {
    emit(
      state.copyWith(
        savingsAmountInput: text,
        clearSavingsAmountError: true,
        clearResult: true,
      ),
    );
  }

  void calculate() {
    final income = _parser.parseAmountMinorUnits(state.incomeInput);
    final savings = _parser.parseAmountMinorUnits(state.savingsAmountInput);

    if (income.error != null || savings.error != null) {
      emit(
        SavingsRateCalculatorState(
          incomeInput: state.incomeInput,
          savingsAmountInput: state.savingsAmountInput,
          incomeError: income.error,
          savingsAmountError: savings.error,
        ),
      );
      return;
    }

    final outcome = _calculateSavingsRate(
      incomeMinorUnits: income.value!,
      savingsAmountMinorUnits: savings.value!,
    );
    final cleared = SavingsRateCalculatorState(
      incomeInput: state.incomeInput,
      savingsAmountInput: state.savingsAmountInput,
    );
    final problem = outcome.problem;
    if (problem == null) {
      emit(cleared.copyWith(result: outcome.value));
      return;
    }
    emit(switch (problem) {
      CalculatorInputProblem.nonPositiveIncome => cleared.copyWith(
        incomeError: CalculatorFieldError.mustBePositive,
      ),
      CalculatorInputProblem.negativeSavings => cleared.copyWith(
        savingsAmountError: CalculatorFieldError.mustNotBeNegative,
      ),
      // Never produced by `SavingsRateCalculator`; listed only to keep this
      // switch exhaustive. Showing no result is the safe fallback.
      CalculatorInputProblem.nonPositiveAmount ||
      CalculatorInputProblem.negativeRate ||
      CalculatorInputProblem.nonPositiveDuration ||
      CalculatorInputProblem.nonPositiveRate ||
      CalculatorInputProblem.resultTooLarge => cleared,
    });
  }
}
