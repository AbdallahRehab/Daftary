import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021 US6: the sync on/off switch (FR-041).
@injectable
class SetSyncEnabled {
  const SetSyncEnabled(this._repository);

  final CloudSyncRepository _repository;

  Future<Either<Failure, Unit>> call(bool enabled) =>
      _repository.setEnabled(enabled);
}
