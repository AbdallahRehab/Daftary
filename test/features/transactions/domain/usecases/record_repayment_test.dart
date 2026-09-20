import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/record_repayment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repository;
  late RecordRepayment recordRepayment;

  setUp(() {
    repository = MockTransactionsRepository();
    recordRepayment = RecordRepayment(repository);
  });

  final date = DateTime(2026, 1, 1);

  test(
    'delegates to the repository without ever accepting a direction parameter '
    '(the repository infers it from the current balance — see the repository test for AC1-AC3)',
    () async {
      final repaymentTx = MoneyTransaction(
        id: 't1',
        idempotencyKey: 'key-1',
        personId: 'p1',
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.received,
        kind: TransactionKind.repayment,
        date: date,
        createdAt: date,
      );
      when(
        () => repository.recordRepayment(
          idempotencyKey: 'key-1',
          personId: 'p1',
          amount: const Money.fromMinorUnits(50000),
          date: date,
          note: null,
        ),
      ).thenAnswer((_) async => Right<Failure, MoneyTransaction>(repaymentTx));

      final result = await recordRepayment(
        idempotencyKey: 'key-1',
        personId: 'p1',
        amount: const Money.fromMinorUnits(50000),
        date: date,
      );

      expect(result, Right<Failure, MoneyTransaction>(repaymentTx));
      expect(
        result.getOrElse((_) => throw StateError('x')).kind,
        TransactionKind.repayment,
      );
    },
  );
}
