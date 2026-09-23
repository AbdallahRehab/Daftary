import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/occasions_repository.dart';

/// Deletes an occasion together with every contribution recorded under it
/// (FR-013).
///
/// This is the destructive step only — it assumes the caller has already
/// shown the "N contributions will be removed" confirmation. N comes from
/// [GetOccasionDetail]'s `summary.participantCount`, read before the dialog
/// is raised; there is deliberately no second "count" API here, because a
/// count fetched twice could disagree with the rows actually deleted.
///
/// The cascade itself stays in the repository, where both the occasion and
/// its contributions can be soft-deleted inside one DB transaction. Doing
/// it here, call by call, would make a half-applied delete — contributions
/// gone, occasion left behind — reachable on any mid-way failure.
@injectable
class DeleteOccasion {
  const DeleteOccasion(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, Unit>> call(String occasionId) =>
      _repository.deleteOccasion(occasionId);
}
