import 'package:injectable/injectable.dart';

import '../entities/sync_status.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021 US6: the live sync status behind the Settings sync page (FR-040).
@injectable
class WatchSyncStatus {
  const WatchSyncStatus(this._repository);

  final CloudSyncRepository _repository;

  Stream<SyncStatus> call() => _repository.watchStatus();
}
