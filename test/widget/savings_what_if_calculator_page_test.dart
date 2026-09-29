import 'dart:async';

import 'package:daftary/core/date/app_date_formatter.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_detail.dart';
import 'package:daftary/features/savings/domain/entities/what_if_mode.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/apply_what_if_scenario.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_completion_date.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_monthly_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/edit_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/presentation/cubit/what_if_cubit.dart';
import 'package:daftary/features/savings/presentation/pages/what_if_calculator_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../features/savings/helpers/savings_harness.dart';
import '../features/savings/helpers/savings_test_data.dart';

/// T047 — `WhatIfCalculatorPage`: both input modes (US3 AS-1/2), the
/// validation messages (FR-016), apply and cancel (FR-015), and the
/// achieved goal's "nothing left to plan" state (FR-016).
void main() {
  late MockSavingsRepository repository;
  late WhatIfCubit cubit;
  final en = lookupAppLocalizations(const Locale('en'));
  // Built lazily: date symbols load once the app's localizations do.
  String date(DateTime value) => AppDateFormatter(locale: 'en').format(value);

  // 65,000 EGP left at 5,000/month: 13 months today.
  final goal = testGoal(target: 10000000, monthly: 500000);
  final detail = testDetail(goal, history: [testEntry(amount: 3500000)]);

  void stubEdit() => when(
    () => repository.editSavingsGoal(
      goalId: any(named: 'goalId'),
      name: any(named: 'name'),
      type: any(named: 'type'),
      targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
      monthlyContributionMinorUnits: any(
        named: 'monthlyContributionMinorUnits',
      ),
      targetDate: any(named: 'targetDate'),
    ),
  ).thenAnswer((_) async => Right(goal));

  void verifyNoEdit() => verifyNever(
    () => repository.editSavingsGoal(
      goalId: any(named: 'goalId'),
      name: any(named: 'name'),
      type: any(named: 'type'),
      targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
      monthlyContributionMinorUnits: any(
        named: 'monthlyContributionMinorUnits',
      ),
      targetDate: any(named: 'targetDate'),
    ),
  );

  setUp(() {
    repository = MockSavingsRepository();
    final getDetail = GetGoalDetail(repository);
    final clock = SettableClock(testToday);
    const calculator = DefaultSavingsCalculator();
    cubit = WhatIfCubit(
      getDetail,
      CalculateWhatIfMonthlyContribution(getDetail, calculator, clock),
      CalculateWhatIfCompletionDate(getDetail, calculator, clock),
      ApplyWhatIfScenario(getDetail, EditSavingsGoal(repository)),
    );
  });

  tearDown(() => cubit.close());

  /// Opens the calculator on top of a stand-in goal page, so apply and
  /// cancel can be seen returning to it.
  Future<void> pump(
    WidgetTester tester,
    SavingsGoalDetail shown, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view
      ..physicalSize = const Size(900, 2600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(shown));
    final router = GoRouter(
      initialLocation: '/goal',
      routes: [
        GoRoute(
          path: '/goal',
          builder: (context, state) => const Scaffold(body: Text('goal page')),
        ),
        GoRoute(
          path: '/what-if',
          builder: (context, state) => BlocProvider.value(
            value: cubit,
            child: const WhatIfCalculatorView(),
          ),
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
    unawaited(cubit.load('g1'));
    unawaited(router.push('/what-if'));
    await tester.pumpAndSettle();
  }

  Future<void> enterMonthly(WidgetTester tester, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('savingsWhatIfMonthlyField')),
        matching: find.byType(TextField),
      ),
      text,
    );
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the real plan, and a monthly what-if answers US3 AS-1 '
      'without touching the goal', (tester) async {
    await pump(tester, detail);

    expect(
      find.text(en.savingsWhatIfCurrentRemaining('65,000.00 EGP')),
      findsOneWidget,
    );
    expect(
      find.text(en.savingsWhatIfCurrentMonthly('5,000.00 EGP')),
      findsOneWidget,
    );
    expect(find.text(en.savingsWhatIfPreviewNotice), findsOneWidget);

    await enterMonthly(tester, '6000');
    await tapKey(tester, 'savingsWhatIfCalculate');

    expect(
      find.text(
        en.savingsWhatIfResultByMonthly(
          '6,000.00 EGP',
          '11 months',
          date(DateTime(2027, 8, 15)),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(en.savingsWhatIfCompareSooner('2 months')),
      findsOneWidget,
    );
    expect(
      find.text(en.savingsWhatIfApplyExplainMonthly('6,000.00 EGP')),
      findsOneWidget,
    );
    verifyNoEdit();
  });

  testWidgets('the target-date mode answers US3 AS-2', (tester) async {
    await pump(tester, detail);

    await tapKey(tester, 'savingsWhatIfModeDate');
    expect(
      find.byKey(const ValueKey('savingsWhatIfTargetDateField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('savingsWhatIfMonthlyField')),
      findsNothing,
    );
    cubit.targetDateChanged(DateTime(2027, 7, 15));
    await tester.pump();
    await tapKey(tester, 'savingsWhatIfCalculate');

    final dateText = date(DateTime(2027, 7, 15));
    expect(
      find.text(en.savingsWhatIfResultByDate(dateText, '6,500.00 EGP')),
      findsOneWidget,
    );
    expect(
      find.text(en.savingsWhatIfCompareMore('1,500.00 EGP')),
      findsOneWidget,
    );
    expect(
      find.text(en.savingsWhatIfApplyExplainDate(dateText, '6,500.00 EGP')),
      findsOneWidget,
    );
    expect(cubit.state.mode, WhatIfMode.targetDate);
  });

  testWidgets('invalid inputs show clear messages, not a result (FR-016)', (
    tester,
  ) async {
    await pump(tester, detail);

    await enterMonthly(tester, '0');
    await tapKey(tester, 'savingsWhatIfCalculate');
    expect(find.text(en.savingsWhatIfMonthlyInvalidError), findsOneWidget);
    expect(find.byKey(const ValueKey('savingsWhatIfResult')), findsNothing);

    await tapKey(tester, 'savingsWhatIfModeDate');
    cubit.targetDateChanged(testToday);
    await tester.pump();
    await tapKey(tester, 'savingsWhatIfCalculate');
    expect(find.text(en.savingsInvalidTargetDateError), findsOneWidget);
    expect(find.byKey(const ValueKey('savingsWhatIfResult')), findsNothing);
  });

  testWidgets('apply is disabled until there is a result', (tester) async {
    await pump(tester, detail);

    final apply = find.byKey(const ValueKey('savingsWhatIfApply'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    verifyNoEdit();
    expect(find.text('goal page'), findsNothing);
  });

  testWidgets('apply writes the scenario and returns to the goal (FR-015)', (
    tester,
  ) async {
    stubEdit();
    await pump(tester, detail);
    await enterMonthly(tester, '6000');
    await tapKey(tester, 'savingsWhatIfCalculate');

    await tapKey(tester, 'savingsWhatIfApply');

    verify(
      () => repository.editSavingsGoal(
        goalId: 'g1',
        name: goal.name,
        type: goal.type,
        targetAmountMinorUnits: goal.targetAmountMinorUnits,
        monthlyContributionMinorUnits: 600000,
        targetDate: goal.targetDate,
      ),
    ).called(1);
    expect(find.text('goal page'), findsOneWidget);
    expect(find.text(en.savingsWhatIfAppliedMessage), findsOneWidget);
  });

  testWidgets('cancel returns to the goal and changes nothing', (tester) async {
    await pump(tester, detail);
    await enterMonthly(tester, '6000');
    await tapKey(tester, 'savingsWhatIfCalculate');

    await tapKey(tester, 'savingsWhatIfCancel');

    expect(find.text('goal page'), findsOneWidget);
    verifyNoEdit();
  });

  testWidgets('an achieved goal explains there is nothing left to plan '
      '(FR-016), with no calculator', (tester) async {
    await pump(
      tester,
      testDetail(
        testGoal(target: 1000000, monthly: 100000),
        history: [testEntry(amount: 1000000)],
      ),
    );

    expect(find.text(en.savingsWhatIfAchievedTitle), findsOneWidget);
    expect(find.text(en.savingsWhatIfAchievedMessage), findsOneWidget);
    expect(find.byKey(const ValueKey('savingsWhatIfCalculate')), findsNothing);
    expect(find.byKey(const ValueKey('savingsWhatIfApply')), findsNothing);

    await tester.tap(find.text(en.savingsWhatIfBackAction));
    await tester.pumpAndSettle();
    expect(find.text('goal page'), findsOneWidget);
  });

  testWidgets('renders in Arabic', (tester) async {
    await pump(tester, detail, locale: const Locale('ar'));
    final ar = lookupAppLocalizations(const Locale('ar'));

    expect(find.text(ar.savingsWhatIfTitle), findsOneWidget);
    expect(find.text(ar.savingsWhatIfModeMonthly), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
