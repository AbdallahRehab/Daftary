import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/usecases/get_possible_duplicate_for_candidate.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

void main() {
  late MockPeopleRepository people;
  late GetPossibleDuplicateForCandidate getPossibleDuplicateForCandidate;

  Person buildPerson(String id, String name) {
    return Person(
      id: id,
      name: name,
      isArchived: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  void stubPeople(Either<Failure, List<Person>> response) {
    when(() => people.searchActivePeople()).thenAnswer((_) async => response);
  }

  setUp(() {
    people = MockPeopleRepository();
    // The real matcher, not a mock: the point of this use case is that a
    // scanned name gets the same answer manual entry would give it.
    getPossibleDuplicateForCandidate = GetPossibleDuplicateForCandidate(
      people,
      const FindPossibleDuplicatePerson(),
    );
  });

  group('GetPossibleDuplicateForCandidate', () {
    test('an empty name short-circuits to an empty Right without reading the '
        'people repository at all', () async {
      final result = await getPossibleDuplicateForCandidate('');

      expect(result.getRight().toNullable(), isEmpty);
      verifyNever(() => people.searchActivePeople());
      verifyNoMoreInteractions(people);
    });

    test('a whitespace-only name short-circuits too: a blank field is not a '
        'question worth asking the database', () async {
      final result = await getPossibleDuplicateForCandidate('   ');

      expect(result.getRight().toNullable(), isEmpty);
      verifyNever(() => people.searchActivePeople());
    });

    test('runs the duplicate check over the active people the repository '
        'returns, producing the same bidirectional match manual entry '
        'produces (FR-009)', () async {
      stubPeople(
        Right([
          buildPerson('p1', 'Ahmed Ali'),
          buildPerson('p2', 'Mona Saeed'),
          buildPerson('p3', 'ahmed'),
        ]),
      );

      final result = await getPossibleDuplicateForCandidate('Ahmed');

      final matches = result.getRight().toNullable();
      // "Ahmed" is contained in "Ahmed Ali" and contains "ahmed" — both
      // directions match, exactly as they do when the name is typed.
      expect(matches?.map((p) => p.id), ['p1', 'p3']);
      verify(() => people.searchActivePeople()).called(1);
    });

    test('matching ignores case and surrounding whitespace, so a sloppily '
        'recognized name still finds its person (FR-009)', () async {
      stubPeople(Right([buildPerson('p1', 'Ahmed  Ali')]));

      final result = await getPossibleDuplicateForCandidate('  ahmed ali  ');

      expect(result.getRight().toNullable()?.single.id, 'p1');
    });

    test('returns an empty list, not a failure, when nobody resembles the '
        'candidate — "no duplicate" is a normal answer', () async {
      stubPeople(Right([buildPerson('p1', 'Mona Saeed')]));

      final result = await getPossibleDuplicateForCandidate('Ahmed');

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), isEmpty);
    });

    test('propagates a people-repository failure unchanged rather than '
        'pretending there are no duplicates', () async {
      const failure = CacheFailure('People table unreadable');
      stubPeople(const Left(failure));

      final result = await getPossibleDuplicateForCandidate('Ahmed');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), same(failure));
    });
  });
}
