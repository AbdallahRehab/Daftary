import 'package:daftary/features/budgets/domain/entities/budget_month.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/budgets_harness.dart';

/// T060 — plan.md Performance Goals: a month with 30 budgeted categories
/// against 2,000 expense entries loads in <1s, and a 6-month trend in
/// <1.5s. Runs against the real in-memory database and the real 007
/// repositories, so the timings cover the same queries the app runs.
void main() {
  late BudgetsHarness h;
  late List<String> categoryIds;

  const month = '2026-06';
  const categoryCount = 30;
  const entriesPerMonth = 2000;

  setUp(() async {
    h = await BudgetsHarness.open();
    // 30 expense categories: whatever the seed provides, topped up with
    // custom ones.
    final existing = (await h.categories.getCategories(
      type: CategoryType.expense,
    )).getOrElse((f) => throw StateError(f.message));
    categoryIds = [for (final c in existing) c.id];
    var n = 0;
    while (categoryIds.length < categoryCount) {
      final created = await h.categories.createCategory(
        name: 'Perf category ${n++}',
        type: CategoryType.expense,
        icon: 'other',
      );
      categoryIds.add(created.getOrElse((f) => throw StateError(f.message)).id);
    }
    categoryIds = categoryIds.take(categoryCount).toList();
  });
  tearDown(() => h.close());

  Future<void> seedMonth(String month, {required int entries}) async {
    final budget = await h.createBudget(month, income: 10000000);
    for (final id in categoryIds) {
      await h.allocate(budget.id, id, 100000);
    }
    final start = BudgetMonth.toDate(month);
    await h.db.transaction(() async {
      for (var i = 0; i < entries; i++) {
        await h.spend(
          categoryIds[i % categoryIds.length],
          100 + i,
          DateTime(start.year, start.month, 1 + i % 28),
        );
      }
    });
  }

  test(
    'getBudgetForMonth: 30 budgeted categories, 2,000 expenses, <1s',
    () async {
      await seedMonth(month, entries: entriesPerMonth);

      // One warm-up call, so the measurement is of the query path and not of
      // first-use statement preparation.
      await h.repository.getBudgetForMonth(month);

      final sw = Stopwatch()..start();
      final result = await h.repository.getBudgetForMonth(month);
      sw.stop();

      final detail = result.getOrElse((f) => throw StateError(f.message));
      expect(detail.summary!.categoryBreakdown, hasLength(categoryCount));
      // Sum of 100..2099 minor units.
      expect(
        detail.summary!.totalActualMinorUnits,
        (100 + 100 + entriesPerMonth - 1) * entriesPerMonth ~/ 2,
      );
      // ignore: avoid_print
      print('T060 getBudgetForMonth: ${sw.elapsedMilliseconds} ms');
      expect(sw.elapsed, lessThan(const Duration(seconds: 1)));
    },
  );

  test('getBudgetTrend: 6 months of history, <1.5s', () async {
    for (var offset = 5; offset >= 0; offset--) {
      await seedMonth(BudgetMonth.shift(month, -offset), entries: 500);
    }
    await h.repository.getBudgetTrend(endMonth: month);

    final sw = Stopwatch()..start();
    final overall = await h.repository.getBudgetTrend(endMonth: month);
    final perCategory = await h.repository.getBudgetTrend(
      endMonth: month,
      categoryId: categoryIds.first,
    );
    sw.stop();

    final points = overall.getOrElse((f) => throw StateError(f.message));
    expect(points, hasLength(6));
    expect(points.every((p) => p.hasBudget), isTrue);
    expect(perCategory.isRight(), isTrue);
    // ignore: avoid_print
    print(
      'T060 getBudgetTrend (overall + per-category): '
      '${sw.elapsedMilliseconds} ms',
    );
    expect(sw.elapsed, lessThan(const Duration(milliseconds: 1500)));
  });
}
