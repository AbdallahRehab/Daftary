import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/catalogue_fixtures.dart';

/// 022 Phase 2 (T009) — budget catalogue. Setup for CHK047-CHK053: October
/// budget, Food planned 2,000.00 (200000). Status thresholds use integer
/// comparison; the overall figure covers budgeted lines only. Every figure is
/// an exact integer count of minor units.
void main() {
  late CatalogueEnv env;
  late String octoberBudgetId;

  setUp(() async {
    env = await CatalogueEnv.open();
    octoberBudgetId = await env.budget('2026-10', {catFood: 200000});
  });
  tearDown(() => env.close());

  Future<BudgetSummary> summaryFor(String month) async {
    final detail = unwrapOrThrow(await env.budgets.getBudgetForMonth(month));
    return detail.summary!;
  }

  Future<BudgetCategoryLine> foodLine([String month = '2026-10']) async =>
      (await summaryFor(
        month,
      )).categoryBreakdown.singleWhere((line) => line.categoryId == catFood);

  group('CHK047 Food spent 1,000.00 of 2,000.00', () {
    test('used 50%, remaining 100000, on track', () async {
      await env.expense(catFood, 100000, DateTime(2026, 10, 10));

      final line = await foodLine();

      expect(line.actualAmountMinorUnits, 100000);
      expect(line.percentageUsed, 50.0);
      expect(line.remainingMinorUnits, 100000);
      expect(line.status, BudgetCategoryStatus.onTrack);
    });
  });

  group('CHK048 Food spent 1,800.00', () {
    test('used 90%, remaining 20000, near full', () async {
      await env.expense(catFood, 180000, DateTime(2026, 10, 10));

      final line = await foodLine();

      expect(line.percentageUsed, 90.0);
      expect(line.remainingMinorUnits, 20000);
      expect(line.status, BudgetCategoryStatus.nearFull);
    });
  });

  group('CHK049 Food spent 1,799.99', () {
    test('stays on track: 89.9995% is never rounded up to 90', () async {
      await env.expense(catFood, 179999, DateTime(2026, 10, 10));

      final line = await foodLine();

      expect(line.remainingMinorUnits, 20001);
      expect(line.status, BudgetCategoryStatus.onTrack);
    });
  });

  group('CHK050 Food spent 2,000.00', () {
    test('used 100%, remaining 0, near full and not over budget', () async {
      await env.expense(catFood, 200000, DateTime(2026, 10, 10));

      final line = await foodLine();

      expect(line.percentageUsed, 100.0);
      expect(line.remainingMinorUnits, 0);
      expect(line.status, BudgetCategoryStatus.nearFull);
    });
  });

  group('CHK051 Food spent 2,000.01', () {
    test('over budget, remaining -1 minor unit (over by 0.01)', () async {
      await env.expense(catFood, 200001, DateTime(2026, 10, 10));

      final line = await foodLine();

      expect(line.remainingMinorUnits, -1);
      expect(line.status, BudgetCategoryStatus.overBudget);
    });
  });

  group('CHK052 planned 0.00 and spent 1.00', () {
    test('over budget with no percentage (no division by zero)', () async {
      unwrapOrThrow(
        await env.budgets.removeBudgetCategoryAllocation(
          (await foodLine()).allocationId,
        ),
      );
      // A 0.00 plan can be stored (unwrapOrThrow fails on a rejection).
      unwrapOrThrow(
        await env.budgets.addBudgetCategoryAllocation(
          idempotencyKey: env.nextKey(),
          budgetId: octoberBudgetId,
          categoryId: catTransport,
          plannedAmountMinorUnits: 0,
        ),
      );
      await env.expense(catTransport, 100, DateTime(2026, 10, 10));

      final line = (await summaryFor('2026-10')).categoryBreakdown.single;

      expect(line.plannedAmountMinorUnits, 0);
      expect(line.actualAmountMinorUnits, 100);
      expect(line.percentageUsed, isNull);
      expect(line.status, BudgetCategoryStatus.overBudget);
    });
  });

  group('CHK053 unbudgeted spending', () {
    test('250.00 in Gifts (no allocation) is listed as 25000 and is in no '
        'budget line', () async {
      await env.expense(catGifts, 25000, DateTime(2026, 10, 12));

      final summary = await summaryFor('2026-10');

      final unbudgeted = summary.unbudgetedSpending.single;
      expect(unbudgeted.categoryId, catGifts);
      expect(unbudgeted.amountMinorUnits, 25000);
      expect(summary.categoryBreakdown.map((l) => l.categoryId), [catFood]);
      expect(summary.totalActualMinorUnits, 0);
    });
  });

  group('CHK054 month boundaries', () {
    test(
      '2026-10-31 counts in October and 2026-11-01 counts in November',
      () async {
        await env.budget('2026-11', {catFood: 200000});
        await env.expense(catFood, 30000, DateTime(2026, 10, 31));
        await env.expense(catFood, 70000, DateTime(2026, 11, 1));

        expect((await foodLine('2026-10')).actualAmountMinorUnits, 30000);
        expect((await foodLine('2026-11')).actualAmountMinorUnits, 70000);
      },
    );
  });

  group('CHK055 copy October to November', () {
    test('same planned lines; November actuals come only from November; '
        'October unchanged', () async {
      unwrapOrThrow(
        await env.budgets.addBudgetCategoryAllocation(
          idempotencyKey: env.nextKey(),
          budgetId: octoberBudgetId,
          categoryId: catTransport,
          plannedAmountMinorUnits: 50000,
        ),
      );
      await env.expense(catFood, 100000, DateTime(2026, 10, 10));
      await env.expense(catFood, 40000, DateTime(2026, 11, 2));
      final october = await summaryFor('2026-10');

      unwrapOrThrow(
        await env.budgets.copyBudgetToMonth(
          idempotencyKey: env.nextKey(),
          sourceBudgetId: octoberBudgetId,
          targetMonth: '2026-11',
        ),
      );

      final november = await summaryFor('2026-11');
      Map<String, int> planned(BudgetSummary s) => {
        for (final l in s.categoryBreakdown)
          l.categoryId: l.plannedAmountMinorUnits,
      };
      expect(planned(november), {catFood: 200000, catTransport: 50000});
      expect((await foodLine('2026-11')).actualAmountMinorUnits, 40000);
      expect(
        november.categoryBreakdown
            .singleWhere((l) => l.categoryId == catTransport)
            .actualAmountMinorUnits,
        0,
      );
      expect(await summaryFor('2026-10'), october);
      expect((await foodLine('2026-10')).actualAmountMinorUnits, 100000);
    });
  });

  group('CHK056 editing an expense updates the line', () {
    test('1,000.00 edited to 1,900.00 => Food 190000, near full', () async {
      await env.expense(catFood, 100000, DateTime(2026, 10, 10));
      final entry = unwrapOrThrow(
        await env.finance.getHistory(
          filter: const FinanceHistoryFilter(type: FinanceEntryType.expense),
        ),
      ).single;
      final updates = env.budgets.watchBudgetForMonth('2026-10');
      final reflected = expectLater(
        updates,
        emitsThrough(
          predicate<Either<Failure, BudgetMonthDetail>>((result) {
            final line = result
                .getOrElse((f) => throw StateError('$f'))
                .summary
                ?.categoryBreakdown
                .where((l) => l.categoryId == catFood)
                .firstOrNull;
            return line != null &&
                line.actualAmountMinorUnits == 190000 &&
                line.status == BudgetCategoryStatus.nearFull;
          }, 'Food line at 190000, near full'),
        ),
      );

      unwrapOrThrow(
        await env.finance.editEntry(
          entryId: entry.id,
          categoryId: entry.categoryId,
          amount: const Money.egp(190000),
          date: entry.date,
        ),
      );

      await reflected;
      final line = await foodLine();
      expect(line.actualAmountMinorUnits, 190000);
      expect(line.status, BudgetCategoryStatus.nearFull);
    });
  });

  group('CHK057 overall figure covers budgeted lines only', () {
    test('Food 100000 + Transport 30000 spent, Gifts 25000 unbudgeted => '
        'overall spent 130000, unbudgeted 25000 as its own total', () async {
      unwrapOrThrow(
        await env.budgets.addBudgetCategoryAllocation(
          idempotencyKey: env.nextKey(),
          budgetId: octoberBudgetId,
          categoryId: catTransport,
          plannedAmountMinorUnits: 50000,
        ),
      );
      await env.expense(catFood, 100000, DateTime(2026, 10, 10));
      await env.expense(catTransport, 30000, DateTime(2026, 10, 11));
      await env.expense(catGifts, 25000, DateTime(2026, 10, 12));

      final summary = await summaryFor('2026-10');

      expect(summary.totalPlannedMinorUnits, 250000);
      expect(summary.totalActualMinorUnits, 130000);
      expect(summary.totalRemainingMinorUnits, 120000);
      expect(summary.totalUnbudgetedMinorUnits, 25000);
    });
  });

  group('CHK084 a line equals the finance history for its category', () {
    test('Food actual equals the sum of October Food expenses from the '
        'history filter', () async {
      await env.expense(catFood, 12345, DateTime(2026, 10, 1));
      await env.expense(catFood, 6789, DateTime(2026, 10, 31));
      await env.expense(catFood, 5000, DateTime(2026, 11, 1));
      await env.expense(catFood, 4000, DateTime(2026, 9, 30));
      await env.expense(catTransport, 999, DateTime(2026, 10, 15));

      final rows = unwrapOrThrow(
        await env.finance.getHistory(
          filter: FinanceHistoryFilter(
            type: FinanceEntryType.expense,
            categoryId: catFood,
            dateRange: DateRange(
              start: DateTime(2026, 10, 1),
              end: DateTime(2026, 10, 31),
            ),
          ),
        ),
      );

      final historySum = rows.fold<int>(
        0,
        (sum, e) => sum + e.amount.minorUnits,
      );
      expect(historySum, 12345 + 6789);
      expect((await foodLine()).actualAmountMinorUnits, historySum);
    });
  });
}
