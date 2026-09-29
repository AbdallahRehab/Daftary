import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/apply_what_if_scenario.dart';
import 'package:daftary/features/savings/domain/usecases/archive_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_completion_date.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_monthly_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/create_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/delete_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/delete_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/edit_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/edit_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/domain/usecases/log_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/log_withdrawal.dart';
import 'package:daftary/features/savings/domain/usecases/restore_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/watch_goal_detail.dart';
import 'package:daftary/features/savings/domain/usecases/watch_savings_overview.dart';
import 'package:daftary/features/savings/presentation/cubit/archived_goals_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/contribution_form_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_detail_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_form_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/savings_goal_actions_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/savings_overview_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/what_if_cubit.dart';
import 'package:daftary/features/savings/presentation/pages/archived_goals_page.dart';
import 'package:daftary/features/savings/presentation/pages/contribution_form_page.dart';
import 'package:daftary/features/savings/presentation/pages/goal_detail_page.dart';
import 'package:daftary/features/savings/presentation/pages/goal_form_page.dart';
import 'package:daftary/features/savings/presentation/pages/savings_overview_page.dart';
import 'package:daftary/features/savings/presentation/pages/what_if_calculator_page.dart';
import 'package:daftary/features/savings/presentation/widgets/achieved_goal_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../core/design_system/glass/glass_test_harness.dart';
import '../features/savings/helpers/savings_harness.dart';
import '../features/savings/helpers/savings_test_data.dart';
import '../features/transactions/helpers/currency_test_doubles.dart';
import '../helpers/watch_stubs.dart';

