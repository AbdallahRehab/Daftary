import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/occasion_detail.dart';
import '../repositories/occasions_repository.dart';

/// The whole occasion detail screen's data in one read: the occasion, its
/// computed totals and settlement label (FR-007/FR-008), its participant
/// rows (FR-016), and its attachments.
///
/// Intentionally a thin pass-through. The repository already assembles the
/// [OccasionDetail] from a single consistent read, and each row's
/// `personOverallStatus` is that person's full `PersonBalance` (FR-009).
/// Re-aggregating any of it here would mean two implementations of the same
/// arithmetic, and a totals card that could disagree with the rows beneath
/// it.
///
/// Also the source of the affected-contribution count a caller must show
/// before [DeleteOccasion]: `summary.participantCount` (FR-013).
@injectable
class GetOccasionDetail {
  const GetOccasionDetail(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, OccasionDetail>> call(String occasionId) =>
      _repository.getOccasionDetail(occasionId);
}
