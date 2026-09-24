import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/add_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repository;
  late AddTransaction addTransaction;

  setUp(() {
    repository = MockTransactionsRepository();
    addTransaction = AddTransaction(repository);
  });

  final date = DateTime(2026, 1, 1);
  final transaction = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'key-1',
    personId: 'p1',
    amount: const Money.egp(200000),
    direction: TransactionDirection.received,
    kind: TransactionKind.initialExchange,
    date: date,
    createdAt: date,
  );

  test(
    'delegates to the repository and returns the saved transaction',
    () async {
      when(
        () => repository.addTransaction(
          idempotencyKey: 'key-1',
          personId: 'p1',
          amount: const Money.egp(200000),
          direction: TransactionDirection.received,
          date: date,
          note: null,
        ),
      ).thenAnswer((_) async => Right<Failure, MoneyTransaction>(transaction));

      final result = await addTransaction(
        idempotencyKey: 'key-1',
        personId: 'p1',
        amount: const Money.egp(200000),
        direction: TransactionDirection.received,
        date: date,
      );

      expect(result, Right<Failure, MoneyTransaction>(transaction));
    },
  );

  test(
    'surfaces a ValidationFailure for a non-positive amount (FR-005)',
    () async {
      when(
        () => repository.addTransaction(
          idempotencyKey: 'key-1',
          personId: 'p1',
          amount: const Money.egp(0),
          direction: TransactionDirection.given,
          date: date,
          note: null,
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, MoneyTransaction>(
          ValidationFailure('Amount must be greater than zero'),
        ),
      );

      final result = await addTransaction(
        idempotencyKey: 'key-1',
        personId: 'p1',
        amount: const Money.egp(0),
        direction: TransactionDirection.given,
        date: date,
      );

      expect(
        result,
        const Left<Failure, MoneyTransaction>(
          ValidationFailure('Amount must be greater than zero'),
        ),
      );
    },
  );

  test(
    'surfaces a ValidationFailure when no distinct counterparty is selected (Edge Cases)',
    () async {
      when(
        () => repository.addTransaction(
          idempotencyKey: 'key-1',
          personId: '',
          amount: const Money.egp(1000),
          direction: TransactionDirection.given,
          date: date,
          note: null,
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, MoneyTransaction>(
          ValidationFailure('A person must be selected'),
        ),
      );

      final result = await addTransaction(
        idempotencyKey: 'key-1',
        personId: '',
        amount: const Money.egp(1000),
        direction: TransactionDirection.given,
        date: date,
      );

      expect(
        result,
        const Left<Failure, MoneyTransaction>(
          ValidationFailure('A person must be selected'),
        ),
      );
    },
  );

  test(
    'a retried call with the same idempotencyKey returns the already-persisted transaction (FR-020, SC-006)',
    () async {
      when(
        () => repository.addTransaction(
          idempotencyKey: 'key-1',
          personId: 'p1',
          amount: const Money.egp(200000),
          direction: TransactionDirection.received,
          date: date,
          note: null,
        ),
      ).thenAnswer((_) async => Right<Failure, MoneyTransaction>(transaction));

      final first = await addTransaction(
        idempotencyKey: 'key-1',
        personId: 'p1',
        amount: const Money.egp(200000),
        direction: TransactionDirection.received,
        date: date,
      );
      final retried = await addTransaction(
        idempotencyKey: 'key-1',
        personId: 'p1',
        amount: const Money.egp(200000),
        direction: TransactionDirection.received,
        date: date,
      );

      expect(first, retried);
      verify(
        () => repository.addTransaction(
          idempotencyKey: 'key-1',
          personId: 'p1',
          amount: const Money.egp(200000),
          direction: TransactionDirection.received,
          date: date,
          note: null,
        ),
      ).called(2);
    },
  );
}
