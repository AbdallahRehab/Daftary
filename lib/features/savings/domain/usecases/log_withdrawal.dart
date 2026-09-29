import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/savings_contribution.dart';
import '../repositories/savings_repository.dart';

/// Logs money taken back out of a goal (FR-006). Same rules as
/// `LogContribution`, plus: the converted amount may not exceed the goal's
/// current balance (`WithdrawalExceedsBalanceFailure`).
@injectable
class LogWithdrawal {
  const LogWithdrawal(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, SavingsContribution>> call({
    required String idempotencyKey,
    required String goalId,
    required Money amount,
    required DateTime date,
    String? note,
  }) => _repository.logWithdrawal(
    idempotencyKey: idempotencyKey,
    goalId: goalId,
    amount: amount,
    date: date,
    note: note,
  );
}
