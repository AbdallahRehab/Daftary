import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/person.dart';
import '../repositories/people_repository.dart';

/// Creates a person, surfacing a [PossibleDuplicateFailure] instead of
/// inserting when the name looks like an existing person's (FR-001, FR-003).
@injectable
class CreatePerson {
  const CreatePerson(this._repository);

  final PeopleRepository _repository;

  Future<Either<Failure, Person>> call({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) {
    return _repository.createPerson(
      name: name,
      phoneNumber: phoneNumber,
      avatarPath: avatarPath,
      relationshipTag: relationshipTag,
      notes: notes,
    );
  }
}
