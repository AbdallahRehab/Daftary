import 'dart:math';

import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_month.dart';
import 'package:daftary/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:daftary/features/budgets/presentation/widgets/budget_category_progress_row.dart';
import 'package:daftary/features/budgets/presentation/widgets/budget_overall_summary_card.dart';
import 'package:daftary/features/budgets/presentation/widgets/budget_trend_chart.dart';
import 'package:daftary/features/budgets/presentation/widgets/unbudgeted_spending_card.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// T061 — end-to-end coverage of 010 Household Budgets against the real app
/// (real DI, real on-device SQLite), following quickstart.md's manual
/// scenarios 1-5.
///
/// The on-device database persists between runs and a month can hold only
/// one budget, so every test works in months nobody else uses: a randomly
/// picked far-future window, verified empty (no budget, no spend) before
/// use. Categories are created per test with a timestamp suffix, so their
/// spend is never mixed with anything else's. Past/future-month expenses
/// are seeded through 007's `FinanceRepository` — the same insert path the
/// expense form uses — because the form always dates a new entry today.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `lib/main.dart`'s own `main()` is never invoked by an integration test,
  // so DI bootstrap has to happen explicitly before the first `pumpWidget`.
  setUpAll(() async => configureDependencies());

  final random = Random();
  final egp = EgpFormatter(locale: 'en');
  String money(int minorUnits) =>
      egp.formatWithSymbol(Money.fromMinorUnits(minorUnits));

  BudgetsRepository budgets() => getIt<BudgetsRepository>();
  FinanceRepository finance() => getIt<FinanceRepository>();
  CategoryRepository categories() => getIt<CategoryRepository>();

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  var seq = 0;
  String key(String base) =>
      'it-budgets-$base-${DateTime.now().microsecondsSinceEpoch}-${seq++}';
  String unique(String base) =>
      '$base ${DateTime.now().millisecondsSinceEpoch}${seq++}';

  /// The first of [span] consecutive months, none of which — nor the six
  /// months before them, which the trend window can reach — has a budget or
  /// any expense yet.
  Future<String> freshMonths(int span) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final first = BudgetMonth.fromDate(
        DateTime(2300 + random.nextInt(700), 1 + random.nextInt(12)),
      );
      final window = await budgets().getBudgetTrend(
        endMonth: BudgetMonth.shift(first, span),
        monthsBack: span + 8,
      );
      final points = window.getOrElse((f) => throw StateError(f.message));
      if (points.every((p) => !p.hasBudget && p.actualMinorUnits == 0)) {
        return first;
      }
    }
    throw StateError('No unused month window found');
  }

  Future<Category> newExpenseCategory(String base) async {
    final created = await categories().createCategory(
      name: unique(base),
      type: CategoryType.expense,
      icon: 'other',
    );
    return created.getOrElse((f) => throw StateError(f.message));
  }

  Future<Budget> createBudget(
    String month,
    Map<Category, int> plannedMinorUnits, {
    int? income,
  }) async {
    final created = await budgets().createBudget(
      idempotencyKey: key('budget'),
      month: month,
      expectedIncomeMinorUnits: income,
    );
    final budget = created.getOrElse((f) => throw StateError(f.message));
    for (final entry in plannedMinorUnits.entries) {
      final added = await budgets().addBudgetCategoryAllocation(
        idempotencyKey: key('allocation'),
        budgetId: budget.id,
        categoryId: entry.key.id,
        plannedAmountMinorUnits: entry.value,
      );
      added.getOrElse((f) => throw StateError(f.message));
    }
    return budget;
  }

  Future<FinanceEntry> spend(
    Category category,
    int minorUnits,
    String month, {
    int day = 10,
  }) async {
    final start = BudgetMonth.toDate(month);
    final added = await finance().addEntry(
      idempotencyKey: key('expense'),
      categoryId: category.id,
      type: FinanceEntryType.expense,
      amountMinorUnits: minorUnits,
      date: DateTime(start.year, start.month, day),
    );
    return added.getOrElse((f) => throw StateError(f.message));
  }

  Future<void> openBudgetMonth(WidgetTester tester, String month) async {
    // `appRouter` is a module-level singleton that keeps wherever the
    // previous test left it — reset explicitly so each test starts on a
    // known screen.
    appRouter.go('/budgets/$month');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    // `tester.tap` on an off-screen widget only warns rather than failing,
    // so a missed tap would otherwise surface much later and far away.
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester, AppLocalizations l10n) async {
    // The keyboard can still cover Save right after typing.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(l10n.commonSave));
  }

  /// The progress row for [category] on the month screen.
  Finder rowFor(Category category) => find.ancestor(
    of: find.text(category.name),
    matching: find.byType(BudgetCategoryProgressRow),
  );

  /// Expects [text] inside [category]'s progress row, scrolling it into view
  /// first — the list runs past the fold once a few rows are present.
  Future<void> expectInRow(
    WidgetTester tester,
    Category category,
    String text,
  ) async {
    await tester.ensureVisible(rowFor(category));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: rowFor(category), matching: find.text(text)),
      findsOneWidget,
      reason: '"$text" in the ${category.name} row',
    );
  }

  /// Re-reads the open month by stepping away and back with the month
  /// navigator — the route a user takes after editing expenses elsewhere.
  Future<void> revisitMonth(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('monthNavigatorNext')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('monthNavigatorPrevious')));
    await tester.pumpAndSettle();
  }

  Finder allocationField(Category category) => find.descendant(
    of: find.byKey(ValueKey('allocation-${category.id}')),
    matching: find.byType(TextField),
  );

  testWidgets('create a budget and allocate categories: negative amounts are '
      'blocked, exceeding income only warns, and a category created from the '
      'picker is usable at once (US1; quickstart.md Scenario 1)', (
    tester,
  ) async {
    final l10n = await english();
    final month = await freshMonths(1);
    final rent = await newExpenseCategory('Rent');
    final food = await newExpenseCategory('Food');
    final transport = await newExpenseCategory('Transport');

    await openBudgetMonth(tester, month);

    // FR-018: an empty month offers to create a budget.
    expect(find.byKey(const ValueKey('budgetCreateAction')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('budgetCreateAction')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.budgetFormCreateTitle), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, l10n.budgetExpectedIncomeLabel),
      '15000',
    );
    await tester.pumpAndSettle();

    for (final category in [rent, food, transport]) {
      await tapVisible(tester, find.widgetWithText(ChoiceChip, category.name));
    }
    expect(allocationField(rent), findsOneWidget);
    expect(allocationField(food), findsOneWidget);
    expect(allocationField(transport), findsOneWidget);

    // Scenario 1.2: a negative amount is refused with a clear message.
    await tester.enterText(allocationField(rent), '-7000');
    await tester.enterText(allocationField(food), '6000');
    await tester.enterText(allocationField(transport), '3000');
    await tester.pumpAndSettle();
    await tapSave(tester, l10n);
    expect(find.text(l10n.budgetFormCreateTitle), findsOneWidget);
    expect(find.text(l10n.budgetAmountNegativeError), findsOneWidget);

    // Scenario 1.3: 16,000 planned against 15,000 expected income is
    // flagged, but does not block the save.
    await tester.enterText(allocationField(rent), '7000');
    await tester.pumpAndSettle();
    expect(find.text(l10n.budgetAmountNegativeError), findsNothing);
    expect(
      find.text(l10n.budgetExceedsIncomeWarning(money(100000))),
      findsOneWidget,
    );

    // Scenario 1.4: a category created from the picker's "manage" link
    // shows up in the picker straight away.
    final inlineName = unique('Inline');
    await tapVisible(
      tester,
      find.text(l10n.financeManageCategoriesAction).first,
    );
    await tester.tap(
      find.widgetWithText(FloatingActionButton, l10n.financeAddCategoryAction),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.financeCategoryNameLabel),
      inlineName,
    );
    await tapVisible(tester, find.byKey(const ValueKey('categoryIcon_other')));
    await tapSave(tester, l10n);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(l10n.budgetFormCreateTitle), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(ChoiceChip, inlineName));
    final inline =
        (await categories().getCategories(type: CategoryType.expense))
            .getOrElse((f) => throw StateError(f.message))
            .firstWhere((c) => c.name == inlineName);
    await tester.enterText(allocationField(inline), '500');
    await tester.pumpAndSettle();

    await tapSave(tester, l10n);

    // Saved: back on the month screen, each category showing its plan.
    expect(find.text(l10n.budgetFormCreateTitle), findsNothing);
    expect(find.byType(BudgetOverallSummaryCard), findsOneWidget);
    await expectInRow(
      tester,
      rent,
      l10n.budgetSpentOfPlanned(money(0), money(700000)),
    );
    await expectInRow(
      tester,
      food,
      l10n.budgetSpentOfPlanned(money(0), money(600000)),
    );
    await expectInRow(
      tester,
      transport,
      l10n.budgetSpentOfPlanned(money(0), money(300000)),
    );
    await expectInRow(
      tester,
      inline,
      l10n.budgetSpentOfPlanned(money(0), money(50000)),
    );

    final saved = (await budgets().getBudgetForMonth(
      month,
    )).getOrElse((f) => throw StateError(f.message));
    expect(saved.budget!.expectedIncomeMinorUnits, 1500000);
    expect(saved.summary!.totalPlannedMinorUnits, 1650000);
  });

  testWidgets('an expense recorded through the expense form counts against '
      "the current month's budget (US2; quickstart.md Scenario 2.1)", (
    tester,
  ) async {
    final l10n = await english();
    final month = BudgetMonth.current();
    final category = await newExpenseCategory('Form food');

    // The current month may already have a budget from earlier runs; the
    // category is new either way, so its figures are this test's alone.
    final existing = (await budgets().getBudgetForMonth(
      month,
    )).getOrElse((f) => throw StateError(f.message));
    if (existing.budget == null) {
      await createBudget(month, {category: 600000});
    } else {
      final added = await budgets().addBudgetCategoryAllocation(
        idempotencyKey: key('allocation'),
        budgetId: existing.budget!.id,
        categoryId: category.id,
        plannedAmountMinorUnits: 600000,
      );
      added.getOrElse((f) => throw StateError(f.message));
    }

    appRouter.go('/finance');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FloatingActionButton, l10n.financeAddExpenseAction),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.amountLabel),
      '3500',
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(ChoiceChip, category.name));
    await tapSave(tester, l10n);

    appRouter.go('/budgets/$month');
    await tester.pumpAndSettle();
    await expectInRow(
      tester,
      category,
      l10n.budgetSpentOfPlanned(money(350000), money(600000)),
    );
    await expectInRow(
      tester,
      category,
      l10n.budgetRemainingAmount(money(250000)),
    );
    await expectInRow(tester, category, l10n.budgetPercentUsed(58));
  });

  testWidgets('planned vs. actual: figures, unbudgeted spending, and edits '
      'and deletes of expenses all show up (US2; quickstart.md Scenario 2)', (
    tester,
  ) async {
    final l10n = await english();
    final month = await freshMonths(2);
    final food = await newExpenseCategory('Food');
    final rent = await newExpenseCategory('Rent');
    final transport = await newExpenseCategory('Transport');
    final gifts = await newExpenseCategory('Unplanned');

    await createBudget(month, {food: 600000, rent: 700000, transport: 300000});
    final foodExpense = await spend(food, 350000, month);
    final rentExpense = await spend(rent, 100000, month, day: 3);
    await spend(gifts, 25000, month, day: 5);

    await openBudgetMonth(tester, month);

    // 2.1: 3,500 of 6,000 — 2,500 left, 58% used.
    await expectInRow(
      tester,
      food,
      l10n.budgetSpentOfPlanned(money(350000), money(600000)),
    );
    await expectInRow(tester, food, l10n.budgetRemainingAmount(money(250000)));
    await expectInRow(tester, food, l10n.budgetPercentUsed(58));

    // 2.4: a budgeted category with nothing spent is 0%, fully remaining.
    await expectInRow(tester, transport, l10n.budgetPercentUsed(0));
    await expectInRow(
      tester,
      transport,
      l10n.budgetRemainingAmount(money(300000)),
    );

    // The overall summary covers budgeted categories only: 4,500 of 16,000.
    final summary = find.byType(BudgetOverallSummaryCard);
    await tester.ensureVisible(summary);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: summary, matching: find.text(money(450000))),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text(money(1600000))),
      findsOneWidget,
    );

    // 2.2: spend outside the budget is listed separately, not folded in.
    final unbudgeted = find.byType(UnbudgetedSpendingCard);
    await tester.ensureVisible(unbudgeted);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: unbudgeted, matching: find.text(gifts.name)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: unbudgeted, matching: find.text(money(25000))),
      findsWidgets,
    );
    expect(rowFor(gifts), findsNothing);

    // 2.3: edit 3,500 -> 4,000 and delete the rent expense.
    final edited = await finance().editEntry(
      entryId: foodExpense.id,
      categoryId: food.id,
      amountMinorUnits: 400000,
      date: foodExpense.date,
    );
    expect(edited.isRight(), isTrue);
    expect((await finance().deleteEntry(rentExpense.id)).isRight(), isTrue);

    await revisitMonth(tester);

    await expectInRow(
      tester,
      food,
      l10n.budgetSpentOfPlanned(money(400000), money(600000)),
    );
    await expectInRow(tester, food, l10n.budgetPercentUsed(66));
    await expectInRow(
      tester,
      rent,
      l10n.budgetSpentOfPlanned(money(0), money(700000)),
    );
    await expectInRow(tester, rent, l10n.budgetRemainingAmount(money(700000)));
  });

  testWidgets('warning states: on track, near full, the 100% boundary, over '
      'budget, and the overall over-budget flag (US3; quickstart.md '
      'Scenario 3)', (tester) async {
    final l10n = await english();
    final month = await freshMonths(2);
    final entertainment = await newExpenseCategory('Entertainment');
    final groceries = await newExpenseCategory('Groceries');
    final transport = await newExpenseCategory('Transport');

    await createBudget(month, {
      entertainment: 100000,
      groceries: 100000,
      transport: 100000,
    });
    await spend(entertainment, 100000, month); // exactly 100%
    await spend(groceries, 90000, month); // 90%: near full
    await spend(transport, 10000, month); // 10%: on track

    await openBudgetMonth(tester, month);

    // 3.1 (boundary): 100% used, nothing left, not yet over.
    await expectInRow(tester, entertainment, l10n.budgetPercentUsed(100));
    await expectInRow(
      tester,
      entertainment,
      l10n.budgetRemainingAmount(money(0)),
    );
    await expectInRow(tester, entertainment, l10n.budgetStatusNearFull);
    // 3.2: ~90% is its own "near full" state, distinct from on-track.
    await expectInRow(tester, groceries, l10n.budgetStatusNearFull);
    await expectInRow(tester, transport, l10n.budgetStatusOnTrack);

    // 2,000 of 3,000 overall: not over.
    final summary = find.byType(BudgetOverallSummaryCard);
    await tester.ensureVisible(summary);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: summary,
        matching: find.text(l10n.budgetStatusOverBudget),
      ),
      findsNothing,
    );

    // 3.1 (past it): the overage amount is shown.
    await spend(entertainment, 20000, month, day: 12);
    // 3.3: 1,300 more pushes the total (3,300) past the plan (3,000).
    await spend(transport, 110000, month, day: 14);
    await revisitMonth(tester);

    await expectInRow(tester, entertainment, l10n.budgetStatusOverBudget);
    await expectInRow(
      tester,
      entertainment,
      l10n.budgetOverByAmount(money(20000)),
    );
    await expectInRow(tester, transport, l10n.budgetStatusOverBudget);
    await expectInRow(tester, groceries, l10n.budgetStatusNearFull);

    await tester.ensureVisible(summary);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: summary,
        matching: find.text(l10n.budgetStatusOverBudget),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text(l10n.budgetOverByLabel)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text(money(30000))),
      findsOneWidget,
    );
  });

  testWidgets('copy forward: the next month is created from the previous one '
      'and edited independently; no copy offer when nothing precedes it '
      '(US4; quickstart.md Scenario 4)', (tester) async {
    final l10n = await english();
    final source = await freshMonths(3);
    final target = BudgetMonth.shift(source, 1);
    final rent = await newExpenseCategory('Rent');
    final food = await newExpenseCategory('Food');
    await createBudget(source, {rent: 500000, food: 200000}, income: 900000);

    await openBudgetMonth(tester, source);
    await expectInRow(
      tester,
      rent,
      l10n.budgetSpentOfPlanned(money(0), money(500000)),
    );

    // Month navigation to the empty next month, which offers the copy.
    await tester.tap(find.byKey(const ValueKey('monthNavigatorNext')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('budgetCreateAction')), findsOneWidget);
    final copy = find.byKey(const ValueKey('budgetCopyForwardAction'));
    expect(copy, findsOneWidget);

    final stopwatch = Stopwatch()..start();
    await tapVisible(tester, copy);
    stopwatch.stop();

    // 4.1: identical categories and amounts, in one tap.
    await expectInRow(
      tester,
      rent,
      l10n.budgetSpentOfPlanned(money(0), money(500000)),
    );
    await expectInRow(
      tester,
      food,
      l10n.budgetSpentOfPlanned(money(0), money(200000)),
    );
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));

    // 4.2: edit the copy's Rent plan to 5,500.
    await tester.tap(find.byTooltip(l10n.budgetFormEditTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.budgetFormEditTitle), findsWidgets);
    await tester.ensureVisible(allocationField(rent));
    await tester.enterText(allocationField(rent), '5500');
    await tester.pumpAndSettle();
    await tapSave(tester, l10n);

    await expectInRow(
      tester,
      rent,
      l10n.budgetSpentOfPlanned(money(0), money(550000)),
    );

    // ...and the source month is untouched.
    await tester.tap(find.byKey(const ValueKey('monthNavigatorPrevious')));
    await tester.pumpAndSettle();
    await expectInRow(
      tester,
      rent,
      l10n.budgetSpentOfPlanned(money(0), money(500000)),
    );
    final sourceDetail = (await budgets().getBudgetForMonth(
      source,
    )).getOrElse((f) => throw StateError(f.message));
    final targetDetail = (await budgets().getBudgetForMonth(
      target,
    )).getOrElse((f) => throw StateError(f.message));
    expect(sourceDetail.summary!.totalPlannedMinorUnits, 700000);
    expect(targetDetail.summary!.totalPlannedMinorUnits, 750000);
    expect(targetDetail.budget!.id, isNot(sourceDetail.budget!.id));

    // 4.3: with no budget anywhere before it, only "create" is offered.
    appRouter.go('/budgets/1900-01');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('budgetCreateAction')), findsOneWidget);
    expect(find.byKey(const ValueKey('budgetCopyForwardAction')), findsNothing);
  });

  testWidgets('spending trends: overall and per-category planned vs. actual '
      'across 3 months, oldest first (US5; quickstart.md Scenario 5.1-5.2)', (
    tester,
  ) async {
    final l10n = await english();
    final first = await freshMonths(3);
    final months = [for (var i = 0; i < 3; i++) BudgetMonth.shift(first, i)];
    final food = await newExpenseCategory('Food');
    final rent = await newExpenseCategory('Rent');

    const foodPlanned = [100000, 120000, 140000];
    const foodActual = [50000, 150000, 0];
    const rentPlanned = [300000, 300000, 300000];
    const rentActual = [300000, 280000, 310000];
    for (var i = 0; i < 3; i++) {
      await createBudget(months[i], {
        food: foodPlanned[i],
        rent: rentPlanned[i],
      });
      if (foodActual[i] > 0) await spend(food, foodActual[i], months[i]);
      await spend(rent, rentActual[i], months[i]);
    }

    await openBudgetMonth(tester, months.last);
    await tester.tap(find.byKey(const ValueKey('budgetTrendAction')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.budgetTrendTitle), findsOneWidget);
    expect(find.text(l10n.budgetTrendInsufficientTitle), findsNothing);
    expect(find.byType(BudgetTrendChart), findsOneWidget);

    // 5.2: overall — the window ends at the opened month, oldest first.
    var points = tester
        .widget<BudgetTrendChart>(find.byType(BudgetTrendChart))
        .points;
    expect(points.last.month, months.last);
    final overall = points.sublist(points.length - 3);
    expect([for (final p in overall) p.month], months);
    for (var i = 0; i < 3; i++) {
      expect(overall[i].hasBudget, isTrue);
      expect(overall[i].plannedMinorUnits, foodPlanned[i] + rentPlanned[i]);
      expect(overall[i].actualMinorUnits, foodActual[i] + rentActual[i]);
    }
    expect(
      points.sublist(0, points.length - 3).every((p) => !p.hasBudget),
      isTrue,
    );

    // 5.1: one category, picked from the selector.
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(food.name).last);
    await tester.pumpAndSettle();

    points = tester
        .widget<BudgetTrendChart>(find.byType(BudgetTrendChart))
        .points;
    final perFood = points.sublist(points.length - 3);
    expect([for (final p in perFood) p.month], months);
    for (var i = 0; i < 3; i++) {
      expect(perFood[i].plannedMinorUnits, foodPlanned[i]);
      expect(perFood[i].actualMinorUnits, foodActual[i]);
    }
    expect(find.text(food.name), findsWidgets);
  });

  testWidgets('spending trends with a single budgeted month show the '
      '"not enough history" state (US5; quickstart.md Scenario 5.3)', (
    tester,
  ) async {
    final l10n = await english();
    final month = await freshMonths(1);
    final food = await newExpenseCategory('Food');
    await createBudget(month, {food: 100000});
    await spend(food, 40000, month);

    await openBudgetMonth(tester, month);
    await tester.tap(find.byKey(const ValueKey('budgetTrendAction')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.budgetTrendInsufficientTitle), findsOneWidget);
    expect(find.byType(BudgetTrendChart), findsNothing);
  });
}
