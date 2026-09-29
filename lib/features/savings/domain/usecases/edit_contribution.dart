import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/savings_contribution.dart';
import '../repositories/savings_repository.dart';

/// Corrects an entry's amount, date or note (FR-009) — never its type. A
/// foreign-currency amount is re-converted at the current rate; the prior
/// values are kept in an audit row (FR-030). Allowed on an archived goal.
@injectable
class EditContribution {
  const EditContribution(this._repository);

  final SavingsRepository _repository;

  Future<Either<Failure, SavingsContribution>> call({
    required String contributionId,
    required Money amount,
    required DateTime date,
    String? note,
  }) => _repository.editContribution(
    contributionId: contributionId,
    amount: amount,
    date: date,
    note: note,
  );
}
