import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/money_transaction.dart';
import '../repositories/transactions_repository.dart';

/// Full chronological history for one person, non-deleted rows only
/// (FR-010).
@injectable
class GetPersonHistory {
  const GetPersonHistory(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, List<MoneyTransaction>>> call(String personId) =>
      _repository.getPersonHistory(personId);
}
