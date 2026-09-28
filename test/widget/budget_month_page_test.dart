import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/usecases/copy_budget_to_month.dart';
import 'package:daftary/features/budgets/domain/usecases/get_budget_for_month.dart';
import 'package:daftary/features/budgets/domain/usecases/get_most_recent_budget_before.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_month_cubit.dart';
import 'package:daftary/features/budgets/presentation/cubit/copy_budget_cubit.dart';
import 'package:daftary/features/budgets/presentation/pages/budget_month_page.dart';
import 'package:daftary/features/budgets/presentation/widgets/budget_overall_summary_card.dart';
import 'package:daftary/features/budgets/presentation/widgets/unbudgeted_spending_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetForMonth extends Mock implements GetBudgetForMonth {}

class MockGetMostRecentBudgetBefore extends Mock
    implements GetMostRecentBudgetBefore {}

class MockCopyBudgetToMonth extends Mock implements CopyBudgetToMonth {}

/// The budget month screen (T035): FR-018 empty state, and the overall
/// card / category rows / unbudgeted card with an overall over-budget
/// marker (FR-009), in both languages and themes.
void main() {
  late MockGetBudgetForMonth getBudgetForMonth;
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
    getBudgetForMonth = MockGetBudgetForMonth();
    getMostRecentBudgetBefore = MockGetMostRecentBudgetBefore();
    // The empty state's copy-forward offer resolves its own cubit (US4).
    when(
      () => getMostRecentBudgetBefore(any()),
    ).thenAnswer((_) async => const Right(null));
    getIt.registerFactory<CopyBudgetCubit>(
      () => CopyBudgetCubit(getMostRecentBudgetBefore, MockCopyBudgetToMonth()),
    );
  });

  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    final cubit = BudgetMonthCubit(getBudgetForMonth);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit..load(month),
          child: const BudgetMonthView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no budget: friendly empty state with a create action '
      '(FR-018)', (tester) async {
    when(
      () => getBudgetForMonth(month),
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
      () => getBudgetForMonth(month),
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
      () => getBudgetForMonth(month),
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
      () => getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(overBudgetDetail));
    await pump(tester, locale: const Locale('ar'), theme: buildDarkTheme());

    expect(tester.takeException(), isNull);
    expect(find.text('الإجمالي'), findsOneWidget);
    expect(find.text('تجاوز الميزانية'), findsNWidgets(2));
  });
}
