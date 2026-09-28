import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget_summary.dart';
import '../repositories/budgets_repository.dart';

/// 021: the live [BudgetMonthDetail] for one month (FR-031) — what the
/// budget month screen subscribes to, so an expense recorded, an allocation
/// edited or an exchange rate set anywhere (or applied by sync) updates the
/// open screen with no reload.
///
/// A pass-through for the same reason as `GetBudgetForMonth`: every figure
/// is derived by the value objects, so the arithmetic exists once.
@injectable
class WatchBudgetForMonth {
  const WatchBudgetForMonth(this._repository);

  final BudgetsRepository _repository;

  Stream<Either<Failure, BudgetMonthDetail>> call(String month) =>
      _repository.watchBudgetForMonth(month);
}
