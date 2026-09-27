import 'package:injectable/injectable.dart';

import '../entities/sync_conflict_item.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021: the live list of open conflicts on financial records (FR-035).
@injectable
class WatchSyncConflicts {
  const WatchSyncConflicts(this._repository);

  final CloudSyncRepository _repository;

  Stream<List<SyncConflictItem>> call() => _repository.watchConflicts();
}
