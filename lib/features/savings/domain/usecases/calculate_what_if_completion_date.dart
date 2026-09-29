import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../entities/savings_failures.dart';
import '../entities/what_if_result.dart';
import '../services/savings_calculator.dart';
import 'calculate_what_if_monthly_contribution.dart';
import 'get_goal_detail.dart';

/// FR-014: the monthly contribution goal [goalId] needs to be finished by a
/// hypothetical target date — without changing the goal (FR-015).
///
/// Read-only by construction, exactly like
/// [CalculateWhatIfMonthlyContribution]: a [GetGoalDetail] read and the pure
/// [SavingsCalculator], nothing that can write.
///
/// Failures: `InvalidTargetDateFailure` for a date on or before today
/// (FR-016, the same rule as FR-003, checked before the goal is read),
/// `GoalAlreadyAchievedFailure` for an achieved goal (FR-016), and whatever
/// reading the goal fails with.
@injectable
class CalculateWhatIfCompletionDate {
  const CalculateWhatIfCompletionDate(
    this._getGoalDetail,
    this._calculator,
    this._clock,
  );

  final GetGoalDetail _getGoalDetail;
  final SavingsCalculator _calculator;
  final AppClock _clock;

  /// On success the result carries [hypotheticalTargetDate] back, plus the
  /// required monthly contribution (goal currency, rounded up to the next
  /// minor unit) and how many months that contribution takes.
  Future<Either<Failure, WhatIfResult>> call({
    required String goalId,
    required DateTime hypotheticalTargetDate,
  }) async {
    final now = _clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(
      hypotheticalTargetDate.year,
      hypotheticalTargetDate.month,
      hypotheticalTargetDate.day,
    );
    if (!date.isAfter(today)) {
      return const Left(
        InvalidTargetDateFailure('Target date must be after today'),
      );
    }
    final detail = await _getGoalDetail(goalId);
    return detail.flatMap((detail) {
      if (detail.progress.isAchieved) return const Left(goalAlreadyAchieved);
      return Right(
        _calculator.whatIfTargetDate(
          remainingMinorUnits: detail.progress.remainingMinorUnits,
          hypotheticalTargetDate: date,
          asOf: now,
        ),
      );
    });
  }
}
