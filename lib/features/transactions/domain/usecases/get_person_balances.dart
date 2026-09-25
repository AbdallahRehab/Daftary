import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/person_balance.dart';
import '../repositories/transactions_repository.dart';

/// Balances for many people in one read (FR-008, FR-009) — the batched form
/// of `GetPersonBalance`, for lists that render every row's balance.
@injectable
class GetPersonBalances {
  const GetPersonBalances(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, Map<String, PersonBalance>>> call(
    List<String> personIds,
  ) => _repository.getPersonBalances(personIds);
}
