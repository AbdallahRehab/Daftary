import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/savings_overview.dart';
import '../repositories/savings_repository.dart';

/// Every active goal — archived ones too with `includeArchived` — with its
/// progress in its own currency and a combined total saved, converted into
/// the primary currency at read time (FR-019). A goal needing a missing
/// rate is listed but blocked and left out of the total
/// (`SavingsOverview.isIncomplete`, 018 FR-009).
///
/// Also what the assistant's savings-status tool and Home read the
/// feature through (research.md Decision 13).
@injectable
class GetSavingsOverview {
  const GetSavingsOverview(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, SavingsOverview>> call({
    bool includeArchived = false,
  }) => _repository.getSavingsOverview(includeArchived: includeArchived);
}
