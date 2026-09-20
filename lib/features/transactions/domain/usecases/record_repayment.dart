import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/money_transaction.dart';
import '../repositories/transactions_repository.dart';

/// Records a repayment against an existing balance (FR-011). Accepts an
/// amount larger than the outstanding balance and lets the resulting
/// balance flip direction rather than blocking (FR-012). `direction` is
/// always inferred by the repository from the current balance.
@injectable
class RecordRepayment {
  const RecordRepayment(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, MoneyTransaction>> call({
    required String idempotencyKey,
    required String personId,
    required Money amount,
    required DateTime date,
    String? note,
  }) {
    return _repository.recordRepayment(
      idempotencyKey: idempotencyKey,
      personId: personId,
      amount: amount,
      date: date,
      note: note,
    );
  }
}
