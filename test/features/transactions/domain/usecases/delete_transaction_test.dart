import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repository;
  late DeleteTransaction deleteTransaction;

  setUp(() {
    repository = MockTransactionsRepository();
    deleteTransaction = DeleteTransaction(repository);
  });

  test('soft-deletes the transaction, excluding it from subsequent balance/'
      'history/overview reads (FR-016)', () async {
    when(
      () => repository.deleteTransaction('t1'),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final result = await deleteTransaction('t1');

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.deleteTransaction('t1')).called(1);
  });

  test(
    'propagates a NotFoundFailure for an unknown/already-deleted transaction',
    () async {
      when(() => repository.deleteTransaction('missing')).thenAnswer(
        (_) async =>
            const Left<Failure, Unit>(NotFoundFailure('Transaction not found')),
      );

      final result = await deleteTransaction('missing');

      expect(
        result,
        const Left<Failure, Unit>(NotFoundFailure('Transaction not found')),
      );
    },
  );
}
