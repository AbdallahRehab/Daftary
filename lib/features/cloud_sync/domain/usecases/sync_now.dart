import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021 US6: "Sync now". Never starts a second cycle (FR-019).
@injectable
class SyncNow {
  const SyncNow(this._repository);

  final CloudSyncRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.syncNow();
}
