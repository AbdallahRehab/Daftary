import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/money_transaction.dart';
import '../repositories/transactions_repository.dart';

/// Records a regular given/received transaction (FR-004). [idempotencyKey]
/// is caller-supplied — generated once per "Save" tap, not here — so a
/// retried call with the same key is a no-op (FR-020, SC-006).
@injectable
class AddTransaction {
  const AddTransaction(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, MoneyTransaction>> call({
    required String idempotencyKey,
    required String personId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
    String? note,
  }) {
    return _repository.addTransaction(
      idempotencyKey: idempotencyKey,
      personId: personId,
      amount: amount,
      direction: direction,
      date: date,
      note: note,
    );
  }
}
