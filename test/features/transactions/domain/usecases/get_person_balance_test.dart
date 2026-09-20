import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repository;
  late GetPersonBalance getPersonBalance;

  setUp(() {
    repository = MockTransactionsRepository();
    getPersonBalance = GetPersonBalance(repository);
  });

  test('delegates to the repository', () async {
    const balance = PersonBalance(
      personId: 'p1',
      net: Money.fromMinorUnits(150000),
    );
    when(
      () => repository.getPersonBalance('p1'),
    ).thenAnswer((_) async => const Right<Failure, PersonBalance>(balance));

    final result = await getPersonBalance('p1');

    expect(result, const Right<Failure, PersonBalance>(balance));
  });

  group('PersonBalance.status (FR-008, FR-009)', () {
    test('a positive net (given > received) means they owe you', () {
      const balance = PersonBalance(
        personId: 'p1',
        net: Money.fromMinorUnits(150000),
      );
      expect(balance.status, RelationshipStatus.theyOweYou);
    });

    test('a negative net (received > given) means you owe them', () {
      const balance = PersonBalance(
        personId: 'p1',
        net: Money.fromMinorUnits(-50000),
      );
      expect(balance.status, RelationshipStatus.youOweThem);
    });

    test('a zero net means settled', () {
      final balance = PersonBalance(personId: 'p1', net: Money.zero());
      expect(balance.status, RelationshipStatus.settled);
    });
  });
}
