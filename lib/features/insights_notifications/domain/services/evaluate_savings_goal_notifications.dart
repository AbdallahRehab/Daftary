import 'package:injectable/injectable.dart';

import '../entities/notification_candidate.dart';
import '../entities/notification_history_entry.dart';
import '../ports/savings_insights_source.dart';

/// Pure pace classification over one already-fetched 011 goal
/// (contracts/notification_engine.md). No repository, no I/O, no clock of
/// its own (research.md Decision 2).
abstract class EvaluateSavingsGoalNotifications {
  /// `null` when [goal] has neither a monthly contribution nor a target
  /// date (FR-005) — there is no plan to be on or off pace against, so
  /// there is nothing to notify about. [now] is the evaluation instant,
  /// passed in so the result is deterministic.
  SavingsGoalNotificationCandidate? evaluate(
    SavingsGoalSnapshot goal, {
    required DateTime now,
  });
}

/// Rules, in order:
///
/// 1. No monthly contribution and no target date → `null` (FR-005).
/// 2. `isAchieved` → [ThresholdBand.achieved].
/// 3. 011 reports a shortfall (estimated date after the target date) →
///    [ThresholdBand.behindPace], `-shortfallMonths`.
/// 4. A target date is set and 011's estimated date lands at least one whole
///    month before it → [ThresholdBand.aheadOfPace] by that many months.
/// 5. Only a monthly contribution is set → the saved amount is compared with
///    `monthly × whole months elapsed since createdAt`; a gap of at least
///    one month's contribution is behind/ahead by that many whole months,
///    otherwise on pace.
/// 6. Anything else (e.g. a target date alone, which gives 011 no estimated
///    date to compare) → [ThresholdBand.onPace].
///
/// Every input figure is 011's own; rule 5 is a comparison against the
/// goal's stored plan, not a second projection.
@LazySingleton(as: EvaluateSavingsGoalNotifications)
class EvaluateSavingsGoalNotificationsImpl
    implements EvaluateSavingsGoalNotifications {
  const EvaluateSavingsGoalNotificationsImpl();

  @override
  SavingsGoalNotificationCandidate? evaluate(
    SavingsGoalSnapshot goal, {
    required DateTime now,
  }) {
    final monthly = goal.monthlyContributionMinorUnits;
    final targetDate = goal.targetDate;
    if (monthly == null && targetDate == null) return null;

    SavingsGoalNotificationCandidate candidate(
      ThresholdBand band,
      int months,
    ) => SavingsGoalNotificationCandidate(
      goalId: goal.goalId,
      goalName: goal.name,
      band: band,
      monthsAheadOrBehind: months,
    );

    if (goal.isAchieved) return candidate(ThresholdBand.achieved, 0);

    final estimate = goal.estimatedCompletion;
    if (estimate != null && estimate.hasShortfall) {
      return candidate(
        ThresholdBand.behindPace,
        -(estimate.shortfallMonths ?? 0),
      );
    }

    if (targetDate != null) {
      final estimatedDate = estimate?.estimatedDate;
      if (estimatedDate != null) {
        final monthsEarly = wholeMonthsBetween(estimatedDate, targetDate);
        if (monthsEarly >= 1) {
          return candidate(ThresholdBand.aheadOfPace, monthsEarly);
        }
      }
      return candidate(ThresholdBand.onPace, 0);
    }

    // Only a monthly contribution is set (monthly != null here).
    final expected = monthly! * wholeMonthsBetween(goal.createdAt, now);
    // Truncates toward zero: less than one full month's contribution either
    // way is still on pace.
    final months = (goal.currentAmountMinorUnits - expected) ~/ monthly;
    if (months <= -1) return candidate(ThresholdBand.behindPace, months);
    if (months >= 1) return candidate(ThresholdBand.aheadOfPace, months);
    return candidate(ThresholdBand.onPace, 0);
  }

  /// Whole calendar months from [from] to [to] (`0` when [to] is not after
  /// [from]). A month only counts once its day-of-month and time have been
  /// reached — Jan 31 → Feb 28 is `0`, Jan 15 → Feb 15 is `1`.
  static int wholeMonthsBetween(DateTime from, DateTime to) {
    if (!to.isAfter(from)) return 0;
    var months = (to.year - from.year) * 12 + (to.month - from.month);
    final anniversary = (from.isUtc ? DateTime.utc : DateTime.new)(
      from.year,
      from.month + months,
      from.day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
    // `DateTime` rolls an overflowing day into the next month (Jan 31 + 1
    // month → Mar 3), which also correctly pushes the anniversary past a
    // short month's end.
    if (anniversary.isAfter(to)) months -= 1;
    return months < 0 ? 0 : months;
  }
}
