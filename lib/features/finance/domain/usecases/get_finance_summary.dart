import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/finance_history_filter.dart';
import '../entities/finance_summary.dart';
import '../repositories/finance_repository.dart';

/// Total income, total expenses, and net for a period (FR-014).
@injectable
class GetFinanceSummary {
  const GetFinanceSummary(this._repository);

  final FinanceRepository _repository;

  Future<Either<Failure, FinanceSummary>> call(DateRange period) =>
      _repository.getSummary(period);
}
