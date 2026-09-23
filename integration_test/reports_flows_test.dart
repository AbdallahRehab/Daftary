import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_spending_trend.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_state.dart';
import 'package:daftary/features/finance/presentation/pages/reports_page.dart';
import 'package:daftary/features/finance/presentation/widgets/category_breakdown_chart.dart';
import 'package:daftary/features/finance/presentation/widgets/monthly_trend_chart.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 013 T053 — end-to-end coverage of Reports (US1) against the real app
/// (real DI, real on-device SQLite), following quickstart.md Scenario 1:
/// trend + breakdown rendering, the period switch, and an RTL/dark-mode
/// spot-check.
///
/// Scenario 1.3 (true empty state) needs a database with no finance entry
/// ever recorded, and 1.4 (load failure + retry) needs a data source that
/// fails on demand — neither of which the shared on-device database can
/// offer without destroying other suites' data. Both are covered by
/// `test/widget/reports_page_test.dart` and
/// `test/features/finance/presentation/cubit/reports_cubit_test.dart`.
///
/// The on-device database persists across runs, so every assertion here is
/// relative to what the owning use cases report right now, never to fixed
/// totals.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `lib/main.dart`'s own `main()` is never invoked by an integration test,
  // so DI bootstrap has to happen explicitly before the first `pumpWidget`.
  setUpAll(() async {
    await configureDependencies();
    // Guarantees Reports has something to show. The fixed idempotency key
    // makes a re-run return the already-saved entry instead of adding
    // another one.
    final seeded = await getIt<FinanceRepository>().addEntry(
      idempotencyKey: 'reports-flows-seed',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amountMinorUnits: 4250,
      date: DateTime.now(),
    );
    expect(seeded.isRight(), isTrue);
  });

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  Future<void> openReportsFromFinance(WidgetTester tester) async {
    // `appRouter` is a module-level singleton that keeps wherever the
    // previous test left it — reset explicitly so each test starts on the
    // finance history screen, Reports' entry point (T017).
    appRouter.go('/finance');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    )!;
    await tester.tap(find.byTooltip(l10n.reportsOpenAction));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsPage), findsOneWidget);
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Reports shows the trend and breakdown the owning use cases '
      'compute, reached from the finance screen (Scenario 1.1)', (
    tester,
  ) async {
    await openReportsFromFinance(tester);
    final l10n = await english();

    expect(find.text(l10n.reportsTrendTitle), findsOneWidget);
    expect(find.byType(MonthlyTrendChart), findsOneWidget);

    final trend = (await getIt<GetSpendingTrend>()(
      monthsBack: ReportsCubit.trendMonths,
    )).getOrElse((f) => throw StateError(f.message));
    expect(
      tester.widget<MonthlyTrendChart>(find.byType(MonthlyTrendChart)).points,
      trend,
    );
    for (final point in trend) {
      expect(
        find.byKey(ValueKey(MonthlyTrendChart.monthKey(point.period.start))),
        findsOneWidget,
      );
    }

    await scrollTo(tester, find.byType(CategoryBreakdownChart));
    final breakdown = (await getIt<GetCategoryBreakdown>()(
      ReportsPeriod.thisMonth.range(),
      type: FinanceEntryType.expense,
    )).getOrElse((f) => throw StateError(f.message));
    expect(
      tester
          .widget<CategoryBreakdownChart>(find.byType(CategoryBreakdownChart))
          .items,
      breakdown,
    );
    // The seeded entry guarantees at least one row this month.
    expect(
      find.byKey(
        const ValueKey('${CategoryBreakdownChart.rowKeyPrefix}seed_groceries'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switching the breakdown period updates only the breakdown; '
      'the trend is unchanged (Scenario 1.2)', (tester) async {
    await openReportsFromFinance(tester);
    final l10n = await english();

    final trendBefore = tester
        .widget<MonthlyTrendChart>(find.byType(MonthlyTrendChart))
        .points;

    for (final (period, label) in [
      (ReportsPeriod.lastMonth, l10n.reportsPeriodLastMonth),
      (ReportsPeriod.last3Months, l10n.reportsPeriodLast3Months),
      (ReportsPeriod.last6Months, l10n.reportsPeriodLast6Months),
    ]) {
      final chip = find.widgetWithText(ChoiceChip, label);
      await scrollTo(tester, chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      final expected = (await getIt<GetCategoryBreakdown>()(
        period.range(),
        type: FinanceEntryType.expense,
      )).getOrElse((f) => throw StateError(f.message));
      final chart = find.byType(CategoryBreakdownChart);
      await scrollTo(tester, chart);
      expect(
        tester.widget<CategoryBreakdownChart>(chart).items,
        expected,
        reason: period.name,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
            .selected,
        isTrue,
      );
    }

    expect(
      tester.widget<MonthlyTrendChart>(find.byType(MonthlyTrendChart)).points,
      trendBefore,
    );
  });

  testWidgets('the app bar shortcut opens Data Export (SC-002)', (
    tester,
  ) async {
    await openReportsFromFinance(tester);
    final l10n = await english();

    await tester.tap(find.byTooltip(l10n.reportsExportAction));
    await tester.pumpAndSettle();
    expect(
      appRouter.routerDelegate.currentConfiguration.uri.path,
      ReportsPage.exportLocation,
    );
  });

  testWidgets('Arabic + dark mode: the chart mirrors and re-themes live '
      '(Scenario 1.5)', (tester) async {
    final settings = getIt<SettingsCubit>();
    final previousLanguage = settings.state.language;
    final previousTheme = settings.state.themeMode;
    addTearDown(() async {
      await settings.changeLanguage(previousLanguage);
      await settings.changeThemeMode(previousTheme);
    });

    await openReportsFromFinance(tester);
    await settings.changeLanguage(AppLanguage.arabic);
    await settings.changeThemeMode(AppThemeMode.dark);
    await tester.pumpAndSettle();

    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final chart = find.byType(MonthlyTrendChart);
    expect(find.text(ar.reportsTitle), findsWidgets);
    expect(find.text(ar.reportsTrendTitle), findsOneWidget);
    expect(Directionality.of(tester.element(chart)), TextDirection.rtl);
    expect(Theme.of(tester.element(chart)).brightness, Brightness.dark);

    // Oldest month sits at the reading start — the right edge under RTL —
    // and the amount axis moves with it.
    final points = tester.widget<MonthlyTrendChart>(chart).points;
    double monthX(int index) => tester
        .getCenter(
          find.byKey(
            ValueKey(MonthlyTrendChart.monthKey(points[index].period.start)),
          ),
        )
        .dx;
    expect(monthX(0), greaterThan(monthX(points.length - 1)));
    expect(
      tester.getCenter(find.byKey(MonthlyTrendChart.axisKey)).dx,
      greaterThan(monthX(0)),
    );
    expect(tester.takeException(), isNull);
  });
}
