import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/occasions_repository.dart';

/// Hides a finished occasion from the default list without destroying
/// anything (FR-014).
///
/// Archiving is the non-destructive alternative to [DeleteOccasion]: the
/// occasion's contributions keep counting toward every participant's
/// balance, so a user tidying their list can never accidentally rewrite
/// their financial history.
@injectable
class ArchiveOccasion {
  const ArchiveOccasion(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, Unit>> call(String occasionId) =>
      _repository.archiveOccasion(occasionId);
}
