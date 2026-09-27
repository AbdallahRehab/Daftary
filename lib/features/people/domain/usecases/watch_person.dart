import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/person.dart';
import '../repositories/people_repository.dart';

/// 021: one person, live — Person Detail's header follows an edit, archive
/// or restore made on any screen or applied by sync (FR-031).
@injectable
class WatchPerson {
  const WatchPerson(this._repository);

  final PeopleRepository _repository;

  Stream<Either<Failure, Person>> call(String personId) =>
      _repository.watchPersonById(personId);
}
