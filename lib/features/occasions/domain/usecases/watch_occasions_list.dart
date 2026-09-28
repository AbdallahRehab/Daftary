import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/occasion.dart';
import '../entities/occasion_filter.dart';
import '../repositories/occasions_repository.dart';

/// 021: the live `GetOccasionsList` (FR-015, FR-031) — an occasion created,
/// edited, archived, restored or deleted on any screen, or applied by
/// sync, reaches the list with no reload.
///
/// [includeArchived] keeps `GetOccasionsList`'s default of `false`, so the
/// archived view stays an explicit, separate request.
@injectable
class WatchOccasionsList {
  const WatchOccasionsList(this._repository);

  final OccasionsRepository _repository;

  Stream<Either<Failure, List<Occasion>>> call({
    OccasionFilter? filter,
    bool includeArchived = false,
  }) => _repository.watchOccasionsList(
    filter: filter,
    includeArchived: includeArchived,
  );
}
