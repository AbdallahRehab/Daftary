import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/restore_person.dart';
import 'package:daftary/features/people/presentation/cubit/archived_people_cubit.dart';
import 'package:daftary/features/people/presentation/cubit/archived_people_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

void main() {
  late MockPeopleRepository repository;

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
  });

  ArchivedPeopleCubit buildCubit() =>
      ArchivedPeopleCubit(repository, RestorePerson(repository));

  blocTest<ArchivedPeopleCubit, ArchivedPeopleState>(
    'load() lists archived people',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.searchArchivedPeople(nameQuery: null),
      ).thenAnswer((_) async => Right([ahmed]));
    },
    act: (cubit) => cubit.load(),
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
    verify: (cubit) {
      expect(cubit.state.people, [ahmed]);
    },
  );

  blocTest<ArchivedPeopleCubit, ArchivedPeopleState>(
    'load() re-reads the current nameQuery rather than resetting it on a '
    'second call (005-archive-state-refresh research.md Decision 4)',
    build: buildCubit,
    seed: () => const ArchivedPeopleState(nameQuery: 'Ahm'),
    setUp: () {
      when(
        () => repository.searchArchivedPeople(nameQuery: 'Ahm'),
      ).thenAnswer((_) async => Right([ahmed]));
    },
    act: (cubit) => cubit.load(),
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
    'from this archived list on reload (FR-018)',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.searchArchivedPeople(nameQuery: null),
      ).thenAnswer((_) async => Right([ahmed]));
      when(
        () => repository.restorePerson('p1'),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    },
    act: (cubit) async {
      await cubit.load();
      when(
        () => repository.searchArchivedPeople(nameQuery: null),
      ).thenAnswer((_) async => const Right<Failure, List<Person>>([]));
      await cubit.restore('p1');
    },
    verify: (cubit) {
      verify(() => repository.restorePerson('p1')).called(1);
      expect(cubit.state.people, isEmpty);
    },
  );
}
