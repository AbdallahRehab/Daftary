import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/savings_contribution.dart';
import '../repositories/savings_repository.dart';

/// Logs money put toward a goal (FR-005), in any currency: a foreign amount
/// is converted into the goal's currency now, and both figures are kept
/// (FR-028). Rejected on an archived goal (FR-020) and when the rate is
/// missing; idempotent on [idempotencyKey] (FR-022).
@injectable
class LogContribution {
  const LogContribution(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, SavingsContribution>> call({
    required String idempotencyKey,
    required String goalId,
    required Money amount,
    required DateTime date,
    String? note,
  }) => _repository.logContribution(
    idempotencyKey: idempotencyKey,
    goalId: goalId,
    amount: amount,
    date: date,
    note: note,
  );
}
