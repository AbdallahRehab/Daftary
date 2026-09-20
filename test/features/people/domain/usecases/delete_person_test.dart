import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/people/domain/entities/people_failures.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/delete_person.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

void main() {
  late MockPeopleRepository repository;
  late DeletePerson deletePerson;

  setUp(() {
    repository = MockPeopleRepository();
    deletePerson = DeletePerson(repository);
  });

  test('blocked with PersonHasTransactionsFailure when the person has any '
      'transaction, including soft-deleted ones', () async {
    when(() => repository.deletePerson('p1')).thenAnswer(
      (_) async => const Left<Failure, Unit>(PersonHasTransactionsFailure()),
    );

    final result = await deletePerson('p1');

    expect(result, const Left<Failure, Unit>(PersonHasTransactionsFailure()));
  });

  test('succeeds when the person has zero transactions (FR-017)', () async {
    when(
      () => repository.deletePerson('p1'),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final result = await deletePerson('p1');

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('propagates NotFoundFailure for an unknown personId', () async {
    when(() => repository.deletePerson('missing')).thenAnswer(
      (_) async =>
          const Left<Failure, Unit>(NotFoundFailure('Person not found')),
    );

    final result = await deletePerson('missing');

    expect(
      result,
      const Left<Failure, Unit>(NotFoundFailure('Person not found')),
    );
  });
}
