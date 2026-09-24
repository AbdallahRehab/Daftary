import 'package:equatable/equatable.dart';

import '../../domain/entities/calculator_results.dart';
import 'calculator_field_error.dart';

/// Immutable state for `CompoundGrowthCalculatorCubit` — updated
/// exclusively via [copyWith] (constitution Principle IV).
class CompoundGrowthCalculatorState extends Equatable {
  const CompoundGrowthCalculatorState({
    this.monthlyContributionInput = '',
    this.annualRateInput = '',
    this.yearsInput = '',
    this.monthlyContributionError,
    this.annualRateError,
    this.yearsError,
    this.isResultTooLarge = false,
    this.result,
    this.prefillAmountMinorUnits,
  });

  final String monthlyContributionInput;
  final String annualRateInput;
  final String yearsInput;

  final CalculatorFieldError? monthlyContributionError;
  final CalculatorFieldError? annualRateError;
  final CalculatorFieldError? yearsError;

  /// The inputs were individually valid but produce a figure too large to
  /// represent exactly — a form-level message rather than a field error.
  final bool isResultTooLarge;

  /// The latest successful calculation. Cleared as soon as any input
  /// changes, so a stale result is never shown next to edited inputs.
  final CompoundGrowthResult? result;

  /// The amount the optional savings-goal pre-fill would copy in (FR-014).
  /// `null` hides the pre-fill action entirely.
  final int? prefillAmountMinorUnits;

  bool get isPrefillAvailable => prefillAmountMinorUnits != null;

  bool get hasErrors =>
      monthlyContributionError != null ||
      annualRateError != null ||
      yearsError != null ||
      isResultTooLarge;

  CompoundGrowthCalculatorState copyWith({
    String? monthlyContributionInput,
    String? annualRateInput,
    String? yearsInput,
    CalculatorFieldError? monthlyContributionError,
    bool clearMonthlyContributionError = false,
    CalculatorFieldError? annualRateError,
    bool clearAnnualRateError = false,
    CalculatorFieldError? yearsError,
    bool clearYearsError = false,
    bool? isResultTooLarge,
    CompoundGrowthResult? result,
    bool clearResult = false,
    int? prefillAmountMinorUnits,
  }) {
    return CompoundGrowthCalculatorState(
      monthlyContributionInput:
          monthlyContributionInput ?? this.monthlyContributionInput,
      annualRateInput: annualRateInput ?? this.annualRateInput,
      yearsInput: yearsInput ?? this.yearsInput,
      monthlyContributionError: clearMonthlyContributionError
          ? null
          : (monthlyContributionError ?? this.monthlyContributionError),
      annualRateError: clearAnnualRateError
          ? null
          : (annualRateError ?? this.annualRateError),
      yearsError: clearYearsError ? null : (yearsError ?? this.yearsError),
      isResultTooLarge: isResultTooLarge ?? this.isResultTooLarge,
      result: clearResult ? null : (result ?? this.result),
      prefillAmountMinorUnits:
          prefillAmountMinorUnits ?? this.prefillAmountMinorUnits,
    );
  }

  @override
  List<Object?> get props => [
    monthlyContributionInput,
    annualRateInput,
    yearsInput,
    monthlyContributionError,
    annualRateError,
    yearsError,
    isResultTooLarge,
    result,
    prefillAmountMinorUnits,
  ];
}
