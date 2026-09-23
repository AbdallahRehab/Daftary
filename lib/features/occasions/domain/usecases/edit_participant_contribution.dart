import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../repositories/occasions_repository.dart';

/// Corrects a contribution's amount, direction, date, or note (FR-010).
///
/// Takes a `transactionId` rather than an occasion-scoped identifier on
/// purpose: there is exactly one row behind a contribution, so an edit made
/// from the occasion screen and one made from the person's own profile are
/// the same operation on the same record and cannot drift apart.
///
/// `kind` and `occasionId` are deliberately absent from the parameter list —
/// a contribution's classification is fixed at creation, and reclassifying
/// means delete plus re-create.
@injectable
class EditParticipantContribution {
  const EditParticipantContribution(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, MoneyTransaction>> call({
    required String transactionId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
    String? note,
  }) {
    return _repository.editParticipantContribution(
      transactionId: transactionId,
      amount: amount,
      direction: direction,
      date: date,
      note: note,
    );
  }
}
