import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget_trend_point.dart';
import '../repositories/budgets_repository.dart';

/// 021: the live form of `GetBudgetTrend` (FR-014, FR-031) — the trend
/// view's points, re-emitted whenever a budget, an allocation, an expense,
/// a category, a rate or the primary currency changes.
@injectable
class WatchBudgetTrend {
  const WatchBudgetTrend(this._repository);

  final BudgetsRepository _repository;

  Stream<Either<Failure, List<BudgetTrendPoint>>> call({
    String? categoryId,
    int monthsBack = 6,
    String? endMonth,
  }) => _repository.watchBudgetTrend(
    categoryId: categoryId,
    monthsBack: monthsBack,
    endMonth: endMonth,
  );
}
