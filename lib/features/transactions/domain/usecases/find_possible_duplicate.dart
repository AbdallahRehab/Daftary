import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/money_transaction.dart';
import '../repositories/transactions_repository.dart';

/// 022 C4: looks for an active transaction that looks identical to one
/// about to be recorded (same person, amount, currency, direction, date).
@injectable
class FindPossibleDuplicate {
  const FindPossibleDuplicate(this._repository);

  final TransactionsRepository _repository;

  Future<Either<Failure, MoneyTransaction?>> call({
    required String personId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
  }) => _repository.findPossibleDuplicate(personId, amount, direction, date);
}
