import 'package:injectable/injectable.dart';

import '../entities/sync_failed_item.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021 US6: the changes the cloud refused, listed on the Settings sync page
/// with Retry.
@injectable
class WatchFailedSyncItems {
  const WatchFailedSyncItems(this._repository);

  final CloudSyncRepository _repository;

  Stream<List<SyncFailedItem>> call() => _repository.watchFailedItems();
}
