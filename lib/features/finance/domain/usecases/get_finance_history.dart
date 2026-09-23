import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/finance_entry.dart';
import '../entities/finance_history_filter.dart';
import '../repositories/finance_repository.dart';

/// Filtered, paginated entry history, newest first (FR-012/FR-013).
@injectable
class GetFinanceHistory {
  const GetFinanceHistory(this._repository);

  final FinanceRepository _repository;

  Future<Either<Failure, List<FinanceEntry>>> call({
    FinanceHistoryFilter? filter,
    int limit = 50,
    int offset = 0,
  }) {
    return _repository.getHistory(filter: filter, limit: limit, offset: offset);
  }
}
