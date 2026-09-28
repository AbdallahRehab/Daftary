import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../budgets/domain/entities/budget_category_line.dart' as budgets;
import '../../../budgets/domain/entities/budget_month.dart';
import '../../../budgets/domain/repositories/budgets_repository.dart';
import '../../domain/ports/budget_insights_source.dart';

/// [BudgetInsightsSource] over 010 Household Budgets' repository — the
/// adapter this port was declared for, now that 010 is merged. Copies 010's
/// own figures and status; nothing is recomputed here (research.md
/// Decision 2).
@LazySingleton(as: BudgetInsightsSource)
class BudgetsInsightsSource implements BudgetInsightsSource {
  const BudgetsInsightsSource(this._budgets);

  final BudgetsRepository _budgets;

  @override
  Future<Either<Failure, List<BudgetCategorySnapshot>>>
  currentMonthCategories() async {
    final month = BudgetMonth.current();
    final result = await _budgets.getBudgetForMonth(month);
    return result.map(
      (detail) => [
        for (final line
            in detail.summary?.categoryBreakdown ??
                const <budgets.BudgetCategoryLine>[])
          // 018 FR-009: a line whose spend needs a missing exchange rate has
          // no known actual or status, so it is left out — never a warning
          // from a partial figure. Its band stays as last recorded, and it
          // is evaluated normally once the rate is set.
          if ((line.actualAmountMinorUnits, line.status) case (
            final actual?,
            final status?,
          ))
            BudgetCategorySnapshot(
              categoryId: line.categoryId,
              categoryName: line.categoryName,
              month: month,
              plannedMinorUnits: line.plannedAmountMinorUnits,
              actualMinorUnits: actual,
              percentageUsed: line.percentageUsed,
              status: switch (status) {
                budgets.BudgetCategoryStatus.onTrack =>
                  BudgetCategoryStatus.onTrack,
                budgets.BudgetCategoryStatus.nearFull =>
                  BudgetCategoryStatus.nearFull,
                budgets.BudgetCategoryStatus.overBudget =>
                  BudgetCategoryStatus.overBudget,
              },
            ),
      ],
    );
  }

  @override
  Future<bool> categoryBudgetExists(String categoryId, String month) async {
    if (!BudgetMonth.isValid(month)) return false;
    final result = await _budgets.getBudgetForMonth(month);
    return result.match(
      // 018: a missing rate blocks only a line's figures, never the plan,
      // so the allocation is still found below.
      (_) => false,
      (detail) =>
          detail.summary?.categoryBreakdown.any(
            (line) => line.categoryId == categoryId,
          ) ??
          false,
    );
  }
}
