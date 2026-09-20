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
