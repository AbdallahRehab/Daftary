import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/edit_person.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

void main() {
  late MockPeopleRepository repository;
  late EditPerson editPerson;

  setUp(() {
    repository = MockPeopleRepository();
    editPerson = EditPerson(repository);
  });

  final createdAt = DateTime(2026);
  final updatedAt = DateTime(2026, 2);
  final edited = Person(
    id: 'p1',
    name: 'Ahmed Ali',
    phoneNumber: '01000000000',
    relationshipTag: 'friend',
    notes: 'Updated notes',
    isArchived: false,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  test(
    'updates name/phoneNumber/relationshipTag/notes and bumps updatedAt',
    () async {
      when(
        () => repository.editPerson(
          personId: 'p1',
          name: 'Ahmed Ali',
          phoneNumber: '01000000000',
          avatarPath: null,
          relationshipTag: 'friend',
          notes: 'Updated notes',
        ),
      ).thenAnswer((_) async => Right<Failure, Person>(edited));

      final result = await editPerson(
        personId: 'p1',
        name: 'Ahmed Ali',
        phoneNumber: '01000000000',
        relationshipTag: 'friend',
        notes: 'Updated notes',
      );

      expect(result, Right<Failure, Person>(edited));
      final updatedPerson = result.getOrElse(
        (_) => throw StateError('expected Right'),
      );
      expect(updatedPerson.updatedAt, updatedAt);
    },
  );

  test('propagates a ValidationFailure for an empty-after-trim name', () async {
    when(
      () => repository.editPerson(
        personId: 'p1',
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

    final result = await editPerson(personId: 'p1', name: '   ');

    expect(
      result,
      const Left<Failure, Person>(ValidationFailure('Name is required')),
    );
  });

  test('propagates a NotFoundFailure for an unknown personId', () async {
    when(
      () => repository.editPerson(
        personId: 'missing',
        name: 'Someone',
        phoneNumber: null,
        avatarPath: null,
        relationshipTag: null,
        notes: null,
      ),
    ).thenAnswer(
      (_) async =>
          const Left<Failure, Person>(NotFoundFailure('Person not found')),
    );

    final result = await editPerson(personId: 'missing', name: 'Someone');

    expect(
      result,
      const Left<Failure, Person>(NotFoundFailure('Person not found')),
    );
  });
}
