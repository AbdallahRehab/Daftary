import 'package:equatable/equatable.dart';

import 'notification_history_entry.dart';

/// One budgeted category's newly computed band, plus the real 010 values a
/// template needs (contracts/notification_engine.md). Not yet compared
/// against history — that is `NotificationEngine`'s job.
class BudgetNotificationCandidate extends Equatable {
  const BudgetNotificationCandidate({
    required this.categoryId,
    required this.categoryName,
    required this.applicablePeriod,
    required this.band,
    required this.percentageUsed,
    required this.actualMinorUnits,
    required this.plannedMinorUnits,
  });

  final String categoryId;
  final String categoryName;

  /// The budget month, `'YYYY-MM'`.
  final String applicablePeriod;

  /// [ThresholdBand.belowWarning], [ThresholdBand.nearLimit] or
  /// [ThresholdBand.exceeded].
  final ThresholdBand band;

  /// Straight from 010; `null` for a zero-planned allocation, where a
  /// percentage is undefined (010 data-model.md).
  final double? percentageUsed;

  final int actualMinorUnits;
  final int plannedMinorUnits;

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    applicablePeriod,
    band,
    percentageUsed,
    actualMinorUnits,
    plannedMinorUnits,
  ];
}

/// One savings goal's newly computed band (contracts/notification_engine.md).
class SavingsGoalNotificationCandidate extends Equatable {
  const SavingsGoalNotificationCandidate({
    required this.goalId,
    required this.goalName,
    required this.band,
    required this.monthsAheadOrBehind,
  });

  final String goalId;
  final String goalName;

  /// [ThresholdBand.onPace], [ThresholdBand.behindPace],
  /// [ThresholdBand.aheadOfPace] or [ThresholdBand.achieved].
  final ThresholdBand band;

  /// Signed whole months: negative = behind, positive = ahead, `0` when on
  /// pace or achieved.
  final int monthsAheadOrBehind;

  @override
  List<Object?> get props => [goalId, goalName, band, monthsAheadOrBehind];
}
