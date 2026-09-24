import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/money/egp_formatter.dart';
import '../../domain/usecases/calculate_doubling_time.dart';
import 'calculator_field_error.dart';
import 'doubling_time_calculator_state.dart';

/// Drives the rule-of-72 doubling-time calculator (US3, FR-011). Invalid or
/// unparseable input becomes an inline [CalculatorFieldError], never an
/// exception.
@injectable
class DoublingTimeCalculatorCubit extends Cubit<DoublingTimeCalculatorState> {
  DoublingTimeCalculatorCubit(
    this._calculateDoublingTime,
    EgpFormatter egpFormatter,
  ) : _parser = CalculatorInputParser(egpFormatter),
      super(const DoublingTimeCalculatorState());

  final CalculateDoublingTime _calculateDoublingTime;
  final CalculatorInputParser _parser;

  void annualRateChanged(String text) {
    emit(
      state.copyWith(
        annualRateInput: text,
        clearAnnualRateError: true,
        clearResult: true,
      ),
    );
  }

  void calculate() {
    final rate = _parser.parsePercent(state.annualRateInput);
    final parseError = rate.error;
    if (parseError != null) {
      emit(state.copyWith(annualRateError: parseError, clearResult: true));
      return;
    }

    final outcome = _calculateDoublingTime(annualRatePercent: rate.value!);
    final result = outcome.value;
    if (result == null) {
      // The only rejection is `nonPositiveRate` (FR-011).
      emit(
        state.copyWith(
          annualRateError: CalculatorFieldError.mustBePositive,
          clearResult: true,
        ),
      );
      return;
    }
    emit(state.copyWith(clearAnnualRateError: true, result: result));
  }
}
