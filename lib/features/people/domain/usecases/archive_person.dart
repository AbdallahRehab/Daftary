import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/people_repository.dart';

/// Archives a person (FR-017/FR-018). Always succeeds regardless of
/// outstanding balance or transaction count.
@injectable
class ArchivePerson {
  const ArchivePerson(this._repository);

  final PeopleRepository _repository;

  Future<Either<Failure, Unit>> call(String personId) =>
      _repository.archivePerson(personId);
}
