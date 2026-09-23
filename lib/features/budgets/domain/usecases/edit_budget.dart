import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget.dart';
import '../repositories/budgets_repository.dart';

/// Sets or clears a budget's expected income reference figure (FR-003).
/// `null` clears it. Allocations have their own use cases — this never
/// touches them.
@injectable
class EditBudget {
  const EditBudget(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, Budget>> call({
    required String budgetId,
    int? expectedIncomeMinorUnits,
  }) {
    return _repository.editBudget(
      budgetId: budgetId,
      expectedIncomeMinorUnits: expectedIncomeMinorUnits,
    );
  }
}
