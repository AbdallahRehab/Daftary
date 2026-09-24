import 'package:daftary/features/insights_notifications/data/services/localized_notification_composer.dart';
import 'package:daftary/features/insights_notifications/domain/entities/composed_notification.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_candidate.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_history_entry.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const composer = LocalizedNotificationComposer();

  BudgetNotificationCandidate budget(ThresholdBand band, double? percent) =>
      BudgetNotificationCandidate(
        categoryId: 'cat-food',
        categoryName: 'Food',
        applicablePeriod: '2026-09',
        band: band,
        percentageUsed: percent,
        actualMinorUnits: 0,
        plannedMinorUnits: 0,
      );

  SavingsGoalNotificationCandidate goal(ThresholdBand band, int months) =>
      SavingsGoalNotificationCandidate(
        goalId: 'goal-1',
        goalName: 'Car',
        band: band,
        monthsAheadOrBehind: months,
      );

  group('budget', () {
    test('near-limit carries the category and the floored percent', () {
      final n = composer.composeBudget(
        budget(ThresholdBand.nearLimit, 99.7),
        languageCode: 'en',
      )!;
      expect(n.title, 'Food is close to its limit');
      expect(n.body, "You've used 99% of your Food budget this month.");
      expect(
        n.deepLinkTarget,
        const NotificationDeepLinkTarget(
          type: NotificationSourceType.budgetCategory,
          id: 'cat-food',
          applicablePeriod: '2026-09',
        ),
      );
    });

    test('exceeded, and exceeded with no planned amount', () {
      expect(
        composer
            .composeBudget(
              budget(ThresholdBand.exceeded, 112.4),
              languageCode: 'en',
            )!
            .body,
        "You've spent 112% of your Food budget this month.",
      );
      expect(
        composer
            .composeBudget(
              budget(ThresholdBand.exceeded, null),
              languageCode: 'en',
            )!
            .body,
        contains('no amount was planned'),
      );
    });

    test('Arabic uses Western digits', () {
      final n = composer.composeBudget(
        budget(ThresholdBand.nearLimit, 92.1),
        languageCode: 'ar',
      )!;
      expect(n.body, contains('92٪'));
      expect(n.body, contains('Food'));
    });

    test('belowWarning has no message', () {
      expect(
        composer.composeBudget(
          budget(ThresholdBand.belowWarning, 10),
          languageCode: 'en',
        ),
        isNull,
      );
    });
  });

  group('savings goal', () {
    test('behind / ahead use the absolute month count with plurals', () {
      expect(
        composer
            .composeSavingsGoal(
              goal(ThresholdBand.behindPace, -3),
              languageCode: 'en',
            )!
            .body,
        contains('Car 3 months later'),
      );
      expect(
        composer
            .composeSavingsGoal(
              goal(ThresholdBand.aheadOfPace, 1),
              languageCode: 'en',
            )!
            .body,
        contains('Car 1 month early'),
      );
      expect(
        composer
            .composeSavingsGoal(
              goal(ThresholdBand.behindPace, -2),
              languageCode: 'ar',
            )!
            .body,
        contains('شهرين'),
      );
    });

    test('achieved links to the goal', () {
      final n = composer.composeSavingsGoal(
        goal(ThresholdBand.achieved, 0),
        languageCode: 'en',
      )!;
      expect(n.title, 'Goal reached: Car');
      expect(n.deepLinkTarget.encode(), 'savingsGoal:goal-1');
    });

    test('onPace and noEstimateAvailable have no message', () {
      for (final band in [
        ThresholdBand.onPace,
        ThresholdBand.noEstimateAvailable,
      ]) {
        expect(
          composer.composeSavingsGoal(goal(band, 0), languageCode: 'en'),
          isNull,
        );
      }
    });

    test('an unsupported language falls back to English', () {
      expect(
        composer
            .composeSavingsGoal(
              goal(ThresholdBand.achieved, 0),
              languageCode: 'fr',
            )!
            .title,
        'Goal reached: Car',
      );
    });
  });
}
