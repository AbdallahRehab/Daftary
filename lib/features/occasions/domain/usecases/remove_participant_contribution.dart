import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/occasions_repository.dart';

/// Removes one participant's contribution from an occasion after the caller
/// has shown an explicit confirmation (FR-011).
///
/// Soft-deletes the single underlying `MoneyTransaction`, so the row leaves
/// the occasion's participant list and the person's own history and balance
/// together — removing money from one view while it lingers in the other is
/// not an expressible outcome.
@injectable
class RemoveParticipantContribution {
  const RemoveParticipantContribution(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, Unit>> call(String transactionId) =>
      _repository.removeParticipantContribution(transactionId);
}
