import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/transactions_repository.dart';

/// Soft-deletes a transaction after the caller has already shown the
/// "cannot be undone" confirmation (FR-016).
@injectable
class DeleteTransaction {
  const DeleteTransaction(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, Unit>> call(String transactionId) =>
      _repository.deleteTransaction(transactionId);
}
