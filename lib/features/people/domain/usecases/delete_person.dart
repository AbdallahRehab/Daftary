import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/people_repository.dart';

/// Permanently deletes a person. Blocked with `PersonHasTransactionsFailure`
/// when the person has any transaction, including soft-deleted ones
/// (FR-017) — the caller should offer archiving instead.
@injectable
class DeletePerson {
  const DeletePerson(this._repository);

  final PeopleRepository _repository;

  Future<Either<Failure, Unit>> call(String personId) =>
      _repository.deletePerson(personId);
}
