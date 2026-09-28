import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/app_lock_repository.dart';

@injectable
class EnableAppLock {
  const EnableAppLock(this._repository);

  final AppLockRepository _repository;

  /// Turns App Lock on (FR-001). Enforces FR-002's ordering: App Lock can
  /// never become active with zero unlock methods, so this fails with a
  /// `NotFoundFailure` unless `SetPin` has already succeeded — checked
  /// against the stored configuration first, and again by the repository
  /// against the stored credential itself.
  Future<Either<Failure, Unit>> call() async {
    final config = await _repository.getConfig();
    return config.match((failure) async => Left(failure), (config) async {
      if (!config.hasPin) {
        return const Left(
          NotFoundFailure('Set a PIN before enabling App Lock'),
        );
      }
      return _repository.enableAppLock();
    });
  }
}
