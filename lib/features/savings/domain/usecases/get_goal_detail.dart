import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/savings_goal_detail.dart';
import '../repositories/savings_repository.dart';

/// One goal with its computed progress (FR-010-FR-012, FR-017) and its
/// history in chronological order (FR-008).
///
/// A pass-through: `GoalProgress` derives remaining/percentage/achieved and
/// `SavingsCalculator` every estimate, so the arithmetic exists once. Also
/// what a what-if exploration reads the goal's current state through.
@injectable
class GetGoalDetail {
  const GetGoalDetail(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, SavingsGoalDetail>> call(String goalId) =>
      _repository.getGoalDetail(goalId);
}
