import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget_month.dart';
import 'package:daftary/features/budgets/domain/entities/budget_trend_point.dart';
import 'package:daftary/features/budgets/domain/usecases/get_budget_trend.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/budgets_harness.dart';

/// T048 — the trend view's data (FR-014), against the real repository and
/// an in-memory database.
void main() {
  late BudgetsHarness h;
  late GetBudgetTrend getTrend;

  setUp(() async {
    h = await BudgetsHarness.open();
    getTrend = GetBudgetTrend(h.repository);
  });

  tearDown(() => h.close());

  /// Jan-Apr 2026: budgets in Feb, Mar and Apr, spending in every month.
  Future<void> seedHistory() async {
    final feb = await h.createBudget('2026-02');
    await h.allocate(feb.id, groceries, 1000);
    await h.allocate(feb.id, rent, 5000);
    final mar = await h.createBudget('2026-03');
    await h.allocate(mar.id, groceries, 1200);
    final apr = await h.createBudget('2026-04');
    await h.allocate(apr.id, groceries, 0);
    await h.allocate(apr.id, rent, 5000);

    await h.spend(groceries, 300, DateTime(2026, 1, 10));
    await h.spend(fuel, 200, DateTime(2026, 1, 11));
    await h.spend(groceries, 900, DateTime(2026, 2, 10));
    await h.spend(rent, 5000, DateTime(2026, 2, 1));
    await h.spend(fuel, 700, DateTime(2026, 2, 12)); // unbudgeted in Feb
    await h.spend(groceries, 1500, DateTime(2026, 3, 10));
    await h.spend(rent, 5000, DateTime(2026, 3, 1)); // unbudgeted in Mar
    await h.spend(groceries, 100, DateTime(2026, 4, 3));
  }

  test('returns monthsBack points ending at endMonth, oldest first', () async {
    final points = (await getTrend(
      monthsBack: 6,
      endMonth: '2026-04',
    )).toNullable()!;

    expect(points.map((p) => p.month), [
      '2025-11',
      '2025-12',
      '2026-01',
      '2026-02',
      '2026-03',
      '2026-04',
    ]);
  });

  test('defaults to the six months ending with the current month', () async {
    final points = (await getTrend()).toNullable()!;

    expect(points, hasLength(6));
    expect(points.last.month, BudgetMonth.current());
  });

  test('overall: planned totals per budgeted month, actual matching the '
      'month view, zero-planned points for unbudgeted months', () async {
    await seedHistory();

    final points = (await getTrend(
      monthsBack: 4,
      endMonth: '2026-04',
    )).toNullable()!;
    final byMonth = {for (final p in points) p.month: p};

    // January: no budget — planned 0, actual is the month's whole spend.
    expect(
      byMonth['2026-01'],
      const BudgetTrendPoint(
        month: '2026-01',
        plannedMinorUnits: 0,
        actualMinorUnits: 500,
        hasBudget: false,
      ),
    );
    // February: budgeted categories only (fuel was unbudgeted) — the same
    // figure as that month's BudgetSummary.totalActualMinorUnits.
    expect(byMonth['2026-02']!.plannedMinorUnits, 6000);
    expect(byMonth['2026-02']!.actualMinorUnits, 5900);
    expect(byMonth['2026-03']!.plannedMinorUnits, 1200);
    expect(byMonth['2026-03']!.actualMinorUnits, 1500);
    expect(byMonth['2026-04']!.plannedMinorUnits, 5000);
    expect(byMonth['2026-04']!.actualMinorUnits, 100);

    final feb = (await h.repository.getBudgetForMonth(
      '2026-02',
    )).toNullable()!.summary!;
    expect(byMonth['2026-02']!.actualMinorUnits, feb.totalActualMinorUnits);
  });

  test('per category: that allocation\'s plan and that category\'s spend, '
      'including months it was not budgeted', () async {
    await seedHistory();

    final points = (await getTrend(
      categoryId: rent,
      monthsBack: 4,
      endMonth: '2026-04',
    )).toNullable()!;

    expect(
      points.map((p) => (p.month, p.plannedMinorUnits, p.actualMinorUnits)),
      [
        ('2026-01', 0, 0),
        ('2026-02', 5000, 5000),
        // Budgeted month, but rent is not in March's budget.
        ('2026-03', 0, 5000),
        ('2026-04', 5000, 0),
      ],
    );
    expect(points.map((p) => p.hasBudget), [false, true, true, true]);
  });

  test('"not enough history" until at least two months have a budget — '
      'months with only spending do not count', () async {
    await h.spend(groceries, 100, DateTime(2026, 2, 1));
    await h.spend(groceries, 100, DateTime(2026, 3, 1));
    final one = await h.createBudget('2026-03');

    var points = (await getTrend(endMonth: '2026-04')).toNullable()!;
    expect(points.budgetedMonthCount, 1);
    expect(points.hasEnoughHistory, isFalse);

    // An all-zero budget is still a budget.
    await h.createBudget('2026-04');
    points = (await getTrend(endMonth: '2026-04')).toNullable()!;
    expect(points.budgetedMonthCount, 2);
    expect(points.hasEnoughHistory, isTrue);

    // A deleted budget stops counting.
    await h.repository.deleteBudget(one.id);
    points = (await getTrend(endMonth: '2026-04')).toNullable()!;
    expect(points.hasEnoughHistory, isFalse);
  });

  test('budgets outside the window are ignored', () async {
    await h.createBudget('2025-01');
    await h.createBudget('2026-05');

    final points = (await getTrend(endMonth: '2026-04')).toNullable()!;

    expect(points.budgetedMonthCount, 0);
  });

  test('rejects monthsBack < 1 and a malformed endMonth', () async {
    expect(
      (await getTrend(monthsBack: 0)).getLeft().toNullable(),
      isA<ValidationFailure>(),
    );
    expect(
      (await getTrend(endMonth: 'soon')).getLeft().toNullable(),
      isA<ValidationFailure>(),
    );
  });

  test('crosses a year boundary correctly', () async {
    final points = (await getTrend(
      monthsBack: 3,
      endMonth: '2026-01',
    )).toNullable()!;
    expect(points.map((p) => p.month), ['2025-11', '2025-12', '2026-01']);
  });
}
