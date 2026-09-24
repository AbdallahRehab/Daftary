import 'package:daftary/core/database/app_database.dart'
    hide NotificationPreference;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/insights_notifications/domain/entities/composed_notification.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_preference.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:daftary/features/insights_notifications/domain/ports/budget_insights_source.dart';
import 'package:daftary/features/insights_notifications/domain/ports/savings_insights_source.dart';
import 'package:daftary/features/insights_notifications/domain/repositories/notification_preference_repository.dart';
import 'package:daftary/features/insights_notifications/domain/services/notification_scheduler.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/handle_notification_tap.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/notification_engine.dart';
import 'package:daftary/features/insights_notifications/presentation/widgets/permission_denied_banner.dart';
import 'package:daftary/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:integration_test/integration_test.dart';

/// T048 — end-to-end coverage of Proactive Insights & Reminders (US1-US3)
/// against the real app: real DI, the real drift database (preference and
/// history tables), the real evaluators, `gen_l10n` composer and the real
/// Notification Settings page — following quickstart.md's scenarios.
///
/// **Gap, flagged per T048**: Budgets (010) and Savings Goals (011) are not
/// implemented in code yet, so their data reaches this feature through
/// [_FakeBudgetSource]/[_FakeSavingsSource], stand-ins for the
/// `BudgetInsightsSource`/`SavingsInsightsSource` ports shaped after those
/// features' published contracts. Swap them for the real adapters once
/// 010/011 ship. Delivery goes to [_RecordingScheduler] so an automated run
/// never posts a real OS notification.
///
/// Zero network activity (FR-017) is guaranteed structurally: nothing under
/// `lib/features/insights_notifications/` imports a network package.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final budgets = _FakeBudgetSource();
  final savings = _FakeSavingsSource();
  final scheduler = _RecordingScheduler();
  final clock = _FakeClock();

  setUpAll(() async {
    await configureDependencies();
    // A fresh in-memory database, never the device's real file: a device
    // that has run another unmerged feature branch can already sit at this
    // schema version without these tables, and a test must not touch the
    // user's own data either way.
    getIt
      ..unregister<AppDatabase>()
      ..registerSingleton<AppDatabase>(
        AppDatabase.forTesting(NativeDatabase.memory()),
      );
    // Replaced before anything resolves NotificationEngine, which captures
    // its collaborators at construction.
    for (final swap in <void Function()>[
      () => getIt
        ..unregister<BudgetInsightsSource>()
        ..registerSingleton<BudgetInsightsSource>(budgets),
      () => getIt
        ..unregister<SavingsInsightsSource>()
        ..registerSingleton<SavingsInsightsSource>(savings),
      () => getIt
        ..unregister<NotificationScheduler>()
        ..registerSingleton<NotificationScheduler>(scheduler),
      () => getIt
        ..unregister<AppClock>()
        ..registerSingleton<AppClock>(clock),
    ]) {
      swap();
    }
  });

  setUp(() async {
    final db = getIt<AppDatabase>();
    await db.delete(db.notificationHistory).go();
    await db.delete(db.notificationPreferences).go();
    budgets.categories = [];
    savings.goals = [];
    scheduler
      ..delivered.clear()
      ..permissionGranted = true;
    clock.current = DateTime(2026, 9, 15, 12);
  });

  NotificationEngine engine() => getIt<NotificationEngine>();

  Future<void> savePreference(NotificationPreference preference) async {
    final result = await getIt<NotificationPreferenceRepository>()
        .savePreference(preference);
    expect(result.isRight(), isTrue);
  }

  const enabled = NotificationPreference(
    isEnabled: true,
    budgetWarningsEnabled: true,
    savingsCheckInsEnabled: true,
    osPermissionGranted: true,
  );

  BudgetCategorySnapshot groceries({
    required String month,
    required int actual,
    required BudgetCategoryStatus status,
  }) => BudgetCategorySnapshot(
    categoryId: 'groceries',
    categoryName: 'Groceries',
    month: month,
    plannedMinorUnits: 200000,
    actualMinorUnits: actual,
    percentageUsed: actual / 200000 * 100,
    status: status,
  );

  group('US1 budget-limit warnings', () {
    testWidgets('near-limit → exceeded → no repeat → new-month reset → tap', (
      tester,
    ) async {
      await savePreference(enabled);

      budgets.categories = [
        groceries(
          month: '2026-09',
          actual: 180000,
          status: BudgetCategoryStatus.nearFull,
        ),
      ];
      await engine().run();
      expect(scheduler.delivered, hasLength(1));
      expect(scheduler.delivered.single.notification.body, contains('90'));
      expect(
        scheduler.delivered.single.notification.body,
        contains('Groceries'),
      );

      budgets.categories = [
        groceries(
          month: '2026-09',
          actual: 220000,
          status: BudgetCategoryStatus.overBudget,
        ),
      ];
      await engine().run();
      expect(scheduler.delivered, hasLength(2), reason: 'distinct exceeded');

      // SC-003: an unchanged band across repeated passes notifies once.
      for (var i = 0; i < 3; i++) {
        clock.current = clock.current.add(const Duration(days: 1));
        await engine().run();
      }
      expect(scheduler.delivered, hasLength(2));

      // FR-016: a new budget month resets the band.
      clock.current = DateTime(2026, 10, 20, 12);
      budgets.categories = [
        groceries(
          month: '2026-10',
          actual: 185000,
          status: BudgetCategoryStatus.nearFull,
        ),
      ];
      await engine().run();
      expect(scheduler.delivered, hasLength(3));

      // FR-014: the tap resolves to that month's category.
      final target = scheduler.delivered.last.notification.deepLinkTarget;
      budgets.existing = {'groceries@2026-10'};
      expect(
        await getIt<HandleNotificationTap>()(target),
        const BudgetCategoryDestination(
          categoryId: 'groceries',
          month: '2026-10',
        ),
      );
      budgets.existing = {};
      expect(
        await getIt<HandleNotificationTap>()(target),
        const SourceNoLongerExists(NotificationSourceType.budgetCategory),
      );
    });

    testWidgets('budget warnings off → no budget notification', (tester) async {
      await savePreference(enabled.copyWith(budgetWarningsEnabled: false));
      budgets.categories = [
        groceries(
          month: '2026-09',
          actual: 220000,
          status: BudgetCategoryStatus.overBudget,
        ),
      ];
      await engine().run();
      expect(scheduler.delivered, isEmpty);
    });
  });

  group('US2 savings-goal check-ins', () {
    SavingsGoalSnapshot fund({required int current, bool achieved = false}) =>
        SavingsGoalSnapshot(
          goalId: 'emergency',
          name: 'Emergency Fund',
          targetAmountMinorUnits: 10000000,
          currentAmountMinorUnits: current,
          isAchieved: achieved,
          createdAt: DateTime(2026, 3, 1),
          monthlyContributionMinorUnits: 500000,
        );

    testWidgets('baseline → ahead → achieved once → tap', (tester) async {
      await savePreference(enabled);

      // Six months in at 5,000/month: 10,000 is four months behind. The
      // first observation only records a baseline (no spurious alert).
      savings.goals = [fund(current: 1000000)];
      await engine().run();
      expect(scheduler.delivered, isEmpty);

      savings.goals = [fund(current: 5000000)];
      await engine().run();
      expect(scheduler.delivered, hasLength(1));
      expect(
        scheduler.delivered.single.notification.title,
        contains('Emergency Fund'),
      );

      savings.goals = [fund(current: 10000000, achieved: true)];
      await engine().run();
      await engine().run();
      expect(scheduler.delivered, hasLength(2), reason: 'achieved fires once');

      final target = scheduler.delivered.last.notification.deepLinkTarget;
      savings.existing = {'emergency'};
      expect(
        await getIt<HandleNotificationTap>()(target),
        const SavingsGoalDestination(goalId: 'emergency'),
      );
    });

    testWidgets('an already-achieved goal never alerts on enable', (
      tester,
    ) async {
      await savePreference(enabled);
      savings.goals = [fund(current: 10000000, achieved: true)];
      await engine().run();
      await engine().run();
      expect(scheduler.delivered, isEmpty);
    });
  });

  group('US3 control', () {
    testWidgets('quiet hours defer delivery to the window end', (tester) async {
      await savePreference(
        enabled.copyWith(quietHoursStart: 22 * 60, quietHoursEnd: 8 * 60),
      );
      clock.current = DateTime(2026, 9, 15, 23, 30);
      budgets.categories = [
        groceries(
          month: '2026-09',
          actual: 220000,
          status: BudgetCategoryStatus.overBudget,
        ),
      ];
      await engine().run();

      expect(scheduler.delivered, hasLength(1));
      expect(scheduler.delivered.single.deliverAt, DateTime(2026, 9, 16, 8));
    });

    testWidgets('disabled → nothing delivered, sources never read', (
      tester,
    ) async {
      await savePreference(enabled.copyWith(isEnabled: false));
      budgets
        ..reads = 0
        ..categories = [
          groceries(
            month: '2026-09',
            actual: 220000,
            status: BudgetCategoryStatus.overBudget,
          ),
        ];
      await engine().run();
      expect(scheduler.delivered, isEmpty);
      expect(budgets.reads, 0);
    });

    testWidgets('settings: off by default, enable asks permission, '
        'denied shows the banner', (tester) async {
      scheduler.permissionGranted = false;
      appRouter.go('/settings/notifications');
      await tester.pumpWidget(const DaftaryApp());
      await tester.pumpAndSettle();

      final master = find.byKey(const Key('notification_master_switch'));
      expect(tester.widget<SwitchListTile>(master).value, isFalse);
      expect(scheduler.permissionRequests, 0, reason: 'never at startup');

      await tester.tap(master);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(scheduler.permissionRequests, 1);
      expect(tester.widget<SwitchListTile>(master).value, isTrue);
      expect(find.byKey(PermissionDeniedBanner.rootKey), findsOneWidget);
    });
  });
}

