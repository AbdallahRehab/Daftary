import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/money_transaction.dart';
import '../repositories/transactions_repository.dart';

/// Edits amount/direction/date/note of an existing transaction (FR-015).
/// `kind` is immutable and never accepted here (Clarifications).
@injectable
class EditTransaction {
  const EditTransaction(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, MoneyTransaction>> call({
    required String transactionId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
    String? note,
  }) {
    return _repository.editTransaction(
      transactionId: transactionId,
      amount: amount,
      direction: direction,
      date: date,
      note: note,
    );
  }
}
