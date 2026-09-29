import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/savings_goal_detail.dart';
import '../repositories/savings_repository.dart';

/// 021: the live `GetGoalDetail` — what the goal page subscribes to, so an
/// entry logged, edited or deleted (here, or applied by sync) updates the
/// open page with no reload (FR-009 "immediately").
@injectable
class WatchGoalDetail {
  const WatchGoalDetail(this._repository);

  final SavingsRepository _repository;

  Stream<Either<Failure, SavingsGoalDetail>> call(String goalId) =>
      _repository.watchGoalDetail(goalId);
}
