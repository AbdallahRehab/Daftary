import 'dart:async';

import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/notification_tap_router.dart';
import 'package:daftary/features/insights_notifications/domain/entities/composed_notification.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:daftary/features/insights_notifications/domain/services/notification_scheduler.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/handle_notification_tap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

class _MockHandleTap extends Mock implements HandleNotificationTap {}

/// T028/T034 — tapped notifications reach the right route, or a graceful
/// "no longer exists" message (FR-014).
void main() {
  const budgetTarget = NotificationDeepLinkTarget(
    type: NotificationSourceType.budgetCategory,
    id: 'food',
    applicablePeriod: '2026-09',
  );
  const goalTarget = NotificationDeepLinkTarget(
    type: NotificationSourceType.savingsGoal,
    id: 'g1',
  );

  late _MockScheduler scheduler;
  late _MockHandleTap handleTap;
  late StreamController<NotificationDeepLinkTarget> taps;
  late GoRouter router;
  late NotificationTapRouter tapRouter;

  setUpAll(() => registerFallbackValue(goalTarget));

  setUp(() {
    scheduler = _MockScheduler();
    handleTap = _MockHandleTap();
    taps = StreamController<NotificationDeepLinkTarget>.broadcast();
    when(() => scheduler.taps).thenAnswer((_) => taps.stream);
    when(() => scheduler.launchTarget()).thenAnswer((_) async => null);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/budgets/:month',
          builder: (_, state) =>
              Scaffold(body: Text('budget ${state.pathParameters['month']}')),
        ),
        GoRoute(
          path: '/savings/:goalId',
          builder: (_, state) =>
              Scaffold(body: Text('goal ${state.pathParameters['goalId']}')),
        ),
      ],
    );
    tapRouter = NotificationTapRouter(scheduler, handleTap);
  });

  tearDown(() async {
    await tapRouter.dispose();
    await taps.close();
  });

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );

  testWidgets('a budget tap opens that month of budgets', (tester) async {
    when(() => handleTap(budgetTarget)).thenAnswer(
      (_) async =>
          const BudgetCategoryDestination(categoryId: 'food', month: '2026-09'),
    );
    await pumpApp(tester);
    await tapRouter.start(router);

    taps.add(budgetTarget);
    await tester.pumpAndSettle();

    expect(find.text('budget 2026-09'), findsOneWidget);
  });

  testWidgets('a cold-start goal tap opens the goal', (tester) async {
    when(() => scheduler.launchTarget()).thenAnswer((_) async => goalTarget);
    when(
      () => handleTap(goalTarget),
    ).thenAnswer((_) async => const SavingsGoalDestination(goalId: 'g1'));
    await pumpApp(tester);

    await tapRouter.start(router);
    await tester.pumpAndSettle();

    expect(find.text('goal g1'), findsOneWidget);
  });

  testWidgets('a stale tap stays put and says the source is gone', (
    tester,
  ) async {
    when(() => handleTap(goalTarget)).thenAnswer(
      (_) async =>
          const SourceNoLongerExists(NotificationSourceType.savingsGoal),
    );
    await pumpApp(tester);
    await tapRouter.start(router);

    taps.add(goalTarget);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('That savings goal no longer exists.'), findsOneWidget);
  });

  test('start is idempotent', () async {
    await tapRouter.start(router);
    await tapRouter.start(router);
    verify(() => scheduler.launchTarget()).called(1);
  });
}
