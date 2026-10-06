import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/transactions_repository.dart';

/// 022 E6: how many repayments were recorded on or after a transaction's
/// date, so deleting it can warn about the balance consequence.
@injectable
class CountLaterRepayments {
  const CountLaterRepayments(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, int>> call(
    String personId,
    DateTime fromDate, {
    String? excludingTransactionId,
  }) => _repository.countLaterRepayments(
    personId,
    fromDate,
    excludingTransactionId: excludingTransactionId,
  );
}
