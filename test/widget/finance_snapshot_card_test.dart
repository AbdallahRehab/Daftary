import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/dashboard/presentation/widgets/finance_snapshot_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/snapshot_error_card.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final period = DateRange(
    start: DateTime(2026, 9),
    end: DateTime(2026, 9, 30),
  );

  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
    theme: theme ?? buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  for (final theme in {
    'Light': buildLightTheme(),
    'Dark': buildDarkTheme(),
  }.entries) {
    testWidgets('${theme.key}: renders income, expenses, and net each with '
        'an icon, label, and themed color', (tester) async {
      await tester.pumpWidget(
        wrap(
          FinanceSnapshotCard(
            summary: FinanceSummary(
              totalIncome: const Money.egp(500000),
              totalExpense: const Money.egp(125050),
              period: period,
            ),
          ),
          theme: theme.value,
        ),
      );
      final colors = theme.value.extension<AppFinanceColors>()!;

      expect(find.text('This month'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Net'), findsOneWidget);
      expect(find.byIcon(Icons.south_west), findsOneWidget);
      expect(find.byIcon(Icons.north_east), findsOneWidget);
      expect(
        find.byIcon(Icons.account_balance_wallet_outlined),
        findsOneWidget,
      );

      expect(colorOf(tester, '5,000.00 EGP'), colors.positive);
      expect(colorOf(tester, '1,250.50 EGP'), colors.negative);
      expect(colorOf(tester, '3,749.50 EGP'), colors.positive);
    });
  }

  testWidgets('an overspent month shows a negative net in the negative '
      'color', (tester) async {
    await tester.pumpWidget(
      wrap(
        FinanceSnapshotCard(
          summary: FinanceSummary(
            totalIncome: const Money.egp(10000),
            totalExpense: const Money.egp(30000),
            period: period,
          ),
        ),
      ),
    );

    expect(
      colorOf(tester, '-200.00 EGP'),
      buildLightTheme().extension<AppFinanceColors>()!.negative,
    );
  });

  testWidgets('is tappable with a chevron only when onTap is given', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(FinanceSnapshotCard(summary: FinanceSummary.empty(period))),
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await tester.pumpWidget(
      wrap(
        FinanceSnapshotCard(
          summary: FinanceSummary.empty(period),
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await tester.tap(find.byType(FinanceSnapshotCard));
    expect(taps, 1);
  });

  testWidgets('SnapshotErrorCard shows its message and a localized retry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      wrap(SnapshotErrorCard(message: 'boom', onRetry: () => retries++)),
    );

    expect(find.text('boom'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });
}