class _FakeClock implements AppClock {
  DateTime current = DateTime(2026, 9, 15, 12);

  @override
  DateTime now() => current;
}

class _FakeBudgetSource implements BudgetInsightsSource {
  List<BudgetCategorySnapshot> categories = [];
  Set<String> existing = {};
  int reads = 0;

  @override
  Future<Either<Failure, List<BudgetCategorySnapshot>>>
  currentMonthCategories() async {
    reads++;
    return Right(categories);
  }

  @override
  Future<bool> categoryBudgetExists(String categoryId, String month) async =>
      existing.contains('$categoryId@$month');
}

class _FakeSavingsSource implements SavingsInsightsSource {
  List<SavingsGoalSnapshot> goals = [];
  Set<String> existing = {};

  @override
  Future<Either<Failure, List<SavingsGoalSnapshot>>> activeGoals() async =>
      Right(goals);

  @override
  Future<bool> goalExists(String goalId) async => existing.contains(goalId);
}

class _Delivery {
  const _Delivery(this.notification, this.deliverAt);

  final ComposedNotification notification;
  final DateTime? deliverAt;
}

class _RecordingScheduler implements NotificationScheduler {
  final List<_Delivery> delivered = [];
  bool permissionGranted = true;
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<Either<Failure, Unit>> scheduleOrDeliver(
    ComposedNotification notification, {
    DateTime? deliverAt,
  }) async {
    delivered.add(_Delivery(notification, deliverAt));
    return const Right(unit);
  }

  @override
  Stream<NotificationDeepLinkTarget> get taps => const Stream.empty();

  @override
  Future<NotificationDeepLinkTarget?> launchTarget() async => null;
}
