import 'dart:async';

import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_mapper_registry.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:daftary/features/currency/presentation/widgets/rate_needed_banner.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/watch_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/watch_spending_trend.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_cubit.dart';
import 'package:daftary/features/finance/presentation/pages/reports_page.dart';
import 'package:daftary/features/finance/presentation/widgets/category_breakdown_chart.dart';
import 'package:daftary/features/finance/presentation/widgets/monthly_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/sync/fakes/server_rows.dart';
import '../../../core/sync/fakes/sync_harness.dart';
import '../../../helpers/test_daos.dart';

/// 021 FR-031: a change made on another device reaches an open Reports
/// screen through one sync cycle — the real repositories on an in-memory
/// database, [SyncEngine] against a [FakeSyncRemote] — with no navigation
/// and no pull to refresh.
void main() {
  late SyncHarness h;
  late FinanceRepositoryImpl finance;

  setUp(() {
    h = SyncHarness();
    final db = h.db;
    finance = FinanceRepositoryImpl(testFinanceDao(db));
    final currency = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    final context = GetConversionContext(currency);
    final watchContext = WatchConversionContext(currency);
    const converter = CurrencyConverterImpl();

    getIt.registerFactory<ReportsCubit>(
      () => ReportsCubit(
        WatchSpendingTrend(
          finance,
          watchContext,
          GetFinanceSummary(finance, context, converter),
        ),
        WatchCategoryBreakdown(
          finance,
          watchContext,
          GetCategoryBreakdown(finance, context, converter),
        ),
        finance,
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget app() => MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const ReportsPage(),
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
    expect(done, isTrue, reason: 'the sync work did not finish');
    await settle(tester);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Lets the cancelled subscriptions finish before the database closes.
    await settle(tester);
    await tester.runAsync(h.close);
  }

  /// A server row for an expense recorded today on another device.
  Map<String, Object?> expenseToday(
    String id, {
    required String categoryId,
    required int amount,
    String currencyCode = 'EGP',
  }) => {
    ...entryRow(id, categoryId: categoryId, amount: amount),
    ...SyncWire.occurrence(DateTime.now().millisecondsSinceEpoch),
    'currency_code': currencyCode,
  };

  ReportsCubit cubitOf(WidgetTester tester) =>
      BlocProvider.of<ReportsCubit>(tester.element(find.byType(ReportsView)));

  Finder row(String categoryId) =>
      find.byKey(ValueKey('${CategoryBreakdownChart.rowKeyPrefix}$categoryId'));

  testWidgets('an expense recorded on another device appears in the open '
      'trend and breakdown after one sync, without navigating', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await finance.addEntry(
        idempotencyKey: 'local-1',
        categoryId: 'seed_groceries',
        type: FinanceEntryType.expense,
        amount: const Money.egp(4575),
        date: DateTime.now(),
      );
      await h.engine.runCycle();
    });
    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.byType(MonthlyTrendChart), findsOneWidget);
    expect(row('seed_groceries'), findsOneWidget);
    expect(row('seed_fuel'), findsNothing);
    expect(cubitOf(tester).state.trend.last.totalExpenseMinorUnits, 4575);

    // Another device of the same account records a fuel expense today.
    h.remote.seedServerRow(
      SyncEntityType.financeEntry,
      expenseToday('e2', categoryId: 'seed_fuel', amount: 10000),
    );
    await drive(tester, () => h.engine.runCycle().then((_) {}));

    expect(row('seed_fuel'), findsOneWidget);
    expect(row('seed_groceries'), findsOneWidget);
    expect(
      cubitOf(tester).state.trend.last.totalExpenseMinorUnits,
      4575 + 10000,
    );
    await dispose(tester);
  });

  testWidgets('a rate set on another device clears the rate-needed banner '
      'after one sync', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await finance.addEntry(
        idempotencyKey: 'local-usd',
        categoryId: 'seed_fuel',
        type: FinanceEntryType.expense,
        amount: Money.fromMinorUnits(1000, Currency.usd),
        date: DateTime.now(),
      );
      await h.engine.runCycle();
    });
    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.byKey(RateNeededBanner.rootKey), findsOneWidget);
    expect(find.byType(MonthlyTrendChart), findsNothing);

    // 1 USD = 50 EGP, set on another device.
    h.remote.seedServerRow(SyncEntityType.exchangeRate, rateRow('USD', 'EGP'));
    await drive(tester, () => h.engine.runCycle().then((_) {}));

    expect(find.byKey(RateNeededBanner.rootKey), findsNothing);
    expect(find.byType(MonthlyTrendChart), findsOneWidget);
    expect(row('seed_fuel'), findsOneWidget);
    // 10.00 USD × 50 = 500.00 EGP.
    expect(cubitOf(tester).state.trend.last.totalExpenseMinorUnits, 50000);
    await dispose(tester);
  });
}
