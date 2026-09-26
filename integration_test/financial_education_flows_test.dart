import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/financial_education/presentation/pages/article_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/category_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/compound_growth_calculator_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/content_library_home_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/doubling_time_calculator_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/savings_rate_calculator_page.dart';
import 'package:daftary/features/financial_education/presentation/widgets/calculator_result_card.dart';
import 'package:daftary/features/financial_education/presentation/widgets/persistent_disclaimer_banner.dart';
import 'package:daftary/features/settings/presentation/pages/settings_page.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/main.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// T055 — end-to-end coverage of Financial Education (US1-US4) against the
/// real app (real DI, real bundled content), following quickstart.md's
/// manual scenarios: browse Settings → home → category → article → back;
/// the three calculators' valid/invalid/edge inputs; and the persistent
/// disclaimer on every screen across repeat visits.
///
/// Zero network activity (FR-017) is guaranteed structurally by
/// `test/features/financial_education/architecture_boundary_test.dart`
/// (no network package is importable by this feature); these flows run
/// entirely from bundled assets and in-memory calculators.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `lib/main.dart`'s own `main()` is never invoked by an integration test,
  // so DI bootstrap has to happen explicitly before the first `pumpWidget`.
  setUpAll(() async {
    await configureDependencies();
    // 019: the app shows the splash until startup (settings + onboarding
    // gate) is ready, so run it exactly like `main()` does.
    // 019: startup now resolves the onboarding gate these flows never
    // went through before; mark it complete so they keep landing in the
    // main app whatever an earlier test left in the shared device DB.
    await getIt<OnboardingRepository>().completeOnboarding();
    await getIt<AppStartupCubit>().start();
  });

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  /// Starts the real app on [location]. `appRouter` is a module-level
  /// singleton that keeps wherever the previous test left it, so every
  /// test resets it explicitly.
  Future<void> pumpAt(WidgetTester tester, String location) async {
    appRouter.go(location);
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  /// Scrolls [finder] into view before tapping it: `tester.tap` on an
  /// off-screen widget only warns, so a missed tap would otherwise surface
  /// later as a confusing failure. A lazy `ListView` doesn't build rows
  /// below the fold at all, so those are scrolled to first.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  void expectDisclaimer(Type pageType, {String? reason}) {
    expect(find.byType(pageType), findsOneWidget, reason: reason);
    expect(
      find.byKey(PersistentDisclaimerBanner.rootKey),
      findsOneWidget,
      reason: reason,
    );
  }

  Future<void> enterField(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    await tester.enterText(find.widgetWithText(TextField, label), value);
    await tester.pumpAndSettle();
  }

  Future<void> calculate(WidgetTester tester, AppLocalizations l10n) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(l10n.finEduCalcCalculate));
  }

  testWidgets('browse Settings → Financial Education → category → article '
      '→ back (US1; quickstart.md Scenario 1)', (tester) async {
    final l10n = await english();
    await pumpAt(tester, '/settings');
    expect(find.byType(SettingsPage), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const Key('settings_financial_education_entry')),
    );
    expectDisclaimer(ContentLibraryHomePage);
    expect(find.text(l10n.finEduToolsSectionTitle), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('fin_edu_category_budgeting_basics')),
    );
    expectDisclaimer(CategoryPage);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('fin_edu_article_why_track_your_spending')),
    );
    expectDisclaimer(ArticlePage);
    expect(find.text('Why Track Your Spending?'), findsWidgets);

    await goBack(tester);
    expectDisclaimer(CategoryPage);
    expect(find.byType(ArticlePage), findsNothing);

    await goBack(tester);
    expectDisclaimer(ContentLibraryHomePage);

    await goBack(tester);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byKey(PersistentDisclaimerBanner.rootKey), findsNothing);
  });

  testWidgets('compound growth: valid result, inline error, high-rate note, '
      'no pre-fill when 011 is absent (US2; quickstart.md Scenario 2)', (
    tester,
  ) async {
    final l10n = await english();
    await pumpAt(tester, FinancialEducationRoutes.home);
    await tapVisible(
      tester,
      find.byKey(
        const ValueKey(
          'fin_edu_calculator_${FinancialEducationRoutes.compoundGrowth}',
        ),
      ),
    );
    expectDisclaimer(CompoundGrowthCalculatorPage);

    // Savings Goals (011) is not in this build → no pre-fill action.
    expect(find.text(l10n.finEduCalcPrefillFromSavingsGoal), findsNothing);
    expect(find.byIcon(Icons.savings_outlined), findsNothing);

    // Invalid input → inline error, no result.
    await enterField(tester, l10n.finEduCalcMonthlyContributionLabel, '0');
    await enterField(tester, l10n.finEduCalcAnnualRateLabel, '7');
    await enterField(tester, l10n.finEduCalcYearsLabel, '10');
    await calculate(tester, l10n);
    expect(find.text(l10n.finEduCalcErrorAmountPositive), findsOneWidget);
    expect(find.byType(CalculatorResultCard), findsNothing);

    // Valid input → result card with the illustrative note, no high-rate
    // note at an ordinary rate.
    await enterField(tester, l10n.finEduCalcMonthlyContributionLabel, '1000');
    await calculate(tester, l10n);
    expect(find.text(l10n.finEduCalcErrorAmountPositive), findsNothing);
    expect(find.byType(CalculatorResultCard), findsOneWidget);
    expect(find.text(l10n.finEduCalcResultFutureValue), findsOneWidget);
    expect(find.text('120,000.00 EGP'), findsOneWidget);
    expect(
      find.byKey(CalculatorResultCard.illustrativeNoteKey),
      findsOneWidget,
    );
    expect(find.byKey(CalculatorResultCard.highRateNoteKey), findsNothing);

    // >30% → the high-rate note appears.
    await enterField(tester, l10n.finEduCalcAnnualRateLabel, '31');
    await calculate(tester, l10n);
    expect(find.byKey(CalculatorResultCard.highRateNoteKey), findsOneWidget);
    expect(find.byKey(PersistentDisclaimerBanner.rootKey), findsOneWidget);
  });

  testWidgets('doubling time: 8% → about 9 years (US3; quickstart.md '
      'Scenario 3)', (tester) async {
    final l10n = await english();
    await pumpAt(tester, FinancialEducationRoutes.home);
    await tapVisible(
      tester,
      find.byKey(
        const ValueKey(
          'fin_edu_calculator_${FinancialEducationRoutes.doublingTime}',
        ),
      ),
    );
    expectDisclaimer(DoublingTimeCalculatorPage);

    await enterField(tester, l10n.finEduCalcAnnualRateLabel, '8');
    await calculate(tester, l10n);
    expect(find.text(l10n.finEduCalcYearsValue('9')), findsOneWidget);
    expect(find.text(l10n.finEduCalcRuleOf72Note), findsOneWidget);
  });

  testWidgets('savings rate: 25,000 saved of 20,000 income → 125%, '
      'unclamped (US3; quickstart.md Scenario 3)', (tester) async {
    final l10n = await english();
    await pumpAt(tester, FinancialEducationRoutes.home);
    await tapVisible(
      tester,
      find.byKey(
        const ValueKey(
          'fin_edu_calculator_${FinancialEducationRoutes.savingsRate}',
        ),
      ),
    );
    expectDisclaimer(SavingsRateCalculatorPage);

    await enterField(tester, l10n.finEduCalcIncomeLabel, '20000');
    await enterField(tester, l10n.finEduCalcSavingsAmountLabel, '25000');
    await calculate(tester, l10n);
    expect(find.text(l10n.finEduCalcPercentValue('125')), findsOneWidget);
    expect(find.text(l10n.finEduCalcSavingsAboveIncomeNote), findsOneWidget);
  });

  testWidgets('the disclaimer is present on every screen on repeat visits '
      '(US4; SC-003; quickstart.md Scenario 4)', (tester) async {
    final screens = <String, Type>{
      FinancialEducationRoutes.home: ContentLibraryHomePage,
      FinancialEducationRoutes.category('budgeting_basics'): CategoryPage,
      FinancialEducationRoutes.article(
        'budgeting_basics',
        'why_track_your_spending',
      ): ArticlePage,
      FinancialEducationRoutes.compoundGrowth: CompoundGrowthCalculatorPage,
      FinancialEducationRoutes.doublingTime: DoublingTimeCalculatorPage,
      FinancialEducationRoutes.savingsRate: SavingsRateCalculatorPage,
    };

    await pumpAt(tester, '/settings');
    for (var visit = 1; visit <= 2; visit++) {
      for (final MapEntry(key: route, value: pageType) in screens.entries) {
        appRouter.push(route);
        await tester.pumpAndSettle();
        expectDisclaimer(pageType, reason: 'visit $visit to $route');

        appRouter.pop();
        await tester.pumpAndSettle();
        expect(find.byType(pageType), findsNothing);
      }
    }
    expect(tester.takeException(), isNull);
  });
}
