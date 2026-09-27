import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/money_transaction.dart';
import '../repositories/transactions_repository.dart';

/// 021: one person's live transaction history (FR-010, FR-031).
@injectable
class WatchPersonHistory {
  const WatchPersonHistory(this._repository);

  final TransactionsRepository _repository;

  Stream<Either<Failure, List<MoneyTransaction>>> call(String personId) =>
      _repository.watchPersonHistory(personId);
}
