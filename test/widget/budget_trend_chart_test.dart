import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/budgets/domain/entities/budget_trend_point.dart';
import 'package:daftary/features/budgets/presentation/widgets/budget_trend_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Oldest first, as GetBudgetTrend returns them. August is over plan; June
  // had spending but no budget.
  const points = [
    BudgetTrendPoint(
      month: '2026-06',
      plannedMinorUnits: 0,
      actualMinorUnits: 1200000,
      hasBudget: false,
    ),
    BudgetTrendPoint(
      month: '2026-07',
      plannedMinorUnits: 3000000,
      actualMinorUnits: 2800000,
      hasBudget: true,
    ),
    BudgetTrendPoint(
      month: '2026-08',
      plannedMinorUnits: 3000000,
      actualMinorUnits: 3250050,
      hasBudget: true,
    ),
  ];

  Widget wrap({
    required Locale locale,
    ThemeData? theme,
    List<BudgetTrendPoint> data = points,
  }) {
    return MaterialApp(
      theme: theme ?? buildLightTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BudgetTrendChart(
            points: data,
            animationDuration: Duration.zero,
          ),
        ),
      ),
    );
  }

  BarChartData chartData(WidgetTester tester) =>
      tester.widget<BarChart>(find.byType(BarChart)).data;

  double labelX(WidgetTester tester, String month) =>
      tester.getCenter(find.byKey(ValueKey('budgetTrendMonthLabel-$month'))).dx;

  testWidgets('renders one planned/actual bar group per month, oldest first '
      'in LTR', (tester) async {
    await tester.pumpWidget(wrap(locale: const Locale('en')));
    await tester.pumpAndSettle();

    final groups = chartData(tester).barGroups;
    expect(groups, hasLength(3));
    for (final group in groups) {
      expect(group.barRods, hasLength(2));
    }
    // [planned, actual] in major units, in chronological order.
    expect(
      [
        for (final g in groups) [g.barRods[0].toY, g.barRods[1].toY],
      ],
      [
        [0.0, 12000.0],
        [30000.0, 28000.0],
        [30000.0, 32500.5],
      ],
    );

    // Month labels run left-to-right, oldest to newest.
    expect(labelX(tester, '2026-06'), lessThan(labelX(tester, '2026-07')));
    expect(labelX(tester, '2026-07'), lessThan(labelX(tester, '2026-08')));
    expect(find.text('Jun'), findsOneWidget);
    expect(find.text('Aug'), findsOneWidget);

    // Amount axis on the reading-start (left) edge.
    final titles = chartData(tester).titlesData;
    expect(titles.leftTitles.sideTitles.showTitles, isTrue);
    expect(titles.rightTitles.sideTitles.showTitles, isFalse);
  });

  testWidgets('legend distinguishes planned/actual by label and shape, and '
      'flags the over-plan month with a glyph, not color alone', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('Actual'), findsOneWidget);
    expect(find.text('Over plan'), findsOneWidget);
    // One in the legend, one under August's month label.
    expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));

    // Planned bars are outlined; actual bars are solid.
    final group = chartData(tester).barGroups[1];
    expect(group.barRods[0].borderSide.width, greaterThan(0));
    expect(group.barRods[1].borderSide.width, 0);
  });

  testWidgets('mirrors in RTL: newest month first from the left, oldest at '
      'the right, amount axis on the right edge', (tester) async {
    await tester.pumpWidget(wrap(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    final data = chartData(tester);
    final groups = data.barGroups;
    expect(groups, hasLength(3));
    // Display order reversed; within a group the rods are reversed too, so
    // "planned" stays on each group's reading-start (right) side.
    expect(
      [
        for (final g in groups) [g.barRods[0].toY, g.barRods[1].toY],
      ],
      [
        [32500.5, 30000.0],
        [28000.0, 30000.0],
        [12000.0, 0.0],
      ],
    );

    // Axis labels mirrored: the oldest month sits at the right.
    expect(labelX(tester, '2026-06'), greaterThan(labelX(tester, '2026-07')));
    expect(labelX(tester, '2026-07'), greaterThan(labelX(tester, '2026-08')));

    expect(data.titlesData.leftTitles.sideTitles.showTitles, isFalse);
    expect(data.titlesData.rightTitles.sideTitles.showTitles, isTrue);

    // Localized legend.
    expect(find.text('المخطط'), findsOneWidget);
    expect(find.text('الفعلي'), findsOneWidget);
  });

  testWidgets('month labels and axis values use Western digits under Arabic '
      '(FR-011)', (tester) async {
    await tester.pumpWidget(wrap(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    final arabicIndic = RegExp('[٠-٩]');
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.data ?? '', isNot(matches(arabicIndic)));
    }
  });

  testWidgets('renders under the dark theme with theme-token colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(locale: const Locale('en'), theme: buildDarkTheme()),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(BarChart));
    final scheme = Theme.of(context).colorScheme;
    final group = chartData(tester).barGroups[1];
    expect(group.barRods[0].borderSide.color, scheme.primary);
    expect(group.barRods[1].color, scheme.tertiary);
    // The over-plan month's actual bar uses the theme's negative token.
    final over = chartData(tester).barGroups[2];
    expect(over.barRods[1].color, context.financeColors.negative);
  });
}
