import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/restore_person.dart';
import 'package:daftary/features/people/domain/usecases/watch_archived_people.dart';
import 'package:daftary/features/people/presentation/cubit/archived_people_cubit.dart';
import 'package:daftary/features/people/presentation/cubit/archived_people_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

void main() {
  late MockPeopleRepository repository;
  late FakeTableChanges changes;

  final now = DateTime(2026);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: true,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    repository = MockPeopleRepository();
    changes = FakeTableChanges();
    stubPeopleWatches(repository, changes);
  });

  tearDown(() => changes.close());

  ArchivedPeopleCubit buildCubit() => ArchivedPeopleCubit(
    WatchArchivedPeople(repository),
    RestorePerson(repository),
  );

  blocTest<ArchivedPeopleCubit, ArchivedPeopleState>(
    'subscribe() lists archived people',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.searchArchivedPeople(nameQuery: null),
      ).thenAnswer((_) async => Right([ahmed]));
    },
    act: (cubit) => cubit.subscribe(),
    expect: () => [
      isA<ArchivedPeopleState>(),
      isA<ArchivedPeopleState>()
          .having((s) => s.status, 'status', ArchivedPeopleStatus.success)
          .having((s) => s.people, 'people', [ahmed]),
    ],
  );

  blocTest<ArchivedPeopleCubit, ArchivedPeopleState>(
    'nameQueryChanged searches archived people by name',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.searchArchivedPeople(nameQuery: 'Ahm'),
      ).thenAnswer((_) async => Right([ahmed]));
    },
    act: (cubit) => cubit.nameQueryChanged('Ahm'),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      expect(cubit.state.people, [ahmed]);
    },
  );

  blocTest<ArchivedPeopleCubit, ArchivedPeopleState>(
    'subscribe() re-reads the current nameQuery rather than resetting it '
    '(005-archive-state-refresh research.md Decision 4)',
    build: buildCubit,
    seed: () => const ArchivedPeopleState(nameQuery: 'Ahm'),
    setUp: () {
      when(
        () => repository.searchArchivedPeople(nameQuery: 'Ahm'),
      ).thenAnswer((_) async => Right([ahmed]));
    },
    act: (cubit) => cubit.subscribe(),
    verify: (cubit) {
      verify(() => repository.searchArchivedPeople(nameQuery: 'Ahm')).called(1);
      expect(cubit.state.nameQuery, 'Ahm');
      expect(cubit.state.people, [ahmed]);
    },
  );

  blocTest<ArchivedPeopleCubit, ArchivedPeopleState>(
    'restore(id) is a no-op re-entrancy guard while already processing the '
    'same id (FR-006)',
    build: buildCubit,
    seed: () => const ArchivedPeopleState(
      status: ArchivedPeopleStatus.success,
      processingPersonId: 'p1',
    ),
    act: (cubit) => cubit.restore('p1'),
    verify: (_) {
      verifyNever(() => repository.restorePerson(any()));
    },
  );

  blocTest<ArchivedPeopleCubit, ArchivedPeopleState>(
    'a failed restore() leaves the person in the archived list, sets an '
    'error message, and clears processingPersonId so the control is '
    'tappable again (FR-007)',
    build: buildCubit,
    seed: () => ArchivedPeopleState(
      status: ArchivedPeopleStatus.success,
      people: [ahmed],
    ),
    setUp: () {
      when(
        () => repository.restorePerson('p1'),
      ).thenAnswer((_) async => const Left(CacheFailure('DB unavailable')));
    },
    act: (cubit) => cubit.restore('p1'),
    expect: () => [
      isA<ArchivedPeopleState>().having(
        (s) => s.processingPersonId,
        'processingPersonId',
        'p1',
      ),
      isA<ArchivedPeopleState>()
          .having(
            (s) => s.failure,
            'failure',
            const CacheFailure('DB unavailable'),
          )
          .having((s) => s.processingPersonId, 'processingPersonId', isNull)
          .having((s) => s.people, 'people', [ahmed]),
    ],
    verify: (_) {
      verifyNever(
        () =>
            repository.searchArchivedPeople(nameQuery: any(named: 'nameQuery')),
      );
    },
  );

  blocTest<ArchivedPeopleCubit, ArchivedPeopleState>(
    'restoring a person moves it back into the active list, dropping it '
    'from this archived list with no reload (FR-018)',
    build: buildCubit,
    setUp: () {
      var archived = [ahmed];
      when(
        () => repository.searchArchivedPeople(nameQuery: null),
      ).thenAnswer((_) async => Right(archived));
      when(() => repository.restorePerson('p1')).thenAnswer((_) async {
        archived = [];
        changes.notify();
        return const Right<Failure, Unit>(unit);
      });
    },
    act: (cubit) async {
      await cubit.subscribe();
      await cubit.restore('p1');
    },
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      verify(() => repository.restorePerson('p1')).called(1);
      expect(cubit.state.people, isEmpty);
      expect(cubit.state.processingPersonId, isNull);
    },
  );

  test('an archive made elsewhere reaches a subscribed archived list '
      '(005 archive refresh, 021 FR-031)', () async {
    var archived = <Person>[];
    when(
      () => repository.searchArchivedPeople(nameQuery: null),
    ).thenAnswer((_) async => Right(archived));
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.subscribe();
    expect(cubit.state.people, isEmpty);

    archived = [ahmed];
    changes.notify();
    await pumpEventQueue();

    expect(cubit.state.people, [ahmed]);
  });
}
