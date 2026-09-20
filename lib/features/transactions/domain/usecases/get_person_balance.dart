import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/person_balance.dart';
import '../repositories/transactions_repository.dart';

/// Computed net balance + status for one person (FR-008, FR-009).
@injectable
class GetPersonBalance {
  const GetPersonBalance(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, PersonBalance>> call(String personId) =>
      _repository.getPersonBalance(personId);
}
