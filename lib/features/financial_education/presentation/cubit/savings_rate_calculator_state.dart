import 'package:equatable/equatable.dart';

import '../../domain/entities/calculator_results.dart';
import 'calculator_field_error.dart';

/// Immutable state for `SavingsRateCalculatorCubit` — updated exclusively
/// via [copyWith] (constitution Principle IV).
class SavingsRateCalculatorState extends Equatable {
  const SavingsRateCalculatorState({
    this.incomeInput = '',
    this.savingsAmountInput = '',
    this.incomeError,
    this.savingsAmountError,
    this.result,
  });

  final String incomeInput;
  final String savingsAmountInput;
  final CalculatorFieldError? incomeError;
  final CalculatorFieldError? savingsAmountError;

  /// Cleared as soon as either input changes. May exceed 100% — never
  /// clamped (FR-012).
  final SavingsRateResult? result;

  SavingsRateCalculatorState copyWith({
    String? incomeInput,
    String? savingsAmountInput,
    CalculatorFieldError? incomeError,
    bool clearIncomeError = false,
    CalculatorFieldError? savingsAmountError,
    bool clearSavingsAmountError = false,
    SavingsRateResult? result,
    bool clearResult = false,
  }) {
    return SavingsRateCalculatorState(
      incomeInput: incomeInput ?? this.incomeInput,
      savingsAmountInput: savingsAmountInput ?? this.savingsAmountInput,
      incomeError: clearIncomeError ? null : (incomeError ?? this.incomeError),
      savingsAmountError: clearSavingsAmountError
          ? null
          : (savingsAmountError ?? this.savingsAmountError),
      result: clearResult ? null : (result ?? this.result),
    );
  }

  @override
  List<Object?> get props => [
    incomeInput,
    savingsAmountInput,
    incomeError,
    savingsAmountError,
    result,
  ];
}
