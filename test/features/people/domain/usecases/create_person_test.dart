import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/people/domain/entities/people_failures.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

void main() {
  late MockPeopleRepository repository;
  late CreatePerson createPerson;

  setUp(() {
    repository = MockPeopleRepository();
    createPerson = CreatePerson(repository);
  });

  final now = DateTime(2026);
  final person = Person(
    id: '1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  test('delegates to the repository and returns the created person', () async {
    when(
      () => repository.createPerson(
        name: 'Ahmed',
        phoneNumber: null,
        avatarPath: null,
        relationshipTag: null,
        notes: null,
      ),
    ).thenAnswer((_) async => Right<Failure, Person>(person));

    final result = await createPerson(name: 'Ahmed');

    expect(result, Right<Failure, Person>(person));
  });

  test(
    'surfaces PossibleDuplicateFailure instead of inserting on a duplicate name',
    () async {
      final failure = PossibleDuplicateFailure([person]);
      when(
        () => repository.createPerson(
          name: 'Ahmed',
          phoneNumber: null,
          avatarPath: null,
          relationshipTag: null,
          notes: null,
        ),
      ).thenAnswer((_) async => Left<Failure, Person>(failure));

      final result = await createPerson(name: 'Ahmed');

      expect(result, Left<Failure, Person>(failure));
    },
  );

  test('surfaces a ValidationFailure for an empty-after-trim name', () async {
    when(
      () => repository.createPerson(
        name: '   ',
        phoneNumber: null,
        avatarPath: null,
        relationshipTag: null,
        notes: null,
      ),
    ).thenAnswer(
      (_) async =>
          const Left<Failure, Person>(ValidationFailure('Name is required')),
    );

    final result = await createPerson(name: '   ');

    expect(
      result,
      const Left<Failure, Person>(ValidationFailure('Name is required')),
    );
  });
}
