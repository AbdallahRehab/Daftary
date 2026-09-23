import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/app_empty_view.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/category_breakdown_item.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/spending_trend_point.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_state.dart';
import 'package:daftary/features/finance/presentation/pages/reports_page.dart';
import 'package:daftary/features/finance/presentation/widgets/category_breakdown_chart.dart';
import 'package:daftary/features/finance/presentation/widgets/monthly_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockReportsCubit extends MockCubit<ReportsState>
    implements ReportsCubit {}

/// 013 T007 + T051 (Reports part) — every state the Reports screen renders,
/// the breakdown's ordering and shares (FR-002), whole-chart RTL mirroring
/// (FR-006), light/dark theming, and ar/en localization (FR-023).
void main() {
  late MockReportsCubit cubit;
  late AppLocalizations en;
  late AppLocalizations ar;

  final trend = [
    SpendingTrendPoint(
      period: DateRange(start: DateTime(2026, 7), end: DateTime(2026, 7, 31)),
      totalIncomeMinorUnits: 800000,
      totalExpenseMinorUnits: 300000,
      netMinorUnits: 500000,
    ),
    SpendingTrendPoint(
      period: DateRange(start: DateTime(2026, 8), end: DateTime(2026, 8, 31)),
      totalIncomeMinorUnits: 900000,
      totalExpenseMinorUnits: 950000,
      netMinorUnits: -50000,
    ),
    SpendingTrendPoint(
      period: DateRange(start: DateTime(2026, 9), end: DateTime(2026, 9, 24)),
      totalIncomeMinorUnits: 1000000,
      totalExpenseMinorUnits: 120050,
      netMinorUnits: 879950,
    ),
  ];

  // Deliberately out of order: the chart must still render largest first.
  const breakdown = [
    CategoryBreakdownItem(
      categoryId: 'seed_fuel',
      categoryName: 'Fuel',
      icon: 'fuel',
      total: Money.fromMinorUnits(20000),
      shareOfPeriod: 0.2,
    ),
    CategoryBreakdownItem(
      categoryId: 'seed_groceries',
      categoryName: 'Groceries',
      icon: 'groceries',
      total: Money.fromMinorUnits(70000),
      shareOfPeriod: 0.7,
    ),
    CategoryBreakdownItem(
      categoryId: 'seed_water',
      categoryName: 'Water',
      icon: 'water',
      total: Money.fromMinorUnits(10000),
      shareOfPeriod: 0.1,
    ),
  ];

  final success = ReportsState(
    status: ReportsStatus.success,
    trend: trend,
    breakdown: breakdown,
    breakdownStatus: ReportsBreakdownStatus.success,
  );

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
    registerFallbackValue(ReportsPeriod.thisMonth);
  });

  setUp(() {
    cubit = MockReportsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.retryBreakdown()).thenAnswer((_) async {});
    when(() => cubit.changeBreakdownPeriod(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    ReportsState state, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    Size size = const Size(800, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => cubit.state).thenReturn(state);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider<ReportsCubit>.value(
            value: cubit,
            child: const ReportsView(),
          ),
        ),
        GoRoute(
          path: '/settings/export',
          builder: (_, _) => const Scaffold(body: Text('export-destination')),
        ),
        GoRoute(
          path: '/finance/entries/new',
          builder: (_, _) => const Scaffold(body: Text('new-entry')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  double centerX(WidgetTester tester, Finder finder) =>
      tester.getCenter(finder).dx;

  Finder month(String yyyyMm) =>
      find.byKey(ValueKey('${MonthlyTrendChart.monthKeyPrefix}$yyyyMm'));

  TrendBarsPainter painterOf(WidgetTester tester, String yyyyMm) {
    final paint = tester.widget<CustomPaint>(
      find.descendant(of: month(yyyyMm), matching: find.byType(CustomPaint)),
    );
    return paint.painter! as TrendBarsPainter;
  }

  group('states', () {
    testWidgets('loading shows a progress indicator', (tester) async {
      when(() => cubit.state).thenReturn(const ReportsState());
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<ReportsCubit>.value(
            value: cubit,
            child: const ReportsView(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('success renders the trend and the breakdown', (tester) async {
      await pump(tester, success);

      expect(find.text(en.reportsTitle), findsOneWidget);
      expect(find.text(en.reportsTrendTitle), findsOneWidget);
      expect(
        find.text(en.reportsTrendSubtitle(ReportsCubit.trendMonths)),
        findsOneWidget,
      );
      expect(find.byType(MonthlyTrendChart), findsOneWidget);
      expect(find.byType(CategoryBreakdownChart), findsOneWidget);
      expect(find.text(en.reportsBreakdownTitle), findsOneWidget);
      for (final point in trend) {
        final key = MonthlyTrendChart.monthKey(point.period.start);
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
    });

    testWidgets('the true empty state explains itself and offers the first '
        'entry (FR-004)', (tester) async {
      await pump(tester, const ReportsState(status: ReportsStatus.empty));

      expect(find.text(en.reportsEmptyTitle), findsOneWidget);
      expect(find.text(en.reportsEmptyMessage), findsOneWidget);
      expect(find.byType(MonthlyTrendChart), findsNothing);

      await tester.tap(find.text(en.reportsEmptyAction));
      await tester.pumpAndSettle();
      expect(find.text('new-entry'), findsOneWidget);
    });

    testWidgets('the error state offers a retry that reloads (FR-005)', (
      tester,
    ) async {
      await pump(
        tester,
        const ReportsState(
          status: ReportsStatus.failure,
          errorMessage: 'disk read failed',
        ),
      );

      expect(find.byType(AppEmptyView), findsOneWidget);
      expect(find.text(en.reportsLoadError), findsOneWidget);
      // The raw failure message is diagnostic only, never shown.
      expect(find.text('disk read failed'), findsNothing);

      await tester.tap(find.text(en.retry));
      verify(() => cubit.load()).called(1);
    });

    testWidgets('an inline breakdown failure keeps the trend and retries only '
        'the breakdown', (tester) async {
      await pump(
        tester,
        success.copyWith(breakdownStatus: ReportsBreakdownStatus.failure),
      );

      expect(find.byType(MonthlyTrendChart), findsOneWidget);
      expect(find.text(en.reportsLoadError), findsOneWidget);
      await tester.tap(find.text(en.retry));
      verify(() => cubit.retryBreakdown()).called(1);
      verifyNever(() => cubit.load());
    });

    testWidgets('a period with no expenses says so instead of an empty gap', (
      tester,
    ) async {
      await pump(tester, success.copyWith(breakdown: const []));
      expect(find.text(en.reportsBreakdownEmpty), findsOneWidget);
    });
  });

  group('interactions', () {
    testWidgets('choosing a period asks the cubit for that breakdown', (
      tester,
    ) async {
      await pump(tester, success);

      for (final label in [
        en.reportsPeriodThisMonth,
        en.reportsPeriodLastMonth,
        en.reportsPeriodLast3Months,
        en.reportsPeriodLast6Months,
      ]) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      await tester.tap(
        find.widgetWithText(ChoiceChip, en.reportsPeriodLast3Months),
      );
      verify(
        () => cubit.changeBreakdownPeriod(ReportsPeriod.last3Months),
      ).called(1);
    });

    testWidgets('the app bar export shortcut opens /settings/export', (
      tester,
    ) async {
      await pump(tester, success);

      await tester.tap(find.byTooltip(en.reportsExportAction));
      await tester.pumpAndSettle();
      expect(find.text('export-destination'), findsOneWidget);
    });
  });

  group('breakdown (FR-002)', () {
    testWidgets('rows run largest to smallest, each with its share and '
        'amount', (tester) async {
      await pump(tester, success);

      double rowY(String id) => tester
          .getTopLeft(
            find.byKey(ValueKey('${CategoryBreakdownChart.rowKeyPrefix}$id')),
          )
          .dy;
      expect(rowY('seed_groceries'), lessThan(rowY('seed_fuel')));
      expect(rowY('seed_fuel'), lessThan(rowY('seed_water')));

      expect(find.text(en.reportsCategoryShare('70')), findsOneWidget);
      expect(find.text(en.reportsCategoryShare('20')), findsOneWidget);
      expect(find.text(en.reportsCategoryShare('10')), findsOneWidget);

      final formatter = EgpFormatter();
      expect(
        find.text(
          formatter.formatWithSymbol(const Money.fromMinorUnits(70000)),
        ),
        findsOneWidget,
      );
      expect(find.text('Groceries'), findsOneWidget);
    });
  });

  group('trend chart direction (FR-006)', () {
    testWidgets('LTR: oldest month at the left, amount axis and legend at '
        'the left edge, income bar on the left of each pair', (tester) async {
      await pump(tester, success);

      expect(
        centerX(tester, month('2026-07')),
        lessThan(centerX(tester, month('2026-08'))),
      );
      expect(
        centerX(tester, month('2026-08')),
        lessThan(centerX(tester, month('2026-09'))),
      );

      final axis = find.byKey(MonthlyTrendChart.axisKey);
      expect(
        centerX(tester, axis),
        lessThan(centerX(tester, month('2026-07'))),
      );

      final incomeLegend = find.byKey(MonthlyTrendChart.incomeLegendKey);
      final expenseLegend = find.byKey(MonthlyTrendChart.expenseLegendKey);
      expect(
        centerX(tester, incomeLegend),
        lessThan(centerX(tester, expenseLegend)),
      );

      expect(painterOf(tester, '2026-07').textDirection, TextDirection.ltr);
    });

    testWidgets('RTL: the whole chart mirrors — months, axis, legend, and '
        'bar order — not just the text', (tester) async {
      await pump(tester, success, locale: const Locale('ar'));

      expect(
        centerX(tester, month('2026-07')),
        greaterThan(centerX(tester, month('2026-08'))),
      );
      expect(
        centerX(tester, month('2026-08')),
        greaterThan(centerX(tester, month('2026-09'))),
      );

      final axis = find.byKey(MonthlyTrendChart.axisKey);
      expect(
        centerX(tester, axis),
        greaterThan(centerX(tester, month('2026-07'))),
      );

      final incomeLegend = find.byKey(MonthlyTrendChart.incomeLegendKey);
      final expenseLegend = find.byKey(MonthlyTrendChart.expenseLegendKey);
      expect(
        centerX(tester, incomeLegend),
        greaterThan(centerX(tester, expenseLegend)),
      );

      expect(painterOf(tester, '2026-07').textDirection, TextDirection.rtl);

      // Fully localized, with no English left behind (FR-023).
      expect(find.text(ar.reportsTitle), findsOneWidget);
      expect(find.text(ar.reportsTrendTitle), findsOneWidget);
      expect(find.text(ar.reportsBreakdownTitle), findsOneWidget);
      expect(find.text(ar.reportsIncome), findsWidgets);
      expect(find.text(ar.reportsExpenses), findsWidgets);
      expect(find.text(en.reportsTrendTitle), findsNothing);
      expect(find.text(en.reportsIncome), findsNothing);
    });

    test('the painter mirrors its own bar order under RTL', () {
      Rect incomeRect(TextDirection direction) => TrendBarsPainter(
        incomeMinorUnits: 100,
        expenseMinorUnits: 50,
        maxMinorUnits: 100,
        incomeColor: const Color(0xFF00FF00),
        expenseColor: const Color(0xFFFF0000),
        expenseFillColor: const Color(0x33FF0000),
        textDirection: direction,
      ).barRects(const Size(40, 100)).income;

      Rect expenseRect(TextDirection direction) => TrendBarsPainter(
        incomeMinorUnits: 100,
        expenseMinorUnits: 50,
        maxMinorUnits: 100,
        incomeColor: const Color(0xFF00FF00),
        expenseColor: const Color(0xFFFF0000),
        expenseFillColor: const Color(0x33FF0000),
        textDirection: direction,
      ).barRects(const Size(40, 100)).expense;

      expect(
        incomeRect(TextDirection.ltr).left,
        lessThan(expenseRect(TextDirection.ltr).left),
      );
      expect(
        incomeRect(TextDirection.rtl).left,
        greaterThan(expenseRect(TextDirection.rtl).left),
      );
      // Heights are proportional to the amounts in both directions.
      expect(incomeRect(TextDirection.rtl).height, 100);
      expect(expenseRect(TextDirection.rtl).height, 50);
    });
  });

  testWidgets('fits a narrow phone in both languages without overflow', (
    tester,
  ) async {
    final sixMonths = [
      for (var m = 4; m <= 9; m++)
        SpendingTrendPoint(
          period: DateRange(
            start: DateTime(2026, m),
            end: DateTime(2026, m, 28),
          ),
          totalIncomeMinorUnits: 123456789,
          totalExpenseMinorUnits: 98765432,
          netMinorUnits: 24691357,
        ),
    ];
    for (final locale in const [Locale('en'), Locale('ar')]) {
      await pump(
        tester,
        success.copyWith(trend: sixMonths),
        locale: locale,
        size: const Size(320, 1400),
      );
      expect(tester.takeException(), isNull);
    }
  });

  group('theming', () {
    for (final (name, theme, colors) in [
      ('light', buildLightTheme(), AppFinanceColors.light),
      ('dark', buildDarkTheme(), AppFinanceColors.dark),
    ]) {
      testWidgets('$name: chart bars and breakdown rows take their colors '
          'from the theme tokens', (tester) async {
        await pump(tester, success, theme: theme);

        final painter = painterOf(tester, '2026-08');
        expect(painter.incomeColor, colors.chartPositive);
        expect(painter.expenseColor, colors.chartNegative);

        final rowIcon = tester.widget<Icon>(
          find.descendant(
            of: find.byKey(
              const ValueKey(
                '${CategoryBreakdownChart.rowKeyPrefix}seed_groceries',
              ),
            ),
            matching: find.byType(Icon),
          ),
        );
        expect(rowIcon.color, colors.negative);

        // Legend pairs each color with an icon and a label, never color
        // alone.
        expect(
          find.descendant(
            of: find.byKey(MonthlyTrendChart.incomeLegendKey),
            matching: find.text(en.reportsIncome),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(MonthlyTrendChart.incomeLegendKey),
            matching: find.byType(Icon),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
