import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/finance_entry.dart';
import '../entities/finance_history_filter.dart';
import '../repositories/finance_repository.dart';

/// 021: the live first [limit] history entries, newest first (FR-012,
/// FR-013, FR-031). Paging resubscribes with a larger limit.
@injectable
class WatchFinanceHistory {
  const WatchFinanceHistory(this._repository);

  final FinanceRepository _repository;

  Stream<Either<Failure, List<FinanceEntry>>> call({
    FinanceHistoryFilter? filter,
    required int limit,
  }) => _repository.watchHistory(filter: filter, limit: limit);
}
