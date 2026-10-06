import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../currency/domain/usecases/get_conversion_context.dart';
import '../entities/money_transaction.dart';
import '../entities/person_balance.dart';
import '../repositories/transactions_repository.dart';
import '../services/deletion_impact.dart';

/// 022 E6: what deleting [transaction] would do, shown before the user
/// confirms. Read-only; never blocks the deletion.
@injectable
class PreviewTransactionDeletion {
  const PreviewTransactionDeletion(this._repository, this._getContext);

  final TransactionsRepository _repository;
  final GetConversionContext _getContext;

  Future<Either<Failure, DeletionImpact>> call(
    MoneyTransaction transaction,
    PersonBalance balance,
  ) async {
    // Only a non-repayment row can have repayments recorded "against" it.
    final count = transaction.kind == TransactionKind.repayment
        ? const Right<Failure, int>(0)
        : await _repository.countLaterRepayments(
            transaction.personId,
            transaction.date,
            excludingTransactionId: transaction.id,
          );
    return count.match(
      (failure) async => Left<Failure, DeletionImpact>(failure),
      (laterRepayments) async => (await _getContext()).map(
        (context) => DeletionImpact.of(
          transaction: transaction,
          balance: balance,
          context: context,
          laterRepaymentCount: laterRepayments,
        ),
      ),
    );
  }
}
