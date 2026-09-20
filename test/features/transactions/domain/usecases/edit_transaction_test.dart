import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/edit_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repository;
  late EditTransaction editTransaction;

  setUp(() {
    repository = MockTransactionsRepository();
    editTransaction = EditTransaction(repository);
  });

  final createdAt = DateTime(2026, 1, 1);
  final editedDate = DateTime(2026, 1, 5);
  final edited = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'key-1',
    personId: 'p1',
    amount: const Money.fromMinorUnits(300000),
    direction: TransactionDirection.received,
    kind: TransactionKind.initialExchange,
    date: editedDate,
    note: 'corrected amount',
    createdAt: createdAt,
    editedAt: DateTime(2026, 1, 5, 9),
  );

  test('updates amount/direction/date/note, and the returned transaction '
      'carries a non-null editedAt (FR-015)', () async {
    when(
      () => repository.editTransaction(
        transactionId: 't1',
        amount: const Money.fromMinorUnits(300000),
        direction: TransactionDirection.received,
        date: editedDate,
        note: 'corrected amount',
      ),
    ).thenAnswer((_) async => Right<Failure, MoneyTransaction>(edited));

    final result = await editTransaction(
      transactionId: 't1',
      amount: const Money.fromMinorUnits(300000),
      direction: TransactionDirection.received,
      date: editedDate,
      note: 'corrected amount',
    );

    expect(result, Right<Failure, MoneyTransaction>(edited));
    final updated = result.getOrElse((_) => throw StateError('expected Right'));
    expect(updated.isEdited, isTrue);
    // kind/id/idempotencyKey/personId/createdAt are never accepted by
    // this use case's signature, so they cannot be reassigned by an edit
    // (data-model.md State transitions) — verified structurally: the
    // returned entity still carries the original identity fields.
    expect(updated.id, 't1');
    expect(updated.idempotencyKey, 'key-1');
    expect(updated.personId, 'p1');
    expect(updated.kind, TransactionKind.initialExchange);
    expect(updated.createdAt, createdAt);
  });

  test('propagates a ValidationFailure for a non-positive amount', () async {
    when(
      () => repository.editTransaction(
        transactionId: 't1',
        amount: const Money.fromMinorUnits(0),
        direction: TransactionDirection.given,
        date: editedDate,
        note: null,
      ),
    ).thenAnswer(
      (_) async => const Left<Failure, MoneyTransaction>(
        ValidationFailure('Amount must be greater than zero'),
      ),
    );

    final result = await editTransaction(
      transactionId: 't1',
      amount: const Money.fromMinorUnits(0),
      direction: TransactionDirection.given,
      date: editedDate,
    );

    expect(
      result,
      const Left<Failure, MoneyTransaction>(
        ValidationFailure('Amount must be greater than zero'),
      ),
    );
  });

  test(
    'propagates a NotFoundFailure for an unknown/deleted transaction',
    () async {
      when(
        () => repository.editTransaction(
          transactionId: 'missing',
          amount: const Money.fromMinorUnits(1000),
          direction: TransactionDirection.given,
          date: editedDate,
          note: null,
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, MoneyTransaction>(
          NotFoundFailure('Transaction not found'),
        ),
      );

      final result = await editTransaction(
        transactionId: 'missing',
        amount: const Money.fromMinorUnits(1000),
        direction: TransactionDirection.given,
        date: editedDate,
      );

      expect(
        result,
        const Left<Failure, MoneyTransaction>(
          NotFoundFailure('Transaction not found'),
        ),
      );
    },
  );
}
