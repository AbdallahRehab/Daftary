import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/transaction_audit_entry.dart';
import '../repositories/transactions_repository.dart';

/// 022 C3: the live, read-only change history of one transaction, oldest
/// first — what the "Edited" marker's history sheet shows.
@injectable
class WatchTransactionAuditHistory {
  const WatchTransactionAuditHistory(this._repository);

  final TransactionsRepository _repository;

  Stream<Either<Failure, List<TransactionAuditEntry>>> call(
    String transactionId,
  ) => _repository.watchAuditHistory(transactionId);
}
