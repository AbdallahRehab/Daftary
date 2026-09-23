import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repository;
  late GetPersonHistory getPersonHistory;

  setUp(() {
    repository = MockTransactionsRepository();
    getPersonHistory = GetPersonHistory(repository);
  });

  test(
    'delegates to the repository and returns non-deleted rows, chronological, with edited/kind/direction metadata (FR-010)',
    () async {
      final older = MoneyTransaction(
        id: 't1',
        idempotencyKey: 'k1',
        personId: 'p1',
        amount: const Money.fromMinorUnits(200000),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      final newer = MoneyTransaction(
        id: 't2',
        idempotencyKey: 'k2',
        personId: 'p1',
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.received,
        kind: TransactionKind.repayment,
        date: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 2),
        editedAt: DateTime(2026, 1, 3),
      );
      when(
        () => repository.getPersonHistory('p1'),
      ).thenAnswer((_) async => Right([older, newer]));

      final result = await getPersonHistory('p1');

      final history = result.getOrElse((_) => throw StateError('x'));
      expect(history, [older, newer]);
      expect(history.last.isEdited, isTrue);
      expect(history.every((t) => !t.isDeleted), isTrue);
    },
  );

  test(
    'occasionContribution rows come back interleaved chronologically with '
    'ordinary ones (008 US2) — the history query is not kind-scoped',
    () async {
      final ordinary = MoneyTransaction(
        id: 't1',
        idempotencyKey: 'k1',
        personId: 'p1',
        amount: const Money.fromMinorUnits(200000),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      final contribution = MoneyTransaction(
        id: 't2',
        idempotencyKey: 'k2',
        personId: 'p1',
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.received,
        kind: TransactionKind.occasionContribution,
        date: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 2),
        occasionId: 'o1',
        countsTowardBalance: false,
      );
      final laterOrdinary = MoneyTransaction(
        id: 't3',
        idempotencyKey: 'k3',
        personId: 'p1',
        amount: const Money.fromMinorUnits(10000),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: DateTime(2026, 1, 3),
        createdAt: DateTime(2026, 1, 3),
      );
      when(
        () => repository.getPersonHistory('p1'),
      ).thenAnswer((_) async => Right([ordinary, contribution, laterOrdinary]));

      final result = await getPersonHistory('p1');

      final history = result.getOrElse((_) => throw StateError('x'));
      expect(history, [ordinary, contribution, laterOrdinary]);
      expect(history[1].isOccasionContribution, isTrue);
      expect(history[1].occasionId, 'o1');
      expect(history.map((t) => t.date).toList(), [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
      ]);
    },
  );
}
