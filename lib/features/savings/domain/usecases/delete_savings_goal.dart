import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/savings_repository.dart';

/// Deletes a goal that has never had an entry (FR-021). A goal with any
/// history — even entries since deleted — is refused with
/// `GoalHasHistoryFailure`, and the caller offers `ArchiveSavingsGoal`
/// instead. To the user the goal is gone; in storage it is a synced
/// tombstone.
@injectable
class DeleteSavingsGoal {
  const DeleteSavingsGoal(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, Unit>> call(String goalId) =>
      _repository.deleteSavingsGoal(goalId);
}
