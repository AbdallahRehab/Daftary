import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/preview_transaction_deletion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/currency_test_doubles.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

/// 022 E6: only a non-repayment row is checked for later repayments.
void main() {
  late MockTransactionsRepository repository;
  late PreviewTransactionDeletion preview;
  final now = DateTime(2026, 1, 1);
  const balance = PersonBalance(personId: 'p1', net: Money.egp(60000));

  MoneyTransaction row(TransactionKind kind) => MoneyTransaction(
    id: 't1',
    idempotencyKey: 'k',
    personId: 'p1',
    amount: const Money.egp(40000),
    direction: TransactionDirection.received,
    kind: kind,
    date: now,
    createdAt: now,
  );

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    repository = MockTransactionsRepository();
    preview = PreviewTransactionDeletion(
      repository,
      getConversionContextWith(),
    );
    when(
      () => repository.countLaterRepayments(
        any(),
        any(),
        excludingTransactionId: any(named: 'excludingTransactionId'),
      ),
    ).thenAnswer((_) async => const Right(2));
  });

  test('an initial-exchange row counts the later repayments', () async {
    final impact = (await preview(
      row(TransactionKind.initialExchange),
      balance,
    )).getOrElse((f) => throw StateError('$f'));

    expect(impact.laterRepaymentCount, 2);
    verify(
      () => repository.countLaterRepayments(
        'p1',
        now,
        excludingTransactionId: 't1',
      ),
    ).called(1);
  });

  test('a repayment row skips the count and reports none', () async {
    final impact = (await preview(
      row(TransactionKind.repayment),
      balance,
    )).getOrElse((f) => throw StateError('$f'));

    expect(impact.laterRepaymentCount, 0);
    expect(impact.resultingNet, const Money.egp(100000));
    verifyNever(
      () => repository.countLaterRepayments(
        any(),
        any(),
        excludingTransactionId: any(named: 'excludingTransactionId'),
      ),
    );
  });
}
