import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_balance.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/test_daos.dart';

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
    const balance = PersonBalance(personId: 'p1', net: Money.egp(150000));
    when(
      () => repository.getPersonBalance('p1'),
    ).thenAnswer((_) async => const Right<Failure, PersonBalance>(balance));

    final result = await getPersonBalance('p1');

    expect(result, const Right<Failure, PersonBalance>(balance));
  });

  group('PersonBalance.status (FR-008, FR-009)', () {
    test('a positive net (given > received) means they owe you', () {
      const balance = PersonBalance(personId: 'p1', net: Money.egp(150000));
      expect(balance.status, RelationshipStatus.theyOweYou);
    });

    test('a negative net (received > given) means you owe them', () {
      const balance = PersonBalance(personId: 'p1', net: Money.egp(-50000));
      expect(balance.status, RelationshipStatus.youOweThem);
    });

    test('a zero net means settled', () {
      final balance = PersonBalance(
        personId: 'p1',
        net: Money.zero(Currency.egp),
      );
      expect(balance.status, RelationshipStatus.settled);
    });
  });

  /// The predicate added by 008 is SQL, so these run against a real database
  /// rather than a mocked repository — a mock could not fail the way a wrong
  /// `WHERE` clause would.
  group('occasionContribution rows in the SUM (008 FR-018, FR-023)', () {
    late AppDatabase db;
    late TransactionsRepositoryImpl repository;

    Future<void> createOccasion(String id) {
      return db
          .into(db.occasions)
          .insert(
            OccasionsCompanion.insert(
              id: id,
              idempotencyKey: 'occ-$id',
              name: 'Occasion $id',
              date: DateTime(2026, 1, 1).millisecondsSinceEpoch,
              type: 'condolence',
              createdAt: DateTime(2026).millisecondsSinceEpoch,
              updatedAt: DateTime(2026).millisecondsSinceEpoch,
            ),
          );
    }

    Future<void> contribute({
      required String key,
      required int minorUnits,
      required bool countsTowardBalance,
    }) async {
      await repository.addOccasionContribution(
        idempotencyKey: key,
        personId: 'p1',
        occasionId: 'o1',
        amount: Money.egp(minorUnits),
        direction: TransactionDirection.given,
        countsTowardBalance: countsTowardBalance,
        date: DateTime(2026, 1, 2),
      );
    }

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = TransactionsRepositoryImpl(testTransactionsDao(db), db);
      await testPeopleDao(
        db,
      ).insertPerson(id: 'p1', name: 'Ahmed', createdAt: DateTime(2026));
      await createOccasion('o1');
    });

    tearDown(() => db.close());

    Future<Money> netOf(String personId) async {
      final result = await repository.getPersonBalance(personId);
      return result.getOrElse((_) => throw StateError('x')).net!;
    }

    test('a non-counting contribution is excluded from the balance', () async {
      await contribute(
        key: 'c1',
        minorUnits: 100000,
        countsTowardBalance: false,
      );

      expect(await netOf('p1'), Money.zero(Currency.egp));
    });

    test('a counting contribution is included in the balance', () async {
      await contribute(
        key: 'c1',
        minorUnits: 100000,
        countsTowardBalance: true,
      );

      expect(await netOf('p1'), const Money.egp(100000));
    });

    test('ordinary and repayment rows are unaffected by the new predicate '
        '(FR-023)', () async {
      await repository.addTransaction(
        idempotencyKey: 'k1',
        personId: 'p1',
        amount: const Money.egp(200000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );
      await repository.recordRepayment(
        idempotencyKey: 'k2',
        personId: 'p1',
        amount: const Money.egp(50000),
        date: DateTime(2026, 1, 3),
      );
      await contribute(
        key: 'c1',
        minorUnits: 999999,
        countsTowardBalance: false,
      );

      expect(await netOf('p1'), const Money.egp(150000));
    });

    test('the overview aggregate applies the same predicate as the '
        'per-person one', () async {
      await contribute(
        key: 'c1',
        minorUnits: 100000,
        countsTowardBalance: false,
      );
      await repository.addTransaction(
        idempotencyKey: 'k1',
        personId: 'p1',
        amount: const Money.egp(70000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );

      final overview = await repository.getOverview();

      expect(
        overview.getOrElse((_) => throw StateError('x')).totalOwedToUser,
        const Money.egp(70000),
      );
    });
  });
}
