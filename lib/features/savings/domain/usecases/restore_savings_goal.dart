import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/savings_repository.dart';

/// Brings an archived goal back into the active list (FR-020).
@injectable
class RestoreSavingsGoal {
  const RestoreSavingsGoal(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, Unit>> call(String goalId) =>
      _repository.restoreSavingsGoal(goalId);
}
