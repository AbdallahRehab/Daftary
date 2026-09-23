import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../people/domain/usecases/find_possible_duplicate_person.dart';

/// Runs the same duplicate-name check the manual transaction form runs,
/// against a candidate entry's name (FR-009).
///
/// A thin wrapper rather than a second matching rule on purpose: "is this
/// the Ahmed I already have?" must get the same answer whether the name was
/// typed or read off a page, or the two entry paths would slowly grow
/// different ideas of who is a duplicate.
@injectable
class GetPossibleDuplicateForCandidate {
  const GetPossibleDuplicateForCandidate(this._people, this._findDuplicates);

  final PeopleRepository _people;
  final FindPossibleDuplicatePerson _findDuplicates;

  Future<Either<Failure, List<Person>>> call(String candidateName) async {
    if (candidateName.trim().isEmpty) return const Right([]);
    final result = await _people.searchActivePeople();
    return result.map((people) => _findDuplicates(candidateName, people));
  }
}
