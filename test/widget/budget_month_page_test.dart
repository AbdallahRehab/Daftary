import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/currency/presentation/widgets/rate_needed_banner.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/usecases/copy_budget_to_month.dart';
import 'package:daftary/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:daftary/features/budgets/domain/usecases/get_most_recent_budget_before.dart';
import 'package:daftary/features/budgets/domain/usecases/watch_budget_for_month.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_month_cubit.dart';
import 'package:daftary/features/budgets/presentation/cubit/copy_budget_cubit.dart';
import 'package:daftary/features/budgets/presentation/pages/budget_month_page.dart';
import 'package:daftary/features/budgets/presentation/widgets/budget_overall_summary_card.dart';
import 'package:daftary/features/budgets/presentation/widgets/budget_rate_needed_badge.dart';
import 'package:daftary/features/budgets/presentation/widgets/unbudgeted_spending_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../features/budgets/helpers/budget_watch_stubs.dart';
import '../helpers/watch_stubs.dart';

class MockBudgetsRepository extends Mock implements BudgetsRepository {}

class MockGetMostRecentBudgetBefore extends Mock
    implements GetMostRecentBudgetBefore {}

class MockCopyBudgetToMonth extends Mock implements CopyBudgetToMonth {}

/// The budget month screen (T035): FR-018 empty state, and the overall
/// card / category rows / unbudgeted card with an overall over-budget
/// marker (FR-009), in both languages and themes — and (018 FR-009) the
/// per-line blocked state when spend needs a missing exchange rate.
void main() {
  late MockBudgetsRepository repository;
  late FakeTableChanges changes;
  late MockGetMostRecentBudgetBefore getMostRecentBudgetBefore;
  const month = '2026-09';
  final now = DateTime(2026, 9, 1);

  final overBudgetDetail = BudgetMonthDetail(
    month: month,
    budget: Budget(
      id: 'b1',
      idempotencyKey: 'k',
      month: month,
      expectedIncomeMinorUnits: 500000,
      createdAt: now,
      updatedAt: now,
    ),
    summary: const BudgetSummary(
      budgetId: 'b1',
      categoryBreakdown: [
        BudgetCategoryLine(
          allocationId: 'a1',
          categoryId: 'seed_entertainment',
          categoryName: 'Entertainment',
          categoryIcon: 'entertainment',
          plannedAmountMinorUnits: 200000,
          actualAmountMinorUnits: 260000,
        ),
        BudgetCategoryLine(
          allocationId: 'a2',
          categoryId: 'seed_rent',
          categoryName: 'Rent',
          categoryIcon: 'rent',
          plannedAmountMinorUnits: 700000,
          actualAmountMinorUnits: 700000,
        ),
      ],
      unbudgetedSpending: [
        UnbudgetedCategorySpend(
          categoryId: 'seed_fuel',
          categoryName: 'Fuel',
          categoryIcon: 'fuel',
          amountMinorUnits: 45000,
        ),
      ],
    ),
  );

  setUp(() {
    repository = MockBudgetsRepository();
    changes = FakeTableChanges();
    stubBudgetsWatches(repository, changes);
    getMostRecentBudgetBefore = MockGetMostRecentBudgetBefore();
    // The empty state's copy-forward offer resolves its own cubit (US4).
    when(
      () => getMostRecentBudgetBefore(any()),
    ).thenAnswer((_) async => const Right(null));
    getIt.registerFactory<CopyBudgetCubit>(
      () => CopyBudgetCubit(getMostRecentBudgetBefore, MockCopyBudgetToMonth()),
    );
  });

  tearDown(() async {
    await changes.close();
    await getIt.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    final cubit = BudgetMonthCubit(WatchBudgetForMonth(repository));
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit..subscribe(month),
          child: const BudgetMonthView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no budget: friendly empty state with a create action '
      '(FR-018)', (tester) async {
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => const Right(BudgetMonthDetail.empty(month)));
    await pump(tester);

    expect(find.text('No budget for September 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('budgetCreateAction')), findsOneWidget);
    expect(find.byType(BudgetOverallSummaryCard), findsNothing);
    // No earlier budget → no copy-forward offer (US4 scenario 3).
    expect(find.byKey(const ValueKey('budgetCopyForwardAction')), findsNothing);
  });

  testWidgets('no budget but an earlier one exists: offers copy-forward '
      '(US4)', (tester) async {
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => const Right(BudgetMonthDetail.empty(month)));
    when(() => getMostRecentBudgetBefore(month)).thenAnswer(
      (_) async => Right(
        Budget(
          id: 'b0',
          idempotencyKey: 'k0',
          month: '2026-08',
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );
    await pump(tester);

    expect(
      find.byKey(const ValueKey('budgetCopyForwardAction')),
      findsOneWidget,
    );
    expect(find.text("Copy August 2026's budget"), findsOneWidget);
  });

  testWidgets('a budget renders overall summary, rows and unbudgeted '
      'spending, overall marked over budget (FR-006/FR-007/FR-009)', (
    tester,
  ) async {
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(overBudgetDetail));
    await pump(tester);

    expect(find.byType(BudgetOverallSummaryCard), findsOneWidget);
    // Overall: planned 9,000, actual 9,600 → over by 600.
    expect(find.text('Over by'), findsOneWidget);
    expect(find.text('600.00 EGP'), findsOneWidget);
    // Overall badge + Entertainment's badge.
    expect(find.text('Over budget'), findsNWidgets(2));
    // Rent at exactly 100% is near-full, not over (US3 scenario 1).
    expect(find.text('100% used'), findsOneWidget);
    // Planned 9,000 exceeds the 5,000 expected income (FR-004).
    expect(
      find.text('Planned spending exceeds expected income by 4,000.00 EGP'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.byType(UnbudgetedSpendingCard), 200);
    expect(find.text('Unbudgeted spending'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);
  });

  testWidgets('renders in Arabic RTL, dark mode, without layout errors '
      '(FR-020)', (tester) async {
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(overBudgetDetail));
    await pump(tester, locale: const Locale('ar'), theme: buildDarkTheme());

    expect(tester.takeException(), isNull);
    expect(find.text('الإجمالي'), findsOneWidget);
    expect(find.text('تجاوز الميزانية'), findsNWidgets(2));
  });

  group('018 FR-009: spend needing a missing exchange rate', () {
    final blockedDetail = BudgetMonthDetail(
      month: month,
      budget: Budget(
        id: 'b1',
        idempotencyKey: 'k',
        month: month,
        createdAt: now,
        updatedAt: now,
      ),
      summary: const BudgetSummary(
        budgetId: 'b1',
        categoryBreakdown: [
          BudgetCategoryLine(
            allocationId: 'a1',
            categoryId: 'seed_entertainment',
            categoryName: 'Entertainment',
            categoryIcon: 'entertainment',
            plannedAmountMinorUnits: 200000,
            actualAmountMinorUnits: null,
            missingRatesFor: [Currency.usd],
          ),
          BudgetCategoryLine(
            allocationId: 'a2',
            categoryId: 'seed_rent',
            categoryName: 'Rent',
            categoryIcon: 'rent',
            plannedAmountMinorUnits: 700000,
            actualAmountMinorUnits: 350000,
          ),
        ],
        unbudgetedSpending: [
          UnbudgetedCategorySpend(
            categoryId: 'seed_fuel',
            categoryName: 'Fuel',
            categoryIcon: 'fuel',
            amountMinorUnits: null,
            missingRatesFor: [Currency.eur],
          ),
        ],
      ),
    );

    testWidgets('a banner names every currency, only the blocked row is '
        'marked, planned figures still show, and totals read blocked', (
      tester,
    ) async {
      when(
        () => repository.getBudgetForMonth(month),
      ).thenAnswer((_) async => Right(blockedDetail));
      await pump(tester);

      expect(find.byType(RateNeededBanner), findsOneWidget);
      expect(
        find.text(
          'Add an exchange rate for USD, EUR to see this total. '
          'Your records are safe and unchanged.',
        ),
        findsOneWidget,
      );
      // The blocked row: its plan and a rate-needed marker, no figures.
      expect(
        find.byKey(const ValueKey('budgetLineRateNeeded-a1')),
        findsOneWidget,
      );
      expect(find.text('2,000.00 EGP planned'), findsOneWidget);
      expect(
        find.text('Spending needs an exchange rate for USD'),
        findsOneWidget,
      );
      // The other row is unaffected.
      expect(find.text('3,500.00 EGP of 7,000.00 EGP'), findsOneWidget);
      expect(find.text('50% used'), findsOneWidget);
      // Overall: planned shows, spent/remaining are blocked.
      expect(find.text('9,000.00 EGP'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('budgetOverallRateNeeded')),
        findsOneWidget,
      );
      expect(
        find.text('Spent and remaining need an exchange rate for USD'),
        findsOneWidget,
      );
      expect(find.byType(BudgetRateNeededBadge), findsNWidgets(2));
      expect(find.text('Over budget'), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('budgetUnbudgetedRateNeeded-seed_fuel')),
        200,
      );
      expect(find.text('Fuel'), findsOneWidget);
    });

    testWidgets('a rate set elsewhere clears the banner on the open screen '
        '(021 FR-031)', (tester) async {
      var detail = blockedDetail;
      when(
        () => repository.getBudgetForMonth(month),
      ).thenAnswer((_) async => Right(detail));
      await pump(tester);
      expect(find.byType(RateNeededBanner), findsOneWidget);

      detail = overBudgetDetail;
      changes.notify();
      await tester.pumpAndSettle();

      expect(find.byType(RateNeededBanner), findsNothing);
      expect(find.byType(BudgetRateNeededBadge), findsNothing);
      expect(find.text('Over budget'), findsNWidgets(2));
    });

    testWidgets('renders blocked rows in Arabic RTL, dark mode, without '
        'layout errors', (tester) async {
      when(
        () => repository.getBudgetForMonth(month),
      ).thenAnswer((_) async => Right(blockedDetail));
      await pump(tester, locale: const Locale('ar'), theme: buildDarkTheme());

      expect(tester.takeException(), isNull);
      expect(find.text('يلزم سعر صرف'), findsNWidgets(2));
    });
  });
}
