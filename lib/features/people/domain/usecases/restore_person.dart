import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/people_repository.dart';

/// Restores an archived person back to the active list (FR-018).
@injectable
class RestorePerson {
  const RestorePerson(this._repository);

  final PeopleRepository _repository;

  Future<Either<Failure, Unit>> call(String personId) =>
      _repository.restorePerson(personId);
}
