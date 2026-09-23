import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget_trend_point.dart';
import '../repositories/budgets_repository.dart';

/// Planned-vs-actual across recent months (FR-014), overall or for one
/// category, oldest month first.
///
/// Returns every month in the window, budgeted or not; whether there is
/// enough history to show a chart is the caller's call via
/// [BudgetTrendHistory.hasEnoughHistory], so the "not enough history yet"
/// state and the chart are driven by the same list.
@injectable
class GetBudgetTrend {
  const GetBudgetTrend(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, List<BudgetTrendPoint>>> call({
    String? categoryId,
    int monthsBack = 6,
    String? endMonth,
  }) {
    return _repository.getBudgetTrend(
      categoryId: categoryId,
      monthsBack: monthsBack,
      endMonth: endMonth,
    );
  }
}
