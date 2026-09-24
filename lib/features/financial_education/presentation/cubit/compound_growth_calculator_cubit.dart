import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/money/egp_formatter.dart';
import '../../domain/entities/calculator_validation_result.dart';
import '../../domain/usecases/calculate_compound_growth.dart';
import '../../domain/usecases/get_prefillable_savings_goal_amount.dart';
import 'calculator_field_error.dart';
import 'compound_growth_calculator_state.dart';

/// Drives the compound-growth calculator form (US2, FR-007..FR-010, FR-014).
///
/// Every input is typed by the user (FR-013). Invalid or unparseable input
/// becomes a per-field [CalculatorFieldError] — nothing here throws.
@injectable
class CompoundGrowthCalculatorCubit
    extends Cubit<CompoundGrowthCalculatorState> {
  CompoundGrowthCalculatorCubit(
    this._calculateCompoundGrowth,
    this._getPrefillableSavingsGoalAmount,
    EgpFormatter egpFormatter,
  ) : _parser = CalculatorInputParser(egpFormatter),
      super(const CompoundGrowthCalculatorState());

  final CalculateCompoundGrowth _calculateCompoundGrowth;
  final GetPrefillableSavingsGoalAmount _getPrefillableSavingsGoalAmount;
  final CalculatorInputParser _parser;

  /// Asks whether a savings-goal amount is available to offer as a pre-fill
  /// (FR-014). Call once when the page opens; when it resolves to `null`
  /// the pre-fill action simply stays hidden.
  Future<void> loadPrefillAvailability() async {
    final int? amount;
    try {
      amount = await _getPrefillableSavingsGoalAmount();
    } on Object {
      // Graceful degradation: an optional convenience must never break the
      // calculator itself.
      return;
    }
    if (isClosed || amount == null || amount <= 0) return;
    emit(state.copyWith(prefillAmountMinorUnits: amount));
  }

  /// Copies the offered amount into the (still freely editable) monthly
  /// amount field. It is only a starting value: nothing is calculated, and
  /// the user may overwrite it before calculating (FR-014).
  void applyPrefill() {
    final amount = state.prefillAmountMinorUnits;
    if (amount == null) return;
    monthlyContributionChanged(
      CalculatorInputParser.formatMinorUnitsForInput(amount),
    );
  }

  void monthlyContributionChanged(String text) {
    emit(
      state.copyWith(
        monthlyContributionInput: text,
        clearMonthlyContributionError: true,
        isResultTooLarge: false,
        clearResult: true,
      ),
    );
  }

  void annualRateChanged(String text) {
    emit(
      state.copyWith(
        annualRateInput: text,
        clearAnnualRateError: true,
        isResultTooLarge: false,
        clearResult: true,
      ),
    );
  }

  void yearsChanged(String text) {
    emit(
      state.copyWith(
        yearsInput: text,
        clearYearsError: true,
        isResultTooLarge: false,
        clearResult: true,
      ),
    );
  }

  void calculate() {
    final monthly = _parser.parseAmountMinorUnits(
      state.monthlyContributionInput,
    );
    final rate = _parser.parsePercent(state.annualRateInput);
    final years = _parser.parseWholeYears(state.yearsInput);

    if (monthly.error != null || rate.error != null || years.error != null) {
      // Report every unparseable field at once, keeping what was typed.
      emit(
        CompoundGrowthCalculatorState(
          monthlyContributionInput: state.monthlyContributionInput,
          annualRateInput: state.annualRateInput,
          yearsInput: state.yearsInput,
          monthlyContributionError: monthly.error,
          annualRateError: rate.error,
          yearsError: years.error,
          prefillAmountMinorUnits: state.prefillAmountMinorUnits,
        ),
      );
      return;
    }

    final outcome = _calculateCompoundGrowth(
      monthlyContributionMinorUnits: monthly.value!,
      annualRatePercent: rate.value!,
      years: years.value!,
    );

    final cleared = CompoundGrowthCalculatorState(
      monthlyContributionInput: state.monthlyContributionInput,
      annualRateInput: state.annualRateInput,
      yearsInput: state.yearsInput,
      prefillAmountMinorUnits: state.prefillAmountMinorUnits,
    );
    final problem = outcome.problem;
    if (problem == null) {
      emit(cleared.copyWith(result: outcome.value));
      return;
    }
    emit(switch (problem) {
      CalculatorInputProblem.nonPositiveAmount => cleared.copyWith(
        monthlyContributionError: CalculatorFieldError.mustBePositive,
      ),
      CalculatorInputProblem.negativeRate ||
      CalculatorInputProblem.nonPositiveRate => cleared.copyWith(
        annualRateError: CalculatorFieldError.mustNotBeNegative,
      ),
      CalculatorInputProblem.nonPositiveDuration => cleared.copyWith(
        yearsError: CalculatorFieldError.mustBePositive,
      ),
      CalculatorInputProblem.resultTooLarge => cleared.copyWith(
        isResultTooLarge: true,
      ),
      // Never produced by `CompoundGrowthCalculator`; listed only to keep
      // this switch exhaustive. Showing no result is the safe fallback.
      CalculatorInputProblem.nonPositiveIncome ||
      CalculatorInputProblem.negativeSavings => cleared,
    });
  }
}
