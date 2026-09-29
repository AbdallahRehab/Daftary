import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/savings_goal.dart';
import '../repositories/savings_repository.dart';

/// Edits a goal's name, type, target, monthly contribution and target date
/// (FR-029) — never its currency (FR-027) and never its history. Every
/// derived figure recalculates on the next read.
///
/// Also the write path a what-if scenario is applied through (FR-015):
/// applying one is an ordinary goal edit.
@injectable
class EditSavingsGoal {
  const EditSavingsGoal(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, SavingsGoal>> call({
    required String goalId,
    required String name,
    String? type,
    required int targetAmountMinorUnits,
    int? monthlyContributionMinorUnits,
    DateTime? targetDate,
  }) => _repository.editSavingsGoal(
    goalId: goalId,
    name: name,
    type: type,
    targetAmountMinorUnits: targetAmountMinorUnits,
    monthlyContributionMinorUnits: monthlyContributionMinorUnits,
    targetDate: targetDate,
  );
}
