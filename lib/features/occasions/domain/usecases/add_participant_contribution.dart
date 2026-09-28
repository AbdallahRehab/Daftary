import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../repositories/occasions_repository.dart';

/// Records one participant's contribution at an occasion (FR-003/FR-004).
///
/// The contribution becomes an ordinary `MoneyTransaction` with
/// `kind = occasionContribution`, not a parallel record, which is what makes
/// the occasion's totals and the person's own balance physically incapable
/// of disagreeing (FR-005).
///
/// Passing `null` for [countsTowardBalance] means "use the occasion type's
/// default" — `false` under a condolence occasion, `true` everywhere else
/// (FR-018). That default is resolved by the repository, which is the only
/// layer that knows the parent occasion's current type; passing an explicit
/// value overrides it. Amount positivity is likewise the repository's rule,
/// shared with every other transaction write.
@injectable
class AddParticipantContribution {
  const AddParticipantContribution(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, MoneyTransaction>> call({
    required String idempotencyKey,
    required String occasionId,
    required String personId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
    bool? countsTowardBalance,
    String? note,
  }) {
    return _repository.addParticipantContribution(
      idempotencyKey: idempotencyKey,
      occasionId: occasionId,
      personId: personId,
      amount: amount,
      direction: direction,
      date: date,
      countsTowardBalance: countsTowardBalance,
      note: note,
    );
  }
}
