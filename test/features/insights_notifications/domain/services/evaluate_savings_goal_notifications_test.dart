import 'package:daftary/features/insights_notifications/domain/entities/notification_history_entry.dart';
import 'package:daftary/features/insights_notifications/domain/ports/savings_insights_source.dart';
import 'package:daftary/features/insights_notifications/domain/services/evaluate_savings_goal_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// T012 — exhaustive coverage for [EvaluateSavingsGoalNotifications].
void main() {
  const evaluator = EvaluateSavingsGoalNotificationsImpl();
  final now = DateTime(2026, 9, 24, 12);

  SavingsGoalSnapshot goal({
    int target = 1200000,
    int current = 0,
    bool isAchieved = false,
    int? monthly,
    DateTime? targetDate,
    DateTime? createdAt,
    SavingsEstimatedCompletionSnapshot? estimate,
  }) {
    return SavingsGoalSnapshot(
      goalId: 'goal-1',
      name: 'Car',
      targetAmountMinorUnits: target,
      currentAmountMinorUnits: current,
      isAchieved: isAchieved,
      monthlyContributionMinorUnits: monthly,
      targetDate: targetDate,
      createdAt: createdAt ?? DateTime(2026, 3, 24, 12),
      estimatedCompletion: estimate,
    );
  }

  group('no plan (FR-005)', () {
    test('no monthly contribution and no target date returns null, not a '
        'candidate', () {
      expect(evaluator.evaluate(goal(current: 5000), now: now), isNull);
    });

    test('returns null even when achieved', () {
      expect(
        evaluator.evaluate(goal(current: 1200000, isAchieved: true), now: now),
        isNull,
      );
    });
  });

  group('achieved', () {
    test('isAchieved wins over every pace signal', () {
      final candidate = evaluator.evaluate(
        goal(
          current: 1300000,
          isAchieved: true,
          monthly: 100000,
          targetDate: DateTime(2027, 3),
        ),
        now: now,
      )!;
      expect(candidate.band, ThresholdBand.achieved);
      expect(candidate.monthsAheadOrBehind, 0);
      expect(candidate.goalId, 'goal-1');
      expect(candidate.goalName, 'Car');
    });
  });

  group('behind pace', () {
    test("011's shortfall is behind by -shortfallMonths", () {
      final candidate = evaluator.evaluate(
        goal(
          monthly: 50000,
          targetDate: DateTime(2027, 3, 24),
          estimate: SavingsEstimatedCompletionSnapshot(
            estimatedMonths: 24,
            estimatedDate: DateTime(2028, 9, 24),
            hasShortfall: true,
            shortfallMonths: 18,
          ),
        ),
        now: now,
      )!;
      expect(candidate.band, ThresholdBand.behindPace);
      expect(candidate.monthsAheadOrBehind, -18);
    });

    test('monthly-only: saved less than one month short of plan is behind by '
        'whole months', () {
      // Six whole months elapsed at 100,000/month → 600,000 planned;
      // 350,000 saved is 2.5 months short → -2.
      final candidate = evaluator.evaluate(
        goal(
          current: 350000,
          monthly: 100000,
          estimate: const SavingsEstimatedCompletionSnapshot(
            estimatedMonths: 9,
            hasShortfall: false,
          ),
        ),
        now: now,
      )!;
      expect(candidate.band, ThresholdBand.behindPace);
      expect(candidate.monthsAheadOrBehind, -2);
    });
  });

  group('ahead of pace', () {
    test("target date set: 011's estimate lands >= 1 whole month early", () {
      final candidate = evaluator.evaluate(
        goal(
          monthly: 200000,
          targetDate: DateTime(2027, 9, 24),
          estimate: SavingsEstimatedCompletionSnapshot(
            estimatedMonths: 6,
            estimatedDate: DateTime(2027, 3, 24),
            hasShortfall: false,
          ),
        ),
        now: now,
      )!;
      expect(candidate.band, ThresholdBand.aheadOfPace);
      expect(candidate.monthsAheadOrBehind, 6);
    });

    test('monthly-only: saved at least one month more than plan', () {
      // 600,000 planned after six months; 850,000 saved → +2.
      final candidate = evaluator.evaluate(
        goal(
          current: 850000,
          monthly: 100000,
          estimate: const SavingsEstimatedCompletionSnapshot(
            estimatedMonths: 4,
            hasShortfall: false,
          ),
        ),
        now: now,
      )!;
      expect(candidate.band, ThresholdBand.aheadOfPace);
      expect(candidate.monthsAheadOrBehind, 2);
    });
  });

  group('on pace', () {
    test('target date set: estimate less than one whole month early', () {
      final candidate = evaluator.evaluate(
        goal(
          monthly: 100000,
          targetDate: DateTime(2027, 9, 24),
          estimate: SavingsEstimatedCompletionSnapshot(
            estimatedMonths: 12,
            estimatedDate: DateTime(2027, 9, 10),
            hasShortfall: false,
          ),
        ),
        now: now,
      )!;
      expect(candidate.band, ThresholdBand.onPace);
      expect(candidate.monthsAheadOrBehind, 0);
    });

    test('target date only: no estimated date to compare, so on pace', () {
      final candidate = evaluator.evaluate(
        goal(
          targetDate: DateTime(2027, 9, 24),
          estimate: const SavingsEstimatedCompletionSnapshot(
            hasShortfall: false,
          ),
        ),
        now: now,
      )!;
      expect(candidate.band, ThresholdBand.onPace);
    });

    test('monthly-only: within one month of plan either way', () {
      for (final current in [510000, 600000, 690000]) {
        final candidate = evaluator.evaluate(
          goal(current: current, monthly: 100000),
          now: now,
        )!;
        expect(candidate.band, ThresholdBand.onPace, reason: '$current');
      }
    });
  });

  group('wholeMonthsBetween', () {
    const months = EvaluateSavingsGoalNotificationsImpl.wholeMonthsBetween;

    test('counts only completed calendar months', () {
      expect(months(DateTime(2026, 1, 15), DateTime(2026, 2, 15)), 1);
      expect(months(DateTime(2026, 1, 15), DateTime(2026, 2, 14)), 0);
      expect(months(DateTime(2026, 1, 31), DateTime(2026, 2, 28)), 0);
      expect(months(DateTime(2026, 1, 31), DateTime(2026, 3, 31)), 2);
      expect(months(DateTime(2025, 11, 1), DateTime(2026, 2, 1)), 3);
    });

    test('is 0 when the end is not after the start', () {
      expect(months(DateTime(2026, 3), DateTime(2026, 1)), 0);
      expect(months(DateTime(2026, 3), DateTime(2026, 3)), 0);
    });
  });
}