/// T071 (FR-025, SC-007) — every savings screen in Arabic RTL and English
/// LTR, light and dark, Liquid Glass on and off, on a 360dp phone, with
/// long goal names and very large amounts: nothing overflows, the layout
/// follows the text direction, the app bar turns to glass when enabled and
/// the achieved state stays in words (never colour alone).
void main() {
  late MockSavingsRepository repository;
  late FakeTableChanges changes;

  const longName =
      'صندوق الطوارئ للعائلة الكبيرة ومصاريف الدراسة والسفر في الصيف القادم';
  // 999,999,999.99 EGP — a figure at the edge of what a phone must fit.
  const huge = 99999999999;

  final active = testGoal(
    id: 'g1',
    name: longName,
    type: 'emergency_fund',
    target: huge,
    monthly: 12345678,
    targetDate: DateTime(2027, 3, 15),
  );
  final achieved = testGoal(id: 'g2', name: longName, target: 10000000);
  final usdGoal = testGoal(
    id: 'g3',
    name: longName,
    currency: Currency.usd,
    target: huge,
  );

  final activeDetail = testDetail(
    active,
    history: [
      for (var i = 0; i < 6; i++)
        testEntry(
          id: 'c$i',
          amount: 987654321,
          note: 'ملاحظة طويلة جدًا عن هذا الإيداع الشهري من مكافأة نهاية العام',
        ),
      testEntry(
        id: 'u',
        amount: 4835000000,
        entered: 100000000,
        enteredCurrency: Currency.usd,
      ),
      testEntry(
        id: 'w',
        type: ContributionType.withdrawal,
        amount: 987654321,
        editedAt: testToday,
      ),
    ],
  );
  final achievedDetail = testDetail(
    achieved,
    history: [testEntry(id: 'a', goalId: 'g2', amount: 12000000)],
  );

  setUpAll(() {
    registerFallbackValue(Money.egp(0));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockSavingsRepository();
    changes = FakeTableChanges();
    stubSavingsWatches(repository, changes);
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(activeDetail));
    when(
      () => repository.getGoalDetail('g2'),
    ).thenAnswer((_) async => Right(achievedDetail));
    when(
      () => repository.getSavingsOverview(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer(
      (_) async => Right(
        SavingsOverview(
          goals: [
            testOverviewLine(active, saved: huge ~/ 3),
            testOverviewLine(achieved, saved: 12000000),
            testOverviewLine(
              usdGoal,
              saved: 500000,
              missing: const [Currency.usd],
            ),
          ],
          primaryCurrency: Currency.egp,
        ),
      ),
    );
  });

  tearDown(() => changes.close());

  SavingsGoalActionsCubit actions() {
    final cubit = SavingsGoalActionsCubit(
      ArchiveSavingsGoal(repository),
      RestoreSavingsGoal(repository),
      DeleteSavingsGoal(repository),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  T closing<T extends BlocBase<Object?>>(T cubit) {
    addTearDown(cubit.close);
    return cubit;
  }

  WhatIfCubit whatIf() {
    final getDetail = GetGoalDetail(repository);
    final clock = SettableClock(testToday);
    const calculator = DefaultSavingsCalculator();
    return closing(
      WhatIfCubit(
        getDetail,
        CalculateWhatIfMonthlyContribution(getDetail, calculator, clock),
        CalculateWhatIfCompletionDate(getDetail, calculator, clock),
        ApplyWhatIfScenario(getDetail, EditSavingsGoal(repository)),
      ),
    );
  }

  /// Each screen: a name, how to build it, and (optionally) what to do once
  /// it is on screen to reach the state worth checking.
  final screens =
      <
        String,
        (
          Widget Function(),
          Future<void> Function(WidgetTester tester)?,
          Finder Function(AppLocalizations l10n),
        )
      >{
        'overview': (
          () => MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: closing(
                  SavingsOverviewCubit(WatchSavingsOverview(repository))
                    ..subscribe(),
                ),
              ),
              BlocProvider.value(value: actions()),
            ],
            child: const SavingsOverviewView(),
          ),
          null,
          (l10n) => find.text(l10n.savingsOverviewIncompleteTitle),
        ),
        'archived': (
          () => MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: closing(
                  ArchivedGoalsCubit(WatchSavingsOverview(repository))
                    ..subscribe(),
                ),
              ),
              BlocProvider.value(value: actions()),
            ],
            child: const ArchivedGoalsView(),
          ),
          null,
          (l10n) => find.text(l10n.savingsArchiveTitle),
        ),
        'goal detail (shortfall + converted history)': (
          () => BlocProvider.value(
            value: closing(
              GoalDetailCubit(
                WatchGoalDetail(repository),
                DeleteContribution(repository),
              )..subscribe('g1'),
            ),
            child: const GoalDetailView(),
          ),
          null,
          (l10n) => find.byKey(const ValueKey('savingsShortfallLine')),
        ),
        'goal detail (achieved)': (
          () => BlocProvider.value(
            value: closing(
              GoalDetailCubit(
                WatchGoalDetail(repository),
                DeleteContribution(repository),
              )..subscribe('g2'),
            ),
            child: const GoalDetailView(),
          ),
          null,
          (l10n) => find.text(l10n.savingsGoalAchievedBadge),
        ),
        'goal form with preview': (
          () => BlocProvider.value(
            value: closing(
              GoalFormCubit(
                _MockCreateSavingsGoal(),
                _MockEditSavingsGoal(),
                GetGoalDetail(repository),
                getPrimaryCurrencyReturning(),
                const DefaultSavingsCalculator(),
                SettableClock(testToday),
              ),
            ),
            child: const GoalFormView(),
          ),
          (tester) async {
            await tester.enterText(
              find.descendant(
                of: find.byKey(const ValueKey('savingsGoalNameField')),
                matching: find.byType(TextField),
              ),
              longName,
            );
            // Fields lower down may not be built yet on a phone; the preview
            // reads the cubit's state, so drive the figures through it.
            tester.element(find.byType(GoalFormView)).read<GoalFormCubit>()
              ..targetChanged('999999999')
              ..monthlyChanged('1234');
            await tester.pumpAndSettle();
          },
          (l10n) => find.byKey(const ValueKey('savingsGoalPreview')),
        ),
        'contribution form (withdrawal, foreign currency)': (
          () {
            final cubit = closing(
              ContributionFormCubit(
                GetGoalDetail(repository),
                LogContribution(repository),
                LogWithdrawal(repository),
                EditContribution(repository),
                SettableClock(testToday),
              ),
            );
            cubit.initialize(goalId: 'g1', type: ContributionType.withdrawal);
            return BlocProvider.value(
              value: cubit,
              child: const ContributionFormView(),
            );
          },
          (tester) async {
            final context = tester.element(find.byType(ContributionFormView));
            context.read<ContributionFormCubit>().currencyChanged(Currency.usd);
            await tester.pumpAndSettle();
          },
          (l10n) => find.byKey(const ValueKey('savingsEntryConversionHint')),
        ),
        'what-if with a result': (
          () {
            final cubit = whatIf()..load('g1');
            return BlocProvider.value(
              value: cubit,
              child: const WhatIfCalculatorView(),
            );
          },
          (tester) async {
            final context = tester.element(find.byType(WhatIfCalculatorView));
            final cubit = context.read<WhatIfCubit>()..monthlyChanged('1');
            await cubit.calculate();
            await tester.pumpAndSettle();
          },
          (l10n) => find.byKey(const ValueKey('savingsWhatIfResult')),
        ),
        'what-if on an achieved goal': (
          () {
            final cubit = whatIf()..load('g2');
            return BlocProvider.value(
              value: cubit,
              child: const WhatIfCalculatorView(),
            );
          },
          null,
          (l10n) => find.text(l10n.savingsWhatIfAchievedTitle),
        ),
      };

  final variants = <String, (Locale, ThemeData Function(), AppGlassStyle?)>{
    'Arabic, dark, glass on': (const Locale('ar'), buildDarkTheme, onStyle),
    'Arabic, light, glass off': (
      const Locale('ar'),
      buildLightTheme,
      AppGlassStyle.off,
    ),
    'English, dark, glass off': (const Locale('en'), buildDarkTheme, null),
    'English, light, glass on': (const Locale('en'), buildLightTheme, onStyle),
  };

  for (final screen in screens.entries) {
    final (build, act, marker) = screen.value;
    group(screen.key, () {
      for (final variant in variants.entries) {
        final (locale, theme, style) = variant.value;
        testWidgets('${variant.key}: fits 360dp with long names and large '
            'amounts', (tester) async {
          tester.view
            ..physicalSize = const Size(360, 780)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              theme: theme(),
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: style == null
                  ? null
                  : (context, child) =>
                        AppGlassScope(style: style, child: child!),
              home: build(),
            ),
          );
          await tester.pumpAndSettle();
          if (act != null) await act(tester);

          final l10n = lookupAppLocalizations(locale);
          final target = marker(l10n);
          await tester
              .scrollUntilVisible(
                target,
                200,
                scrollable: find.byType(Scrollable).first,
              )
              .catchError((_) {});
          expect(target, findsWidgets);

          // Direction follows the locale.
          final direction = Directionality.of(
            tester.element(find.byType(AppBar)),
          );
          expect(
            direction,
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );

          // The app bar is glass exactly when glass is on.
          final glass = find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(GlassContainer),
          );
          expect(
            glass,
            style?.enabled ?? false ? findsOneWidget : findsNothing,
          );

          // An overflow (or any other layout error) fails here.
          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  testWidgets('the achieved badge is labelled in words for assistive tech '
      'in Arabic dark mode (never colour alone)', (tester) async {
    final ar = lookupAppLocalizations(const Locale('ar'));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AchievedGoalBadge()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(ar.savingsGoalAchievedBadge), findsOneWidget);
    // The badge's colours come from the dark theme's finance roles, so the
    // text stays legible on its surface.
    final context = tester.element(find.byType(AchievedGoalBadge));
    final box = tester.widget<Container>(
      find.byKey(const ValueKey('savingsAchievedBadge')),
    );
    expect(
      (box.decoration! as BoxDecoration).color,
      context.financeColors.successSurface,
    );
  });
}

class _MockCreateSavingsGoal extends Mock implements CreateSavingsGoal {}

class _MockEditSavingsGoal extends Mock implements EditSavingsGoal {}
