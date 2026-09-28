import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart';
import 'package:daftary/features/budgets/presentation/widgets/budget_category_progress_row.dart';
import 'package:daftary/features/budgets/presentation/widgets/over_budget_warning_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T039 — `OverBudgetWarningBadge` renders three visually distinct states
/// using more than color alone (icon + label), per the constitution's
/// Accessibility standard and FR-020, in both languages and both themes.
void main() {
  Widget wrap(
    Widget child, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? buildLightTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  const expected = {
    BudgetCategoryStatus.onTrack: (Icons.check_circle_outline, 'On track'),
    BudgetCategoryStatus.nearFull: (Icons.warning_amber_rounded, 'Near limit'),
    BudgetCategoryStatus.overBudget: (Icons.error_outline, 'Over budget'),
  };

  for (final MapEntry(key: status, value: (icon, label)) in expected.entries) {
    testWidgets('$status shows its own icon and label', (tester) async {
      await tester.pumpWidget(wrap(OverBudgetWarningBadge(status: status)));

      expect(find.byIcon(icon), findsOneWidget);
      expect(find.text(label), findsOneWidget);
      // Screen readers get the label too, not a color.
      expect(find.bySemanticsLabel(label), findsOneWidget);
    });
  }

  test('each state has a distinct icon', () {
    final icons = BudgetCategoryStatus.values.map(
      OverBudgetWarningBadge.iconFor,
    );
    expect(icons.toSet(), hasLength(3));
  });

  testWidgets('the three states use distinct colors in light and dark', (
    tester,
  ) async {
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      late BuildContext captured;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
          theme: theme,
        ),
      );
      final colors = BudgetCategoryStatus.values
          .map((s) => OverBudgetWarningBadge.colorFor(captured, s))
          .toSet();
      expect(colors, hasLength(3));
    }
  });

  testWidgets('labels are localized in Arabic', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OverBudgetWarningBadge(status: BudgetCategoryStatus.onTrack),
            OverBudgetWarningBadge(status: BudgetCategoryStatus.nearFull),
            OverBudgetWarningBadge(status: BudgetCategoryStatus.overBudget),
          ],
        ),
        locale: const Locale('ar'),
      ),
    );
    expect(find.text('ضمن الخطة'), findsOneWidget);
    expect(find.text('يقترب من الحد'), findsOneWidget);
    expect(find.text('تجاوز الميزانية'), findsOneWidget);
  });

  group('BudgetCategoryProgressRow (T033/T041)', () {
    BudgetCategoryLine line(int planned, int actual) => BudgetCategoryLine(
      allocationId: 'a1',
      categoryId: 'seed_groceries',
      categoryName: 'Groceries',
      categoryIcon: 'groceries',
      plannedAmountMinorUnits: planned,
      actualAmountMinorUnits: actual,
    );

    testWidgets('shows spent of planned, remaining and percentage '
        '(US2 scenario 1)', (tester) async {
      await tester.pumpWidget(
        wrap(BudgetCategoryProgressRow(line: line(600000, 350000))),
      );
      expect(find.text('3,500.00 EGP of 6,000.00 EGP'), findsOneWidget);
      expect(find.text('2,500.00 EGP left'), findsOneWidget);
      expect(find.text('58% used'), findsOneWidget);
      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('an over-budget line shows the overage amount and badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(BudgetCategoryProgressRow(line: line(200000, 250000))),
      );
      expect(find.text('500.00 EGP over'), findsOneWidget);
      expect(find.text('Over budget'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('near-full at 90%', (tester) async {
      await tester.pumpWidget(
        wrap(BudgetCategoryProgressRow(line: line(100000, 90000))),
      );
      expect(find.text('Near limit'), findsOneWidget);
      expect(find.text('90% used'), findsOneWidget);
    });

    testWidgets('zero spent shows 0% and the full plan remaining '
        '(US2 scenario 5)', (tester) async {
      await tester.pumpWidget(
        wrap(BudgetCategoryProgressRow(line: line(600000, 0))),
      );
      expect(find.text('0% used'), findsOneWidget);
      expect(find.text('6,000.00 EGP left'), findsOneWidget);
    });

    testWidgets('renders in Arabic RTL and dark mode without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 360,
            child: BudgetCategoryProgressRow(line: line(200000, 250000)),
          ),
          locale: const Locale('ar'),
          theme: buildDarkTheme(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('تجاوز الميزانية'), findsOneWidget);
      final direction = Directionality.of(
        tester.element(find.byType(BudgetCategoryProgressRow)),
      );
      expect(direction, TextDirection.rtl);
    });
  });
}
