import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/usecases/get_budget_for_month.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/budgets_harness.dart';

BudgetCategoryLine line({required int planned, required int actual}) =>
    BudgetCategoryLine(
      allocationId: 'a',
      categoryId: 'c',
      categoryName: 'C',
      categoryIcon: 'i',
      plannedAmountMinorUnits: planned,
      actualAmountMinorUnits: actual,
    );

BudgetSummary summaryOf(List<(int, int)> plannedActual) => BudgetSummary(
  budgetId: 'b',
  categoryBreakdown: [
    for (final (planned, actual) in plannedActual)
      line(planned: planned, actual: actual),
  ],
  unbudgetedSpending: const [],
);

void main() {
  late BudgetsHarness h;
  late GetBudgetForMonth getBudgetForMonth;

  setUp(() async {
    h = await BudgetsHarness.open();
    getBudgetForMonth = GetBudgetForMonth(h.repository);
  });

  tearDown(() => h.close());

  group('empty month', () {
    test('a month with no budget is an empty detail, not a failure '
        '(FR-018)', () async {
      await h.spend(groceries, 500, DateTime(2026, 3, 5));

      final detail = (await getBudgetForMonth('2026-03')).toNullable()!;

      expect(detail.hasBudget, isFalse);
      expect(detail.month, '2026-03');
      expect(detail.summary, isNull);
      expect(detail.plannedExceedsExpectedIncome, isFalse);
    });

    test('a malformed month is a validation failure', () async {
      final result = await getBudgetForMonth('March');
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });

  group('T015 exceeds-income indication (FR-004)', () {
    test('planned total above the expected income is flagged, without '
        'blocking anything', () async {
      final budget = await h.createBudget('2026-03', income: 1000);
      await h.allocate(budget.id, groceries, 700);
      // This allocation takes the total past the income and still saves.
      final over = await h.repository.addBudgetCategoryAllocation(
        idempotencyKey: 'over',
        budgetId: budget.id,
        categoryId: rent,
        plannedAmountMinorUnits: 400,
      );
      expect(over.isRight(), isTrue);

      final detail = (await getBudgetForMonth('2026-03')).toNullable()!;
      expect(detail.summary!.totalPlannedMinorUnits, 1100);
      expect(detail.plannedExceedsExpectedIncome, isTrue);
    });

    test('planned equal to income, or no income recorded, is not '
        'flagged', () async {
      final equal = await h.createBudget('2026-03', income: 1000);
      await h.allocate(equal.id, groceries, 1000);
      final noIncome = await h.createBudget('2026-04');
      await h.allocate(noIncome.id, groceries, 999999);

      expect(
        (await getBudgetForMonth(
          '2026-03',
        )).toNullable()!.plannedExceedsExpectedIncome,
        isFalse,
      );
      expect(
        (await getBudgetForMonth(
          '2026-04',
        )).toNullable()!.plannedExceedsExpectedIncome,
        isFalse,
      );
    });

    test('the free function the form uses gives the same answer', () {
      expect(
        budgetPlannedExceedsIncome(
          totalPlannedMinorUnits: 1001,
          expectedIncomeMinorUnits: 1000,
        ),
        isTrue,
      );
      expect(
        budgetPlannedExceedsIncome(
          totalPlannedMinorUnits: 1001,
          expectedIncomeMinorUnits: null,
        ),
        isFalse,
      );
    });
  });

  group('T027 per-category actual/remaining/percentage (FR-005)', () {
    test('only the target month\'s non-deleted expense entries in each '
        'category count', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 10000);
      await h.allocate(budget.id, rent, 50000);
      await h.allocate(budget.id, fuel, 2000);

      // In month, counted.
      await h.spend(groceries, 3000, DateTime(2026, 3, 1));
      await h.spend(groceries, 1500, DateTime(2026, 3, 31));
      await h.spend(rent, 50000, DateTime(2026, 3, 2));
      // Outside the month on either side, not counted.
      await h.spend(groceries, 9999, DateTime(2026, 2, 28));
      await h.spend(groceries, 9999, DateTime(2026, 4, 1));
      // Deleted, not counted.
      final deleted = await h.spend(groceries, 7777, DateTime(2026, 3, 15));
      await h.finance.deleteEntry(deleted.id);
      // Income in month, never counted as spend.
      await h.earn(100000, DateTime(2026, 3, 10));

      final summary = (await getBudgetForMonth(
        '2026-03',
      )).toNullable()!.summary!;
      final byCategory = {
        for (final l in summary.categoryBreakdown) l.categoryId: l,
      };

      final g = byCategory[groceries]!;
      expect(g.plannedAmountMinorUnits, 10000);
      expect(g.actualAmountMinorUnits, 4500);
      expect(g.remainingMinorUnits, 5500);
      expect(g.percentageUsed, 45);
      expect(g.categoryName, 'Groceries');
      expect(g.categoryIcon, isNotEmpty);

      final r = byCategory[rent]!;
      expect(r.actualAmountMinorUnits, 50000);
      expect(r.remainingMinorUnits, 0);
      expect(r.percentageUsed, 100);

      final f = byCategory[fuel]!;
      expect(f.actualAmountMinorUnits, 0);
      expect(f.remainingMinorUnits, 2000);
      expect(f.percentageUsed, 0);

      // FR-006 totals aggregate the lines.
      expect(summary.totalPlannedMinorUnits, 62000);
      expect(summary.totalActualMinorUnits, 54500);
      expect(summary.totalRemainingMinorUnits, 7500);
      expect(summary.overallPercentageUsed, closeTo(87.9, 0.01));
    });

    test('lines are ordered largest planned amount first', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, fuel, 100);
      await h.allocate(budget.id, rent, 900);
      await h.allocate(budget.id, groceries, 500);

      final summary = (await getBudgetForMonth(
        '2026-03',
      )).toNullable()!.summary!;

      expect(summary.categoryBreakdown.map((l) => l.categoryId), [
        rent,
        groceries,
        fuel,
      ]);
    });

    test('percentage is null, not a division by zero, for a zero plan', () {
      expect(line(planned: 0, actual: 0).percentageUsed, isNull);
      expect(summaryOf([(0, 0)]).overallPercentageUsed, isNull);
    });

    test('an archived category keeps its name and actual spend in an '
        'existing budget (FR-021)', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 1000);
      await h.spend(groceries, 400, DateTime(2026, 3, 3));
      await h.categories.removeCategory(groceries); // archives: has entries

      final g = (await getBudgetForMonth(
        '2026-03',
      )).toNullable()!.summary!.categoryBreakdown.single;

      expect(g.isCategoryArchived, isTrue);
      expect(g.categoryName, 'Groceries');
      expect(g.actualAmountMinorUnits, 400);
    });
  });

  group('T028 unbudgeted spending (FR-007)', () {
    test('expense categories with spend this month but no allocation are '
        'listed separately, largest first, and never folded into the '
        'budgeted totals', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 1000);
      await h.allocate(budget.id, rent, 1000);

      await h.spend(groceries, 300, DateTime(2026, 3, 3));
      await h.spend(restaurants, 250, DateTime(2026, 3, 4));
      await h.spend(restaurants, 100, DateTime(2026, 3, 5));
      await h.spend(fuel, 900, DateTime(2026, 3, 6));
      // Other months' spend in an unbudgeted category is not this month's.
      await h.spend(fuel, 5000, DateTime(2026, 2, 6));
      await h.earn(100000, DateTime(2026, 3, 10));

      final summary = (await getBudgetForMonth(
        '2026-03',
      )).toNullable()!.summary!;

      expect(summary.unbudgetedSpending, hasLength(2));
      expect(summary.unbudgetedSpending[0].categoryId, fuel);
      expect(summary.unbudgetedSpending[0].amountMinorUnits, 900);
      expect(summary.unbudgetedSpending[1].categoryId, restaurants);
      expect(summary.unbudgetedSpending[1].amountMinorUnits, 350);
      expect(summary.unbudgetedSpending[1].categoryName, 'Restaurants');
      expect(summary.totalUnbudgetedMinorUnits, 1250);
      // Budgeted rent with no spend is a line, not unbudgeted.
      expect(
        summary.unbudgetedSpending.map((u) => u.categoryId),
        isNot(contains(rent)),
      );
      expect(summary.totalActualMinorUnits, 300);
    });

    test('removing an allocation turns its spend into unbudgeted '
        'spending', () async {
      final budget = await h.createBudget('2026-03');
      final allocation = await h.allocate(budget.id, groceries, 1000);
      await h.spend(groceries, 300, DateTime(2026, 3, 3));

      await h.repository.removeBudgetCategoryAllocation(allocation.id);
      final summary = (await getBudgetForMonth(
        '2026-03',
      )).toNullable()!.summary!;

      expect(summary.categoryBreakdown, isEmpty);
      expect(summary.unbudgetedSpending.single.categoryId, groceries);
      expect(summary.unbudgetedSpending.single.amountMinorUnits, 300);
    });
  });

  group('T037 BudgetCategoryLine.status (FR-008)', () {
    test('overBudget once actual exceeds planned', () {
      expect(
        line(planned: 1000, actual: 1001).status,
        BudgetCategoryStatus.overBudget,
      );
    });

    test('any spend against a zero plan is immediately overBudget', () {
      expect(
        line(planned: 0, actual: 1).status,
        BudgetCategoryStatus.overBudget,
      );
      expect(line(planned: 0, actual: 0).status, BudgetCategoryStatus.onTrack);
    });

    test('nearFull from exactly 90% up to and including 100%', () {
      expect(
        line(planned: 1000, actual: 899).status,
        BudgetCategoryStatus.onTrack,
      );
      expect(
        line(planned: 1000, actual: 900).status,
        BudgetCategoryStatus.nearFull,
      );
      expect(
        line(planned: 1000, actual: 1000).status,
        BudgetCategoryStatus.nearFull,
      );
    });

    test('the 90% threshold is exact in integers, with no rounding '
        'slack', () {
      // 89.99…% must not round up to near-full.
      expect(
        line(planned: 10001, actual: 9000).status,
        BudgetCategoryStatus.onTrack,
      );
      expect(line(planned: 3, actual: 3).status, BudgetCategoryStatus.nearFull);
    });

    test(
      'onTrack otherwise, and statuses come through the repository',
      () async {
        final budget = await h.createBudget('2026-03');
        await h.allocate(budget.id, groceries, 1000);
        await h.allocate(budget.id, rent, 1000);
        await h.allocate(budget.id, fuel, 1000);
        await h.spend(groceries, 100, DateTime(2026, 3, 1));
        await h.spend(rent, 950, DateTime(2026, 3, 1));
        await h.spend(fuel, 1200, DateTime(2026, 3, 1));

        final lines = {
          for (final l in (await getBudgetForMonth(
            '2026-03',
          )).toNullable()!.summary!.categoryBreakdown)
            l.categoryId: l.status,
        };

        expect(lines[groceries], BudgetCategoryStatus.onTrack);
        expect(lines[rent], BudgetCategoryStatus.nearFull);
        expect(lines[fuel], BudgetCategoryStatus.overBudget);
      },
    );
  });

  group('T038 BudgetSummary.isOverBudgetOverall (FR-009)', () {
    test('true when total actual exceeds total planned', () {
      final summary = summaryOf([(1000, 1500), (1000, 600)]);
      expect(summary.isOverBudgetOverall, isTrue);
      expect(summary.totalRemainingMinorUnits, -100);
      expect(summary.overallStatus, BudgetCategoryStatus.overBudget);
    });

    test('false when one category is over but the totals are not', () {
      final summary = summaryOf([(1000, 1500), (1000, 100)]);
      expect(
        summary.categoryBreakdown.first.status,
        BudgetCategoryStatus.overBudget,
      );
      expect(summary.isOverBudgetOverall, isFalse);
      expect(summary.overallStatus, BudgetCategoryStatus.onTrack);
    });

    test('false when exactly on plan', () {
      final summary = summaryOf([(1000, 1000)]);
      expect(summary.isOverBudgetOverall, isFalse);
      expect(summary.overallStatus, BudgetCategoryStatus.nearFull);
    });

    test('an empty budget is not over budget', () {
      final summary = summaryOf(const []);
      expect(summary.isOverBudgetOverall, isFalse);
      expect(summary.totalPlannedMinorUnits, 0);
    });
  });
}
