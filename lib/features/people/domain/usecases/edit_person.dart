import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/person.dart';
import '../repositories/people_repository.dart';

/// Updates a person's editable fields (FR-015-adjacent — profile edits, not
/// transaction edits). Does not affect archive state.
@injectable
class EditPerson {
  const EditPerson(this._repository);

  final PeopleRepository _repository;

  Future<Either<Failure, Person>> call({
    required String personId,
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) {
    return _repository.editPerson(
      personId: personId,
      name: name,
      phoneNumber: phoneNumber,
      avatarPath: avatarPath,
      relationshipTag: relationshipTag,
      notes: notes,
    );
  }
}
