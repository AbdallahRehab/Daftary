import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/occasion_detail.dart';
import '../repositories/occasions_repository.dart';

/// 021: the live `GetOccasionDetail` (FR-007, FR-031). Re-emits when a
/// contribution is added, edited or removed — here, from the person's own
/// profile, or through sync — when a photo is attached or removed, when a
/// participant is renamed, and when the primary currency or a rate changes,
/// because the totals are converted (018).
///
/// Still one consistent read per emission, so the totals card and the rows
/// beneath it can never disagree.
@injectable
class WatchOccasionDetail {
  const WatchOccasionDetail(this._repository);

  final OccasionsRepository _repository;

  Stream<Either<Failure, OccasionDetail>> call(String occasionId) =>
      _repository.watchOccasionDetail(occasionId);
}
