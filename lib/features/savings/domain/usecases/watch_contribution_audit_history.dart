import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/savings_contribution_audit.dart';
import '../repositories/savings_repository.dart';

/// 022 C3: the live, read-only edit/delete history of one contribution,
/// oldest first — what the "Edited" marker's history sheet shows.
@injectable
class WatchContributionAuditHistory {
  const WatchContributionAuditHistory(this._repository);

  final SavingsRepository _repository;

  Stream<Either<Failure, List<SavingsContributionAudit>>> call(
    String contributionId,
  ) => _repository.watchContributionAuditHistory(contributionId);
}
