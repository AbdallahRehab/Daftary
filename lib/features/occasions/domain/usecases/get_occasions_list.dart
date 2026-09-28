import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/occasion.dart';
import '../entities/occasion_filter.dart';
import '../repositories/occasions_repository.dart';

/// The occasions list, reverse-chronological so the most recent event is
/// what the user sees first (FR-015).
///
/// [includeArchived] defaults to `false`, which is what keeps archiving
/// meaningful: the archived view is an explicit, separate request rather
/// than something a caller can fall into by forgetting a flag.
@injectable
class GetOccasionsList {
  const GetOccasionsList(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, List<Occasion>>> call({
    OccasionFilter? filter,
    bool includeArchived = false,
  }) {
    return _repository.getOccasionsList(
      filter: filter,
      includeArchived: includeArchived,
    );
  }
}
