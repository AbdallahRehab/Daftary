import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/entities/budget_trend_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/budgets_harness.dart';

/// 018 FR-009 per-line rate handling and 021 FR-031 live reads —
/// `BudgetsRepositoryImpl` on an in-memory database with the real 007 and
/// 018 repositories behind it.
void main() {
  late BudgetsHarness h;

  setUp(() async => h = await BudgetsHarness.open());
  tearDown(() => h.close());

  Future<BudgetSummary> summaryOf(String month) async =>
      (await h.repository.getBudgetForMonth(month)).toNullable()!.summary!;

  group('018 FR-009: only what needs a missing rate is blocked', () {
    test('a line whose spend is in a currency with no rate is blocked; the '
        'others, and every planned amount, still show', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 100000);
      await h.allocate(budget.id, rent, 500000);
      await h.spend(groceries, 30000, DateTime(2026, 3, 4));
      await h.spend(rent, 1000, DateTime(2026, 3, 5), currency: Currency.usd);

      final result = await h.repository.getBudgetForMonth('2026-03');
      expect(result.isRight(), isTrue, reason: 'never a whole-month failure');
      final summary = result.toNullable()!.summary!;

      final rentLine = summary.categoryBreakdown.firstWhere(
        (l) => l.categoryId == rent,
      );
      expect(rentLine.isBlocked, isTrue);
      expect(rentLine.actualAmountMinorUnits, isNull);
      expect(rentLine.remainingMinorUnits, isNull);
      expect(rentLine.percentageUsed, isNull);
      expect(rentLine.status, isNull);
      expect(rentLine.missingRatesFor, [Currency.usd]);
      expect(rentLine.plannedAmountMinorUnits, 500000);

      final groceriesLine = summary.categoryBreakdown.firstWhere(
        (l) => l.categoryId == groceries,
      );
      expect(groceriesLine.isBlocked, isFalse);
      expect(groceriesLine.actualAmountMinorUnits, 30000);
      expect(groceriesLine.remainingMinorUnits, 70000);

      // Totals: planned always; the actual side blocked by the one line.
      expect(summary.totalPlannedMinorUnits, 600000);
      expect(summary.isActualBlocked, isTrue);
      expect(summary.totalActualMinorUnits, isNull);
      expect(summary.totalRemainingMinorUnits, isNull);
      expect(summary.overallPercentageUsed, isNull);
      expect(summary.isOverBudgetOverall, isNull);
      expect(summary.overallStatus, isNull);
      expect(summary.missingRatesFor, [Currency.usd]);
      expect(summary.isBlocked, isTrue);
    });

    test('a mixed-currency category is blocked as a whole — never a partial '
        'actual', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 100000);
      await h.spend(groceries, 30000, DateTime(2026, 3, 4));
      await h.spend(
        groceries,
        500,
        DateTime(2026, 3, 6),
        currency: Currency.eur,
      );

      final line = (await summaryOf('2026-03')).categoryBreakdown.single;
      expect(line.actualAmountMinorUnits, isNull);
      expect(line.missingRatesFor, [Currency.eur]);
    });

    test('unbudgeted spending is blocked per item, and its total with '
        'it', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 100000);
      await h.spend(groceries, 30000, DateTime(2026, 3, 4));
      await h.spend(fuel, 20000, DateTime(2026, 3, 4));
      await h.spend(
        restaurants,
        1000,
        DateTime(2026, 3, 5),
        currency: Currency.usd,
      );

      final summary = await summaryOf('2026-03');
      // The budgeted side is unaffected.
      expect(summary.isActualBlocked, isFalse);
      expect(summary.totalActualMinorUnits, 30000);
      expect(summary.overallStatus, isNotNull);

      // Known items first, the blocked one listed last — never dropped.
      expect(
        summary.unbudgetedSpending.map((i) => (i.categoryId, i.isBlocked)),
        [(fuel, false), (restaurants, true)],
      );
      expect(summary.unbudgetedSpending.first.amountMinorUnits, 20000);
      expect(summary.unbudgetedSpending.last.amountMinorUnits, isNull);
      expect(summary.unbudgetedSpending.last.missingRatesFor, [Currency.usd]);
      expect(summary.totalUnbudgetedMinorUnits, isNull);
      expect(summary.isBlocked, isTrue);
      expect(summary.missingRatesFor, [Currency.usd]);
    });

    test('setting the rate unblocks the line with an exact converted '
        'figure', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, rent, 500000);
      await h.spend(rent, 1000, DateTime(2026, 3, 5), currency: Currency.usd);
      expect((await summaryOf('2026-03')).isBlocked, isTrue);

      await h.setRate(Currency.usd, 50);

      final summary = await summaryOf('2026-03');
      expect(summary.isBlocked, isFalse);
      // 10.00 USD × 50 = 500.00 EGP.
      expect(summary.categoryBreakdown.single.actualAmountMinorUnits, 50000);
      expect(summary.totalActualMinorUnits, 50000);
      expect(summary.totalRemainingMinorUnits, 450000);
    });

    test('the trend never fails for a missing rate: the month is a gap on '
        'its own point, the others are exact', () async {
      final march = await h.createBudget('2026-03');
      await h.allocate(march.id, groceries, 100000);
      final april = await h.createBudget('2026-04');
      await h.allocate(april.id, groceries, 100000);
      await h.spend(groceries, 30000, DateTime(2026, 3, 4));
      await h.spend(
        groceries,
        1000,
        DateTime(2026, 4, 4),
        currency: Currency.usd,
      );

      final result = await h.repository.getBudgetTrend(
        monthsBack: 2,
        endMonth: '2026-04',
      );
      expect(result.isRight(), isTrue);
      final points = result.toNullable()!;
      expect(points.first.actualMinorUnits, 30000);
      expect(points.first.isBlocked, isFalse);
      expect(points.last.plannedMinorUnits, 100000);
      expect(points.last.actualMinorUnits, isNull);
      expect(points.last.hasBudget, isTrue);
      expect(points.last.missingRatesFor, [Currency.usd]);
      // The month still counts toward the history minimum.
      expect(points.hasEnoughHistory, isTrue);
      expect(points.missingRatesFor, [Currency.usd]);

      // A category that is not the blocked one is unaffected.
      final rentTrend = (await h.repository.getBudgetTrend(
        categoryId: rent,
        monthsBack: 2,
        endMonth: '2026-04',
      )).toNullable()!;
      expect(rentTrend.every((p) => !p.isBlocked), isTrue);
    });

    test('a budget planned in a currency that no longer converts to the '
        'primary one leaves only its planned figure unknown', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 100000);
      await h.setPrimary(Currency.usd);

      final point = (await h.repository.getBudgetTrend(
        monthsBack: 1,
        endMonth: '2026-03',
      )).toNullable()!.single;
      expect(point.plannedMinorUnits, isNull);
      expect(point.isPlannedBlocked, isTrue);
      // Nothing was spent: a known zero.
      expect(point.actualMinorUnits, 0);
      expect(point.missingRatesFor, isNotEmpty);
      expect(point.isOverPlan, isFalse);

      // The month screen is in the budget's own currency: nothing blocked.
      expect((await summaryOf('2026-03')).isBlocked, isFalse);
    });
  });

  group('021 FR-031: live reads', () {
    /// Past the 50 ms write debounce, plus the re-read.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 150));

    test('watchBudgetForMonth re-emits for an expense recorded and a rate '
        'set elsewhere', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 100000);
      await h.allocate(budget.id, rent, 500000);

      final emissions = <Either<Failure, BudgetMonthDetail>>[];
      final subscription = h.repository
          .watchBudgetForMonth('2026-03')
          .listen(emissions.add);
      await settle();
      expect(emissions, hasLength(1));
      expect(emissions.last.toNullable()!.summary!.totalActualMinorUnits, 0);

      await h.spend(groceries, 30000, DateTime(2026, 3, 4));
      await settle();
      expect(
        emissions.last.toNullable()!.summary!.totalActualMinorUnits,
        30000,
      );

      await h.spend(rent, 1000, DateTime(2026, 3, 5), currency: Currency.usd);
      await settle();
      expect(emissions.last.toNullable()!.summary!.isActualBlocked, isTrue);

      await h.setRate(Currency.usd, 50);
      await settle();
      final summary = emissions.last.toNullable()!.summary!;
      expect(summary.isBlocked, isFalse);
      expect(summary.totalActualMinorUnits, 80000);

      // A write that changes nothing the month shows is not re-emitted.
      final count = emissions.length;
      await h.spend(groceries, 100, DateTime(2026, 5, 1));
      await settle();
      expect(emissions, hasLength(count));

      await subscription.cancel();
    });

    test('watchBudgetForMonth follows the budget itself being created and '
        'edited', () async {
      final emissions = <Either<Failure, BudgetMonthDetail>>[];
      final subscription = h.repository
          .watchBudgetForMonth('2026-03')
          .listen(emissions.add);
      await settle();
      expect(emissions.last.toNullable()!.hasBudget, isFalse);

      final budget = await h.createBudget('2026-03');
      await settle();
      expect(emissions.last.toNullable()!.hasBudget, isTrue);

      await h.allocate(budget.id, groceries, 100000);
      await settle();
      expect(
        emissions.last.toNullable()!.summary!.totalPlannedMinorUnits,
        100000,
      );
      await subscription.cancel();
    });

    test('watchBudgetTrend re-emits when a month gains spend', () async {
      final budget = await h.createBudget('2026-03');
      await h.allocate(budget.id, groceries, 100000);

      final emissions = <Either<Failure, List<BudgetTrendPoint>>>[];
      final subscription = h.repository
          .watchBudgetTrend(monthsBack: 2, endMonth: '2026-03')
          .listen(emissions.add);
      await settle();
      expect(emissions.last.toNullable()!.last.actualMinorUnits, 0);

      await h.spend(groceries, 30000, DateTime(2026, 3, 4));
      await settle();
      expect(emissions.last.toNullable()!.last.actualMinorUnits, 30000);
      await subscription.cancel();
    });
  });
}
