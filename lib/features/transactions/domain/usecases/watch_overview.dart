import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/overview_summary.dart';
import '../repositories/transactions_repository.dart';

/// 021: the live consolidated overview (FR-013, FR-014, FR-031) — it
/// updates on its own after a change on any other screen.
@injectable
class WatchOverview {
  const WatchOverview(this._repository);

  final TransactionsRepository _repository;

  Stream<Either<Failure, OverviewSummary>> call() =>
      _repository.watchOverview();
}
