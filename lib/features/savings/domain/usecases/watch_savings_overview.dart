import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/savings_overview.dart';
import '../repositories/savings_repository.dart';

/// 021: the live `GetSavingsOverview` — re-emits whenever a goal, an
/// entry, a rate or the primary currency changes, here or through sync.
@injectable
class WatchSavingsOverview {
  const WatchSavingsOverview(this._repository);

  final SavingsRepository _repository;

  Stream<Either<Failure, SavingsOverview>> call({
    bool includeArchived = false,
  }) => _repository.watchSavingsOverview(includeArchived: includeArchived);
}
