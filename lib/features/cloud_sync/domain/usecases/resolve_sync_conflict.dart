import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sync_conflict_item.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021: keeps one version of a record in conflict. The other version is
/// never lost: it is recorded as the discarded side of the resolution
/// (FR-035, contracts/sync-rpc.md §6).
@injectable
class ResolveSyncConflict {
  const ResolveSyncConflict(this._repository);

  final CloudSyncRepository _repository;

  Future<Either<Failure, Unit>> call(
    ConflictEntityType entityType,
    String entityId,
    ConflictChoice choice,
  ) => _repository.resolveConflict(entityType.wire, entityId, choice);
}
