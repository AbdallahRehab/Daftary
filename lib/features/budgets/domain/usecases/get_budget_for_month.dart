import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget_summary.dart';
import '../repositories/budgets_repository.dart';

/// The whole budget month screen's data in one read: the budget, its
/// computed summary and per-category lines, and unbudgeted spending
/// (FR-005/FR-006/FR-007/FR-009), plus the FR-004 "planned exceeds income"
/// hint via [BudgetMonthDetail.plannedExceedsExpectedIncome].
///
/// Intentionally a thin pass-through: every figure is derived by the value
/// objects from the two inputs the repository supplies (planned, actual),
/// so there is exactly one implementation of the arithmetic. A month with
/// no budget is a successful [BudgetMonthDetail.empty], not a failure
/// (FR-018).
@injectable
class GetBudgetForMonth {
  const GetBudgetForMonth(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, BudgetMonthDetail>> call(String month) =>
      _repository.getBudgetForMonth(month);
}
