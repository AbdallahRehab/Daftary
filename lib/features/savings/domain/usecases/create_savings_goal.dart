import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../currency/domain/usecases/get_primary_currency.dart';
import '../entities/savings_goal.dart';
import '../repositories/savings_repository.dart';

/// Creates a savings goal (FR-001), optionally with a starting amount that
/// becomes its first entry (research.md Decision 3).
///
/// [idempotencyKey] is caller-supplied — generated once per save action —
/// so a rapid double-tap returns the goal already created (FR-022).
/// [currency] defaults to the primary currency (FR-027); it is fixed for
/// the goal's life.
///
/// Validation lives in the repository, which owns it for every caller.
@injectable
class CreateSavingsGoal {
  const CreateSavingsGoal(this._repository, this._getPrimaryCurrency);

  final SavingsRepository _repository;
  final GetPrimaryCurrency _getPrimaryCurrency;

  Future<Either<Failure, SavingsGoal>> call({
    required String idempotencyKey,
    required String name,
    String? type,
    Currency? currency,
    required int targetAmountMinorUnits,
    int? startingAmountMinorUnits,
    int? monthlyContributionMinorUnits,
    DateTime? targetDate,
  }) async {
    final Currency goalCurrency;
    if (currency != null) {
      goalCurrency = currency;
    } else {
      final primary = await _getPrimaryCurrency();
      if (primary.isLeft()) return Left(primary.getLeft().toNullable()!);
      goalCurrency = primary.toNullable()!.currency;
    }
    return _repository.createSavingsGoal(
      idempotencyKey: idempotencyKey,
      name: name,
      type: type,
      currency: goalCurrency,
      targetAmountMinorUnits: targetAmountMinorUnits,
      startingAmountMinorUnits: startingAmountMinorUnits,
      monthlyContributionMinorUnits: monthlyContributionMinorUnits,
      targetDate: targetDate,
    );
  }
}
