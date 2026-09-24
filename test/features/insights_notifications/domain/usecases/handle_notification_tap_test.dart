import 'package:daftary/features/insights_notifications/domain/entities/composed_notification.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/handle_notification_tap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'notification_engine_harness.dart';

/// T023/T031 — resolving a tapped notification's deep-link target (FR-014).
void main() {
  late MockBudgetSource budgets;
  late MockSavingsSource savings;
  late FakeClock clock;
  late HandleNotificationTap handleTap;

  setUp(() {
    budgets = MockBudgetSource();
    savings = MockSavingsSource();
    clock = FakeClock(DateTime(2026, 10, 3));
    handleTap = HandleNotificationTap(budgets, savings, clock);
  });

  group('T023 budgetCategory', () {
    const target = NotificationDeepLinkTarget(
      type: NotificationSourceType.budgetCategory,
      id: 'food',
      applicablePeriod: '2026-09',
    );

    test('resolves to the category in the notified month', () async {
      when(
        () => budgets.categoryBudgetExists('food', '2026-09'),
      ).thenAnswer((_) async => true);

      expect(
        await handleTap(target),
        const BudgetCategoryDestination(categoryId: 'food', month: '2026-09'),
      );
      verifyZeroInteractions(savings);
    });

    test('a deleted budget/category is "no longer exists"', () async {
      when(
        () => budgets.categoryBudgetExists('food', '2026-09'),
      ).thenAnswer((_) async => false);

      expect(
        await handleTap(target),
        const SourceNoLongerExists(NotificationSourceType.budgetCategory),
      );
    });

    test('a target with no period falls back to the current month', () async {
      when(
        () => budgets.categoryBudgetExists('food', '2026-10'),
      ).thenAnswer((_) async => true);

      expect(
        await handleTap(
          const NotificationDeepLinkTarget(
            type: NotificationSourceType.budgetCategory,
            id: 'food',
          ),
        ),
        const BudgetCategoryDestination(categoryId: 'food', month: '2026-10'),
      );
    });

    test('an existence check that throws is "no longer exists"', () async {
      when(
        () => budgets.categoryBudgetExists(any(), any()),
      ).thenThrow(Exception('db'));

      expect(await handleTap(target), isA<SourceNoLongerExists>());
    });
  });

  group('T031 savingsGoal', () {
    const target = NotificationDeepLinkTarget(
      type: NotificationSourceType.savingsGoal,
      id: 'car',
    );

    test('resolves to the goal', () async {
      when(() => savings.goalExists('car')).thenAnswer((_) async => true);

      expect(
        await handleTap(target),
        const SavingsGoalDestination(goalId: 'car'),
      );
      verifyZeroInteractions(budgets);
    });

    test('a deleted goal is "no longer exists"', () async {
      when(() => savings.goalExists('car')).thenAnswer((_) async => false);

      expect(
        await handleTap(target),
        const SourceNoLongerExists(NotificationSourceType.savingsGoal),
      );
    });
  });
}
