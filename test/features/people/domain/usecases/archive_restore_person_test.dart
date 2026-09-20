import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/archive_person.dart';
import 'package:daftary/features/people/domain/usecases/restore_person.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

void main() {
  late MockPeopleRepository repository;
  late ArchivePerson archivePerson;
  late RestorePerson restorePerson;

  setUp(() {
    repository = MockPeopleRepository();
    archivePerson = ArchivePerson(repository);
    restorePerson = RestorePerson(repository);
  });

  test(
    'archiving succeeds regardless of outstanding balance or transaction count',
    () async {
      when(
        () => repository.archivePerson('p1'),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

      final result = await archivePerson('p1');

      expect(result, const Right<Failure, Unit>(unit));
    },
  );

  test('archiving an unknown person propagates NotFoundFailure', () async {
    when(() => repository.archivePerson('missing')).thenAnswer(
      (_) async =>
          const Left<Failure, Unit>(NotFoundFailure('Person not found')),
    );

    final result = await archivePerson('missing');

    expect(
      result,
      const Left<Failure, Unit>(NotFoundFailure('Person not found')),
    );
  });

  test(
    'restoring an archived person moves it back to the active list',
    () async {
      when(
        () => repository.restorePerson('p1'),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

      final result = await restorePerson('p1');

      expect(result, const Right<Failure, Unit>(unit));
    },
  );

  test('restoring an unknown person propagates NotFoundFailure', () async {
    when(() => repository.restorePerson('missing')).thenAnswer(
      (_) async =>
          const Left<Failure, Unit>(NotFoundFailure('Person not found')),
    );

    final result = await restorePerson('missing');

    expect(
      result,
      const Left<Failure, Unit>(NotFoundFailure('Person not found')),
    );
  });
}
