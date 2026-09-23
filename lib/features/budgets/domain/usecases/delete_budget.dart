import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/budgets_repository.dart';

/// Deletes a whole budget (FR-011).
///
/// The destructive step only — it assumes the caller has already shown the
/// confirmation. The expense entries the budget was compared against are
/// 007's and are never touched (FR-022); the month simply goes back to
/// having no budget.
@injectable
class DeleteBudget {
  const DeleteBudget(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, Unit>> call(String budgetId) =>
      _repository.deleteBudget(budgetId);
}
