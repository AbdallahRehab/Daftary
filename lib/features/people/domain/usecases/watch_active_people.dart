import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/person_balance.dart';
import '../entities/person.dart';
import '../repositories/people_repository.dart';

/// 021: the live active-people list (FR-019, FR-031) — re-emits after any
/// local or synced change instead of needing a reload.
@injectable
class WatchActivePeople {
  const WatchActivePeople(this._repository);

  final PeopleRepository _repository;

  Stream<Either<Failure, List<Person>>> call({
    String? nameQuery,
    RelationshipStatus? statusFilter,
  }) => _repository.watchActivePeople(
    nameQuery: nameQuery,
    statusFilter: statusFilter,
  );
}
