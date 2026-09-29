import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/savings_goal.dart';
import '../entities/what_if_mode.dart';
import '../entities/what_if_result.dart';
import 'calculate_what_if_monthly_contribution.dart';
import 'edit_savings_goal.dart';
import 'get_goal_detail.dart';

/// FR-015: the one way a what-if exploration changes the real goal — an
/// explicit apply, carried out as an ordinary [EditSavingsGoal] (so the
/// repository's validation and sync enqueue apply unchanged; no new DAO
/// path).
///
/// What an apply changes depends on the [WhatIfMode] explored:
/// - [WhatIfMode.monthlyContribution]: sets the monthly contribution to the
///   scenario's and **keeps** the stored target date. The date the scenario
///   estimated is an outcome of the contribution, not something the user
///   chose; if the goal also has a target date, FR-012's shortfall line
///   then reports honestly whether the new amount meets it.
/// - [WhatIfMode.targetDate]: sets the target date to the scenario's **and**
///   the monthly contribution to the one it requires, so the saved plan is
///   self-consistent (no shortfall) — the date alone would leave an old
///   contribution that may not reach it.
///
/// Name, type and target are passed through unchanged (an edit overwrites
/// every field). An unchanged stored target date that has since passed is
/// kept without the future-date check; a new one gets it (FR-003).
///
/// Failures: `ValidationFailure` when the scenario lacks the value its mode
/// applies (or the repository rejects the amount), `InvalidTargetDateFailure`
/// when a scenario date is no longer after today, `GoalAlreadyAchievedFailure`
/// for an achieved goal (FR-016), and whatever reading or editing the goal
/// fails with.
@injectable
class ApplyWhatIfScenario {
  const ApplyWhatIfScenario(this._getGoalDetail, this._editSavingsGoal);

  final GetGoalDetail _getGoalDetail;
  final EditSavingsGoal _editSavingsGoal;

  Future<Either<Failure, SavingsGoal>> call({
    required String goalId,
    required WhatIfMode mode,
    required WhatIfResult scenario,
  }) async {
    final monthly = scenario.hypotheticalMonthlyContributionMinorUnits;
    final date = scenario.hypotheticalTargetDate;
    if (monthly == null || (mode == WhatIfMode.targetDate && date == null)) {
      return const Left(
        ValidationFailure('The scenario has no value to apply'),
      );
    }

    final read = await _getGoalDetail(goalId);
    final detail = read.toNullable();
    if (detail == null) return Left(read.getLeft().toNullable()!);
    if (detail.progress.isAchieved) return const Left(goalAlreadyAchieved);

    final goal = detail.goal;
    return _editSavingsGoal(
      goalId: goal.id,
      name: goal.name,
      type: goal.type,
      targetAmountMinorUnits: goal.targetAmountMinorUnits,
      monthlyContributionMinorUnits: monthly,
      targetDate: switch (mode) {
        WhatIfMode.monthlyContribution => goal.targetDate,
        WhatIfMode.targetDate => date,
      },
    );
  }
}
