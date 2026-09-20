import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/people/data/datasources/people_dao.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/entities/people_failures.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  late AppDatabase db;
  late PeopleRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PeopleRepositoryImpl(
      PeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
    );
  });

  tearDown(() => db.close());

  group('createPerson', () {
    test('creates a person with just a name', () async {
      final result = await repository.createPerson(name: 'Ahmed');

      expect(result.isRight(), isTrue);
      final person = result.getOrElse(
        (_) => throw StateError('expected Right'),
      );
      expect(person.name, 'Ahmed');
      expect(person.isArchived, isFalse);
    });

    test('rejects an empty-after-trim name', () async {
      final result = await repository.createPerson(name: '   ');
      expect(
        result,
        const Left<Failure, Person>(ValidationFailure('Name is required')),
      );
    });

    test(
      'returns PossibleDuplicateFailure instead of inserting on a near-duplicate name',
      () async {
        await repository.createPerson(name: 'Ahmed Ali');

        final result = await repository.createPerson(name: 'Ahmed');

        expect(result.isLeft(), isTrue);
        result.match((failure) {
          expect(failure, isA<PossibleDuplicateFailure>());
          expect(
            (failure as PossibleDuplicateFailure).matches.first.name,
            'Ahmed Ali',
          );
        }, (_) => fail('expected a PossibleDuplicateFailure'));

        final all = await repository.searchActivePeople();
        expect(all.getOrElse((_) => []), hasLength(1));
      },
    );
  });

  group('confirmCreateDespiteDuplicate', () {
    test('bypasses the duplicate check and inserts anyway', () async {
      await repository.createPerson(name: 'Ahmed Ali');

      final result = await repository.confirmCreateDespiteDuplicate(
        name: 'Ahmed',
      );

      expect(result.isRight(), isTrue);
      final all = await repository.searchActivePeople();
      expect(all.getOrElse((_) => []), hasLength(2));
    });
  });

  group('searchActivePeople', () {
    test('excludes archived people', () async {
      final created = await repository.createPerson(name: 'Ahmed');
      final personId = created.getOrElse((_) => throw StateError('x')).id;
      await repository.archivePerson(personId);

      final result = await repository.searchActivePeople();

      expect(result.getOrElse((_) => []), isEmpty);
    });

    test('filters by a name query', () async {
      await repository.createPerson(name: 'Ahmed');
      await repository.confirmCreateDespiteDuplicate(name: 'Sara');

      final result = await repository.searchActivePeople(nameQuery: 'ahm');

      final names = result.getOrElse((_) => []).map((p) => p.name);
      expect(names, ['Ahmed']);
    });
  });

  group('getPersonById', () {
    test('returns NotFoundFailure for an unknown id', () async {
      final result = await repository.getPersonById('missing');
      expect(
        result,
        const Left<Failure, Person>(NotFoundFailure('Person not found')),
      );
    });
  });
}
