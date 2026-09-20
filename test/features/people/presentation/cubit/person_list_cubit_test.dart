import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/archive_person.dart';
import 'package:daftary/features/people/presentation/cubit/person_list_cubit.dart';
import 'package:daftary/features/people/presentation/cubit/person_list_state.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_balance.dart';
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
  final sara = Person(
    id: 'p2',
    name: 'Sara',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    peopleRepository = MockPeopleRepository();
    transactionsRepository = MockTransactionsRepository();
  });

  PersonListCubit buildCubit() => PersonListCubit(
    peopleRepository,
    GetPersonBalance(transactionsRepository),
    ArchivePerson(peopleRepository),
  );

  blocTest<PersonListCubit, PersonListState>(
    'load() lists active people with their balances',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: null,
          statusFilter: null,
        ),
      ).thenAnswer((_) async => Right([ahmed, sara]));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p1', net: Money.fromMinorUnits(150000)),
        ),
      );
      when(() => transactionsRepository.getPersonBalance('p2')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p2', net: Money.fromMinorUnits(-50000)),
        ),
      );
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, PersonListStatus.success);
      expect(cubit.state.items, hasLength(2));
      expect(
        cubit.state.items.map((i) => i.person.id),
        containsAll(['p1', 'p2']),
      );
    },
  );

  blocTest<PersonListCubit, PersonListState>(
    'nameQueryChanged filters active people by name (FR-019)',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: 'Sara',
          statusFilter: null,
        ),
      ).thenAnswer((_) async => Right([sara]));
      when(() => transactionsRepository.getPersonBalance('p2')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p2', net: Money.fromMinorUnits(-50000)),
        ),
      );
    },
    act: (cubit) => cubit.nameQueryChanged('Sara'),
    verify: (cubit) {
      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.items.single.person.name, 'Sara');
    },
  );

  blocTest<PersonListCubit, PersonListState>(
    'statusFilterChanged filters active people by RelationshipStatus (FR-019)',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: null,
          statusFilter: RelationshipStatus.youOweThem,
        ),
      ).thenAnswer((_) async => Right([sara]));
      when(() => transactionsRepository.getPersonBalance('p2')).thenAnswer(
        (_) async => const Right(
          PersonBalance(personId: 'p2', net: Money.fromMinorUnits(-50000)),
        ),
      );
    },
    act: (cubit) => cubit.statusFilterChanged(RelationshipStatus.youOweThem),
    verify: (cubit) {
      expect(cubit.state.statusFilter, RelationshipStatus.youOweThem);
      expect(cubit.state.items.single.person.id, 'p2');
    },
  );

  blocTest<PersonListCubit, PersonListState>(
    'surfaces a failure when the repository call fails',
    build: buildCubit,
    setUp: () {
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: null,
          statusFilter: null,
        ),
      ).thenAnswer(
        (_) async =>
            const Left<Failure, List<Person>>(CacheFailure('DB unavailable')),
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PersonListState>(),
      isA<PersonListState>().having(
        (s) => s.status,
        'status',
        PersonListStatus.failure,
      ),
    ],
  );
}
