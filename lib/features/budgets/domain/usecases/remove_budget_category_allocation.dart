import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/budgets_repository.dart';

/// Removes a category from its budget (FR-010). Any spend in that category
/// for the month is not lost — it reappears as unbudgeted spending (FR-007)
/// on the next read.
@injectable
class RemoveBudgetCategoryAllocation {
  const RemoveBudgetCategoryAllocation(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, Unit>> call(String allocationId) =>
      _repository.removeBudgetCategoryAllocation(allocationId);
}
