import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget_category_allocation.dart';
import '../repositories/budgets_repository.dart';

/// Adds one expense category's planned amount to a budget (FR-001/FR-002).
///
/// The rules — non-negative amount (zero allowed), active expense-type
/// category, one allocation per category — are enforced by the repository
/// for every caller. [idempotencyKey] makes a double-tapped "Add" return
/// the row it already wrote (FR-017).
@injectable
class AddBudgetCategoryAllocation {
  const AddBudgetCategoryAllocation(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, BudgetCategoryAllocation>> call({
    required String idempotencyKey,
    required String budgetId,
    required String categoryId,
    required int plannedAmountMinorUnits,
  }) {
    return _repository.addBudgetCategoryAllocation(
      idempotencyKey: idempotencyKey,
      budgetId: budgetId,
      categoryId: categoryId,
      plannedAmountMinorUnits: plannedAmountMinorUnits,
    );
  }
}
