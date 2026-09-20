import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/overview_summary.dart';
import '../repositories/transactions_repository.dart';

/// Consolidated totals/groupings across all people, active and archived
/// (FR-013, FR-024).
@injectable
class GetOverview {
  const GetOverview(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, OverviewSummary>> call() => _repository.getOverview();
}
