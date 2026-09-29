import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/savings_failures.dart';
import '../../domain/entities/what_if_mode.dart';
import '../../domain/entities/what_if_result.dart';
import '../../domain/usecases/apply_what_if_scenario.dart';
import '../../domain/usecases/calculate_what_if_completion_date.dart';
import '../../domain/usecases/calculate_what_if_monthly_contribution.dart';
import '../../domain/usecases/get_goal_detail.dart';
import 'what_if_state.dart';

/// Drives the what-if calculator (FR-013-FR-016).
///
/// Exploring ([calculate]) goes only through the read-only
/// `CalculateWhatIf*` use cases and only ever sets `state.result`; the goal
/// changes solely through an explicit [apply] (`ApplyWhatIfScenario`,
/// FR-015). Closing the page without applying is the cancel — there is
/// nothing to undo.
@injectable
class WhatIfCubit extends Cubit<WhatIfState> {
  WhatIfCubit(
    this._getGoalDetail,
    this._calculateByMonthly,
    this._calculateByDate,
    this._applyScenario,
  ) : super(const WhatIfState(goalId: ''));

  final GetGoalDetail _getGoalDetail;
  final CalculateWhatIfMonthlyContribution _calculateByMonthly;
  final CalculateWhatIfCompletionDate _calculateByDate;
  final ApplyWhatIfScenario _applyScenario;

  /// Reads goal [goalId]'s current state. Call once, right after
  /// construction.
  Future<void> load(String goalId) async {
    emit(WhatIfState(goalId: goalId));
    final result = await _getGoalDetail(goalId);
    if (isClosed) return;
    result.match(
      (failure) =>
          emit(state.copyWith(status: WhatIfStatus.failure, failure: failure)),
      (detail) => emit(
        state.copyWith(
          status: detail.progress.isAchieved
              ? WhatIfStatus.achieved
              : WhatIfStatus.ready,
          detail: detail,
        ),
      ),
    );
  }

  void modeChanged(WhatIfMode mode) {
    if (mode == state.mode) return;
    emit(
      state.copyWith(
        mode: mode,
        monthlyInvalid: false,
        targetDateInvalid: false,
        clearResult: true,
        clearFailure: true,
      ),
    );
  }

  void monthlyChanged(String text) => emit(
    state.copyWith(
      monthlyInput: text,
      monthlyInvalid: false,
      clearResult: true,
      clearFailure: true,
    ),
  );

  void targetDateChanged(DateTime date) => emit(
    state.copyWith(
      targetDate: date,
      targetDateInvalid: false,
      clearResult: true,
      clearFailure: true,
    ),
  );

  /// Runs the what-if for the current mode and input. Never writes.
  Future<void> calculate() async {
    final detail = state.detail;
    if (detail == null || state.status != WhatIfStatus.ready) return;
    if (state.isCalculating || state.isApplying) return;

    final mode = state.mode;
    final Future<Either<Failure, WhatIfResult>> pending;
    switch (mode) {
      case WhatIfMode.monthlyContribution:
        final amount = _parse(state.monthlyInput, detail.goal.currency);
        if (amount == null || amount <= 0) {
          emit(state.copyWith(monthlyInvalid: true, clearResult: true));
          return;
        }
        pending = _calculateByMonthly(
          goalId: state.goalId,
          hypotheticalMonthlyContributionMinorUnits: amount,
        );
      case WhatIfMode.targetDate:
        final date = state.targetDate;
        if (date == null) {
          emit(state.copyWith(targetDateInvalid: true, clearResult: true));
          return;
        }
        pending = _calculateByDate(
          goalId: state.goalId,
          hypotheticalTargetDate: date,
        );
    }

    emit(
      state.copyWith(
        isCalculating: true,
        clearResult: true,
        clearFailure: true,
      ),
    );
    final result = await pending;
    if (isClosed) return;
    result.match(
      (failure) => emit(switch (failure) {
        GoalAlreadyAchievedFailure() => state.copyWith(
          status: WhatIfStatus.achieved,
          isCalculating: false,
        ),
        ValidationFailure() => state.copyWith(
          monthlyInvalid: true,
          isCalculating: false,
        ),
        InvalidTargetDateFailure() => state.copyWith(
          targetDateInvalid: true,
          isCalculating: false,
        ),
        _ => state.copyWith(isCalculating: false, failure: failure),
      }),
      (whatIf) => emit(
        state.copyWith(isCalculating: false, result: whatIf, resultMode: mode),
      ),
    );
  }

  /// FR-015: writes the current result to the real goal — the only write
  /// this cubit can make. A re-entrant tap while applying is ignored.
  Future<void> apply() async {
    final scenario = state.result;
    final mode = state.resultMode;
    if (scenario == null || mode == null || !state.canApply) return;

    emit(
      state.copyWith(
        applyStatus: WhatIfApplyStatus.applying,
        clearFailure: true,
      ),
    );
    final result = await _applyScenario(
      goalId: state.goalId,
      mode: mode,
      scenario: scenario,
    );
    if (isClosed) return;
    result.match(
      (failure) => emit(
        state.copyWith(
          status: failure is GoalAlreadyAchievedFailure
              ? WhatIfStatus.achieved
              : null,
          applyStatus: WhatIfApplyStatus.failed,
          failure: failure,
        ),
      ),
      (goal) => emit(
        state.copyWith(
          applyStatus: WhatIfApplyStatus.applied,
          appliedGoal: goal,
        ),
      ),
    );
  }

  /// The page has shown [WhatIfState.failure]; clear it so it is shown once.
  void failureShown() => emit(state.copyWith(clearFailure: true));

  /// Typed text as minor units of the goal's currency (Arabic-Indic digits
  /// accepted), or `null` when it is empty or not an amount.
  static int? _parse(String input, Currency currency) {
    final text = NumeralParser.toWesternDigits(input).trim();
    if (text.isEmpty) return null;
    try {
      return CurrencyFormatter(currency: currency).parse(text).minorUnits;
    } on FormatException {
      return null;
    }
  }
}
