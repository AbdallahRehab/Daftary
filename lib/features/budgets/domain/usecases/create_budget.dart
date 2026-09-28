import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget.dart';
import '../repositories/budgets_repository.dart';

/// Creates a budget for one calendar month (FR-001/FR-003).
///
/// [idempotencyKey] is caller-supplied — generated once per save action,
/// not here — which is what turns a rapid double-tap on "Save" into a call
/// that returns the already-created budget instead of a second one
/// (FR-017).
///
/// Month-format and income validation, and the one-budget-per-month rule,
/// live in the repository, which owns them for every caller; repeating them
/// here would create a second place for the answers to drift apart.
@injectable
class CreateBudget {
  const CreateBudget(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, Budget>> call({
    required String idempotencyKey,
    required String month,
    int? expectedIncomeMinorUnits,
  }) {
    return _repository.createBudget(
      idempotencyKey: idempotencyKey,
      month: month,
      expectedIncomeMinorUnits: expectedIncomeMinorUnits,
    );
  }
}
