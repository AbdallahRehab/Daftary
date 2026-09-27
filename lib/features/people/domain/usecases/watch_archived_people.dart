import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/person.dart';
import '../repositories/people_repository.dart';

/// 021: the live archived-people list (FR-018, FR-031) — a restore or a
/// synced change updates it with no reload.
@injectable
class WatchArchivedPeople {
  const WatchArchivedPeople(this._repository);

  final PeopleRepository _repository;

  Stream<Either<Failure, List<Person>>> call({String? nameQuery}) =>
      _repository.watchArchivedPeople(nameQuery: nameQuery);
}
