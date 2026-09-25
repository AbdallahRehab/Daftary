import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/archive_person.dart';
import 'package:daftary/features/people/domain/usecases/restore_person.dart';
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
    RestorePerson(peopleRepository),
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
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(150000))),
      );
      when(() => transactionsRepository.getPersonBalance('p2')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p2', net: Money.egp(-50000))),
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
        (_) async =>
            const Right(PersonBalance(personId: 'p2', net: Money.egp(-50000))),
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
        (_) async =>
            const Right(PersonBalance(personId: 'p2', net: Money.egp(-50000))),
      );
    },
    act: (cubit) => cubit.statusFilterChanged(RelationshipStatus.youOweThem),
    verify: (cubit) {
      expect(cubit.state.statusFilter, RelationshipStatus.youOweThem);
      expect(cubit.state.items.single.person.id, 'p2');
    },
  );

  blocTest<PersonListCubit, PersonListState>(
    'load() re-reads the current nameQuery/statusFilter rather than '
    'resetting them on a second call (005-archive-state-refresh research.md '
    'Decision 4)',
    build: buildCubit,
    seed: () => const PersonListState(
      nameQuery: 'Sara',
      statusFilter: RelationshipStatus.youOweThem,
    ),
    setUp: () {
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: 'Sara',
          statusFilter: RelationshipStatus.youOweThem,
        ),
      ).thenAnswer((_) async => Right([sara]));
      when(() => transactionsRepository.getPersonBalance('p2')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p2', net: Money.egp(-50000))),
      );
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      verify(
        () => peopleRepository.searchActivePeople(
          nameQuery: 'Sara',
          statusFilter: RelationshipStatus.youOweThem,
        ),
      ).called(1);
      expect(cubit.state.nameQuery, 'Sara');
      expect(cubit.state.statusFilter, RelationshipStatus.youOweThem);
      expect(cubit.state.items.single.person.id, 'p2');
    },
  );

  blocTest<PersonListCubit, PersonListState>(
    'archive(id) is a no-op re-entrancy guard while already processing the '
    'same id (FR-006)',
    build: buildCubit,
    seed: () => const PersonListState(
      status: PersonListStatus.success,
      processingPersonId: 'p1',
    ),
    act: (cubit) => cubit.archive('p1'),
    verify: (_) {
      verifyNever(() => peopleRepository.archivePerson(any()));
    },
  );

  blocTest<PersonListCubit, PersonListState>(
    'archive(id) sets processingPersonId while in flight, reloads on '
    'success, and clears it once the reload has emitted',
    build: buildCubit,
    seed: () =>
        const PersonListState(status: PersonListStatus.success, items: []),
    setUp: () {
      when(
        () => peopleRepository.archivePerson('p1'),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: null,
          statusFilter: null,
        ),
      ).thenAnswer((_) async => Right([sara]));
      when(() => transactionsRepository.getPersonBalance('p2')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p2', net: Money.egp(-50000))),
      );
    },
    act: (cubit) => cubit.archive('p1'),
    expect: () => [
      isA<PersonListState>().having(
        (s) => s.processingPersonId,
        'processingPersonId',
        'p1',
      ),
      isA<PersonListState>().having(
        (s) => s.status,
        'status',
        PersonListStatus.loading,
      ),
      isA<PersonListState>()
          .having((s) => s.status, 'status', PersonListStatus.success)
          .having((s) => s.processingPersonId, 'processingPersonId', 'p1'),
      isA<PersonListState>().having(
        (s) => s.processingPersonId,
        'processingPersonId',
        isNull,
      ),
    ],
  );

  blocTest<PersonListCubit, PersonListState>(
    'a failed archive() leaves the person in the list, sets an error '
    'message, and clears processingPersonId so the control is tappable '
    'again (FR-007)',
    build: buildCubit,
    seed: () => const PersonListState(status: PersonListStatus.success),
    setUp: () {
      when(
        () => peopleRepository.archivePerson('p1'),
      ).thenAnswer((_) async => const Left(CacheFailure('DB unavailable')));
    },
    act: (cubit) => cubit.archive('p1'),
    expect: () => [
      isA<PersonListState>().having(
        (s) => s.processingPersonId,
        'processingPersonId',
        'p1',
      ),
      isA<PersonListState>()
          .having(
            (s) => s.failure,
            'failure',
            const CacheFailure('DB unavailable'),
          )
          .having((s) => s.processingPersonId, 'processingPersonId', isNull),
    ],
    verify: (_) {
      verifyNever(
        () => peopleRepository.searchActivePeople(
          nameQuery: any(named: 'nameQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      );
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

  blocTest<PersonListCubit, PersonListState>(
    'lists a person whose balance is blocked on a missing rate, with an '
    'unknown status, without failing (018 FR-009)',
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
          PersonBalance.blocked(
            personId: 'p1',
            nativeNets: [
              Money.egp(1000),
              Money.fromMinorUnits(-500, Currency.usd),
            ],
            missingRatesFor: [Currency.usd],
          ),
        ),
      );
      when(() => transactionsRepository.getPersonBalance('p2')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p2', net: Money.egp(-50000))),
      );
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, PersonListStatus.success);
      final blocked = cubit.state.items.firstWhere((i) => i.person.id == 'p1');
      expect(blocked.balance.isBlocked, isTrue);
      expect(blocked.balance.status, isNull);
      expect(blocked.balance.missingRatesFor, [Currency.usd]);
    },
  );

  blocTest<PersonListCubit, PersonListState>(
    'a successful archive() reports the archived person once, so the page '
    'can offer Undo',
    build: buildCubit,
    seed: () => PersonListState(
      status: PersonListStatus.success,
      items: [
        PersonListItem(
          person: ahmed,
          balance: const PersonBalance(personId: 'p1', net: Money.egp(0)),
        ),
      ],
    ),
    setUp: () {
      when(
        () => peopleRepository.archivePerson('p1'),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: null,
          statusFilter: null,
        ),
      ).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.archive('p1'),
    verify: (cubit) => expect(cubit.state.lastArchived, ahmed),
  );

  blocTest<PersonListCubit, PersonListState>(
    'undoArchive(id) restores the person and reloads the list',
    build: buildCubit,
    seed: () =>
        const PersonListState(status: PersonListStatus.success, items: []),
    setUp: () {
      when(
        () => peopleRepository.restorePerson('p1'),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: null,
          statusFilter: null,
        ),
      ).thenAnswer((_) async => Right([ahmed]));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(0))),
      );
    },
    act: (cubit) => cubit.undoArchive('p1'),
    verify: (cubit) {
      verify(() => peopleRepository.restorePerson('p1')).called(1);
      expect(cubit.state.items.map((i) => i.person), [ahmed]);
      expect(cubit.state.lastArchived, isNull);
    },
  );
}
