import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../entities/money_transaction.dart';
import '../entities/person_balance.dart';
import 'balance_projection.dart';

/// What deleting a transaction leaves behind (022 E6): how many later
/// repayments were recorded after it and the balance without it.
class DeletionImpact extends Equatable {
  const DeletionImpact({
    required this.laterRepaymentCount,
    required this.resultingNet,
  });

  /// Pure part: the balance once [transaction] no longer counts. `null`
  /// when it cannot be computed (blocked balance, missing rate).
  factory DeletionImpact.of({
    required MoneyTransaction transaction,
    required PersonBalance balance,
    required ConversionContext context,
    required int laterRepaymentCount,
  }) {
    Money? resulting = balance.net;
    if (transaction.countsTowardBalance) {
      final removed = transaction.direction == TransactionDirection.given
          ? -transaction.amount.minorUnits
          : transaction.amount.minorUnits;
      resulting = BalanceProjection.afterChange(
        balance,
        Money.fromMinorUnits(removed, transaction.amount.currency),
        context,
      );
    }
    return DeletionImpact(
      laterRepaymentCount: laterRepaymentCount,
      resultingNet: resulting,
    );
  }

  final int laterRepaymentCount;

  /// Positive = they owe you. `null` = unknown.
  final Money? resultingNet;

  @override
  List<Object?> get props => [laterRepaymentCount, resultingNet];
}
