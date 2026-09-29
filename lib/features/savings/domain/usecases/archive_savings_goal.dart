import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/savings_repository.dart';

/// Hides a goal from the active list and overview, keeping it and its full
/// history (FR-020). Its existing entries stay editable; new ones need a
/// restore first.
@injectable
class ArchiveSavingsGoal {
  const ArchiveSavingsGoal(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, Unit>> call(String goalId) =>
      _repository.archiveSavingsGoal(goalId);
}
