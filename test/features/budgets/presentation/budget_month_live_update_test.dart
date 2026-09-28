import 'dart:async';

import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/budgets/domain/usecases/copy_budget_to_month.dart';
import 'package:daftary/features/budgets/domain/usecases/get_most_recent_budget_before.dart';
import 'package:daftary/features/budgets/domain/usecases/watch_budget_for_month.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_month_cubit.dart';
import 'package:daftary/features/budgets/presentation/cubit/copy_budget_cubit.dart';
import 'package:daftary/features/budgets/presentation/pages/budget_month_page.dart';
import 'package:daftary/features/budgets/presentation/widgets/budget_rate_needed_badge.dart';
import 'package:daftary/features/currency/presentation/widgets/rate_needed_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/budgets_harness.dart';

/// 021 FR-031: the open budget month screen follows changes made elsewhere
/// — the real repositories on an in-memory database, no mocks — with no
/// navigation and no pull to refresh.
void main() {
  late BudgetsHarness h;
  const month = '2026-03';

  Widget app() => MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const BudgetMonthPage(month: month),
  );

  /// Lets the database streams deliver: the queries run on real time, the
  /// page's debounce timers (50 ms) on the test's fake time.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// Runs [work] while the page is open, in the test's zone, so the page's
  /// own re-queries (started by [work]'s writes) are pumped alongside it
  /// instead of holding the database lock.
  Future<void> drive(WidgetTester tester, Future<void> Function() work) async {
    var done = false;
    Object? error;
    unawaited(
      work().then(
        (_) => done = true,
        onError: (Object e) {
          error = e;
          done = true;
        },
      ),
    );
    for (var i = 0; i < 200 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    if (error != null) throw error!;
    expect(done, isTrue, reason: 'the work did not finish');
    await settle(tester);
  }

  Future<void> open(WidgetTester tester) async {
    await tester.runAsync(() async {
      h = await BudgetsHarness.open();
      final budget = await h.createBudget(month);
      await h.allocate(budget.id, groceries, 100000);
      await h.allocate(budget.id, rent, 500000);
    });
    getIt
      ..registerFactory<BudgetMonthCubit>(
        () => BudgetMonthCubit(WatchBudgetForMonth(h.repository)),
      )
      ..registerFactory<CopyBudgetCubit>(
        () => CopyBudgetCubit(
          GetMostRecentBudgetBefore(h.repository),
          CopyBudgetToMonth(h.repository),
        ),
      );
    await tester.pumpWidget(app());
    await settle(tester);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Lets the cancelled subscription finish before the database closes.
    await settle(tester);
    await tester.runAsync(h.close);
    await getIt.reset();
  }

  testWidgets('an expense recorded elsewhere updates the open budget '
      'screen', (tester) async {
    await open(tester);
    expect(find.text('0.00 EGP of 1,000.00 EGP'), findsOneWidget);

    await drive(tester, () => h.spend(groceries, 30000, DateTime(2026, 3, 4)));

    expect(find.text('300.00 EGP of 1,000.00 EGP'), findsOneWidget);
    expect(find.text('300.00 EGP'), findsOneWidget); // overall spent
    await dispose(tester);
  });

  testWidgets('spend needing a rate blocks only its row, and a rate set '
      'elsewhere unblocks the open budget screen', (tester) async {
    await open(tester);

    await drive(
      tester,
      () => h.spend(rent, 1000, DateTime(2026, 3, 5), currency: Currency.usd),
    );
    expect(find.byType(RateNeededBanner), findsOneWidget);
    // The rent row and the overall card are blocked; groceries is not.
    expect(find.byType(BudgetRateNeededBadge), findsNWidgets(2));
    expect(find.text('0.00 EGP of 1,000.00 EGP'), findsOneWidget);
    expect(find.text('5,000.00 EGP planned'), findsOneWidget);

    await drive(tester, () => h.setRate(Currency.usd, 50));

    expect(find.byType(RateNeededBanner), findsNothing);
    expect(find.byType(BudgetRateNeededBadge), findsNothing);
    // 10.00 USD at 50 → 500.00 EGP against rent's 5,000.00 plan.
    expect(find.text('500.00 EGP of 5,000.00 EGP'), findsOneWidget);
    await dispose(tester);
  });
}
