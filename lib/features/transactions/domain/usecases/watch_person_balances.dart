import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/person_balance.dart';
import '../repositories/transactions_repository.dart';

/// 021: live balances for many people in one read — the watched form of
/// `GetPersonBalances` (FR-031).
@injectable
class WatchPersonBalances {
  const WatchPersonBalances(this._repository);

  final TransactionsRepository _repository;

  Stream<Either<Failure, Map<String, PersonBalance>>> call(
    List<String> personIds,
  ) => _repository.watchPersonBalances(personIds);
}
