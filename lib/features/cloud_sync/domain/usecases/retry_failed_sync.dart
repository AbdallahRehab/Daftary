import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021 US6: queues every failed item again and requests a cycle.
@injectable
class RetryFailedSync {
  const RetryFailedSync(this._repository);

  final CloudSyncRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.retryFailed();
}
