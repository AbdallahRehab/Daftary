import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/design_system/currency_picker.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/currency/domain/repositories/currency_repository.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_detail.dart';
import 'package:daftary/features/savings/domain/repositories/savings_repository.dart';
import 'package:daftary/features/savings/presentation/cubit/what_if_cubit.dart';
import 'package:daftary/features/savings/presentation/pages/what_if_calculator_page.dart';
import 'package:daftary/features/savings/presentation/savings_routes.dart';
import 'package:daftary/features/savings/presentation/widgets/achieved_goal_badge.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// T073 — end-to-end coverage of 011 Savings Goals against the real app:
/// real DI, the real drift schema (on a fresh in-memory database, never the
/// device's own file), the real repository, use cases, cubits and screens —
/// following quickstart.md scenarios 1-6:
///  1. create (contribution mode, starting amount, target-date mode, no
///     plan), the zero-target block, and edit (US1);
///  2. log / withdraw / edit / delete with live recompute, the
///     withdrawal-exceeds-balance block, the achieved transition and its
///     reversal (US2);
///  3. what-if in both directions, validation, explicit apply, and the
///     achieved goal's "nothing to plan" state (US3);
///  4. the multi-goal overview, archive/restore and delete protection (US4);
///  5. Arabic RTL + dark mode + Liquid Glass on the achieved goal and the
///     calculator (FR-025);
///  6. foreign-currency conversion, the missing-rate block naming the
///     currency, the incomplete total, and no currency field on edit.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await configureDependencies();
    getIt
      ..unregister<db.AppDatabase>()
      ..registerSingleton<db.AppDatabase>(
        db.AppDatabase.forTesting(NativeDatabase.memory()),
      );
    // As `main()` does: onboarding done (fresh database), then startup.
    await getIt<OnboardingRepository>().completeOnboarding();
    await getIt<AppStartupCubit>().start();
  });

  setUp(() async {
    final database = getIt<db.AppDatabase>();
    await database.delete(database.savingsContributionAudits).go();
    await database.delete(database.savingsContributions).go();
    await database.delete(database.savingsGoals).go();
    await database.delete(database.exchangeRates).go();
    await database.delete(database.primaryCurrencySettings).go();
  });

  SavingsRepository savings() => getIt<SavingsRepository>();
  CurrencyRepository currency() => getIt<CurrencyRepository>();

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  var seq = 0;
  String key(String base) =>
      'it-savings-$base-${DateTime.now().microsecondsSinceEpoch}-${seq++}';

  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<SavingsGoal> createGoal({
    String name = 'Emergency Fund',
    Currency goalCurrency = Currency.egp,
    int target = 10000000,
    int? starting,
    int? monthly,
    DateTime? targetDate,
  }) async => (await savings().createSavingsGoal(
    idempotencyKey: key('goal'),
    name: name,
    currency: goalCurrency,
    targetAmountMinorUnits: target,
    startingAmountMinorUnits: starting,
    monthlyContributionMinorUnits: monthly,
    targetDate: targetDate,
  )).getOrElse((f) => fail('createSavingsGoal: $f'));

  Future<SavingsGoalDetail> detail(String goalId) async =>
      (await savings().getGoalDetail(
        goalId,
      )).getOrElse((f) => fail('getGoalDetail: $f'));

  Future<void> open(WidgetTester tester, String location) async {
    // `appRouter` is a module-level singleton that keeps wherever the
    // previous test left it — reset so each test starts on a known screen.
    appRouter.go(location);
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    // Lazy lists only build what is on screen: scroll a missing target in.
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String fieldKey, String text) async {
    final field = find.descendant(
      of: find.byKey(ValueKey(fieldKey)),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    // Focus it first: right after a submit unfocused the form, entering
    // text straight away can be dropped.
    await tester.tap(field, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String submitKey) async {
    // The keyboard can still cover the button right after typing.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(ValueKey(submitKey)));
  }

  /// Opens the log form from the goal page, enters [amount] and saves.
  Future<void> logFromGoalPage(
    WidgetTester tester,
    String amount, {
    bool withdrawal = false,
  }) async {
    await tapVisible(
      tester,
      find.byKey(
        ValueKey(
          withdrawal ? 'savingsLogWithdrawal' : 'savingsLogContribution',
        ),
      ),
    );
    await enter(tester, 'savingsEntryAmountField', amount);
    await submit(tester, 'savingsEntrySubmit');
  }

  Finder saved(String text) => find.descendant(
    of: find.byKey(const ValueKey('savingsSavedFigure')),
    matching: find.text(text),
  );

  Finder remaining(String text) => find.descendant(
    of: find.byKey(const ValueKey('savingsRemainingFigure')),
    matching: find.text(text),
  );

  // ---------------------------------------------------------------------
  // Scenario 1 — create and edit (US1)
  // ---------------------------------------------------------------------

  testWidgets('scenario 1: create from the empty state with a monthly '
      'contribution, with a starting amount, by target date and with no '
      'plan; a zero target is blocked; edit updates the goal', (tester) async {
    final l10n = await english();
    await open(tester, SavingsRoutes.overview);

    // 4.5 — the empty state carries the create action.
    expect(find.text(l10n.savingsOverviewEmptyTitle), findsOneWidget);
    await tapVisible(tester, find.text(l10n.savingsOverviewEmptyAction));

    // 1.3 — a target of 0 is blocked with a clear message.
    await enter(tester, 'savingsGoalNameField', 'Emergency Fund');
    await enter(tester, 'savingsGoalTargetField', '0');
    await submit(tester, 'savingsGoalSubmit');
    expect(find.text(l10n.savingsGoalTargetInvalidError), findsOneWidget);
    final none = (await savings().getSavingsOverview()).getOrElse(
      (f) => fail('getSavingsOverview: $f'),
    );
    expect(none.goals, isEmpty);

    // 1.1 — 100,000 at 5,000/month: 20 months.
    await enter(tester, 'savingsGoalTargetField', '100000');
    await enter(tester, 'savingsGoalMonthlyField', '5000');
    expect(find.textContaining('20 months'), findsWidgets);
    await submit(tester, 'savingsGoalSubmit');

    // The new goal's page replaces the form.
    expect(find.text('Emergency Fund'), findsWidgets);
    expect(remaining('100,000.00 EGP'), findsOneWidget);
    expect(find.textContaining('20 months'), findsWidgets);

    // 1.2 — with 35,000 already saved: 65,000 left, 13 months.
    await open(tester, SavingsRoutes.newGoal);
    await enter(tester, 'savingsGoalNameField', 'Emergency Fund 2');
    await enter(tester, 'savingsGoalTargetField', '100000');
    await enter(tester, 'savingsGoalStartingField', '35000');
    await enter(tester, 'savingsGoalMonthlyField', '5000');
    await submit(tester, 'savingsGoalSubmit');
    expect(remaining('65,000.00 EGP'), findsOneWidget);
    expect(find.textContaining('13 months'), findsWidgets);

    // 1.4 — a target date instead: the required monthly amount is shown.
    final byDate = await createGoal(
      name: 'By date',
      target: 10000000,
      targetDate: DateTime(today().year, today().month + 10, today().day),
    );
    await open(tester, SavingsRoutes.goal(byDate.id));
    expect(find.byKey(const ValueKey('savingsRequiredLine')), findsOneWidget);
    expect(find.textContaining('10,000.00 EGP a month'), findsOneWidget);

    // 1.5 — neither: saved, with the prompt to set a plan.
    final noPlan = await createGoal(name: 'No plan', target: 500000);
    await open(tester, SavingsRoutes.goal(noPlan.id));
    expect(find.text(l10n.savingsNoEstimatePrompt), findsOneWidget);

    // Edit (FR-029): rename and raise the target.
    await tapVisible(tester, find.byTooltip(l10n.savingsGoalEditAction));
    await enter(tester, 'savingsGoalNameField', 'Laptop');
    await enter(tester, 'savingsGoalTargetField', '8000');
    await submit(tester, 'savingsGoalSubmit');
    final edited = (await detail(noPlan.id)).goal;
    expect(edited.name, 'Laptop');
    expect(edited.targetAmountMinorUnits, 800000);
    expect(find.text('Laptop'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // Scenario 2 — log contributions and track progress (US2)
  // ---------------------------------------------------------------------

  testWidgets('scenario 2: log, withdraw, over-withdrawal blocked, achieved '
      'and back, and edit/delete recompute live', (tester) async {
    final l10n = await english();
    final goal = await createGoal(starting: 3500000, monthly: 500000);
    await open(tester, SavingsRoutes.goal(goal.id));
    expect(saved('35,000.00 EGP'), findsOneWidget);

    // 2.1 — +5,000 → 40,000; remaining and estimate update.
    await logFromGoalPage(tester, '5000');
    expect(saved('40,000.00 EGP'), findsOneWidget);
    expect(remaining('60,000.00 EGP'), findsOneWidget);
    expect(find.textContaining('12 months'), findsWidgets);

    // 2.2 — a one-off bonus.
    await logFromGoalPage(tester, '10000');
    expect(saved('50,000.00 EGP'), findsOneWidget);

    // 2.3 — a withdrawal, shown distinctly in the history.
    await logFromGoalPage(tester, '3000', withdrawal: true);
    expect(saved('47,000.00 EGP'), findsOneWidget);
    expect(find.text(l10n.savingsEntryWithdrawal), findsWidgets);
    expect(find.text('−3,000.00 EGP'), findsOneWidget);

    // 2.4 — withdrawing more than the balance is blocked and explained.
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsLogWithdrawal')),
    );
    await enter(tester, 'savingsEntryAmountField', '1000000');
    await submit(tester, 'savingsEntrySubmit');
    expect(
      find.text(l10n.savingsWithdrawalExceedsBalanceError),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(saved('47,000.00 EGP'), findsOneWidget);
    expect((await detail(goal.id)).history, hasLength(4));

    // 2.5 — reaching the target: celebratory, not a warning.
    await logFromGoalPage(tester, '53000');
    expect(find.byType(AchievedGoalBadge), findsOneWidget);
    expect(find.text(l10n.savingsGoalAchievedBadge), findsOneWidget);

    // 2.6 — edit an earlier entry and delete another: both recompute at
    // once on the open page (a withdrawal, then the achieving entry).
    final history = (await detail(goal.id)).history;
    final bonus = history.firstWhere((e) => e.amountMinorUnits == 1000000);
    final achieving = history.firstWhere((e) => e.amountMinorUnits == 5300000);
    final edited = await savings().editContribution(
      contributionId: bonus.id,
      amount: Money.egp(800000),
      date: bonus.date,
    );
    expect(edited.isRight(), isTrue);
    await tester.pumpAndSettle();
    expect(saved('98,000.00 EGP'), findsOneWidget);
    // The achieved state reverses with the figures (US2 edge case).
    expect(find.byType(AchievedGoalBadge), findsNothing);

    expect(
      (await savings().deleteContribution(achieving.id)).isRight(),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(saved('45,000.00 EGP'), findsOneWidget);
    expect(remaining('55,000.00 EGP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // Scenario 3 — what-if (US3)
  // ---------------------------------------------------------------------

  testWidgets('scenario 3: what-if by monthly amount and by date never '
      'changes the goal until applied; invalid inputs are explained; an '
      'achieved goal has nothing to plan', (tester) async {
    final l10n = await english();
    final goal = await createGoal(starting: 3500000, monthly: 500000);
    await open(tester, SavingsRoutes.goal(goal.id));
    await tapVisible(tester, find.byKey(const ValueKey('savingsWhatIfEntry')));

    // 3.4 — a monthly amount of 0 is rejected.
    await enter(tester, 'savingsWhatIfMonthlyField', '0');
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsWhatIfCalculate')),
    );
    expect(find.text(l10n.savingsWhatIfMonthlyInvalidError), findsOneWidget);

    // 3.1 — 6,000/month: 11 months; the goal is untouched.
    await enter(tester, 'savingsWhatIfMonthlyField', '6000');
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsWhatIfCalculate')),
    );
    expect(find.byKey(const ValueKey('savingsWhatIfResult')), findsOneWidget);
    expect(find.textContaining('11 months'), findsWidgets);
    expect((await detail(goal.id)).goal.monthlyContributionMinorUnits, 500000);

    // 3.2 — finish in 10 months: 6,500/month.
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsWhatIfModeDate')),
    );
    final cubit = tester
        .element(find.byType(WhatIfCalculatorView))
        .read<WhatIfCubit>();
    // 3.4 — a date in the past is rejected.
    cubit.targetDateChanged(today().subtract(const Duration(days: 1)));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsWhatIfCalculate')),
    );
    expect(find.text(l10n.savingsInvalidTargetDateError), findsOneWidget);

    final inTenMonths = DateTime(today().year, today().month + 10, today().day);
    cubit.targetDateChanged(inTenMonths);
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsWhatIfCalculate')),
    );
    expect(find.textContaining('6,500.00 EGP'), findsWidgets);
    expect((await detail(goal.id)).goal.targetDate, isNull);

    // 3.3 — applying is the only thing that changes the goal.
    await tapVisible(tester, find.byKey(const ValueKey('savingsWhatIfApply')));
    final applied = (await detail(goal.id)).goal;
    expect(applied.monthlyContributionMinorUnits, 650000);
    expect(applied.targetDate, inTenMonths);
    expect(
      find.byKey(const ValueKey('savingsLogContribution')),
      findsOneWidget,
    );

    // 3.5 — an achieved goal: a clear "nothing left to plan" message.
    final done = await createGoal(
      name: 'Done',
      target: 100000,
      starting: 100000,
    );
    await open(tester, SavingsRoutes.whatIf(done.id));
    expect(find.text(l10n.savingsWhatIfAchievedTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('savingsWhatIfCalculate')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // Scenario 4 — multiple goals (US4)
  // ---------------------------------------------------------------------

  testWidgets('scenario 4: the overview lists every goal with a combined '
      'total; archive hides and restore returns a goal; a goal with history '
      'cannot be deleted, one without can', (tester) async {
    final l10n = await english();
    final a = await createGoal(
      name: 'Car',
      target: 20000000,
      starting: 1000000,
    );
    final b = await createGoal(name: 'Trip', target: 5000000, starting: 500000);
    final c = await createGoal(name: 'Phone', target: 3000000);

    await open(tester, SavingsRoutes.overview);
    for (final name in ['Car', 'Trip', 'Phone']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('savingsOverviewTotal')))
          .data,
      '15,000.00 EGP',
    );

    // 4.3 — a goal with history: blocked, archive offered instead.
    await tapVisible(tester, find.byKey(ValueKey('savingsGoalMenu-${b.id}')));
    await tapVisible(tester, find.text(l10n.savingsDeleteAction).last);
    await tapVisible(tester, find.text(l10n.savingsDeleteAction).last);
    expect(find.text(l10n.savingsDeleteBlockedTitle), findsOneWidget);

    // 4.2 — take the offer: archived, gone from the active list.
    await tapVisible(tester, find.text(l10n.savingsDeleteBlockedArchiveAction));
    expect(find.text('Trip'), findsNothing);
    expect((await detail(b.id)).goal.isArchived, isTrue);

    // Still viewable and restorable under archived goals, history intact.
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsOverviewArchived')),
    );
    expect(find.text('Trip'), findsOneWidget);
    await tapVisible(tester, find.byKey(ValueKey('savingsRestore-${b.id}')));
    expect((await detail(b.id)).goal.isArchived, isFalse);
    expect((await detail(b.id)).history, hasLength(1));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Trip'), findsOneWidget);

    // 4.4 — no history: permanently removed after confirming.
    await tapVisible(tester, find.byKey(ValueKey('savingsGoalMenu-${c.id}')));
    await tapVisible(tester, find.text(l10n.savingsDeleteAction).last);
    await tapVisible(tester, find.text(l10n.savingsDeleteAction).last);
    expect(find.text('Phone'), findsNothing);
    expect((await savings().getGoalDetail(c.id)).isLeft(), isTrue);
    expect((await detail(a.id)).goal.name, 'Car');
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // Scenario 5 — localization, theming and glass (FR-025)
  // ---------------------------------------------------------------------

  testWidgets('scenario 5: an achieved goal and the calculator in Arabic '
      'RTL, dark mode, with Liquid Glass on', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final settings = getIt<SettingsCubit>();
    final previous = settings.state;
    addTearDown(() async {
      await settings.changeLanguage(previous.language);
      await settings.changeThemeMode(previous.themeMode);
      await settings.setGlassEnabled(previous.glassAppearance.enabled);
    });
    await settings.changeLanguage(AppLanguage.arabic);
    await settings.changeThemeMode(AppThemeMode.dark);
    await settings.setGlassEnabled(true);

    final done = await createGoal(
      name: 'صندوق الطوارئ للعائلة',
      target: 1000000,
      starting: 1200000,
    );
    await open(tester, SavingsRoutes.goal(done.id));

    expect(find.text(ar.savingsGoalAchievedBadge), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AchievedGoalBadge))),
      TextDirection.rtl,
    );
    expect(
      Theme.of(tester.element(find.byType(AchievedGoalBadge))).brightness,
      Brightness.dark,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(GlassContainer),
      ),
      findsOneWidget,
    );

    await open(tester, SavingsRoutes.whatIf(done.id));
    expect(find.text(ar.savingsWhatIfAchievedTitle), findsOneWidget);

    final open2 = await createGoal(
      name: 'سيارة',
      target: 10000000,
      monthly: 500000,
    );
    await open(tester, SavingsRoutes.whatIf(open2.id));
    await enter(tester, 'savingsWhatIfMonthlyField', '6000');
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsWhatIfCalculate')),
    );
    expect(find.byKey(const ValueKey('savingsWhatIfResult')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // Scenario 6 — currency (FR-019, FR-027, FR-028)
  // ---------------------------------------------------------------------

  testWidgets('scenario 6: a USD entry converts into an EGP goal; with the '
      'rate removed it is blocked naming USD; the total is marked '
      'incomplete; the currency cannot be edited', (tester) async {
    final l10n = await english();
    final rate = await currency().setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 50,
    );
    expect(rate.isRight(), isTrue);
    final egpGoal = await createGoal(name: 'Home', target: 10000000);
    final usdGoal = await createGoal(
      name: 'Abroad',
      goalCurrency: Currency.usd,
      target: 500000,
      starting: 10000,
    );

    // 6.1 — log 100 USD into the EGP goal: both figures shown, EGP counts.
    await open(tester, SavingsRoutes.goal(egpGoal.id));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsLogContribution')),
    );
    await enter(tester, 'savingsEntryAmountField', '100');
    await tapVisible(tester, find.byKey(CurrencyPicker.fieldKey));
    await tapVisible(tester, find.text('US Dollar (USD)').last);
    expect(
      find.byKey(const ValueKey('savingsEntryConversionHint')),
      findsOneWidget,
    );
    await submit(tester, 'savingsEntrySubmit');
    expect(find.text('+100.00 USD'), findsOneWidget);
    expect(
      find.text(l10n.savingsEntryConvertedAmount('5,000.00 EGP')),
      findsOneWidget,
    );
    expect(saved('5,000.00 EGP'), findsOneWidget);

    // 6.2 — remove the rate: another USD entry is blocked, naming USD.
    expect((await currency().removeExchangeRate('USD')).isRight(), isTrue);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savingsLogContribution')),
    );
    await enter(tester, 'savingsEntryAmountField', '100');
    await tapVisible(tester, find.byKey(CurrencyPicker.fieldKey));
    await tapVisible(tester, find.text('US Dollar (USD)').last);
    await submit(tester, 'savingsEntrySubmit');
    final failure = find.byKey(const ValueKey('savingsEntryFailure'));
    expect(failure, findsOneWidget);
    expect(tester.widget<Text>(failure).data, contains('USD'));
    expect((await detail(egpGoal.id)).history, hasLength(1));
    final blocked = await savings().logContribution(
      idempotencyKey: key('blocked'),
      goalId: egpGoal.id,
      amount: Money.fromMinorUnits(10000, Currency.usd),
      date: today(),
    );
    expect(blocked.getLeft().toNullable(), isA<RatesMissingFailure>());

    // 6.3 — the overview: the USD goal listed, left out of an incomplete
    // EGP total that names USD.
    await open(tester, SavingsRoutes.overview);
    expect(find.text('Abroad'), findsOneWidget);
    expect(
      find.byKey(ValueKey('savingsOverviewBlocked-${usdGoal.id}')),
      findsOneWidget,
    );
    expect(find.text(l10n.savingsOverviewIncompleteTitle), findsOneWidget);
    expect(
      find.text(l10n.savingsOverviewIncompleteMessage('USD')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('savingsOverviewTotal')))
          .data,
      '5,000.00 EGP',
    );

    // 6.4 — editing shows no currency field, only the fixed-currency note.
    await open(tester, SavingsRoutes.editGoal(usdGoal.id));
    expect(find.byKey(CurrencyPicker.fieldKey), findsNothing);
    expect(
      find.byKey(const ValueKey('savingsGoalCurrencyFixed')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
