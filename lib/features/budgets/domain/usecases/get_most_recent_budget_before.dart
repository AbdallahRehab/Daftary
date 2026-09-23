import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget.dart';
import '../repositories/budgets_repository.dart';

/// The budget the FR-018 empty state offers to copy forward (FR-012): the
/// most recent month before [month] that has one, or `null` when the user
/// has never budgeted an earlier month (the offer is then hidden).
@injectable
class GetMostRecentBudgetBefore {
  const GetMostRecentBudgetBefore(this._repository);

  final BudgetsRepository _repository;

  Future<Either<Failure, Budget?>> call(String month) =>
      _repository.getMostRecentBudgetBefore(month);
}
