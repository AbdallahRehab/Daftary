import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/occasions_repository.dart';

/// Returns an archived occasion to the default list (FR-014).
///
/// The exact inverse of [ArchiveOccasion], and the reason archiving is safe
/// to offer without a confirmation step: nothing about the occasion or its
/// contributions changed while it was hidden, so restoring is a pure
/// visibility flip.
@injectable
class RestoreOccasion {
  const RestoreOccasion(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, Unit>> call(String occasionId) =>
      _repository.restoreOccasion(occasionId);
}
