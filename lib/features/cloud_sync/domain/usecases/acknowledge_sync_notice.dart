import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021 US6: records that the one-time sync notice was shown, so it never
/// shows again.
@injectable
class AcknowledgeSyncNotice {
  const AcknowledgeSyncNotice(this._repository);

  final CloudSyncRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.markNoticeShown();
}
