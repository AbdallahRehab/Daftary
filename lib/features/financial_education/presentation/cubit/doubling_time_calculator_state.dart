import 'package:equatable/equatable.dart';

import '../../domain/entities/calculator_results.dart';
import 'calculator_field_error.dart';

/// Immutable state for `DoublingTimeCalculatorCubit` — updated exclusively
/// via [copyWith] (constitution Principle IV).
class DoublingTimeCalculatorState extends Equatable {
  const DoublingTimeCalculatorState({
    this.annualRateInput = '',
    this.annualRateError,
    this.result,
  });

  final String annualRateInput;
  final CalculatorFieldError? annualRateError;

  /// Cleared as soon as the input changes.
  final DoublingTimeResult? result;

  DoublingTimeCalculatorState copyWith({
    String? annualRateInput,
    CalculatorFieldError? annualRateError,
    bool clearAnnualRateError = false,
    DoublingTimeResult? result,
    bool clearResult = false,
  }) {
    return DoublingTimeCalculatorState(
      annualRateInput: annualRateInput ?? this.annualRateInput,
      annualRateError: clearAnnualRateError
          ? null
          : (annualRateError ?? this.annualRateError),
      result: clearResult ? null : (result ?? this.result),
    );
  }

  @override
  List<Object?> get props => [annualRateInput, annualRateError, result];
}
