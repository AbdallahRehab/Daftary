import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/savings_repository.dart';

/// Removes an entry after the caller has confirmed (FR-009), keeping its
/// prior values in an audit row (FR-030). Refused when removing a
/// contribution would leave the goal's balance below zero.
@injectable
class DeleteContribution {
  const DeleteContribution(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, Unit>> call(String contributionId) =>
      _repository.deleteContribution(contributionId);
}
