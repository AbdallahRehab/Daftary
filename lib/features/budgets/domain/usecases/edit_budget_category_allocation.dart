import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget_category_allocation.dart';
import '../repositories/budgets_repository.dart';

/// Changes an allocation's planned amount (FR-010). Zero is allowed; a
/// negative amount is refused (FR-002).
@injectable
class EditBudgetCategoryAllocation {
  const EditBudgetCategoryAllocation(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, BudgetCategoryAllocation>> call({
    required String allocationId,
    required int plannedAmountMinorUnits,
  }) {
    return _repository.editBudgetCategoryAllocation(
      allocationId: allocationId,
      plannedAmountMinorUnits: plannedAmountMinorUnits,
    );
  }
}
