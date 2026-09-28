import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart'
    hide BudgetCategoryStatus;
import 'package:daftary/features/budgets/domain/entities/budget_month.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:daftary/features/insights_notifications/data/datasources/budgets_insights_source.dart';
import 'package:daftary/features/insights_notifications/domain/ports/budget_insights_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetsRepository extends Mock implements BudgetsRepository {}

/// The 010 adapter under 017's budget warnings. 018 FR-009: a line whose
/// spend needs a missing exchange rate has no known figures, so it never
/// yields a snapshot (and so never a warning); the other lines do.
void main() {
  late MockBudgetsRepository repository;
  late BudgetsInsightsSource source;
  final month = BudgetMonth.current();
  final now = DateTime(2026);

  BudgetMonthDetail detailWith(List<BudgetCategoryLine> lines) =>
      BudgetMonthDetail(
        month: month,
        budget: Budget(
          id: 'b1',
          idempotencyKey: 'k',
          month: month,
          createdAt: now,
          updatedAt: now,
        ),
        summary: BudgetSummary(
          budgetId: 'b1',
          categoryBreakdown: lines,
          unbudgetedSpending: const [],
        ),
      );

  const over = BudgetCategoryLine(
    allocationId: 'a1',
    categoryId: 'c-food',
    categoryName: 'Food',
    categoryIcon: 'food',
    plannedAmountMinorUnits: 1000,
    actualAmountMinorUnits: 1200,
  );
  const blocked = BudgetCategoryLine(
    allocationId: 'a2',
    categoryId: 'c-travel',
    categoryName: 'Travel',
    categoryIcon: 'travel',
    plannedAmountMinorUnits: 1000,
    actualAmountMinorUnits: null,
    missingRatesFor: [Currency.usd],
  );

  setUp(() {
    repository = MockBudgetsRepository();
    source = BudgetsInsightsSource(repository);
  });

  test('a blocked line yields no snapshot; the others are copied '
      'through', () async {
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWith(const [over, blocked])));

    final snapshots = (await source.currentMonthCategories()).getOrElse(
      (f) => fail('$f'),
    );

    expect(snapshots, [
      BudgetCategorySnapshot(
        categoryId: 'c-food',
        categoryName: 'Food',
        month: month,
        plannedMinorUnits: 1000,
        actualMinorUnits: 1200,
        percentageUsed: over.percentageUsed,
        status: BudgetCategoryStatus.overBudget,
      ),
    ]);
  });

  test('a blocked line is still budgeted — a tap on its notification is '
      'not stale', () async {
    when(
      () => repository.getBudgetForMonth(month),
    ).thenAnswer((_) async => Right(detailWith(const [blocked])));

    expect(await source.categoryBudgetExists('c-travel', month), isTrue);
    expect(await source.categoryBudgetExists('c-other', month), isFalse);
  });
}
