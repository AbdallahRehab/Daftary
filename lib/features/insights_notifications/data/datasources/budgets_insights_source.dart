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
    return switch (result) {
      // 018: a month whose spend needs a missing exchange rate has no known
      // actuals, so there is nothing to warn about yet — never a warning
      // from a partial figure.
      Left(value: RatesMissingFailure()) => const Right([]),
      Left(:final value) => Left(value),
      Right(:final value) => Right([
        for (final line
            in value.summary?.categoryBreakdown ??
                const <budgets.BudgetCategoryLine>[])
          BudgetCategorySnapshot(
            categoryId: line.categoryId,
            categoryName: line.categoryName,
            month: month,
            plannedMinorUnits: line.plannedAmountMinorUnits,
            actualMinorUnits: line.actualAmountMinorUnits,
            percentageUsed: line.percentageUsed,
            status: switch (line.status) {
              budgets.BudgetCategoryStatus.onTrack =>
                BudgetCategoryStatus.onTrack,
              budgets.BudgetCategoryStatus.nearFull =>
                BudgetCategoryStatus.nearFull,
              budgets.BudgetCategoryStatus.overBudget =>
                BudgetCategoryStatus.overBudget,
            },
          ),
      ]),
    };
  }

  @override
  Future<bool> categoryBudgetExists(String categoryId, String month) async {
    if (!BudgetMonth.isValid(month)) return false;
    final result = await _budgets.getBudgetForMonth(month);
    return result.match(
      // Unknowable spend still leaves the plan itself readable, but the
      // repository answers the month as a whole; treat it as present so a
      // tap is never dismissed as stale on a rate problem.
      (failure) => failure is RatesMissingFailure,
      (detail) =>
          detail.summary?.categoryBreakdown.any(
            (line) => line.categoryId == categoryId,
          ) ??
          false,
    );
  }
}
