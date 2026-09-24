import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/presentation/widgets/rate_needed_banner.dart';
import 'package:daftary/features/finance/domain/entities/category_breakdown_item.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/presentation/widgets/category_breakdown_bar.dart';
import 'package:daftary/features/finance/presentation/widgets/finance_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 018 FR-009: a blocked total is replaced by the RateNeededBanner naming the
/// missing currency — never a partial or 1:1-converted figure.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  final period = DateRange.thisMonth(DateTime(2026, 3, 18));

  testWidgets('a resolved summary shows its totals and no banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        FinanceSummaryCard(
          summary: FinanceSummary(
            totalIncome: const Money.egp(100000),
            totalExpense: const Money.egp(2550),
            period: period,
          ),
        ),
      ),
    );

    expect(find.byKey(RateNeededBanner.rootKey), findsNothing);
    expect(find.text('1,000.00 EGP'), findsOneWidget);
    expect(find.text('974.50 EGP'), findsOneWidget);
  });

  testWidgets('a blocked summary shows the banner naming the currency', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        FinanceSummaryCard(
          summary: FinanceSummary.blocked(
            period: period,
            currency: Currency.egp,
            missingRatesFor: const [Currency.usd],
          ),
        ),
      ),
    );

    expect(find.byKey(RateNeededBanner.rootKey), findsOneWidget);
    expect(find.textContaining('USD'), findsWidgets);
    expect(find.textContaining('EGP'), findsNothing);
  });

  testWidgets('a blocked breakdown shows the banner and no shares', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const CategoryBreakdownBar(
          breakdown: CategoryBreakdown(
            missingRatesFor: [Currency.eur],
            items: [
              CategoryBreakdownItem(
                categoryId: 'seed_rent',
                categoryName: 'Rent',
                icon: 'rent',
                total: Money.egp(100000),
                shareOfPeriod: null,
              ),
              CategoryBreakdownItem(
                categoryId: 'seed_groceries',
                categoryName: 'Groceries',
                icon: 'groceries',
                total: null,
                shareOfPeriod: null,
              ),
            ],
          ),
          categoriesById: {},
        ),
      ),
    );

    expect(find.byKey(RateNeededBanner.rootKey), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('1,000.00 EGP'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });
}
