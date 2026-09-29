import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/features/savings/domain/usecases/archive_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/delete_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/restore_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/watch_savings_overview.dart';
import 'package:daftary/features/savings/presentation/cubit/archived_goals_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/savings_goal_actions_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/savings_overview_cubit.dart';
import 'package:daftary/features/savings/presentation/pages/archived_goals_page.dart';
import 'package:daftary/features/savings/presentation/pages/savings_overview_page.dart';
import 'package:daftary/features/savings/presentation/savings_routes.dart';
import 'package:daftary/features/savings/presentation/widgets/savings_overview_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../features/savings/helpers/savings_test_data.dart';
import '../helpers/watch_stubs.dart';

/// T059 — `SavingsOverviewPage` (and `ArchivedGoalsPage`): FR-023's empty
/// state with a create-first-goal action, the FR-019 incomplete total
/// naming the missing rate, and FR-021's delete-blocked → offer-archive
/// dialog.
void main() {
  late MockSavingsRepository repository;
  late FakeTableChanges changes;
  late SavingsGoalActionsCubit actions;
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));

  final egpGoal = testGoal(id: 'g1', name: 'Emergency', target: 1000000);
  final usdGoal = testGoal(
    id: 'g2',
    name: 'Trip',
    currency: Currency.usd,
    target: 100000,
  );

  setUp(() {
    repository = MockSavingsRepository();
    changes = FakeTableChanges();
    stubSavingsWatches(repository, changes);
    actions = SavingsGoalActionsCubit(
      ArchiveSavingsGoal(repository),
      RestoreSavingsGoal(repository),
      DeleteSavingsGoal(repository),
    );
  });

  tearDown(() async {
    await actions.close();
    await changes.close();
  });

  void answer(List<GoalOverviewLine> lines) =>
      when(
        () => repository.getSavingsOverview(
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(SavingsOverview(goals: lines, primaryCurrency: Currency.egp)),
      );

  /// Pumps [page] at `/savings` (or [initial]) in a router that has stub
  /// pages for the paths the overview navigates to.
  Future<GoRouter> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    String initial = SavingsRoutes.overview,
  }) async {
    tester.view
      ..physicalSize = const Size(900, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final overviewCubit = SavingsOverviewCubit(WatchSavingsOverview(repository))
      ..subscribe();
    final archivedCubit = ArchivedGoalsCubit(WatchSavingsOverview(repository))
      ..subscribe();
    addTearDown(overviewCubit.close);
    addTearDown(archivedCubit.close);
    Widget stub(GoRouterState state) =>
        Scaffold(body: Text('stub:${state.uri}'));
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: SavingsRoutes.overview,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: overviewCubit),
              BlocProvider.value(value: actions),
            ],
            child: const SavingsOverviewView(),
          ),
        ),
        GoRoute(
          path: SavingsRoutes.archived,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: archivedCubit),
              BlocProvider.value(value: actions),
            ],
            child: const ArchivedGoalsView(),
          ),
        ),
        GoRoute(
          path: SavingsRoutes.newGoal,
          builder: (context, state) => stub(state),
        ),
        GoRoute(
          path: '/savings/:goalId',
          builder: (context, state) => stub(state),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('FR-023: no goals shows the friendly empty state, whose '
      'action opens the create-goal form', (tester) async {
    answer(const []);
    await pump(tester);

    expect(find.text(en.savingsOverviewEmptyTitle), findsOneWidget);
    expect(find.text(en.savingsOverviewEmptyMessage), findsOneWidget);
    expect(find.byType(SavingsOverviewSummaryCard), findsNothing);

    await tester.tap(find.text(en.savingsOverviewEmptyAction));
    await tester.pumpAndSettle();

    expect(find.text('stub:${SavingsRoutes.newGoal}'), findsOneWidget);
  });

  testWidgets('US4 AS-1/AS-6: every goal is listed with its own-currency '
      'progress, and the total is in the primary currency', (tester) async {
    answer([
      testOverviewLine(egpGoal, saved: 250000),
      testOverviewLine(usdGoal, saved: 10000, converted: 500000),
    ]);
    await pump(tester);

    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('Trip'), findsOneWidget);
    expect(find.textContaining('USD'), findsWidgets);
    expect(find.byKey(const ValueKey('savingsOverviewTotal')), findsOneWidget);
    final total = tester.widget<Text>(
      find.byKey(const ValueKey('savingsOverviewTotal')),
    );
    expect(total.data, contains('7,500.00'));
    expect(total.data, contains('EGP'));
    expect(find.byKey(SavingsOverviewSummaryCard.incompleteKey), findsNothing);
    expect(find.text(en.savingsOverviewNewGoalAction), findsOneWidget);

    await tester.tap(find.text('Trip'));
    await tester.pumpAndSettle();
    expect(find.text('stub:/savings/g2'), findsOneWidget);
  });

  testWidgets('US4 AS-7: without the USD rate the total is marked '
      'incomplete, naming USD, and the USD goal says it is not counted', (
    tester,
  ) async {
    answer([
      testOverviewLine(egpGoal, saved: 250000),
      testOverviewLine(usdGoal, saved: 10000, missing: [Currency.usd]),
    ]);
    await pump(tester);

    expect(
      find.byKey(SavingsOverviewSummaryCard.incompleteKey),
      findsOneWidget,
    );
    expect(find.text(en.savingsOverviewIncompleteTitle), findsOneWidget);
    expect(
      find.text(en.savingsOverviewIncompleteMessage('USD')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('savingsOverviewBlocked-g2')),
      findsOneWidget,
    );
    expect(find.text(en.savingsOverviewNotInTotal('USD')), findsOneWidget);
    // The total covers only the EGP goal.
    final total = tester.widget<Text>(
      find.byKey(const ValueKey('savingsOverviewTotal')),
    );
    expect(total.data, contains('2,500.00'));
  });

  testWidgets('FR-021: deleting a goal with history is blocked and offers '
      'to archive it instead', (tester) async {
    answer([testOverviewLine(egpGoal, saved: 250000)]);
    when(
      () => repository.deleteSavingsGoal('g1'),
    ).thenAnswer((_) async => const Left(GoalHasHistoryFailure('history')));
    when(
      () => repository.archiveSavingsGoal('g1'),
    ).thenAnswer((_) async => const Right(unit));
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('savingsGoalMenu-g1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.savingsDeleteAction));
    await tester.pumpAndSettle();
    expect(
      find.text(en.savingsDeleteConfirmTitle('Emergency')),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, en.savingsDeleteAction));
    await tester.pumpAndSettle();

    expect(find.text(en.savingsDeleteBlockedTitle), findsOneWidget);
    expect(find.text(en.savingsDeleteBlockedMessage), findsOneWidget);
    verifyNever(() => repository.archiveSavingsGoal(any()));

    await tester.tap(find.text(en.savingsDeleteBlockedArchiveAction));
    await tester.pumpAndSettle();

    verify(() => repository.archiveSavingsGoal('g1')).called(1);
    expect(find.text(en.savingsArchiveDoneMessage), findsOneWidget);
  });

  testWidgets('US4 AS-4: a goal with no history is deleted after the '
      'confirmation', (tester) async {
    answer([testOverviewLine(egpGoal)]);
    when(
      () => repository.deleteSavingsGoal('g1'),
    ).thenAnswer((_) async => const Right(unit));
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('savingsGoalMenu-g1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.savingsDeleteAction));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.savingsDeleteAction));
    await tester.pumpAndSettle();

    verify(() => repository.deleteSavingsGoal('g1')).called(1);
    expect(find.text(en.savingsDeleteDoneMessage), findsOneWidget);
    expect(find.text(en.savingsDeleteBlockedTitle), findsNothing);
  });

  testWidgets('the archived list shows only archived goals, each with a '
      'restore action', (tester) async {
    final paused = testGoal(id: 'p', name: 'Paused', isArchived: true);
    answer([testOverviewLine(egpGoal), testOverviewLine(paused, saved: 100)]);
    when(
      () => repository.restoreSavingsGoal('p'),
    ).thenAnswer((_) async => const Right(unit));
    await pump(tester, initial: SavingsRoutes.archived);

    expect(find.text(en.savingsArchiveTitle), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Emergency'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('savingsRestore-p')));
    await tester.pumpAndSettle();

    verify(() => repository.restoreSavingsGoal('p')).called(1);
    expect(find.text(en.savingsArchiveRestoredMessage), findsOneWidget);
  });

  testWidgets('an empty archive explains itself', (tester) async {
    answer([testOverviewLine(egpGoal)]);
    await pump(tester, initial: SavingsRoutes.archived);

    expect(find.text(en.savingsArchiveEmptyTitle), findsOneWidget);
  });

  testWidgets('Arabic RTL: the overview and its incomplete marker render '
      'without overflow', (tester) async {
    answer([
      testOverviewLine(egpGoal, saved: 250000),
      testOverviewLine(usdGoal, saved: 10000, missing: [Currency.usd]),
    ]);
    await pump(tester, locale: const Locale('ar'));

    expect(find.text(ar.savingsOverviewTitle), findsOneWidget);
    expect(find.text(ar.savingsOverviewIncompleteTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
