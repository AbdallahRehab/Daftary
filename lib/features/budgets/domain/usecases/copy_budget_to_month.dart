import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget.dart';
import '../repositories/budgets_repository.dart';

/// Starts [targetMonth]'s budget as a copy of an existing one (FR-012).
///
/// The result is fully independent: new rows, no link back, so editing
/// either budget afterward never affects the other. The copy itself runs
/// in one DB transaction in the repository — doing it here as a create
/// followed by N allocation adds would make a half-copied budget reachable
/// on any mid-way failure.
@injectable
class CopyBudgetToMonth {
  const CopyBudgetToMonth(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, Budget>> call({
    required String idempotencyKey,
    required String sourceBudgetId,
    required String targetMonth,
  }) {
    return _repository.copyBudgetToMonth(
      idempotencyKey: idempotencyKey,
      sourceBudgetId: sourceBudgetId,
      targetMonth: targetMonth,
    );
  }
}
