import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_balance.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_history.dart';
import 'package:daftary/features/transactions/presentation/cubit/person_detail_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/person_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockPeopleRepository peopleRepository;
  late MockTransactionsRepository transactionsRepository;

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
  });

  PersonDetailCubit buildCubit() => PersonDetailCubit(
    peopleRepository,
    GetPersonBalance(transactionsRepository),
    GetPersonHistory(transactionsRepository),
    DeleteTransaction(transactionsRepository),
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'resolves to theyOweYou for a positive net (FR-009)',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p1', net: Money.fromMinorUnits(150000)),
        ),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.load('p1'),
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
        (_) async => const Right(
          PersonBalance(personId: 'p1', net: Money.fromMinorUnits(-50000)),
        ),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.load('p1'),
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
        (_) async => const Right(
          PersonBalance(personId: 'p1', net: Money.fromMinorUnits(0)),
        ),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.load('p1'),
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
        amount: const Money.fromMinorUnits(200000),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: now,
        createdAt: now,
      );
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p1', net: Money.fromMinorUnits(200000)),
        ),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => Right([tx]));
    },
    act: (cubit) => cubit.load('p1'),
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
        (_) async => const Right(
          PersonBalance(personId: 'missing', net: Money.fromMinorUnits(0)),
        ),
      );
      when(
        () => transactionsRepository.getPersonHistory('missing'),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.load('missing'),
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
    'deleteTransaction soft-deletes then refreshes so the balance '
    'recalculates immediately (US6 Acceptance Scenario 2)',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p1', net: Money.fromMinorUnits(200000)),
        ),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => transactionsRepository.deleteTransaction('t1'),
      ).thenAnswer((_) async => const Right(unit));
    },
    act: (cubit) async {
      await cubit.load('p1');
      // The balance drops after the delete — refresh() must be re-run to
      // pick up the new value, not just report success.
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p1', net: Money.fromMinorUnits(0)),
        ),
      );
      await cubit.deleteTransaction('t1');
    },
    verify: (cubit) {
      verify(() => transactionsRepository.deleteTransaction('t1')).called(1);
      expect(cubit.state.balance?.status, RelationshipStatus.settled);
    },
  );

  blocTest<PersonDetailCubit, PersonDetailState>(
    'refresh() reflects the updated balance after an edit (US6 Acceptance '
    'Scenario 1) — the same mechanism the edit flow re-invokes on return',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p1', net: Money.fromMinorUnits(100000)),
        ),
      );
    },
    act: (cubit) async {
      await cubit.load('p1');
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p1', net: Money.fromMinorUnits(300000)),
        ),
      );
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state.balance?.net, const Money.fromMinorUnits(300000));
    },
  );
}
