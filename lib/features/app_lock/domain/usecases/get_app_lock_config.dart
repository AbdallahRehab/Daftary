import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_lock_config.dart';
import '../repositories/app_lock_repository.dart';

/// The current App Lock configuration, or [AppLockConfig.initial] when it
/// has never been configured.
@injectable
class GetAppLockConfig {
  const GetAppLockConfig(this._repository);

  final AppLockRepository _repository;

  Future<Either<Failure, AppLockConfig>> call() => _repository.getConfig();
}
