import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/currency/domain/usecases/watch_primary_currency.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/watch_person.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_balance.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_history.dart';
import 'package:daftary/features/transactions/presentation/cubit/person_detail_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/person_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';
import '../../helpers/currency_test_doubles.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockPeopleRepository peopleRepository;
  late MockTransactionsRepository transactionsRepository;
  late FakeTableChanges changes;

  final now = DateTime(2026);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    peopleRepository = MockPeopleRepository();
    transactionsRepository = MockTransactionsRepository();
    changes = FakeTableChanges();
    stubPeopleWatches(peopleRepository, changes);
    stubTransactionsWatches(transactionsRepository, changes);
  });

  tearDown(() => changes.close());

  WatchPrimaryCurrency watchPrimary([Currency primary = Currency.egp]) {
    final repository = currencyRepositoryWith(primary: primary);
    stubCurrencyWatches(repository, changes);
    return WatchPrimaryCurrency(repository);
  }

  PersonDetailCubit buildCubit({Currency primary = Currency.egp}) =>
      PersonDetailCubit(
        WatchPerson(peopleRepository),
        WatchPersonBalance(transactionsRepository),
        WatchPersonHistory(transactionsRepository),
        DeleteTransaction(transactionsRepository),
        watchPrimary(primary),
        transactionsRepository,
      );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'resolves to theyOweYou for a positive net (FR-009)',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(150000))),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.subscribe('p1'),
    expect: () => [
      isA<PersonDetailState>().having(
        (s) => s.status,
        'status',
        PersonDetailStatus.loading,
      ),
      isA<PersonDetailState>()
          .having((s) => s.status, 'status', PersonDetailStatus.success)
          .having(
            (s) => s.balance?.status,
            'balance.status',
            RelationshipStatus.theyOweYou,
          ),
    ],
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'resolves to youOweThem for a negative net (FR-009)',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(-50000))),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.subscribe('p1'),
    expect: () => [
      isA<PersonDetailState>(),
      isA<PersonDetailState>().having(
        (s) => s.balance?.status,
        'balance.status',
        RelationshipStatus.youOweThem,
      ),
    ],
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'resolves to settled when net is exactly zero (FR-009)',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(0))),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.subscribe('p1'),
    expect: () => [
      isA<PersonDetailState>(),
      isA<PersonDetailState>().having(
        (s) => s.balance?.status,
        'balance.status',
        RelationshipStatus.settled,
      ),
    ],
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'loads balance and history together',
    build: buildCubit,
    setUp: () {
      final tx = MoneyTransaction(
        id: 't1',
        idempotencyKey: 'k1',
        personId: 'p1',
        amount: const Money.egp(200000),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: now,
        createdAt: now,
      );
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(200000))),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => Right([tx]));
    },
    act: (cubit) => cubit.subscribe('p1'),
    verify: (cubit) {
      expect(cubit.state.person, ahmed);
      expect(cubit.state.history, hasLength(1));
    },
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'surfaces a failure when the person cannot be loaded',
    build: buildCubit,
    setUp: () {
      when(() => peopleRepository.getPersonById('missing')).thenAnswer(
        (_) async => const Left(NotFoundFailure('Person not found')),
      );
      when(() => transactionsRepository.getPersonBalance('missing')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'missing', net: Money.egp(0))),
      );
      when(
        () => transactionsRepository.getPersonHistory('missing'),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.subscribe('missing'),
    expect: () => [
      isA<PersonDetailState>(),
      isA<PersonDetailState>().having(
        (s) => s.status,
        'status',
        PersonDetailStatus.failure,
      ),
    ],
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'deleteTransaction soft-deletes and the subscription recalculates the '
    'balance with no refresh (US6 Acceptance Scenario 2)',
    build: buildCubit,
    setUp: () {
      var net = const Money.egp(200000);
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(
        () => transactionsRepository.getPersonBalance('p1'),
      ).thenAnswer((_) async => Right(PersonBalance(personId: 'p1', net: net)));
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
      when(() => transactionsRepository.deleteTransaction('t1')).thenAnswer((
        _,
      ) async {
        // The soft delete writes the table; only the notification follows.
        net = const Money.egp(0);
        changes.notify();
        return const Right(unit);
      });
    },
    act: (cubit) async {
      await cubit.subscribe('p1');
      await cubit.deleteTransaction('t1');
    },
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      verify(() => transactionsRepository.deleteTransaction('t1')).called(1);
      expect(cubit.state.balance?.status, RelationshipStatus.settled);
    },
  );

  test(
    'adding, editing and deleting a transaction elsewhere updates history '
    'and balance with no refresh and no duplicate rows (004, 021 FR-031)',
    () async {
      MoneyTransaction tx(String id, int minorUnits) => MoneyTransaction(
        id: id,
        idempotencyKey: 'k$id',
        personId: 'p1',
        amount: Money.egp(minorUnits),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: now,
        createdAt: now,
      );
      var history = <MoneyTransaction>[];
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => Right(history));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => Right(
          PersonBalance(
            personId: 'p1',
            net: Money.egp(
              history.fold(0, (sum, t) => sum + t.amount.minorUnits),
            ),
          ),
        ),
      );
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await cubit.subscribe('p1');
      expect(cubit.state.history, isEmpty);

      history = [tx('t1', 100000)];
      changes.notify();
      await pumpEventQueue();
      expect(cubit.state.history.map((t) => t.id), ['t1']);
      expect(cubit.state.balance?.net, const Money.egp(100000));

      history = [tx('t1', 300000)];
      changes.notify();
      await pumpEventQueue();
      expect(cubit.state.history.map((t) => t.id), ['t1']);
      expect(cubit.state.balance?.net, const Money.egp(300000));

      history = [];
      changes.notify();
      await pumpEventQueue();
      expect(cubit.state.history, isEmpty);
      expect(cubit.state.balance?.status, RelationshipStatus.settled);
    },
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'a balance blocked on a missing rate is surfaced as-is with the primary '
    'currency (018 FR-009)',
    build: () => buildCubit(primary: Currency.usd),
    setUp: () {
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance.blocked(
            personId: 'p1',
            nativeNets: [
              Money.fromMinorUnits(500, Currency.usd),
              Money.fromMinorUnits(700, Currency.eur),
            ],
            missingRatesFor: [Currency.eur],
          ),
        ),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.subscribe('p1'),
    verify: (cubit) {
      final balance = cubit.state.balance!;
      expect(cubit.state.status, PersonDetailStatus.success);
      expect(cubit.state.primaryCurrency, Currency.usd);
      expect(balance.isBlocked, isTrue);
      expect(balance.missingRatesFor, [Currency.eur]);
      expect(balance.status, RelationshipStatus.theyOweYou);
    },
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'loads occasion-linked contributions with their occasion names '
    'populated (008 US2)',
    build: buildCubit,
    setUp: () {
      final ordinary = MoneyTransaction(
        id: 't1',
        idempotencyKey: 'k1',
        personId: 'p1',
        amount: const Money.egp(200000),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: now,
        createdAt: now,
      );
      final contribution = MoneyTransaction(
        id: 't2',
        idempotencyKey: 'k2',
        personId: 'p1',
        amount: const Money.egp(50000),
        direction: TransactionDirection.received,
        kind: TransactionKind.occasionContribution,
        date: now,
        createdAt: now,
        occasionId: 'o1',
        countsTowardBalance: false,
      );
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(200000))),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => Right([ordinary, contribution]));
      when(
        () => transactionsRepository.getOccasionNamesForPerson('p1'),
      ).thenAnswer((_) async => const Right({'o1': "Ahmed's wedding"}));
    },
    act: (cubit) => cubit.subscribe('p1'),
    verify: (cubit) {
      expect(cubit.state.history, hasLength(2));
      expect(cubit.state.occasionNames, {'o1': "Ahmed's wedding"});
    },
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'removing the last contribution for an occasion drops its name as soon '
    'as the tables change, exactly as an ordinary row disappears (008 US2)',
    build: buildCubit,
    setUp: () {
      final contribution = MoneyTransaction(
        id: 't1',
        idempotencyKey: 'k1',
        personId: 'p1',
        amount: const Money.egp(50000),
        direction: TransactionDirection.received,
        kind: TransactionKind.occasionContribution,
        date: now,
        createdAt: now,
        occasionId: 'o1',
      );
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(50000))),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => Right([contribution]));
      when(
        () => transactionsRepository.getOccasionNamesForPerson('p1'),
      ).thenAnswer((_) async => const Right({'o1': "Ahmed's wedding"}));
      when(
        () => transactionsRepository.deleteTransaction('t1'),
      ).thenAnswer((_) async => const Right(unit));
    },
    act: (cubit) async {
      await cubit.subscribe('p1');
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => transactionsRepository.getOccasionNamesForPerson('p1'),
      ).thenAnswer((_) async => const Right({}));
      await cubit.deleteTransaction('t1');
      // The real tables would signal the delete; the fake does it here.
      changes.notify();
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      expect(cubit.state.history, isEmpty);
      expect(cubit.state.occasionNames, isEmpty);
    },
  );
}
