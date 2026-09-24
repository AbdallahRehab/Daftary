import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/ports/budget_insights_source.dart';

/// Placeholder while 010 Household Budgets is not implemented in code: no
/// budgets exist, so there is never anything to warn about. Replaced by an
/// adapter over 010's `BudgetRepository` once that feature ships.
@LazySingleton(as: BudgetInsightsSource)
class UnavailableBudgetInsightsSource implements BudgetInsightsSource {
  const UnavailableBudgetInsightsSource();

  @override
  Future<Either<Failure, List<BudgetCategorySnapshot>>>
  currentMonthCategories() async => const Right([]);

  @override
  Future<bool> categoryBudgetExists(String categoryId, String month) async =>
      false;
}
