import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../entities/savings_failures.dart';
import '../entities/what_if_result.dart';
import '../services/savings_calculator.dart';
import 'get_goal_detail.dart';

/// FR-013: when goal [goalId] would be reached at a hypothetical monthly
/// contribution — without changing the goal (FR-015).
///
/// Read-only by construction (research.md Decision 1): the goal's current
/// state is read through [GetGoalDetail] and the answer comes from the pure
/// [SavingsCalculator]; this class has no way to write anything. Only
/// `ApplyWhatIfScenario` turns a result into a change.
///
/// Failures: `ValidationFailure` for a hypothetical `<= 0` (FR-016, checked
/// before the goal is read), `GoalAlreadyAchievedFailure` for an achieved
/// goal (FR-016), and whatever reading the goal fails with (e.g.
/// `GoalNotFoundFailure`).
@injectable
class CalculateWhatIfMonthlyContribution {
  const CalculateWhatIfMonthlyContribution(
    this._getGoalDetail,
    this._calculator,
    this._clock,
  );

  final GetGoalDetail _getGoalDetail;
  final SavingsCalculator _calculator;
  final AppClock _clock;

  /// [hypotheticalMonthlyContributionMinorUnits] is in the goal's own
  /// currency. On success the result carries it back, plus the estimated
  /// completion date and month count.
  Future<Either<Failure, WhatIfResult>> call({
    required String goalId,
    required int hypotheticalMonthlyContributionMinorUnits,
  }) async {
    if (hypotheticalMonthlyContributionMinorUnits <= 0) {
      return const Left(
        ValidationFailure('Monthly contribution must be greater than zero'),
      );
    }
    final detail = await _getGoalDetail(goalId);
    return detail.flatMap((detail) {
      if (detail.progress.isAchieved) return const Left(goalAlreadyAchieved);
      return Right(
        _calculator.whatIfMonthlyContribution(
          remainingMinorUnits: detail.progress.remainingMinorUnits,
          hypotheticalMonthlyContributionMinorUnits:
              hypotheticalMonthlyContributionMinorUnits,
          asOf: _clock.now(),
        ),
      );
    });
  }
}

/// Shared by the what-if use cases (FR-016).
const goalAlreadyAchieved = GoalAlreadyAchievedFailure(
  'This goal is already achieved — there is nothing left to plan for',
);
